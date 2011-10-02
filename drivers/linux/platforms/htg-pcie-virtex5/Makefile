#
# Makefile for PCIe Hardware Channel Driver
#
CFLAGS = -O2

ifneq ($(KERNELRELEASE),)


#EXTRA_CFLAGS		+= -DDBG
EXTRA_CFLAGS		+= -I$(PWD)

PACCL_MOD			:= pchnl
obj-m				+= $(PACCL_MOD).o
$(PACCL_MOD)-objs	:= pchnl_main.o

else

KDIR	:= /lib/modules/$(shell uname -r)/build


default:
	@unset ARCH; \
	PATH=/usr/bin:$$PATH; \
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean

endif
