init:
	mov r0,#0x4000000	@ I/O space offset
	mov r1,#0x3		@ Both screens on
	mov r2,#0x10000		@ 2D mode 0
	orr r2,#0x100		@ BG0 On
	mov r3,#0x81		@ Bank A enabled @ 0x6000000

	str r1,[r0, #0x304]	@ Set POWERCNT
	str r2,[r0]		@     DISPCNT
	str r3,[r0, #0x240]	@     VRAMCNT_A

	mov r1,#0x84		@ BG0 tile mode, 32x32 @ 256
	str r1,[r0, #0x8]	@ Into BG0CNT

	mov r0,#0x5000000	@ Palette memory
	mov r1,#0x7C00		@ Blue
	strh r1,[r0]		@ Copy to palette memory
	mov r1,#0xC00		@ Darker blue
	strh r1,[r0, #0x2]	@ Copy to palette memory
	mov r1,#0x3E0		@ Green
	strh r1,[r0, #0x4]	@ Copy to palette mem

	@ Tile ram - 0x6004000
	@ Map ram -  0x6000000

	adr r0,bluetile		@ CpuSet source address
	mov r1,#0x6000000	@ CpuSet dest address base
	orr r1,#0x4000		@ Dest address offset
	mov r2,#32		@ # of halfwords to copy
	blx swiCpuSet

	adr r0,darktile		@ Next source address
	add r1,r1,#64		@ Next dest address
	blx swiCpuSet

	adr r0,tilemap		@ Source
	mov r1,#0x6000000	@ Map memory
	mov r2,#1024
	blx swiCpuSet

nf:	b nf			@ Loop forever

	.align 2
	.thumb_func
swiCpuSet:
	swi 0x0B		@ swi to CpuSet
	bx lr

	.include "tiledata.s"

