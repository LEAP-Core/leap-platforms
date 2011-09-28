#ifndef _PCHNL_MAIN_H_
#define _PCHNL_MAIN_H_

#include <linux/stddef.h>
#include <linux/module.h>
#include <linux/types.h>
#include <asm/byteorder.h>
#include <asm/msr.h>
#include <linux/init.h>
#include <linux/mm.h>
#include <linux/errno.h>
#include <linux/ioport.h>
#include <linux/pci.h>
#include <linux/kernel.h>
#include <linux/delay.h>
#include <linux/timer.h>
#include <linux/slab.h>
#include <linux/interrupt.h>
#include <linux/string.h>
#include <linux/pagemap.h>
#include <asm/bitops.h>
#include <asm/io.h>
#include <asm/irq.h>
#include <linux/capability.h>
#include <linux/list.h>
#include <linux/reboot.h>
#include <linux/miscdevice.h>
#include <linux/fs.h>
#include <linux/poll.h>
#include <linux/moduleparam.h>
#include <linux/version.h>
#include <asm/uaccess.h>

// Fix compile for old kernels

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,18)
#define IRQF_SHARED                    SA_SHIRQ
#endif /* < 2.6.18 */

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,18)
#define IRQF_SAMPLE_RANDOM             SA_SAMPLE_RANDOM
#endif /* < 2.6.18 */

#if LINUX_VERSION_CODE < KERNEL_VERSION(2,6,18)
#define pci_register_driver            pci_init_module
#endif /* < 2.6.18 */


#ifdef DBG
#define PCHNL_DBG(args...) printk(KERN_DEBUG "pchnl: " args)
#else
#define PCHNL_DBG(args...)
#endif

#define PCHNL_ERR(args...) printk(KERN_ERR "pchnl: " args)

#define BAR_0 0
#define PCI_DMA_64BIT	0xffffffffffffffffULL
#define PCI_DMA_32BIT	0x00000000ffffffffULL

struct pchnl_driver;
struct pchnl_device;

struct pchnl_device 
{
     struct pci_dev *pdev;
     uint8_t *hw_addr;
     unsigned long io_base;
     void *dma_h2fp;
     struct page *h2f_pg_base;
     struct page *f2h_pg_base;
     void *dma_f2hp;
};

struct pchnl_driver
{
     struct miscdevice miscdev;
     char *name;
     unsigned int intr_count;
     unsigned int * usr_intr_reg_p;
};


#endif
