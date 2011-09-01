init:
	mov r0,#0x4000000	@ I/O space offset
	mov r1,#0x200		@ Both screens on
	orr r1,#3		
	mov r2,#0x10000		@ 2D mode 0
	orr r2,#0x100		@ BG0 On
	mov r3,#0x81		@ Bank A enabled @ 0x6000000
	mov r4,#0x81		@ Bank H enabled @ 0x6200000

	str r1,[r0, #0x304]	@ Set POWCNT1
	str r2,[r0]		@     DISPCNT
	str r3,[r0, #0x240]	@     VRAMCNT_A
	str r4,[r0, #0x248]	@     VRAMCNT_H

	mov r1,#0x84		@ BG0 tile mode, 32x32 @ 256
	str r1,[r0, #0x8]	@ Into BG0CNT

	orr r0,#0x1000		@ Moving into sub screen territory
	
	str r2,[r0]		@ DISPCNT Same as main screen
	str r1,[r0, #0x8]	@ BG0CNT Same as main screen also

	adrl r0,fontPal	@ Pointer to font palette
	mov r1,#0x5000000	@ Palette memory
	mov r2,#16		@ Copying 32 bytes
	blx swiCpuSet

	orr r1,r1,#0x400	@ Sub screen palette memory
	blx swiCpuSet

	adr r0,fontTiles	@ CpuSet source address
	mov r1,#0x6000000	@ CpuSet dest address base
	orr r1,#0x4000		@ Dest address offset
	mov r2,#4096		@ # of halfwords to copy
	blx swiCpuSet

	orr r1,#0x200000	@ Switch to screen 2
	blx swiCpuSet	@ Copy the same stuff

	adr r0,hellotext	@ Get a pointer to the ascii data
	mov r1,#0x6000000	@ Writing to video memory
	bl print

	@ init stack to 0x2001000
	mov sp,#0x2000000
	orr sp,#0x1000
	
	push {r0-r5}
	pop {r0-r4}
	
	mov r0,sp
	adrl r1,dualtext
binToString:
	mov r2,#0x30		@ ASCII for 0
	strb r2,[r1]		@ Write to string
	add r1,r1,#1		@ Move to next char
	mov r2,#0x62		@ ASCII for b
	strb r2,[r1]		@ Write to string
	add r1,r1,#1		@ Move to next char

	@ Now, mask each bit in the number and read it out to the string. Remember to write ASCII
	@ codes and not numerical values!
	
	mov r3,#0x80000000		@ Initial mask bit
	mov r4,#32			@ And loop 32 times
binToString_loop:
	tst r0,r3			@ Compare input to mask bit
	moveq r2,#0x30		@ Write a 0 if it's 0
	movne r2,#0x31		@ Or write a 1 if it isn't
	strb r2,[r1]		@ Write it to the string
	add r1,r1,#1		@ Advance string pointer
	lsr r3,r3,#1		@ Shift mask bit right one
	subs r4,r4,#1		@ Decrement loop counter
	bne binToString_loop	@ Loop back

	mov r2,#0			@ String delimiter
	strb r2,[r1]		@ Close off string
	
	adr r0,dualtext		@ Copy other text to sub screen
	mov r1,#0x6200000
	bl print
	
nf:	b nf			@ Loop forever

print:		@ NOTE: r1 is trashed after using this subroutine
	mov r3,#0		@ Line delimiter
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
	.asciz "Dual screens!"

hellotext:
	.asciz "Hello, world! This is a         Nintendo DS thing."

	.include "font.s"

