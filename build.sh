#!/bin/bash


#               FLASH
# -----------------------------------
# PONY-BOOT     0x08000000 -             max 2MiB
#
#               RAM (example)
# -----------------------------------
# KERNEL (XIP)  0x90000000 - 4MiB-32KiB = 4064KiB
# DTB           0x903F8000 -                32KiB
# FREE RAM      0x90400000                   4MiB
#
#               SDCARD
# -----------------------------------
# Master Boot Record (MBR)
# 1. Partition - Linux Kernel image (RAW data)
# 2. Partition - Device Tree Blob (RAW data)
# 3. Partition - Rootfs (EXT2,3,4 busybox etc.)
# 4. Partition - Reserved

THREADS=12
# PONYBOOT=pony-boot/Debug/F429_ponyboot.bin
# BOOTLOADER=u-boot/build/u-boot.bin
KERNEL=linux/arch/arm/boot/xipImage
DTB=linux/arch/arm/boot/dts/stm32f429-disco.dtb

KERNEL_ADDR=0x90000000
DTB_ADDR=0x902F8000
INITRD_ADDR=0

KERNEL_MAX_SIZE=0x002F8000
DTB_MAX_SIZE=0x00008000
INITRD_MAX_SIZE=0

## DO EVE
for argument in "$@"; do
	######################################################################
	## PROJECT
	######################################################################
	
	# Reset whole project
	if [ "$argument" = "mrproper" ]; then
		cd linux
		git clean -xfd
		git restore .
		cd ../busybox
		git clean -xfd
		git restore .
		cd ../afboot-stm32
		git clean -xfd
		git restore .
		cd ..
		rm -rf initramfs
		rm sdcard.img
	fi

	# Exporting binaries path into the $PATH
	if [ "$argument" = "path" ]; then
		export PATH=${PATH}:$(pwd)/../tools/buildroot/output/host/bin/:$(pwd)/../tools/genimage/
	fi

	# Propare project
	if [ "$argument" = "prepare" ]; then
		cp configs/spl_lk_defconfig linux/arch/arm/configs/
		cp configs/spl_bb_defconfig busybox/configs/
		cd linux
		make ARCH=arm spl_lk_defconfig
		git apply ../configs/linux.patch
		cd ../busybox
		make ARCH=arm spl_bb_defconfig
		cd ../afboot-stm32
		git apply ../configs/afboot.patch		
		cd ..
	fi

	######################################################################
	## LINUX KERNEL
	######################################################################

	# linux tiny-config
	if [ "$argument" = "linuxt" ]; then
		cd linux
		make ARCH=arm tinyconfig
		cd ..
	fi

	# linux defconfig
	if [ "$argument" = "linuxd" ]; then
		cd linux
		make ARCH=arm stm32_defconfig
		cd ..
	fi

	# linux menuconfig
	if [ "$argument" = "linuxm" ]; then
		cd linux
		make ARCH=arm menuconfig
		cd ..
	fi

	# linux clean
	if [ "$argument" = "linuxc" ]; then
		cd linux
		make ARCH=arm clean
		cd ..
	fi

	# linux all
	if [ "$argument" = "linux" ]; then
		cd linux
		make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j${THREADS} all
		cd ..
	fi

	######################################################################
	# IMAGES
	######################################################################
	
	# SD card image
	if [ "$argument" = "sdcard" ]; then
		mkdir root
		rm sdcard.img
		cp ${KERNEL} kernel.bin && \
		cp ${DTB} dtb.bin && \
		fakeroot genext2fs -B 1024 -b 8192 -d rootfs rootfs.ext2 && \
		fakeroot genimage --config configs/sdcard.config --inputpath . --outputpath .
		rm kernel.bin dtb.bin rootfs.ext2
		rm tmp -rf
		rm root -rf
	fi

	######################################################################
	# BOOTLOADER + STM32-FLASH MEMORY
	######################################################################

	if [ "$argument" = "afboot_and_flash" ]; then
		cd "afboot-stm32"
		make clean stm32f429i-disco flash_stm32f429i-disco \
		KERNEL_ADDR=${KERNEL_ADDR} DTB_ADDR=${DTB_ADDR} \
		KERNEL_MAX_SIZE=${KERNEL_MAX_SIZE} DTB_MAX_SIZE=${DTB_MAX_SIZE} \
		INITRD_MAX_SIZE=${INITRD_MAX_SIZE} INITRD_ADDR=${INITRD_ADDR}
		cd ..
	fi

	######################################################################
	# BUSYBOX
	######################################################################
		
	if [ "$argument" = "busyboxc" ]; then
		rm initrd.img
		cd busybox
		make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- clean
		cd ..		
	fi			
		
	if [ "$argument" = "busyboxd" ]; then
		cd busybox
		make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- allnoconfig
		cd ..		
	fi			
		
	if [ "$argument" = "busyboxm" ]; then
		cd busybox
		make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- menuconfig
		cd ..		
	fi			
		
	if [ "$argument" = "busybox" ]; then
		rm -rf initramfs
		cd busybox
		make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- SKIP_STRIP=y -j${THREADS} all && \
		mkdir ../initramfs && \
		make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- CONFIG_PREFIX=../initramfs/ install && \
		cd ../initramfs && \
		cp ../configs/init.sh ./ && \
		mkdir -p etc proc sys dev etc/init.d usr/lib home/root mnt && \
		cp ../configs/home_root/* home/root/ -r
		tree .
		cd ..
	fi
done

#
#	if [ "$argument" = "cpio" ]; then
#		rm initramfs.cpio initramfs.cpio.gz
#		cd "initramfs"
#		fakeroot find . -print0 | cpio --null -ov --format=newc | gzip -9 -n > ../initramfs.cpio.gz
#		cd ..		
#	fi
#
#	## flashing
#
#	if [ "$argument" = "image" ]; then
#		#               FLASH
#		# -----------------------------------
#		# BOOTLOADER    0x08000000 -  256KiB
#		# BOOT_ENV      0x08040000 -  128KiB
#		# DTB           0x08060000 -   32KiB
#		# KERNEL (GZ)   0x08068000 - 1632KiB
#		#
#		#               RAM
#		# -----------------------------------
#		# KERNEL (XIP)  0x90000000 -    3MiB
#		# RAM           0x90500000 -    5MiB
#		#
#		# setenv bootargs console=ttySTM0,115200 earlyprintk consoleblank=0 ignore_loglevel
#		# unzip 0x08068000 0x90000000
#		# bootm 0x90000000 - 0x08060000
#		#
#		
#		# Create GZipped kernel
#		gzip -cf -9 ${KERNEL} > ${KERNEL}.gz
#
#		# 2MiB of FLASH
#		dd if=/dev/zero     of=flash.bin bs=1024 count=1 && \
#		dd if=${BOOTLOADER} of=flash.bin bs=1024 seek=0     conv=notrunc,noerror && \
#		dd if=${DTB}        of=flash.bin bs=1024 seek=384   conv=notrunc,noerror && \
#		dd if=${KERNEL}.gz  of=flash.bin bs=1024 seek=416   conv=notrunc,noerror
#	fi
#
#	if [ "$argument" = "stat" ]; then
#		echo ${BOOTLOADER} $(wc -c < ${BOOTLOADER})
#		echo ${KERNEL} $(wc -c < ${KERNEL})
#		echo ${DTB} $(wc -c < ${DTB})
#	fi
#
#	if [ "$argument" = "flash" ]; then
#		st-flash write flash.bin 0x08000000
#	fi		
#		
#	if [ "$argument" = "gdb" ]; then
#		cd linux
#		st-util & gdb-multiarch vmlinux -ex "target remote :4242"
#		cd ..
#	fi
#
#	## U-BOOT
#		
#	# u-boot defconfig
#	if [ "$argument" = "ubootd" ]; then
#		cd u-boot
#		make O=build ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- stm32f429-discovery_defconfig
#		cd ..
#	fi
#
#	# u-boot menuconfig
#	if [ "$argument" = "ubootm" ]; then
#		cd u-boot
#		make O=build ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- menuconfig
#		cd ..
#	fi
#
#	# u-boot clean
#	if [ "$argument" = "ubootc" ]; then
#		cd u-boot
#		make O=build ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- clean
#		cd ..
#	fi
#
#	# u-boot all
#	if [ "$argument" = "uboot" ]; then
#		cd u-boot
#		make O=build ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j${THREADS} all
#		cd ..
#	fi
#
#	## PONY-BOOT
#	if [ "$argument" = "ponyboot" ]; then
#		cd pony-boot/Debug
#		make clean
#		make all
#		cd ..
#	fi
