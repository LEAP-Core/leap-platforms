PREFIX = /usr/hasim

CFLAGS = -O2
CPPFLAGS = -DPREFIX='"$(PREFIX)"'

all: leap-fpga-ctrl

leap-fpga-ctrl: leap-fpga-ctrl.o

.PHONY install:
install:
	mkdir -p $(PREFIX)/bin $(PREFIX)/dev $(PREFIX)/reservations $(PREFIX)/local
	install --owner=root --group=root --mode=4555 leap-fpga-ctrl $(PREFIX)/bin
	install --owner=root --group=root --mode=555 init-leap-fpga /etc/init.d/leap-fpga
	chkconfig leap-fpga on
	cp -f README.dev $(PREFIX)/dev/README

.PHONY clean:
clean:
	@rm -rf *.o
	@rm -rf leap-fpga-ctrl
