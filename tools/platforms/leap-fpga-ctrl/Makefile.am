#
# Copyright (C) 2003-2006 Intel Corporation
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
# 
#

bin_PROGRAMS = leap-fpga-ctrl
leap_fpga_ctrl_SOURCES = leap-fpga-ctrl.c iniparser.c dictionary.c
AM_CPPFLAGS = -DBINDIR='"$(bindir)"' -DCONFDIR='"$(sysconfdir)/leap"' -DSCRIPTSDIR='"$(datarootdir)/leap/scripts"' -DLOCKDIR='"$(localstatedir)/lock/leap"' 

.PHONY install-arch:
install-arch: install

.PHONY install:
install:
	mkdir -p $(DESTDIR)$(bindir)
	install --owner=root --group=root --mode=4555 leap-fpga-ctrl $(DESTDIR)$(bindir)
	mkdir -p $(DESTDIR)$(datarootdir)/leap/drivers
	mkdir -p $(DESTDIR)$(datarootdir)/leap/scripts
	mkdir -p $(DESTDIR)$(datarootdir)/leap/state
	install --owner=root --group=root --mode=554 scripts/VC707 $(DESTDIR)$(datarootdir)/leap/scripts
	mkdir -p $(DESTDIR)$(sysconfdir)/leap
	install --owner=root --group=root --mode=444 etc/config-sample $(DESTDIR)$(sysconfdir)/leap
	mkdir -p $(DESTDIR)$(sysconfdir)/init.d
	install --owner=root --group=root --mode=554 init/leap-fpga $(DESTDIR)$(sysconfdir)/init.d/leap-fpga
	mkdir -p $(DESTDIR)$(localstatedir)/lock/leap
#chkconfig leap-fpga on	


