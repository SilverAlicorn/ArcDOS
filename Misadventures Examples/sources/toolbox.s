@------------------------------------------------------------------------------
@ Takes a pointer to a string in r0 and prints it to the screen buffer
@ pointed in r1, at the cursor offset in r2. Attempting to write to an
@ area outside the buffer causes the uppermost line to be deleted,
@ shifts everything up one row, and resets the cursor to the end of
@ the last line.
@------------------------------------------------------------------------------
print:
	push {r4,r5,r6,lr}
	mov r3,#0			@ String delimiter
	mov r4,#0xA			@ Newline character
	mov r5,#0x300		@ First cursor position beyond buffer (0-index)
	
	printloop:
	ldrb r6,[r0],#1		@ Load a character
	cmp r6,r3			@ See if it's null
	beq print_exit		@ And branch out if it is
	cmp r2,r5			@ Check if we're outside the buffer
	bleq print_shift		@ And shift everything up if we are
	cmp r6,r4			@ See if it's a newline
	beq print_newline	@ And treat it like a newline if it is
	strb r6,[r1,r2]		@ Store tile number to buffer
	add r2,r2,#1		@ Move cursor along one
	b printloop
	
	print_newline:		@ Assumes a buffer pitch of 32 characters
	lsr r2,r2,#5		@ rewind to the start of the line
	add r2,r2,#1		@ Hop down to the next line
	lsl r2,r2,#5		@ Format back to an 8-bit value
	b printloop

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

@------------------------------------------------------------------------------
@ Update the screen based on a given text buffer. This version works in 16-bit
@ color mode. Needs a pointer to VRAM in r0, and a pointer to the text buffer
@ in r1. This assumes you're using a 32x24 text buffer.
@------------------------------------------------------------------------------
updateScreen16:
	mov r3,#0x300		@ Write 768 characters

	updateScreen16_lp:
	ldrb r2,[r1],#1		@ Load a char
	strh r2,[r0],#2		@ put it in the map
	subs r3,r3,#1		@ move along one
	bne updateScreen16_lp

	bx lr

@------------------------------------------------------------------------------
@ Initialize the DS for interrupts. This installs an interrupt handler at the
@ correct spot. Does not require any parameters; interrupt handler is defined
@ in IRQhandler.s. This must be called from a privileged mode or spooky things
@ may happen.
@------------------------------------------------------------------------------
IRQ_Init:
	mrc p15,0,r0,c9,c1	@ Read DTCM size & base address into r0
	mov r0,r0,lsr #12
	mov r0,r0,lsl #12	@ Remove size bits to reveal address
	add r0,r0,#0x4000	@ Interrupt area is at DTCM+0x3FFC
	adr r1,intrMain		@ Interrupt handler address
	str r1,[r0,#-4]		@ Install pointer to interrupt handler

	mov r0,#0x4000000	@ I/O space offset
	mov r1,#1
	str r1,[r0,#0x208]	@ Enable interrupts in IME
	str r1,[r0,#0x210]	@ Enable vblank interrupt in IE

	bx lr

	.include "IRQhandler.s"

@------------------------------------------------------------------------------
@ Initialize the DS hardware to print data to the screen console-style. Sets up
@ both screens in text mode and initializes BG0 on both screens for 256-color
@ tiles. This should be the first function called in a program as it does all
@ initial setup. Meant to be used with the included print function.
@------------------------------------------------------------------------------
console_init:
	mov r0,#0x4000000	@ I/O space offset
	mov r1,#0x200
	orr r1,#0x3		@ Enable both screens in POWCNT1
	mov r2,#0x10000		@ Set DISPCNT to 2D mode 0
	orr r2,#0x100		@ Enable BG0
	mov r3,#0x81		@ Enable VRAM bank A @ 0x6000000 & bank H @ 0x6200000

	str r1,[r0, #0x304]	@ Set POWCNT1
	str r2,[r0]		@     DISPCNT
	str r3,[r0, #0x240]	@     VRAMCNT_A
	str r4,[r0, #0x248]	@     VRAMCNT_H

	mov r1,#0x84		@ BG0 tile mode, 32x32 @ 256 color
	str r1,[r0, #0x8]	@ Set BG0CNT
	
	orr r0,#0x1000		@ Move to sub screen offset
	str r2,[r0]		@ Set DISPCNT_sub same as DISPCNT
	str r1,[r0, #0x8]	@ Set BG0CNT

	adrl r0,fontPal		@ Font palette
	mov r1,#0x5000000	@ Palette memory
	mov r2,#16		@ Copying 32 bytes
	blx swiCpuSet

	orr r2,r2,#0x400	@ Sub screen palette memory
	blx swiCpuSet

	adrl r0,fontTiles	@ Start of tile data
	mov r1,#0x6000000	@ Main screen VMEM
	orr r1,#0x4000		@ Tile data starts here (in 256 color mode)
	mov r2,#4096		@ Copying 8192 bytes
	blx swiCpuSet

	orr r1,#0x200000	@ Switch to sub screen
	blx swiCpuSet		@ Copy tiles to sub screen

	bx lr
@------------------------------------------------------------------------------
@ BIOS call stubs follow.
@------------------------------------------------------------------------------

	.thumb_func
swiCpuSet:
	swi 0x0B
	bx lr
	
