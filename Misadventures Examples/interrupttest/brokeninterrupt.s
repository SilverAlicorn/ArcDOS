main:
	mov r0,#0x04000000      @ I/O space offset
	mov r1,#0x3             @ Both screens on
	mov r2,#0x00020000      @ Framebuffer mode
	mov r3,#0x80            @ VRAM bank A enabled, LCD

	str r1,[r0, #0x304]     @ Set POWERCNT
	str r2,[r0]             @     DISPCNT 
	str r3,[r0, #0x240]     @     VRAMCNT_A
    
	mov r1,#0x1		@ enable interrupts
	mov r2,#0x1		@ enable vblank interrupt
	str r1,[r0, #0x208]	@ IME
	str r2,[r0, #0x210]	@ IE

	mov r1, #1
	negs r1,r1		@ = 0xFFFFFFFF, so we can clear all the flags
	str r1,[r0, #0x214]	@ clear all pending interrupts (in IF)

	mov r1, #0x8
@	str r1,[r0,#0x4]	@ Generate vblank interrupts

	mrs r2, CPSR		@ read program status
	mov r0, #0x1f
	msr CPSR_fc, r0		@ Enter supervisor mode
	adr r1,intrMain
	mrc p15,0,r0,c9,c1	@ Find DTCM base address
	mov r0,r0,lsr #12
	mov r0,r0,lsl #12	@ Get rid of unnecessary bits
	add r0,r0,#0x4000	@ + 4000
	str r1,[r0,#-4]
	mov r1, #1
	str r1,[r0,#-8]		@ Write to IRQ check bits

nf:	mcr p15,0,r0,c7,c0,4	@ Halt CPU and wait for interrupt
	b nf

intrMain:
	mov r0,#0x06800000      @ VRAM offset
	mov r1,#31              @ Writing red pixels
	mov r2,#0xC000          @ 96k of them

drawloop:
	strh r1,[r0],#2         @ Write a pixel
	subs r2,r2,#1           @ Move along one
	bne drawloop           @ And loop back if not done
	b nf
