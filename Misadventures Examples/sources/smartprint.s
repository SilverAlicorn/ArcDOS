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

	adrl r0,fontTiles	@ CpuSet source address
	mov r1,#0x6000000	@ CpuSet dest address base
	orr r1,#0x4000		@ Dest address offset, so tile indices match ASCII codes
	mov r2,#4096		@ # of bytes to copy
	blx swiCpuSet
	
	orr r1,#0x200000	@ Switch to sub screen
	blx swiCpuSet		@ Copy tiles to sub screen
	
	adrl r0,testtext
	mov r1,#0x6200000
	bl print
	
	@ init stack to 0x2001000
	mov sp,#0x2000000
	orr sp,#0x1000

	
	adr r0,txtMonologue
	adrl r1,buffer_screen1
	mov r2,#0
	bl smartprint
	
	mov r0,#0x6000000	@ Vmem tile map, buffer already in r1
	bl updateScreens
	
nf: b nf
	

##########
# Copy the 8-bit ASCII data in the text buffers to the video screen, as
# 16-bit tile indices
##########
updateScreens:
	mov r3,#0x300		@ Fill whole map
	
	updateScreens_lp:
	ldrb r2,[r1],#1		@ Load a char
	strh r2,[r0],#2		@ Put it in the map
	subs r3,r3,#1		@ move along one
	bne updateScreens_lp
	
	b nf	

##########
# Takes a pointer to a string in r0 and prints it to the screen buffer
# pointed in r1, at the cursor offset in r2. Attempting to write to an
# area outside the buffer causes the uppermost line to be deleted,
# shifts everything up one row, and resets the cursor to the end of
# the last line.
##########
smartprint:
	push {r4,r5,r6,lr}
	mov r3,#0			@ String delimiter
	mov r4,#0xA			@ Newline character
	mov r5,#0x300		@ First cursor position beyond buffer (0-index)
	
	smartprintloop:
	ldrb r6,[r0],#1		@ Load a character
	cmp r6,r3			@ See if it's null
	beq print_exit		@ And branch out if it is
	cmp r2,r5			@ Check if we're outside the buffer
	bleq print_shift		@ And shift everything up if we are
	cmp r6,r4			@ See if it's a newline
	beq print_newline	@ And treat it like a newline if it is
	strb r6,[r1,r2]		@ Store tile number to buffer
	add r2,r2,#1		@ Move cursor along one
	b smartprintloop
	
	print_newline:		@ Assumes a buffer pitch of 32 characters
	lsr r2,r2,#5		@ rewind to the start of the line
	add r2,r2,#1		@ Hop down to the next line
	lsl r2,r2,#5		@ Format back to an 8-bit value
	b smartprintloop

	print_shift:		@ Assumes a 768-byte buffer
		push {r2,r3,r4,r5}
		mov r2,#32			@ Read pointer, starting at line 2
		mov r3,#0			@ Write offset
		mov r4,#0x2e0		@ Loop for 23 lines * 8 bytes
		
		print_shift_lp:
		ldrb r5,[r1,r2]		@ Load first byte
		strb r5,[r1,r3]		@ Save it back, shifted up 32 bytes
		add r2,r2,#1		@ Advance read pointer
		add r3,r3,#1		@ Advance write pointer
		subs r4,r4,#1		@ Decrement loop pointer
		bne print_shift_lp
		
		mov r2,#0x2e0		@ Fill the last line with zeroes before
		mov r3,#0			@ writing new text on it
		mov r4,#32
		print_shift_zerofill:
		strb r3,[r1,r2]
		add r2,#1
		subs r4,r4,#1
		bne print_shift_zerofill
		
		pop {r2,r3,r4,r5}
		mov r2,#0x2e0		@ Beginning of last line
		mov pc,lr
	
	print_exit:
	pop {r4,r5,r6,pc}
	
print:		@ NOTE: r1 is trashed after using this subroutine
	mov r3,#0		@ Line delimiter
	printloop:	
	ldrb r2,[r0],#1		@ Load a character
	cmp r2,r3		@ See if it's null
	moveq pc,lr		@ And branch out if it is
	strh r2,[r1],#2		@ Store tile number to video mem
	bne printloop		@ Branch if not finished
	
	bx lr
	
	.align 2
	.thumb_func
swiCpuSet:	@ Copy data from one spot to another
	swi 0x0B		@ swi to CpuSet
	bx lr
	
testtext:
	.asciz "test text"

txtMonologue:
	.asciz "We hold these truths to be self-evident, that all men are created equal, that they are endowed by their Creator with certain unalienable Rights, that among these are Life, Liberty and the pursuit of Happiness. — That to secure these rights, Governments are instituted among Men, deriving their just powers from the consent of the governed, — That whenever any Form of Government becomes destructive of these ends, it is the Right of the People to alter or to abolish it, and to institute new Government, laying its foundation on such principles and organizing its powers in such form, as to them shall seem most likely to effect their Safety and Happiness. Prudence, indeed, will dictate that Governments long established should not be changed for light and transient causes; and accordingly all experience hath shewn that mankind are more disposed to suffer, while evils are sufferable than to right themselves by abolishing the forms to which they are accustomed. But when a long train of abuses and usurpations, pursuing invariably the same Object evinces a design to reduce them under absolute Despotism, it is their right, it is their duty, to throw off such Government, and to provide new Guards for their future security. Such has been the patient sufferance of these Colonies; and such is now the necessity which constrains them to alter their former Systems of Government. The history of the present King of Great Britain is a history of repeated injuries and usurpations, all having in direct object the establishment of an absolute Tyranny over these States. To prove this, let Facts be submitted to a candid world."
buffer_screen1:
	.space 768

	.include "font.s"
