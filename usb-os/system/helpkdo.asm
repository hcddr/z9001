;------------------------------------------------------------------------------
; Z9001 USB-OS
; (c) V. Pohlers 10.12.2019 
; letzte Änderung 
;------------------------------------------------------------------------------

		cpu	z80undoc

		if phase="CODE"

RED:    		EQU     0114H
GREEN:  		EQU     0214H
YELLOW:   		EQU     0314H
BLUE:   		EQU     0414H
MAGENTA:		EQU     0514H
CYAN:   		EQU     0614H
WHITE:  		EQU     0714H 


CSTS:		equ	0F006h		;STATUS CONST
CONSI:		equ	0F009h		;EINGABE ZEICHEN VON CONST
;CONSO:		equ	0F00Ch		;AUSGABE ZEICHEN ZU CONST
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H
GVAL    	EQU	0F1EAh
REA1		EQU	0F5A6h
ERINP   	EQU	0F5E2h
ERPAR   	EQU	0F5E6h
ERDIS   	EQU	0F5EAh

PARBU:		EQU	0040H		;HILFSZELLE (wird nur von ALDEV genutzt)
FCB: 		EQU	005Ch 		;Dateikontrollblock
DMA:		EQU	001BH		;STANDARDPUFFER FUER KASSETTE
 INTLN:		equ	0100h		;interner Zeichenkettenpuffer
;
NMBUF		equ	FCB		;Zwischenspeicher für Name etc.

AADR:		EQU	00300H		;ANFANGSADRESSE


;jpvecbas	equ	0C23DH
;		include	modul.inc

		endif
			
;; jetzt in menukdo.asm
;		org	1000h

		if phase="MENU"

		jp	help
		db	"HELP    ",0
		;; db	0
		
		endif

		if phase="CODE"


;;;COOUT Ausgabe ab (HL) (B) Zeichen, nur Buchstaben
;;;
;;COOUT:		LD	A,(HL)
;;		CP	A, ' '
;;		JR	NC, COUT1
;;		LD	A,'.'
;;COUT1:		CALL	OUTA			;Zeichen ausgeben
;;		INC	HL
;;		DJNZ	COOUT
;;		RET

;------------------------------------------------------------------------------
; HELP [pgm]		Anzeige einer Hilfe zum Programm
;			ohne Parameter: Liste aller Hilfetexte
;------------------------------------------------------------------------------

HELP:		
		;; call	GVAL			; GVAL wurde in GOCPM schon aufgerufen (f. Kommandoname)
		ex	af,af'			; Cy'=1 kein weiterer Parameter in CONBU
		jr	c,HELP1			; wenn kein Parameter
		call	GVAL
		xor	a
		cp	b			; Länge = 0?
		jr	z, HELP1

		; mit Parameter 
		call	showhlp			; Hilfe anzeigen
		jr	HELPEND

		; ohne Parameter
HELP1:		call	help0


HELPEND:	ld	e,2			;grün
		call	color
		
		;neue Zeile, wenn nötig
		ld	c,17			;GETCU
		call	5
		ld	a,e			;E Spalte des Cursors
		cp	1
		CALL	NZ, OCRLF
;		
		or	a
		ret


;------------------------------------------------------------------------------
; mit Parameter: Anzeigen der Hilfe
;------------------------------------------------------------------------------


showhlp:	; Laden ...

	if p_load==0		;Laden per eigenem Code

;DATEI LADEN OHNE START
hload1:	LD	HL,ERPAR
	PUSH	HL
	LD	A,(INTLN)	;PARAMETERLAENGE
	CP	A, 9
	RET	NC		;NAME ZU LANG
	LD	DE,FCB
	LD	A,8
	CALL	MOV		;NAME IN FCB EINTRAGEN
	EX	AF, AF'
	JR	NC, hload3	;DATEITYP FOLGT
	EX	AF, AF'
	LD	HL,"LH"		;STANDARDEINTRAGUNG
	LD	(FCB+8),HL	;
	LD	A,'P'		;HLP VORNEHMEN
	LD	(FCB+10),A	;
	JR	hLOA33
hload3:	LD	A,C
	CP	A, '.'
	POP	HL
	JP	NZ, ERINP	;FALSCHES TRENNZEICHEN
	PUSH	HL
	CALL	GVAL		;PARAMETER HOLEN
	RET	Z		;KEIN GUELTIGER TYP
	LD	A,3
	CP	A, B		;TYP IST ZU LANG
	RET	C
	LD	DE,FCB+8	;TYP IN FCB EINTRAGEN
	CALL	MOV
