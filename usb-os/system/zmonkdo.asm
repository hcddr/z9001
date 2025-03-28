
	cpu	z80undoc

		if phase="CODE"

;------------------------------------------------------------------------------
; System
;------------------------------------------------------------------------------

;;CBOS:		EQU	05H		;zentraler BOS-Ruf
;;;
;;;CBOS-Rufe
;;;
;;;CONSI:		EQU	1		;CONST-Eingabe
;;;CONSO:		EQU	2		;CONST-Ausgabe
;;;LISTO:		EQU	5		;LIST-Ausgabe
;;;CSTS:		EQU	11		;CONST-Status
;;
;;CSTS:		equ	0F006h		;STATUS CONST
;;CONSI:		equ	0F009h		;EINGABE ZEICHEN VON CONST
;;CONSO:		equ	0F00Ch		;AUSGABE ZEICHEN ZU CONST
;;LISTO:  	equ	0F00Fh
;;
;;;
;;IOBYT:		equ	0004h
;;CONBU:		EQU	0080H		;CCP ZEICHENKETTENPUFFER
;;STDMA:		EQU	0080H		;STANDARDPUFFER FUER KASSETTE
;;INTLN:		equ	0100h		; interner Zeichenkettenpuffer
;;DMA:		EQU	001BH		;ZEIGER AUF KASSETTENPUFFER
;;PU:		EQU	002FH		;HILFSZELLE (TIME + Status CONST)
;;WORKA:		EQU	0033H		;HILFSZELLE (ASGN)
;;PARBU:		EQU	0040H		;HILFSZELLE (wird nur von ALDEV genutzt)
;;
;;FCB: 		EQU	005Ch 		;Dateikontrollblock
;;START:		EQU	0071H		;STARTADRESSE
;;
;;; BDOS
;;OCRLF:		EQU	0F2FEH
;;OUTA:		EQU	0F305H
;;OSPAC:		EQU	0F310H
;;;
;;DISPE   	EQU	0F0C0h
;;GVAL    	EQU	0F1EAh
;;LOCK    	EQU	0F2B8h
;;GETMS   	EQU	0F35Ch
;;;LOAD1   	EQU	0F526h
;;COEXT   	EQU	0F5B9h
;;ERPAR   	EQU	0F5E6h
;;ERDIS   	EQU	0F5EAh
;;WBOOT   	EQU	0F003h	;0F6AEh
;;;;CONS1		equ	0f758h
;;;
;;ERINP		EQU	0F5E2h
;;REA1		EQU	0F5A6h
;;
;;;25.06.2013
;;DECO0		equ	0FD33h		; DECODIEREN DER TASTATURMATRIX

		endif

;------------------------------------------------------------------------------
; Systemsoftware
;------------------------------------------------------------------------------

		;ORG	03800H
;		ORG	0D000H
;
;PBEG:

		if phase="MENU"

; Anzeige der transienten Kommandos
		JP	MENU
		DB	"MENU    ", 0

; vom Z1013 

		JP	D_KDO
		DB	"DUMP    ", 0

		JP	K_KDO
		DB	"FILL    ", 0

		JP	T_KDO
		DB	"TRANS   ", 0

		JP	J_KDO
		DB	"RUN     ", 0

		JP	I_KDO
		DB	"IN      ", 0

		JP	O_KDO
		DB	"OUT     ", 0

		JP	MEM
		DB	"MEM     ", 0

; weitere Kommandos

		JP	EOR
		DB	"EOR     ", 0

		JP	KDO_LOAD
		DB	"LOAD    ", 0

		JP	KDO_SAVE
		DB	"SAVE    ", 0

		jp	KDO_FCB
		db	"FCB     ", 0

;;		Db	0

		endif
	
		if phase="CODE"

;------------------------------------------------------------------------------
; Unterprogramme
;------------------------------------------------------------------------------

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
		JR	NC, COUT1		; A>=' '
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
		;;JP	Z, GOCPM
		jr	z,wait0
;
		CP	A, 013H			;<PAUSE>?
		RET	NZ			;nein
		CALL	CONSI			;Eingabe
		RET
;Ende
wait0:		ld	hl,(200h-2)		;GOCPM
		jp (hl)
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

