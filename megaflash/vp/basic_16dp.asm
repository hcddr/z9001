; "vp\basic_16dp.rom"			; 16 Farben, korr. CSAVE, neues PRINT-AT

	cpu	z80


; Kassette R0111 	"BASIC_84" + "RAM"
; BASIC_84 		"BASIC_84" + "ROM"
; BASIC_85		"BASIC_85" + "ROM"
; BASIC_86 (BM600.ROM)	"BASIC_86" + "ROM"
; CP/M-BASIC orig	"BASIC_84" + "RAM" +CPM=1
; CP/M-BASIC vp		"BASIC_86" + "RAM" +CPM=1

ROMTYP	EQU	"ROM"
;ROMTYP	EQU	"RAM"
;BASTYP	EQU	"BASIC_84"
;BASTYP	EQU	"BASIC_85"
BASTYP	EQU	"BASIC_86"
CPM	EQU	0		; CP/M-Version
p_EOR	EQU	1		; EOR-Patch (geht nur bei CPM=0 und BASIC_85 oder BASIC_86)

	
	include	basic_8k_kern.asm



; Patches
;V. Pohlers 13.12.2009
p_printat	equ	1	;PRINT AT über CALL 5 statt direktem Schreiben in den BWS
p_printatw	equ	0	;Window auf vollen Bildschrim setzen

;V. Pohlers 14.12.2009
p_80z		equ	1	;Änderung WINDOW f. max. 80 Zeichen/Zeile f. CRT80
;V. Pohlers 13.02.2012
p_disk		equ	1	;Änderung CALL 5 Block 0, damit ein sinnvoller Block 0 geschrieben wird
				;(wichtig für Diskettenarbeit)
;V. Pohlers 30.10.2018				
p_zbs		equ	1	;Dateiendung '.ZBS' (analog CPM-Version) oder '.SSS', '.TTT'
				;(wichtig für Diskettenarbeit)

;U.Zander
p_farb16	equ	1	;INK, PAPER f. 16 Farben zulassen
;p_farb16p	equ	1	;Border 16 Farben
p_wtape		equ	0	;Patch auf BIOS-Routinen statt CALL 5, verhindert Block 0
				;nicht nutzbar bei p_disk=1


;23.12.2019 ifdef-Variable !!
dirkdo		equ	1	; USB-Version


	include	bm608pd.asm
	;include	bm608.asm
	;include	M511.asm
	
	end
