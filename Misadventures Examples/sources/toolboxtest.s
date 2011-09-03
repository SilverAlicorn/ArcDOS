
b main
	.include "toolbox.s"
	.include "font.s"
	
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

	bl updateScreen16

nf: 	b nf
	
	.align
maintext:
	.asciz "Hello, Nintendo DS!\n This is a text demo."
	
	.align
subtext:
	.asciz "We are drawing on two screens as well."

	.align
buffer_main:
	.space 768

	.align
buffer_sub:
	.space 768
