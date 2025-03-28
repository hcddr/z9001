; 13.02.2011 VPohlers 
; CRT-Treiber, gestutzt auf Zeichenausgabe, zusätzlich Wrapper für ASGN
; ist i.W. der originale OS-Treiber + schnelles CLS
; 18.05.2013 neu sortiert
; 10.08.2020 Zeicheneingabe um fehlende Zeichen erweitert. Idee aus PrettyC übernommen



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

; aufgerufene OS-Funktionen

;COL	equ	0F868h
;CI	equ	0F924h
os_DELC	equ	0FA33h
INITA	equ	0FAE3h
INIVT	equ	0FF0Dh
AUS1	equ	0FF31h

AUP2		equ	0EFDFh		; Eigentlich Adresse UP2-Treiber für PUNCH
					; hier f. Re-Init ON_COLD genutzt

	org	0B000h

;*******************************************************************
;*	CRT - TREIBER	für OS Z9001                               *
;*******************************************************************

	jp	init
txtuc	db	"CRT40   ",0
	jp	cls
	db	"CLS     ",0
	db	0

; Bildschirm löschen
cls:	ld	e,12
	ld	c,2
	call	5
	ret


;*******************************************************************
;*	MYCRT - TREIBER	                                           *
;*******************************************************************

;Treiber initialisiert sich selbst, kann aber auch mit ASGN genutzt werden

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
	di
	set	0, (hl)
	set	1, (hl)
	ei

; ASGN-Informationen bereitstellen

	ld	bc, crt
	ld	de, txtuc

	ld	h, 0		; log. Gerätenummer (CONST)
	ld	l, 3		; phys. Gerätenummer (UC)

	or	a
	ret

;*******************************************************************
;STEUERPROGRAMM DES CRT - TREIBERS
;*******************************************************************
;

	;Eingangsverteiler für CRT-Treiber mit allen Funktionen
CRT:
	INC	A
	JP	Z, ICRT		;FF Initialisieren/Rücksetzen Gerät
	DEC	A
	JP	Z, STAT		;00 Status
	DEC	A
	LD	HL,COLSW	;HL FUER FARBBEHANDLUNG STELLEN	
	JP	Z, CI		;01 Eingabe
	DEC	A
	JP	Z, OCHAR	;02 Ausgabe
	DEC	A
	JP	Z, DELC		;03 Löschen Cursor
	DEC	A
	JP	Z, SETC		;04 Anzeige Cursor
	DEC	A
	JP	Z, GLCU		;05 Abfrage log. und phy. Cursoradresse
	DEC	A
	JP	Z, SLCU		;06 Setzen Cursor auf log. Adresse
	DEC	A
	JP	Z, OC		;07 Abfrage phy. Cursoradresse
	DEC	A
	JP	Z, SPCU		;08 Setzen Cursor auf phy. Adresse
FEHL:	SCF			;unzulässiges Kommando
	RET			;Fehlerausgang

; FF lnitialisieren/Rücksetzen Gerät
ICRT:	DI			;INITIALISIERUNG CRT
	LD	HL,1900H	;
	LD	(P1ROL),HL	;STANDARDFENSTER
	LD	H,29H		;EINSTELLEN
	LD	(P3ROL),HL	;
	LD	H,0
	LD	(COUNT),HL	;
	LD	(KEYBU),HL	;ARBEITSZELLEN LOESCHEN
	LD	(JOYR),HL	;
	LD	(BSW),HL	;
	IN	A, 88H
	AND	A, 38H		;GRAFIKANZEIGE UND
	OUT	88H, A		;TASTATURSUMMER AUS
	JP	INITA		;INIT. TASTATUR
;

;00	Abfrage Status
STAT:	LD	A,(KEYBU)	;STATUS ABFRAGEN
	RET

;01 Eingabe
;-> CI	im OS

;02 Ausgabe
;-> OCHAR	s.u.

;03 LOESCHEN CURSOR
DELC:	LD	HL,(CURS)
	LD	A,(MAPAR+7)	;KONFIGURATIONSBYTE FUER FARBE
	BIT	5,A		;FARBVARIANTE?
	JR	NZ, DELC1	;FARBE
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

