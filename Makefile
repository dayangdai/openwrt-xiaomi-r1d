#
# Copyright (c) 2014 Jack's Lab <http://jackslab.org>
#

kerndir=kernel/linux-2.6.36
cross=../../toolchain/hndtools-arm-linux-2.6.36-uclibc-4.5.3/bin/arm-brcm-linux-uclibcgnueabi-

STRIP=toolchain/hndtools-arm-linux-2.6.36-uclibc-4.5.3/bin/arm-brcm-linux-uclibcgnueabi-strip

NCPUS:=1
OS:=$(shell uname -s)

ifeq ($(OS),Linux)
  NCPUS:=$(shell grep -c ^processor /proc/cpuinfo)
endif

# export LD_LIBRARY_PATH=$(shell pwd)/toolchain/hndtools-arm-linux-2.6.36-uclibc-4.5.3/lib/
cross=arm-xiaomi-linux-uclibcgnueabi-r1d-
STRIP=arm-xiaomi-linux-uclibcgnueabi-r1d-strip

all: vmlinuz rootfs
	@echo '-----------------------------------------------------'
	@echo ' Kernel image and rootfs of Xiaomi R1D is generated.'
	@echo ' Kernel image vmlinuz is located at current directory'
	@echo ' The rootfs is located at rootfs/'
	@echo '-----------------------------------------------------'

nonfs: vmlinuz-nonfs rootfs
	@echo '-----------------------------------------------------'
	@echo ' Kernel image and rootfs of Xiaomi R1D is generated.'
	@echo ' Kernel image vmlinuz is located at current directory'
	@echo ' The rootfs is located at rootfs/'
	@echo '-----------------------------------------------------'

config:
	if [ ! -f $(kerndir)/.config ]; then \
		cp $(kerndir)/arch/arm/configs/xiaomi-r1d-with-nfs_defconfig \
			$(kerndir)/.config; \
	fi

menuconfig: config
	@echo 'Enter the menuconfig of the kernel of Xiaomi R1D'
	@make -C $(kerndir) ARCH=arm CROSS_COMPILE=$(cross) menuconfig

modules: config
	@echo 'Build the kernel modules of Xiaomi R1D'
	@make -C $(kerndir) ARCH=arm CROSS_COMPILE=$(cross) modules -j$(NCPUS)

vmlinuz: modules
	@echo 'Build the kernel image of Xiaomi R1D'
	@$(STRIP) -g $(kerndir)/drivers/net/et/et.ko -o \
				$(kerndir)/usr/ramfs/lib/modules/et.ko
	@cp -f kernel/tools/busybox.mount $(kerndir)/usr/ramfs/usr/bin/busybox
	@make -C $(kerndir) ARCH=arm CROSS_COMPILE=$(cross) vmlinuz -j$(NCPUS)
	@ln -sf $(kerndir)/arch/arm/boot/vmlinuz .

vmlinuz-nonfs: modules
	@echo 'Build the kernel image of Xiaomi R1D'
	@$(STRIP) -g $(kerndir)/drivers/net/et/et.ko -o \
				$(kerndir)/usr/ramfs/lib/modules/et.ko
	@rm -f $(kerndir)/usr/ramfs/usr/bin/busybox
	@make -C $(kerndir) ARCH=arm CROSS_COMPILE=$(cross) vmlinuz -j$(NCPUS)
	@make -C tools/
	@tools/trx -o vmlinuz.trx $(kerndir)/arch/arm/boot/vmlinuz

modules_install: modules
	@rm -rf rootfs/*
	@echo 'Install the kernel modules into rootfs/ directory'
	@make -C $(kerndir) ARCH=arm CROSS_COMPILE=$(cross) INSTALL_MOD_STRIP=1 \
		INSTALL_MOD_PATH=../../rootfs modules_install

rootfs: modules_install
	@echo 'Build the rootfs of Xiaomi R1D'
	tar jxfp rootfs.tar.bz2 -C rootfs/
	@cd rootfs && sudo tar czfp ../jarvis-rootfs.tgz *
	@echo 'The rootfs jarvis-rootfs.tgz is generated'

clean:
	@make -C $(kerndir) ARCH=arm CROSS_COMPILE=$(cross) clean
	@rm -f vmlinuz
	@rm -rf rootfs/*

distclean:
	@make -C $(kerndir) ARCH=arm CROSS_COMPILE=$(cross) distclean
	@rm -f vmlinuz
	@rm -rf rootfs/*

help:
	@echo  'all		- Build the kernel and rootfs'
	@echo  'nonfs		- Build the kernel deployed into flash.os and rootfs'
	@echo  'clean		- Remove most generated files but keep the config'
	@echo  'distclean	- Remove the all generated files including the config'
	@echo  'menuconfig	- Config the kernel of Xiaomi R1D'
	@echo  'vmlinuz		- Build the kernel of Xiaomi R1D'
	@echo  'modules		- Build all kernel modules'
	@echo  'rootfs		- Build the rootfs with kernel modules'

.PHONY:	all nonfs clean help vmlinuz modules modules_install rootfs menuconfig config
