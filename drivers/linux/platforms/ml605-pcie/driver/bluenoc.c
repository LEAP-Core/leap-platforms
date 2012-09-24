/*
 * Linux device driver for Bluespec FPGA-based interconnect networks.
 */

#include <linux/module.h>
#include <linux/pci.h>         /* pci device types, fns, etc. */
#include <linux/errno.h>       /* error codes */
#include <linux/io.h>          /* I/O mapping, reading, writing */
#include <linux/types.h>       /* size_t */
#include <linux/cdev.h>        /* struct cdev */
#include <linux/fs.h>          /* struct file_operations */
#include <linux/init.h>        /* __init, __exit, etc. */
#include <linux/ioctl.h>       /* ioctl macros */
#include <linux/interrupt.h>   /* request_irq, free_irq, etc. */
#include <linux/delay.h>       /* ndelay */
#include <linux/mm.h>          /* kmalloc, kfree, struct page, etc. */
#include <linux/sched.h>       /* task_struct */
#include <linux/pagemap.h>     /* page_cache_release */
#include <linux/scatterlist.h> /* sg_* operations */
#include <linux/spinlock.h>    /* spinlock_t, spin_lock_irqsave, etc. */
#include <asm/uaccess.h>       /* copy_to_user, copy_from_user */

#include "bluenoc.h"

/*
 * driver module data for the kernel
 */

MODULE_AUTHOR ("Bluespec, Inc.");
MODULE_DESCRIPTION ("PCIe device driver for Bluespec FPGA interconnect");
MODULE_LICENSE ("Dual BSD/GPL");

/*
 * driver configuration
 */

/* stem used for module and device names */
#define DEV_NAME "bluenoc"

/* version string for the driver */
#define DEV_VERSION "1.0"

/* Bluespec's standard vendor ID */
#define BLUESPEC_VENDOR_ID 0x1be7

/* Bluespec's NoC device ID */
#define BLUESPEC_NOC_DEVICE_ID 0xb100

/* Number of boards to support */
#define NUM_BOARDS 16
#define UNASSIGNED 0

/* set to 1 to enable debug messages */
#define DEBUG 0

/*
 * Per-device data
 */

/* per-device data that persists from probe to remove */
typedef struct tBoard {
  /* bars */
  void __iomem* bar0io;
  void __iomem* bar1io;
  /* pci device pointer */
  struct pci_dev* pci_dev;
  unsigned int    board_number;
  /* board identification fields */
  unsigned int       major_rev;
  unsigned int       minor_rev;
  unsigned int       build;
  unsigned int       timestamp;
  unsigned int       bytes_per_beat;
  unsigned long long content_id;
  /* wait queue used for interrupt notifications */
  unsigned int irq_num;
  wait_queue_head_t intr_wq;
  /* spin lock used to protect access to DMA information fields */
  spinlock_t dma_lock;
  /* DMA information fields */
  unsigned int read_buffers_level;
  unsigned int read_flushed;
  unsigned int read_completed;
  unsigned int read_queue_full;
  unsigned int write_buffers_level;
  unsigned int write_completed;
  unsigned int write_queue_full;
  /* link to next board */
  struct tBoard* next;
} tBoard;

static tBoard* board_list = NULL;

/* forward declarations of driver routines */
static int __devinit bluenoc_probe(struct pci_dev* dev, const struct pci_device_id* id);
static void __devexit bluenoc_remove(struct pci_dev* dev);

static int bluenoc_open(struct inode* inode, struct file* filp);
static int bluenoc_release(struct inode* inode, struct file* filp);

static ssize_t bluenoc_read(struct file* filp, char* buf, size_t count, loff_t* loc);
static ssize_t bluenoc_write(struct file* filp, const char* buf, size_t count, loff_t* loc);

static loff_t bluenoc_llseek(struct file* filp, loff_t off, int whence);

static long bluenoc_ioctl(struct file* file, unsigned int cmd, unsigned long arg);

static irqreturn_t intr_handler(int irq, void* brd);

/*
 * driver initialization and exit
 *
 * these routines are responsible for allocating and
 * freeing kernel resources, creating device nodes,
 * registering the driver, obtaining a major and minor
 * numbers, etc.
 */

/* static device data */
static dev_t         device_number;
static struct class* bluenoc_class = NULL;
static struct cdev   cdev;
static unsigned int  open_count[NUM_BOARDS+1];

/* file operations pointers */
static const struct file_operations bluenoc_fops = {
  .owner          = THIS_MODULE,
  .open           = bluenoc_open,
  .release        = bluenoc_release,
  .read           = bluenoc_read,
  .write          = bluenoc_write,
  .llseek         = bluenoc_llseek,
  .unlocked_ioctl = bluenoc_ioctl,
  .compat_ioctl   = bluenoc_ioctl
};

/* PCI ID pattern table */
static DEFINE_PCI_DEVICE_TABLE(bluenoc_id_table) = {
  {PCI_DEVICE(BLUESPEC_VENDOR_ID, BLUESPEC_NOC_DEVICE_ID)},
  {}
};

