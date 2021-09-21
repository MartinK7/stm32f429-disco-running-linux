# Linux on STM32F429-DISCO kit
### Hardware stup
1. Connect SD-Card reader to SPI4 on the kit.\
SPI4_SCK = GPIOE2\
SPI4_NSS = GPIOE4\
SPI4_MISO = GPIOE5\
SPI4_MOSI = GPIOE6\
and +3.3V power
3. Connect UART to USART1 on the kit.\
TX = GPIOA9\
RX = GPIOA10\

**Make sure**

Make sure if you have this in your $PATH:\
`arm-buildroot-uclinux-uclibcgnueabi-elfedit-gcc` toolchain\
`genimage` tool

**Firmware setup**

1. Clone this repository\
`git clone https://github.com/MartinK7/stm32f429_disco_running_linux.git --recurse-submodules`
2. Apply patches and build\
`make prepare all`
3. Flash the generated `sdcard.img` to you SD-Card.
4. Attach Discovery-kit and flash modified afboot bootloader with SD-Card support
`make flash`
5. Attach SD-Card to Discovery-Kit and reset.

**More (and hopefully better) info later**\
*Note: There is a `make CFGDIR=nommc` option that should produce a version where an SD card reader is not needed (smaller version of linux), but it needs some work.***