;04 CURSOR WIEDER ANZEIGEN
SETC:	LD	A,(CHARP)
	LD	C,A
	LD	A,(LINEP)
	LD	B,A
	LD	HL,SCTOP-LINEL 	;ZEICHENSPEICHERADR.-ZEILENLAENGE
	LD	DE,LINEL	;ZEILENLAENGE
SETC1:	ADD	HL,DE		;
	DJNZ	SETC1		;
	LD	B,C		;BERECHNEN CURSORADR.
	DEC	HL		;
SETC2:	INC	HL		;
	DJNZ	SETC2		;
	LD	(CURS),HL	;MERKEN CURSORADRESSE
	LD	A,(MAPAR+7)	;KONFGURATIONSBYTE FUER FARBE
	BIT	5,A		;FARBVARIANTE?
	JR	NZ, SETC5	;FARBE
	LD	A,(HL)		;KEINE FARBE->MERKEN ZEICHEN
	LD	(BUFF),A	;
	LD	(HL),0FFH	;SETZEN CURSOR
SETC5:	LD	DE,ONEKB
	PUSH	HL
	SBC	HL,DE		;ZUGEHOERIGE FARBCODEADRESSE
	LD	A,(HL)		;
	LD	(BUFFA),A	;MERKEN FARBCODE
	LD	A,(ATRIB)
	XOR	80H		;BLINKEN FUER CURSOR INVERTIEREN
	LD	B,A
	XOR	(HL)
	AND	A, 0F0H
	LD	A,B
	CALL	Z, MIAT		;CURSORFARBE INVERTIEREN
	LD	(HL),A		;CURSORFARBE SETZEN
	POP	HL
	RET

;05 Abfrage log. und phy. Cursoradresse
GLCU:	LD	C,0		;ZUFAELLIGES ZEICHEN LOESCHEN
	CALL	OC		;ABFRAGE LOG. CURSORADRESSE
				;HL MIT PHYS. ADR. LADEN
	LD	DE,(CHARP)	;LOG. ADRESSE
	RET

;06 Setzen Cursor auf log. Adresse
; -> SLCU bei 08

;07 Abfrage phy. Cursoradresse
;->  OC s.u.

;08 Setzen Cursor auf phy. Adresse
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
	EX	DE,HL
SLCU:	LD	(CHARP),DE	;CURSOR AUF LOG. ADR. SETZEN
	LD	C,0		;ZUFAELLIGES ZEICHEN LOESCHEN
	JP	OC
;

;
;*******************************************************************
;*	CRT - TREIBER	TEIL 1: BILDSCHIRM                         *
;*******************************************************************
;
;
;ZEICHENAUSGABE
OCHAR:	LD	A,(ATRIB)	;AKTUELLER FARBCODE
	LD	E,A
	LD	A,(HL)		;(HL)=ADR. VON COLSW
	OR	A
	JR	NZ, MCOL	;ZEICHEN IST FARBCODE
;
	LD	A,C		;AUSZUGEBENDES ZEICHEN
	cp	5
	JR	Z, SCOL		;STEUERCODE RANDFARBE GEFUNDEN
	cp	6
	jr	z, Blink
	cp	7	
	jr	z, Bell
	cp	17		; ctrl-q
	jr	z, OCH4		;UMSCHALTEN KONTROLLTON
	cp	20
	JR	Z, SCOL		;FARBSTEUERCODE VORDERGRUND
	cp	21
	JR	Z, SCOL		;FARBSTEUERCODE HINTERGRUND
	cp	22
	JR	Z, INVER	;FARBEN INVERTIEREN
;sonst	
OCH5	CALL	OC		;AUSGABE DES ZEICHENS
	LD	A,(BSW)
	OR	A
	RET	Z		;KEIN KONTROLLTON
	JR	BELL		;KONTROLLTON AUSGEBEN

;20+21
SCOL:	;LD	A,C
	LD	(HL),A		;FARBSTEUERCODE IN COLSW MERKEN
	jr	OCH5
;22
INVER:	LD	A,E
	CALL	MIAT		;FARBE INVERTIEREN
	JR	MCOL1
;6
BLINK:	LD	A,E		;BLINKBIT EIN/AUS
	XOR	80H		;BLINKBIT AENDERN
	JR	MCOL1
;FARBCODE
MCOL:	CALL	COL		;NEUEN FARBCODE BERECHNEN
;
MCOL1:	LD	(ATRIB),A	;NEUER AKTUELLER FARBCODE
MCOL2:	XOR	A
	LD	(HL),A		;FARBSCHALTERLOESCHEN
	RET
