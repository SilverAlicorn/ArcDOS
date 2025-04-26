init:
	mov r0,#0x4000000	@ I/O space offset
	mov r1,#0x200		@ Both screens on
	orr r1,#3		
	mov r2,#0x10000		@ 2D mode 0
	orr r2,#0x100		@ BG0 On
	mov r3,#0x81		@ Bank A enabled @ 0x6000000
	mov r4,#0x81		@ Bank H enabled @ 0x6200000
	mov r5,#0x1		@ Enable Vblank interrupt

	str r1,[r0, #0x304]	@ Set POWCNT1
	str r2,[r0]		@     DISPCNT
	str r3,[r0, #0x240]	@     VRAMCNT_A
	str r4,[r0, #0x248]	@     VRAMCNT_H
	str r5,[r0, #0x210]	@     IE

	mov r1,#0x84		@ BG0 tile mode, 32x32 @ 256
	str r1,[r0, #0x8]	@ Into BG0CNT

	orr r0,#0x1000		@ Moving into sub screen territory
	
	str r2,[r0]		@ DISPCNT Same as main screen
	str r1,[r0, #0x8]	@ BG0CNT Same as main screen also

	adrl r0,fontlz77Pal	@ Pointer to font palette
	mov r1,#0x5000000	@ Palette memory
	mov r2,#16		@ Copying 32 bytes
	blx swiCpuSet

	orr r1,r1,#0x400	@ Sub screen palette memory
	blx swiCpuSet

	adr r0,fontlz77Tiles	@ CpuSet source address
	mov r1,#0x6000000	@ CpuSet dest address base
	orr r1,#0x4800		@ Dest address offset, so tile indices match ASCII codes
	blx swiLZ77UnCompVram

	orr r1,#0x200000	@ Switch to screen 2
	blx swiLZ77UnCompVram	@ Copy the same stuff

	adr r0,hellotext	@ Get a pointer to the ascii data
	mov r1,#0x6000000	@ Writing to video memory
	bl print

	adr r0,dualtext		@ Copy other text to sub screen
	mov r1,#0x6200000
	bl print

	mov r5,#0x4000000	@ KEYINPUT
	orr r5,r5,#0x130
	mov r6,#0x6000000	@ Writing to the letter under A
	orr r6,#0x52
inputloop:
	ldr r0,[r5]		@ Get key status
	tst r0,#0x1		@ See if A is pressed
	moveq r4,#0x58
	streqh r4,[r6]
	tst r0,#0x0
	moveq r4,#0x0
	streqh r4,[r6]
	b inputloop


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

swiLZ77UnCompVram:
	swi 0x12
	bx lr

dualtext:
	.asciz "Dual screens!                   LZ77 Compression!"

hellotext:
	.asciz "Hello world!"

	.include "fontlz77.s"

