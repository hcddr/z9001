;basic_16d.rom			; 16 Farben, korr. CSAVE

	cpu	z80

; 05.11.2020 
; hi basic (rom-basic) z.B. f. mazogs und andere ROM-BASIC-Spiele
; Achtung Grafik-Erw geht nicht! Der Treiber �berlagert das Basic!
; Achtung 2: memory end < 36864 (9000h) !!
; 9000h-B7FFh


; Kassette R0111 	"BASIC_84" + "RAM"
; BASIC_84 		"BASIC_84" + "ROM"
; BASIC_85		"BASIC_85" + "ROM"
; BASIC_86 (BM600.ROM)	"BASIC_86" + "ROM"
; CP/M-BASIC orig	"BASIC_84" + "RAM" +CPM=1
; CP/M-BASIC vp		"BASIC_86" + "RAM" +CPM=1

;ROMTYP	EQU	"ROM"
ROMTYP	EQU	"RAMH"		;hi basic ab 9000h
;BASTYP	EQU	"BASIC_84"
;BASTYP	EQU	"BASIC_85"
BASTYP	EQU	"BASIC_86"
CPM	EQU	0		; CP/M-Version
p_EOR	EQU	0		; EOR-Patch (geht nur bei CPM=0 und BASIC_85 oder BASIC_86)

	
	include	basic_8k_kern.asm


; Patches
;V. Pohlers 13.12.2009
p_printat	equ	0	;PRINT AT �ber CALL 5 statt direktem Schreiben in den BWS
p_printatw	equ	0	;Window auf vollen Bildschrim setzen

;V. Pohlers 14.12.2009
p_80z		equ	0	;�nderung WINDOW f. max. 80 Zeichen/Zeile f. CRT80
;V. Pohlers 13.02.2012
p_disk		equ	1	;�nderung CALL 5 Block 0, damit ein sinnvoller Block 0 geschrieben wird
;V. Pohlers 30.10.2018				
p_zbs		equ	1	;Dateiendung '.ZBS' (analog CPM-Version) oder '.SSS', '.TTT'
				;(wichtig f�r Diskettenarbeit)

;U.Zander
p_farb16	equ	0	;INK, PAPER f. 16 Farben zulassen
p_wtape		equ	0	;Patch auf BIOS-Routinen statt CALL 5, verhindert Block 0
				;nicht nutzbar bei p_disk=1


;23.12.2019 ifdef-Variable !!
dirkdo		equ	1	; USB-Version


	include	bm608pd.asm
	;include	bm608.asm
	;include	M511.asm
	
	end
