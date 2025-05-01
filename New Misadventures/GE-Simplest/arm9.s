@ Load up the Geometry Engine with the absolute bare minimum of setup

    .text
    .align 2

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
    b GETest
    .pool

GETest:
    mov r1,#0x0
    mov r0,#0x4000000       @ Display registers
    str r1,[r0,#0x540]      @ SWAP_BUFFERS

    mov r0,#0x4000000       @ Display registers
    mov r1,#0x70            @ Turn on texture mapping & alpha blending
    str r1,[r0,#0x60]       @ Write to DISP3DCNT
    ldr r1,=0x1F001F        @ Command for CLEAR_COLOR
    str r1,[r0,#0x350]      @ Write to CLEAR_COLOR
  
    mov r0,#0x4000000       @ Display registers
    ldr r1,=0xBFFF0000      @ Viewport coordinates (X1,Y1 are 0, X2=255,Y2=191)
    str r1,[r0,#0x580]      @ Write to VIEWPORT

    mov r1,#0x0
    mov r0,#0x4000000       @ Display registers
    str r1,[r0,#0x540]      @ SWAP_BUFFERS
    b nf
    .pool

nf: b nf
