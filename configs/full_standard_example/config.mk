# the iso final name
ISO_OUTPUT_NAME := full_standard_example.iso

# the packages that gets installed
CHROOT_PKGS := live-boot \
	linux-image-6.12.107+deb13-amd64 \
	isc-dhcp-client \
	ifupdown \
	lightdm \
	xfce4 \
	xorg \
	sudo

DEBIAN_VERSION := stable
ARCH := amd64

#APT_ARG := --no-install-recommends
#DEBOOTSTRAP_ARGS := --variant minbase