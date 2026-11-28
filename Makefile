.PHONY: all check_existing createisoskel default_checks reiso migrate chroot masclean isoclean install_pkgs setup_rootfs genInitramfs genSquashfs copyBoots

ifdef CONFIG
-include configs/$(CONFIG)/config.mk
endif

workdir         := $(shell pwd)
chrootPath      := $(workdir)/build/$(CONFIG)/rootfs
configBuildPath := $(workdir)/build/$(CONFIG)

configMigratePath := $(configBuildPath)/migrate

GRUB_MKRESCUE := $(shell command -v grub2-mkrescue 2>/dev/null || echo grub-mkrescue)	
migrate_files := $(wildcard $(workdir)/configs/$(CONFIG)/migrate/*)
SHELL := /bin/bash

all:
	@echo "Check the README.md, to get started!"

# check you are running as root/sudo
default_checks:
ifndef CONFIG
	$(error 'CONFIG' is not set! Run: make CONFIG=<name>)
else ifndef ISO_OUTPUT_NAME
	$(error 'ISO_OUTPUT_NAME' is not set in your configuration, read docs!)
else ifndef CHROOT_PKGS
	$(error 'CHROOT_PKGS' is not set in your configuration, read docs!)
else ifndef DEBIAN_VERSION
	$(error 'DEBIAN_VERSION' is not set in your configuration, read docs!)
else ifndef ARCH
	$(error 'ARCH' is not set in your configuration, read docs!)
endif
	@if [[ "$$EUID" -ne 0 ]]; then \
		echo "For running its you need to run it with sudo"; \
		exit 1; \
	fi

check_existing: default_checks
	@test ! -e "$(configBuildPath)" || { echo "Already generated! Run: sudo make CONFIG=$(CONFIG) distclean"; exit 1; }

# chroot into the filesystem
chroot: default_checks 
	chroot $(chrootPath) /bin/bash || true
	umount $(chrootPath)/proc || true


# clean the iso_root's boot and live folder
isoclean: default_checks
	rm -rf $(configBuildPath)/iso_root/*
	rm -f $(configBuildPath)/$(ISO_OUTPUT_NAME)

# cleans everything
distclean: default_checks
	sudo rm -rf $(configBuildPath)

# migrate
migrate: default_checks
	@for file in $(migrate_files); do \
		echo "Applying: $$file..."; \
		cp "$$file" $(chrootPath)/tmp/migrate.sh || exit 1; \
		chmod +x $(chrootPath)/tmp/migrate.sh; \
		chroot $(chrootPath) /tmp/migrate.sh || exit 1; \
		rm $(chrootPath)/tmp/migrate.sh; \
	done
	@echo "Migrate is done."

# installs definied packages.
install_pkgs: default_checks
	chroot $(chrootPath) apt install $(APT_ARG) $(CHROOT_PKGS) -y

# creates default skeleton for the ISO
createisoskel: default_checks
	mkdir -p $(configBuildPath)/iso_root/live
	mkdir -p $(configBuildPath)/iso_root/boot/grub

setup_rootfs: default_checks
	@echo "Debian: '$(DEBIAN_VERSION)' being created from: '$(CONFIG)' config"
	debootstrap $(DEBOOTSTRAP_ARGS) --arch $(ARCH) $(DEBIAN_VERSION) $(chrootPath) http://deb.debian.org/debian/

setup: default_checks check_existing createisoskel setup_rootfs install_pkgs migrate
	@echo "Setup is done, used config: '$(CONFIG)'"

# initramfs generating
genInitramfs: default_checks 
	chroot $(chrootPath) update-initramfs -u

# squashfs generating
genSquashfs: default_checks
	rm -f $(configBuildPath)/iso_root/live/filesystem.squashfs || true
	mksquashfs $(chrootPath) $(configBuildPath)/iso_root/live/filesystem.squashfs -comp xz

# copy boot files
copyBoots: default_checks
	cp -r $(workdir)/configs/$(CONFIG)/iso_root/* $(configBuildPath)/iso_root/
	cp $(chrootPath)/vmlinuz $(configBuildPath)/iso_root/boot
	cp $(chrootPath)/initrd.img $(configBuildPath)/iso_root/boot

# iso regenerating
reiso: default_checks copyBoots
	$(GRUB_MKRESCUE) $(configBuildPath)/iso_root -o $(configBuildPath)/$(ISO_OUTPUT_NAME)
	@echo "Your iso is regerated: $(configBuildPath)/$(ISO_OUTPUT_NAME)"
	@echo "Your iso is stored here: $(configBuildPath)"

# original iso generating 
iso: default_checks isoclean createisoskel genInitramfs genSquashfs copyBoots
	$(GRUB_MKRESCUE) $(configBuildPath)/iso_root -o $(configBuildPath)/$(ISO_OUTPUT_NAME)
	@echo "Your iso is done: $(configBuildPath)/$(ISO_OUTPUT_NAME)"
	@echo "Your iso is stored here: $(configBuildPath)"
