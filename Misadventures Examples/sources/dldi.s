	b main		@ Skip over to main program!

	.space 252

@---------------------------------------------------------------------------------
	.align	4
	.arm
	.global _io_dldi
@---------------------------------------------------------------------------------
.equ FEATURE_MEDIUM_CANREAD,		0x00000001
.equ FEATURE_MEDIUM_CANWRITE,		0x00000002
.equ FEATURE_SLOT_GBA,				0x00000010
.equ FEATURE_SLOT_NDS,				0x00000020


_dldi_start:

@---------------------------------------------------------------------------------
@ Driver patch file standard header -- 16 bytes
	.word	0xBF8DA5ED		@ Magic number to identify this region
	.asciz	" Chishm"		@ Identifying Magic string (8 bytes with null terminator)
	.byte	0x01			@ Version number
	.byte	0x0F	@32KiB	@ Log [base-2] of the size of this driver in bytes.
	.byte	0x00			@ Sections to fix
	.byte 	0x0F	@32KiB	@ Log [base-2] of the allocated space in bytes.
	
@---------------------------------------------------------------------------------
@ Text identifier - can be anything up to 47 chars + terminating null -- 16 bytes
	.align	4
	.asciz "Default (No interface)"

@---------------------------------------------------------------------------------
@ Offsets to important sections within the data	-- 32 bytes
	.align	6
	.word   _dldi_start		@ data start
	.word   _dldi_end		@ data end
	.word	0x00000000		@ Interworking glue start	-- Needs address fixing
	.word	0x00000000		@ Interworking glue end
	.word   0x00000000		@ GOT start					-- Needs address fixing
	.word   0x00000000		@ GOT end
	.word   0x00000000		@ bss start					-- Needs setting to zero
	.word   0x00000000		@ bss end

@---------------------------------------------------------------------------------
@ IO_INTERFACE data -- 32 bytes
_io_dldi:
	.ascii	"DLDI"					@ ioType
	.word	0x00000000				@ Features
	.word	_DLDI_startup			@ 
	.word	_DLDI_isInserted		@ 
	.word	_DLDI_readSectors		@   Function pointers to standard device driver functions
	.word	_DLDI_writeSectors		@ 
	.word	_DLDI_clearStatus		@ 
	.word	_DLDI_shutdown			@ 
	
@---------------------------------------------------------------------------------

_DLDI_startup:			@ void
_DLDI_isInserted:		@ void
_DLDI_readSectors:		@ u32 sector, u8 numSecs, void* buffer
_DLDI_writeSectors:		@ u32 sector, u8 numSecs, void* buffer
_DLDI_clearStatus:		@ void
_DLDI_shutdown:			@ void
	mov		r0, #0x00				@ Return false for every function
	bx		lr



@---------------------------------------------------------------------------------
	.align
	.pool

.space 32632						@ Fill to 32KiB

_dldi_end:
@---------------------------------------------------------------------------------

@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@ ~ Real Program Starts Here ~ @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	.include "toolbox.s"
	.arm			@ Toolbox ends in THUMB mode
