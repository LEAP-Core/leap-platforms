#include "pchnl_main.h"
#include "pchnl_if.h"

char pchnl_driver_name[] = "pchnl";
char pchnl_driver_string[] = "Intel(R) PCIe Channel";
char pchnl_driver_version[] = "1.0.0.0";
char pchnl_copyright[] = "Copyright (c) 2007-2008 Intel Corporation.";

// Global driver object
static struct pchnl_driver* gpchnl_drv = NULL;
// Global device ogject
static struct pchnl_device* gpchnl_dev = NULL;

// Global interrupt counter
//static unsigned int intr_count = 0;
static DECLARE_WAIT_QUEUE_HEAD(wq);
static int flag = 0;

//static unsigned long mmio_start;

/* paccl_pci_tbl - PCI Device ID Table
 *
 * Wildcard entries (PCI_ANY_ID) should come last
 * Last entry must be all 0s
 *
 * { Vendor ID, Device ID, SubVendor ID, SubDevice ID,
 *   Class, Class Mask, private data (not used) }
 */
static struct pci_device_id pchnl_pci_tbl[] = {
     {0x10ee, 0x0007, PCI_ANY_ID, PCI_ANY_ID, 0, 0, 0},
     /* required last entry */
     {0,}
};
MODULE_DEVICE_TABLE(pci, pchnl_pci_tbl);

/************************************
 * Function Declearation Section
 ************************************/
static int pchnl_init_module(void);
static void pchnl_exit_module(void);
static int __devinit pchnl_probe(struct pci_dev *pdev, const struct pci_device_id *ent);
static void __devexit pchnl_remove(struct pci_dev *pdev);
static irqreturn_t pchnl_intr(int irq, void *data, struct pt_regs *regs);
static int pchnl_open (struct inode *inode, struct file *file);
static int pchnl_close(struct inode *inode, struct file *file);
static int pchnl_ioctl(struct inode *inode, struct file *file, unsigned int cmd, unsigned long arg);
static int pchnl_mmap(struct file *filp, struct vm_area_struct *vma);
static ssize_t pchnl_write(struct file *filp, const char *buf, size_t count, loff_t *f_pos);
static ssize_t pchnl_read(struct file *filp, char *buf, size_t count, loff_t *f_pos);
static int pchnl_init_device(struct pchnl_device *gpchnl_dev);
static int pchnl_shutdown_device(struct pchnl_device *gpchnl_dev);
static uint32_t big_endian(uint32_t little);


static struct pci_driver pchnl_driver = {
     .name = pchnl_driver_name,
     .id_table = pchnl_pci_tbl,
     .probe = pchnl_probe,
     .remove = __devexit_p(pchnl_remove)
};

MODULE_AUTHOR("Wang, Liang<liang.wang@intel.com>");
MODULE_DESCRIPTION("Intel PCIe Hardware Channel");
MODULE_LICENSE("GPL");

static struct file_operations pchnl_fops =
{
     .owner    = THIS_MODULE,
     .open     = pchnl_open,
     .ioctl    = pchnl_ioctl,
     .read     = pchnl_read,
     .write    = pchnl_write,
     .mmap     = pchnl_mmap,
     .release  = pchnl_close,
};


/**
 * pchnl_init_module - Driver Registration Routine
 *
 * pchnl_init_module is the first routine called when the driver is
 * loaded. All it does is register with the PCI subsystem.
 **/
