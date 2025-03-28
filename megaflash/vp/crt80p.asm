; 01.12.2009 VPohlers 
; CRT-Treiber, gestutzt auf Zeichenausgabe, zusätzlich Wrapper für ASGN
; ist i.W. der originale OS-Treiber + 80 Zeichen
; 03.12.2009 16:22 funktioniert
; 06.12.2009 Der Text-Cursor wird gelöscht, die Invers-Darstellung erfolgt auch bei S/W-Hardware
; es werden alle 8 Zeilen pro Buchstabe geschrieben
; neu: Treiberfunktion 09: Zeichensatztabelle wechseln, Adr. in DE. Bei DE=0 Standard-Tabelle
; 20.03.2012 Korrektur Farbe bei Zeilenvorschub in DELC1
; 20.03.2012 kompletter 4x8 Zeichensatz für Z9001 (handgepixelt)


	cpu	z80
;
;*******************************************************************
;*                                                                 *
;*	MONITOR - D E F I N I T I O N E N                          *
;*                                                                 *
;*******************************************************************
;
JOYR:	EQU	13H		;SPIELHEBEL 1
BSW:	EQU	16H		;SCHALTER KONTROLLTON
COLSW:	EQU	17H		;PUFFER FARBSTEUERCODE
COUNT:	EQU	23H		;ZAEHLER CTC2 - INTERRUPTS
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
BUFF:	EQU	3FH		;PUFFER FUER ZEICHEN

SCTOP:	EQU	0EC00H		;ADR. ZEICHENSPEICHER
MAPPI:	EQU	0F000H-64	;SYSTEMBYTE
MAPAR:	EQU	MAPPI+1		;64 BIT KONFIG.-REGISTER

LINEL:	EQU	40		;LAENGE PHYSISCHE BILDSCHIRMZEILE
ONEKB:	EQU	400H		;KONSTANTE 1 KBYTE
SPACE:	EQU	20H		;LEERZEICHEN
FIRST:	EQU	SPACE		;1. DRUCKBARES ZEICHEN

CTC0:	EQU	80H

portB8		equ	0B8h		; Vollgrafik

; aufgerufene OS-Funktionen

COL	equ	0F868h
CI	equ	0F924h
os_DELC	equ	0FA33h
INITA	equ	0FAE3h
INIVT	equ	0FF0Dh
AUS1	equ	0FF31h

AUP2		equ	0EFDFh		; Eigentlich Adresse UP2-Treiber für PUNCH
					; hier f. Re-Init ON_COLD genutzt

	org	0B000h

;*******************************************************************
;*	CRT80 - TREIBER	für OS Z9001                               *
;*******************************************************************

	jp	init
txtuc	db	"CRT80   ",0
	jp	cls
	db	"CLS     ",0
	jp	x
	db	"X       ",0
	db	0

; Bildschirm löschen
cls:	ld	e,12
	ld	c,2
	call	5
	ret
; Zurückschalten in Textmodus
x:	ld	a,0
	out	(portb8),a
	jp	0


;*******************************************************************
;*	MYCRT - TREIBER	                                           *
;*******************************************************************

init:
; Treiber eintragen
	ld	bc, crt
	ld	(0EFCFh), bc	; AUC
	ld	de, txtuc
	ld	(0EFE9h), de	; TXCON

	; f. Flash-Modul, on_cold
	ld	hl, init
	ld	(AUP2),hl

	call	ICRT		; Initialisieren

; IO-Byte setzen

	ld	hl, 4		; CONST := UC
	set	0, (hl)
	set	1, (hl)

; ASGN-Informationen bereitstellen

	ld	de,txtuc
	ld	c,9
	call	5

	ld	bc, crt
	ld	de, txtuc

	ld	h, 0		; log. Gerätenummer (CONST)
	ld	l, 3		; phys. Gerätenummer (UC)

	or	a
	ret

;*******************************************************************
;*	CRT - TREIBER	TEIL 1: BILDSCHIRM                         *
;*******************************************************************
;
;ZEICHENAUSGABE
;02	Ausgabe Zeichen
;	Eingang:
;		C Zeichen
OCHAR:	LD	A,(ATRIB)	;AKTUELLER FARBCODE
	LD	E,A
	LD	A,(HL)		;(HL)=ADR. VON COLSW
	OR	A
	JR	Z, OCH1		;ZEICHEN IST KEIN FARBCODE
