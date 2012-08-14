@ Calling THUMB functions from ARM code
	.text
	.global LZ77UnCompVram
	.thumb_func
LZ77UnCompVram:
	swi 0x12
	bx lr

	.global CpuSet
	.thumb_func
CpuSet:
	swi 0x0b
	bx lr

	.align
	.code 16
bios_swi0b:
	swi 0x0b
	bx lr
bios_swi12:
	swi 0x12
	bx lr
