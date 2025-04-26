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
    .pool

start:
    mov r0,#0x4000000       @ Main I/O offset
    mov r1,#0x3			    @ Both screens on - for REG_POWERCNT
	mov r2,#0x10000          
    orr r2,r2,#0x800
    orr r2,r2,#0x5          @ Engine A extended BG mode
	mov r3,#0x81		    @ Enable VRAM bank A @ 0x60000000- for REG_VRAMCNT_A
    mov r4,#0x4000		    @ BG3 parameters
	orr r4,#0x80		    @ = 4080

    str r1,[r0, #0x304]	    @ Set REG_POWERCNT
	str r2,[r0]			    @     REG_DISPCNT
	strb r3,[r0, #0x240]	@     REG_VRAMCNT_A
    strh r4,[r0, #0xE]	    @     REG_BG3CNT - this is halfword aligned!

    ldr r0,=0x27C3FFC
    adr r1,irqHandler
    str r1,[r0]             @ Write IRQ handler address to end of DTCM

    mov r0,#0x4000000       @ Main I/O offset again
    mov r1,#0x1
    str r1,[r0,#0x208]        @ Enable interrupts in REG_IME
    str r1,[r0,#0x210]        @ Enable VBlank interupt in REG_IE
    mov r1,#0x8
    str r1,[r0,#0x4]        @ Enable VBlank IRQ generation in REG_DISPSTAT


    mov r0,#0x6000000       @ Pointer to VRAM
    adr r3,logoBitmap       @ Pointer for bitmap data
    ldrh r1,[r3],#2         @ Load pixel into color register & advance pointer
    mov r2,#0x18000         @ Loop counter = 96K of pixels (256x192 pixels, 16 bit color)
    .pool

loop:
    strh r1,[r0],#2         @ Write pixel to VRAM and advance pointer
    ldrh r1,[r3],#2         @ load pixel into color register & advance pointer
    subs r2,r2,#1           @ Decrement loop counter
    bne loop                @ Loop until all pixels are copied

    mov r0,#0x5000000	    @ Palette memory
	adrl r3,logoPal		    @ Pointer for palette data (needs to be long)
	ldrh r1,[r3],#2		    @ Load palette data into color reg
	mov r2,#0x200		    @ Loop counter - 512B of memory

loop2:
    strh r1,[r0],#2		    @ Write pixel to palette memory
	ldrh r1,[r3],#2		    @ load the next one
	subs r2,r2,#1		    @ Decrement loop counter
	bne loop2				@ loop back until finished

    mov r0,#0x4000000 	    @ Going back to display registers
	mov r1,#0x100		    @ Value for transformation matrix values
    mov r2,#0x100           @ X coordinate
    mov r5,#0x100           @ Y coordinate
	strh r1,[r0,#0x30]	    @ REG_BG3PA
	strh r1,[r0,#0x36]	    @ REG_BG3PD
    str r2,[r0,#0x38]      @ REG_BG3X
    str r5,[r0,#0x3C]      @ REG_BG3Y
    mov r3,#0x48            @ X Loop counter
    mov r4,#0x0             @ X Direction
    mov r6,#0x28            @ Y Loop counter
    mov r7,#0x0             @ Y Direction
animate:
    swi 0x60000
    mov r0,#0x4000000
    subs r3,r3,#1
    eoreq r4,r4,#0x1        @ Change direction
    moveq r3,#0x90       @ Reset loop counter
    cmp r4,#0x1
    addne r2,r2,#0x100
    subeq r2,r2,#0x100
    str r2,[r0,#0x38]
    subs r6,r6,#1
    eoreq r7,r7,#0x1        @ Change Y direction
    moveq r6,#0x50          @ Reset Y loop counter
    cmp r7,#0x1
    addne r5,r5,#0x200
    subeq r5,r5,#0x200
    str r5,[r0,#0x3C]
    b animate

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
    .pool

    .include "logo.s"
