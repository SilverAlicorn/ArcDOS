init:
	mov r0,#0x04000000	@ I/O space offset
	mov r1,#0x3		@ Both screens on
	mov r2,#0x00020000	@ Framebuffer mode
	mov r3,#0x80		@ VRAM bank A enabled, LCD

	str r1,[r0, #0x304]	@ Set POWERCNT
	str r2,[r0]		@     DISPCNT
	str r3,[r0, #0x240]	@     VRAMCNT_A

	mov r0,#0x06800000	@ VRAM offset
	mov r3,#0x2000000
	orr r3,#0x1000		@ Touch data from ARM7
	ldrh r1,[r3]		@ Load pixel to color reg
	mov r2,#0xC000		@ Loop size for 96k pixels

lp:	strh r1,[r0],#2		@ Write a pixel
	ldrh r1,[r3]		@ Load next pixel
	subs r2,r2,#1		@ Move along one
	bne lp			@ Loop back if not finished

	mov r0,#0x68000000	@ Back to vmem start
	mov r2,#0xC000		@ Remake loop
	ldrh r1,[r3]		@ Load color again
	b lp			@ Back to loop
