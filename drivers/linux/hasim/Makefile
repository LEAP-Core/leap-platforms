PREFIX = /usr/hasim

CFLAGS = -O2

all: hasim-fpga-ctrl driver

hasim-fpga-ctrl: hasim-fpga-ctrl.o

.PHONY driver:
driver:
	@unset ARCH; \
	PATH=/usr/bin:$$PATH; \
	cd kernel; \
	$(MAKE) $(MFLAGS)

.PHONY install:
install:
	mkdir -p $(PREFIX)/bin $(PREFIX)/dev $(PREFIX)/kernel $(PREFIX)/reservations
	install --owner=root --group=root --mode=4555 hasim-fpga-ctrl $(PREFIX)/bin
	install kernel/pchnl.ko $(PREFIX)/kernel

.PHONY clean:
clean:
	@rm -rf *.o
	@rm -rf hasim-fpga-ctrl
	@(cd kernel; $(MAKE) $(MFLAGS) clean)
