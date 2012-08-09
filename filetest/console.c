#include "ndsarm9.h"
#include "consolefont.h"
#include "asmfuncs.h"

/* Pointer to video memory where the hardware will expect to find the tile
 * map. Use this like an array of characters. */
unsigned short *map1 = (unsigned short*)0x6000000;

/* Enable a screen for some sweet textin'. Eventually we will initialize both
 * screens or put in a software keyboard or something. */
void console_init()
{
	POWCNT1 = ENABLE_SCREENS | ENGINE_A_2D | ENGINE_B_2D;

	VRAMCNT_A = VRAM_ENABLE | VRAM_MST1;	// Engine A BG
//	VRAMCNT_C = VRAM_ENABLE | VRAM_MST4;	// Engine B BG
	
	DISPCNT = NORM_DISPLAY | BG0_ENABLE;

	BG0CNT = BG_SIZE0 | BG_CHARBASE1;

	// BIOS functions are kinda like magic
	CpuSet(consolefontPal, &MAIN_PALMEM, consolefontPalLen);
	LZ77UnCompVram(consolefontTiles, VRAM_6000000 + 0x4000);
}

void putline(char *input, int linenum)
{
	int i;
	linenum = (linenum << 5);
	for (i = 0; i < 32; i++) {
		if (input[i] == 0)
			break;
		map1[linenum + i] = input[i];
	}
}
