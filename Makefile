# SPDX-License-Identifier: AGPL-3.0-or-later

include version.mk

all:

include build.mk

install:
	$(call mk_install_dir,/)
	cp -R include $(INSTALL_DIR)
	$(call install_libexec,src/zm-util-base.sh)
	$(call install_libexec,src/zm-load-localconfig.sh)

clean:
