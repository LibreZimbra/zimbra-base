# SPDX-License-Identifier: AGPL-3.0-or-later

all:

include build.mk

install:
	$(call mk_install_dir,/)
	cp -R include $(INSTALL_DIR)

clean:
