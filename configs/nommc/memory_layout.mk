#               FLASH
# -----------------------------------
# AFBOOT        0x08000000 - 4KiB
#    DTB        0x08001000 - 22KiB
# KERNEL (zIMG) 0x08006800 - 2022KiB
#
#               RAM
# -----------------------------------
# KERNEL (XIP)  0x90000000 - 3MiB
# FREE RAM      0x90300000 - 5MiB
#
DATADIR=initramfs
BOOT_FROM_MMC=0
BOOTLOADER=afboot-stm32/stm32f429i-disco.bin
KERNEL=linux/arch/arm/boot/zImage
DTB=linux/arch/arm/boot/dts/stm32f429-disco.dtb
BOOTLOADER_ADDR=0x08000000
KERNEL_ADDR=0x08006800
DTB_ADDR=0x08001000
BOOTLOADER_MAX_SIZE=0x1000
DTB_MAX_SIZE=0x00005800
KERNEL_MAX_SIZE=0x001F9800
BOOTLOADER_OFFSET_IN_FLASH_BIN=$(shell expr $(shell printf "%d\n" $(BOOTLOADER_ADDR)) - $(shell printf "%d\n" 0x08000000))
KERNEL_OFFSET_IN_FLASH_BIN=$(shell expr $(shell printf "%d\n" $(KERNEL_ADDR)) - $(shell printf "%d\n" 0x08000000))
DTB_OFFSET_IN_FLASH_BIN=$(shell expr $(shell printf "%d\n" $(DTB_ADDR)) - $(shell printf "%d\n" 0x08000000))
