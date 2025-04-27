s? = $(subst $(empty) ,?,$1)
?s = $(subst ?, ,$1)
notdirx = $(call ?s,$(notdir $(call s?,$1)))

nds: arm7.bin arm9.bin
	ndstool -c $(call notdirx,$(CURDIR)).nds -9 build/arm9.bin -7 build/arm7.bin -r9 0x02001000
arm7.bin: arm7.elf
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-objcopy -O binary build/arm7.elf build/arm7.bin
arm9.bin: arm9.elf
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-objcopy -O binary build/arm9.elf build/arm9.bin
arm7.elf: builddir
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-as -o build/arm7.elf arm7.s
arm9.elf:
	/opt/devkitpro/devkitARM/bin/arm-none-eabi-as -o build/arm9.elf arm9.s
builddir:
	test -d build || mkdir build

clean:
	rm -r ./$(call notdirx,$(CURDIR)).nds build
