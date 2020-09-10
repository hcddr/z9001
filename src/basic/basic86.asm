; BASIC_86 (BM600.ROM)	"BASIC_86" + "ROM"

	cpu	z80

ROMTYP	EQU	"ROM"
;ROMTYP	EQU	"RAM"
;BASTYP	EQU	"BASIC_84"
;BASTYP	EQU	"BASIC_85"
BASTYP	EQU	"BASIC_86"
CPM	EQU	0		; CP/M-Version
p_EOR	EQU	0		; EOR-Patch (geht nur bei CPM=0 und BASIC_85 oder BASIC_86)

	
	include	basic_8k_kern.asm

; Patches (original - alle deaktiviert)
p_printat	equ	0
p_printatw	equ	0
p_80z		equ	0
p_disk		equ	0
p_farb16		equ	0
p_wtape		equ	0

	include	bm608pd.asm
	
	end
