    .text
    .align 2

init:
    msr cpsr_c,#0xD3         @ Set CPU to supervisor mode
    mov r12,#0x78          @ Set exception vector to 0x00000000 - Is this necessary?
    mcr p15,0,r12,cr1,cr0,0  @ Write this commmand to master control register
    mov r0,#0x20
    mcr p15,0,r0,c9,c1,1    @ Set up ITCM - 0x0 - 32M
    orr r12,r12,#0x40000    @ Enable ITCM
    mcr p15,0,r12,cr1,cr0,0 @ Write this command to master control register

    msr cpsr_c,#0x1F        @ Switch CPU to system mode

start:
    mov r0,#0x4000000       @ Main I/O offset
    mov r1,#0x3			    @ Both screens on - for REG_POWERCNT
	mov r2,#0x20000         @ Framebuffer video mode - for REG_DISPCNT
	mov r3,#0x80		    @ Enable VRAM bank A @ 0x68000000- for REG_VRAMCNT_A

	str r1,[r0, #0x304]	    @ Set REG_POWERCNT
	str r2,[r0]			    @     REG_DISPCNT
	strb r3,[r0, #0x240]	@     REG_VRAMCNT_A

    mov r0,#0x8
    ldr r1,irqVector
    str r1,[r0]             @ Install IRQ vector

    mov r0,#0x100           @ Might as well put the IRQ handler here
    adr r1,irqHandler
    ldr r2,[r1]             @ Load the first instruction and move the source pointer ahead
    mov r3,#0x34            @ Length of handler
copyHandler:
    str r2,[r0],#4          @ Write instruction and move dest pointer ahead
    add r1,r1,#4            @ Move source pointer along
    ldr r2,[r1]             @ load next instruction
    subs r3,r3,#1           @ Decrement loop counter
    bne copyHandler         @ Loop until finished


    mov r0,#0x4000000       @ Main I/O offset again
    mov r1,#0x1
    str r1,[r0,#0x208]        @ Enable interrupts in REG_IME
    str r1,[r0,#0x210]        @ Enable VBlank interupt in REG_IE
    mov r1,#0x8
    str r1,[r0,#0x4]        @ Enable VBlank IRQ generation in REG_DISPSTAT

    mov r3,#0x6800000       @ Pointer to VRAM
    mov r4,#0x0             @ Color value
    mov r6,#0x2000000       @ Start of main memory
    strh r4,[r6]            @ Write color value memory
    mov r5,#0x18000         @ Loop counter = 96K of pixels (256x192 pixels, 16 bit color)

loop:
    mcr p15,0,r0,c7,c0,4    @ Halt CPU and wait for interrupts
    mov r6,#0x2000000       @ Start of main memory, where we saved the color value
    ldr r4,[r6]             @ Load color value into r4
    strh r4,[r3],#0x1       @ Write pixel to VRAM - and advance to the next pixel
    subs r5,r5,#1         @ Decrement loop counter
    bne loop                @ Loop until screen is full

nf: b nf                    @ Do nothing forever

irqVector:
    .word 0xEA00003C        @ Should branch to #0x100

irqHandler:                 @ This does NOT save any registers to stack!
    mov r0,#0x4000000       @ Main I/O offset
    mov r1,#0x0
    str r1,[r0,#0x208]      @ Disable interrupts in REG_IME
    mov r1,#0x1
    str r1,[r0,#0x214]      @ Acknowledge VRAM interrupt in REG_IF
    mov r0,#0x2000000        @ Start of main memory, where we saved the color value
    ldr r1,[r0]             @ Load it into r1
    add r1,r1,#0x1          @ Add 1 to make it a different color
    str r1,[r0]             @ Write back to DTCM
    mov r0,#0x4000000       @ Main IO offset
    mov r1,#0x1
    str r1,[r0,#0x208]      @ Enable interrupts in REG_IME
    subs pc,lr,#0x04        @ Switch back to previous CPU mode and return to interrupted code
