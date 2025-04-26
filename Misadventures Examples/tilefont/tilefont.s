init:
	mov r0,#0x4000000	@ I/O space offset
	mov r1,#0x200		@ Both screens on
	orr r1,#3
	mov r2,#0x10000		@ 2D mode 0
	orr r2,#0x100		@ BG0 On
	mov r3,#0x81		@ Bank A enabled at 0x6000000 | Bank H at 0x6200000

	str r1,[r0, #0x304]	@ Set POWCNT1
	str r2,[r0]		@     DISPCNT
	str r3,[r0, #0x240]	@     VRAMCNT_A
	str r3,[r0, #0x248]	@     VRAMCNT_H

	mov r1,#0x84		@ BG0 tile mode, 32x32 @ 256
	str r1,[r0, #0x8]	@ Set BG0CNT
	orr r0,#0x1000		@ Switch to sub screen
	str r2,[r0]		@ Set DISPCNT
	str r1,[r0, #0x8]	@ Set up BG0CNT same as main screen

	adrl r0,fontPal		@ Point to font palete
	mov r1,#0x5000000	@ Palette memory
	mov r2,#16		@ Copying 32 bytes
	blx swiCpuSet

	adr r0,fontTiles	@ Pointer to font tiles
	mov r1,#0x6000000	@ Dest address base in vmem
	orr r1,#0x4800		@ Dest address offset - make tile indices match ASCII codes
	mov r2,#3072		@ Copy 6144 bytes
	blx swiCpuSet

	adr r0,hellotext	@ Get a pointer to the ASCII screen
	mov r1,#0x6000000	@ Write to video memory
	bl print

nf:	b nf			@ Loop forever

print:		@ NOTE: r1 is trashed after using this subroutine
	mov r3,#0		@ Line delimiter
	mov r5,#0xBE00
	add r5,#0xEF
	printloop:	
	ldrb r2,[r0],#1		@ Load a character
	cmp r2,r3		@ See if it's null
	moveq pc,lr		@ And branch out if it is
	strh r2,[r1],#2		@ Store tile number to video mem
	bne printloop		@ Branch if not finished

	.align 2
	.thumb_func
swiCpuSet:	@ Copy data from one spot to another
	swi 0x0B		@ swi to CpuSet
	bx lr

hellotext:
	.asciz "Hello world!"

	.include "font.s"
