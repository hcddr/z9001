; Z9001\drucker\BM116.rom
; Base Address:	0000h Range: B800h - C000h Loaded length: 0800h
; reass. Volker Pohlers 2006, basiert teilw. auf Quelle v24a3q.asm von robotron
; letzte Änderung 24.03.2020
;------------------------------------------------------------------------------
; Druckertreiber V24A1, V24A2, V24A3, Druckermodul 690025.2 (ab 3. Quartal 1987), ROM BM116
;------------------------------------------------------------------------------
; orig. Autor Lutz Elßner (?)
; Beschreibung s. Bedienungsanleitung Schreibmaschinenmodul

		cpu	z80
		page	0
		title	"V24Q"

;*************************************
;
;Teiber fuer V24-Drucker (V24, Quelle)
;
;Stand: 19.6.86
;
;*************************************
;
;Treiberaufbau entsprechend Beschreibung
;"Betriebssystem Z9001"
;Abschnitt "3. Zusaetzliche Treiber"
;
;************************************
;
;Geeignet fuer alle Drucker mit Schnittstelle
;RS232C und DTR-Protokoll (Hardware-Protokoll)
;
;
;Verwendbar sind alle Drucker- und Schreib-
;maschinen-Module mit abgeschaltetem EPROM
;und an den Drucker angepassten Steckverbinder
;
;************************************
;
;Anschluss Drucker an Modulkabel
;
;Modulkabel           Drucker
;
;Schirm:SG -----------SG
;blau  :TxD>--------->RxD
;rot   :CTS<---------<DTR
;                     (bei S6010: RTS)
;
; ------------------------------------------
;                            Leitungsbe-
;      Name                  zeichnung nach
;                            CCITT  EIA DIN
; ------------------------------------------
; SG   Betriebsmasse         102    AB  E2
; TxD  Sendedaten            103    BA  D1
; RxD  Empfangsdaten         104    BB  D2
; RTS  Sendeteil einschalten 105    CA  S2
; CTS  Sendebereitschaft     106    CB  M2
; DTR  Betriebsbereitschaft  108.2  CD  S1.2
; ------------------------------------------
;
;************************************
;
;Parameter zur Anpassung des Treibers
;an verschiedene Einsatzbedinungen
;
;====================================
;
;Programmanfang: ANF (auf 100H-Grenze!)
;
;------------------------------------
;
;Baudrate: BDRAT in Bd
;    BDRAT=50, 75, 100, 150, 200, 300, 600,
;          1200, 2400, 4800 oder 9600
;
;Zeitkonstante fuer CTC: ZKCTC=9600/BDRAT
;
;------------------------------------
;
; Datenbit: DABI
;    7 Datenbit: DABI=20H
;    8 Datenbit: DABI=60H
;
;------------------------------------
;
; Paritaetsbit: PABI
;    ohne     Paritaet: PABI=2
;    gerade   Paritaet: PABI=3
;    ungerade Paritaet: PABI=1
;
;------------------------------------
;
; Stopbit: STPBI
;    1   Stopbit: STPBI=4
;    1.5 Stopbit: STPBI=8
;    2   Stopbit: STPBI=0CH
;
;------------------------------------
;
; Portadressen
;    Adresse SIO-Kanal Daten    : SIODA
;         - " -        Kommandos: SIOKD
;    Adresse CTC-Kanal          : CTC
;
;************************************
;
;Vereinbarungen
;
;====================================
;
ANF:	EQU	0B800H	;Programmanfang
;------------------------------------
;
ZKCTC:	EQU	1	;9600 Bd
DABI:	EQU	60H	;8 Datenbit
PABI:	EQU	2	;ohne Paritaet
STPBI:	EQU	4	;1 Stopbit
;------------------------------------
SIODA:	EQU	0B0H	;Datenadr SIO Kanal A
SIOKD:	EQU	SIODA+2	;Kdoadr   - " -
CTC:	EQU	0A8H	;Adr CTC Kanal 0
;------------------------------------
IOBYT:	EQU	4	
ASV:	EQU	0FH	;Register für A bei Eintritt in BOS
LISW:	EQU	15H	;Schalter für Hardcopy (1=copy)
PU:	EQU	2FH	;Hilfszelle
DRADR:	EQU	0EFE1H	;Adr.Druckertreiber
DRNAM:	EQU	0EFEFH	;Name Druckertreiber
CSTS:	EQU	0F006H	;Consol-Status
CONSI:	EQU	0F009H	;Consol-Input
;
;	44h	Seiteneinteilung J/N
;	45h	Textzeilen je Seite
;	46h	Anz. freier Zeilen in Seite
;	47h	Leerzeilen je Seite
;	48h	linker Rand
;	49h	max. Zeilenänge
;	4Ah	Anz. freier Zeichen in Zeile
;	4Bh	V24A1 = 81h, V24A2 = 80h, V24A3 = 0
;
;------------------------------------
STOP:	EQU	3	;STOP-Taste
LF:	EQU	0AH	;Line feed
CR:	EQU	0DH	;Carriage return
COP:	EQU	10H	;CONTR-P
;
;************************************
;
	ORG	ANF	

		jp	DINI1
