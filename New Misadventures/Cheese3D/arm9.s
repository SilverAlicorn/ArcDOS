@@@ Make a cheese wedge looking thing and rotate it. Over time, rounding errors add up
@@@ and the shape distorts.

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
    ldr r1,=0x820F          @ Turn on 2D engine A/B, geometry engine, rendering engine, swap screens
    ldr r2,=0x1110D         @ Engine A extended BG mode, OBJs ON
	mov r3,#0x81		    @ Enable VRAM bank A @ 0x60000000- for Engine A BG

    str r1,[r0, #0x304]	    @ Set REG_POWERCNT
	str r2,[r0]			    @     REG_DISPCNT, engine A
	strb r3,[r0, #0x240]	@     REG_VRAMCNT_A
    ldr r0,=0x4001000       @ Engine B registers
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

    b GEStart
    .pool

GEStart:
    mov r0,#0x4000000       @ Display registers
    mov r1,#0x0
    str r1,[r0,#0x540]      @ SWAP_BUFFERS
    mov r1,#0x70            @ Turn on texture mapping & alpha blending & edge marking
    str r1,[r0,#0x60]       @ Write to DISP3DCNT
    ldr r1,=0x3F1F0000      @ Command for CLEAR_COLOR
    str r1,[r0,#0x350]      @ Write to CLEAR_COLOR
    mov r0,#0x4000000       @ Display registers
    ldr r1,=0xBFFF0000      @ Viewport coordinate X2 (X1,Y1 are 0)
    str r1,[r0,#0x580]      @ Write to VIEWPORT


    ldr r0,=0x4000440       @ MTX_MODE
    mov r1,#1
    str r1,[r0]             @ Set MTX_MODE to Position Matrix
    ldr r0,=0x4000468       @ MTX_MULT_3x3
    
    mov r1,#0x1000          @ Matrix Row 1
    str r1,[r0]             @ 1
    mov r1,#0
    str r1,[r0]             @ 0
    str r1,[r0]             @ 0

    mov r1,#0               @ Matrix Row 2
    str r1,[r0]             @ 0
    ldr r1,=0xE1C
    str r1,[r0]             @ .882
    ldr r1,=0xFFFFF879               
    str r1,[r0]             @ -.471

    mov r1,#0               @ Matrix Row 3
    str r1,[r0]             @ 0
    ldr r1,=0x787               
    str r1,[r0]             @ .471
    ldr r1,=0xE1C
    str r1,[r0]             @ .882

GECont:
    swi 0x60000             @ Wait for vblank
    bl drawCheese
    
    mov r0,#0x4000000       @ Display registers
    mov r1,#0
    str r1,[r0,#0x540]      @ SWAP_BUFFERS
    b GECont
    .pool

nf: b nf

drawCheese:
    @@@ Rotate the Position Matrix (Model View?) fractionally each frame.
    @@@ We are using Quaternions here to avoid gimbal lock.
    ldr r0,=0x4000440       @ MTX_MODE
    mov r1,#1
    str r1,[r0]             @ Set MTX_MODE to Position Matrix
    ldr r0,=0x4000468       @ MTX_MULT_3x3
    
    ldr r1,=0xFFC           @ Matrix Row 1
    str r1,[r0]             @ .992
    mov r1,#0
    str r1,[r0]             @ 0
    mov r1,#0xA3           
    str r1,[r0]             @ .04

    mov r1,#0               @ Matrix Row 2
    str r1,[r0]             @ 0
    mov r1,#0x1000               
    str r1,[r0]             @ 1
    mov r1,#0
    str r1,[r0]             @ 0

    ldr r1,=0xFFFFFF5D      @ Matrix Row 3
    str r1,[r0]             @-.04
    mov r1,#0
    str r1,[r0]             @ 0     
    ldr r1,=0xFFC
    str r1,[r0]             @ .992


    @@@ Begin drawing vertices
    mov r0,#0x4000000
    ldr r1,=0x2FF           @ Color = CHEESE YELLOW
    str r1,[r0,#0x480]      @ Write to COLOR
    ldr r0,=0x40004A4       @ POLYGON_ATTR
    ldr r1,=0x1F00C0        @ Set front & backface on, solid
    str r1,[r0]             @ Write to POLYGON_ATTR
    mov r0,#0x4000000
    mov r1,#0               @ Separate Triangle
    str r1,[r0,#0x500]      @ Send command to BEGIN_VTXS
    ldr r2,=0x83E1          @ X = -32, Y = 32, Z = 0
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0xF87E1         @ X = -32, Y = -32 , Z = 0 
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0x8020          @ X = 32, Y = 32, Z = 0
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r0,=0x4000504           
    str r1,[r0]        @ (END_VTXS)

    mov r0,#0x4000000
    ldr r1,=0x6BA           @ Color = CHEESE YELLOW DARKER
    str r1,[r0,#0x480]      @ Write to COLOR
    mov r1,#1               @ Separate quad
    str r1,[r0,#0x500]      @ Send command to BEGIN_VTXS
    ldr r2,=0xF87E1         @ X = -32, Y = -32 , Z = 0 
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0x8020          @ X = 32, Y = 32, Z = 0
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0xF08020          @ X = 32, Y = 32, Z = F
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0xFF87E1         @ X = -32, Y = -32 , Z = F 
    str r2,[r0,#0x490]      @ Send to VTX_10

    mov r0,#0x4000000
    mov r1,#1               @ Separate quad
    str r1,[r0,#0x500]      @ Send command to BEGIN_VTXS
    ldr r2,=0xF87E1         @ X = -32, Y = -32 , Z = 0 
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0x83E1          @ X = -32, Y = 32, Z = 0
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0xF083E1          @ X = -32, Y = 32, Z = F
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0xFF87E1         @ X = -32, Y = -32 , Z = F 
    str r2,[r0,#0x490]      @ Send to VTX_10

    mov r0,#0x4000000
    mov r1,#1               @ Separate quad
    str r1,[r0,#0x500]      @ Send command to BEGIN_VTXS
    ldr r2,=0x83E1          @ X = -32, Y = 32, Z = 0
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0x8020          @ X = 32, Y = 32, Z = 0
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0xF08020          @ X = 32, Y = 32, Z = 0
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0xF083E1          @ X = -32, Y = 32, Z = F
    str r2,[r0,#0x490]      @ Send to VTX_10

    mov r0,#0x4000000
    ldr r1,=0x2FF           @ Color = CHEESE YELLOW
    str r1,[r0,#0x480]      @ Write to COLOR
    mov r1,#0               @ Separate Triangle
    str r1,[r0,#0x500]      @ Send command to BEGIN_VTXS
    ldr r2,=0xF083E1          @ X = -32, Y = 32, Z = F
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0xFF87E1         @ X = -32, Y = -32 , Z = F 
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r2,=0xF08020          @ X = 32, Y = 32, Z = F
    str r2,[r0,#0x490]      @ Send to VTX_10
    ldr r0,=0x4000504           
    str r1,[r0]        @ (END_VTXS)

    bx lr
    .pool

    .align 2
irqHandler:                 @ BIOS branches here after saving scratch registers & lr to stack
    mov r0,#0x4000000       @ Main I/O offset
    mov r1,#0x0
    str r1,[r0,#0x208]      @ Disable interrupts in REG_IME
    mov r1,#0x1
    str r1,[r0,#0x214]      @ Acknowledge VRAM interrupt in REG_IF
    ldr r0,=0x27C3FF8       @ REG_IF mirror in DTCM
    str r1,[r0]             @ Acknowledge VRAM interrupt in REG_IF mirror
    ldr r10,=0xDEADBEEF
    mov r0,#0x4000000       @ Main IO offset
    mov r1,#0x1
    str r1,[r0,#0x208]      @ Enable interrupts in REG_IME
    bx lr                   @ Return to BIOS
    .pool