
default: bluenoc-ioctl

bluenoc-ioctl: bluenoc-ioctl.c 
	gcc -I../driver/ -o bluenoc-ioctl bluenoc-ioctl.c 

.PHONY: install
install: bluenoc-ioctl
	install -m755 bluenoc-ioctl /usr/local/bin/

.PHONY: clean
clean:
	rm -f bluenoc-ioctl
