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
    mov r1,#0x8200			@ Turn on 2D engine A/B, geometry engine, rendering engine
    orr r1,r1,#0xF          @ And swap screens
	mov r2,#0x11000          
    orr r2,r2,#0x100
    orr r2,r2,#0xD          @ Engine A extended BG mode, OBJs ON
	mov r3,#0x81		    @ Enable VRAM bank A @ 0x60000000- for Engine A BG
    mov r4,#0x4000		    @ BG3 parameters
	orr r4,#0x80		    @ = 4080
    mov r5,#0x84            @ Enable VRAM bank C @ 0x6200000 - For Engine B BG
    mov r6,#0x82            @ Enable VRAM bank E @ 0x6400000 - for Engine A OBJ
    mov r7,#0x82            @ Enable VRAM bank I @ 0x6600000 - For Engine B OBJ

    str r1,[r0, #0x304]	    @ Set REG_POWERCNT
	str r2,[r0]			    @     REG_DISPCNT, engine A
	strb r3,[r0, #0x240]	@     REG_VRAMCNT_A
    orr r0,r0,#0x240        @ Change address to VRAM registers
    strb r5,[r0,#0x2]       @ Set REG_VRAMCNT_C
    strb r6,[r0,#0x4]       @     REG_VRAMCNT_E
    strb r7,[r0,#0x9]       @     REG_VRAMCNT_I
    mov r0,#0x4000000       @ Main I/O offset
    add r0,r0,#0x1000
    ldr r2,=0x1190D
    str r2,[r0]             @ Set REG_DISPCNT, engine B
    strh r4,[r0, #0xE]	    @     REG_BG3CNT - engine B

    ldr r0,=0x27C3FFC
    adrl r1,irqHandler
    str r1,[r0]             @ Write IRQ handler address to end of DTCM

    mov r0,#0x4000000       @ Main I/O offset again
    mov r1,#0x1
    str r1,[r0,#0x208]        @ Enable interrupts in REG_IME
    str r1,[r0,#0x210]        @ Enable VBlank interupt in REG_IE
    mov r1,#0x8
    str r1,[r0,#0x4]        @ Enable VBlank IRQ generation in REG_DISPSTAT


    mov r0,#0x6200000       @ Pointer to VRAM - Engine B BG
    adrl r3,logoBitmap       @ Pointer for bitmap data
    ldrh r1,[r3],#2         @ Load pixel into color register & advance pointer
    mov r2,#0x10000         @ Loop counter = 32K of pixels (256x256 pixels, 8 bit color)          
    b logo_lp
    .pool

logo_lp:
    strh r1,[r0],#2         @ Write pixel to VRAM and advance pointer
    ldrh r1,[r3],#2         @ load pixel into color register & advance pointer
    subs r2,r2,#1           @ Decrement loop counter
    bne logo_lp             @ Loop until all pixels are copied

    mov r0,#0x5000000	    @ Palette memory
    orr r0,r0,#0x400        @ Engine B BG palette
	adrl r3,logoPal		    @ Pointer for palette data (needs to be long)
	ldrh r1,[r3],#2		    @ Load palette data into color reg
	mov r2,#0x100		    @ Loop counter - 256B of memory
pal_lp:
    strh r1,[r0],#2		    @ Write pixel to palette memory
	ldrh r1,[r3],#2		    @ load the next one
	subs r2,r2,#1		    @ Decrement loop counter
	bne pal_lp				@ loop back until finished

    mov r0,#0x6600000       @ Pointer to Engine B OBJ tile area
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
    orr r0,r0,#0x600        @ Pointer to OBJ palette space
    adrl r3,fontPal       @ Pointer for tile data
    ldr r1,[r3],#4          @ Load some pixels & advance pointer
    mov r2,#0x80           @ Loop counter = 80 words of data
obj_pal_lp:
    str r1,[r0],#4		    @ Write pixel to OBJ tile memory
	ldr r1,[r3],#4		    @ load the next one
	subs r2,r2,#1		    @ Decrement loop counter
    bne obj_pal_lp

    @@@ Minimal Geometry Engine setup protocol. We need to swap the buffers to wake the Engine up.
    @@@ We're also drawing a triangle and saving the vertices to main memory for animation later.
GESetup:
    mov r0,#0x4000000       @ Display registers
    mov r1,#0x0
    str r1,[r0,#0x540]      @ SWAP_BUFFERS
    mov r1,#0x50            @ Turn on texture mapping & alpha blending
    str r1,[r0,#0x60]       @ Write to DISP3DCNT
    ldr r1,=0x3F1F0000      @ Command for CLEAR_COLOR
    str r1,[r0,#0x350]      @ Write to CLEAR_COLOR
    orr r0,r0,#0x354        @ CLEAR_DEPTH
    mov r1,#0x7F00          @ Clear depth high bits
    orr r1,r1,#0xFF         @ Low bits
    str r1,[r0]             @ Write to CLEAR_DEPTH
    mov r0,#0x4000000       @ Display registers
    ldr r1,=0xBFFF0000      @ Viewport coordinate X2 (X1,Y1 are 0)
    str r1,[r0,#0x580]      @ Write to VIEWPORT
    mov r1,#0x3E0           @ Color = GREEN
    str r1,[r0,#0x480]      @ Write to COLOR
    mov r0,#0x4000000       @ Display registers
    orr r0,r0,#0x4A0
    orr r0,r0,#0x4          @ POLYGON_ATTR
    ldr r1,=0x1F00C0        @ Set front & backface on, alpha solid
    str r1,[r0]             @ Write to POLYGON_ATTR
    mov r0,#0x4000000
    mov r1,#0               @ Separate Triangle
    str r1,[r0,#0x500]      @ Send command to BEGIN_VTXS
    mov r2,#0x08000         @ Y = 32, Z = 0
    orr r2,r2,#0x3F0        @ X = -32 ish 
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r3,=0x2000000       @ Main memory
    str r2,[r3]             @ Save a copy to main mem

    mov r1,#0x1F           @ Color = BLUE
    str r1,[r0,#0x480]      @ Write to COLOR

    mov r2,#0xF8000         @ Y = -32 , Z = 0
    orr r2,#0x3F0           @ X = -32
    str r2,[r0,#0x490]      @ Send to VTX_10
    str r2,[r3,#0x4]       @ Save a copy to main mem

    mov r1,#0x7C00           @ Color = RED
    str r1,[r0,#0x480]      @ Write to COLOR

    mov r2,#0xA000            @ Y = 28, Z = 0 (and a couple bits from X)
    orr r2,#0x20           @ X = 20
    str r2,[r0,#0x490]      @ Send to VTX_10
    str r2,[r3,#0x8]        @ Save a copy to main mem

    ldr r0,=0x4000504           
    str r1,[r0]        @ (END_VTXS)
    mov r0,#0x40000000
    str r1,[r0,#0x440]      @ Set MTX_MODE to Projection matrix
    add r0,r0,#0x450        @ Move r0 closer to 0x454
    str r1,[r0,#0x4]        @ Send MTX_IDENTITY to matrix stack
    
    mov r0,#0x4000000       @ Display registers

    str r1,[r0,#0x540]      @ SWAP_BUFFERS
    b main
    .pool


main:
    mov r0,#0x4000000 	    @ Going back to display registers
    orr r0,r0,#0x1000       @ Engine B
	mov r1,#0x100		    @ Value for BG transformation matrices
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
    mov r0,#0x4000000       
    orr r0,r0,#0x1000       @ Engine B control offset
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

    bl animTri              @ Draw the triangle again
    b animate               @ loop forever

animTri:                    @ Animate the triangle, we're low on registers so use some pointers to main mem
    stmdb sp!,{r2,r3,r4,r5,r6,lr}       @ Save these scratch registers the main program is using
    mov r0,#0x2000000       @ Main mem where we stored the copied vertices
    bl processVertex

    add r0,#0x4             @ Point to the 2nd vertex
    bl processVertex

    add r0,#0x4             @ Point to the 3rd vertex
    bl processVertex

    mov r0,#0x4000000       @ Display registers
    orr r0,r0,#0x4A0
    orr r0,r0,#0x4          @ POLYGON_ATTR
    ldr r1,=0x1F00C0        @ Set front & backface on, alpha solid
    str r1,[r0]             @ Write to POLYGON_ATTR
    mov r0,#0x4000000
    mov r1,#0               @ Separate Triangle
    str r1,[r0,#0x500]      @ Send command to BEGIN_VTXS

    mov r3,#0x2000000
    mov r1,#0x3E0           @ Color = GREEN
    str r1,[r0,#0x480]      @ Write to COLOR
    ldr r4,[r3],#4          @ Load 1st vertex and advance pointer
    str r4,[r0,#0x490]      @ Send to VTX_10

    mov r1,#0x1F           @ Color = RED
    str r1,[r0,#0x480]      @ Write to COLOR
    ldr r4,[r3],#4          @ Load 2nd vertex and advance pointer
    str r4,[r0,#0x490]      @ Send to VTX_10

    mov r1,#0x7C00           @ Color = RED
    str r1,[r0,#0x480]      @ Write to COLOR
    ldr r4,[r3],#4          @ Load 2nd vertex and advance pointer
    str r4,[r0,#0x490]      @ Send to VTX_10

    b animTri_exit
    .pool

animTri_exit:
    mov r0,#0x4000000       @ Display registers
    str r1,[r0,#0x540]      @ SWAP_BUFFERS
    ldmia sp!,{r2,r3,r4,r5,r6,lr}       @ Restore saved registers
    bx lr

nf: b nf                    @ Do nothing forever

objPrint:                   @ Convert an ASCII string into several OBJs - r0 = string ptr; r1 coords
    stmdb sp!,{r2,r3,r4}       @ Save these scratch registers the main program is using
    mov r2,#0x7000000       @ OAM
    orr r2,r2,#0x400        @ Engine B
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

    @@@ OKAY LISTEN UP:
    @@@ For this bit, we have 10bit packed vertex coordinates stored in memory. Pass the address in R2 and this routine 
    @@@ will write the new location back to that address. NOTE that we are using bits 30 and 31 in the vertex data to
    @@@ control which direction the vertex moves in. The DS does not use these bits with 10bit packed coordinates.
    @@@ It's free real estate
processVertex:
    stmdb sp!,{r4,r5,r6,lr}        @ Save non scratch registers & lr
    ldr r1,[r0]                   @ Load the vertex into a register
    and r2,r1,#0xC0000000       @ Grab the direction bits
    mov r10,r2                  @ Copy to r10 for debug
    ldr r12,=0x3FF               @ Mask for X coordinate, making sure we have it for later too
    and r3,r1,r12                @ Load the X coordinate
    ldr r5,=0xFFC00
    and r4,r1,r5
    mov r4,r4,LSR #10           @ Load and shift the Y coordinate
    tst r2,#0x40000000          @ Test the X direction bit
    beq pv_left             @ Move vertex LEFT if 0
    bne pv_right            @ Move vertex RIGHT if 1
pv_left:
    sub r3,r3,#1            @ Move vertex left
    and r3,r3,r12            @ Discard overflow bits
    cmp r3,#0x3C0            @ Compare with left border of screen 
    eoreq r2,#0x40000000     @ Flip the directional control bit
    addeq r3,r3,#2           @ move to the right a little so it doesn't get stuck
    b pv_cont
pv_right:
    add r3,r3,#1            @ Move vertex right
    cmp r3,#0x40            @ Compare with right border of screen
    eoreq r2,#0x40000000    @ Flip the directional control bit
    b pv_cont
pv_cont:
    tst r2,#0x80000000      @ Test the Y direction bit
    beq pv_up               @ Move vertex UP if 0
    bne pv_down             @ Move vertex DOWN if 1
pv_up:
    add r4,r4,#1            @ Move vertex up
    cmp r4,#0x40            @ Compare with top border of screen
    eoreq r2,#0x80000000    @ Flip the directional control bit
    b pv_exit
pv_down:
    sub r4,r4,#1           @ Move vertex DOWN
    cmp r4,#0x3C0           @ Compare with bottom border of screen
    eoreq r2,#0x80000000    @ Flip the directional control bit
    b pv_exit
pv_exit:
    and r4,r4,r12               @ Grab the Y coordinate
    mov r4,r4,LSL #10           @ Shift the Y coordinate back
    orr r2,r2,r4                @ OR the Y coordinate into the output register
    orr r2,r2,r3                @ OR the X coordinate into the output register
    str r2,[r0]                 @ Write the vertex back out to memory
    ldmia sp!,{r4,r5,r6,lr}        @ Restore saved registers
    bx lr

unpackVTXTen:            @ Unpacks a VX_10 into r1 and r2, leaving r0 alone. Skips the Z coordinate for now
    stmdb sp!,{r4,r5,lr}       @ Save these scratch registers the main program is using
    ldr r1,[r0]
    ldr r2,=0x3FF              
    and r3,r1,r2            @ Load the X coordinate
    mov r2,#0xC0000000
    and r5,r1,r2            @ save the direction bits
    ldr r2,=0xFFC00
    and r4,r1,r2
    mov r4,r4,LSR #10       @ Load and shift the Y coordinate
    mov r1,r3
    mov r2,r4
    mov r3,r5
    ldmia sp!,{r4,r5,lr}       @ Restore saved registers
    bx lr
    .pool

packVTXTen:              @ Takes r1 and r2 and packs them into r3.
    mov r3,r2,LSL #10
    orr r3,r1
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

helloText: .asciz "Hello world! Shout out to DevKitPro for making this possible!"

    .include "logo.s"
    .include "font.s"
