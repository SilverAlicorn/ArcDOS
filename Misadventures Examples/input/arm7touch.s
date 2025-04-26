	.align 2
init:
	mov r0,#0x4000000		@ I/O register offset
	mov r1,#1
	str r1,[r0, #0x210]		@ Enable vblank interrupt in IE
	mov r1,#0x8
	str r1,[r0, #0x4]		@ Generate interrupt on vblank

	str r1,[r0, #0x208]		@ Enable interrupts in IME	
	adr r1,intrMain
	str r1,[r0, #-4]		@ Install our interrupt handler at 0x3fffffc
	b main

main:
	blx swiHalt			@ Wait for interrupt	

	mov r0,#0x4000000		@ I/O regs
	mov r1,#0
	str r1,[r0, #0x208]		@ Disable interrupts (in IME)

	orr r0,#0x1c0			@ SPI regs offset
	bl spiWaitBusy			@ Check that we can use the SPI
	
	mov r2,#0x8a00
	orr r2,#0x01			@ Enable SPI, talking to touchscreen
	mov r3,#0x94			@ request Y-pos from touchscreen

	strh r2,[r0]		@ Write command to SPICNT
	strb r3,[r0, #2]		@ Write command to SPIDATA
	bl spiWaitBusy			@ Wait until SPI is clear again

	strb r1,[r0, #2]		@ Strobe SPIDATA to start transfer
	bl spiWaitBusy			@ Wait again
	ldrb r4,[r0, #2]		@ Read SPIDATA

	bic r2,#0xff00
	orr r2,#0x8200			@ = 0x8201
	strh r2,[r0]		@ Signal end of transfer
	strb r1,[r0, #02]		@ Strobe SPIDATA again
	bl spiWaitBusy
	ldrb r5,[r0, #02]

	mov r6,#0x2000000
	orr r6,#0x1000			@ Memory location toot
	lsl r4,r4,#5
	orr r4,r4,r5			@ Combine r4 & r5 to one bitfield
	str r4,[r6]			@ Save touch data to memory
	
	mov r0,#0x4000000		@ I/O regs
	mov r1,#1
	str r1,[r0, #0x208]		@ Re-enable interrupts

	b main

spiWaitBusy:
	push {r0, r1, r2}
	mov r0,#0x4000000
	orr r0,#0x1c0			@ SPICNT
	mov r2,#0x80			@ Checking bit 7 (busy flag)
spiWaitBusy_lp:
	ldrh r1,[r0]		@ Read SPICNT
	tst r1,r2			@ Test if SPI bus is busy	
	bne spiWaitBusy_lp		@ Check again if it still is
	pop {r0, r1, r2}
	mov pc,lr			@ Return

intrMain:
	mov r0,#0x4000000		@ I/O regs offset
	mov r2,#0
	str r2,[r0, #0x208]		@ Disable interrupts
	mov r1,#1
	neg r1,r1
	str r1,[r0, #0x214]		@ Acknowledge all interrupts
	str r1,[r0, #0x208]		@ Re-enable interrupts
	mov pc,lr			@ Return

	.thumb_func
swiHalt:
	swi 0x02
	bx lr
