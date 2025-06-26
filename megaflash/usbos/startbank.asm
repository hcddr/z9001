; Startbank enthält das kleine CH376-OS
; + Stater für Mega-Flash-Software

	cpu	z80

;------------------------------------------------------------------------------
	
	org	0c000h
	binclude ch376os.rom
	

;------------------------------------------------------------------------------

	include	../includes.asm	
	
	align 100h
	jp	mega
	db	"MEGA    ",0
	db	0

mega:	ld	hl,starta
	ld	de,start0
	ld	bc,starte-starta
	ldir
	jp 	start0
	
starta:
	phase 80h
	
start0:	ld	a, systembank
	out	(bankport), a
	jp	0F000h
	
	dephase
starte:
	
;------------------------------------------------------------------------------
	end	