MCOL:	CALL	COL		;NEUEN FARBCODE BERECHNEN
MCOL1:	LD	(ATRIB),A	;NEUER AKTUELLER FARBCODE
MCOL2:	XOR	A
	LD	(HL),A		;FARBSCHALTERLOESCHEN
	RET
;
OCH1:	LD	A,C		;AUSZUGEBENDES ZEICHEN
	SUB	5
	JR	Z, SCOL		;STEUERCODE RANDFARBE GEFUNDEN
	DEC	A
	JR	NZ, OCH3
BLINK:	LD	A,E		;BLINKBIT EIN/AUS
	XOR	80H		;BLINKBIT AENDERN
	JR	MCOL1
OCH3:	DEC	A
	JR	NZ, OCH4
BELL:	DI			;AUSGABE TASTATURTON
	CALL	BELL1		;SUMMER EIN/AUS
	CALL	INIVT		;INIT. TONAUSGABE
	LD	BC,30H		;ANZAHL TOENE
BELL0:	CALL	AUS1		;AUSGABE
	CPI			;
	JP	PE,BELL0	;
	LD	A,3
	OUT	CTC0, A		;CTC 0  HALT
BELL1:	IN	A, 88H
	XOR	80H
	OUT	88H, A
	RET
;
OCH4:	SUB	0AH
	JR	NZ, OCH44
	DEC	HL		;(HL)=ADR. SCHALT. KONTROLLTON
	LD	A,(HL)		;
	XOR	1		;UMSCHALTEN
	LD	(HL),A		;
	RET
;
OCH44:	SUB	3
	JR	Z, SCOL		;FARBSTEUERCODE VORDERGRUND
	DEC	A
	JR	NZ, OCH5	;KEIN FARBSTEUERCODE HINTERGRUND
; 14 (F) COLOR CTRL/T nächstes Zeichen ist Code für Vordergrundfarbe
; 15 (F) SHIFT+COLOR o. CTRL/U nächstes Zeichen ist Code für Hintergrundfarbe
SCOL:	LD	A,C		; C = 14h oder 15h
	LD	(HL),A		;FARBSTEUERCODE IN COLSW MERKEN
OCH5:	DEC	A
	JR	Z, INVER	;FARBEN INVERTIEREN
	CALL	OC		;AUSGABE DES ZEICHENS
	LD	A,(BSW)
	OR	A
	RET	Z		;KEIN KONTROLLTON
	JR	BELL		;KONTROLLTON AUSGEBEN
INVER:	jp	toggleinv
;	LD	A,E
;	CALL	MIAT		;FARBE INVERTIEREN
;	JR	MCOL1
;
;STEUERPROGRAMM DES CRT - TREIBERS
;der eigentliche CRT-Treiber, Eintritt A = Funktion (0..8, FF)

CRT:	LD	HL,COLSW	;HL FUER FARBBEHANDLUNG STELLEN
	INC	A
	JR	NZ, CRT1

; FF	Initialisieren/Rücksetzen des Gerätes
ICRT:	DI			;INITIALISIERUNG CRT
	LD	HL,1900H	;(24 Zeilen)
	LD	(P1ROL),HL	;STANDARDFENSTER
	LD	H,51H		;EINSTELLEN (80 Spalten)
;	LD	H,29H		; testweise 40 spalten
	LD	(P3ROL),HL	;
	LD	H,0
	LD	(COUNT),HL	;
	LD	(KEYBU),HL	;ARBEITSZELLEN LOESCHEN
	LD	(JOYR),HL	;
	LD	(BSW),HL	;

	call	os_delc		; Cursor von Textmodus löschen

	ld	hl, zeitab
	ld	(pzeitab+1), hl
	
	ld	a, 0		; NOP
	ld	(labinv), a

	call	ginit

	IN	A, 88H
	AND	A, 38H		;GRAFIKANZEIGE UND
	OUT	88H, A		;TASTATURSUMMER AUS
	JP	INITA		;INIT. TASTATUR
;
CRT1:	DEC	A
	JR	NZ, CRT2

; 00	Abfrage Status
;	Return:
;		A Status
;		0 kein Zeichen bei Eingabegerät, nicht bereit bei Ausgabegerät
;		sonst Zeichen liegt an bei Eingabegerät,
;		(im installierten CRT-Treiber wird der Zeichencode übergeben)
STAT:	LD	A,(KEYBU)	;STATUS ABFRAGEN
	RET
