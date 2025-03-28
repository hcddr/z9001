;------------------------------------------------------------------------------
; Z9001
; (c) V. Pohlers 2012
; letzte Änderung 19.02.2012 19:16:56
;------------------------------------------------------------------------------
; CP/M-Disketten unter OS
; DUMP-Kommando
;------------------------------------------------------------------------------

	cpu	Z80


	section dump
	public	ddump

;;		ORG	7800H
;;BDOS		EQU	4006h	;DOS ENTRY POINT
CONS		EQU	1	;READ CONSOLE
TYPEF		EQU	2	;TYPE FUNCTION
PRINTF		EQU	9	;BUFFER PRINT ENTRY
BRKF		EQU	11	;BREAK KEY FUNCTION (TRUE IF CHAR READY)
OPENF		EQU	15	;FILE OPEN
READF		EQU	20	;READ FUNCTION
;
FCB		EQU	comfcb 	;FILE CONTROL BLOCK ADDRESS		!! s. ddosxx.lst comfcb
BUFF		EQU	80H	;INPUT DISK BUFFER ADDRESS
;
;	NON GRAPHIC CHARACTERS
CR		EQU	0DH	;CARRIAGE RETURN
LF		EQU	0AH	;LINE FEED
;


;;		jp	ddump
;;		db	"DDUMP   ",0
;;		db	0

ddump:
		call	INITCCP
		call	SETDISK
;;		call	FILLFCB0a
		xor	a
		ld	(recno),a	; 0

		;open
		XOR	A
		ld	hl,FCB+32
		ld	(hl),a		;CLEAR CURRENT RECORD
		LD	DE,FCB
		LD	C,OPENF
		CALL	BDOS
		CP	255		;255 IF FILE NOT PRESENT
		scf
		ld	a,13		;file not found
		ret	Z		;bei Fehler

		;read block
dump1:		LD	DE,FCB
		LD	C,READF
		CALL	BDOS
		OR	A		;ZERO VALUE IF READ OK
		RET	NZ		;bei EOF
		;
		;Block anzeigen

		;Ausgabe Record
		ld	de,nxtblk
		ld	c,9
		call	5
		ld	hl,recno
		ld	a,(hl)
		inc	(hl)
		CALL	OUTHX		; Ausgabe Record Number
		CALL	OCRLF

		call	D_KDO

		; nächster Block
		jr	dump1

;
nxtblk:		DB	CR,LF,"Record Nr: ",0
recno:		ds	1
;

;------------------------------------------------------------------------------
; DKO
;------------------------------------------------------------------------------

D_KDO:		ld	hl,BUFF			; von
		ld	b,10h			; 10x8 byte

DKO1:		push	bc
		ld	de, 0			; offs
		ex 	de,hl
		add	hl,de
		call 	OuTHL
		ex 	de,hl
		call	ospac
		LD	B,8
		push	hl
DKO2:		call	ospac
		LD	A,(HL)
		call	OuTHX
		LD	A,(HL)
		INC	HL
		DJNZ	DKO2
		call	ospac
		call	ospac
		POP	HL
		call	c_white
		LD	B,8
		CALL	COOUT			;Ausgabe ASCII
		call	c_gruen
		CALL	OCRLF			;neue Zeile
		push	hl
		CALL	WAIT			;Bei STOP -> GOCPM
		pop	hl
;
		pop	bc
		djnz	DKO1			; wenn nicht STOP
		ret

;------------------------------------------------------------------------------
; Unterprogramme
;------------------------------------------------------------------------------

; BDOS
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H
CSTS:		equ	0F006h		;STATUS CONST
CONSI:		equ	0F009h		;EINGABE ZEICHEN VON CONST

;OUTHL Ausgabe (HL) hexa
;
OUTHL:		LD	A,H
		CALL	OUTHX
		LD	A,L
;
;OUTHX Ausgabe (A) hexa
;
OUTHX:		PUSH	AF
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	OUTH1
		POP	AF
OUTH1:		AND	A, 0FH
		ADD	A, 30H
		CP	A, 3AH
		JR	C, OUTH2
		ADD	A, 07H
OUTH2:		CALL	OUTA
		RET
;
;COOUT Ausgabe ab (HL) (B) Zeichen, nur Buchstaben
;
COOUT:		LD	A,(HL)
		CP	A, ' '
		JR	NC, COUT1
		LD	A,'.'
COUT1:		CALL	OUTA			;Zeichen ausgeben
		INC	HL
		DJNZ	COOUT
		RET
;
;WAIT Unterbrechung Programm, wenn <PAUSE> gedrueckt,
;     weiter mit beliebiger Taste
;
WAIT:		CALL	CSTS			;Abfrage Status
		OR	A
		RET	Z			;keine Taste gedrueckt
		CALL	CONSI			;Eingabe
		CP	A, 03H			;<STOP>?
		JP	Z, 0
;
		CP	A, 013H			;<PAUSE>?
		RET	NZ			;nein
		CALL	CONSI			;Eingabe
		RET
;;

;;Farben
c_rot		ld	e,1
		jr	color
c_gruen		ld	e,2
		jr	color
c_gelb		ld	e,3
		jr	color
c_blau		ld	e,4
		jr	color
c_magenta	ld	e,5
		jr	color
c_cyan		ld	e,6
		jr	color
c_white		ld	e,7
;
color		ld	a,14h
		call	outa
		ld	a,e
		call	outa
		ret

; -------------------------------------------------------

		endsection