MODULE_DEVICE_TABLE(pci, bluenoc_id_table);

/* PCI driver operations pointers */
static struct pci_driver bluenoc_driver = {
  .name     = DEV_NAME,
  .id_table = bluenoc_id_table,
  .probe    = bluenoc_probe,
  .remove   = __devexit_p(bluenoc_remove)
};

/* utility routine to clear the status register and DMA status fields
 * in the tBoard structure
 */

typedef enum { START_READ, START_WRITE, CLEAR_ALL } tDMAClearReason;

static void clear_dma_status(tBoard* this_board, tDMAClearReason reason)
{
  unsigned long flags;

  spin_lock_irqsave(&(this_board->dma_lock), flags);

  if (reason == START_READ) {
    iowrite32(0,this_board->bar0io + 2048);
    this_board->read_flushed    = 0;
    this_board->read_completed  = 0;
  }
  else if (reason == START_WRITE) {
    iowrite32(0,this_board->bar0io + 2052);
    this_board->write_completed = 0;
  }
  else { /* reason == CLEAR_ALL */
    writeq(0llu,this_board->bar0io + 2048);
    this_board->read_flushed    = 0;
    this_board->read_completed  = 0;
    this_board->write_completed = 0;
  }

  spin_unlock_irqrestore(&(this_board->dma_lock), flags);
}

/* utility routine to read the status register and fill in the
 * DMA status fields in the tBoard structure
 */

static void update_dma_buffer_status(tBoard* this_board)
{
  unsigned long long buffer_status;
  unsigned long flags;

  spin_lock_irqsave(&(this_board->dma_lock), flags);

  buffer_status = readq(this_board->bar0io + 2048);

  this_board->read_buffers_level  = (unsigned int) (buffer_status & 0x1fllu);
  this_board->read_flushed        = (buffer_status & (1llu << 5)) != 0;
  this_board->read_completed      = (buffer_status & (1llu << 6)) != 0;
  this_board->read_queue_full     = (buffer_status & (1llu << 7)) != 0;

  this_board->write_buffers_level = (unsigned int) (buffer_status >> 32) & 0x1fllu;
  this_board->write_completed     = (buffer_status & (1llu << 38)) != 0;
  this_board->write_queue_full    = (buffer_status & (1llu << 39)) != 0;

  spin_unlock_irqrestore(&(this_board->dma_lock), flags);
}


/* first routine called on module load */
static int __init bluenoc_init(void)
{
  int status;

  /* dynamically allocate a device number */
  if (alloc_chrdev_region(&device_number, 1, NUM_BOARDS, DEV_NAME) < 0) {
    printk(KERN_ERR "%s: failed to allocate character device region\n", DEV_NAME);
    return -1;
  }

  /* initialize driver data */
  board_list = NULL;

  /* register the driver with the PCI subsystem */
  status = pci_register_driver(&bluenoc_driver);
  if (status < 0) {
    printk(KERN_ERR "%s: failed to register PCI driver\n", DEV_NAME);
    return status;
  }

  /* log the fact that we loaded the driver module */
  printk(KERN_INFO "%s: Registered Bluespec BlueNoC driver %s\n", DEV_NAME, DEV_VERSION);
  printk(KERN_INFO "%s: Major = %d  Minors = %d to %d\n",
         DEV_NAME, MAJOR(device_number), MINOR(device_number), MINOR(device_number) + NUM_BOARDS - 1);

  return 0; /* success */
}

/* routine called on module unload */
static void __exit bluenoc_exit (void)
{
  tBoard* brd_ptr;

  /* unregister the driver with the PCI subsystem */
  pci_unregister_driver(&bluenoc_driver);

  /* release reserved device numbers */
  unregister_chrdev_region(device_number, NUM_BOARDS);

  /* log that the driver module has been unloaded */
  printk(KERN_INFO "%s: Unregistered Bluespec BlueNoC driver %s\n", DEV_NAME, DEV_VERSION);

  /* free all allocated board structures */
  brd_ptr = board_list;
  while (brd_ptr != NULL) {
    tBoard* free_me = brd_ptr;
    brd_ptr = brd_ptr->next;
    kfree(free_me);
  }
}

/* register init and exit routines */
module_init(bluenoc_init);
module_exit(bluenoc_exit);

/* driver PCI operations */

