;------------------------------------------------------------------------------
; Zeichen-Gerätetreiber f. Mini-CPM
; Nutzt das OS-I/O-Konzept 
; mit IOBYTE = 0004 :(
;------------------------------------------------------------------------------



	if codesec=commentsec

; Code-Bereiche codesec
;	commentsec	Kommentare
;	equsec		Definitionen
;	biossec		z.b. im Shadow-RAM oder im ROM
;	ubiossec	im RAM, von CCP aus erreichbar
;	initsec		Initialisierung, Hardware-Erkennung etc.

	elseif codesec=equsec

; die Einsprungpunkte fürs BIOS
CONST		equ	chrdrv._const	; const im upper bios 
CONIN		equ	0F009h		; conin im z9001-os   
CONOUT		equ	chrdrv._conout	; conout im upper bios
LIST		equ	0F00Fh		; list im z9001-os    
PUNCH		equ	0F012h		; punch im z9001-os   
READER		equ	0F015h		; reader im z9001-os  
LISTST		equ	0F02Dh		; listst im z9001-os

;Ports
CTC0		equ	80h	; System CTC0
CTC1		equ	81h	; System CTC1
CTC3		equ	83h	; System CTC3

PIO1AD		equ	88h	; System PIO1AD
PIO1BD		equ	89h	; System PIO1BD	Anwenderport
PIO1BC		equ	8bh	; System PIO1BC Anwenderport


stdiobyte:	equ	10010100b	; I/O-Byte: LIST=UL:,PUNCH=UP1:,READER=UR1:,CONST=TTY:

	elseif codesec=biossec

;-----------------------------------------------------------------------------
; PUN-Gerätetreiber für	PUNCH
; Z9001-System-Gerätetreiber
; Ausgabe Zeichen auf Console als "(xx)" (Hexzahl)
;-----------------------------------------------------------------------------

chrdrv.upunch:	ld	a, c
		ld	de, chrdrv.upunch1+1
		call	chrdrv.hexa		; A nach hex konvertieren, Eintragen nach (DE),	2x inc DE
		ld	c, '('
		call	chrdrv._conout		; _conout im upper Bios
chrdrv.upunch1:	ld	bc, 0			; Wert wird durch hexa gepatcht
		push	bc
		call	chrdrv._conout		; _conout im upper Bios
		pop	bc
		ld	c, b
		call	chrdrv._conout		; _conout im upper Bios
		ld	c, ')'
		jp	chrdrv._conout		; _conout im upper Bios


;-----------------------------------------------------------------------------
; Hilfsprogramm, genutzt in UL-, und CRT-Treiber
;-----------------------------------------------------------------------------
chrdrv.stopkey:	call	0FD33h		; Z9001-OS DECO0: Abfrage Tastaturmatrix
		ei
		sub	3		; STOP-Taste ?
		or	a
		ret	nz
		ld	(25h), a	; Tastaturbuffer
		scf
		ret


;-----------------------------------------------------------------------------
; (HL) nach hex	konvertieren, Eintragen	nach (DE), 2x inc DE
;-----------------------------------------------------------------------------
;hexm:		ld	a, (hl)
chrdrv.hexa:	call	chrdrv.hexa1		; A nach hex konvertieren, Eintragen nach (DE),	2x inc DE
chrdrv.hexa1:	rrca
		rrca
		rrca
		rrca
		push	af
		and	0Fh
		sub	0Ah
		jr	c, chrdrv.hexa2
		add	a, 7
chrdrv.hexa2:	add	a, 3Ah
		ld	(de), a
		inc	de
		pop	af
		ret

;-----------------------------------------------------------------------------
; TTY-Treiber für CONS
; Z9001-System-Gerätetreiber
; Beep + Gross<=>Klein-Wandlung
;-----------------------------------------------------------------------------

chrdrv.uttyc:	cp	1		; Kommandocode 'Eingabe Zeichen' ?
chrdrv.uttyc1:	scf			; nein, dann alle anderen Kommandocodes vom OS bearbeiten
		ccf
		jp	nz, 0F8F1h	; Z9001-OS CRT:	Steuerprogramm des CRT-Treibers

; Kommandocode 'Eingabe Zeichen'
chrdrv.uttyc2:	call	0F8F1h		; Z9001-OS CRT:	Steuerprogramm des CRT-Treibers
		call	chrdrv.bell
		ld	hl, chrdrv.lstflag
		bit	0, (hl)		; listflag gesetzt?
		jr	nz, chrdrv.uttyc10	; ja
		cp	1Ch		; jetzt LIST-Taste gedrückt?
		jr	nz, chrdrv.uttyc10	; nein
		ld	a, 1		; LIST merken in lstflag
		ld	(hl), a
		jr	chrdrv.uttyc		; und nächstes Zeichen holen

chrdrv.uttyc10:	bit	0, (hl)		; listflag gesetzt?
		jr	z, chrdrv.uttyc4	; nein -> weiter mit Groß<->Klein
		ld	(hl), 0		; listflag rücksetzen
		cp	1Ch		; nochmal LIST-Taste?
		ret	z		; das ignorieren
		cp	'P'		; 'P' ?
		jr	nz, chrdrv.uttyc12
; LIST+P Hardcopy ein/aus
		ld	a, (15h)	; LISW Schalter für Hardcopy. 0 kein Copy, 1 Copy
		xor	1
		ld	(15h), a	; LISW Schalter für Hardcopy. 0 kein Copy, 1 Copy
chrdrv.uttyc11:	ld	a, 1
		jr	chrdrv.uttyc

chrdrv.uttyc12:	cp	'N'
		jr	nz, chrdrv.uttyc18
; LIST+N Bildschirmkopie
		push	de
		ld	hl, 0EC00h	; Adr. Bildwiederholspeicher
		in	a, (PIO1AD)
		bit	2, a		; 20-Zeilen-Modus?
		ld	a, 20		; Anz. Zeilen
		jr	nz, chrdrv.uttyc13
		add	a, 4		; sonst +4
chrdrv.uttyc13:	ld	d, a
chrdrv.uttyc14:	ld	e, 40		; Anzahl Spalten
;
chrdrv.uttyc15:	ld	c, (hl)
		push	de
		push	hl
		call	0F00Fh		; Z9001-OS: list
		pop	hl
		pop	de
		jr	c, chrdrv.uttyc17
		inc	hl
		dec	e
		jr	nz, chrdrv.uttyc15
		push	hl
		push	de
		ld	c, 0Dh		; CR
		call	0F00Fh		; Z9001-OS: list
		jr	c, chrdrv.uttyc16
		ld	c, 0Ah		; LF
		call	0F00Fh		; Z9001-OS: list
chrdrv.uttyc16:	pop	de
		pop	hl
		jr	c, chrdrv.uttyc17
		dec	d
		jr	nz, chrdrv.uttyc14
chrdrv.uttyc17:	pop	de
		jr	chrdrv.uttyc11
; Ende
chrdrv.uttyc18:	equ	$

; Sondertaste? vorher wurde LIST gedrückt
		ld	hl, chrdrv.lsttab	; Tabelle Extrazeichen (LIST+char)
		ld	bc, chrdrv.lsttabe-chrdrv.lsttab
		cpir			; suche	Sondertaste
		jr	nz, chrdrv.uttyc4
		ld	bc, chrdrv.lsttabe-chrdrv.lsttab-1
		add	hl, bc
		ld	a, (hl)		; Sonderzeichen	holen

; Zeichenkonvertierung Groß<->Klein
chrdrv.uttyc4:	ld	hl, chrdrv.uttyc6	; Returnadresse
		push	hl
		cp	'A'
		jr	c, chrdrv.uttyc5
		cp	'Z'+1
		jr	nc, chrdrv.uttyc5
		or	20h
		ret
chrdrv.uttyc5:		cp	'a'
		ret	c
		cp	'z'+1
		ret	nc
		sub	20h
		ret
chrdrv.uttyc6:		or	a
		ret


;
chrdrv.lsttab:	db	'8'		; Tabelle Extrazeichen (LIST+char)
		db	'9'
		db	','
		db	'.'
		db	'I'
		db	'?'
		db	'='
chrdrv.lsttabe:
;
		db	'['
		db	']'
		db	'{'
		db	'}'
		db	'|'
		db	5Ch		; '\'
		db	'~'

;-----------------------------------------------------------------------------
; CRT-Treiber für CONS
; Z9001-System-Gerätetreiber
; nur  Tastatur-Beep
;-----------------------------------------------------------------------------

chrdrv.ucrtc:	cp	1		; Kommandocode 'Eingabe Zeichen' ?
		jp	nz, chrdrv.uttyc1	; nein, dann alle anderen Kommandocodes vom OS bearbeiten
		call	0F8F1h		; Z9001-OS CRT:	Steuerprogramm des CRT-Treibers
;
; Tastaturbeep
chrdrv.bell:	di
		push	af
		push	bc
		ld	b, 0
		ld	c, 14h
		ld	a, 00000111b	; Interrupt aus, Zeitgeber Mode, Vorteiler 16, negative	Flanke,
					; Start	sofort,	Konstante folgt, Kanal Reset
		out	(CTC0), a	; CTC0
		ld	a, 96h		; Zeitkonstante
		out	(CTC0), a
		in	a, (PIO1AD)
		set	7, a
		out	(PIO1AD), a	; Lautsprecher an
chrdrv.bell1:	djnz	chrdrv.bell1
		dec	c
		jr	nz, chrdrv.bell1
		res	7, a
		out	(PIO1AD), a	; Lautsprecher aus
		ld	a, 00000011b
		out	(CTC0), a	; CTC0 Reset
		pop	bc
		pop	af
		ei
		ret


;-----------------------------------------------------------------------------
; UP2 Gerätreiber für PUNCH
; Z9001-System-Gerätetreiber
; V24-User-Port 9600 Bd
; User-Pio, Bit7 (in) DTR Drucker bereit? 1=kein Senden. Bit 0 (out) serielle Daten
; s.a. mp 10/87, S. 311 ff.
;-----------------------------------------------------------------------------

chrdrv.uup:	push	af		; Kommandocode merken
		ld	a, 12		; Zeitconstante TC für 9600 baud
		jr	chrdrv.ucrtl1

;-----------------------------------------------------------------------------
; CRT-Gerätetreiber für	LIST
; Z9001-System-Gerätetreiber
; V24-User-Port 1200 Bd
; User-Pio, Bit7 (in) DTR Drucker bereit? 1=kein Senden. Bit 0 (out) serielle Daten
; s.a. mp 10/87, S. 311 ff.
;-----------------------------------------------------------------------------

chrdrv.ucrtl:	push	af		; Kommandocode merken
		ld	a, 126		; Zeitconstante TC für 1200 baud
chrdrv.ucrtl1:	ld	(chrdrv.ucrtl4+1), a
		ld	a, 11001111b
		out	(PIO1BC), a	; PIO1B	init Bitmode
		ld	a, 10000000b
		out	(PIO1BC), a	; Bit7 Eingabe,	Bit6-Bit0 Ausgabe
;
		pop	af		; Kommandocode
		inc	a		; FF? (Initialisieren)
		ret	z		; dann fertig
		dec	a		; 0?  (Abfrage Status)
		jr	nz, chrdrv.ucrtl2	; nein
;
		in	a, (PIO1BD)	; PIO1B	lesen
		or	7Fh		; Bit 7=0
		cpl
		ret
; Zeichenausgabe
chrdrv.ucrtl2:	call	chrdrv.stopkey
		jr	nc, chrdrv.ucrtl3	; Sprung, wenn STOP-Taste nicht	gedrückt
		ld	(15h), a	; LISW,	Schalter für Hardcopy
		ret
;
chrdrv.ucrtl3:	in	a, (PIO1BD)	; PIO1B	lesen
		add	a, a		; Drucker bereit?
		jr	c, chrdrv.ucrtl2	; warten, solange Bit7 gesetzt
		ld	a, c		; Zeichen nach A
		cp	7Fh
		jr	nz, chrdrv.ucrtl4
		ld	a, 1Bh
chrdrv.ucrtl4:		ld	e, 126		; Zeitkonstante, Wert wird verändert (ucrtl1)
		ld	b, 9		; 1 Startbit + 8 Datenbits
		di
		or	a		; Cy=0
		rla			; Start-Bit
chrdrv.ucrtl5:	out	(PIO1BD), a	; Bit ausgeben, PIO1B schreiben
		call	chrdrv.ucrtl6		; kurze	Pause, Zeitwert	in E
		rra			; nächstes Bit
		djnz	chrdrv.ucrtl5
		or	1		; Stopbit
		out	(PIO1BD), a	; PIO1B	schreiben
		ei
; Bit-Wartezeit, kurze Pause, Zeitwert in E
chrdrv.ucrtl6:	push	de
chrdrv.ucrtl7:	dec	e
		jr	nz, chrdrv.ucrtl7
		pop	de
		ret


;-----------------------------------------------------------------------------
; UL Gerätetreiber für LIST
; Z9001-System-Gerätetreiber
; Centronics User-Port
; s.a. mp 10/87, S. 311 ff.
; 7 Datenbits verfueghar, PIO bit7 wird zur Bildung des Centronics-/STR0BE-Signals verwendet.
; /ACKNLG vom Drucker wird ueber den CTC-Kanal erfasst.
;-----------------------------------------------------------------------------

chrdrv.uul:	inc	a		; Kommandocode FF (Initialisieren)?
		ret	z		; ja
		dec	a		; Kommandocode 0?  (Abfrage Status)
		cpl
		ret	z		; ja
;
		ld	a, 11001111b
		out	(PIO1BC), a	; Bit-Mode
		xor	a		; alles Ausgabe
		out	(PIO1BC), a
		ld	a, 01010111b	; Zähler, pos. Flanke
		out	(CTC1), a	; Init. CTC
		out	(CTC1), a
;
		ld	a, c		; Zeichen
		or	80h		; /Strobe = high
		cp	0FFh		; Zeichen 7F->1Bh
		jr	nz, chrdrv.uul1
		ld	a, 9Bh
chrdrv.uul1:		out	(PIO1BD), a	; Zeichen ausgeben
		push	ix		; kurze Wartezeit
		pop	ix
		and	7Fh		; /Strobe = low
		out	(PIO1BD), a
		or	80h		; /Strobe = high
		out	(PIO1BD), a
chrdrv.uul2:		call	chrdrv.stopkey		; STOP-Taste?
		ret	c
		in	a, (CTC1)
		cp	57h		; /ACKNLG?
		jr	z, chrdrv.uul2		; nein, warten
		xor	a
		ret

;-----------------------------------------------------------------------------
; console status
;-----------------------------------------------------------------------------

chrdrv._const:	call	0F006h		; Z9001-OS: Abfrage Status CONST
		or	a
		ret	z
		ld	a, 0FFh
		ret

;-----------------------------------------------------------------------------
; BAT-Gerätereiber für CRT
;-----------------------------------------------------------------------------

chrdrv._BATC:	or	a
		jp	nz, 0F7B4h	; Z9001-OS: BAT, Steuerprogramm für Batch-Mode von CONST
		ld	hl, (0F016h)	; Z9001-OS: Adresse des UP READER (Eingabe Zeichen von Reader)
		inc	hl
		inc	hl
		jp	(hl)

;-----------------------------------------------------------------------------
; Dummy-Gerätetreiber, gibt stets Dateiende (^Z) zurück
;-----------------------------------------------------------------------------

chrdrv._dummyin:				; ^Z; Eingabeende
		ld	a, 1Ah
		ret


;-----------------------------------------------------------------------------
; console character out
;-----------------------------------------------------------------------------

chrdrv._conout:	ld	a, (chrdrv._con_esc)
		cp	0FFh		; normale Ausgabe?
		jr	z, chrdrv._conout3
;		
		ld	hl, (chrdrv._con_escp)	; Pointer in Liste
		res	7, c		; Bit 7 löschen
		inc	c		; + 1
		ld	(hl), c		; Zeichen merken
		dec	hl
		ld	(chrdrv._con_escp), hl	; Pointer rücksetzen
		ld	hl, chrdrv._con_esc	; Anzahl weiterer Kommando-Zeichen 
		dec	(hl)		; = 0?
		jr	nz, chrdrv._conout2	; nein
;		
		dec	(hl)		; Anzahl weiterer Kommando-Zeichen - 1 setzen
		
		ld	hl, chrdrv._conout1	; return-Adresse
		push	hl		; auf Stack
		ld	hl, (0F069h)	; Z9001-OS: Adr. Setzen log. Cursor
		push	hl		; auf Stack
		ld	l, 3		;  L=3, Anfangswert fuer Cursorrufe (OS-BOS)
		ld	de, (chrdrv._con_escp1)	; DE := Zeile/Spalte
		ret			; und Cursor setzen
;
chrdrv._conout1:
		ld	hl, chrdrv._con_escp2	; Pointer in Liste
		ld	(chrdrv._con_escp), hl	; auf Anfang-1 setzen
;
chrdrv._conout2:or	a
		ret
;
chrdrv._conout3:
		ld	a, (25h)	; KEYBU	(Tastaturbuffer)
		cp	13h		; PAUSE-Taste?
		jr	nz, chrdrv._conout4
		push	bc
		call	0F009h		; Z9001-OS: Eingabe Zeichen von CONST, PAUSE-Taste holen
		call	0F009h		; Z9001-OS: Eingabe Zeichen von CONST, Warten auf Tastendruck
		pop	bc
chrdrv._conout4:	
		ld	a, 1Bh		; ESC?
		cp	c
		jr	nz, chrdrv._conout5
; Cursor-Positionierung 1Bh Zeile+128 Spalte+128 (kompatibel zum PC 1715)
		ld	a, 2		;escape flag setzen
		ld	(chrdrv._con_esc), a
		jr	chrdrv._conout1
chrdrv._conout5:
;schnelles CLS 04.08.2016
		ld	a,0Ch		; CLS
		cp	c
		jp	nz, 0F00Ch	; Z9001-OS: Ausgabe Zeichen zu CONST
		jr	chrdrv.fcls


;------------------------------------------------------------------------------
; Schnelles Löschen beliebiger Fenster, frei nach mp 11/1989, S. 344
;------------------------------------------------------------------------------

chrdrv.fcls:
	
	section fastcls

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

SPACE:	EQU	20H		;LEERZEICHEN

	
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

	endsection

;-----------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------


	elseif codesec=ubiossec
;RAM
;
chrdrv.lstflag:		db	0		; wenn vorher LIST gedrückt, dann steht hier 1 bzw. 1Ch

chrdrv._con_esc:	db 	0FFh		; Anzahl weiterer ESC-Kommando-Zeichen
chrdrv._con_escp:	dw	chrdrv._con_escp1	; Pointer in Liste der ESC-Kommando-Zeichen
chrdrv._con_escp1:	db	0		; Parameterliste (Ringpuffer Länge 2), hier Cursor-Zeile
chrdrv._con_escp2:	db	0		; und Cursor-Spalte

	elseif codesec=initsec

;INIT

chrdrv.init:	ld	hl, 0FCB0h	; Z9001-OS: Tabelle der Interruptadressen
		ld	bc, 0Ch
		ld	de, intvectab	; nach E700 kopieren
		ldir

		ld	c, stdiobyte	
		call	0F03Ch		; Z9001-OS: Setzen I/O-Byte

		ld	a, hi(intvectab); Interrupttabelle
		ld	i, a		; Interruptregister setzen
		im	2

		; Gerätetreibertabellen füllen
		di
		ld	hl,chrdrv.fiotab
		ld	de,0EFC9h	; Tabelle der Gerätetreiberadressen
		ld	bc,4*4*2
		ldir
		
		ei

		xor	a
		ld	(chrdrv.lstflag), a
		
		; Initialisierung CRT
		ld	hl, chrdrv._con_escp1	; ESCAPE-Modus Ringpuffer
		ld	(chrdrv._con_escp), hl	; init.
		ld	hl, 0		; mit 0 füllen
		ld	(chrdrv._con_escp1), hl
		ld	a, 0FFh
		ld	(chrdrv._con_esc), a	; evtl. ESCAPE-Modus beenden
		
		ret


chrdrv.fiotab:
		; Gerätetreiber	CONST/CON setzen
		dw	chrdrv.uTTYC		; TTY:
		dw	chrdrv.uCRTC		; CRT:
		dw	chrdrv._BATC		; BAT:
		dw	0F8F1h		; RDR/UC1:=	CRT-Treiber Z9001
		; Gerätetreibertabelle READER/RDR setzen
		dw	0F8F1h		; TTY:=	CRT-Treiber Z9001
		dw	chrdrv._dummyin	; RDR/PTR:
		dw	chrdrv._dummyin	; UR1:
		dw	chrdrv._dummyin	; UR2:
		; Gerätetreibertabelle PUNCH/PUN setzen
		dw	0F8F1h		; TTY:=	CRT-Treiber Z9001
		dw	chrdrv.upunch		; PUN/PTP:
		dw	chrdrv.upunch		; UP1:
		dw	0E397h		; UP2:
		; Gerätetreibertabelle LIST/LST setzen
		dw	18h
		dw	0F8F1h		; TTY:=	CRT-Treiber Z9001
		dw	chrdrv.uCRTL		; CRT:
		dw	chrdrv.uup		; LST/LPT:
		dw	chrdrv.uUL		; UL/UL1:


;display I/O-Byte Macro
chrdrv.diob		macro 	maske,compare
		IF stdiobyte & maske = compare
			db 	'*'
		ELSE
			db	' '
		ENDIF
		endm


chrdrv.BOOTMSG	macro
                db      0dh,0ah
                dw	gelb
	if IOLOC=4
                db      "I/O-Byte 0004H (Z9001)", 0Dh, 0Ah
	endif
                db      "I/O-Devices:", 0Dh, 0Ah
                dw	gruen
		chrdrv.diob 11000000b, 01000000b
		db	" LST:=CRT: V24-User-Port 1200 Bd", 0Dh, 0Ah
		chrdrv.diob 11000000b, 10000000b
		db	" LST:=LPT: V24-User-Port 9600 Bd", 0Dh, 0Ah
		chrdrv.diob 11000000b, 11000000b
		db	" LST:=UL1: Centronics User-Port", 0Dh, 0Ah
		chrdrv.diob 00000011b, 00000000b
		db	" CON:=TTY: Beep + Gross<=>Klein", 0Dh, 0Ah
		chrdrv.diob 00000011b, 00000001b
		db	" CON:=CRT: nur  Tastatur-Beep", 0Dh, 0Ah
		chrdrv.diob 00000011b, 00000011b
		db	" CON:=UC1: ohne Beep", 0Dh, 0Ah
		endm

	endif
