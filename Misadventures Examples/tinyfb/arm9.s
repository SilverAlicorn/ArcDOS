main:
		@ sets POWER_CR
	mov r0, #0x4000000
	orr r0, r0, #0x300
	orr r0, r0, #0x4
	mov r1, #0x200
	orr r1, r1, #0x3
	str r1, [r0]
 
		@ sets mode
	mov r0, #0x04000000
	mov r1, #0x00020000
	str r1, [r0]
 
		@ sets VRAM bank a
	mov r0, #0x04000000
	add r0, r0, #0x240
	mov r1, #0x80
	strb r1, [r0]
 
		@ loop
	mov r0, #0x06800000
	ldrh r1,image
	mov r2, #0x18000
 
	filloop:
		strh r1, [r0], #0x1
		subs r2, r2, #0x1
		bne filloop
 
	lforever:
      b lforever

image:
	.hword 0xB0C0

