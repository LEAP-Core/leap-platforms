# Copyright (c) 2003 Xilinx, Inc.  All rights reserved. 
# 
# Xilinx, Inc. 
# XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS" AS A 
# COURTESY TO YOU.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION AS 
# ONE POSSIBLE   IMPLEMENTATION OF THIS FEATURE, APPLICATION OR 
# STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS IMPLEMENTATION 
# IS FREE FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE RESPONSIBLE 
# FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE FOR YOUR IMPLEMENTATION. 
# XILINX EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH RESPECT TO 
# THE ADEQUACY OF THE IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO 
# ANY WARRANTIES OR REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE 
# FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY 
# AND FITNESS FOR A PARTICULAR PURPOSE. 
#

ARCH = LINUX
VER = $(shell uname -r)
OD = $(ARCH).$(VER)

ARCH_64BIT = $(shell arch | grep -c "64")

INCLUDEDIR = /lib/modules/$(VER)/build/include

KERNELDIR = /usr/src/linux-2.4

#include $(KERNELDIR)/.config

INSTALLDIR = /lib/modules/$(shell uname -r)/kernel/drivers/misc

CFLAGS = -O -I$(INCLUDEDIR) -I$(KERNELDIR)/include -Wall

ifdef CONFIG_SMP
 CFLAGS += -D__SMP__ -DSMP
endif

ifeq ($(ARCH_64BIT),1)
CFLAGS += -mcmodel=kernel
endif
	
GCC_VERSION = $(shell cat /proc/version | sed -e "s/.*gcc version \([0-9]\).*/\1/")
ifeq (3, $(GCC_VERSION))
ifeq ($(ARCH_64BIT),0)
       LIBS = ioctl_3.a
else
       LIBS = ioctl_3_64.a
endif
else
       LIBS = ioctl_2.a
endif

EXECDIR = $(shell pwd)

OBJS = xpc4drvr.o

all: $(OD) $(OBJS)

$(OD):
	-@ mkdir $@ &

$(OD)/xpc4.o: xpc4.c
	$(CC) $(CFLAGS) -c -o $@ $<

xpc4drvr.o: $(OD)/xpc4.o $(LIBS)
	$(LD) -r $^ -o $(OD)/$@

install: 
	echo Installing to $(INSTALLDIR)
	mkdir -p $(INSTALLDIR)
	cp -pf $(OD)/xpc4drvr.o $(INSTALLDIR)
	cp -pf install_drv $(INSTALLDIR)/install_xpc4drvr
	$(INSTALLDIR)/install_xpc4drvr

clean:
	rm -f $(OD)/*.o core

# End of makefile