hLOA33:	POP	HL
	EX	AF, AF'		;'
	JP	NC, ERINP	;ZU VIELE PARAMETER
;
hload4:	;CALL	OPENR
	ld	a,'N'
	ld	(fcb+24),a 	;ohne kopfblock laden
;	
	ld	c,13		;OPENR
	call	5
	JR	NC, hload5	;KEIN FEHLER
	OR	A
	SCF
	RET	Z		;STOP GEGEBEN
	CALL	REA1		;AUSG. FEHLERMELD. WARTEN REAKT.
	RET
	;RET	C		;STOP GEGEBEN
	;JR	hload4		;WIEDERHOLUNG
hload5:	LD	HL,AADR		;DATEIANFANGSADRESSE
	LD	(DMA),HL	;NACH ADR. KASSETTENPUFFER
hLOA55:	;CALL	READ		;LESEN BLOCK
	ld	c,20		; READ
	call	5
	JR	NC, hload6	;KEIN FEHLER
	CALL	REA1		;AUSG. FEHLERMELD. WARTEN REAKT.
	RET	C		;STOP GEGEBEN
	XOR	A
hload6:	OR	A
	JR	Z, hLOA55	;WEITER BIS DATEIENDE LESEN
	CALL	OCRLF
;

	else			;pLoad = 1, laden via CALL5
	
;;fext	db	"HLP"
	
hload1:	ld	hl,fcb+24
	ld	(HL), 'N'	; kein Kopfblock
	LD	HL,AADR		; neue Zieladr.
	ld	a,83h		; Dateiname in CONBU
	ld	ix,dirzbsc+1	; Filetyp HLP
	ld	c,34		; CLOAD
	call	5
	RET	C
	
	endif


	;0-Byte anfügen
	ld	hl,(fcb+25)	;LEADR
	ld	(hl),0

	; Anzeigen
	ld	hl, AADR
outtext:
	ld 	a,(hl)
	cp	0
	jr	z, ende
	cp	'<'		; attrib?
	call	z,check
	call	outa
	inc	hl
	jr	outtext
ende:
	xor	a
	ret

; UP's

	if p_load==0		;Laden per eigenem Code

MOV:	LD	HL,INTLN+1	;ZWISCHENPUFFER
	LD	B,A
MOV2:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	MOV2
	RET

	endif
	
;umwandeln Steuercodes
;Attribut-Suche
check:	ld	de, attrib
check0:	push	hl
check1:	inc	hl
	ld	c,(hl)
	ld	a,(de)
	cp	20h
	jr	c,check3	; ende erreicht
	cp	a,c
	jr	nz,check2	; nicht gleich
	inc	de
	jr	check1

;nicht gleich, nächstes Attribut testen
check2:	inc	de
	ld	a,(de)
	cp	20h		; Attributende?
	jr	nc,check2	
	cp	0		; Listenende?
	jr	z,check4
	inc	de
	pop	hl
	jr	check0
;gleich, gefunden
check3:	ld	e,a
	ld	a,(hl)
	cp	'>'		; attrib?
	jr	nz,check4
	ld	a,14h		; Farbe folgt
	call	outa
	ld	a,e		; Farbe
	pop	de		; HL von Stack nehmen
	ret
;nichts gefunden		
check4:	pop	hl
	ld	a,(hl)
	ret	


attrib:
	db "RED",01
	db "GREEN",02
	db "YELLOW",03
	db "BLUE",04
	db "MAGENTA",05
	db "CYAN",06
	db "WHITE",07
	db 0

;------------------------------------------------------------------------------
; kein Parameter: Auflisten aller HLP-Dateien
;------------------------------------------------------------------------------

HELP0:		ld	de, hlptxt
		ld	c, 9
		call	5

;Auflisten aller HLP-Dateien
		
dirzbs:		ld	a,0c0h		;mit Suchmuster, keine Ext. anzeigen
		ld	de,dirzbsc
		ld	c,19		;DIRS
		call	5		
		ret
		
dirzbsc:	db	"?HLP",0

hlptxt:		dw	YELLOW
		db	"Anzeige einer kurzen Hilfe", 0dh,0ah
		DW	WHITE
		db	0dh,0ah
		db	"Aufruf:   HELP kommando", 0dh,0ah
		db	0dh,0ah
		db	"moegliche Kommandos: ", 0dh,0ah
		DW	GREEN
		db	0


;------------------------------------------------------------------------------

;Farben
color		ld	a,14h
		call	outa
		ld	a,e
		call	outa
		ret

;------------------------------------------------------------------------------

		endif 	; phase="CODE"

;  		end
