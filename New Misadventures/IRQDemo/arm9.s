    .text
    .align 2

init:
    msr cpsr_c,#0xD3         @ Set CPU to supervisor mode
    ldr r12,=0x2078          @ Set exception vector to FFFF0000h - that's where the BIOS lives
    mcr p15,0,r12,cr1,cr0,0  @ Write this commmand to master control register
    mov r0,#0x0
    mcr p15,0,r0,cr7,cr5,0     @ Invalidate entire instruction cache
    mcr p15,0,r0,cr7,cr6,0     @ Invalidate entire Data Cache
    mcr p15,0,r0,cr7,cr10,4    @ Drain write buffer
    ldr r0,=0x27C0000
    orr r0,r0,#0xA
    mcr p15,0,r0,cr9,cr1,0     @ Set DTCM to 0x27C0000, 16K
    mov r0,#0x20
    mcr p15,0,r0,c9,c1,1    @ Set up ITCM - 0x0 - 32M
    orr r12,r12,#0x50000    @ Enable DTCM/ITCM
    mcr p15,0,r12,cr1,cr0,0 @ Write this command to master control register

    ldr sp,=0x27C3FC0       @ Set supervisor stack pointer
    msr cpsr_c,#0xD2        @ Switch CPU to IRQ mode
    ldr sp,=0x27C3F80       @ Set IRQ stack pointer
    msr cpsr_c,#0x1F        @ Switch CPU to system mode
    ldr sp,=0x27C3E80       @ Set system mode stack pointer and unmask interrupts

start:
    mov r0,#0x4000000       @ Main I/O offset
    mov r1,#0x3			    @ Both screens on - for REG_POWERCNT
	mov r2,#0x20000         @ Framebuffer video mode - for REG_DISPCNT
	mov r3,#0x80		    @ Enable VRAM bank A @ 0x68000000- for REG_VRAMCNT_A

	str r1,[r0, #0x304]	    @ Set REG_POWERCNT
	str r2,[r0]			    @     REG_DISPCNT
	strb r3,[r0, #0x240]	@     REG_VRAMCNT_A

    ldr r0,=0x27C3FFC
    adr r1,irqHandler
    str r1,[r0]             @ Write IRQ handler address to end of DTCM

    mov r0,#0x4000000       @ Main I/O offset again
    mov r1,#0x1
    str r1,[r0,#0x208]        @ Enable interrupts in REG_IME
    str r1,[r0,#0x210]        @ Enable VBlank interupt in REG_IE
    mov r1,#0x8
    str r1,[r0,#0x4]        @ Enable VBlank IRQ generation in REG_DISPSTAT

    mov r3,#0x6800000       @ Pointer to VRAM
    mov r4,#0x0             @ Color value
    ldr r6,=0x27C0000       @ Start of DTCM
    strh r4,[r6]            @ Write color value to DTCM
    mov r5,#0x18000         @ Loop counter = 96K of pixels (256x192 pixels, 16 bit color)

loop:
    swi 0x60000             @ Halt CPU and wait for interrupts
    ldr r6,=0x27C0000       @ Start of DTCM, where we saved the color value
    ldr r4,[r6]             @ Load color value into r4
    strh r4,[r3],#0x1       @ Write pixel to VRAM - and advance to the next pixel
    subs r5,r5,#0x1         @ Decrement loop counter
    bne loop                @ Loop until screen is full

nf: b nf                    @ Do nothing forever

irqHandler:                 @ BIOS branches here after saving scratch registers & lr to stack
    mov r0,#0x4000000       @ Main I/O offset
    mov r1,#0x0
    str r1,[r0,#0x208]      @ Disable interrupts in REG_IME
    mov r1,#0x1
    str r1,[r0,#0x214]      @ Acknowledge VRAM interrupt in REG_IF
    ldr r0,=0x27C3FF8       @ REG_IF mirror in DTCM
    str r1,[r0]             @ Acknowledge VRAM interrupt in REG_IF mirror
    ldr r0,=0x27C0000       @ Start of DTCM, where we saved the color value
    ldr r1,[r0]             @ Load it into r1
    add r1,r1,#0x1          @ Add 1 to make it a different color
    str r1,[r0]             @ Write back to DTCM
    mov r0,#0x4000000       @ Main IO offset
    mov r1,#0x1
    str r1,[r0,#0x208]      @ Enable interrupts in REG_IME
    bx lr                   @ Return to BIOS