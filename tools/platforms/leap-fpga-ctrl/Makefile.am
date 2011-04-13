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
	mkdir -p $(bindir) $(sysconfdir)/leap $(datarootdir)/leap/scripts $(localstatedir)/lock/leap
	install --owner=root --group=root --mode=4555 leap-fpga-ctrl $(bindir)
	install --owner=root --group=root --mode=444 config-sample $(sysconfdir)/leap
	install --owner=root --group=root --mode=554 scripts/HTG-V5-PCIe $(datarootdir)/leap/scripts
	install --owner=root --group=root --mode=554 init-leap-fpga /etc/init.d/leap-fpga
#chkconfig leap-fpga on

