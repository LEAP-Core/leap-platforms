/*Copyright (C) 2009 by Bluespec Inc.

  Permission is hereby granted, free of charge, to any person obtaining a copy
  of this software and associated documentation files (the "Software"), to deal
  in the Software without restriction, including without limitation the rights
  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
  copies of the Software, and to permit persons to whom the Software is
  furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
  ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
  SOFTWARE.
*/

/* Originally derived from Dini Group PCIE driver example, which was
 * itself derived from the book "Linux Device Drivers" by Alessandro
 * Rubini and Jonathan Corbet.
 */

#define DEBUG 0  /* set to 1 for extra debug messages */

#include <linux/pci.h>
#include <linux/highmem.h>
#include <linux/kernel.h>       /* printk() */
#include <linux/errno.h>        /* error codes */
#include <linux/types.h>        /* size_t */
#include <linux/smp_lock.h>     /* lock_kernel(), unlock_kernel() */
#include <linux/cdev.h>         /* struct cdev */

/* driver meta-data */

MODULE_LICENSE("MIT");
MODULE_AUTHOR("Bluespec, Inc.");
MODULE_DESCRIPTION("PCIE device driver for FPGA boards");

/*
 * driver and device setup
 */

int bsemu_major = 61; /* in the local/experimental major number range */
int bsemu_minor = 0;
int bsemu_devs = 0;   /* number of bare bsemu devices */

/* number of BARs per device */
#define MAXNUM_PCI_BAR 6

/* maximum number of driver instances supported */
#define NUM_SUPPORTED_DEVICES 128

/* accepted vendor IDs */
#define BSPEC_VENDOR_ID 0xb100
#define DINI_VENDOR_ID  0x17DF

/*
 * driver data structures
 */

/* data describing a single BAR location and size */
typedef struct _BSEMU_bar_type {
  unsigned long long log_addr;
  unsigned long long size;
} BSEMU_bar_type;

/* device data that is shared between kernel and user space */
typedef struct _BSEMU_SharedData {
  u16 vid; /* vendor id */
  u16 did; /* device id */
  BSEMU_bar_type bar[MAXNUM_PCI_BAR];
} BSEMU_SharedData;

/* kernel space device data */
typedef struct _BSEMU_KernelData {
  struct pci_dev *pdev;
  void *kernel_ptr[MAXNUM_PCI_BAR]; /* kernel virtual pointers */
  void *log_ptr[MAXNUM_PCI_BAR];    /* kernel virtual pointers */
  spinlock_t lock;
} BSEMU_KernelData;

/* this is the top level type for each device */
typedef struct _BSEMU_DeviceData {
    BSEMU_SharedData shared_data;
    BSEMU_KernelData kernel_data;
    struct cdev cdev;
} BSEMU_DeviceData;

/*
 * forward function declarations
 */

extern int pci_getdevices(BSEMU_DeviceData *);

/*
 * global driver data
 */

static spinlock_t bsemu_devices_lock = SPIN_LOCK_UNLOCKED;
static BSEMU_DeviceData bsemu_devices[NUM_SUPPORTED_DEVICES];
static BSEMU_DeviceData* pLastDevice = bsemu_devices;

/*
 * IOCTL definitions
 */

#define BSEMU_IOC_MAGIC  'B'

#define BSEMU_IOC_RESET                           _IO(BSEMU_IOC_MAGIC, 0)
#define BSEMU_IOC_GETDEVICE                       _IOWR(BSEMU_IOC_MAGIC, 1, BSEMU_SharedData)

#define BSEMU_IOC_MAXNR 1

/*
 * device open, close and mmap routines
 */

int bsemu_open(struct inode *inode, struct file *filp)
{
  BSEMU_DeviceData* pdev = container_of(inode->i_cdev, BSEMU_DeviceData, cdev);

  int num = pdev - bsemu_devices;

  printk(KERN_INFO "bsemu: open minor number %d\n", num);
  if ( num >= (sizeof(bsemu_devices)/sizeof(bsemu_devices[0])) ) {
    return -ENODEV;
  }
  /* store the bsemu structure related to this filp into the private data area of the filp. */
  filp->private_data = pdev;
  return 0;                   /* success */
}

int bsemu_close(struct inode *inode, struct file *filp)
{
  BSEMU_DeviceData* pdev = container_of(inode->i_cdev, BSEMU_DeviceData, cdev);

  int num = pdev - bsemu_devices;

  printk(KERN_INFO "bsemu: close minor number %d\n", num);
  if ( num >= (sizeof(bsemu_devices)/sizeof(bsemu_devices[0])) ) {
    return -ENODEV;
  }

  /* clear the bsemu structure related to this filp into the private data area of the filp. */
  filp->private_data = NULL;
  return 0;                   /* success */
}