aV24a1:		db 	"V24A1   ",0
		jp	DINI2
aV24a2:		db 	"V24A2   ",0
		jp	DINI3
aV24a3:		db 	"V24A3   ",0
		db    0	;

;-----------------------------------------------------------------------------
DINI1:		call	dia1
		jr	c, DINIF	; Fehler
		ld	hl, aV24a1	; "V24A1   "
		ld	bc, ol1

;-----------------------------------------------------------------------------
DINIE:		ld	(DRNAM), hl	;Name Druckertreiber
		ld	(DRADR), bc	;Adr.Druckertreiber
		ld	a, (IOBYT)
		and	3Fh		;Zuordnung LIST:=TTY (phys. Geraet 0)
		ld	(IOBYT), a
		;vp 30.04.2020
		ld	de,ANF-101h
		ld	(0036h),de	;EOR setzen
		;
		and	a		; Cy=0
		ret

;-----------------------------------------------------------------------------
DINIF:		ld	a, 0		; Korr.	Monitor
		ld	(LISW), a	; Version 1.1.
		ld	a, 4		; error 4 (Fehler bei Gerätezuweisung)
		ret

;-----------------------------------------------------------------------------
DINI2:		call	dia2
		jr	c, DINIF	; Fehler
		ld	hl, aV24a2	; "V24A2   "
		ld	bc, ol2
		jr	DINIE

;-----------------------------------------------------------------------------
DINI3:		call	DIA3
		jr	c, DINIF	; Fehler
		ld	hl, aV24a3	; "V24A3   "
		ld	bc, OL3
		jr	DINIE

;-----------------------------------------------------------------------------
; Initialisierung V24A1
dia1:		ld	a, 81h
dia11:		push	af
		ld	hl, aStandardwerteF ; "\nStandardwerte fuer Format A4\r\n\nEndlosp"...
		call	GetJN
		jp	c, dia111
		cp	'N'
		jr	z, dia14
		ld	hl, aMitSeiteneinte ; "\nMit Seiteneinteilung? (J)/N:"
		call	GetJN
		jr	c, dia111
		cp	'N'
		jr	z, dia16
		ld	a, 3
		push	af
		ld	ix, aTextzeilenJeSe ; "\nTextzeilen je Seite:   66   "
		call	GetNUM
		jr	c, dia110
		push	af
		ld	ix, aLeerzeilenJeSe ; "\nLeerzeilen je Seite:    6   "
		call	GetNUM
		jr	c, dia19
dia12:		push	af
		ld	ix, aLinkerRand10 ; "\nLinker Rand:           10   "
		call	GetNUM
		jr	c, dia18
		push	af
		ld	ix, aMax_Zeilenlaen ; "\nMax. Zeilenlaenge:     68   "
		call	GetNUM
		jr	c, dia17
		ld	(49h), a	;max. Zeilenänge
		ld	(4Ah), a	;max. Zeilenänge
		pop	af
		ld	(48h), a	;linker Rand
		pop	af
		ld	(47h), a	;Leerzeilen je Seite
		pop	af
		ld	(45h), a	;Textzeilen je Seite
		ld	(46h), a	;Textzeilen je Seite
		pop	af
		ld	(44h), a	;Seiteneinteilung J/N
		pop	af