;
CRT2:	DEC	A
	JP	Z, CI		;01 Eingabe Zeichen
	DEC	A
	JP	Z, OCHAR	;02 ZEICHEN AUSGEBEN
	LD	C,0		;ZUFAELLIGES ZEICHEN LOESCHEN
	DEC	A
	JP	Z, DELC		;03 CURSOR LOESCHEN
	DEC	A
	JP	Z, SETC		;04 CURSOR ANZEIGEN
	DEC	A
	JR	NZ, CRT4

; 05	Abfrage logische und physische Cursoradresse
;	Return:
;		HL physische Cursoradresse
;		DE logische Cursoradresse
GLCU:	CALL	OC		;ABFRAGE LOG. CURSORADRESSE
				;HL MIT PHYS. ADR. LADEN
	LD	DE,(CHARP)	;LOG. ADRESSE
	RET
;
CRT4:	DEC	A
	JR	Z, SLCU		;06 LOG. CURSORADRESSE SETZEN
	DEC	A
	JR	Z, OC		;07 ABFRAGE PHYS. CURSORADRESSE
				;HL MIT PHYS. ADR. LADEN
	DEC	A		;08 Setzen Cursor auf physische Adresse
	jr	z, SPCU
	dec	a
	RET	NZ		;KEIN GUELTIGER RUF

; 09 (vp) Setzen Zeichensatztabelle
;	Eingang:
;		DE Adresse 4x8-Font, bei DE=0 interner Standard-Font
	ld	a, d
	or	e
	jr	nz, sztab1
	ld	de, zeitab
sztab1	ld	(pzeitab+1), de
	ret

; 08	Setzen Cursor auf physische Adresse
;	Eingang:
;		DE physische Cursoradresse

SPCU:	LD	HL,0EC00H	;CURSOR AUF PHYS. ADR. SETZEN
	EX	DE,HL
	SBC	HL,DE
	RET	C		;ADR. NICHT IM ZEICHENSPEICHER
	LD	DE,40		;UMRECHNEN PHYS. --> LOG. ADR.
SP1:	SBC	HL,DE
	INC	A
	JR	NC, SP1
	ADD	HL,DE
	INC	L
	LD	H,A
	sla	l		; Spalte x 2
	EX	DE,HL

;06	Setzen Cursor auf logische Adresse
;	Eingang:
;		DE logische Cursoradresse

SLCU:	LD	(CHARP),DE	;CURSOR AUF LOG. ADR. SETZEN
;
;*******************************************************************
;*	PHYSISCHER BILDSCHIRMTREIBER                               *
;*******************************************************************
;
; 07	Abfrage physische Cursoradresse
;	Return:
;		HL physische Cursoradresse

OC:	LD	HL,SETC		;ADR. FUER ABSCHLIESSENDES
	PUSH	HL		;CURSOR ANZEIGEN KELLERN
	CALL	DELC		;CURSOR LOESCHEN
	; HL = (CURS), DE= (CURS)-ONEKB (=Adr. im Farbspeicher)
	LD	A,C		;AUSZUGEBENDES ZEICHEN
	SUB	8		;CURSOR LINKS
	RET	C		;FEHLER
	JR	Z, DECCP	;DEC ZEICHENZEIGER
	DEC	A		;CURSOR RECHTS
	JR	Z, INCCP	;INC ZEICHENZEIGER
	DEC	A		;CURSOR RUNTER (LF)
	JR	Z, INCLP	;INC ZEILENZEIGER
	DEC	A		;CURSOR HOCH
	JR	Z, DECLP	;DEC ZEILENZEIGER
	DEC	A
	JR	Z, HOME		;LOESCHEN BILDSCHIRM
	DEC	A
	JR	Z, CR		;CURSOR AUF ZEILENANFANG (CR)
	CP	A, FIRST-0DH
	RET	C		;KEIN DRUCKBARES ZEICHEN
;Zeichenausgabe
;HL=(CURS)
	; ZEICHEN IN ZEICHENSPEICHER
	ld	a,c

	push	de
	call	lab
	pop	de

	LD	A,(ATRIB)	;AKTUELLER FARBCODE
	LD	(DE),A		;FARBCODE IN FARBSPEICHER
	JR	INCCP		;INC ZEICHENZEIGER

