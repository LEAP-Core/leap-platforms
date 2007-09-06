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

#ifndef _XPC4_H
#define _XPC4_H

#if defined(__cplusplus)
    extern "C" {
#endif

#ifndef XPC4_MAJOR
#define XPC4_MAJOR 0   // dynamic major by default 
#endif

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

#ifndef PORT_DATA_DEFINED
#define PORT_DATA_DEFINED
typedef struct PortData
{
	int PortNumber;
    unsigned long BaseAddress;
    unsigned long EcpBaseAddress ;
    unsigned long FifoSize ;  
	unsigned long StartSecCount;
	unsigned long TimeRemaining; // in seconds
	struct timer_list* Timer;
} PortData;
#endif

#ifndef IO_ADDR_COUNT_DEFINED
#define IO_ADDR_COUNT_DEFINED
#define IO_ADDR_COUNT				3
#endif

int XPC4_access_ok(int type, const void *addr, unsigned long size);
unsigned long XPC4_copy_from_user(void * to, const void * from, unsigned long count);
int XPC4_printk(const char *fmt, ...);
unsigned char XPC4_inb(unsigned port);
void XPC4_outb(unsigned char value, unsigned port);
unsigned long XPC4_copy_to_user(void * to, const void * from, unsigned long count);
struct resource *XPC4_request_region (unsigned long first, unsigned long n, const char* name);
int xpc4_ioctl2 (void* data, unsigned int cmd, unsigned long arg);

void xpc4_start_timer (PortData* pPortData, unsigned long seconds);
void xpc4_stop_timer (PortData* pPortData);
int xpc4_is_timeout (PortData* pPortData);

#if defined(__cplusplus)
    }
#endif
    
#endif //_XPC4_H
