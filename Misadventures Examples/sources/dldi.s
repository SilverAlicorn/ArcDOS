	b main

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
	.arm
main:
	bl console_init

	mov r0,#0
	mov r1,#1
	adr r2,readbuffer
	adrl r3, _io_dldi
	add r3,#0x10
	ldr r4,[r3]
	orr r4,#0x2000000
	blx r4

	adrl r0,mbrtext
	adr r1,textbuffer
	mov r2,#0
	bl print

	adr r1,readbuffer
	ldr r0,[r1, #0x1c2]
	adrl r1,mbrtext
binToString:
	mov r2,#0x30		@ ASCII for 0
	strb r2,[r1]		@ Write to string
	add r1,r1,#1		@ Move to next char
	mov r2,#0x62		@ ASCII for b
	strb r2,[r1]		@ Write to string
	add r1,r1,#1		@ Move to next char

	@ Now, mask each bit in the number and read it out to the string. Remember to write ASCII
	@ codes and not numerical values!
	
	mov r3,#0x80000000		@ Initial mask bit
	mov r4,#32			@ And loop 32 times
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

	adrl r0,mbrtext
	adr r1,textbuffer
	mov r2,#32
	bl print

	mov r0,#0x6200000
	bl updateScreen16

nf:	b nf

	.ascii "DEADBEEF"
readbuffer:
	.space 512

textbuffer:
	.space 768

mbrtext:
	.asciz "Partition 1 filesystem type:"
