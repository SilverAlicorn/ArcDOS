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
    b start
    .pool

start:
    mov r0,#0x4000000       @ Main I/O offset
    mov r1,#0x3			    @ Both screens on - for REG_POWERCNT
	mov r2,#0x11000          
    orr r2,r2,#0x800
    orr r2,r2,#0x5          @ Engine A extended BG mode, OBJs ON
	mov r3,#0x81		    @ Enable VRAM bank A @ 0x60000000- for REG_VRAMCNT_A
    mov r4,#0x4000		    @ BG3 parameters
	orr r4,#0x80		    @ = 4080
    mov r5,#0x82            @ Enable VRAM bank E @ 0x6400000 - for OBJ

    str r1,[r0, #0x304]	    @ Set REG_POWERCNT
	str r2,[r0]			    @     REG_DISPCNT, engine A
	strb r3,[r0, #0x240]	@     REG_VRAMCNT_A
    strh r4,[r0, #0xE]	    @     REG_BG3CNT - this is halfword aligned!
    orr r0,r0,#0x244        @ Change address to REG_VRAMCNT_E
    strb r5,[r0]            @ Set REG_VRAMCNT_E
    mov r0,#0x4000000       @ Main I/O offset
    add r0,r0,#0x1000
    str r2,[r0]             @ Set REG_DISPCNT, engine B

    ldr r0,=0x27C3FFC
    adrl r1,irqHandler
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
    mov r2,#0x10000         @ Loop counter = 32K of pixels (256x192 pixels, 8 bit color)          
    b logo_lp
    .pool

logo_lp:
    strh r1,[r0],#2         @ Write pixel to VRAM and advance pointer
    ldrh r1,[r3],#2         @ load pixel into color register & advance pointer
    subs r2,r2,#1           @ Decrement loop counter
    bne logo_lp             @ Loop until all pixels are copied

    mov r0,#0x5000000	    @ Palette memory
	adrl r3,logoPal		    @ Pointer for palette data (needs to be long)
	ldrh r1,[r3],#2		    @ Load palette data into color reg
	mov r2,#0x100		    @ Loop counter - 256B of memory
pal_lp:
    strh r1,[r0],#2		    @ Write pixel to palette memory
	ldrh r1,[r3],#2		    @ load the next one
	subs r2,r2,#1		    @ Decrement loop counter
	bne pal_lp				@ loop back until finished

    mov r0,#0x6400000       @ Pointer to Engine A OBJ tile area
    orr r0,r0,#0x400        @ Add some empty space so the tiles line up with ASCII codes
    adrl r3,fontTiles       @ Pointer for tile data
    ldr r1,[r3],#4          @ Load some pixels & advance pointer
    mov r2,#0x300            @ Loop counter = 768 words of data
obj_lp:
    str r1,[r0],#4		    @ Write pixel to OBJ tile memory
	ldr r1,[r3],#4		    @ load the next one
	subs r2,r2,#1		    @ Decrement loop counter
    bne obj_lp

    mov r0,#0x5000000
    orr r0,r0,#0x200        @ Pointer to OBJ palette space
    adrl r3,fontPal       @ Pointer for tile data
    ldr r1,[r3],#4          @ Load some pixels & advance pointer
    mov r2,#0x80           @ Loop counter = 80 words of data
obj_pal_lp:
    str r1,[r0],#4		    @ Write pixel to OBJ tile memory
	ldr r1,[r3],#4		    @ load the next one
	subs r2,r2,#1		    @ Decrement loop counter
    bne obj_pal_lp

main:
    mov r0,#0x4000000 	    @ Going back to display registers
	mov r1,#0x100		    @ Value for transformation matrix values
    mov r2,#0x100           @ X coordinate
    mov r5,#0x100           @ Y coordinate
	strh r1,[r0,#0x30]	    @ REG_BG3PA
	strh r1,[r0,#0x36]	    @ REG_BG3PD
    str r2,[r0,#0x38]      @ REG_BG3X
    str r5,[r0,#0x3C]      @ REG_BG3Y
    mov r3,#0x48            @ X Loop counter    @ NDS extended backgrounds are a little weird,
    mov r4,#0x0             @ X Direction       @ The origin is in the middle instead of the corner.
    mov r6,#0x28            @ Y Loop counter    @ So you need to put in positive numbers to scroll left,
    mov r7,#0x0             @ Y Direction       @ Or negative numbers to scroll right.
    mov r8,#0x0             @ X coordinate for scrolling text
animate:
    swi 0x60000             @ Call BIOS to halt CPU & wait for interrupts
    mov r0,#0x4000000       @ Reload main I/O space
    subs r3,r3,#1           @ Decrement X loop
    eoreq r4,r4,#0x1        @ Change X direction
    moveq r3,#0x90          @ Reset X loop counter
    cmp r4,#0x1             @ Test which direction we're moving in
    addne r2,r2,#0x100      @ Move left
    subeq r2,r2,#0x100      @ Or move right
    str r2,[r0,#0x38]       @ Write offset to control register

    subs r6,r6,#1           @ Decrement Y loop
    eoreq r7,r7,#0x1        @ Change Y direction
    moveq r6,#0x30          @ Reset Y loop counter
    cmp r7,#0x1             @ Test which direction we're mobing in
    addne r5,r5,#0x200      @ Move left
    subeq r5,r5,#0x200      @ Or move right
    str r5,[r0,#0x3C]       @ Write offset to control register

    adrl r0,helloText
    mov r1,r8,LSL #23       @ Load X coordinate and discard upper bits
    mov r1,r1,LSR #7        @ Move it back to the start of the high word
    orr r1,r1,#0x90         @ OR the Y coordinate
    bl objPrint
    sub r8,r8,#1            @ Increment X coordinate

    b animate               @ loop forever

nf: b nf                    @ Do nothing forever

objPrint:                   @ Convert an ASCII string into several OBJs - r0 = string ptr; r1 coords
    stmdb sp!,{r2,r3,r4}       @ Save these scratch registers the main program is using
    mov r2,#0x7000000       @ OAM
    mov r12,#8              @ Offset from initial X coordinate
    ldrb r3,[r0],#1         @ Load a char and advance pointer
objPrint_lp:
    cmp r3,#0               @ Check if it's the end of the string (NULL)
    beq objPrint_exit       @ Exit loop if NULL
    ldrh r4,[r2,#2]         @ Look ahead to the next X coordinate
    mov r4,r4,LSL #26
    mov r4,r4,LSR #26       @ Grab just the last few bits
    tst r4,#0x20            @ Test bit 3
    addeq r4,r1,r4            @ Add to the Y coordinate to shift the position a little
    subne r4,r1,r4          @ ... or maybe subtract it
    addne r4,r4,#0x40
    strh r4,[r2],#2         @ Write Y-coordinate to attr 0 and advance to attr 1
    mov r1,r1,ROR #16       @ Rotate out Y-coordinate
    strh r1,[r2],#2         @ Write X-coordinate to attr 1 and advance to attr 2
    strh r3,[r2],#4         @ Write the ASCII value to the character name in attr 3, advance to next OBJ
    ldrb r3,[r0],#1         @ Load a char and advance pointer
    add r1,r1,r12           @ Add X offset
    mov r1,r1,ROR #16
    b objPrint_lp           @ Loop to next char
objPrint_exit:
    ldmia sp!,{r2,r3,r4}       @ Restore saved registers
    bx lr

irqHandler:                 @ BIOS branches here after saving scratch registers & lr to stack
    mov r0,#0x4000000       @ Main I/O offset
    mov r1,#0x0
    str r1,[r0,#0x208]      @ Disable interrupts in REG_IME
    mov r1,#0x1
    str r1,[r0,#0x214]      @ Acknowledge VRAM interrupt in REG_IF
    ldr r0,=0x27C3FF8       @ REG_IF mirror in DTCM
    str r1,[r0]             @ Acknowledge VRAM interrupt in REG_IF mirror
    mov r0,#0x4000000       @ Main IO offset
    mov r1,#0x1
    str r1,[r0,#0x208]      @ Enable interrupts in REG_IME
    bx lr                   @ Return to BIOS
    .pool

helloText: .asciz "Hello world! Thanks to DevKitPro for making this possible!"

    .include "logo.s"
    .include "font.s"
