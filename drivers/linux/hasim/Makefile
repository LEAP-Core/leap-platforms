PREFIX = /usr/hasim

CFLAGS = -O2
CPPFLAGS = -DPREFIX='"$(PREFIX)"'

all: leap-fpga-ctrl driver

leap-fpga-ctrl: leap-fpga-ctrl.o

.PHONY driver:
driver:
	@unset ARCH; \
	PATH=/usr/bin:$$PATH; \
	cd kernel; \
	$(MAKE) $(MFLAGS)

.PHONY install:
install:
	mkdir -p $(PREFIX)/bin $(PREFIX)/dev $(PREFIX)/kernel $(PREFIX)/reservations $(PREFIX)/local
	install --owner=root --group=root --mode=4555 leap-fpga-ctrl $(PREFIX)/bin
	install --owner=root --group=root --mode=555 init-leap-fpga /etc/init.d/leap-fpga
	chkconfig hasim-fpga on
	install kernel/pchnl.ko $(PREFIX)/kernel
	cp -f README.dev $(PREFIX)/dev/README

.PHONY clean:
clean:
	@rm -rf *.o
	@rm -rf leap-fpga-ctrl
	@(cd kernel; $(MAKE) $(MFLAGS) clean)