;Sonderzeichen
HOME:	LD	A,(P1ROL)
	INC	A
	LD	(LINEP),A	;CURSOR AUF 1. ZEILE
	LD	B,A
	LD	A,(P2ROL)
	SUB	B		;AKTUELLE ZEILENZAHL
	LD	B,A
HOME1:	PUSH	BC
	CALL	ROLU		;ROLLEN AUFWAERTS
	POP	BC
	DJNZ	HOME1		;BIS FENSTER LEER
;
CR:	LD	A,(P3ROL)
	LD	(CHARP),A	;CURSOR AUF 1. SPALTE-1
;INC ZEICHENZEIGER
INCCP:	LD	HL,CHARP
	LD	DE,P4ROL
	INC	(HL)		;CURSOR AUF NAECHSTE SPALTE
	LD	A,(DE)
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	NZ
	DEC	DE
	LD	A,(DE)
	INC	A
	LD	(HL),A		;CURSOR AUF 1. SPALTE
;INC ZEILENZEIGER
INCLP:	LD	HL,LINEP
	INC	(HL)		;CURSOR AUF NAECHSTE ZEILE
	LD	A,(P2ROL)
	DEC	A
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	NC
	LD	(HL),A		;CURSOR AUF LETZTE ZEILE
	JR	ROLU		;ROLLEN AUFWAERTS
;DEC ZEICHENZEIGER
DECCP:	LD	HL,CHARP
	LD	DE,P3ROL
	DEC	(HL)		;CURSOR AUF VORHERGEHENDE SPALTE
	LD	A,(DE)
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	NZ
	INC	DE
	LD	A,(DE)
	DEC	A
	LD	(HL),A		;CURSOR AUF LETZTE SPALTE
;DEC ZEILENZEIGER
DECLP:	LD	HL,LINEP
	DEC	(HL)
	LD	A,(P1ROL)
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	C
	INC	A
	LD	(HL),A		;CURSOR AUF 1. ZEILE
	JR	ROLD		;ROLLEN ABWAERTS

;CURSOR WIEDER ANZEIGEN
; 04	Cursor anzeigen
;	Return:
;		HL physische Cursoradresse
SETC:	LD	A,(CHARP)
	LD	C,A
	LD	A,(LINEP)
	LD	B,A
	LD	HL,SCTOP-LINEL 	;ZEICHENSPEICHERADR.-ZEILENLAENGE
	LD	DE,LINEL	;ZEILENLAENGE
SETC1:	ADD	HL,DE		;
	DJNZ	SETC1		;
	LD	B,C		;BERECHNEN CURSORADR.
; Spaltenzahl halbieren
	inc	b
	srl	b
	DEC	HL		;
SETC2:	INC	HL		;
	DJNZ	SETC2		;
	LD	(CURS),HL	;MERKEN CURSORADRESSE

;	LD	A,(MAPAR+7)	;KONFGURATIONSBYTE FUER FARBE
;	BIT	5,A		;FARBVARIANTE? (Adr. E800 = RAM?)
;	JR	NZ, SETC5	;FARBE
	ld	a, 00001111b
	out	(PortB8),a	; unterste Zeile
	LD	A,(HL)		;KEINE FARBE->MERKEN ZEICHEN
	LD	(BUFF),A	;
;Je nach spalte 0f oder f0 nehmen
	ld	b,a
	ld	a,(CHARP)
	and	1
	LD	A,00FH		;SETZEN CURSOR
	jr	z, setcx
	ld	a,0F0H
setcx	or	b
	LD	(HL),A		;SETZEN CURSOR
SETC5:	LD	DE,ONEKB
	PUSH	HL
	SBC	HL,DE		;ZUGEHOERIGE FARBCODEADRESSE
	LD	A,(HL)		;
	LD	(BUFFA),A	;MERKEN FARBCODE
	LD	A,(ATRIB)
;	XOR	80H		;BLINKEN FUER CURSOR INVERTIEREN
;	LD	B,A
;	XOR	(HL)
;	AND	A, 0F0H
;	LD	A,B
;	CALL	Z, MIAT		;CURSORFARBE INVERTIEREN
	LD	(HL),A		;CURSORFARBE SETZEN
	POP	HL
	RET