static int __init
pchnl_init_module(void)
{
     int ret;
     printk(KERN_INFO "%s - version %s\n",
            pchnl_driver_string, pchnl_driver_version);

     printk(KERN_INFO "%s\n", pchnl_copyright);

     PCHNL_DBG("pchnl_init_module enter\n");

     gpchnl_drv = kmalloc (sizeof(struct pchnl_driver), GFP_KERNEL);

     if ( !gpchnl_drv) {
          ret = -ENOMEM;
          PCHNL_ERR("pchnl_init_module kmalloc failed\n");
          goto err_alloc_mem;
     }
     memset(gpchnl_drv, 0, sizeof(struct pchnl_driver));

     ret = pci_module_init(&pchnl_driver);
     if ( ret < 0){
          PCHNL_ERR("pchnl_init_module pci_module_init failed\n");
          goto err_module_init;
     }

     gpchnl_drv->miscdev.minor = MISC_DYNAMIC_MINOR;
     gpchnl_drv->miscdev.name  = pchnl_driver_name;
     gpchnl_drv->miscdev.fops  = &pchnl_fops;
     gpchnl_drv->name = pchnl_driver_name;

     ret = misc_register(&gpchnl_drv->miscdev);
     if (ret) {
          PCHNL_ERR("pchnl_init_module misc_register failed\n");
          ret = -1;
          goto err_register_pchnldrv;
     }

     PCHNL_DBG("pchnl_init_module register misc device with minor version %d\n", gpchnl_drv->miscdev.minor);

     PCHNL_DBG("pchnl_init_module exit with success\n");

     return ret;
err_register_pchnldrv:
     pci_unregister_driver(&pchnl_driver);
err_module_init:
     kfree(gpchnl_drv);
     gpchnl_drv = NULL;
err_alloc_mem:
     PCHNL_DBG("pcnhl_init_module exit with error\n");
     return ret;
}

module_init(pchnl_init_module);

/**
 * pchnl_exit_module - Driver Exit Cleanup Routine
 *
 * pchnl_exit_module is called just before the driver is removed
 * from memory.
 **/
static void __exit
pchnl_exit_module(void)
{
     PCHNL_DBG("pchnl_exit_module enter\n");
     pci_unregister_driver(&pchnl_driver);

     misc_deregister(&gpchnl_drv->miscdev);

     kfree(gpchnl_drv);
     gpchnl_drv = NULL;

     PCHNL_DBG("pchnl_exit_module exit\n");
}

module_exit(pchnl_exit_module);

/**
 * pchnl_probe - Device Initialization Routine
 * @pdev: PCI device information struct
 * @ent: entry in paccl_pci_tbl
 *
 * Returns 0 on success, negative on failure
 *
 * pchnl_probe initializes an adapter identified by a pci_dev structure.
 * The OS initialization, configuring of the adapter private structure,
 * and a hardware reset occur.
 **/
static int __devinit
pchnl_probe(struct pci_dev *pdev,
            const struct pci_device_id *ent)
{
//     unsigned long mmio_start;
     int mmio_len;
     int pci_using_dac;
     int err;
     unsigned int order;
//     uint32_regs reg32;

     PCHNL_DBG("pchnl_probe enter\n");

     if ((err = pci_enable_device(pdev)))
          return err;

     if (!(err = pci_set_dma_mask(pdev, PCI_DMA_64BIT))) {
          pci_using_dac = 1;
     } else{
          if (( err = pci_set_dma_mask(pdev, PCI_DMA_32BIT))) {
               PCHNL_ERR("No usable DMA configuration, aborting\n");
               return err;
          }
          pci_using_dac = 0;
     }

     if(( err = pci_request_regions(pdev, pchnl_driver_name)))
          return err;

     pci_set_master(pdev);

     gpchnl_dev = kmalloc (sizeof(struct pchnl_device), GFP_KERNEL);
     if (!gpchnl_dev){
          err = -ENOMEM;
          PCHNL_ERR("pchnl_probe kmalloc failed\n");
          goto err_alloc_gpchnl_dev;
     }
     memset(gpchnl_dev, 0, sizeof(struct pchnl_device));
     
     pci_set_drvdata(pdev, gpchnl_dev);

     gpchnl_dev->io_base = pci_resource_start(pdev, BAR_0);
     mmio_len = pci_resource_len(pdev, BAR_0);

     gpchnl_dev->hw_addr = ioremap(gpchnl_dev->io_base, mmio_len);
     if(!gpchnl_dev->hw_addr){
          err = -EIO;
          goto err_ioremap;
     }
     PCHNL_DBG("pchnl_probe ioremapped addr %p & len %u\n", gpchnl_dev->hw_addr, mmio_len);

     gpchnl_dev->pdev = pdev;
     if(pchnl_init_device(gpchnl_dev)){
          err = -ENODEV;
          PCHNL_ERR("pchnl_probe pchnl_init_device failed\n");
          goto err_dev_init;
     }

     if ((err = request_irq(gpchnl_dev->pdev->irq, &pchnl_intr,
                            SA_SHIRQ | SA_SAMPLE_RANDOM,
                            NULL, gpchnl_dev))){
          PCHNL_ERR("pchnl_probe Unabe to allocate interrupt Error: %d\n", err);
          goto err_dev_init;
     }

     order = get_order(BUF_SIZE);
     gpchnl_dev->h2f_pg_base = alloc_pages(GFP_KERNEL, order);
     if (gpchnl_dev->h2f_pg_base == NULL){
          err = -ENOMEM;
          PCHNL_ERR("pchnl_probe Unable to allocate memory\n");
          goto err_dev_init;
     }
     gpchnl_dev->dma_h2fp = page_address(gpchnl_dev->h2f_pg_base);
     memset(gpchnl_dev->dma_h2fp, 0x00, BUF_SIZE);

     gpchnl_dev->f2h_pg_base = alloc_pages(GFP_KERNEL, order);
     if (gpchnl_dev->f2h_pg_base == NULL){
          err = -ENOMEM;
          PCHNL_ERR("pchnl_probe Unable to allocate memory\n");
          goto err_dev_init;
     }
     gpchnl_dev->dma_f2hp = page_address(gpchnl_dev->f2h_pg_base);
     memset(gpchnl_dev->dma_f2hp, 0x00, BUF_SIZE);
     
     

     PCHNL_DBG("pchnl_probe exit with success\n");
     return 0;
err_dev_init:
     pchnl_shutdown_device(gpchnl_dev);
     iounmap(gpchnl_dev->hw_addr);
err_ioremap:
     kfree(gpchnl_dev);
err_alloc_gpchnl_dev:
     pci_release_regions(pdev);
     PCHNL_DBG("pchnl_probe exit with error\n");
     return err;
}

