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
static unsigned int intr_count = 0;

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
//  .mmap     = pchnl_mmap,
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
     unsigned long mmio_start;
     int mmio_len;
     int pci_using_dac;
     int err;
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

     mmio_start = pci_resource_start(pdev, BAR_0);
     mmio_len = pci_resource_len(pdev, BAR_0);

     gpchnl_dev->hw_addr = ioremap(mmio_start, mmio_len);
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

     PCHNL_DBG("pchnl_remove enter\n");

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
//     uint32_regs reg32;

     PCHNL_DBG("pchnl_intr enter\n");

     writel(0xffffffff, gpchnl_dev->hw_addr + 0x08);
     printk("INTR-TEST: we receive interrupt - %d\ttimes\n", ++intr_count);
     
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

static int
pchnl_ioctl(struct inode *inode, struct file *file, unsigned int cmd, unsigned long arg)
{
     int ret;
     uint32_t offset;
     struct pchnl_req req;
     
     if ( copy_from_user(&req, (void *)arg, sizeof(req)))
          return -EFAULT;
     
     ret = -EINVAL;
     switch(cmd){
     case PCHNL_CSR_READ:

          offset = req.u.tranx_csr.idx * 4 + COMM_CSR_BASE_OFFSET;
//          printk("COMM_CSR_READ hw_addr:0x%016lx, offset: %d\n", gpchnl_dev->hw_addr, offset);
          req.u.tranx_csr.val = readl( gpchnl_dev->hw_addr + offset);
          if ( copy_to_user((void *)arg, &req, sizeof(req))){
               ret = -EFAULT;
          }else{
               ret = 0;
          }
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
     }

     

     return ret;
}

static uint32_t big_endian(uint32_t little)
{
     return ((little & 0xff) << 24) |
          ((little & 0xff00) << 8) |
          ((little & 0xff0000) >> 8) |
          ((little & 0xff000000) >> 24);
}
