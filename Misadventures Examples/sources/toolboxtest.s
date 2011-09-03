
b main
	.include "toolbox.s"
	
	.arm
main:
	bl console_init

	adr r0,maintext
	adr r1,buffer_main
	mov r2,#0
	bl print

	adr r0,subtext
	adr r1,buffer_sub
	mov r2,#0
	bl print

	mov r0,#0x6000000
	adr r1,buffer_main
	bl updateScreen16

	mov r0,#0x6200000
	adr r1,buffer_sub
	bl updateScreen16

nf: 	b nf
	
	.align
maintext:
	.asciz "Hello, Nintendo DS!\nThis is a text demo."
	
	.align
subtext:
	.ascii "We are drawing on two screens as"
	.asciz "well."

	.align
buffer_main:
	.space 768

	.align
buffer_sub:
	.space 768
