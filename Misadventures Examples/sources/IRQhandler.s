intrMain:
	mov r0,#0x4000000	@ I/O space offset
	mvn r1,#0		@ Set r1 to 0xFFFF

	str r1,[r0,#0x214]	@ Clear flags in IF

	bx lr	