;
;LOESCHEN CURSOR
; 03	Cursor löschen
DELC:	LD	HL,(CURS)
;	LD	A,(MAPAR+7)	;KONFIGURATIONSBYTE FUER FARBE
;	BIT	5,A		;FARBVARIANTE?
;	JR	NZ, DELC1	;FARBE
	LD	A,(BUFF)	;KEINE FARBE
	LD	(HL),A		;ZEICHEN ZURUECK
DELC1:	LD	DE,ONEKB
	PUSH	HL
	OR	A
	SBC	HL,DE		;ZUGEHOERIGE FARBCODEADRESSE
	LD	A,(BUFFA)
	LD	(HL),A		;ALTEN FARBCODE ZURUECK
	EX	DE,HL
	POP	HL
	RET
;
;BILDSCHIRM ROLLEN (FENSTER)
ROLU:	DB	3EH		;LD A,
;
ROLD:	XOR	A
;
ROL:	PUSH	AF
	LD	HL,SCTOP-LINEL	;ZEICHENSPEICHERADR.-ZEILENLAENGE
	LD	DE,LINEL	;ZEILENLAENGE
	LD	A,(P1ROL)
	INC	A
	LD	C,A
	LD	A,(P2ROL)
	DEC	A
	LD	B,A
	POP	AF
	PUSH	BC
	OR	A		;ROLLEN ABWAERTS?
	JR	Z, ROL1
	LD	B,C
ROL1:	ADD	HL,DE
	DJNZ	ROL1		;1. ZU ROLLENDE ZEILE
	POP	BC
	PUSH	AF
	LD	A,B
	SUB	C
	JR	Z, ENDRO	;EINE ZEILE, NUR LOESCHEN
	LD	B,A
ROL2:	POP	AF
	PUSH	HL
	OR	A		;ROLLEN ABWAERTS?
	JR	Z, ROL3
	ADD	HL,DE
	JR	ROL4
ROL3:	SBC	HL,DE
ROL4:	POP	DE
	PUSH	AF
	PUSH	HL
	PUSH	BC
;
;EINE ZEILE IN ROLLRICHTUNG UMSPEICHERN
MOVEL:	LD	A,(P3ROL)
	srl	a		;vp
	INC	A
	LD	B,A
	DEC	HL
	DEC	DE
MOVL1:	INC	HL
	INC	DE
	DJNZ	MOVL1		;1. SPALTE SUCHEN
	LD	C,A
	LD	A,(P4ROL)
	srl	a		;vp
	inc	a
	SUB	C
	LD	C,A		;ZEICHENANZAHL
	CALL	MOVE		;UMSPEICHERN
	PUSH	BC
	LD	BC,ONEKB
	EX	DE,HL
	SBC	HL,BC		;ADR. IM FARBSPEICHER
	EX	DE,HL
	SBC	HL,BC
	POP	BC
	LDIR
	POP	BC
	POP	HL
	LD	DE,LINEL
	DJNZ	ROL2
ENDRO:	POP	AF
;
;ZEILE LOESCHEN
DELLI:	LD	A,(P3ROL)
	srl	a		;vp
	INC	A
	LD	C,A
	LD	B,A
DELL1:	INC	HL
	DJNZ	DELL1		;1. SPALTE SUCHEN
	LD	E,L
	LD	D,H
	DEC	HL
	LD	A,(P4ROL)
	srl	a		;vp
	inc	a
	SUB	C
	LD	C,A		;ANZAHL ZEICHEN
	DEC	C

;;	LD	(HL), SPACE
	
	push	af
	ld	a,00001000b
DELL2	out	(portb8), a
	ld	(hl), 0
      	inc	a
      	cp	00010000b
      	jr	nz,DELL2
      	pop	af
	
	PUSH	BC
	PUSH	AF
	CALL	NZ, MOVE	;LOESCHEN
	LD	DE,ONEKB
	SBC	HL,DE		;ADR. IM FARBSPEICHER
	LD	A,(ATRIB)	;AKTUELLER FARBCODE
	RES	7,A		;KEIN BLINKEN
	LD	(HL),A
	POP	AF
	POP	BC
	RET	Z
	LD	E,L
	LD	D,H
	INC	DE
	LDIR			;LOESCHEN FARBSPEICHER