/**
 * pchnl_remove - Device Removal Routine
 * @pdev: PCI device information struct
 *
 * pchnl_remove is called by the PCI subsystem to alert the driver
 * that it should release a PCI device.  The could be caused by a
 * Hot-Plug event, or because the driver is going to be removed from
 * memory.
 **/
static void __devexit
pchnl_remove(struct pci_dev *pdev)
{
     struct pchnl_device *gpchnl_dev = pci_get_drvdata(pdev);
//     uint32_regs reg32;
     unsigned int order;

     PCHNL_DBG("pchnl_remove enter\n");

     order = get_order(BUF_SIZE);
     __free_pages(gpchnl_dev->h2f_pg_base, order);
     __free_pages(gpchnl_dev->f2h_pg_base, order);

     free_irq(gpchnl_dev->pdev->irq, gpchnl_dev);
     pchnl_shutdown_device(gpchnl_dev);

     iounmap(gpchnl_dev->hw_addr);
     pci_release_regions(pdev);

     kfree(gpchnl_dev);

     PCHNL_DBG("pchnl_remove exit\n");
}


static int
pchnl_init_device(struct pchnl_device *gpchnl_dev)
{

     PCHNL_DBG("pchnl_init_device enter\n");
     
     PCHNL_DBG("pchnl_init_device exit\n");
     return 0;
}

static int
pchnl_shutdown_device(struct pchnl_device *gpchnl_dev)
{
     PCHNL_DBG("pchnl_shutdown_device enter\n");

     PCHNL_DBG("pchnl_shutdown_device enter\n");
     return 0;
}

irqreturn_t
pchnl_intr(int irq, void *data, struct pt_regs *regs)
{

     PCHNL_DBG("pchnl_intr enter\n");

     //write acknowledge to hardware
     writel(0xffffffff, gpchnl_dev->hw_addr + 0x08);
     
     gpchnl_drv->intr_count ++;
     copy_to_user(gpchnl_drv->usr_intr_reg_p, &(gpchnl_drv->intr_count), sizeof(unsigned int));

     if (flag == 0) {
          flag = 1;
          wake_up_interruptible(&wq);
     }else {
          flag = 0;
     }
     
     
     PCHNL_DBG("pchnl_intr exit\n");
     return IRQ_HANDLED;
}

static int
pchnl_open (struct inode *inode, struct file *file)
{
     struct pchnl_driver *dev = gpchnl_drv;
     int minor, ret = 0;

     minor = iminor(inode);
     if ( minor != dev->miscdev.minor){
          ret = -ENODEV;
          goto fail;
     }
fail:
     return ret;
}