;------------------------------------------------------------------------------
;25.06.2013
;------------------------------------------------------------------------------

; Test,	ob <STOP> gedrückt -> Cy=1
stopkey:	call	DECO0		; DECODIEREN DER TASTATURMATRIX
		ei
		or	a
		ret	z
		cp	3		; <STOP> ?
		scf
		ret	z
		ccf
		ret

;------------------------------------------------------------------------------
; LOAD/SAVE
;------------------------------------------------------------------------------
;

	if	1=0	;code ist schon in modul.asm im CCP mit drin

LOAD:	CALL	GVAL		;NAECHSTEN PARAMETER HOLEN
	RET	Z		;KEIN GUELTIGER NAME
;

;DATEI LADEN OHNE START
LOAD1:	call	prepfcb
	ret	c
LOAD4:
	;CALL	OPENR
	ld	c,13		;OPENR
	call	5
	JR	NC, LOAD5	;KEIN FEHLER
	OR	A
	SCF
	RET	Z		;STOP GEGEBEN
	CALL	REA1		;AUSG. FEHLERMELD. WARTEN REAKT.
	RET	C		;STOP GEGEBEN
	JR	LOAD4		;WIEDERHOLUNG
LOAD5:	ld	hl,(data)	;neue aadr?
	ld	a,h
	or	l
	jr	nz,LOAD51
	LD	HL,(FCB+17)	;DATEIANFANGSADRESSE
LOAD51:	LD	(DMA),HL	;NACH ADR. KASSETTENPUFFER
LOA55:
	;CALL	READ		;LESEN BLOCK
	ld	c,20		; READ
	call	5
	JR	NC, LOAD6	;KEIN FEHLER
	CALL	REA1		;AUSG. FEHLERMELD. WARTEN REAKT.
	RET	C		;STOP GEGEBEN
	XOR	A
LOAD6:	OR	A
	JR	Z, LOA55	;WEITER BIS DATEIENDE LESEN
	JP	OCRLF
;
MOV:	LD	HL,INTLN+1	;ZWISCHENPUFFER
MOV1:	LD	B,A
MOV2:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	MOV2
	RET

prepfcb:
	LD	HL,ERPAR
	PUSH	HL
	LD	A,(INTLN)	;PARAMETERLAENGE
	CP	A, 9
	RET	NC		;NAME ZU LANG
	LD	DE,FCB
	LD	A,8
	CALL	MOV		;NAME IN FCB EINTRAGEN
	EX	AF, AF'
	JR	NC, LOAD3	;DATEITYP FOLGT
	EX	AF, AF'
	;STANDARDEINTRAGUNG
	push	ix
	pop	hl
	ld	a,3
	JR	LOA31
LOAD3:	LD	A,C
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
	LD	HL,INTLN+1	;ZWISCHENPUFFER
loa31:	CALL	MOV1
LOA33:	POP	HL
	EX	AF, AF'		;'
	JP	NC, ERINP	;ZU VIELE PARAMETER
	ccf
	ret

	endif

;CLOAD
;in:
;   A=0 => Dateiname+Typ ist bereits im FCB eingetragen
;   A=1 => Dateiname "Name[.Typ]" muss in CONBU abgelegt sein
;   A=2 => zuerst Abfrage "Filename:"
;   A=3 => Dateiname "Name[.Typ]" muss in CONBU abgelegt sein, ohne initiales GVAL
;   A+80h -> in IX Zeiger auf Default-Dateityp, sonst COM
;   HL = 0 => orig. aadr wird genommen
;   HL <> 0 => aadr
;ret: Cy=1 Fehler
cload: 		bit 	7,a
		jr 	nz,cload0
		ld 	ix,dfltext
cload0:		res	7,a
		ld	(data),hl	; HL merken
		or	a
		jp	z, LOAD4	; A=0 -> Dateiname+Typ ist bereits im FCB eingetragen
		dec	a
		jr	z, cload1	; A=1 => Dateiname+Typ steht in CONBU
		dec	a
		jr	z, cload2	; A=2 => Filename abfragen
		jp	LOAD1		; A=3 => Dateiname+Typ steht in CONBU;  ohne GVAL

cload2:		call	getfname	; Filename abfragen
		ret	c
cload1:		jp	LOAD

