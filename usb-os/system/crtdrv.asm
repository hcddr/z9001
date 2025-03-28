; CRT-Treiber-Erweiterung
; schnelles CLS
; Zeicheneingabe um fehlende Zeichen erweitert. Idee aus PrettyC übernommen

	cpu	z80
;
;*******************************************************************
;*                                                                 *
;*	MONITOR - D E F I N I T I O N E N                          *
;*                                                                 *
;*******************************************************************
;
JOYR:	EQU	13H		;SPIELHEBEL 1
JOYL:	EQU	14H		;SPIELHEBEL 2
COLSW:	EQU	17H		;PUFFER FARBSTEUERCODE
KEYBU:	EQU	25H		;TASTATURPUFFER
ATRIB:	EQU	27H		;AKTUELLES FARBATRIBUT
CHARP:	EQU	2BH		;ZEIGER AUF SPALTE
LINEP:	EQU	2CH		;ZEIGER AUF ZEILE
CURS:	EQU	2DH		;PHYS. CURSORADRESSE
BUFFA:	EQU	34H		;PUFFER FARBCODE
P1ROL:	EQU	3BH		;1. ZU ROLLENDE ZEILE-1
P2ROL:	EQU	3CH		;LETZTE ZU ROLLENDE ZEILE+1
P3ROL:	EQU	3DH		;1. ZU ROLLENDE SPALTE-1
P4ROL:	EQU	3EH		;LETZTE ZU ROLLENDE SPALTE+1

SCTOP:	EQU	0EC00H		;ADR. ZEICHENSPEICHER

LINEL:	EQU	40		;LAENGE PHYSISCHE BILDSCHIRMZEILE
ONEKB:	EQU	400H		;KONSTANTE 1 KBYTE
SPACE:	EQU	20H		;LEERZEICHEN
FIRST:	EQU	SPACE		;1. DRUCKBARES ZEICHEN

; aufgerufene OS-Funktionen
;CRT	0F8F1h	CRT-TReiber im Monitor
;MCOL	0F895h
;OCH1	0F89Eh

SETC	equ	0F9F3h
DELC	equ	0FA33h

keybu1	equ	005Ah		;letztes eingegebenes Zeichen
keybu2	equ	005Bh		;ersetztes Zeichen

;	org	08000h


;*******************************************************************
;*	CRT - TREIBER	für OS Z9001                               *
;*******************************************************************

	;Eingangsverteiler für CRT-Treiber mit allen Funktionen
CRT:	push	af
	cp	1
	jp	z, CI0		;01 Eingabe
	cp	2		;02 Ausgabe
	jr	nz, crt1

;02 ZEICHENAUSGABE
OCHAR:	LD	A,(COLSW)	;(HL)=ADR. VON COLSW
	OR	A
	jr	NZ, crt1
;
	LD	A,C		;AUSZUGEBENDES ZEICHEN
	cp	12		; cls
	jr	z, FCLS

crt1:	pop	af
	jp	0F8F1h		;CRT-TReiber im Monitor

;------------------------------------------------------------------------------
; Schnelles Löschen beliebiger Fenster, frei nach mp 11/1989, S. 344
;------------------------------------------------------------------------------
;12 LOESCHEN BILDSCHIRM

FCLS:	pop	af
	CALL	DELC

	LD 	HL, SCTOP	;ZEICHENSPEICHERADR.
	LD 	BC,40		;ZEILENLAENGE
	LD 	A,(P1ROL)	;1. ZU ROLLENDE ZEILE-1
	LD 	D,A
	CP 	A,0
	JR	Z, M1
M0: 	ADD 	HL,BC
	DEC 	A
	JR	NZ, M0		;HL=Anfangsadr. 1. Zeile
;	
M1: 	LD 	A,(P2ROL)	;LETZTE ZU ROLLENDE ZEILE+1
	DEC 	A
	SUB 	D
	LD	B,A		;Anzahl Zeilen im Fenster
	LD 	A,(P3ROL)	;1. ZU ROLLENDE SPALTE-1
	LD 	E,A
	ADD 	A,L		;HL :=HL+A
	LD	L,A
	JR	NC, M2
	INC 	H		;HL=Adr. 1.Byte im Fenster