static int
pchnl_close(struct inode *inode, struct file *file)
{
     int ret = 0;
     PCHNL_DBG("enter chnl_close\n");

     
     PCHNL_DBG("exit chnl_close\n");
     return ret;
}

static ssize_t
pchnl_write(struct file *filp, const char *buf, size_t count, loff_t *f_pos)
{
#if 0
     ssize_t index;
     uint64_t addr64;
     uint32_t addr_hi, addr_lo, len;
     addr64 = (uint64_t)__pa(gpchnl_dev->dma_h2fp);
     addr_hi = (u32)(((addr64) >> 32) & 0x00000000ffffffff);
     addr_lo = (u32)((addr64) & 0x00000000ffffffff);
     for ( index = 0; index < count; index += BUF_SIZE){
          len = ((count - index) < BUF_SIZE) ? (count - index) : BUF_SIZE;
          if ( copy_from_user(gpchnl_dev->dma_h2fp, buf+index, len)) {
               PCHNL_ERR("Failed copy from user\n");
               return 0;
          }
          writel(big_endian(addr_lo),
                 gpchnl_dev->hw_addr + 972);
          writel(big_endian(addr_hi),
                 gpchnl_dev->hw_addr + 976);
          writel(big_endian(len),
                 gpchnl_dev->hw_addr + 980);
          writel(big_endian(0xffffffff), gpchnl_dev->hw_addr);
          wait_event_interruptible(wq, flag!= 0);
          if ( copy_to_user(buf+index, gpchnl_dev->dma_f2hp,
                            ((count - index) < BUF_SIZE) ? (count - index) : BUF_SIZE)){
               PCHNL_ERR("Failed copy to user\n");
               return 0;
          }
     }
#endif     
     return count;
}

static ssize_t
pchnl_read(struct file *filp, char *buf, size_t count, loff_t *f_pos)
{
     ssize_t index;
     uint64_t addr64;
     uint32_t addr_hi,addr_lo, len;
     addr64 = (uint64_t)__pa(gpchnl_dev->dma_f2hp);
     addr_hi = (u32)(((addr64) >> 32) & 0x00000000ffffffff);
     addr_lo = (u32)((addr64) & 0x00000000ffffffff);
     for ( index = 0; index < count; index += BUF_SIZE){
          len = ((count - index) < BUF_SIZE) ? (count - index) : BUF_SIZE;
          writel(big_endian(addr_lo),
                 gpchnl_dev->hw_addr + 972);
          writel(big_endian(addr_hi),
                 gpchnl_dev->hw_addr + 976);
          writel(big_endian(len),
                 gpchnl_dev->hw_addr + 980);
          writel(big_endian(0xffffffff), gpchnl_dev->hw_addr);
          wait_event_interruptible(wq, flag!= 0);
          if ( copy_to_user(buf+index, gpchnl_dev->dma_f2hp,
                            ((count - index) < BUF_SIZE) ? (count - index) : BUF_SIZE)){
               PCHNL_ERR("Failed copy to user\n");
               return 0;
          }
     }
     return count;
}

