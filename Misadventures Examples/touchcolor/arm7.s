init:
	mov r0,#0x4000000		@ I/O register offset
	mov r1,#1
	str r1,[r0, #0x210]		@ Enable vblank interrupt in IE
	mov r1,#0x8
	str r1,[r0, #0x4]		@ DISPSTAT Generate interrupt on vblank

	str r1,[r0, #0x208]		@ Enable interrupts in IME	
	adr r1,intrMain
	str r1,[r0, #-4]		@ Install our interrupt handler at 0x3fffffc
	
	adr r0,main
	add r0,r0,#1
	bx r0

	.align
	.thumb
main:
	bl swiHalt			@ Wait for interrupt	

	ldr r0,adrIME
	mov r1,#0
	str r1,[r0]		@ Disable interrupts (in IME)

	ldr r0,adrSPI		@ SPI regs base
	bl spiWaitBusy		@ Check that we can use the SPI
	
	ldr r2,flagSPIStartTSC	@ Enable SPI, talking to touchscreen (0x8a01)

	strh r2,[r0]		@ Write command to SPICNT

	mov r3,#0xd0		@ command to request X-pos from touchscreen
	
	strh r3,[r0, #2]	@ Write command to SPIDATA
	bl spiWaitBusy		@ Wait until SPI is clear again

	strh r1,[r0, #2]	@ Strobe SPIDATA to start transfer
	bl spiWaitBusy		@ Wait again
	ldrh r4,[r0, #2]	@ Read SPIDATA

	ldr r2,flagSPIEndTSC	@ Flags to signal end of transfer (0x8201)

	strh r2,[r0]		@ Signal end of transfer
	strh r1,[r0, #02]		@ Strobe SPIDATA again
	bl spiWaitBusy
	ldrh r5,[r0, #02]	@ Read TSC data

	ldr r6,adrTouchData	@ Memory location for touch data
	mov r2,#0x7f
	and r4,r2
	lsl r4,r4,#5
	lsr r5,r5,#3
	
	orr r4,r4,r5		@ Combine r4 & r5 to one bitfield
	str r4,[r6]		@ Save touch data to memory
	
	ldr r0,adrIME		@ Interrupt master enable
	mov r1,#1
	str r1,[r0]		@ Re-enable interrupts

	b main

	.align
flagSPIStartTSC:
	.word 0x00008a01

flagSPIEndTSC:
	.word 0x00008201

	.arm
intrMain:
	mov r0,#0x4000000		@ I/O regs offset
	mov r2,#0
	str r2,[r0, #0x208]		@ Disable interrupts
	mov r1,#1
	neg r1,r1
	str r1,[r0, #0x214]		@ Acknowledge all interrupts
	str r1,[r0, #0x208]		@ Re-enable interrupts
	mov pc,lr			@ Return

	.thumb
swiHalt:
	swi 0x02
	bx lr

spiWaitBusy:		@ Only works if called from THUMB code!
	push {r0, r1, r2}
	ldr r0,adrSPI		@ SPI base address
	mov r2,#0x80			@ Checking bit 7 (busy flag)
spiWaitBusy_lp:
	ldrh r1,[r0]		@ Read SPICNT
	tst r1,r2			@ Test if SPI bus is busy	
	bne spiWaitBusy_lp		@ Check again if it still is
	pop {r0, r1, r2}
	mov pc,lr			@ Returns

	.align
adrSPI:
	.word 0x040001c0

adrIORegs:
	.word 0x04000000

adrIME:
	.word 0x04000208

adrTouchData:
	.word 0x02001000