dia13:		ld	(4Bh), a	;Endlospapier J/N
		ld	de, aPapierPosition ; "\nPapier positionieren!\r\n"
		call	prnst		; Ausgabe Text
;
		ld	hl, PROGT
		ld	b, 3
		ld	c, CTC
		otir
		ld	b, 9
		ld	c, SIOKD
		otir
		and	a
		ret
;
dia14:		ld	a, 2
		push	af
		ld	ix, aTextzeilenJe_0 ; "\nTextzeilen je Seite:   58   "
		call	GetNUM
		jr	c, dia110
dia15:		push	af
		jr	dia12
dia16:		ld	a, 1
		push	af
		jr	dia15
;
dia17:		pop	hl
dia18:		pop	hl
dia19:		pop	hl
dia110:		pop	hl
dia111:		pop	hl
		ret


;-----------------------------------------------------------------------------
; Initialisierung V24A2
dia2:		ld	a, 80h
		jp	dia11

;-----------------------------------------------------------------------------
; Initialisierung V24A3
DIA3:		xor	a
		jr	dia13

;-----------------------------------------------------------------------------
aStandardwerteF:db 	"\nStandardwerte fuer Format A4\r\n"
		db 	"\nEndlospapier?         (J)/N:",0
aMitSeiteneinte:db 	"\nMit Seiteneinteilung? (J)/N:",0
		db 	1
		db 	66
aTextzeilenJeSe:db 	"\nTextzeilen je Seite:   66   ",0
		db 	1
		db 	58
aTextzeilenJe_0:db 	"\nTextzeilen je Seite:   58   ",0
		db 	1
		db 	6
aLeerzeilenJeSe:db 	"\nLeerzeilen je Seite:    6   ",0
		db 	0
		db 	10
aLinkerRand10:	db 	"\nLinker Rand:           10   ",0
		db 	1
		db 	68
aMax_Zeilenlaen:db 	"\nMax. Zeilenlaenge:     68   ",0
aPapierPosition:db 	"\nPapier positionieren!\r\n",0

;-----------------------------------------------------------------------------
PROGT:		DB	3	;CTC
		DB	17H	
		DB	ZKCTC	
		DB	18H	;SIO
		DB	4	
		DB	40H+PABI+STPBI	
		DB	1	
		DB	0	
		DB	3	
		DB	0C0H	
		DB	5	
		DB	DABI+8	
		
;-----------------------------------------------------------------------------
GetJN:		ex	de, hl
		call	prnst		; Ausgabe Text
		ex	de, hl
		ld	a, 2
		call	RCONB
		ret	c
		jr	nz, GetJN1
		ld	a, 'J'
		ret
;
GetJN1:		cp	2
		jr	nc, GetJN
		inc	de
		ld	a, (de)
		cp	'N'
		ret	z
		cp	'J'
		jr	nz, GetJN
		ret
;-----------------------------------------------------------------------------
GetNUM:		push	ix
		pop	de
		call	prnst		; Ausgabe Text
		ld	a, 4
		call	RCONB
		ret	c
		jr	nz, GetNUM1
		ld	a, (ix-1)
		ret
;
GetNUM1:	cp	4
		jr	nc, GetNUM
		ld	b, a
		ld	hl, 0
GetNUM2:	push	bc
		add	hl, hl
		push	hl
		add	hl, hl
		add	hl, hl
		pop	bc
		add	hl, bc
		inc	de
		ld	a, (de)
		sub	30h ; '0'
		cp	0Ah
		pop	bc
		jr	nc, GetNUM
		push	bc
		ld	c, a
		ld	b, 0
		add	hl, bc
		pop	bc
		djnz	GetNUM2
		ld	a, h
		and	a
		jr	nz, GetNUM
		ld	a, l
		cp	(ix-2)
		jr	c, GetNUM
		ret
;-----------------------------------------------------------------------------
; Ausgabe Text
prnst:		ld	c, 9
		jp	5