static int __devinit bluenoc_probe(struct pci_dev* dev, const struct pci_device_id* id)
{
  int err = 0;
  void __iomem* bar0_io = NULL;
  void __iomem* bar1_io = NULL;
  tBoard* this_board = NULL;
  unsigned int board_number = UNASSIGNED;

  printk(KERN_INFO "%s: PCI probe for 0x%04x 0x%04x\n", DEV_NAME, dev->vendor, dev->device);

  /* double-check vendor and device */
  if ((dev->vendor != BLUESPEC_VENDOR_ID) || (dev->device != BLUESPEC_NOC_DEVICE_ID)) {
    printk(KERN_ERR "%s: probe with invalid vendor or device ID\n", DEV_NAME);
    err = -EINVAL;
    goto exit_bluenoc_probe;
  }

  /* enable the PCI device */
  if (pci_enable_device(dev) != 0) {
    printk(KERN_ERR "%s: failed to enable %s\n", DEV_NAME, pci_name(dev));
    err = -EFAULT;
    goto exit_bluenoc_probe;
  }

  /* setup memory regions */
  if ((pci_request_region(dev, 0, "bar0") != 0) ||
      (pci_request_region(dev, 1, "bar1") != 0))
  {
    err = -EBUSY;
    goto disable_pci_device;
  }

  /* map BARs */
  bar0_io = pci_iomap(dev, 0, 0);
  bar1_io = pci_iomap(dev, 1, 0);
  if ((NULL == bar0_io) || (NULL == bar1_io)) {
    err = -EFAULT;
    goto unmap_bars;
  }

  /* check the magic number in BAR 0 */
  {
    unsigned long long magic_num = readq(bar0_io);
    unsigned long long expected_magic = 'B'
                                      | ((unsigned long long)'l' << 8)
                                      | ((unsigned long long)'u' << 16)
                                      | ((unsigned long long)'e' << 24)
                                      | ((unsigned long long)'s' << 32)
                                      | ((unsigned long long)'p' << 40)
                                      | ((unsigned long long)'e' << 48)
                                      | ((unsigned long long)'c' << 56);
    if (magic_num != expected_magic) {
      printk(KERN_ERR "%s: magic number %llx does not match expected %llx\n", DEV_NAME, magic_num, expected_magic);
      err = -EINVAL;
      goto unmap_bars;
    }
  }

  /* select the first available board number */
  board_number = 1;
  while (board_number <= NUM_BOARDS) {
    tBoard* brd = board_list;
    bool collision = false;
    while (brd != NULL && !collision) {
      collision |= (brd->board_number == board_number);
      brd = brd->next;
    }
    if (!collision) break;
    ++board_number;
  }
  if (board_number > NUM_BOARDS) {
    printk(KERN_ERR "%s: %d boards are already in use!\n", DEV_NAME, NUM_BOARDS);
    err = -EBUSY;
    goto unmap_bars;
  }

  /* allocate a structure for this board */
  this_board = (tBoard*) kmalloc(sizeof(tBoard),GFP_KERNEL);
  if (NULL == this_board) {
    printk(KERN_ERR "%s: unable to allocate memory for board structure\n", DEV_NAME);
    err = -EINVAL;
    goto unmap_bars;
  }
  else {
    unsigned int minor_rev = ioread32(bar0_io + 8);
    unsigned int major_rev = ioread32(bar0_io + 12);
    unsigned int build_version = ioread32(bar0_io + 16);
    unsigned int timestamp = ioread32(bar0_io + 20);
    unsigned int noc_params = ioread32(bar0_io + 28);
    unsigned long long board_content_id = readq(bar0_io + 32);
    struct msix_entry msix_entries[1];
    int result;

    /* insert board into linked list of boards */
    this_board->next = board_list;
    board_list = this_board;

    /* basic board info */

    printk(KERN_INFO "%s: board_number = %d\n", DEV_NAME, board_number);
    printk(KERN_INFO "%s: revision = %d.%d\n", DEV_NAME, major_rev, minor_rev);
    printk(KERN_INFO "%s: build_version = %d\n", DEV_NAME, build_version);
    printk(KERN_INFO "%s: timestamp = %d\n", DEV_NAME, timestamp);
    printk(KERN_INFO "%s: NoC is using %d byte beats\n", DEV_NAME, (noc_params & 0xff));
    printk(KERN_INFO "%s: Content identifier is %llx\n", DEV_NAME, board_content_id);

    this_board->bar0io         = bar0_io;
    this_board->bar1io         = bar1_io;
    this_board->pci_dev        = dev;
    this_board->board_number   = board_number;
    this_board->major_rev      = major_rev;
    this_board->minor_rev      = minor_rev;
    this_board->build          = build_version;
    this_board->timestamp      = timestamp;
    this_board->bytes_per_beat = noc_params & 0xff;
    this_board->content_id     = board_content_id;

    /* DMA setup */

    if (pci_set_dma_mask(dev,0xffffffffllu) != 0) {
      printk(KERN_ERR "%s: pci_set_dma_mask failed for 0xffffffff\n", DEV_NAME);
      err = -EIO;
      goto free_board;
    }

    init_waitqueue_head(&(this_board->intr_wq));

    this_board->dma_lock = SPIN_LOCK_UNLOCKED;

    update_dma_buffer_status(this_board);

    msix_entries[0].entry = 0;
    if (pci_enable_msix(this_board->pci_dev, msix_entries, 1) != 0) {
      printk(KERN_ERR "%s: Failed to allocate MSI-X interrupts\n", DEV_NAME);
      err = -EFAULT;
      goto free_board;
    }
    this_board->irq_num = msix_entries[0].vector;
    result = request_irq(this_board->irq_num, intr_handler, 0, DEV_NAME, (void*) this_board);
    if (result != 0) {
      printk(KERN_ERR "%s: Failed to get requested IRQ %d\n", DEV_NAME, this_board->irq_num);
      err = -EBUSY;
      goto disable_intr;
    }

    printk(KERN_INFO "%s: MSI-X interrupts enabled with IRQ %d\n", DEV_NAME, this_board->irq_num);
    iowrite32(0, bar0_io + 16396); /* set MSI-X Entry 0 Vector Control value to 0 (unmasked) */
  }

  /* setup a device file for this board */
  {
    dev_t this_device_number = MKDEV(MAJOR(device_number),board_number);

    open_count[board_number] = 0;

    /* add the device operations */
    cdev_init(&cdev,&bluenoc_fops);
    err = cdev_add(&cdev,this_device_number,1);
    if (err) {
      printk(KERN_ERR "%s: cdev_add failed\n", DEV_NAME);
      err = -EFAULT;
      goto release_irq;
    }

    /* create a device node via udev */
    if (NULL == this_board->next)
      bluenoc_class = class_create (THIS_MODULE, "Bluespec");
    device_create(bluenoc_class, NULL, this_device_number, NULL, "%s_%d", DEV_NAME, board_number);

    /* log creation of device */
    printk(KERN_INFO "%s: /dev/%s_%d device file created\n", DEV_NAME, DEV_NAME, board_number);
  }

  goto exit_bluenoc_probe;

  /* error cleanup code */
 release_irq:
  free_irq(this_board->irq_num, (void*) this_board);
 disable_intr:
  pci_disable_msix(this_board->pci_dev);
 free_board:
  board_list = this_board->next;
  kfree(this_board);
 unmap_bars:
  if (bar0_io != NULL) pci_iounmap(dev, bar0_io);
  if (bar1_io != NULL) pci_iounmap(dev, bar1_io);
 disable_pci_device:
  pci_disable_device(dev);
  pci_release_regions(dev);

 exit_bluenoc_probe:
  return err;
}

static void __devexit bluenoc_remove(struct pci_dev* dev)
{
  void __iomem* bar0_io = NULL;
  void __iomem* bar1_io = NULL;
  tBoard* this_board = NULL;
  tBoard* prev_board = NULL;
  dev_t this_device_number;

  /* locate device-specific data for this board */
  for (this_board = board_list; this_board != NULL; prev_board = this_board, this_board = this_board->next) {
    if (this_board->pci_dev == dev) break;
  }
  if (NULL == this_board) {
    printk(KERN_ERR "%s: Unable to locate board when removing PCI device %p\n", DEV_NAME, dev);
    return;
  }

  bar0_io = this_board->bar0io;
  bar1_io = this_board->bar1io;

  /* release the DMA irq */
  disable_irq(this_board->irq_num);
  free_irq(this_board->irq_num, (void*) this_board);

  /* turn off MSI-X interrupts */
  pci_disable_msix(dev);

  /* unmap BARs */
  if (bar0_io != NULL) pci_iounmap(dev, bar0_io);
  if (bar1_io != NULL) pci_iounmap(dev, bar1_io);

  /* disable the PCI device */
  pci_disable_device(dev);

  /* release the BAR regions */
  pci_release_regions(dev);

  /* free the board structure */
  this_device_number = MKDEV(MAJOR(device_number),this_board->board_number);
  if (prev_board)
    prev_board->next = this_board->next;
  else
    board_list = this_board->next;
  kfree(this_board);

  /* remove the device nodes via udev and release resources */
  device_destroy(bluenoc_class, this_device_number);
  if (NULL == board_list)
    class_destroy(bluenoc_class);

  /* delete the device */
  cdev_del(&cdev);

  /* log removal of device */
  printk(KERN_INFO "%s: /dev/%s_%d device file removed\n", DEV_NAME, DEV_NAME, MINOR(this_device_number));
}

/*
 * interrupt handler
 */

static irqreturn_t intr_handler(int irq, void* brd)
{
  tBoard* this_board = brd;

  update_dma_buffer_status(this_board);

#if DEBUG
  printk(KERN_INFO "%s_%d: interrupt!  buffer levels: %0d wr / %0d rd\n", DEV_NAME, this_board->board_number, this_board->write_buffers_level, this_board->read_buffers_level);
  if (this_board->write_completed)
    printk(KERN_INFO "%s_%d:   WRITE TRANSFER COMPLETED!\n", DEV_NAME, this_board->board_number);
  if (this_board->read_completed)
    printk(KERN_INFO "%s_%d:   READ TRANSFER COMPLETED!\n", DEV_NAME, this_board->board_number);
  if (this_board->read_flushed)
    printk(KERN_INFO "%s_%d:   READ TRANSFER FLUSHED!\n", DEV_NAME, this_board->board_number);
#endif

  wake_up_interruptible(&(this_board->intr_wq));

  return IRQ_HANDLED;
}


/*
 * driver file operations
 */


/* open the device file */
static int bluenoc_open(struct inode *inode, struct file *filp)
{
  int err = 0;
  unsigned int this_board_number = UNASSIGNED;
  tBoard* this_board = NULL;
  tBoard* tmp_board = NULL;

  /* figure out the board number */
  this_board_number = iminor(inode);

  /* store the board pointer for easy access */
  for (tmp_board = board_list; tmp_board != NULL; tmp_board = tmp_board->next) {
    if (tmp_board->board_number == this_board_number) {
      this_board = tmp_board;
      break;
    }
  }
  if (NULL == this_board) {
    printk(KERN_ERR "%s_%d: Unable to locate board\n", DEV_NAME, this_board_number);
    err = -ENXIO;
    goto exit_bluenoc_open;
  }
  filp->private_data = (void*) this_board;

  /* increment the open file count */
  open_count[this_board_number] += 1;

#if DEBUG
  /* log the operation */
  printk(KERN_INFO "%s_%d: Opened device file\n", DEV_NAME, this_board_number);
#endif

  goto exit_bluenoc_open;

 exit_bluenoc_open:
  return err;
}

/* close the device file */
static int bluenoc_release (struct inode *inode, struct file *filp)
{
  unsigned int this_board_number = UNASSIGNED;

  /* figure out the board number */
  this_board_number = iminor(inode);

  /* decrement the open file count */
  open_count[this_board_number] -= 1;

#if DEBUG
  /* log the operation */
  printk (KERN_INFO "%s_%d: Closed device file\n", DEV_NAME, this_board_number);
#endif

  return 0; /* success */
}

