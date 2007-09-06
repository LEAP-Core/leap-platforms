// Copyright (c) 2005 Xilinx, Inc.  All rights reserved. 
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
// Version 1.02

#include <linux/kernel.h>
#include <linux/module.h> 
#include <linux/init.h>
#include <asm/io.h> 
#include <asm/uaccess.h>
#include <linux/ioport.h>
#include <linux/timer.h>
#include <linux/fs.h>

#include "xpc4.h"

#ifndef LINUX_VERSION_CODE
#  include <linux/version.h>
#endif

#ifndef VERSION_CODE
#  define VERSION_CODE(vers,rel,seq) ( ((vers)<<16) | ((rel)<<8) | (seq) )
#endif

#if LINUX_VERSION_CODE < VERSION_CODE(2,6,0) /* not < 2.6 */
#  error "This kernel is not supported by this module"
#endif

MODULE_LICENSE("Proprietary");

char XPC4DRVR_VERSION [32] = "Xpc4drvr v1041";

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

unsigned long XPC4_copy_to_user(void *to, const void *from, unsigned long count)
{
	return (copy_to_user (to, from, count));			
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

unsigned long XPC4_get_expire_time (void)
{
	return (jiffies + HZ);
}

int xpc4_major = XPC4_MAJOR;

void xpc4_init_data (int portNumber, struct file* filp)
{
	PortData* pPortData;

	// allocate private data
	filp->private_data = kmalloc (sizeof(PortData), GFP_KERNEL);
	memset(filp->private_data, 0, sizeof(PortData));

	pPortData = filp->private_data;
	pPortData->PortNumber = portNumber;
	pPortData->BaseAddress = -1;
	pPortData->EcpBaseAddress = -1;
	//pPortData->Timer = &(timerList [portNumber]);
	pPortData->Timer = kmalloc (sizeof(struct timer_list), GFP_KERNEL);
}

void xpc4_release_data (struct file *filp)
{
	PortData* pPortData = filp->private_data;

	printk(KERN_INFO "xpc4drvr%d: release device.\n", pPortData->PortNumber);

	// release io ports
	if (pPortData->EcpBaseAddress != -1)
	{
		release_region (pPortData->EcpBaseAddress, IO_ADDR_COUNT);
	}
	if (pPortData->BaseAddress != -1)
	{
		release_region (pPortData->BaseAddress, IO_ADDR_COUNT);
	}
	if (pPortData->Timer)
	{
		kfree (pPortData->Timer);
	}
	// release port data
	if (filp->private_data)
	{
		kfree (filp->private_data);
	}
}

int xpc4_open (struct inode *inode, struct file *filp)
{
	int num = MINOR(inode->i_rdev);
	printk(KERN_INFO "xpc4drvr%d: open device.\n", num);
	xpc4_init_data (num, filp);
	return 0;
}

int xpc4_release (struct inode *inode, struct file *filp)
{
	int num = MINOR(inode->i_rdev);
	printk(KERN_INFO "xpc4drvr%d: release device.\n", num);
	xpc4_release_data (filp);
	return 0;
}

int xpc4_ioctl (struct inode *inode, struct file *filp,
                 unsigned int cmd, unsigned long arg)
{
	int ret = 0;
	int err = 0;		
	void* dataPtr;
    
	if (_IOC_TYPE(cmd) != 'k') return -ENOTTY;

	if (_IOC_DIR(cmd) & _IOC_READ)
		err = !access_ok(VERIFY_WRITE, (void *)arg, _IOC_SIZE(cmd));
	else if (_IOC_DIR(cmd) & _IOC_WRITE)
		err =  !access_ok(VERIFY_READ, (void *)arg, _IOC_SIZE(cmd));
	if (err) return -EFAULT;

	dataPtr = filp->private_data;

	ret = xpc4_ioctl2 (dataPtr, cmd, arg);

	return ret;
}

void xpc4_timer_timeout (unsigned long arg)
{
	PortData* pPortData = (PortData*)arg;
	if (pPortData->TimeRemaining != -1)  // timer is running
	{
		if (pPortData->TimeRemaining > 0)  // timer is running
		{
			pPortData->TimeRemaining--;
			printk(KERN_INFO "xpc4drvr%d: time remaining = %ld sec.\n", pPortData->PortNumber,
						pPortData->TimeRemaining);
			mod_timer (pPortData->Timer, XPC4_get_expire_time());
		}
	}
}

void xpc4_start_timer (PortData* pPortData, unsigned long seconds)
{
	init_timer (pPortData->Timer);
	pPortData->Timer->function = xpc4_timer_timeout;
	pPortData->Timer->data = (unsigned long)pPortData;
	pPortData->Timer->expires = XPC4_get_expire_time ();
	add_timer (pPortData->Timer);
	pPortData->TimeRemaining = seconds;
}

void xpc4_stop_timer (PortData* pPortData)
{
	pPortData->TimeRemaining = -1;
	del_timer_sync (pPortData->Timer);
}

int xpc4_is_timeout (PortData* pPortData)
{
	int timeout = FALSE;
	if (pPortData->TimeRemaining == 0)
	{
		printk(KERN_INFO "xpc4drvr%d: timeout.\n", pPortData->PortNumber);
		timeout = TRUE;
	}
	return (timeout);
}

#ifdef NO_GET_USER_SIZE
int get_user_size (unsigned int size, void* val, const void* ptr)
{
	return (copy_from_user(val,ptr,(unsigned long)size));
}
#endif

struct resource *XPC4_request_region (unsigned long first, unsigned long n, const char* name)
{
	return (request_region (first, n, name));
}

struct file_operations xpc4_fops = {
	.owner = THIS_MODULE, 
	.ioctl = xpc4_ioctl,
	.open = xpc4_open,
	.release = xpc4_release
};

int xpc4drvr_init_module (void)
{
	int result;

	printk(KERN_INFO "xpc4drvr: init_module\n");

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
