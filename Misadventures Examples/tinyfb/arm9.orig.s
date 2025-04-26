	.text
	.align 2	
main:
	mov r0,#0x04000000
	mov r1,#0x3
	mov r2,#0x00020000
	mov r3,#0x80

	str r1,[r0, #0x304]
	str r2,[r0]
	str r3,[r0, #0x240]

	mov r0,#0x06800000
	mov r1,#31
	mov r2,#0xC000

lp:	strh r1,[r0],#2
	subs r2,r2,#1
	bne lp

flash:  add r1,r1,#1
	mov r0,#0x06800000
	mov r2,#0xC000
	b lp
