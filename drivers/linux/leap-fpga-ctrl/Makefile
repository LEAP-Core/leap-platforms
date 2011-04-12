PREFIX =

CFLAGS = -O2
CPPFLAGS = -DPREFIX='"$(PREFIX)"'

all: leap-fpga-ctrl

leap-fpga-ctrl: leap-fpga-ctrl.o iniparser.o dictionary.o

.PHONY install:
install:
	mkdir -p $(PREFIX)/usr/bin $(PREFIX)/etc/leap/scripts $(PREFIX)/var/lock/leap
	install --owner=root --group=root --mode=4555 leap-fpga-ctrl $(PREFIX)/usr/bin
	install --owner=root --group=root --mode=444 config-sample $(PREFIX)/etc/leap
	install --owner=root --group=root --mode=554 scripts/HTG-V5-PCIe /etc/leap/scripts
	install --owner=root --group=root --mode=554 init-leap-fpga /etc/init.d/leap-fpga
	chkconfig leap-fpga on

.PHONY clean:
clean:
	@rm -rf *.o
	@rm -rf leap-fpga-ctrl


dictionary.o: dictionary.h
iniparser.o: iniparser.h
leap-fpga-ctrl.o: iniparser.h dictionary.h
