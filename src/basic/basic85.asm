; BASIC_85		"BASIC_85" + "ROM"

	cpu	z80

ROMTYP	EQU	"ROM"
;ROMTYP	EQU	"RAM"
;BASTYP	EQU	"BASIC_84"
BASTYP	EQU	"BASIC_85"
;BASTYP	EQU	"BASIC_86"
CPM	EQU	0		; CP/M-Version
p_EOR	EQU	0		; EOR-Patch (geht nur bei CPM=0 und BASIC_85 oder BASIC_86)

	
	include	basic_8k_kern.asm

	include	m511.asm
	
	end