static int
pchnl_ioctl(struct inode *inode, struct file *file, unsigned int cmd, unsigned long arg)
{
     int ret;
     uint32_t offset;
     uint32_t ui32;
     uint64_t ui64;
//     unsigned int counter;
     struct pchnl_req req;
//     int misc;
     if ( (void *)arg != NULL){
          if ( (copy_from_user(&req, (void *)arg, sizeof(req))) ){
               PCHNL_DBG("ioctl: error copy_from_user\n");
               return -EFAULT;
          }
     }
     
     
     ret = -EINVAL;
     switch(cmd){
     case PCHNL_CSR_READ:

          offset = req.u.tranx_csr.idx * 4 + COMM_CSR_BASE_OFFSET;
//          printk("COMM_CSR_READ hw_addr:0x%016lx, offset: %d\n", gpchnl_dev->hw_addr, offset);
          req.u.tranx_csr.val = readl( gpchnl_dev->hw_addr + offset);
          if ( copy_to_user((void *)arg, &req, sizeof(req))){
               PCHNL_DBG("PCHNL_CSR_READ: error copy_to_user\n");
               ret = -EFAULT;
          }else{
               ret = 0;
          }
          PCHNL_DBG("PCHNL_CSR_READ: exit\n");
          break;
     case PCHNL_CSR_WRITE:

          offset = req.u.tranx_csr.idx * 4 + COMM_CSR_BASE_OFFSET;
//          printk("COMM_CSR_WRITE hw_addr:0x%016lx, offset: %d\n", gpchnl_dev->hw_addr, offset);
          writel(req.u.tranx_csr.val, gpchnl_dev->hw_addr + offset);
          ret = 0;
          break;
     case PCHNL_CSR_TESTER:
          //reg#252(or offset 0x50): csr index in csr-tester
          offset = 0X3F0 + SYS_CSR_BASE_OFFSET;
          writel( big_endian(req.u.tranx_csr_tester.idx),
                  gpchnl_dev->hw_addr + offset);

          //reg#19(or offset 0x4C): csr value in csr-tester
          offset = 0X3EC + SYS_CSR_BASE_OFFSET;
          writel( req.u.tranx_csr_tester.val,
                  gpchnl_dev->hw_addr + offset);

          //reg#18(or offset 0x48): start csr tester
          offset = 0X3E8 + SYS_CSR_BASE_OFFSET;
          writel( 0xffffffff,
                  gpchnl_dev->hw_addr + offset);

          ret = 0;
          break;
     case PCHNL_SYS_CSR_WRITE:
          offset = 0X00 + SYS_CSR_BASE_OFFSET;
          writel(req.u.tranx_sys_csr.val,
                 gpchnl_dev->hw_addr + offset);
          ret = 0;
          break;
     case PCHNL_SYS_CSR_READ:
          offset = 0X04 + SYS_CSR_BASE_OFFSET;
          req.u.tranx_sys_csr.val = readl( gpchnl_dev->hw_addr + offset);
          if ( copy_to_user((void *)arg, &req, sizeof(req))){
               ret = -EFAULT;
          }else{
               ret = 0;
          }
          ret = 0;
          break;
     case PCHNL_INTR_TESTER:
          offset = 0x3F4 + SYS_CSR_BASE_OFFSET;
          writel(0xffffffff,
                 gpchnl_dev->hw_addr + offset);
          ret = 0;
          break;
     case PCHNL_DMA_H2F:
          if (copy_from_user(gpchnl_dev->dma_h2fp, req.u.tranx_dma.datap,
                             req.u.tranx_dma.len)){
               PCHNL_ERR("failed to copy from user\n");
               ret = -EFAULT;
          }
          
          ui64 = (uint64_t)__pa(gpchnl_dev->dma_h2fp);
          ui32 = (uint32_t)(ui64 & 0x00000000ffffffff);
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 960);
          ui32 = (uint32_t)((ui64 >> 32) & 0x00000000ffffffff);
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 964);
          ui32 = req.u.tranx_dma.len;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 968);
          ui32 = req.u.tranx_dma.loop_count;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 984);
          ui32 = 0xffffffff;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 1020);
          wait_event_interruptible(wq, flag!=0);
          flag = 0;
          ret = 0;
          break;
     case PCHNL_DMA_F2H:
          ui64 = (uint64_t) __pa(gpchnl_dev->dma_f2hp);
          ui32 = (uint32_t)(ui64 & 0x00000000ffffffff);
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 972);
          ui32 = (uint32_t)((ui64 >> 32) & 0x00000000ffffffff);
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 976);
          ui32 = req.u.tranx_dma.len;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 980);
          ui32 = req.u.tranx_dma.loop_count;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 984);
          ui32 = 0xffffffff;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 1020);

          wait_event_interruptible(wq, flag!=0);
          flag = 0;
          
          if (copy_to_user(req.u.tranx_dma.datap, gpchnl_dev->dma_f2hp,
                           req.u.tranx_dma.len)){
               PCHNL_ERR("failed to copy to user\n");
               ret = -EFAULT;
          }
          ret = 0;
          break;
     case PCHNL_SET_INTR_REG:
          gpchnl_drv->usr_intr_reg_p = req.u.tranx_set_intr_reg.intr_reg_p;
          ret = 0;
          break;
     case PCHNL_DMA_DUPLEX:
          if ( req.u.tranx_dma_duplex.h2f_datap != NULL){
#if 0
               if (copy_from_user(gpchnl_dev->dma_h2fp, req.u.tranx_dma_duplex.h2f_datap,
                                  req.u.tranx_dma_duplex.h2f_len)){
                    PCHNL_ERR("failed to copy from user\n");
                    ret = -EFAULT;
               }
#endif
               ui64 = (uint64_t)__pa(gpchnl_dev->dma_h2fp);
               ui32 = (uint32_t)(ui64 & 0x00000000ffffffff);
               writel(big_endian(ui32),
                      gpchnl_dev->hw_addr + 960);
               ui32 = (uint32_t)(((ui64 >> 32)) & 0x00000000ffffffff);
               writel(big_endian(ui32),
                      gpchnl_dev->hw_addr + 964);
          }else{
               writel(0, gpchnl_dev->hw_addr + 960);
               writel(0, gpchnl_dev->hw_addr + 964);
          }
          
          ui32 = req.u.tranx_dma_duplex.h2f_len;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 968);

          if ( req.u.tranx_dma_duplex.f2h_datap != NULL){
               
               ui64 = (uint64_t) __pa(gpchnl_dev->dma_f2hp);
               ui32 = (uint32_t)(ui64 & 0x00000000ffffffff);
               writel(big_endian(ui32),
                      gpchnl_dev->hw_addr + 972);
               ui32 = (uint32_t)((ui64 >> 32) & 0x00000000ffffffff);
               writel(big_endian(ui32),
                      gpchnl_dev->hw_addr + 976);
          }else{
               writel(0, gpchnl_dev->hw_addr + 972);
               writel(0, gpchnl_dev->hw_addr + 976);
          }
          
          ui32 = req.u.tranx_dma_duplex.f2h_len;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 980);
          ui32 = req.u.tranx_dma_duplex.loop_count;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 984);
          ui32 = 0xffffffff;
          writel(big_endian(ui32),
                 gpchnl_dev->hw_addr + 1020);
          wait_event_interruptible(wq, flag!=0);
          flag = 0;
          if ( req.u.tranx_dma_duplex.f2h_datap != NULL){
#if 0
               if (copy_to_user(req.u.tranx_dma_duplex.f2h_datap, gpchnl_dev->dma_f2hp,
                                req.u.tranx_dma_duplex.f2h_len)){
                    PCHNL_ERR("failed to copy to user\n");
                    ret = -EFAULT;
               }
#endif
          }
          
          ret = 0;

          break;
     case PCHNL_RESET:
          writel(0xffffffff, gpchnl_dev->hw_addr + 12);
          /*
          while (1){
               ui32 = readl(gpchnl_dev->hw_addr + 12);
               if ( ui32 == 0 )
                    break;
          }
          */
          ret = 0;
          break;
     }
     PCHNL_DBG("ioctl: ret %d\n", ret);
     return ret;
}

static int
pchnl_mmap(struct file *filp, struct vm_area_struct *vma)
{
     unsigned long off = vma->vm_pgoff << PAGE_SHIFT;
//     unsigned long paddr = gpchnl_dev->io_base + off;
     unsigned long vsize = vma->vm_end - vma->vm_start;
     unsigned long psize = CSR_REGION_SIZE - off;

     vma->vm_pgoff = ( (u32)gpchnl_dev->io_base >> PAGE_SHIFT);
     

     if ( vsize > psize)
          return -EINVAL;
     printk("off: %ld, vsize: %ld, psize: %ld\n", off, vsize, psize);
     
#if 1
#if LINUX_VERSION_CODE > KERNEL_VERSION(2,6,9)
     return remap_pfn_range(vma, vma->vm_start, vma->vm_pgoff,
                            vsize, vma->vm_page_prot);
#else
     return remap_page_range(vma, vma->vm_start, vma->vm_pgoff << PAGE_SHIFT,
                             vsize, vma->vm_page_prot);
#endif
#endif
}


static uint32_t big_endian(uint32_t little)
{
     return ((little & 0xff) << 24) |
          ((little & 0xff00) << 8) |
          ((little & 0xff0000) >> 8) |
          ((little & 0xff000000) >> 24);
}
