LogoBounce.nds: arm7.bin arm9.bin
	ndstool -c LogoBounce.nds -9 arm9.bin -7 arm7.bin -r9 0x02001000
arm7.bin: arm7.elf
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-objcopy -O binary arm7.elf arm7.bin
arm9.bin: arm9.elf
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-objcopy -O binary arm9.elf arm9.bin
arm7.elf:
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-as -o arm7.elf arm7.s
arm9.elf:
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-as -o arm9.elf arm9.s

clean:
	rm LogoBounce.nds *.bin *.elf
