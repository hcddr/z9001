;OS-Notizspeicheradressen
DMA:	EQU	01BH	;Zeiger auf Kassettenpuffer
FCB:	EQU	05CH	;Filecontrolblock
FNAME:	EQU	FCB	;Dateiname
FTYP:	EQU	FCB+8	;Dateityp
PSUM:	EQU	FCB+13	;Pruefsumme
BLNR:	EQU	FCB+15	;Blocknummer
LBLNR:	EQU	FCB+16	;gesuchte Blocknr.
AADR:	EQU	FCB+17	;Anfangsadresse
EADR:	EQU	FCB+19	;Endadresse
SADR:	EQU	FCB+21	;Startadresse
SBY:	EQU	FCB+23	;Schutzbyte
CONBU:	EQU	80H	;Eingabepuffer
INTLN:	EQU	100H	;Zeichenkettenpuffer

JOYR:	EQU	13H		;SPIELHEBEL 1
JOYL:	EQU	14H		;SPIELHEBEL 2
LAKEY		equ	0024h		; Merkzelle für letztes gültiges Zeichen von Tastatur
KEYBU		equ	0025h		; Tastaturpuffer
ATRIB		equ	0027h		; aktuelles Farbattribut
CHARP		equ	002Bh		; aktuelle Spalte d. Cursors(1-40)
LINEP		equ	002Ch		; aktuelle Zeile d. Cursors(1-24)
CURS		equ	002Dh		; aktuelle physische Adresse des Cursors
BUFFA		equ	0034h		; Puffer für das Attribut des von Cursor überlagerten Zeichens
P1ROL		equ	003Bh		; 1. rollende Zeile - 1
P2ROL		equ	003Ch		; letzte zu rollende Zeile + 1
P3ROL		equ	003Dh		; 1. zu rollende Spalte - 1
P4ROL		equ	003Eh		; letzte zu rollende Spalte + 1
BUFF		equ	003Fh		; Puffer für das vom Cursor überschriebene Zeichen
PARBU		equ	0040h		; Hilfszelle zur Paramterpufferung

;
;OS-Routinen
CBOS:	EQU	05H	;zentraler BOS-Ruf
GVAL:	EQU	0F1EAH	;Parameter holen
OCRLF:	EQU	0F2FEH
OUTA:	EQU	0F305H
OSPAC:	EQU	0F310H
PRNST:	EQU	0F3E2H	;Stringausgabe
MOV:	EQU	0F588H
ERINP:	EQU	0F5E2H	;Eingabefehler
ERPAR:	EQU	0F5E6H	;Parameterfehler
;
;CBOS-Rufe
CONSI:	EQU	1	;CONST-Eingabe
CONSO:	EQU	2	;CONST-Ausgabe
GETST 	EQU	6	;Abfrage der Spielbebel

OPENR:	EQU	13	;OPEN READ
DCU 	EQU	29 ;Löschen Cursor
SCU 	EQU	30 ;Setzen Cursor

CR	equ	0dh
LF	equ	0ah
ESC	equ	1Bh

;-----------------------------------------------------------------------------


	if 1=0

;***
;
;COOUT Ausgabe ab (HL) (B) Zeichen, nur Buchstaben
;
COOUT:	LD	A,(HL)
	CP	A, ' '
	JR	NC, COUT1
	LD	A,' '
COUT1:	CALL	OUTA	;Zeichen ausgeben
	INC	HL
	DJNZ	COOUT
	RET
;***
;
;OUTHL Ausgabe (HL) hexa
;
OUTHL:	LD	A,H
	CALL	OUTHX
	LD	A,L
;
;***
;
;OUTHX Ausgabe (A) hexa
;
OUTHX:	PUSH	AF
	RLCA
	RLCA
	RLCA
	RLCA
	CALL	OUTH1
	POP	AF
OUTH1:	AND	A, 0FH
	ADD	A, 30H
	CP	A, 3AH
	JR	C, OUTH2
	ADD	A, 07H
OUTH2:	CALL	OUTA
	RET
;
;***
;
;HLKON Wandlung HEX HL --> DEZ (DE)
;
hlkon	push	bc
	push	de
	push	hl
	ld	bc,-10000
	call	Num1
	ld	bc,-1000
	call	Num1
	ld	bc,-100
	call	Num1
	ld	c,-10
	call	Num1
	ld	c,-1
	call	Num1
;	xor	a
;	ld	(de),a		; 0-Byte am Ende
	pop	hl
	pop	de
	pop	bc
	ret
Num1	ld	a,'0'-1
Num2	inc	a
	add	hl,bc
	jr	c,Num2
	sbc	hl,bc
	ld	(de),a
	inc	de
	ret


;;	aufruf
;;	ld	de,DEZBUF
;;	CALL	HLKON
;;	CALL	PRNST


;------------------------------------------------------------------------------
;Ausgabe String, bis 0
;-------------------------------------------------------------------------------
;
prnst0:		EX	(SP),HL			;Adresse hinter CALL
PRS1:		LD	A,(HL)
		INC	HL
		or	A			;Ende (A=0=?
		JR	Z, PRS2			;ja
		CALL	OUTA
		JR	PRS1			;nein
PRS2:		EX	(SP),HL			;neue Returnadresse
		RET

;-------------------------------------------------------------------------------
;Konvertierung ASCII-Hex 
;-------------------------------------------------------------------------------

CNVBN:		sub	'0'
		ret	c
		cp	a,10
		ccf
		ret	nc
		cp	a,11h
		ret	c
		cp	a,17h
		ccf
		ret	c
		sub	7
		ret

;2 Hex-Ziffern ab (HL) -> A
;verändert B, HL

atoh:	ld	a,(hl)
	inc	hl
	call	CNVBN
	ret	c
	rla
	rla
	rla
	rla
	ld	b,a
	ld	a,(hl)
	inc	hl
	call	CNVBN
	ret	c
	add	a,b
	ret

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

; DEZBUF:	Ds	6 	; Buffer für Hex-Dez-Konvertierung

	endif