;	
M2: 	
;Cursor Pos. Home
	ld	(CURS),HL	;MERKEN CURSORADRESSE
	inc	d
	ld	a,d
	LD	(LINEP),A
	inc	e
	ld	a,e
	LD	(CHARP),A
;Farbe vorbereiten
	LD	A,(ATRIB)	;AKTUELLER FARBCODE
	RES	7,A		;KEIN BLINKEN
;	ld	(m5+1),A	;Farb-Attribut patchen
	ld	(BUFFA),A
	ex	af,af'		;'
;
	LD 	A,(P4ROL)	;LETZTE ZU ROLLENDE SPALTE+1
	SUB 	E
	LD 	C,A
	LD 	A,40		;ZEILENLAENGE
	SUB 	C
	LD 	D,0
	LD 	E,A
	LD 	A,C
M3: 	LD 	C,A		;Anz. Zeichen pro Zeile
M4: 	LD 	(HL), SPACE	;BWS löschen
	res	2,h		;->Farb-BWS
M5	ex	af,af'
	LD	(HL), a		;Farb-Attribut, wird gepatcht
	ex	af,af'
	set	2,h
	INC 	HL
	DEC 	C
	JR	NZ, M4
	ADD 	HL,DE		;DE=40, ZEILENLAENGE
	DJNZ 	M3
;	
;;	RET
	jp	SETC

;------------------------------------------------------------------------------
; neue Tastaturroutine 
;------------------------------------------------------------------------------

CI0:	pop	af

ci:	ld	a,(keybu2)
	or	a
	jr	nz,ci1
	LD	A,(KEYBU)	;TASTATUREINGABE
	OR	A
	JR	Z, CI		;WARTEN AUF ZEICHEN, 01 Eingabe Zeichen
ci1:	PUSH	AF
	XOR	A
	LD	(KEYBU),A	;TASTATURPUFFER LOESCHEN
	ld	(keybu2),a
	LD	(JOYR),A	;SPIELHEBELPUFFER
	LD	(JOYL),A	;LOESCHEN
	LD	A,(COLSW)	;(HL)=ADR. FARBSCHALTER
	OR	A
	JR	Z, CI2		;ZEICHEN IST KEIN FARBCODE
	POP	AF
	CP	A, 39H
	JR	NC, CI		;KEIN GUELTIGER FARBCODE
	SUB	31H		;WANDELN IN INTERNEN FARBCODE
	JR	C, CI		;KEIN GUELTIGER FARBCODE
	PUSH	AF
CI2:	POP	AF
	cp	'@'
	jr	nz,ci5
	ld      a, (keybu1)
	;push    bc
	ld      hl, citab
        ld      bc, 0Fh
        cpir                    ; suchen
        ;pop     bc
        ld      a, '@'
        jr      nz, ci5         ; nicht gefunden -> @
        ld      a, (hl)         ; sonst nachfolgendes Zeichen aus Liste	
        ld	(keybu2),a
        ld	a, 8		; backspace
ci5:	ld	(keybu1),a
	or	a
	RET

citab:  db  28h ; (
	db  5Bh ; [
	db  7Bh ; {
	db  28h ; (
	db  29h ; )
	db  5Dh ; ]
	db  7Dh ; }
	db  29h ; )
	db  2Dh ; -
	db  7Eh ; ~
	db  2Dh ; -
	db  2Fh ; /
	db  7Ch ; |
	db  5Ch ; 
	db  2Fh ; /

; 10.08.2020
; Auf der Tastatur nicht vorhandene Zeichen wie '[' können aus vorherigen
; Zeichen durch nachfolgendes Drücken von '@'  entsprechend folgender
; Umwandlungsreihen dargestellt werden:
; 
; ( [ {
; ) ] }
; / | \
; - ~
; 
; Steht links vom Cursor keines dieser Zeichen, so wird '@' normal ausgegeben.

