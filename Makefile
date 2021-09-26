include configs/common/config.mk
include configs/$(CFGDIR)/config.mk

######################################################################
## PROJECT
######################################################################

# Build automaticly
all:
	-rm sdcard.img flash.bin
	make images
	@echo "all - done!"

clean:
	cd linux && make ARCH=arm clean
	cd busybox && make ARCH=arm clean
	cd afboot-stm32 && make ARCH=arm clean
	-rm -rf initramfs initrd root tmp
	-rm sdcard.img flash.bin mmcfs.ext2
	@echo "clean - done!"

# Reset whole project
mrproper: clean
	cd linux && \
	git clean -xfd && \
	git restore .
	cd busybox && \
	git clean -xfd && \
	git restore .
	cd afboot-stm32 && \
	git clean -xfd && \
	git restore .
	@echo "mrproer - done!"

# Prepare project
prepare: mrproper
	cd afboot-stm32 && git apply ../configs/common/afboot.patch
	cp configs/$(CFGDIR)/spl_linux_defconfig linux/arch/arm/configs/
	cp configs/$(CFGDIR)/spl_busybox_defconfig busybox/configs/
	cd linux && git apply ../configs/$(CFGDIR)/linux.patch
	cd linux && make ARCH=arm spl_linux_defconfig
	cd busybox && make ARCH=arm spl_busybox_defconfig
	@echo "prepare - done!"

######################################################################
## EXPERIMENTAL-DEVELOPMENT ONLY
######################################################################

# Exporting binaries path into the $PATH
patches:
	cd afboot-stm32 && git diff > ../configs/common/afboot.patch
	cd linux && git diff > ../configs/$(CFGDIR)/linux.patch && cp .config ../configs/$(CFGDIR)/spl_linux_defconfig
	cd busybox && cp .config ../configs/$(CFGDIR)/spl_busybox_defconfig
	@echo "patches - meowed!"
	@echo " "
	@echo "                         _._     _,-'""\`-._"
	@echo "     Patches >>>        (,-.\`._,'(       |\\\`-/|"
	@echo "                            \`-.-' \ )-\`( , o o)"
	@echo "                                  \`-    \\\`_\`\"'-"
	@echo " "

######################################################################
## LINUX KERNEL
######################################################################

# linux tinyconfig
linuxt-tinyconfig:
	cd linux && make ARCH=arm tinyconfig
	@echo "linuxt-tinyconfig - done!"

# linux defconfig
linux-defconfig:
	cd linux && make ARCH=arm stm32_defconfig
	@echo "linux-defconfig - done!"

# linux menuconfig
linux-menuconfig:
	cd linux && make ARCH=arm menuconfig
	@echo "linux-menuconfig - done!"

# linux clean
linux-clean:
	cd linux && make ARCH=arm clean
	@echo "linux-clean - done!"

# linux all
.PHONY: linux
linux:
	cd linux && make ARCH=arm CROSS_COMPILE=arm-linux-gnueabi- -j$(THREADS) all
	@echo "linux - done!"

######################################################################
# BOOTLOADER + STM32-FLASH MEMORY
######################################################################

bootloader:
	-rm flash.bin
	cd afboot-stm32 && \
	make clean stm32f429i-disco \
	KERNEL_ADDR=$(KERNEL_ADDR) DTB_ADDR=$(DTB_ADDR) \
	KERNEL_MAX_SIZE=$(KERNEL_MAX_SIZE) DTB_MAX_SIZE=$(DTB_MAX_SIZE) BOOT_FROM_MMC=$(BOOT_FROM_MMC)
	@echo "bootloader - done!"

flash:
	openocd -f board/stm32f429discovery.cfg \
	  -c "init" \
	  -c "reset init" \
	  -c "flash probe 0" \
	  -c "flash info 0" \
	  -c "flash write_image erase flash.bin 0x08000000" \
	  -c "reset run" \
	  -c "shutdown"
	@echo "flash - done!"

######################################################################
# IMAGES
######################################################################

images: busybox linux bootloader
ifeq ($(CFGDIR),yesmmc)
	cp $(BOOTLOADER) flash.bin
	-rm tmp root -rf
	mkdir tmp root
	fakeroot genext2fs -B 1024 -b 8192 -d configs/yesmmc/mmcfs/ mmcfs.ext2
	fakeroot genimage --config configs/yesmmc/sdcard.config --inputpath . --outputpath .
	-rm tmp root mmcfs.ext2 -rf
else
	./if.sh $(BOOTLOADER) $(BOOTLOADER_MAX_SIZE) "Bootloader will not fit!"
	./if.sh $(DTB) $(DTB_MAX_SIZE) "Bootloader will not fit!"
	./if.sh $(KERNEL) $(KERNEL_MAX_SIZE) "Kernel will not fit!"
	dd if=$(BOOTLOADER) of=flash.bin bs=1 seek=$(BOOTLOADER_OFFSET_IN_FLASH_BIN) conv=notrunc,noerror && \
	dd if=$(DTB) of=flash.bin bs=1 seek=$(DTB_OFFSET_IN_FLASH_BIN) conv=notrunc,noerror && \
	dd if=$(KERNEL) of=flash.bin bs=1 seek=$(KERNEL_OFFSET_IN_FLASH_BIN) conv=notrunc,noerror
endif
	@echo " "
	@echo "-------------------------------------------------------------------------------"
ifeq ($(CFGDIR),yesmmc)
	@echo "[sdcard.img] --> SD-CARD image is ready!"
endif
	@echo "[flash.bin]  --> STM32 flash memory image is ready! Flash it with: 'make flash'"
	@echo "-------------------------------------------------------------------------------"
	@echo " "
	@echo "images - done!"

######################################################################
# BUSYBOX
######################################################################

busybox-clean:
	cd busybox && make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- clean
	@echo "busybox-clean - done!"

busybox-allnoconfig:
	cd busybox && make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- allnoconfig
	cd ..
	@echo "busybox-allnoconfig - done!"

busybox-menuconfig:
	cd busybox && make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- menuconfig
	@echo "busybox-menuconfig - done!"

.PHONY: busybox
busybox:
	rm -rf initramfs initrd
	cd busybox && make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- SKIP_STRIP=y -j$(THREADS) all
	mkdir $(DATADIR)
	cd busybox && make ARCH=arm CROSS_COMPILE=arm-buildroot-uclinux-uclibcgnueabi- CONFIG_PREFIX=../$(DATADIR)/ install
	cd $(DATADIR) && \
	cp ../configs/$(CFGDIR)/extra_files/* ./ -r && \
	cp ../configs/common/extra_files/* ./ -r && \
	mkdir -p etc proc sys dev etc/init.d usr/lib mnt && \
	tree .
	@echo "busybox - done!"
	