;7
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
;17
OCH4	DEC	HL		;(HL)=ADR. SCHALT. KONTROLLTON
	LD	A,(HL)		;
	XOR	1		;UMSCHALTEN
	LD	(HL),A		;
	RET

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

;FARBCODEBERECHNUNG
COL:	SUB	14H		;(A)=FARBSTEUERCODE
	JR	C, RAND		;RANDFARBE AENDERN
	JR	Z, INK		;VORDERGRUNDFARBE AENDERN

;HINTERGRUNDFARBE AENDERN
PAPER:	LD	B,0F8H		;HINTERGRUNDFARBE AENDERN
	LD	A,E		;ALTER FARBCODE
P1:	AND	A, B
	OR	C		;(C)=ALTER FARBCODE
	RET			;(A)=RSULTIERENDER FARBCODE

;VORDERGRUNDFARBE AENDERN
INK:	LD	A,E
	LD	B,8FH
I0:	SLA	C
I1:	SLA	C
	SLA	C
	SLA	C
	JR	P1

;RANDFARBE AENDERN
RAND:	IN	A, 88H		;SYSTEMPORT PIO 1
	LD	B,0C7H
	CALL	I1
R1:	OUT	88H, A
	POP	AF		;RUECKKEHRADR. VERNICHTEN
	JR	MCOL2

;*******************************************************************
;*	PHYSISCHER BILDSCHIRMTREIBER                               *
;*******************************************************************
;
OC:	LD	HL,SETC		;ADR. FUER ABSCHLIESSENDES
	PUSH	HL		;CURSOR ANZEIGEN KELLERN
;
	CALL	DELC		;CURSOR LOESCHEN
;
	LD	A,C		;AUSZUGEBENDES ZEICHEN
	SUB	8		;8 CURSOR LINKS
	RET	C		;FEHLER A < 8
;	
	JR	Z, DECCP	;DEC ZEICHENZEIGER
	DEC	A		;9 CURSOR RECHTS
	JR	Z, INCCP	;INC ZEICHENZEIGER
	DEC	A		;10 CURSOR RUNTER (LF)
	JR	Z, INCLP	;INC ZEILENZEIGER
	DEC	A		;11 CURSOR HOCH
	JR	Z, DECLP	;DEC ZEILENZEIGER
	DEC	A
;	JR	Z, HOME		;12 LOESCHEN BILDSCHIRM
	JP	Z, FCLS		;12 LOESCHEN BILDSCHIRM
	DEC	A
	JR	Z, CR		;13 CURSOR AUF ZEILENANFANG (CR)
	CP	A, FIRST-0DH
	RET	C		;KEIN DRUCKBARES ZEICHEN

;FIRST..FFh
; Zeichen auf Bildschirm ausgeben
DIS:	LD	(HL),C		;ZEICHEN IN ZEICHENSPEICHER
	LD	A,(ATRIB)	;AKTUELLER FARBCODE
	LD	(DE),A		;FARBCODE IN FARBSPEICHER
	JR	INCCP		;INC ZEICHENZEIGER

;;;12 LOESCHEN BILDSCHIRM
;;HOME:	LD	A,(P1ROL)
;;	INC	A
;;	LD	(LINEP),A	;CURSOR AUF 1. ZEILE
;;	LD	B,A
;;	LD	A,(P2ROL)
;;	SUB	B		;AKTUELLE ZEILENZAHL
;;	LD	B,A
;;HOME1:	PUSH	BC
;;	CALL	ROLU		;ROLLEN AUFWAERTS
;;	POP	BC
;;	DJNZ	HOME1		;BIS FENSTER LEER
	
;13 CURSOR AUF ZEILENANFANG (CR)	
CR:	LD	A,(P3ROL)
	LD	(CHARP),A	;CURSOR AUF 1. SPALTE-1
;9 CURSOR RECHTS
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
;10 CURSOR RUNTER (LF)
;INC ZEILENZEIGER
INCLP:	LD	HL,LINEP
	INC	(HL)		;CURSOR AUF NAECHSTE ZEILE
	LD	A,(P2ROL)
	DEC	A
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	NC
	LD	(HL),A		;CURSOR AUF LETZTE ZEILE
	JR	ROLU		;ROLLEN AUFWAERTS
	