main:
	bl console_init		@ Initialize screens for text

	mov r0,#0		@ LBA of first sector to read
	mov r1,#1		@ # of sectors to read
	adr r2,readbuffer	@ buffer to read into
	adrl r3, _io_dldi + 0x10	@ Get pointer for DLDI read command
	ldr r3,[r3]		@ Dereference pointer
	orr r3,#0x2000000	@ Correct address
	blx r3

	adrl r0,mbrtext		@ Message about what's being printed
	adr r1,textbuffer	@ Buffer to print to
	mov r2,#0		@ Cursor position
	bl print

	adr r1,readbuffer
	ldrb r0,[r1, #0x1c2]	@ Get partition type for first partition
@	adr r2,beeftag
@	ldr r0,[r2]
	adrl r1,mbrtext		@ Store it in this now unused spot
	bl binToHex
	b cont

beeftag:
	.word 0xBEEF2011

@------------------------------------------------------------------------------	
binToString:
	mov r2,#0x30		@ ASCII for 0
	strb r2,[r1]		@ Write to string
	add r1,r1,#1		@ Move to next char
	mov r2,#0x62		@ ASCII for b
	strb r2,[r1]		@ Write to string
	add r1,r1,#1		@ Move to next char

	@ Now, mask each bit in the number and read it out to the string.
	@ Remember to write ASCII
	@ codes and not numerical values!
	
	mov r3,#0x80		@ Initial mask bit
	mov r4,#8			@ And loop 8 times
binToString_loop:
	tst r0,r3			@ Compare input to mask bit
	moveq r2,#0x30		@ Write a 0 if it's 0
	movne r2,#0x31		@ Or write a 1 if it isn't
	strb r2,[r1]		@ Write it to the string
	add r1,r1,#1		@ Advance string pointer
	lsr r3,r3,#1		@ Shift mask bit right one
	subs r4,r4,#1		@ Decrement loop counter
	bne binToString_loop	@ Loop back

	mov r2,#0			@ String delimiter
	strb r2,[r1]		@ Close off string
@------------------------------------------------------------------------------

@------------------------------------------------------------------------------
@ binToHex takes the 32-bit value in r0 and turns it into an 8-char string of
@ ASCII characters. It expects a pointer to memory for the string output in
@ r1. Strings produced are null-terminated to work with the toolbox print
@ function.
@------------------------------------------------------------------------------
binToHex:
	mov r4,#0xA		@ Less than A? add 0x30. More? add 0x41
	mov r2,#0xF0000000
	and r3,r0,r2		@ Get the most significant nybble
	lsr r3,#28
	cmp r3,r4		@ Is the value less than 0xA?
	addlt r3,#0x30		@ Convert to numeric ASCII value
	addgt r3,#0x37		@ Otherwise convert to alphabetic (A-F)
	strb r3,[r1],#1		@ Copy to output string

	mov r2,#0x0F000000
	and r3,r0,r2		@ Get next nybble
	lsr r3,#24
	cmp r3,r4		@ Less than 0xA?
	addlt r3,#0x30		@ Convert to numeric
	addgt r3,#0x37		@ Otherwise alpha
	strb r3,[r1],#1		@ Copy to output string

	mov r2,#0x00F00000
	and r3,r0,r2		@ Get next nybble
	lsr r3,#20
	cmp r3,r4		@ Less than 0xA?
	addlt r3,#0x30		@ Convert to numeric
	addgt r3,#0x37		@ Otherwise alpha
	strb r3,[r1],#1		@ Copy to output string

	mov r2,#0x000F0000
	and r3,r0,r2		@ Get next nybble
	lsr r3,#16
	cmp r3,r4		@ Less than 0xA?
	addlt r3,#0x30		@ Convert to numeric
	addgt r3,#0x37		@ Otherwise alpha
	strb r3,[r1],#1		@ Copy to output string

	mov r2,#0x0000F000
	and r3,r0,r2		@ Get next nybble
	lsr r3,#12
	cmp r3,r4		@ Less than 0xA?
	addlt r3,#0x30		@ Convert to numeric
	addgt r3,#0x37		@ Otherwise alpha
	strb r3,[r1],#1		@ Copy to output string

	mov r2,#0x00000F00
	and r3,r0,r2	@ Get next nybble
	lsr r3,#8
	cmp r3,r4		@ Less than 0xA?
	addlt r3,#0x30		@ Convert to numeric
	addgt r3,#0x37		@ Otherwise alpha
	strb r3,[r1],#1		@ Copy to output string

	mov r2,#0x000000F0
	and r3,r0,r2		@ Get next nybble
	lsr r3,#4
	cmp r3,r4		@ Less than 0xA?
	addlt r3,#0x30		@ Convert to numeric
	addgt r3,#0x37		@ Otherwise alpha
	strb r3,[r1],#1		@ Copy to output string

	mov r2,#0x0000000F
	and r3,r0,r2		@ Get last nybble
	cmp r3,r4		@ Less than 0xA?
	addlt r3,#0x30		@ Convert to numeric
	addgt r3,#0x37		@ Otherwise alpha
	strb r3,[r1],#1		@ Copy to output string



	mov r2,#0
	strb r2,[r1]		@ Close off string

	bx lr			@ Return
@------------------------------------------------------------------------------

cont:
	adrl r0,mbrtext
	adr r1,textbuffer
	mov r2,#32		@ Print binary string on second line
	bl print

	mov r0,#0x6200000	@ Display buffer on sub screen
	bl updateScreen16

nf:	b nf

	.ascii "DEADBEEF"	@ String to help find this section in a debugger
readbuffer:
	.space 512

textbuffer:
	.space 768

mbrtext:
	.asciz "Partition 1 filesystem type:"