;-----------------------------------------------------------------------------
RCONB:		ld	de, 80h
		ld	(de), a
		ld	c, 0Ah		; Eingabe Zeichenkette
		call	5
		ret	c
		inc	de
		ld	a, (de)
		and	a
		ret

;-----------------------------------------------------------------------------
;Ausgaberoutine fuer Drucker V24A1 (Ansprung über DRADR)
ol1:		inc	a
		jp	z, dia1		; A=FF, Initialisierung

;-----------------------------------------------------------------------------
OLE:		dec	a
		jp	z, STA		; A=0, Statusabfrage
		dec	a
		dec	a
		jr	nz, OLF		; nur A=0,2,FF wird unterstützt, alle anderen Werte -> Fehler
		call	DOUT		; A=2
		ret	nc

;-----------------------------------------------------------------------------
OLF:		xor	a		; Korr.Monitor
		ld	(LISW), a	; Version 1.1.
		scf			; Fehler
		ret			; Treiberaufruf

;-----------------------------------------------------------------------------
;Ausgaberoutine fuer Drucker V24A2
ol2:		inc	a
		jp	z, dia2		; A=FF
		jr	OLE

;-----------------------------------------------------------------------------
;Ausgaberoutine fuer Drucker V24A3
OL3:		inc	a
		jp	z, DIA3		; A=FF
		jr	OLE

;-----------------------------------------------------------------------------
; Datenausgabe 
; Zeichen in C
DOUT:		ld	a, (4Bh)
		and	a		; Modus V24A3?
		jp	p, DOUT2	; dann direkte Zeichenausgabe
; V24A1 und V24A3: Seitenaufteilung und Sonderzeichen
		bit	1, a
		set	1, a
		ld	(4Bh), a
		push	bc
		call	z, DOLIRAND	; Ausgabe von Leerzeichen
		pop	bc
		ret	c
; Bildschirmkopie
		ld	a, c
		cp	0Eh		; Bildschirmkopie? CTRL-N
		jr	nz, DOBSPC
		ld	hl, 0EC00h
		in	a, (88h)
		bit	2, a
		ld	a, 20		; 20 Zeilen
		jr	nz, dout_1
		add	a, 4		; oder 24 Zeilen?
dout_1:		ld	d, a
dout_2:		ld	e, 40
dout_3:		ld	c, (hl)
		push	de
		call	DOUT		; Datenausgabe
		pop	de
		ret	c
		inc	hl
		dec	e
		jr	nz, dout_3
		call	DOCRLF		; Ausgabe CR+LF
		ret	c
		dec	d
		jr	nz, dout_2
		ret
;BackSpace
DOBSPC:		cp	8
		jr	nz, DOCR
		ld	a, (4Ah)
		ld	hl, 49h
		cp	(hl)
		ret	z
		inc	a
		jp	dout_20
;CR carriage return
DOCR:		cp	0Dh
		jr	nz, DOLF
		call	DOUT2
		ret	c
		ld	a, (49h)
		ld	(4Ah), a

;-----------------------------------------------------------------------------
; Ausgabe von Leerzeichen
DOLIRAND:	ld	a, (48h)
		and	a
		ret	z
		ld	b, a
DOLIRAND1:	ld	c, ' '    	; Ausgabe von B Leerzeichen
		call	DOUT2
		ret	c
		djnz	DOLIRAND1
		ret

;-----------------------------------------------------------------------------
;LF line feed
DOLF:		cp	0Ah
		jr	nz, dout_13
		call	DOUT2
		ret	c
		ld	a, (44h)
		cp	1
		ret	z
		ld	a, (46h)
		dec	a
		ld	(46h), a
		ret	nz

dout_7:		ld	a, (45h)
		ld	(46h), a
		ld	a, (44h)
		cp	2
		jr	nz, dout_11
		push	bc
		push	de
		push	hl
		ld	hl, (PU)
		ld	a, (ASV)
		ld	h, a
		push	hl

