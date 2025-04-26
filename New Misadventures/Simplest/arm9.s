    .text
    .align 2

init:
    mov r0,#0x4000000       @ Main I/O offset
    mov r1,#0x3			    @ Both screens on - for REG_POWERCNT
	mov r2,#0x20000         @ Framebuffer video mode - for REG_DISPCNT
	mov r3,#0x80		    @ Enable VRAM bank A @ 0x68000000- for REG_VRAMCNT_A

    str r1,[r0, #0x304]	    @ Set REG_POWERCNT
	str r2,[r0]			    @     REG_DISPCNT
	strb r3,[r0, #0x240]	@     REG_VRAMCNT_A

    mov r3,#0x6800000       @ Pointer to VRAM
    mov r4,#0x1F            @ Color value - RED
    mov r5,#0x18000         @ Loop counter = 96K of pixels (256x192 pixels, 16 bit color)

loop:
    strh r4,[r3],#0x1       @ Write pixel to VRAM - and advance to the next pixel
    subs r5,r5,#0x1         @ Decrement loop counter
    bne loop                @ Loop until screen is full

nf: b nf                    @ Do nothing forever
