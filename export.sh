#!/bin/bash
# Exporting binaries path into the $PATH
#  With this hack I'm able to obtain that arm-buildroot-uclinux-uclibcgnueabi- toolchain
#  In future I'm planning embed this somehow without buildroot into this project.
export PATH=${PATH}:$(pwd)/../tools/buildroot/output/host/bin/:$(pwd)/../tools/genimage/
