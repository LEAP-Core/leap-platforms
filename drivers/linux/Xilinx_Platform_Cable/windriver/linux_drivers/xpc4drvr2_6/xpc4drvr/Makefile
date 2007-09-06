# Copyright (c) 2005 Xilinx, Inc.  All rights reserved. 
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

# Run ./configure first, to generate regparm_option
REG_PARM = $(shell grep -c "regparm=3" $(PWD)/regparm_option)
SYM_FILE_DIR = /lib/modules/$(shell uname -r)/build
GET_USER_SIZE_SYM = $(shell grep -c "get_user_size" $(SYM_FILE_DIR)/Module.symvers)
ARCH_64BIT = $(shell arch | grep -c "64")
ifeq ($(ARCH_64BIT),1)
CFLAGS += -mcmodel=kernel
endif
ifeq ($(GET_USER_SIZE_SYM),0)
CFLAGS += -DNO_GET_USER_SIZE
endif

ifeq ($(ARCH_64BIT),0)
IOCTL_A = ioctl_3.a
ifneq ($(REG_PARM),0)
IOCTL_A = ioctl_3_regparm.a
endif
else
IOCTL_A = ioctl_3_64.a
ifneq ($(REG_PARM),0)
IOCTL_A = ioctl_3_regparm_64.a
endif
endif

ifneq ($(KERNELRELEASE),)

	obj-m	:= xpc4drvr.o

xpc4drvr-objs := xpc4.o $(IOCTL_A) 

else
	KDIR	:= /lib/modules/$(shell uname -r)/build
	PWD	:= $(shell pwd)

    default:
	@echo Ioctl library = $(IOCTL_A).
	$(MAKE) -C $(KDIR) M=$(PWD) modules

endif

INSTALLDIR = /lib/modules/$(shell uname -r)/kernel/drivers/misc
install: 
	echo Installing to $(INSTALLDIR)
	mkdir -p $(INSTALLDIR)
	cp xpc4drvr.ko $(INSTALLDIR)
	cp -p install_drv $(INSTALLDIR)/install_xpc4drvr
	$(INSTALLDIR)/install_xpc4drvr

clean:
	rm -f *.o *.ko core

# End of makefile
