// Copyright (c) 2003 Xilinx, Inc.  All rights reserved. 
// 
// Xilinx, Inc. 
// XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
// COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
// ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
// STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
// IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
// FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
// XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
// THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
// ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
// FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
// AND FITNESS FOR A PARTICULAR PURPOSE. 
//
// Version 1.041

#ifndef __KERNEL__
#define __KERNEL__
#endif

#define MODULE
#include <linux/config.h>
#ifdef CONFIG_SMP
#define __SMP__
#endif

#if defined(CONFIG_MODVERSIONS) && !defined(MODVERSIONS)
#define MODVERSIONS
#endif

#ifdef MODVERSIONS
#include <linux/modversions.h>
#endif

#include <linux/kernel.h>
#include <linux/module.h> 
#include <linux/sched.h>
#include <linux/kmod.h>
#include <linux/init.h>
#include <asm/io.h> 
#include <linux/slab.h>
#include <asm/uaccess.h>

#include "xpc4.h"

#ifndef LINUX_VERSION_CODE
#  include <linux/version.h>
#endif

#ifndef VERSION_CODE
#  define VERSION_CODE(vers,rel,seq) ( ((vers)<<16) | ((rel)<<8) | (seq) )
#endif

#if LINUX_VERSION_CODE < VERSION_CODE(2,4,0) /* not < 2.4 */
#  error "This kernel is not supported by this module"
#endif

#if defined(MODULE_LICENSE)
	MODULE_LICENSE("Proprietary");
#endif

char XPC4DRVR_VERSION [32] = "Xpc4drvr v1041";

void *XPC4_kmalloc(unsigned int size)
{
    return (kmalloc((size_t) size, GFP_KERNEL));
}

void XPC4_kfree(void *addr)
{
    kfree ((const void *)addr);
}

int XPC4_access_ok(int type, const void *addr, unsigned long size)
{
	int accessType = VERIFY_READ;
	if (type != 0)
	{
		accessType = VERIFY_WRITE;
	}
	return (access_ok (accessType, addr, size));
}

unsigned long XPC4_copy_from_user(void *to, const void *from, unsigned long count)
{
	return (copy_from_user (to, from, count));			
}

int XPC4_printk(const char *fmt, ...)
{
	int result;
	int a [8];
	int i;
	va_list args;
	va_start (args, fmt);
	for (i=0; i<sizeof(a)/sizeof(*a); i++)
	{
		a[i] = va_arg (args, int);
	}
	result = printk (fmt, a[0], a[1], a[2], a[3], a[4], a[5], a[6], a[7]);
	va_end (args);
	return (result);
}

struct timer_list timerList [10];

void XPC4_add_timer(struct timer_list *timer)
{
	add_timer(timer);
}

void XPC4_init_timer(struct timer_list *timer)
{
	init_timer(timer);
}

int XPC4_del_timer_sync(struct timer_list *timer)
{
	return (del_timer_sync(timer));
}
    
int XPC4_mod_timer(struct timer_list *timer, unsigned long expires)
{
	return (mod_timer(timer, expires));
}
    
unsigned char XPC4_inb(unsigned port)
{
	unsigned char data = inb (port);
	rmb ();
	return (data);
}

void XPC4_outb(unsigned char value, unsigned port)
{
	outb (value, port);
	wmb ();
}

void *XPC4_memset(void *adrr ,int s, size_t count)
{
	return (memset(adrr, s, count));
}

unsigned long XPC4_get_expire_time ()
{
	return (jiffies + HZ);
}

int xpc4_major = XPC4_MAJOR;

int xpc4_open (struct inode *inode, struct file *filp)
{
	int num = MINOR(inode->i_rdev);
	printk(KERN_INFO "xpc4drvr%d: open device.\n", num);
	xpc4_init_data (num, filp);
	MOD_INC_USE_COUNT; 
	return 0;
}

int xpc4_release (struct inode *inode, struct file *filp)
{
	int num = MINOR(inode->i_rdev);
	printk(KERN_INFO "xpc4drvr%d: release device.\n", num);
	xpc4_release_data (filp);
	MOD_DEC_USE_COUNT;
	return 0;
}

int xpc4_ioctl (struct inode *inode, struct file *filp,
                 unsigned int cmd, unsigned long arg)
{
	int ret = 0;
	int err = 0;		
	void* dataPtr;
    
    /*
     * extract the type and number bitfields, and don't decode
     * wrong cmds: return ENOTTY (inappropriate ioctl) before access_ok()
     */
    if (_IOC_TYPE(cmd) != 'k') return -ENOTTY;

    /*
     * the direction is a bitmask, and VERIFY_WRITE catches R/W
     * transfers. `Type' is user-oriented, while
     * access_ok is kernel-oriented, so the concept of "read" and
     * "write" is reversed
     */
	if (_IOC_DIR(cmd) & _IOC_READ)
		err = !access_ok(VERIFY_WRITE, (void *)arg, _IOC_SIZE(cmd));
	else if (_IOC_DIR(cmd) & _IOC_WRITE)
		err =  !access_ok(VERIFY_READ, (void *)arg, _IOC_SIZE(cmd));
	if (err) return -EFAULT;

	dataPtr = filp->private_data;

	ret = xpc4_ioctl2 (dataPtr, cmd, arg);

	return ret;
}

struct file_operations xpc4_fops = {
	ioctl:      xpc4_ioctl,
	open:       xpc4_open,
	release:    xpc4_release,
};

int xpc4drvr_init_module (void)
{
	int result;

	printk(KERN_INFO "xpc4drvr: init_module\n");

	SET_MODULE_OWNER (&xpc4_fops);

	result = register_chrdev (xpc4_major, "xpc4drvr", &xpc4_fops);
	if (result < 0)
	{
		printk(KERN_EMERG "xpc4drvr: can't get major %d\n", xpc4_major);
		return result;
	}
	if (xpc4_major == 0) xpc4_major = result; /* dynamic */
	{
		request_module ("parport_lowlevel");
		return (0);
	}
}

void xpc4drvr_cleanup_module (void)
{
	printk(KERN_INFO "xpc4drvr: cleanup_module\n");
	unregister_chrdev (xpc4_major, "xpc4drvr");
}

module_init (xpc4drvr_init_module);
module_exit (xpc4drvr_cleanup_module);

// End of file.
