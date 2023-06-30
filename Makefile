.PHONY: all clean distclean dist package

ifeq ($(PREFIX),)
    PREFIX := /usr/local/
endif


DIST_NAME := tmpusb-initramfs
DIST_VERSION := $(shell cat CHANGES.md | head -1 | cut -d" " -f2)
DEB_BUILD_ARCH := all

SOURCE_LIST := Makefile CHANGES.md LICENSE.md README.md package/ src/

HAS_DPKGDEB := $(shell command -v dpkg-deb >/dev/null 2>&1 ; echo $$?)
HAS_FAKEROOT := $(shell command -v fakeroot >/dev/null 2>&1 ; echo $$?)
HAS_LINTIAN := $(shell command -v lintian >/dev/null 2>&1 ; echo $$?)
HAS_UNCOMMITTED := $(shell git diff --quiet 2>/dev/null ; echo $$?)


all: package


clean:
	-@$(RM) -r build/

distclean: clean
	-@$(RM) -r dist/

dist:
	@$(RM) -r build/dist/
	@mkdir -p build/dist/$(DIST_NAME)-$(DIST_VERSION)/
	@cp -r $(SOURCE_LIST) build/dist/$(DIST_NAME)-$(DIST_VERSION)/
	@tar -cz -C build/dist/  --owner=0 --group=0 -f build/dist/$(DIST_NAME)-$(DIST_VERSION).tar.gz $(DIST_NAME)-$(DIST_VERSION)/
	@mkdir -p dist/
	@mv build/dist/$(DIST_NAME)-$(DIST_VERSION).tar.gz dist/
	@echo Output at dist/$(DIST_NAME)-$(DIST_VERSION).tar.gz

package: dist
	$(if $(findstring 0,$(HAS_DPKGDEB)),,$(error Package 'dpkg-deb' not installed))
	$(if $(findstring 0,$(HAS_FAKEROOT)),,$(error Package 'fakeroot' not installed))
	$(if $(findstring 0,$(HAS_LINTIAN)),,$(error Package 'lintian' not installed))
	$(if $(findstring 0,$(HAS_UNCOMMITTED)),,$(warning Uncommitted changes present))
	@echo "Packaging for $(DEB_BUILD_ARCH)"
	@$(eval PACKAGE_NAME = $(DIST_NAME)_$(DIST_VERSION)_$(DEB_BUILD_ARCH))
	@$(eval PACKAGE_DIR = /tmp/$(PACKAGE_NAME)/)
	-@$(RM) -r $(PACKAGE_DIR)/
	@mkdir $(PACKAGE_DIR)/
	@cp -r package/deb/DEBIAN $(PACKAGE_DIR)/
	@sed -i "s/MAJOR.MINOR.PATCH/$(DIST_VERSION)/" $(PACKAGE_DIR)/DEBIAN/control
	@sed -i "s/ARCHITECTURE/$(DEB_BUILD_ARCH)/" $(PACKAGE_DIR)/DEBIAN/control
	@mkdir -p $(PACKAGE_DIR)/usr/share/doc/$(DIST_NAME)/
	@cp package/deb/copyright $(PACKAGE_DIR)/usr/share/doc/$(DIST_NAME)/copyright
	@cp CHANGES.md build/changelog
	@sed -i '/^$$/d' build/changelog
	@sed -i '/## Release Notes ##/d' build/changelog
	@sed -i '1{s/### \(.*\) \[.*/$(DIST_NAME) \(\1\) stable; urgency=low/}' build/changelog
	@sed -i '/###/,$$d' build/changelog
	@sed -i 's/\* \(.*\)/  \* \1/' build/changelog
	@echo >> build/changelog
	@echo ' -- Josip Medved <jmedved@jmedved.com>  $(shell date -R)' >> build/changelog
	@gzip -cn --best build/changelog > $(PACKAGE_DIR)/usr/share/doc/$(DIST_NAME)/changelog.gz
	@find $(PACKAGE_DIR)/ -type d -exec chmod 755 {} +
	@find $(PACKAGE_DIR)/ -type f -exec chmod 644 {} +
	@chmod 755 $(PACKAGE_DIR)/DEBIAN/config
	@chmod 755 $(PACKAGE_DIR)/DEBIAN/postinst
	@chmod 755 $(PACKAGE_DIR)/DEBIAN/postrm
	@install -d $(PACKAGE_DIR)/usr/lib/$(DIST_NAME)/
	@install -m 644 LICENSE.md $(PACKAGE_DIR)/usr/lib/$(DIST_NAME)/LICENSE
	@install -d $(PACKAGE_DIR)/usr/lib/$(DIST_NAME)/backup/
	@install -d $(PACKAGE_DIR)/usr/lib/$(DIST_NAME)/bin/
	@install -m 755 src/initramfs-adjust.sh $(PACKAGE_DIR)/usr/lib/$(DIST_NAME)/bin/tmpusb-zfs-initramfs-adjust
	@install -m 755 src/load-keys.sh $(PACKAGE_DIR)/usr/lib/$(DIST_NAME)/bin/tmpusb-zfs-load-keys
	@install -d $(PACKAGE_DIR)/usr/lib/cryptsetup/scripts
	@install -m 755 src/cryptsetup/scripts/decrypt_tmpusb.sh $(PACKAGE_DIR)/usr/lib/cryptsetup/scripts/decrypt_tmpusb
	@install -d $(PACKAGE_DIR)/usr/share/initramfs-tools/scripts/init-premount/
	@install -m 755 src/initramfs-tools/scripts/init-premount/tmpusb-mount.sh $(PACKAGE_DIR)/usr/share/initramfs-tools/scripts/init-premount/tmpusb-mount
	@install -d $(PACKAGE_DIR)/usr/share/initramfs-tools/scripts/init-bottom/
	@install -m 755 src/initramfs-tools/scripts/init-bottom/tmpusb-umount.sh $(PACKAGE_DIR)/usr/share/initramfs-tools/scripts/init-bottom/tmpusb-umount
	@install -d $(PACKAGE_DIR)/usr/share/initramfs-tools/hooks
	@install -m 755 src/initramfs-tools/hooks/decrypt_tmpusb.sh $(PACKAGE_DIR)/usr/share/initramfs-tools/hooks/decrypt_tmpusb
	@fakeroot dpkg-deb -Z gzip --build $(PACKAGE_DIR)/ > /dev/null
	@cp /tmp/$(PACKAGE_NAME).deb dist/
	@$(RM) -r $(PACKAGE_DIR)/
	@lintian --suppress-tags script-not-executable dist/$(PACKAGE_NAME).deb
	@echo Output at dist/$(PACKAGE_NAME).deb