/* read data from the device */
static ssize_t bluenoc_read(struct file* filp, char* buf, size_t count, loff_t* loc)
{
  int err = 0;
  int result;
  unsigned long first_page;
  unsigned long last_page;
  unsigned int offset;
  unsigned int first_page_len;
  unsigned int last_page_len;
  int num_pages;
  struct page** pages;
  tBoard* this_board;
  int n;
  struct sg_table dma_table;
  struct scatterlist* sg;
  int num_dma_xfers;
  unsigned int slots_free = 0;
  unsigned int byte_count = 0;

  /* access the tBoard structure for this file */
  this_board = (tBoard*) filp->private_data;
#if DEBUG
  printk(KERN_INFO "%s_%d: read %0lu into %p\n", DEV_NAME, this_board->board_number, count, buf);
#endif

  /* convert the user buffer pointer to page / offset format and compute the number
   * of pages in the user buffer
   */
  first_page = (unsigned long) buf & PAGE_MASK;
  last_page = (unsigned long) (buf + count - 1) & PAGE_MASK;
  offset = (unsigned int) ((unsigned long) buf & ~PAGE_MASK);
  num_pages = (last_page >> PAGE_SHIFT) - (first_page >> PAGE_SHIFT) + 1;
  if (1 == num_pages)
    first_page_len = count;
  else
    first_page_len = PAGE_SIZE - offset;
  last_page_len = (unsigned int) ((unsigned long) (buf + count) & ~PAGE_MASK);
  if (num_pages > 4096) {
    printk(KERN_ERR "%s_%d: Read buffer is too large\n", DEV_NAME, this_board->board_number);
    err = -EFAULT;
    goto exit_bluenoc_read;
  }

  /* the buffer must be aligned on 128-byte boundaries */
  if ((offset % 128) != 0) {
    printk(KERN_ERR "%s_%d: Read buffer is not 128B aligned\n", DEV_NAME, this_board->board_number);
    err = -EFAULT;
    goto exit_bluenoc_read;
  }

  /* lock the buffer pages in memory */
  pages = kmalloc(num_pages * sizeof(struct page *), GFP_KERNEL);
  if (NULL == pages) {
    printk(KERN_ERR "%s_%d: Failed to allocate memory when mapping user pages\n", DEV_NAME, this_board->board_number);
    err = -ENOMEM;
    goto exit_bluenoc_read;
  }
  down_read(&current->mm->mmap_sem);
  result = get_user_pages(current, current->mm,
                          first_page, num_pages,
                          1, 0, /* write to buffer, don't force */
                          pages, NULL);
  up_read(&current->mm->mmap_sem);
  if (result != num_pages) {
    printk(KERN_ERR "%s_%d: get_user_pages failed\n", DEV_NAME, this_board->board_number);
    err = (result < 0) ? result : -EINVAL;
    if (result > 0) {
      for (n = 0; n < result; ++n)
        page_cache_release(pages[n]);
    }
    goto free_page_pointer_mem;
  }

  /* map the buffer for scatter-gather DMA */
  result = sg_alloc_table(&dma_table, num_pages, GFP_KERNEL);
  if (result != 0) {
    printk(KERN_ERR "%s_%d: Failed to allocate scatter-gather table\n", DEV_NAME, this_board->board_number);
    err = -ENOMEM;
    goto release_locked_pages;
  }
  sg = dma_table.sgl;
  sg_set_page(sg, pages[0], first_page_len, offset);
#if DEBUG
  printk(KERN_INFO "%s_%d: sg[0] = %0d @ %p + %x", DEV_NAME, this_board->board_number, first_page_len, page_address(pages[0]), offset);
#endif
  sg = sg_next(sg);
  if (num_pages > 2) {
    for (n = 1; n < num_pages - 1; ++n) {
      sg_set_page(sg, pages[n], PAGE_SIZE, 0);
#if DEBUG
      printk(KERN_INFO "%s_%d: sg[%0d] = %0lu @ %p + %x\n", DEV_NAME, this_board->board_number, n, PAGE_SIZE, page_address(pages[n]), 0);
#endif
      sg = sg_next(sg);
    }
  }
  if (num_pages > 1) {
    sg_set_page(sg, pages[num_pages-1], last_page_len, 0);
#if DEBUG
    printk(KERN_INFO "%s_%d: sg[%0d] = %0d @ %p + %x\n", DEV_NAME, this_board->board_number, num_pages-1, last_page_len, page_address(pages[num_pages-1]), 0);
#endif
  }
  num_dma_xfers = pci_map_sg(this_board->pci_dev, dma_table.sgl, num_pages, DMA_FROM_DEVICE);
  if (num_dma_xfers < 1) {
    printk(KERN_ERR "%s_%d: Failed to map scatter-gather list to DMA blocks\n", DEV_NAME, this_board->board_number);
    err = -EFAULT;
    goto unmap_sg_list;
  }

#if DEBUG
  /* check for out-of-range addresses or blocks which are too long */
  for (sg = dma_table.sgl; sg != NULL; sg = sg_next(sg)) {
    dma_addr_t   addr = sg_dma_address(sg);
    unsigned int len  = sg_dma_len(sg);
    if ((unsigned long)addr != ((unsigned long long)addr & 0x0000ffffffffffffllu)) {
      printk(KERN_ERR "%s_%d: DMA block address is out-of-range (%llx)\n", DEV_NAME, this_board->board_number, addr);
      err = -EFAULT;
      goto unmap_sg_list;
    }
    if (len > 16384) {
      printk(KERN_ERR "%s_%d: DMA block length is out-of-range (%0d)\n", DEV_NAME, this_board->board_number, len);
      err = -EFAULT;
      goto unmap_sg_list;
    }
  }
#endif

  /* program the device to perform DMA */
  clear_dma_status(this_board,START_READ);
  sg = dma_table.sgl;
  slots_free = 16 - this_board->read_buffers_level;
  while (sg != NULL) {
    dma_addr_t   addr = sg_dma_address(sg);
    unsigned int len  = sg_dma_len(sg);
    unsigned long long dma_cmd;
    unsigned int done = 0;
    sg = sg_next(sg);
    dma_cmd = (((sg == NULL) ? 0x1llu : 0x0llu) << 63)
            | (((unsigned long long)len & 0x3fff) << 48)
            | ((unsigned long long)addr & 0x0000ffffffffffffllu);
    while (slots_free == 0) {
      /* wait for more slots to become available */
      udelay(5); /* must give time for DMA command to be reflected in buffer status */
      update_dma_buffer_status(this_board);
      result = wait_event_interruptible(this_board->intr_wq,!this_board->read_queue_full);
      if (result != 0) {
        err = -ERESTARTSYS;
        goto unmap_sg_list;
      }
      if (this_board->read_flushed) {
        /* the read was terminated before the entire buffer list was sent,
         * so the device will be flushing its scatter gather list.
         */
#if DEBUG
        printk(KERN_INFO "%s_%d: sending end-of-list due to read flush\n", DEV_NAME, this_board->board_number);
#endif
        writeq((0x1llu << 63), this_board->bar0io + 4096);
        done = 1;
        break;
      }
      slots_free = 16 - this_board->read_buffers_level;
    }
    if (done) break;
    if (slots_free == 1) dma_cmd |= (0x1llu << 62);
#if DEBUG
    printk(KERN_INFO "%s_%d: sending dma cmd = %llx\n", DEV_NAME, this_board->board_number, dma_cmd);
#endif
    writeq(dma_cmd, this_board->bar0io + 4096);
    --slots_free;
  }
#if DEBUG
  printk(KERN_INFO "%s_%d: finished sending scatter-gather list\n", DEV_NAME, this_board->board_number);
#endif

  /* block waiting for the DMA to complete */
  while (!this_board->read_completed && !this_board->read_flushed) {
    result = wait_event_interruptible(this_board->intr_wq,this_board->read_completed || this_board->read_flushed);
    if (result != 0) {
      err = -ERESTARTSYS;
      break;
    }
  }

  /* figure out how much data was actually transfered */
  byte_count = ioread32(this_board->bar0io + 2056);
#if DEBUG
  printk(KERN_INFO "%s_%d: rd transfer count = %d bytes\n", DEV_NAME, this_board->board_number, byte_count);
#endif

  /* return a count of bytes read */
  if (err != -ERESTARTSYS)
    err = byte_count;

  /* mark modified pages */
  for (n = 0; n < num_pages; ++n) {
    if ((byte_count > 0) && !PageReserved(pages[n]))
      SetPageDirty(pages[n]);
    if (n == 0) {
      if (byte_count <= first_page_len)
        break;
      else
        byte_count -= first_page_len;
    }
    else if (n < num_pages - 1) {
      if (byte_count <= PAGE_SIZE)
        break;
      else
        byte_count -= PAGE_SIZE;
    }
  }

 unmap_sg_list:
  pci_unmap_sg(this_board->pci_dev, dma_table.sgl, num_pages, DMA_FROM_DEVICE);
  sg_free_table(&dma_table);

 release_locked_pages:
  for (n = 0; n < num_pages; ++n)
    page_cache_release(pages[n]);

 free_page_pointer_mem:
  kfree(pages);

 exit_bluenoc_read:
  return err;
}

