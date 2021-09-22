#               FLASH
# -----------------------------------
# AFBOOT        0x08000000 -             max 2MiB
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
# 3. Partition - MMC-FS (EXT2,3,4 busybox etc.)
# 4. Partition - Reserved
DATADIR=initrd
BOOT_FROM_MMC=1
BOOTLOADER=afboot-stm32/stm32f429i-disco.bin
KERNEL=linux/arch/arm/boot/xipImage
DTB=linux/arch/arm/boot/dts/stm32f429-disco.dtb
KERNEL_ADDR=0x90000000
DTB_ADDR=0x902F8000
KERNEL_MAX_SIZE=0x002F8000
DTB_MAX_SIZE=0x00008000