/* TODO: We mmap IO memory. This works in x86 because IO space is part
 *       of physical address space.  So this linux driver is really
 *       linux x86 driver.  make this portable
 */
int bsemu_mmap(struct file *filp, struct vm_area_struct *vma)
{
  BSEMU_DeviceData* pdevdata = (BSEMU_DeviceData*)filp->private_data;
  int idx;
  unsigned long size, bar, off;

  if ( pdevdata == NULL ) {
    printk(KERN_DEBUG
	   "bsemu: bsemu_mmap : invalid filp used, no bsemu_data value stored in private_data\n");
    return -EINVAL;
  }

  idx  = (int)(pdevdata - bsemu_devices);
  size = vma->vm_end - vma->vm_start;
  bar  = vma->vm_pgoff % MAXNUM_PCI_BAR;
  off  = 0;

  printk(KERN_DEBUG
	 "bsemu: bsemu_mmap(%04X:%04X,%d,%d) : called size = 0x%08x\n", pdevdata->shared_data.vid,pdevdata->shared_data.did,idx,(int)bar, (unsigned int)size);
  printk(KERN_DEBUG
	 "bsemu: bsemu_mmap(%04X:%04X,%d,%d) : log_addr: 0x%p\tuser loc: 0x%08x\n",
	 pdevdata->shared_data.vid,pdevdata->shared_data.did,idx,(int)bar,
	 ((char*)pdevdata->kernel_data.log_ptr[bar]) + (unsigned int)off,
	 (unsigned int) vma->vm_start);
  printk(KERN_DEBUG
	 "bsemu: bsemu_mmap(%04X:%04X,%d,%d) : pgoff 0x%08x\n", pdevdata->shared_data.vid,pdevdata->shared_data.did,idx,(int) bar, (int) vma->vm_pgoff);

  if (size > pdevdata->shared_data.bar[bar].size - off)
    return -EINVAL;

  /* io_remap_pfn_range is the newer more proper function than remap_pfn_range.
   * on older kernels io_remap_pfn_range doesn't exist, use io_remap_page_range
   */
#ifdef KERNEL_IS_PRE_2_6_15
  if (io_remap_page_range(vma, vma->vm_start,
			  ((unsigned long) pdevdata->kernel_data.log_ptr[bar] + off),
#else
  if (io_remap_pfn_range(vma, vma->vm_start,
			 ((unsigned long) pdevdata->kernel_data.log_ptr[bar] + off) >> PAGE_SHIFT,
#endif
			 size, vma->vm_page_prot)) {
    printk("io_remap failed");
    return -EAGAIN;
  }

  return 0;
}

/*
  The ioctl() implementation for main module

  BSEMU_IOC_GETDEVICE:
    user space program sends vendor/device id to this driver, if a device is found
    return information on each BAR

*/

int bsemu_ioctl(struct inode *inode, struct file *filp,
                unsigned int cmd, unsigned long arg)
{
  BSEMU_DeviceData* pdev = container_of(inode->i_cdev, BSEMU_DeviceData, cdev);

  int num = pdev - bsemu_devices;
  int ret = 0;
  BSEMU_KernelData *kdata;
  BSEMU_SharedData *sdata;

  printk(KERN_INFO "bsemu: ioctl minor number %d\n", num);
  if ( num >= (sizeof(bsemu_devices)/sizeof(bsemu_devices[0])) ) {
    return -ENODEV;
  }

  /* don't even decode wrong cmds: better returning  ENOTTY than EFAULT */
  if (_IOC_TYPE(cmd) != BSEMU_IOC_MAGIC)
    return -ENOTTY;
  if (_IOC_NR(cmd) > BSEMU_IOC_MAXNR)
    return -ENOTTY;

  kdata = &pdev->kernel_data;
  sdata = &pdev->shared_data;

  switch (cmd) {
    case BSEMU_IOC_GETDEVICE:
      {
	if (!access_ok(VERIFY_WRITE, (void __user *) arg, sizeof(BSEMU_SharedData))) {
	  ret = -EINVAL;
	  break;
	}
	printk(KERN_DEBUG "bsemu: IOC_GETDEVICE called %04x %04x\n", sdata->vid, sdata->did);

	ret = copy_to_user((BSEMU_SharedData *) arg, sdata, sizeof(BSEMU_SharedData));
	break;
      }
  default: /* redundant, as cmd was checked against MAXNR */
    return -ENOTTY;
  }

  return ret;
}


/* IOCTL compatibility to allow 32-bit binaries to use a driver on a 64-bit kernel */
long bsemu_compat_ioctl(struct file *filp, unsigned int cmd, unsigned long arg)
{
  struct inode* inode = filp->f_path.dentry->d_inode;
  int status;

  lock_kernel();

  status = bsemu_ioctl(inode, filp, cmd, arg);

  unlock_kernel();

  return (long) status;
}

/*
 * The fops for main module
 */

struct file_operations bsemu_fops = {
  owner:THIS_MODULE,
  ioctl:bsemu_ioctl,
  compat_ioctl:bsemu_compat_ioctl,
  mmap:bsemu_mmap,
  open:bsemu_open,
  release:bsemu_close
};

/*
 * Device allocation, probing, etc.
 */

static BSEMU_DeviceData* getDevice(struct pci_dev* dev)
{
  BSEMU_DeviceData* pDev = bsemu_devices;
  spin_lock(&bsemu_devices_lock);

  /* locate next available device */
  while ( pDev < pLastDevice ) {
    if ( pDev->kernel_data.pdev == NULL ) {
      goto exit_nextDevice;
    }
    pDev++;
  }
  if ( pLastDevice == (bsemu_devices + (sizeof(bsemu_devices)/sizeof(bsemu_devices[0]))) ) {
    /* too many devices already present */
    return NULL;
  }
  pDev = pLastDevice;
  pLastDevice++;
exit_nextDevice:
  spin_unlock(&bsemu_devices_lock);
  return pDev;
}

static void putDevice(BSEMU_DeviceData* pDev) {
  spin_lock(&bsemu_devices_lock);
  pDev->kernel_data.pdev = NULL;
  spin_unlock(&bsemu_devices_lock);
}


static int bsemu_probe(struct pci_dev* dev, const struct pci_device_id *id)
{
  int err = 0;
  int i = 0;
  BSEMU_DeviceData* pDevice = NULL;
  BSEMU_KernelData* kdata;
  BSEMU_SharedData* sdata;

  printk( KERN_NOTICE "bsemu_probe: probed with 0x%04x, 0x%04x\n",dev->vendor,dev->device);

  if ( (dev->vendor != BSPEC_VENDOR_ID) && (dev->vendor != DINI_VENDOR_ID) ) {
    printk( KERN_NOTICE "bsemu_probe: 0x%04x, 0x%04x is not an accepted vendor ID",dev->vendor,dev->device);
    return -EINVAL;
  }

  pDevice= getDevice(dev);
  if ( pDevice == NULL ) {
    /* too many devices already present */
    return -ENOMEM;
  }

  /* initialize the device data structure! */
  pDevice->kernel_data.pdev = dev;
  pDevice->shared_data.vid = dev->vendor;
  pDevice->shared_data.did = dev->device;
  for ( i = 0; i < MAXNUM_PCI_BAR; i++ ) {
    pDevice->kernel_data.log_ptr[i] = NULL;
    pDevice->kernel_data.kernel_ptr[i] = NULL;
    pDevice->shared_data.bar[i].log_addr = 0;
    pDevice->shared_data.bar[i].size = 0;
  }
  spin_lock_init(&pDevice->kernel_data.lock);

  /* Now lets access the device and determine is resources and capabilities. */

  if ( pci_enable_device(dev) != 0 ) {
    err = -EFAULT;
    goto exit_bsemu_probe;
  }
  pci_set_drvdata(dev,pDevice); /* match this device struct with our device struct. */

  // set DMA Bus mastering
  pci_set_master(dev);

  // get bar locations
  for ( i = 0; i < MAXNUM_PCI_BAR; i++ ) {
    pDevice->kernel_data.log_ptr[i] = (void*)pci_resource_start(dev,i);
    pDevice->shared_data.bar[i].log_addr = (unsigned long)pci_resource_start(dev,i);
    pDevice->shared_data.bar[i].size = pci_resource_len(dev,i);

    printk("BAR %i, log addr %x, size %x\n",i,(unsigned int)pDevice->shared_data.bar[i].log_addr,
	   (unsigned int)pDevice->shared_data.bar[i].size);
  }

  kdata = &pDevice->kernel_data;
  sdata = &pDevice->shared_data;

  /* map BAR0 and BAR1 to kernel memory space */
  kdata->kernel_ptr[0] =
    ioremap_nocache((unsigned long) kdata->log_ptr[0],
		    sdata->bar[0].size);
  if (kdata->kernel_ptr[0] == NULL) {
    printk (KERN_ERR
	    "bsemu: error mapping BAR 0 to kernel virtual memory\n");
    err = -EBUSY;
    goto disable_bsemu_device;
  } else {
    printk (KERN_INFO
	    "bsemu: mapping BAR 0 to kernel virtual memory (%p)\n",
	    kdata->kernel_ptr[0]);
  }

  kdata->kernel_ptr[1] =
    ioremap_nocache((unsigned long) kdata->log_ptr[1],
		    sdata->bar[1].size);
  if (kdata->kernel_ptr[1] == NULL) {
    printk (KERN_ERR
	    "bsemu: error mapping BAR 1 to kernel virtual memory\n");
    err = -EBUSY;
    goto unmap_kernel_ptr0;
  } else {
    printk (KERN_INFO
	    "bsemu: mapping BAR 1 to kernel virtual memory (%p)\n",
	    kdata->kernel_ptr[1]);
  }

  /* register this character device. */
  {
    int index = (pDevice - bsemu_devices);
    int devno = MKDEV(bsemu_major, bsemu_minor + index);
    cdev_init(&pDevice->cdev,&bsemu_fops);
    pDevice->cdev.owner = THIS_MODULE;
    pDevice->cdev.ops = &bsemu_fops;
    err = cdev_add(&pDevice->cdev,devno,1);
    if (err) {
      printk(KERN_NOTICE "bsemu: Error %d adding bsemu%d", err, index);
      err = -EFAULT;
      goto unmap_kernel_ptr1;
    }
  }

  goto exit_bsemu_probe;

unmap_kernel_ptr1:
    iounmap(kdata->kernel_ptr[1]);
unmap_kernel_ptr0:
    iounmap(kdata->kernel_ptr[0]);
disable_bsemu_device:
    pci_disable_device(dev);

exit_bsemu_probe:
    return err;
}

/* called when the device is being removed */
static void bsemu_remove(struct pci_dev *dev) {
  BSEMU_DeviceData* pdevdata = (BSEMU_DeviceData*)pci_get_drvdata(dev);
  BSEMU_KernelData *kdata = &pdevdata->kernel_data;

  /* free bar memory mappings */
  if (kdata->kernel_ptr[0] != NULL)
    iounmap(kdata->kernel_ptr[0]);
  if (kdata->kernel_ptr[1] != NULL)
    iounmap(kdata->kernel_ptr[1]);

  pci_disable_device(kdata->pdev);

  /* remove the character device associated with this board. */
  cdev_del(&pdevdata->cdev);
  putDevice(pdevdata);
}

/*
 * Driver function mapping
 */

struct pci_device_id bsemu_id_table[3] = {
  {
    .vendor = BSPEC_VENDOR_ID,
    .device = PCI_ANY_ID,
    .subvendor = PCI_ANY_ID,
    .subdevice = PCI_ANY_ID,
    .class = 0,
    .class_mask = 0,
    .driver_data = 0
  },
  {
    .vendor = DINI_VENDOR_ID,
    .device = PCI_ANY_ID,
    .subvendor = PCI_ANY_ID,
    .subdevice = PCI_ANY_ID,
    .class = 0,
    .class_mask = 0,
    .driver_data = 0
  },
  {0}
};

struct pci_driver bsemu_driver = {
  .name = "bsemu",
  .id_table = bsemu_id_table,
  .probe = bsemu_probe,
  .remove = bsemu_remove
};

static int __init bsemu_init(void) {
  int result;
  dev_t dev;
  spin_lock_init(&bsemu_devices_lock);

  printk(KERN_INFO "bsemu: bsemu_init\n");

  /*
   * Register your major, and accept a dynamic number
   */
  result = alloc_chrdev_region(&dev, 0, NUM_SUPPORTED_DEVICES, bsemu_driver.name);
  bsemu_major = MAJOR(dev); bsemu_minor = MINOR(dev);
  if (result < 0) {
    printk( KERN_WARNING "bsemu: can't allocate major %d\n", bsemu_major );
    return result;
  }

  return pci_register_driver(&bsemu_driver);
}

static void __exit bsemu_exit(void) {
  dev_t dev;

  printk(KERN_INFO "bsemu: bsemu_exit\n");
  dev = MKDEV(bsemu_major, bsemu_minor);
  unregister_chrdev_region(dev, NUM_SUPPORTED_DEVICES);
  unregister_chrdev(bsemu_major, bsemu_driver.name);
  pci_unregister_driver(&bsemu_driver);
}

module_init(bsemu_init);
module_exit(bsemu_exit);