;8 CURSOR LINKS	
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
;11 CURSOR HOCH 	
;DEC ZEILENZEIGER
DECLP:	LD	HL,LINEP
	DEC	(HL)
	LD	A,(P1ROL)
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	C
	INC	A
	LD	(HL),A		;CURSOR AUF 1. ZEILE
	JR	ROLD		;ROLLEN ABWAERTS

;
;BILDSCHIRM ROLLEN (FENSTER)
ROLU:	DB	3EH		;LD A,xx  --> A := <> 0
;
ROLD:	XOR	A		; A := 0
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
	INC	A
	LD	B,A
	DEC	HL
	DEC	DE
MOVL1:	INC	HL
	INC	DE
	DJNZ	MOVL1		;1. SPALTE SUCHEN
	LD	C,A
	LD	A,(P4ROL)
	SUB	C
	LD	C,A		;ZEICHENANZAHL
	CALL	MOVE		;UMSPEICHERN
;	PUSH	BC
;	LD	BC,ONEKB
;	EX	DE,HL
;	SBC	HL,BC		;ADR. IM FARBSPEICHER
;	EX	DE,HL
;	SBC	HL,BC
;	POP	BC
	res	2,h		;->Farb-BWS
	res	2,d
	LDIR
	POP	BC
	POP	HL
	LD	DE,LINEL
	DJNZ	ROL2
ENDRO:	POP	AF
;
;ZEILE LOESCHEN
DELLI:	LD	A,(P3ROL)
	INC	A
	LD	C,A
	LD	B,A
DELL1:	INC	HL
	DJNZ	DELL1		;1. SPALTE SUCHEN
	LD	E,L
	LD	D,H
	DEC	HL
	LD	A,(P4ROL)
	SUB	C
	LD	C,A		;ANZAHL ZEICHEN
	DEC	C
	LD	(HL),SPACE
	PUSH	BC
	PUSH	AF
	CALL	NZ, MOVE	;LOESCHEN
;	LD	DE,ONEKB
;	SBC	HL,DE		;ADR. IM FARBSPEICHER
	res	2,h		;->Farb-BWS
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

MOVE:	PUSH	HL
	PUSH	DE
	PUSH	BC
	LDIR
	POP	BC
	POP	DE
	POP	HL
	RET

;------------------------------------------------------------------------------
; Schnelles Löschen beliebiger Fenster, frei nach mp 11/1989, S. 344
;------------------------------------------------------------------------------
;12 LOESCHEN BILDSCHIRM

FCLS:	LD 	HL, SCTOP	;ZEICHENSPEICHERADR.
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
	ld	(m5+1),A	;Farb-Attribut patchen
	ld	(BUFFA),A
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
M5	LD	(HL), 0		;Farb-Attribut, wird gepatcht
	set	2,h
	INC 	HL
	DEC 	C
	JR	NZ, M4
	ADD 	HL,DE		;DE=40, ZEILENLAENGE
	DJNZ 	M3
;	
	RET

;------------------------------------------------------------------------------
; neue Tastaturroutine 
;------------------------------------------------------------------------------

keybu1	db	0		;letztes eingegebenes Zeichen
keybu2	db	0		;ersetztes Zeichen

CI:	ld	a,(keybu2)
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
	LD	A,(HL)		;(HL)=ADR. FARBSCHALTER
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

	if 1=0 ; orig
citab:  db  28h ; (
	db  5Bh ; [
	db  7Bh ; {
	db  7Bh ; {
	db  29h ; )
	db  5Dh ; ]
	db  7Dh ; }
	db  7Dh ; }
	db  2Dh ; -
	db  7Eh ; ~
	db  7Eh ; ~
	db  2Fh ; /
	db  7Ch ; |
	db  5Ch ; 
	db  5Ch ; 
	else
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
	endif
	
	end

10.08.2020
Auf der Tastatur nicht vorhandene Zeichen wie '[' können aus vorherigen
Zeichen durch nachfolgendes Drücken von '@'  entsprechend folgender
Umwandlungsreihen dargestellt werden:

( [ {
) ] }
/ | \
- ~

Steht links vom Cursor keines dieser Zeichen, so wird '@' normal ausgegeben.
