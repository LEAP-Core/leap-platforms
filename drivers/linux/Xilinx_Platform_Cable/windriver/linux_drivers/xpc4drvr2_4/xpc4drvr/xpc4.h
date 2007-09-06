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
// Version 1.01

#ifndef _XPC4_H
#define _XPC4_H

#include <linux/timer.h>
#include <linux/fs.h>

#if defined(__cplusplus)
    extern "C" {
#endif

#ifndef XPC4_MAJOR
#define XPC4_MAJOR 0   // dynamic major by default 
#endif

int XPC4_access_ok(int type, const void *addr, unsigned long size);
unsigned long XPC4_copy_from_user(void * to, const void * from, unsigned long count);
int XPC4_printk(const char *fmt, ...);
void XPC4_add_timer(struct timer_list *timer);
int XPC4_mod_timer(struct timer_list *timer, unsigned long expires);
void XPC4_init_timer(struct timer_list *timer);
int XPC4_del_timer_sync(struct timer_list *timer);
unsigned char XPC4_inb(unsigned port);
void XPC4_outb(unsigned char value, unsigned port);
void *XPC4_memset(void *adrr ,int s, size_t count);
void *XPC4_kmalloc(unsigned int size);
void XPC4_kfree(void *addr);
unsigned long XPC4_get_expire_time ();
void xpc4_init_data (int portNumber, struct file* filp);
void xpc4_release_data (struct file* filp);
int xpc4_ioctl2 (void* data, unsigned int cmd, unsigned long arg);

#if defined(__cplusplus)
    }
#endif
    
#endif //_XPC4_H