;Filename abfragen, Eingabe als "Name[.Typ]"
getfname:	ld	de, aFilename	; Kassetten-I/O: Filename abfragen+laden/speichern
		ld	c,9
		call	5
		call	GETMS		; EINGABE ZEICHENKETTE IN MONITORPUFFER
		ret	c
		call	COEXT		; VORVERARBEITEN EINER ZEICHENKETTE
		ret
aFilename:	db "Filename: ",0
;;dfltEXT:	db	"COM"

;CSAVE
;
csave: 		bit 	7,a
		jr 	nz,csave0
		ld 	ix,dfltext
csave0		res 	7,a
 		or	a
		jp	z, csave1	; A=0 -> Dateiname+Typ ist bereits im FCB eingetragen
		dec	a
		jr	z, csave4	; A=1 => Dateiname+Typ steht in CONBU
;
		call	getfname	; A=2 => Filename abfragen
		ret	c
;
csave4:		CALL	GVAL		;NAECHSTEN PARAMETER HOLEN
		RET	Z		;KEIN GUELTIGER NAME
		call	prepfcb
		ret	c
;
csave1		ld	hl, (fcb+19)	; EADR
		ld	de, (fcb+17)	; AADR
		or	a
		sbc	hl, de
		ret	c		; aadr > eadr
		ld	c, 15		;OPENW: Eroeffnen Kassette schreiben
		call	5
		ret	c
		call	ospac		; Ausgabe Leerzeichen
		call	stopkey		; Test auf <STOP>
		ret	c		; wenn STOP
		ex	de, hl
		ld	(DMA), hl
csave3:		ld	hl, (DMA)
		ld	de, 7Fh
		add	hl, de
		ld	de, (fcb+19)	; EADR
		sbc	hl, de
		jr	nc, csave2
		ld	c, 21		; WRITS: Schreiben eines Blockes auf Kassette
		call	5
		ret	c
		call	ospac		; Ausgabe Leerzeichen
		call	stopkey		; Test auf <STOP>
		ret	c		; wenn STOP
		jr	csave3
csave2:		ld	c, 16		; CLOSW: Abschlie¯en Kassette schreiben
		call	5
		ret	c
		JP	OCRLF
;

;------------------------------------------------------------------------------
; MENU-Befehl
;------------------------------------------------------------------------------


MENU:		ld	hl, 0FC00H		;ANFANGSADRESSE
MENU0:		push	hl
		LD	A,0C3H
		CP	A, (hl)			;JMP-Befehl?
		CALL	Z, MENANZ
		pop	hl
		Dec	h			;IX=IX-100H
		jr	nz,MENU0
		or	a
		ret

;OS-Rahmen gefunden
MENANZ:		push	hl
		pop	ix
MENU1:		call	MENU2
		LD	A,(IX+12)
		CP	A, 0C3H			;folgt Name?
		ret	NZ			;nein
		LD	DE,12
		ADD	IX,DE			;Zaehler erhoehen
		JR	MENU1
;

;OS-Rahmen auswerten
;Rahmen-Daten ab IX
MENU2:		XOR	A
		CP	A, (IX+11)		;Stringende=0?
		ret	NZ			;kein Name
;test 1. Zeichen ein Buchstabe?
		ld	a,(IX+3)
		cp	'#'			; Ausnahme für EOS-Programme
		jr	z, MENU3
		cp	'A'-1
		ret	c
		cp	'z'
		ret	nc
;Langanzeige Name, Rahmen-Adr, Startadr. (A=1)
MENU3:		push 	ix
		pop	hl
		inc	hl
		inc	hl
		inc	hl
		LD	B,8
		CALL	COOUT			;Ausgabe Name
		CALL	OSPAC
		CALL	OSPAC
		CALL	MEADR			;Ausgabe Adressen
		CALL	OCRLF
MENU4		CALL	WAIT
		RET

;Ausgabe Adressen
MEADR:		PUSH	IX			;orig. Adr.
		POP	HL
		CALL	OUTHL			;Ausg. 1. Adr.
		CALL	OSPAC
		LD	L,(IX+1)
		LD	H,(IX+2)
		CALL	OUTHL			;Ausg. 2. Adr.
		RET

		
;-------------------------------------------------------------------------------

		endif 	; phase="CODE"

;		END