DELEN:	RET
;
;FARBCODE INVERTIEREN
MIAT:	LD	C,0
	SLA	A
	RR	C		;MERKEN BLINKBIT
	RLCA
	RLCA
	RLCA
	AND	A, 7FH
	OR	C		;BLINKBIT ZURUECK
	RET
;

bufhl	ds	2
bufde	ds	2	
bufbc	ds	2

MOVE:	ld	(bufhl),hl
	ld	(bufde),de
	ld	(bufbc),bc
	ld	a,00001000b
MOVE1	out	(portb8), a
      	LDIR	
      	ld	hl,(bufhl)
	ld	de,(bufde)
	ld	bc,(bufbc)
      	inc	a
      	cp	00010000b
      	jr	nz,MOVE1
	ret


;------------------------------------------------------------------------------
; 80 Zeichen - Ausgabe
;------------------------------------------------------------------------------

; Ausgabe ein Zeichen
; in A: zeichen, hl: CURS-Adresse (col): Spalte
; (nach wordpro6)

lab		ld	b,0
		sla	a
		rl	b		;*2
		sla	a
		rl	b		;*4
		ld	c,a

		ld	a,(CHARP)	;Position
		srl	a
		push	af		;links oder rechts in CY merken

		ex	de,hl
pzeitab		ld	hl,zeitab
		add	hl,bc		;Beginn Zeichencode in ZS-Tabelle
		ex	de,hl		;HL=Bildschirmadresse (uebergeben in HL)
					;DE=Beginn Zeichencode

		ld	a,00001000b
		ld	(bws),a
		out	(PortB8),a

lab1:		ld	a,(de)		;Zeichencode
		inc	de
labinv:		nop			; oder cpl, s. toggleinv
		ld	b,a		;Pixelcode 2
		rrca
		rrca
		rrca
		rrca
		ld	c,a		;Pixelcode 1
;
		pop	af		;links oder rechts in CY
		push	af
		jr	nc,lab3		; wenn rechts
;Zeichen links
		rld
		ld	a,c		;erster Teil
		rrd
		call	nextbws
		rld
		ld	a,b		;zweiter Teil
		rrd
		jr	lab4
;Zeichen rechts
lab3:		rrd
		ld	a,c		;erster Teil
		rld
		call	nextbws
		rrd
		ld	a,b		;zweiter Teil
		rld
lab4:		call	nextbws		;naechste BS-Zeile
		and	0111b		;A = BWS
		jr	nz,lab1		;bis Zeichen fertig
		pop	af
		ret

nextbws		ld	a,(bws)
		inc	a
		or	00001000b
		ld	(bws),a
		out	(PortB8),a
		ret

; Bei S/W-Grafik bei INVERS Zeichen invertieren 
toggleinv	
;		ld	a,(mapar+7)	;Konfgurationsbyte fuer Farbe
;		bit	5,a		;Farbvariante? (Adr. E800 = RAM?)
;		ret	nz		;Farbe
		ld	a, (labinv)
		xor	2Fh		;Code f. CPL (2F) <-> Code f. NOP (00)
		ld	(labinv), a
		ret

; Zeichensatz

ZEICH		MACRO	 a,b,c,d,e,f,g,h
		db	a*10h+b
		db	c*10h+d
		db	e*10h+f
		db	g*10h+h
		ENDM

ZEITAB	EQU	$-20H			;theoretisch ab Code 00!
		include	"zs80p_zs.asm"

; BWSG init.
ginit:		di
		ld	a, 00000000b
		out	(PortB8),a
		ld	hl, 0efc0h	; Beginn Systemzellen
		ld	de, sysbuff
		ld	bc, 64
		ldir
		ld	b,8
		ld	a, 00001000b
ginit1:		out	(PortB8),a
		push	af
		push	bc
		call	gcls		; aktuellen BWSG löschen
		ld	hl, sysbuff
		ld	de, 0efc0h	; Beginn Systemzellen
		ld	bc, 64
		ldir
		pop	bc
		pop	af
		inc	a
		djnz	ginit1
		ei
		ret

; aktuellen BWSG löschen
gcls:		ld	HL, 0ec00h
		ld	de, 0ec01h
		ld	bc, 960
		ld	(hl),0
		ldir
		ret

bws		ds	1
sysbuff:	ds	64

		end

	END