/* write data to the device */
static ssize_t bluenoc_write(struct file* filp, const char* buf, size_t count, loff_t* loc)
{
  int err = 0;
  int result;
  unsigned long first_page;
  unsigned long last_page;
  unsigned int offset;
  unsigned int first_page_len;
  unsigned int last_page_len;
  int num_pages;
  struct page** pages;
  tBoard* this_board;
  int n;
  struct sg_table dma_table;
  struct scatterlist* sg;
  int num_dma_xfers;
  unsigned int slots_free = 0;
  unsigned int byte_count = 0;

  /* access the tBoard structure for this file */
  this_board = (tBoard*) filp->private_data;
#if DEBUG
  printk(KERN_INFO "%s_%d: write %0lu from %p\n", DEV_NAME, this_board->board_number, count, buf);
#endif

  /* convert the user buffer pointer to page / offset format and compute the number
   * of pages in the user buffer
   */
  first_page = (unsigned long) buf & PAGE_MASK;
  last_page = (unsigned long) (buf + count - 1) & PAGE_MASK;
  offset = (unsigned int) ((unsigned long) buf & ~PAGE_MASK);
  num_pages = (last_page >> PAGE_SHIFT) - (first_page >> PAGE_SHIFT) + 1;
  if (1 == num_pages)
    first_page_len = count;
  else
    first_page_len = PAGE_SIZE - offset;
  last_page_len = (unsigned int) ((unsigned long) (buf + count) & ~PAGE_MASK);
  if (num_pages > 4096) {
    printk(KERN_ERR "%s_%d: Write buffer is too large\n", DEV_NAME, this_board->board_number);
    err = -EFAULT;
    goto exit_bluenoc_write;
  }

  /* the buffer must be aligned on 128-byte boundaries */
  if ((offset % 128) != 0) {
    printk(KERN_ERR "%s_%d: Write buffer is not 128B aligned\n", DEV_NAME, this_board->board_number);
    err = -EFAULT;
    goto exit_bluenoc_write;
  }

  /* lock the buffer pages in memory */
  pages = kmalloc(num_pages * sizeof(struct page *), GFP_KERNEL);
  if (NULL == pages) {
    printk(KERN_ERR "%s_%d: Failed to allocate memory when mapping user pages\n", DEV_NAME, this_board->board_number);
    err = -ENOMEM;
    goto exit_bluenoc_write;
  }
  down_read(&current->mm->mmap_sem);
  result = get_user_pages(current, current->mm,
                          first_page, num_pages,
                          0, 0, /* read from buffer, don't force */
                          pages, NULL);
  up_read(&current->mm->mmap_sem);
  if (result != num_pages) {
    printk(KERN_ERR "%s_%d: get_user_pages failed\n", DEV_NAME, this_board->board_number);
    err = (result < 0) ? result : -EINVAL;
    if (result > 0) {
      for (n = 0; n < result; ++n)
        page_cache_release(pages[n]);
    }
    goto free_page_pointer_mem;
  }

  /* map the buffer for scatter-gather DMA */
  result = sg_alloc_table(&dma_table, num_pages, GFP_KERNEL);
  if (result != 0) {
    printk(KERN_ERR "%s_%d: Failed to allocate scatter-gather table\n", DEV_NAME, this_board->board_number);
    err = -ENOMEM;
    goto release_locked_pages;
  }

  sg = dma_table.sgl;
  sg_set_page(sg, pages[0], first_page_len, offset);
#if DEBUG
  printk(KERN_INFO "%s_%d: sg[0] = %0d @ %p + %x", DEV_NAME, this_board->board_number, first_page_len, page_address(pages[0]), offset);
#endif
  sg = sg_next(sg);
  if (num_pages > 2) {
    for (n = 1; n < num_pages - 1; ++n) {
      sg_set_page(sg, pages[n], PAGE_SIZE, 0);
#if DEBUG
      printk(KERN_INFO "%s_%d: sg[%0d] = %0lu @ %p + %x\n", DEV_NAME, this_board->board_number, n, PAGE_SIZE, page_address(pages[n]), 0);
#endif
      sg = sg_next(sg);
    }
  }
  if (num_pages > 1) {
    sg_set_page(sg, pages[num_pages-1], last_page_len, 0);
#if DEBUG
    printk(KERN_INFO "%s_%d: sg[%0d] = %0d @ %p + %x\n", DEV_NAME, this_board->board_number, num_pages-1, last_page_len, page_address(pages[num_pages-1]), 0);
#endif
  }
  num_dma_xfers = pci_map_sg(this_board->pci_dev, dma_table.sgl, num_pages, DMA_TO_DEVICE);
  if (num_dma_xfers < 1) {
    printk(KERN_ERR "%s_%d: Failed to map scatter-gather list to DMA blocks\n", DEV_NAME, this_board->board_number);
    err = -EFAULT;
    goto unmap_sg_list;
  }

#if DEBUG
  /* check for out-of-range addresses or blocks which are too long */
  for (sg = dma_table.sgl; sg != NULL; sg = sg_next(sg)) {
    dma_addr_t   addr = sg_dma_address(sg);
    unsigned int len  = sg_dma_len(sg);
    if ((unsigned long)addr != ((unsigned long long)addr & 0x0000ffffffffffffllu)) {
      printk(KERN_ERR "%s_%d: DMA block address is out-of-range (%llx)\n", DEV_NAME, this_board->board_number, addr);
      err = -EFAULT;
      goto unmap_sg_list;
    }
    if (len > 16384) {
      printk(KERN_ERR "%s_%d: DMA block length is out-of-range (%0d)\n", DEV_NAME, this_board->board_number, len);
      err = -EFAULT;
      goto unmap_sg_list;
    }
  }
#endif

  /* program the device to perform DMA */
  clear_dma_status(this_board,START_WRITE);
  sg = dma_table.sgl;
  slots_free = 16 - this_board->write_buffers_level;
  while (sg != NULL) {
    dma_addr_t   addr = sg_dma_address(sg);
    unsigned int len  = sg_dma_len(sg);
    unsigned long long dma_cmd;
    sg = sg_next(sg);
    dma_cmd = (((sg == NULL) ? 0x1llu : 0x0llu) << 63)
            | (((unsigned long long)len & 0x3fff) << 48)
            | ((unsigned long long)addr & 0x0000ffffffffffffllu);
#if DEBUG
    printk(KERN_INFO "%s_%d: slots_free = %d\n", DEV_NAME, this_board->board_number, slots_free);
#endif
    while (slots_free == 0) {
      /* wait for more slots to become available */
#if DEBUG
      printk(KERN_INFO "%s_%d: waiting for a free slot\n", DEV_NAME, this_board->board_number);
#endif
      udelay(5); /* must give time for DMA command to be reflected in buffer status */
      update_dma_buffer_status(this_board);
      result = wait_event_interruptible(this_board->intr_wq,!this_board->write_queue_full);
      if (result != 0) {
        err = -ERESTARTSYS;
        goto unmap_sg_list;
      }
      slots_free = 16 - this_board->write_buffers_level;
    }
    if (slots_free == 1) dma_cmd |= (0x1llu << 62);
#if DEBUG
    printk(KERN_INFO "%s_%d: sending dma cmd = %llx\n", DEV_NAME, this_board->board_number, dma_cmd);
#endif
    writeq(dma_cmd, this_board->bar0io + 4104);
    --slots_free;
  }
#if DEBUG
  printk(KERN_INFO "%s_%d: finished sending scatter-gather list\n", DEV_NAME, this_board->board_number);
#endif

  /* block waiting for the DMA to complete */
  while (!this_board->write_completed) {
    result = wait_event_interruptible(this_board->intr_wq,this_board->write_completed);
    if (result != 0) {
      err = -ERESTARTSYS;
      break;
    }
  }

  /* figure out how much data was actually transfered */
  byte_count = ioread32(this_board->bar0io + 2060);
#if DEBUG
  printk(KERN_INFO "%s_%d: wr transfer count = %d bytes\n", DEV_NAME, this_board->board_number, byte_count);
#endif

  /* return a count of bytes written */
  if (err != -ERESTARTSYS)
    err = byte_count;

 unmap_sg_list:
  pci_unmap_sg(this_board->pci_dev, dma_table.sgl, num_pages, DMA_TO_DEVICE);
  sg_free_table(&dma_table);

 release_locked_pages:
  for (n = 0; n < num_pages; ++n)
    page_cache_release(pages[n]);

 free_page_pointer_mem:
  kfree(pages);

 exit_bluenoc_write:
  return err;
}

/* seek is not supported */
static loff_t bluenoc_llseek(struct file* filp, loff_t off, int whence)
{
  return -ESPIPE; /* unseekable */
}

/*
 * driver IOCTL operations
 */

static long bluenoc_ioctl(struct file* filp, unsigned int cmd, unsigned long arg)
{
  /* basic sanity checks */
  if (_IOC_TYPE(cmd) != BS_IOC_MAGIC)
    return -ENOTTY;
  if (_IOC_NR(cmd) > BS_IOC_MAXNR)
    return -ENOTTY;

  /* we don't support any ioctls at this time */
  return -ENOTTY;
}