dout_8:		call	CSTS		; get console status
		jr	c, dout_10	; Cy=1
		and	a
		jr	z, dout_8	; CY=0
		cp	STOP
		scf
		jr	z, dout_10	; CY=1
		cp	COP		; CTRL-P
		jr	nz, dout_9	; CY=0
		xor	a
		ld	(LISW), a
dout_9:		call	CONSI		; console input
dout_10:	pop	hl
		ld	a, h
		ld	(ASV), a
		ld	a, l
		ld	(PU), a
		pop	hl
		pop	de
		pop	bc
		ret
;
dout_11:	ld	bc, (46h)
dout_12:	ld	c, 0Ah
		call	DOUT2
		ret	c
		djnz	dout_12
		ret
;		
dout_13:	cp	0Ch		;CLS Bildschirm löschen, CTRL-L
		jr	z, dout_14
		cp	17h		;Seitenvorschub CTRL-W
		jr	nz, DOCUR
;
dout_14:	ld	a, (44h)
		cp	1
		jp	z, DOCRLF	; Ausgabe CR+LF
		ld	bc, (45h)
;
dout_15:	ld	c, LF
		call	DOUT2
		ret	c
		djnz	dout_15
		ld	c, CR
		call	DOUT		; Datenausgabe
		ret	c
		jr	dout_7
;
; Kursor rechts
DOCUR:		cp	9
		jr	nz, dout_17
		ld	c, ' '		; ersetzen durch Leerzeichen
		ld	a, c
;
dout_17:	cp	1Bh		; ESC ?
		jr	z, DOUT2	; direkt an Drucker ausgeben
		cp	20h 		; nicht bearbeitetes Steuerzeichen < 20h ?
		ccf
		ret	nc		; dann Fehler
		cp	7Fh 		; Steuerzeichen 7Fh ?
		ret	z
		ld	a, (4Ah)
		and	a		; Zeilenende erreicht ?
		jr	nz, dout_18
		ld	d, c
		call	DOCRLF		; ja, Ausgabe CR+LF
		ret	c
		ld	c, d
;
dout_18:	ld	a, c
		cp	80h 		; Grafikzeichen?
		jr	c, dout_19
		ld	a, (4Bh)
		bit	0, a		; Modus V24A1 ?
		jr	z, dout_19
		ld	c, '*'		; dann Stern statt Grafikzeichen drucken
;
dout_19:	ld	a, (4Ah)
		dec	a
dout_20:	ld	(4Ah), a

;-----------------------------------------------------------------------------
; direkte Zeichenausgabe, V24A3
DOUT2:		push	bc
		push	de
		push	hl
		ld	hl, (PU)
		ld	a, (ASV)
		ld	h, a
		push	hl
		call	CSTS		; Taste gedrückt?
		jr	c, DOUT8
		and	a
		jr	z, DOUT8	; Cy=0
		cp	STOP
		scf
		jr	z, DOUT8	; Cy=1
		xor	COP
		jr	nz, DOUT8	; Cy=0
		xor	a		; A := 0
		ld	(LISW), a	; Hardcopy aus
		call	CONSI		; gedrückte Taste aus Puffer entfernen
;
DOUT8:		pop	hl
		ld	a, h
		ld	(ASV), a
		ld	a, l
		ld	(PU), a
		pop	hl
		pop	de
		pop	bc
		ret	c		; Fehler-->RET
		call	STA		; Statusabfrage
		and	a
		jr	z, DOUT2
		ld	a, c		; Zeichen aus C nehmen
		out	(SIODA), a	; und Ausgabe
		ret

;-----------------------------------------------------------------------------
; Ausgabe CR+LF
DOCRLF:		ld	c, 0Dh
		call	DOUT		; Datenausgabe
		ret	c
		ld	c, 0Ah
		jp	DOUT		; Datenausgabe

;-----------------------------------------------------------------------------
; Statusabfrage
STA:		ld	a, 10h
		out	(SIOKD), a
		in	a, (SIOKD)	; SIO RR0
		and	24h
		cp	24h
		ret	z		; Bereit (A<>0)
		xor	a		; Nicht	bereit
		ret			;  (A=0)

END:	EQU	$-1	
LAENG:	EQU	$-ANF	
		;end	0ffffh
		end	DINI3
