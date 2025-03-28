;------------------------------------------------------------------------------
; WINDOW-Befehl für OS
; V.Pohlers 31.05.2013
; Code i.W. aus bm608.asm
;------------------------------------------------------------------------------

		cpu	z80

		ifndef includeprg
		org	1000h
		endif


GVAL: 		equ	0F1EAh
spsv:		equ	0073h		;freier Bereich im FCB
numcols:	equ	0075h		;Anzahl Spalten + 2

p_80z		equ	1	;Änderung WINDOW f. max. 80 Zeichen/Zeile f. CRT80
		
;-------------------------------------------------------------------------------
; Kommando-Rahmen
;-------------------------------------------------------------------------------

		jp	WINDOW		
		db	"WINDOW  ", 0
		db	0

;-------------------------------------------------------------------------------
; Test auf 80-Zeichen-Modus
; TXCON Zeichenkette durchsuchen, ob 80 vorkommt -> dann 80-Zeichen-Modus
;-------------------------------------------------------------------------------

test80:		ld	a,42
		ld	(numcols),a
;
		ld	hl, (0EFE9h)	; TXCON
test80a		ld	a, (hl)
		or	a		; 0-Byte = Ende erreicht
		ret	z
		cp	'8'
		inc	hl
		jr	nz, test80a
		ld	a, (hl)
		cp	'0'
		jr	nz, test80a
		ld	a,82		;80 gefunden
		ld	(numcols),a
		ret	
		
;-------------------------------------------------------------------------------
; Parameter holen
; Ret A = Parameter
;-------------------------------------------------------------------------------

param:		ex	af, af'
		jr	c, ERPAR	; keine weiteren Parameter
		call	gval		; nächsten Parameter holen
		jr	nz, ERPAR	; wenn keine Zahl
		jr	c, ERPAR	; wenn Fehler im Parameter
		ret
		
ERPAR:		ld	SP, (spsv)	;Stack richten
 		LD	A,1		;error 1  Eingabe eines unerlaubten Parameters
		SCF
		RET

;-----------------------------------------------------------------------------
; WINDOW erste_zeile, letzte_zeile, erste_spalte, letzte_spalte
; WINDOW ist gleich WINDOW 0,23,0,39
;-----------------------------------------------------------------------------

WINDOW:		ld	(spsv), SP
		call	test80
	
		ld	c, 29		; DCU - Cursor löschen
		call	5
;		
		ex	af, af'
		jr	c, window3	;wenn keine Parameter
		ex	af, af'
;
		call	param		;Argument holen
		push	af
		call	param		;Argument holen
		push	af
		call	param		;Argument holen
		push	af
		call	param		;Argument holen
		inc	a
		inc	a
		ld	d, a		;d=letzte_spalte+2
		ld	hl,numcols	;42 oder 82
		cp	(hl)		;letzte_spalte+2 < 42 ?
		jr	nc, window2	;nein, d.h. letzte_spalte >= 40
		pop	af
		ld	e, a		;e=erste_spalte
		pop	af
		inc	a
		inc	a
		ld	b, a		;b=letzte_zeile+2
		cp	26		;letzte_zeile+2 < 26?
		jr	nc, window2	;nein, d.h. letzte_zeile >= 24
		pop	af
		ld	c, a
		inc	a
		cp	b		;erste_zeile+1 < letzte_zeile+2 ?
		jr	nc, window2	;nein, d.h. erste_zeile > letzte_zeile
		ld	a, e
		inc	a
		cp	d		;erste_spalte+1 < letzte_spalte+2 ?
		jr	nc, window2	;nein, d.h. erste_spalte > letzte_spalte
		jr	window1
;
window3:	ld	bc, 1900h	;Zeilen 1 - 18h=24
		ld	e,c		;Spalten 1 - 40/80
		ld	a,(numcols)		
		dec	a		;41 (29h) oder 81 (51h)
		ld	d,a
window1:	ld	(3Dh), de	;E=P3ROL (1. ZU ROLLENDE SPALTE-1)
					;D=P4ROL (LETZTE ZU ROLLENDE SPALTE+1)
		ld	(3Bh), bc	;C=P1ROL (1. ZU ROLLENDE ZEILE-1)
					;B=P2ROL (LETZTE ZU ROLLENDE ZEILE+1)
		ld	d, c		;Cursor auf Fensteranfang
		inc	d
		inc	e
		ld	c, 18		; SETCU
		call	5
		ret
;
window2:	LD	A,1		; error 3  Überschreitung des zulässigen Zahlenbereichs
		SCF
		RET

;		end
