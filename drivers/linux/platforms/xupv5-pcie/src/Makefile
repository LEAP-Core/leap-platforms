# use linux kernel 2.6 module kbuild system

ifndef KERNELDIR
# make sure it's a properly configured and made kernel source tree.
# simply untarred tree won't do. If working with vendor kernel,
# look to install things along the line of kernel-devel 
KERNELVER=$(shell uname -r)
KERNELDIR=/lib/modules/$(KERNELVER)/build/
endif

DRV_DIR=$(shell pwd)

dndev.ko: main.c
	$(MAKE) -C $(KERNELDIR) SUBDIRS=$(DRV_DIR) modules

obj-m := bsemu.o
bsemu-objs := main.o

clean:
	rm -rf *~ *.o core .depend .*.cmd *.ko *.mod.c .tmp_versions
	rm -f Module.markers modules.order Module.symvers
