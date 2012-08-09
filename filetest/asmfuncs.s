@ Calling THUMB functions from ARM code
	.text
	.code 32
	.global LZ77UnCompVram
LZ77UnCompVram:
	push {lr}
	blx bios_swi12
	pop {pc}

	.global CpuSet
CpuSet:
	push {lr}
	blx bios_swi0b
	pop {pc}

	.align
	.code 16
bios_swi0b:
	swi 0x0b
	bx lr
bios_swi12:
	swi 0x12
	bx lr
