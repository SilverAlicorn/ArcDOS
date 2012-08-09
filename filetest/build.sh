#!/bin/bash

arm-none-eabi-gcc -specs=arcdos_arm9.specs -o arm9.elf main.c console.c consolefont.c asmfuncs.s

arm-none-eabi-objcopy -O binary arm9.elf arm9.bin

ndstool -c filetest.nds -7 arm7.bin -9 arm9.bin
