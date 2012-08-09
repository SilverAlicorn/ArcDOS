/* ndsarm9.h - definitions for registers on the ARM9 side
 * 
 * By Faye Duhamel, adapted from nocash's GBATEK, buyer beware!
 *
 * Empty flags are provided to make code more readable. */

/* DISPCNT -- Display setup for Engine A (main screen) */
/* DISPCNTSUB -- Display setup for Engine B (sub screen ) */
#define DISPCNT		*(unsigned int*)0x4000000
#define DISPCNTSUB	*(unsigned int*)0x4001000
#define BG0_ENABLE	0x100
#define NORM_DISPLAY	0x10000
#define VRAM_DISPLAY	0x20000
#define RAM_DISPLAY	0x30000

/* BGxCNT -- Background layer settings
 * The screen base block is a 5bit value, so you should OR a shifted value
 * to the register. */
#define BG0CNT		*(unsigned int*)0x4000008
#define BG1CNT		*(unsigned int*)0x400000a
#define BG2CNT		*(unsigned int*)0x400000c
#define BG3CNT		*(unsigned int*)0x400000e
#define BG0CNTSUB	*(unsigned int*)0x4001008
#define BG1CNTSUB	*(unsigned int*)0x400100a
#define BG2CNTSUB	*(unsigned int*)0x400100c
#define BG3CNTSUB	*(unsigned int*)0x400100e
#define BG_CHARBASE0	0x0
#define BG_CHARBASE1	0x4
#define BG_16COL	0x0
#define BG_256COL	0x80
#define BG_SCREENBASEMASK	0x1f00
#define BG_SIZE0	0x0

/* VRAMCNT_x -- VRAM mapping / settings */
/* I still don't know what MST stands for, but it's some sort of mode select
   for each memory bank. Not all banks accept all MST values, and sometimes
   banks cannot have the same MSTs. See GBATEK for a full breakdown. */
#define VRAMCNT_A	*(unsigned int*)0x4000240
#define VRAMCNT_B	*(unsigned int*)0x4000241
#define VRAMCNT_C	*(unsigned int*)0x4000242
#define VRAM_MST0	0x0
#define VRAM_MST1	0x1
#define VRAM_MST2	0x2
#define VRAM_MST3	0x3
#define VRAM_MST4	0x4
#define VRAM_OFFSET0	0x0
#define VRAM_OFFSET1	0x8
#define VRAM_OFFSET2	0x10
#define VRAM_OFFSET3	0x18
#define VRAM_ENABLE	0x80

/* POWCNT1 -- Graphics power control */
#define POWCNT1		*(unsigned int*)0x4000304
#define ENABLE_SCREENS	0x1
#define ENGINE_A_2D	0x2
#define ENGINE_B_2D	0x200
#define MAIN_ON_TOP	0x8000

#define MAIN_PALMEM	*(unsigned short*)0x5000000
#define SUB_PALMEM	*(unsigned short*)0x5000400
#define VRAM_6000000	0x6000000
