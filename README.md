# Linux on STM32F429-DISCO kit
### Hardware stup
1. Connect SD-Card reader to SPI4 on the kit.
2. Connect UART to USART1 on the kit.
### Firmware setup
0. Make sure if you have this in your $PATH:
`arm-buildroot-uclinux-uclibcgnueabi-elfedit-gcc` toolchain
`genimage` tool
1. Clone this repository
`git clone https://github.com/MartinK7/stm32f429_disco_running_linux.git --recurse-submodules`
2. Apply patches
`./buils.sh prepare`
3. Build busybox and linux kernel -> Generate initrd/initramfs -> Generate SD-Card image with MBR
`./buils.sh busybox linux sdcard`
4. Flash the generated sdcard.img to you SD-Card. Be careful don't destroy your disk like me!
Attach Discovery-kit and build&flash modified afboot bootloader with SD-Card support
`./buils.sh afboot_and_flash`
5. Attach SD-Card to Discovery-Kit and reset.

More (and hopefully better) info later
