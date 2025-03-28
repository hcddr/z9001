	CPU	Z80
;04.03.2003 15:59 Umsetzung auf AS
;************************************************
;
;        extended monitor fuer Z9001
;           mit OS V 1.2. oder 1.3.
;
;************************************************
;
;
;Band:        /        ,      -      .
;
;
;Autor: Volker Pohlers,
;       Lomonossowallee 41/81, Greifswald, 2200
;
;1986-1990 entstanden, Vorlaeufer: CMON6
;
;letzte Aenderung: 10.08.1990
;19.03.2006 ROM-Schreibschutz bei SAVE nun komplett ausgehebelt
;20.03.2006 HLKON war fehlerhaft! komplett neue Routine
;
;
;************************************************
;DEFINITIONEN
;************************************************
;
;OS-Notizspeicheradressen
;------------------------
;
RST8:	EQU	008H	;RST 8-Adr.
SPSV:	EQU	00BH
BCSV:	EQU	00DH
ASV:	EQU	00FH
LISW:	EQU	015H	;Druckschalter
DMA:	EQU	01BH	;Zeiger auf Kassettenpuffer
LAKEY:	EQU	024H	;letztes Zeichen von Tastatur
KEYBU:	EQU	025H	;Merkzelle letztes Zeichen
EOR:	EQU	036H	;Ende des RAM-Speichers
P3ROL:	EQU	03DH	;1. WINDOWspalte-1
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
ARB:	EQU	006AH
CONBU:	EQU	80H	;Eingabepuffer
INTLN:	EQU	100H	;Zeichenkettenpuffer
RKACT:	EQU	200H	;Interruptadr. SAVE
RKEP:	EQU	20AH	;Interruptadr. LOAD
MAPPI:	EQU	0EFC0H	;Systemschutz
;
;OS-Routinen
;-----------
;
CBOS:	EQU	05H	;zentraler BOS-Ruf
WBOOT:	EQU	0F003H	;Warmstart
JPVEC:	EQU	0F045H	;BOS-Adresstabelle
DISPA:	EQU	0F0BDH	;ASGN-Anzeige
ZAU:	EQU	0F1B8H	;Ausgabe Uhrzeit
GVAL:	EQU	0F1EAH	;Parameter holen
CHRAM:	EQU	0F23BH	;RAM-Test
OCRLF:	EQU	0F2FEH
OUTA:	EQU	0F305H
OSPAC:	EQU	0F310H
BOSE:	EQU	0F345H	;BOS-Ende
GETMS:	EQU	0F35CH	;Eing. Zeile
PRNST:	EQU	0F3E2H	;Stringausgabe
LOAD1:	EQU	0F526H	;File lesen
MOV:	EQU	0F588H
REQU:	EQU	0F593H	;Ausg. Startmeldung
COEXT:	EQU	0F5B9H	;Vorverarbeiten Zeile
ERINP:	EQU	0F5E2H	;Eingabefehler
ERPAR:	EQU	0F5E6H	;Parameterfehler
ERDIS:	EQU	0F5EAH	;Fehlermeldung
REA:	EQU	0F5A3H	;Ausgabe Fehlermeldung
BOSER:	EQU	0F5DEH	;BOS-Error
DCU:	EQU	0F73EH	;Cursor loeschen
FORMS:	EQU	0F836H	;Stringformatierung
INITA:	EQU	0FAE3H	;Tastatur init.
INIC1:	EQU	0FB0AH
COMPW:	EQU	0FCBCH	;Adressvergleich
DECO0:	EQU	0FD33H
KARAM:	EQU	0FED6H	;Blockschreiben
MAREO:	EQU	0FF59H	;Blocklesen
IKACT:	EQU	0FF43H	;Int.routine SAVE
IKEP:	EQU	0FFBDH	;Int.routine LOAD
;
;CBOS-Rufe
;
CONSI:	EQU	1	;CONST-Eingabe
CONSO:	EQU	2	;CONST-Ausgabe
LISTO:	EQU	5	;LIST-Ausgabe
CSTS:	EQU	11	;CONST-Status
RETVN:	EQU	12	;Monitorversion
OPENR:	EQU	13	;OPEN READ
OPENW:	EQU	15	;OPEN WRITE
CLOSW:	EQU	16	;CLOSE WRITE
WRITS:	EQU	21	;Block schreiben
SETCU:	EQU	18	;Cursor setzen
;
;Zeichencodes
;
CUL:	EQU	08H
CLS:	EQU	0CH
CRLF:	EQU	0A0DH
CR:	EQU	0DH
LF:	EQU	0AH
ROT:	EQU	0114H
GRUEN:	EQU	0214H
GELB:	EQU	0314H
;
;
;EMON-Standorte
;--------------
;
;MROM:	EQU	0B200H
MROM:	EQU	03200H
MRAM:	EQU	MROM-80H
;
;***
;
;************************************************
;             EMON-Arbeitsspeicher
;************************************************
;
	ORG	MRAM
;
BOVEC:	DS	68	;BOS-Adresstabelle
;
MARAM:	DS	3	;Block lesen jp MAREO
;
AREA:	Ds 	2	;Kopierspeicher 500H
BLAN:	Ds	1	;Blockanzahl
LAEN:	Ds	1	;Namenlaenge
CMODE:	Ds	1	;CASSETTE-MODUS
;
ARB1:	Ds	1
ARB2:	Ds	1
ARA1:	Ds	2
ARA2:	Ds	2
;
RAM:	Ds	3	;RAM-Editor jp ERAM
DEZBUF:	Ds	6 	; Buffer für Hex-Dez-Konvertierung
REND:	EQU	$
;***
;
;
;************************************************
;
;                ***KOPFLISTE***
;
;************************************************
;
	ORG	MROM
;
	JP	ECCP	;bei <RESET>
	DB	"#       "
	DB	0
	JP	RAM	;RAM-Editor
	DB	"DISPLAY "
	DB	0
	JP	CASS	;Kassettenmodul
	DB	"CASSETTE"
	DB	0
	JP	HELP	;Hilfsfkt.
	DB	"HELP    "
	DB	0
	JP	ECCP1
	DB	"MENUE   "
	DB	0
	DB	0BBH	;Texte folgen
;
	DB	0	;# kein Text
	DB	"kleiner RAM-Editor"
	DB	0
	DB	"Monitor zur Kassettenarbeit"
	DB	0
	DB	"Hilfsfunktion: Auflisten der"
	DW	CRLF
	DB	"          Kurzerklaerungen"
	DB	0
	DB	"Auflisten nutzbarer Programme"
	DB	0
;
;***
;
;
;   ***SUPERVISOR***
;
;externe Nutzungsmoeglichkeit von EMON-Routinen
;
SBOS:	EX	(SP),HL
	PUSH	AF
	LD	A,(HL)	;Byte nach RST
	LD	(ARB1),A	;holen
	INC	HL	;Rueckkehradr.
	POP	AF
	EX	(SP),HL	;kellern
	PUSH	HL
	PUSH	BC
	PUSH	AF
	LD	HL,SBTAB	;Sprungtabelle
	LD	A,(ARB1)
	SLA	A
	LD	C,A
	LD	B,0
	ADD	HL,BC	;HL=Tab.adr.
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A	;HL=Adr. Routine
	POP	AF
	POP	BC
	EX	(SP),HL	;Ansprung
	RET		;Routine
;
;
;Sprungtabelle fuer Supervisor
SBTAB:	DW	OUTA	;Ausgabe (A) auf CONST
	DW	OUTHX	;Ausgabe (A) hexa
	DW	OUTHL	;Ausgabe (HL) hexa
	DW	OSPAC	;Ausgabe SPACE
	DW	OCRLF	;Ausgabe CR u. LF
	DW	PRNST	;Ausgabe String
	DW	HLKON	;Kovertierung >dez.
	DW	GVAL	;Parameter holen
	DW	EING	;..+Wandlung hex
	DW	CPROM	;Suchen Namen
	DW	MENU	;Ausgabe Menue
	DW	COOUT	;Ausgabe ASCII
	DW	WAIT	;Unterbrechung Lauf
	DW	MEM	;Uebergabe Adr.
;
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
;HLKON Wandlung HEX (HL) --> DEZ (AHL)
;
;HLKON:	PUSH	DE
;	PUSH	BC
;	XOR	A
;	LD	D,A	;Dezimalwert=0
;	LD	B,16	;Bitzaehler
;HLKO1:	ADD	HL,HL	;Bits ins Cy
;	ADC	A, A
;	DAA
;	LD	E,A
;	LD	A,D
;	ADC	A, A
;	DAA
;	LD	D,A
;	RL	C
;	LD	A,E
;	DJNZ	HLKO1
;	EX	DE,HL
;	LD	A,C
;	POP	BC
;	POP	DE
;	RET

;--20.03.2006
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
;                                                   
;***
;
;EING    Uebernahme Parameter aus CONBU nach INTLN
;        analog GVAL, war Parameter Hexzahl, so
;        Konvertierung nach (DE)
;Return: Z=0  keine Zahl
;        Cy=1 Zahl zu gross, Rest siehe GVAL
;
EING:	CALL	GVAL	;Parameter holen
	RET	NZ	;keine Zahl
	PUSH	HL
	PUSH	BC
	LD	DE,INTLN
	CALL	EING3	;Konvertierung
	POP	BC
	POP	HL
	JR	C, EING1	;Fehler
	CP	A, A	;Z=0,Cy=0
	RET
EING1:	CP	A, A
	JP	ERINP
;
EING3:	LD	A,(DE)	;Laenge Parameter
	OR	A
	SCF
	RET	Z	;kein Parameter
	LD	A,4
	CALL	FORMS	;Formatieren String
	RET	C	;zu viele Stellen
	LD	HL,ARA1+1
	LD	B,2
EING2:	CALL	EING4
	RET	C	;keine Hexziffer
	LD	(HL),A
	CALL	EING4
	RET	C	;keine Hexziffer
	RLD
	DEC	HL
	DJNZ	EING2	;4 Stellen
	LD	DE,(ARA1)	;DE=Hexzahl
	RET
;
EING4:	LD	A,(DE)	;A=ASCII
	INC	DE	;naechste Stelle
	CP	A, '0'
	RET	C	;zu klein
	CP	A, 03AH	;'9'+1
	CCF
	RET	NC	;Zahl
	CP	A, 'A'
	RET	C	;kein Buchstabe
	SUB	7	;fuer Konvertierung
	CP	A, 040H	;'F'+1-7
	CCF		;Cy=1 keine Hexzahl
	RET		;A=0...F
;
;***
;
;CPROM Suchen Transientkommando im Speicher
;Parameter: INTLN+1 - Name
;           B  - Laenge Name (1..8)
;           HL - erste Suchadresse
;Return:Z=1 - gefunden, dann HL=Startadresse
;
CPROM:	LD	A,B
	LD	(LAEN),A
	LD	B,0	;Anzahl Bloecke (=100H)
CP1:	PUSH	BC
	PUSH	HL
CP2:	LD	A,0C3H	;Suchen JMP
	CP	A, (HL)
	INC	HL
	JR	NZ, CP22	;naechste Adresse
	INC	HL
	INC	HL
	LD	A,(LAEN)
	LD	B,A
	LD	DE,INTLN+1
	CALL	CHEC	;Vergleich Name
	JR	Z, CPE1	;gefunden
	LD	B,9
CP3:	INC	HL
	DJNZ	CP3
	LD	A,(HL)
	CP	A, 0C3H	;folgt Name?
	JR	Z, CP2
CP22:	POP	HL
	DEC	H	;naechster Block
	POP	BC
	DJNZ	CP1
	INC	H		;Z=0
	RET		;nicht gefunden
CPE1:	POP	BC
	POP	BC
	RET
;
;Zeichenkettenvergleich B Zeichen
CHEC:	PUSH	HL		;Adr. 1. Zeichenkette
	PUSH	DE		;Adr. 2. Zeichenkette
	EX	DE,HL
CHC0:	LD	A,(DE)
	CP	A, (HL)
	INC	DE
	INC	HL
	JR	NZ, CHC1
	DJNZ	CHC0
	POP	DE
	POP	DE		;Adr. 1. Zeichenkette
	LD	L,E
	LD	H,D
	DEC	HL
	LD	A,(HL)
	DEC	HL
	LD	L,(HL)
	LD	H,A	;HL=Startadr.
	RET		;Z=1
CHC1:	POP	DE
	POP	HL		;Z=0
	RET		;nicht gleich
;
;***
;
;MENU Auflisten der Rufnamen der Programme ab (IX) abwaerts
;Parameter:A=0 nur Namen
;          A=1 Name und Listen- und calladresse
;          A=2 Name und HELP-Text
;
MENU:	LD	(ARB1),A
	LD	B,0	;Anzahl Bloecke (=100H)
MENU1:	PUSH	BC
	LD	(ARA1),IX
	LD	A,0C3H
	CP	A, (IX+0)	;JMP-Befehl?
	CALL	Z, MENU2
	LD	IX,(ARA1)
	LD	DE,0FF00H
	ADD	IX,DE	;IX=IX-100H
	POP	BC
	DJNZ	MENU1
	CALL	OCRLF
	RET
;
;Kopftabelle gefunden
MENU2:	XOR	A
	LD	(ARB2),A	;Namenzaehler
MENU3:	XOR	A
	CP	A, (IX+11)	;Stringende
	RET	NZ	;kein Name
	PUSH	IX
	POP	HL
	INC	HL
	INC	HL
	INC	HL
	LD	B,8
	CALL	COOUT	;Ausgabe Name
	CALL	OSPAC
	CALL	OSPAC
	LD	A,(ARB1)
	PUSH	AF
	CP	A, 1
	CALL	Z, MEADR	;Ausgabe Adressen
	POP	AF
	CP	A, 2
	CALL	Z, MEHLP	;Ausg. HELP-Text
	CALL	WAIT
	CALL	OCRLF
	LD	A,(IX+12)
	CP	A, 0C3H	;folgt Name?
	RET	NZ	;nein
	LD	DE,12
	ADD	IX,DE	;Zaehler erhoehen
	LD	HL,ARB2
	INC	(HL)
	JR	MENU3
;
;Ausgabe Adressen
MEADR:	PUSH	IX
	POP	HL
	LD	A,'0'
	CALL	OUTA
	CALL	OUTHL	;Ausg. 1. Adr.
	CALL	OSPAC
	LD	L,(IX+1)
	LD	H,(IX+2)
	LD	A,'0'
	CALL	OUTA
	CALL	OUTHL	;Ausg. 2. Adr.
	RET
;
;Ausgabe HELP-Texte
MEHLP:	LD	DE,12	;suchen Listenende
	LD	HL,(ARA1)
MEHL1:	ADD	HL,DE
	LD	A,(HL)
	CP	A, 0C3H
	JR	Z, MEHL1
	CP	A, 0BBH	;folgen HELP-Texte?
	RET	NZ	;nein
	INC	HL
	LD	A,(ARB2)
	OR	A
	JR	Z, MEHL2	;gleich 1. Text
	LD	B,A
MEHL3:	LD	A,(HL)	;richtigen Text
	OR	A	;suchen
	INC	HL
	JR	NZ, MEHL3
	DJNZ	MEHL3
MEHL2:	LD	D,H
	LD	E,L
	CALL	PRNST	;Ausgabe Text
	RET
;
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
;
;***
;
;WAIT Unterbrechung Programm, wenn <PAUSE> gedrueckt,
;     weiter mit beliebiger Taste
;
WAIT:	LD	C,CSTS	;Abfrage Status
	CALL	CBOS
	OR	A
	RET	Z	;keine Taste gedrueckt
	LD	C,CONSI	;Eingabe
	CALL	CBOS
	CP	A, 013H	;<PAUSE>?
	RET	NZ	;nein
	CALL	CBOS	;Warten auf Tastendruck
	RET
;
;***
;
;MEM Uebergabe der akt. EMON-Adressen
;Return: HL=MRAM, DE=MROM
;
MEM:	LD	HL,MRAM
	LD	DE,MROM
	RET
;
;***
;
;************************************************
;
;                 *** ECCP ***
;
;************************************************
;
;externes CCP, uebernimmmt Ausgabe Menue, Einlesen und Start
;von Programmen
;
ECCP:	CALL	BOS	;Systemueberpruefung
	RET	C	;nicht Version 1.2. o. 1.3.
	LD	HL,NBOS
	LD	A,(CBOS+2)
	CP	A, H	;Monitor init.?
	CALL	NZ, EINIT	;wenn nicht
	CALL	CASIN	;Cassetteninit
	LD	DE,MRAM-0101H
	LD	HL,(EOR)
	OR	A	;Cy=0
	SBC	HL,DE
	JR	C, ECCP1	;EOR schon gesetzt
	LD	(EOR),DE	;sonst vor MRAM stellen
;
ECCP1:	LD	DE,ECTX1
	CALL	PRNST	;Ausg. Kopfzeile
	LD	A,23	;linker Rand=24
	LD	(P3ROL),A
	LD	D,4
	LD	E,24
	LD	C,SETCU
	CALL	CBOS
;Ausgabe asgn
	LD	DE,ECTX2
	CALL	PRNST
	CALL	DISPA
;Ausgabe eor
	LD	DE,ECTX3
	CALL	PRNST
	LD	HL,(EOR)
	CALL	OUTHL
	LD	A,'='
	CALL	OUTA
	ld	de,DEZBUF
	CALL	HLKON
	CALL	PRNST
;Ausgabe time
	LD	DE,ECTX4
	CALL	PRNST	;"time"
	CALL	ZAU
	XOR	A
	LD	(P3ROL),A
	LD	D,4
	LD	E,1
	LD	C,SETCU
	CALL	CBOS
;Ausgabe Menu
	LD	IX,0BF00H	;Menue
	LD	A,1
	CALL	MENU
;
;zentrale Schleife
ECCPM:	LD	HL,ECCPM
	PUSH	HL	;Rueckkehradr.
	LD	HL,CONBU
	LD	(DMA),HL	;Standartpuffer
	LD	A,'>'
	CALL	OUTA
	CALL	GETMS	;Eingabe Zeile
	JP	C, WBOOT	;<STOP> gedrueckt
	CALL	COEXT	;Zeile bearbeiten
	RET	C	;leere Zeile
	LD	HL,ERDIS
	PUSH	HL	;Adr. Fehlerroutine
	CALL	GVAL	;1. Parameter holen
	JP	Z, ERPAR	;kein Name
	LD	A,B
	CP	A, 9
	JP	NC, ERPAR	;Name zu lang
;Behandlung Transientkommando
	PUSH	BC
	LD	HL,0BF00H
	CALL	CPROM	;Name suchen
	POP	BC
	JR	Z, JMPHL	;wenn gefunden
;Programm laden
	CALL	LOAD1
	RET	C	;Ladefehler
	LD	HL,(SADR)
JMPHL:	JP	(HL)	;Start
;
;***
;
;Ueberpruefen Monitorversion
;
BOS:	LD	C,RETVN
	CALL	CBOS	;Version abfragen
	LD	A,1
	CP	A, B	;Version 1.x
	JR	NZ, BOS1
	INC	A
	CP	A, C	;Version 1.2.
	RET	Z
	INC	A
	CP	A, C	;Version 1.3.
	RET	Z
BOS1:	XOR	A
	LD	(MROM),A	;EMON abschalten
	LD	A,7	;'BOS-ERROR'
	SCF
	RET
;
;Initialisieren Arbeitsspeicher
;
EINIT:	LD	A,0C3H	;Eintragen
	LD	(RST8),A	;RST8-Ruf
	LD	(RAM),A
	LD	HL,SBOS
	LD	(RST8+1),HL
	LD	HL,JPVEC	;BOS-Adresstabelle
	LD	DE,MRAM
	LD	BC,68
	LDIR		;in RAM uebertragen
	LD	HL,NBOS	;neues BOS
	LD	(CBOS+1),HL	;eintragen
	LD	HL,ERAM
	LD	(RAM+1),HL		;DISPLAY-Jump
;
	LD	A,0FFH
	LD	(CMODE),A
	LD	HL,500H
	LD	(AREA),HL
;--20.03.2006
	xor	a
	ld	(DEZBUF+5),a	
	RET
;
;neues BOS
;
NBOS:	LD	(SPSV),SP	;Stack sichern
	LD	SP,1C0H	;BOS-Stack
	OR	A
	PUSH	HL
	PUSH	DE
	PUSH	AF
	LD	(BCSV),BC
	LD	(ASV),A
	LD	HL,BOSE
	PUSH	HL	;Rueckkehradr. kellern
	LD	A,33
	CP	A, C
	JP	C, BOSER
	LD	B,0
	LD	HL,MRAM	;JPVEC neu
	ADD	HL,BC
	ADD	HL,BC
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A
	LD	C,E	;Eingangsparameter
	LD	B,D	;uebernehmen
	LD	A,(ASV)
	PUSH	HL	;Rufadresse kellern
	LD	L,3	;fuer Cursorrufe
	RET		;Sprung zur Ausfuehrung
;
;***
;
;ECCP-Texte
;
ECTX1:	DB	CLS
	DW	ROT
	DB	"extended monitor Z9001 "
	DB	"by VP-SOFT 1989"
	DW	GRUEN
	DW	CRLF
	DB	LF
	DB	0
;
ECTX2:	DW	GELB
	DB	"asgn"
	DW	GRUEN
	DW	CRLF
	DB	0
;
ECTX3:	DW	CRLF
	DB	LF
	DW	GELB
	DB	"eor"
	DW	GRUEN
	DW	CRLF
	DB	LF
	DB	"0"
	DB	0
;
ECTX4:	DW	CRLF
	DB	LF
	DB	LF
	DW	GELB
	DB	"time"
	DW	GRUEN
	DW	CRLF
	DB	LF
	DB	0
;
;***
;
;   *** HELP ***
;
;Auflisten der Rufnamen der ueber ECCP erreichbaren Programme
;sowie deren HELP-Texte
;
HELP:	LD	IX,0BF00H	;erste Suchadresse
	CALL	OCRLF
	LD	A,2	;Ausg. Texte
	CALL	MENU
	XOR	A	;Cy=0,A=0
	RET		;zum ECCP
;
;***
;
;
;************************************************
;
;   CASSETTE:Kassettenarbeits-dienstprogramm
;
;************************************************
;
	ORG	MROM+0440H
;
;***
;
;   ***KOPFLISTE***
;
MCASS:	JP	CHELP
	DB	"HELP    "
	DB	0
	JP	LOAD
	DB	"LOAD    "
	DB	0
	JP	SAVE
	DB	"SAVE    "
	DB	0
	JP	VERIF
	DB	"VERIFY  "
	DB	0
	JP	CLIST
	DB	"CLIST   "
	DB	0
	JP	FREAD
	DB	"READ    "
	DB	0
	JP	WRITE
	DB	"WRITE   "
	DB	0
	JP	MODUS
	DB	"MODUS   "
	DB	0
	JP	JUMP
	DB	"JUMP    "
	DB	0
	JP	SEOR
	DB	"EOR     "
	DB	0
	JP	CURS
	DB	"CURSOR  "
	DB	0
	DB	0BBH
	DB	"Kurzerlaeuterungen/Parameter"
	DB	0
	DB	"(ladr)"
	DB	0
	DB	"name(.typ) aadr,eadr(,sadr)"
	DB	0
	DB	"Aufzeichnung pruefen"
	DB	0
	DB	"(P)    Kassettenverzeichnis"
	DB	0
	DB	"(area) Kopierroutine"
	DB	0
	DB	"(blocktime(,FF-time))"
	DB	0
	DB	"(nr)   System anpassen"
	DB	0
	DB	"(adr)  Sprung zu sadr/adr"
	DB	0
	DB	"adr    EOR setzen"
	DB	0
	DB	"Cursor setzen/loeschen"
	DB	0
;
;***
;
;   ***ZENTRALPROGRAMM***
;
CASS:	EX	AF, AF'
	JR	NC, CASS1	;Parameter folgen
;
	LD	DE,CATX1
	CALL	PRNST	;Ausg. Titelzeile
	LD	IX,0BF40H	;erste Adresse
	LD	A,1	;Adressausgabe
	CALL	MENU
;
CASS2:	LD	HL,CONBU
	LD	(DMA),HL
	LD	A,'*'	;neues Prompt
	CALL	OUTA
	CALL	GETMS
	JP	C, WBOOT
	CALL	COEXT
	LD	A,0
	RET	C	;keine Eingabe -> ECCP
;Einlesen+Ausfuehren Ruf
CASS1:	CALL	GVAL
	JP	Z, ERPAR	;kein Name
	PUSH	BC
	LD	HL,0BF40H
	CALL	CPROM	;Name suchen
	POP	BC
	LD	A,0
	RET	NZ	;nicht gefunden -> ECCP
	JP	(HL)	;Ausfuehren Ruf
;
; Initialisierung
;
CASIN:	LD	A,(CMODE)
	OR	A
	JR	Z, CASI1
	CP	A, 3
	JR	C, CASI1	;schon init.
	XOR	A	;sonst Modus 0
CASI1:	EX	AF, AF'
	JP	MOD0	;initialisieren.
;
;
CATX1:	DB	CLS
	DW	ROT
	DB	"cassette monitor Z9001"
	DB	" by VP-SOFT 1989"
	DW	GRUEN
	DW	CRLF
	DB	LF
	DB	LF
	DB	0
;
;***
;
;************************************************
;
;     Unterprogramme zur Kassettenarbeit
;
;************************************************
;
;
; Blocklesen sequentiell
;
READ:	CALL	RRAND	;Block lesen
	RET	C	;Lesefehler
	LD	(DMA),HL	;Pufferadr. um 80H erhoehen
	PUSH	AF
	LD	HL,LBLNR
	INC	(HL)
	LD	A,(BLNR)
	CALL	OBLNR	;BLNR anzeigen
	POP	AF
	RET
;
;Blocklesen
;
RRAND:	LD	HL,(EOR)	;end of RAM
	LD	DE,7FH
	SBC	HL,DE
	LD	DE,(DMA)	;Pufferadr.
	CALL	COMPW	;Vergleich
	LD	A,10
	RET	C	;"memory end!"
	EX	DE,HL
	CALL	CHRAM	;log. RAM-Test
	LD	A,9
	JR	NC, ERAND
RR1:	PUSH	AF
RR2:	POP	AF
	CALL	MARAM	;Eingabe Block
	CALL	INITA	;Tastatur init.
	PUSH	AF
	PUSH	HL
	LD	HL,LBLNR	;zu lesende BLNR
	LD	A,(BLNR)	;gelesene BLNR
	CP	A, (HL)
	POP	HL
	JR	C, RR2	;noch nicht erreicht
	JR	Z, RROK	;gefunden
	CP	A, 0FFH
	JR	Z, RROK	;Endeblock
	POP	AF
	LD	A,11
ERAND:	SCF
	RET
RROK:	POP	AF
	LD	A,12
	RET	C	;Lesefehler
	LD	A,(BLNR)	;Rueckgabe EOF
	INC	A
	LD	A,0
	JR	NZ, RROK1
	INC	A
RROK1:	LD	(ASV),A	;1-wenn Endeblock
	RET		;0-sonst
;
;Ausgabe <A> hexa, Cursor zurueck
;
OBLNR:	PUSH	AF
	CALL	OUTHX
	LD	A,CUL
	CALL	OUTA
	LD	A,CUL
	CALL	OUTA
	PUSH	BC
	PUSH	DE
	PUSH	HL
	LD	L,3	;noetig
	CALL	DCU	;Cusor loeschen
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
;
; Lesen eines Blocks
;
; Routine aus BASIC-Programm HELP87
;
MAREK:	DI
	CALL	INIC1	;FB0A
	OUT	93H, A	;Tastatur aus
	OUT	8AH, A
	LD	A,5
	OUT	80H, A	;CTC0 zum Zeitmessen
	LD	A,0B0H	;Startwert
	OUT	80H, A
	LD	A,0FH
	OUT	8AH, A
	LD	A,0AH
	OUT	8AH, A
	LD	A,0E7H	;Interrupt PIO
	OUT	8AH, A	;erlaubt
	EI
MA1:	LD	B,32H	;50 Vortoene suchen
MA2:	CALL	FLANK
	JR	NC, MA1	;0-Bit gelesen
	CP	A, 48H
	JR	C, MA1	;Trennzeichen gelesen
	DJNZ	MA2
	LD	C,A
MA3:	CALL	FLANK
	LD	B,A
	SUB	C
	LD	C,B
	JR	NC, MA3
	CALL	FLANK
	CP	A, 40H
	JR	NC, MA3
	CALL	IBYTE	;Blocknummer lesen
	RET	C	;Fehler
	LD	(BLNR),A	;Blocknummer
	LD	E,0	;E=Pruefsumme
	LD	B,80H	;Anzahl Bytes
	LD	HL,(DMA)
MA4:	CALL	IBYTE	;Byte lesen
	RET	C	;Fehler
	LD	(HL),A
	INC	HL
	ADD	A, E
	LD	E,A	;neue Pruefsumme
	DJNZ	MA4
	CALL	IBYTE	;Pruefsumme lesen
	RET	C	;Fehler
	CP	A, E
	RET	Z	;in Ordnung
	SCF
	RET		;Fehler
;
;Lesen einer Flanke
;
FLANK:	XOR	A
	LD	(ARB),A
FL1:	LD	A,(ARB)
	OR	A
	JR	Z, FL1
	CP	A, 80H	;Cy=0 0-Bit
	RET		;Cy=1 1-Bit
;
;Lesen ein Byte
;
IBYTE:	PUSH	DE
	LD	D,8
	XOR	A
	LD	E,A
IB1:	CALL	FLANK
	CALL	FLANK
	JR	NC, IB2	;0-Bit
	CP	A, 48H
	JR	C, IB3	;Trennzeichen
	SCF		;1-Bit
IB2:	RR	E
	DEC	D
	JR	NZ, IB1
	CALL	FLANK	;Lesen Trennzeichen
	CALL	FLANK
	CP	A, 48H
	CCF
	LD	A,E
IB3:	POP	DE
	RET
;
;***
;
;   ***CHELP***
;
;Auflisten der CASSETTE-Routinenerklaerungen
;
CHELP:	LD	IX,0BF40H	;erste Adr.
	CALL	OCRLF
	LD	A,2
	CALL	MENU
	JP	CASS2	;Eingabe in CASS
;
;***
;
;   ***LOAD***
;
;Einlesen eines Programmes
;
LOAD:	LD	DE,0
	EX	AF, AF'
	JR	C, LOA1	;kein Parameter
	LD	HL,ERPAR
	PUSH	HL
	CALL	EING
	RET	NZ	;keine Zahl
	RET	C	;Zahl zu gross
	EX	AF, AF'
	RET	NC	;wenn weitere Parameter
	POP	HL
;
LOA1:	LD	(ARA1),DE
LOA2:	LD	HL,CONBU	;Puffer=FCB
	LD	(DMA),HL
	CALL	REQU	;Startmeldung
	INC	A
	RET	C	;STOP gegeben
	XOR	A
	LD	(LBLNR),A	;Block 0
	CALL	READ	;Block lesen
	JR	NC, LOA3	;kein Fehler
	CALL	REA	;Ausgabe Fehlermeldung
	RET	C	;STOP gegeben
	JR	LOA2	;Wiederholung
LOA3:	LD	HL,CONBU
	LD	DE,FNAME
	LD	BC,13
	LDIR
	LD	HL,CONBU+17
	LD	DE,AADR
	LD	BC,7
	LDIR
	CALL	DFCB
	LD	HL,(ARA1)
	LD	A,H
	OR	L
	JR	NZ, LOA4	;neue AADR
	LD	HL,(AADR)	;sonst alte
LOA4:	LD	(DMA),HL
LOA5:	CALL	READ	;Blocklesen
	JR	NC, LOA6	;kein Fehler
	CALL	REA	;Fehlermeldung
	RET	C	;STOP gegeben
	XOR	A
LOA6:	OR	A
	JR	Z, LOA5	;weiter lesen
	CALL	OCRLF	;bis Dateiende
	XOR	A
	RET
;
;***
;
;   ***SAVE***
;
;Abspeichern von Programmen
;SAVE (name(.typ) aadr eadr( sadr))
;
;Aufbereiten FCB
;
SAVE:	EX	AF, AF'
	JR	C, SA5	;keine Folgeparameter
	LD	HL,ERPAR
	PUSH	HL
;lesen name
	CALL	EING	;Parameter holen
	RET	Z	;Zahl
	EX	AF, AF'
	RET	C	;keine Folgeparameter
	LD	A,(INTLN)
	OR	A
	RET	Z	;Laenge 0
	CP	A, 9
	RET	NC	;zu lang
	LD	DE,FNAME
	LD	A,8
	CALL	MOV
;lesen typ
	LD	A,C	;Trennzeichen
	CP	A, '.'
	JR	Z, SA1	;Typ folgt
	LD	HL,FTYP
	LD	(HL),'C'
	INC	HL
	LD	(HL),'O'
	INC	HL
	LD	(HL),'M'
	JR	SA2
SA1:	CALL	EING
	RET	Z	;Zahl
	EX	AF, AF'
	RET	C
	LD	A,3
	CP	A, B	;Laenge=3?
	RET	NZ
	LD	DE,FTYP
	CALL	MOV	;Typ eintragen
;lesen Anfangsadresse
SA2:	CALL	EING
	RET	NZ	;keine Zahl
	RET	C	;zu gross
	EX	AF, AF'
	RET	C
	LD	(AADR),DE
;lesen Endadresse
	CALL	EING
	RET	NZ
	RET	C
	LD	(EADR),DE
	EX	AF, AF'
	JR	NC, SA3	;sadr folgt
;lesen Startadresse
	LD	DE,(AADR)
	JR	SA4
SA3:	CALL	EING
	RET	NZ
	RET	C
	EX	AF, AF'
	RET	NC	;es folgt Parameter
SA4:	LD	(SADR),DE
	POP	HL	;Fehlercall
	JR	SA6
SA5:	CALL	DFCB
SA6:	LD	HL,(EADR)
	LD	DE,(AADR)
	OR	A	;Cy=0
	SBC	HL,DE
	JP	C, ERINP	;aadr>eadr
;
; 19.03.2006 ROM-Schutz aushebeln
	LD	hl, (EOR)	;1. EOR auf 0FFFFh setzen
	PUSH	hl
	LD	hl, 0ffffh
	LD	(EOR), hl
	LD	hl,MAPPI+1
	LD	A,0FFH		;2. den ganzen Speicher als RAM deklarieren
	LD	B,8
sarom:	LD	(hl), A
	inc	hl
	DJNZ	sarom
;
;Abspeichern File
;
	LD	DE,(AADR)
	XOR	A
	LD	(MAPPI),A	;3. kein Schutzbyte
	LD	(SBY),A
	LD	HL,SARET
	PUSH	HL	;Returnadresse
	LD	C,OPENW	;File eroeffnen
	CALL	CBOS
	RET	C	;Fehler
	CALL	OBLNR	;Ausgabe Blocknr.
	EX	DE,HL
	LD	(DMA),HL
SAV1:	LD	HL,(DMA)
	LD	DE,7FH
	ADD	HL,DE
	LD	DE,(EADR)
	SBC	HL,DE
	JR	NC, SAV2	;letzter Block
	LD	C,WRITS
	CALL	CBOS
	RET	C	;Fehler
	CALL	OBLNR
	JR	SAV1
SAV2:	LD	C,CLOSW
	CALL	CBOS
	RET	C
	CALL	OBLNR
;
	CALL	OCRLF
	pop	hl	;20.03.2006 SARET vom Stack nehmen
SARET:	XOR	A
	LD	(KEYBU),A
; 19.03.2006 ROM-Schutz: eor zurücksetzen
	POP	hl
	LD	(eor), hl
	RET
;
;***
;
; Anzeige der FCB-Struktur
;
DFCB:	LD	HL,FNAME
	LD	B,8
DFCB1:	LD	A,(HL)	;Anzeige Name
	CP	A, ' '
	JR	Z, DFCB2	;Namensende
	CALL	OUTA
	INC	HL
	DJNZ	DFCB1	;max. 8 Zeichen
DFCB2:	LD	HL,FTYP
	LD	A,'.'
	CALL	OUTA
	LD	B,3
	CALL	COOUT	;Anzeige Typ
	CALL	OSPAC
	LD	HL,(AADR)
	CALL	FCB1	;aadr
	LD	A,','
	CALL	OUTA
	LD	HL,(EADR)
	CALL	FCB1	;eadr
	LD	A,','
	CALL	OUTA
	LD	HL,(SADR)
	CALL	FCB1	;sadr
	CALL	OCRLF
	RET
;
FCB1:	LD	A,'0'	;Anzeige Adresse
	CALL	OUTA
	CALL	OUTHL
	RET
;
;***
;
;   ***VERIFY***
;
;Ueberpruefen der Aufzeichnung
;
VERIF:	EX	AF, AF'
	JP	NC, ERINP	;zu viele Parameter
	CALL	REQU	;Startmeldung
	INC	A
	RET	C	;STOP gegeben
	LD	HL,0EC00H	;Anzeige
	LD	(DMA),HL	;auf Bildschirm
VERI1:	CALL	MARAM	;Block lesen
	PUSH	AF
	CALL	INITA	;Tastatur init.
	POP	AF
	LD	A,12	;Lesefehler
	CALL	ERDIS	;Ausg. Fehlermeldung
	CALL	DECO0	;Tastaturabfrage
	EI
	OR	A
	JR	Z, VERI2
	CP	A, 3	;>STOP< ?
	JR	Z, VERI3	;ja
VERI2:	LD	A,(BLNR)	;gelesene BLNR
	INC	A
	JR	NZ, VERI1	;kein Ende
VERI3:	XOR	A
	RET
;
;***
;
;   ***MODUS***
;
;Einstellen Systemmodus
;  0 - Systemroutinen
;  1 - Turbo-system
;  2 - MAREK/System-SAVE
;
MODUS:	EX	AF, AF'
	JR	NC, MOD3	;Parameter folgt
	XOR	A
	EX	AF, AF'
	JR	MOD0	;sonst Modus 0
MOD3:	CALL	GVAL	;Parameter holen
	LD	HL,ERPAR
	PUSH	HL	;Fehlerroutine
	RET	C	;Fehler
	RET	NZ	;keine Zahl
	CP	A, 3
	RET	NC	;wenn A>2
	EX	AF, AF'
	RET	NC	;weitere Parameter
	POP	HL
MOD0:	LD	A,0C3H	;JMP ...
	LD	(MARAM),A
	LD	HL,MAREO	;MAREK vom System
	LD	(MARAM+1),HL
	LD	HL,READ	;Eintraege in BOS-
	LD	(MRAM+40),HL	;Adresstabelle
	LD	HL,RRAND
	LD	(MRAM+66),HL
	LD	HL,IKACT	;Standart-Interrupt
	LD	(RKACT),HL
	LD	HL,IKEP
	LD	(RKEP),HL
	EX	AF, AF'
	LD	(CMODE),A	;A=Parameter
	OR	A	;=0 ?
	JR	Z, MODE
MOD1:	CP	A, 1
	JR	NZ, MOD2
	LD	HL,TKACT	;Turboroutinen
	LD	(RKACT),HL
	LD	HL,TKEP
	LD	(RKEP),HL
	JR	MODE
MOD2:	LD	HL,MAREK	;neue Leseroutine
	LD	(MARAM+1),HL
MODE:	XOR	A
	RET
;
;Routinen von L.Boltze, Halle-Neustadt, 1987
; ( doppelte Geschwindigkeit )
;
;Turboload-interruptroutine
;
TKEP:	PUSH	AF
	IN	A, 80H
	CP	A, 78H
	JR	NC, TKEP1	;weiter testen
	LD	A,30H	;Trennzeichen
	JR	TKEP2
TKEP1:	CP	A, 98H
	JR	NC, TKEP3
	LD	A,70H	;1-BIT
	JR	TKEP2
TKEP3:	LD	A,90H	;0-BIT
TKEP2:	PUSH	AF
	LD	A,7
	OUT	80H, A
	LD	A,0B0H
	OUT	80H, A
	POP	AF
	LD	(ARB),A
	POP	AF
	EI
	RETI
;
;Turbosave-interruptroutine
;
TKACT:	PUSH	AF
	LD	A,3
	OUT	80H, A
	LD	A,85H
	OUT	80H, A
	LD	A,(ARB)
	CP	A, 40H
	JR	Z, TKAC1
	JR	C, TKAC2
	LD	A,40H	;Trennzeichen (turbo)
	JR	TKAC3
TKAC1:	LD	A,20H	;1-BIT (turbo)
	JR	TKAC3
TKAC2:	LD	A,10H	;0-BIT (turbo)
TKAC3:	OUT	80H, A
	XOR	A
	LD	(ARB),A
	POP	AF
	EI
	RETI
;
;***
;
;   ***JUMP***
;
;Sprung zu adr/Startadresse
;
JUMP:	EX	AF, AF'
	JR	C, JUM2	;kein Parameter
	CALL	EING	;Parameter holen
	JP	NZ, ERPAR	;keine Zahl
	JP	C, ERPAR	;Zahl zu gross
	JR	JUM1
JUM2:	LD	DE,(SADR)	;Startadresse
JUM1:	PUSH	DE
	RET		;Ansprung
;
;***
;
;   ***EOR***
;
;Setzen EOR auf adr
;
SEOR:	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	EING	;Parameter holen
	JP	NZ, SEOER	;keine Zahl
	JP	C, SEOER	;Zahl zu gross
	LD	(EOR),DE
	XOR	A
SEOR1:	POP	BC
	POP	DE
	POP	HL
	RET
SEOER:	LD	A,2	;Parameterfehler
	SCF
	JR	SEOR1
;
;***
;
;   ***CURSOR***
;
CURS:	LD	A,(65536-4152)	;Cursor setzen
	XOR	00100000B	;/loeschen
	LD	(65536-4152),A
	XOR	A
	RET
;
;***
;
;   ***CLIST***
;
;Kassetteninhalt listen
;       fuer MC, BASIC, MC vom KC85/2..4
;
CLIST:	EX	AF, AF'
	LD	A,0
	LD	(ARB1),A
	JR	C, CLIS1	;kein Parameter
	CALL	GVAL
	JP	Z, ERPAR	;wenn Zahl
	EX	AF, AF'
	JP	NC, ERPAR	;wenn weitere Parameter
	DEC	B
	JP	NZ, ERPAR	;Wort zu lang
	LD	A,(INTLN+1)
	CP	A, 'P'
	JP	NZ, ERPAR	;falscher Buchstabe
	LD	(ARB1),A
;Abfage Kassettenname und Seite
	LD	DE,CLTX7
	CALL	PRNST
	LD	HL,CONBU
	LD	(DMA),HL	;Standartpuffer
	CALL	GETMS	;Zeile einlesen
	RET	C	;wenn <STOP>
	CALL	COEXT	;Zeile vorverarbeiten
	JR	C, CLIS5	;wenn Zeile leer
	LD	HL,CLTX7
	LD	B,8
	CALL	CPROT	;Ausg. 'Kassette '
	CALL	GVAL	;Parameter holen
	EX	AF, AF'
	PUSH	AF
	LD	HL,INTLN+1
	CALL	CPROT	;Ausg. Name
	POP	AF
	JR	C, CLIS5	;keine Seite
	LD	HL,CLTX8
	LD	B,5
	CALL	CPROT	;Ausg. 'Seite '
	CALL	GVAL
	LD	HL,INTLN+1
	CALL	CPROT	;Ausg. Seite
;
CLIS5:	LD	A,1
	LD	(LISW),A	;Drucker an
	CALL	OCRLF
;Block lesen
CLIS1:	CALL	OCRLF
CLIS3:	XOR	A	;A=0
	LD	(ARB2),A	;Flag ruecksetzen
	LD	HL,CONBU
	LD	(DMA),HL
	CALL	MARAM
	CALL	INITA
	CALL	DECO0	;Tastaturabfrage
	EI
	OR	A
	JR	Z, CLIS2	;keine Taste
	CP	A, CR	;Ende?
	JR	NZ, CLIS2
	CALL	OCRLF
	XOR	A
	LD	(LISW),A	;Druck aus
	LD	(KEYBU),A
	RET
;
CLIS2:	LD	A,(BLNR)
	OR	A
	JP	Z, CLMC	;Maschinencodepgm.
	CP	A, 1
	JR	NZ, CLIS3	;weiterlesen
;
;Ermitteln BASIC-Typ
;
CLIS4:	LD	HL,CONBU
	LD	A,(HL)
	CP	A, 0DAH
	JP	NC, CLMC
	CP	A, 0D3H
	JP	C, CLMC	;evtl MC-Pgm ?
	INC	HL	;3x dasselbe Zeichen ?
	CP	A, (HL)
	JP	NZ, CLMC
	INC	HL
	CP	A, (HL)
	JP	NZ, CLMC
;
	SUB	0D3H
	PUSH	AF
;
	LD	A,(ARB1)
	OR	A
	JR	Z, CLIS6
	LD	DE,CLTX1	;Platz fuer
	CALL	PRNST	;Zaehlerstand
;
CLIS6:	LD	HL,CONBU+3
	LD	B,8
	CALL	COOUT	;Ausgabe Name
	LD	DE,CLTX2	;Ausgabe "BASIC"
	CALL	PRNST
	POP	AF
	BIT	2,A
	PUSH	AF
	JR	Z, CL2
	LD	A,'G'	;geschuetzte Datei
	JR	CL3
CL2:	LD	A,' '
CL3:	CALL	OUTA	;Anzeige Schutz
	POP	AF
	AND	A, 011B
	OR	A
	JR	Z, BAPRO
	CP	A, 1
	JR	Z, BADAT
;
	LD	DE,CLTX3	;BASIC-ASCII-Dateien
	CALL	PRNST
	JR	BAEND
BADAT:	LD	DE,CLTX4	;BASIC-Felder
	JR	BAPR1
BAPRO:	LD	DE,CLTX5	;BASIC-Programme
BAPR1:	CALL	PRNST
	LD	HL,(CONBU+11)	;Laenge des Pgm.
	ld	de,DEZBUF
	CALL	HLKON
	CALL	PRNST
BAEND:	CALL	OCRLF
	JP	CLIS3
;
CLTX1:	DB	"...... "
	DB	0
CLTX2:	DB	" BASIC "
	DB	0
CLTX3:	DB	" ASCII"
	DB	0
CLTX4:	DB	" FELD     "
	DB	0
CLTX5:	DB	" PROGR.   "
	DB	0
CLTX6:	DB	" MC"
	DB	0
CLTX7:	DB	"Kassette"
	DB	", "
CLTX8:	DB	"Seite: "
	DB	0
;
;MC-Files
CLMC:	LD	A,(ARB2)
	OR	A 	;schon mal durchlaufen?
	JP	NZ, CLIS3	;ja --> zurueck
;
	LD	A,(ARB1)
	OR	A	;A=0 ?
	JR	Z, CLMC3	;ja
	LD	DE,CLTX1
	CALL	PRNST	;sonst Punkte drucken
CLMC3:	LD	HL,CONBU+0
	LD	B,8
	CALL	COOUT	;Anzeige Name
	LD	DE,CLTX6	;Anzeige MC
	CALL	PRNST
	LD	HL,CONBU+8
	LD	B,3
	CALL	COOUT	;Anzeige Dateityp
	CALL	OSPAC
	LD	A,(CONBU+23)	;Schutzbyte
	OR	A
	JR	Z, CLMC1
	LD	A,'G'	;geschuetzt
	JR	CLMC2
CLMC1:	LD	A,' '
CLMC2:	CALL	OUTA	;ausgeben
	LD	HL,(CONBU+17)	;AADR
	CALL	CLMOT	;ausgeben
	LD	HL,(CONBU+19)	;EADR
	CALL	CLMOT
	LD	HL,(CONBU+21)	;SADR
	CALL	CLMOT
	CALL	OCRLF
	LD	A,0FFH
	LD	(ARB2),A
	CALL	MARAM	;noch ein Block lesen
	JP	CLIS4	;wegen KC-Unterschieden
;
CLMOT:	CALL	OSPAC
	CALL	OUTHL
	RET
;
CPROT:	LD	C,LISTO	;auf Drucker
CPRO1:	LD	E,(HL)	;ab HL B Zeichen
	CALL	CBOS
	INC	HL
	DJNZ	CPRO1
	LD	E,' '
	CALL	CBOS
	RET
;
;***
;
;universelles Kopieren
;
;   ***FREAD***
;
;Lesen von Bloecken bis >RESET<, Parameter: AREA
;
FREAD:	EX	AF, AF'
	JR	C, FREA2	;kein Parameter
	CALL	EING	;Parameter holen
	JP	NZ, ERPAR	;keine Zahl
	JP	C, ERPAR	;Zahl zu gross
	LD	(AREA),DE
;
FREA2:	CALL	REQU	;Startmeldung
	INC	A
	RET	C	;wenn <STOP>
	LD	HL,(AREA)
	LD	(DMA),HL
	XOR	A
	LD	(BLAN),A
	CALL	FRAD2
	JP	C, ERDIS	;RAM geschuetzt
	LD	B,11
	LD	HL,(AREA)
	CALL	COOUT	;Anzeige Titel
	CALL	OCRLF
	JR	FREA3
;
FREA1:	CALL	FRAD2
	JP	C, ERDIS	;RAM geschuetzt
FREA3:	LD	HL,BLAN
	INC	(HL)	;Blockanzahl erhoehen
	JR	FREA1
;
FRAD2:	CALL	FRAND
	RET	C
	LD	(DMA),HL
	CALL	OBLNR	;Ausg. Blocknummer
	RET
;
FRAND:	LD	HL,(EOR)
	LD	DE,7FH
	SBC	HL,DE
	LD	DE,(DMA)
	CALL	COMPW
	LD	A,10	;RAM-Ende
	RET	C
	EX	DE,HL
	CALL	CHRAM	;log. Test
	LD	A,11
	CCF
	RET	C	;wenn ROM
;
	LD	A,9
	CALL	MARAM
	CALL	INITA
	CALL	C, ERR
	LD	A,(BLNR)
	LD	(HL),A	;BLNR ablegen
	INC	HL
	RET
;
ERR:	LD	A,12
	CALL	ERDIS
	LD	A,(BLNR)
	LD	(LBLNR),A
	LD	C,33	;Block lesen
ERR1:	CALL	CBOS
	JR	C, ERR1	;wenn Lesefehler
	CP	A, 1	;FF-Block?
	JR	NZ, ERR2
	LD	A,(LBLNR)	;sollte FF-Block
	CP	A, 0FFH	;gelesen werden?
	JR	Z, ERR1
ERR2:	LD	HL,(DMA)
	LD	DE,80H
	ADD	HL,DE	;DMA erhoehen
	RET
;
;***
;
;   ***WRITE***
;
;Ausgeben des Speichers ab AREA auf Kassette
;WRITE (block-time(,FF-block-time))
;
WRITE:	LD	HL,ERPAR
	PUSH	HL
	EX	AF, AF'
	JR	C, WRIT1
	CALL	EING	;Parameter holen
	RET	C	;Fehler
	RET	NZ	;keine Zahl
	LD	(ARA1),DE	;Synch-ton-Laenge
	EX	AF, AF'
	JR	C, WRIT2	;kein Parameter weiter
	CALL	EING
	RET	C	;Fehler
	RET	NZ	;keine Zahl
	EX	AF, AF'
	RET	NC	;noch Parameter
	LD	(ARA2),DE	;FF-Synch-ton-Laenge
	JR	WRIT
WRIT1:	LD	HL,0A0H
	LD	(ARA1),HL
WRIT2:	LD	HL,140H
	LD	(ARA2),HL
WRIT:	POP	HL	;RET-Adr. zurueck
;
	CALL	OCRLF
	LD	B,11
	LD	HL,(AREA)
	CALL	COOUT	;Ausgabe der ersten
	CALL	OCRLF	;11 Zeichen (Name)
;
	CALL	REQU	;Ausgabe Startmeldung
	INC	A
	RET	C	;wenn <STOP>
	LD	HL,(AREA)
	LD	(DMA),HL	;erste Adresse
	LD	A,(BLAN)
	LD	B,A	;Blockanzahl
WRI3:	PUSH	BC
	LD	DE,(DMA)
	LD	HL,80H
	ADD	HL,DE
	LD	A,(HL)	;BLNR des Blocks
	LD	(BLNR),A
	LD	A,(BLAN)
	CP	A, B	;erster Block ?
	JR	Z, WRI4
	DEC	DE
	LD	A,(DE)	;BLNR des vorigen Blocks
	CP	A, 0FFH	;FF-Block ?
	JR	Z, WRI1
	LD	BC,(ARA1)	;Synch-Ton-Laenge
	JR	WRI2
WRI4:	LD	BC,1770H	;langer Vorton1
	JR	WRI2
WRI1:	LD	BC,(ARA2)	;FF-Synch-Laenge
WRI2:	CALL	KARAM	;Blockschreiben
	CALL	INITA
	LD	HL,(DMA)
	LD	DE,81H
	ADD	HL,DE
	LD	(DMA),HL	;DMA erhoehen
	LD	A,(BLNR)
	CALL	OBLNR	;Ausg. BLNR
	POP	BC
	DJNZ	WRI3	;naechsten Block
	CALL	OCRLF
	CALL	OCRLF
	XOR	A
	RET
;
;***
;
ERAM:	EX	AF, AF'
	JP	C, ERPAR	;kein Parameter
	CALL	EING	;Parameter holen
	JP	NZ, ERPAR	;keine Zahl
	JP	C, ERPAR	;Zahl zu gross
	EX	AF, AF'
	JR	NC, RAM2	;Parameter folgt
;
	LD	H,D
	LD	L,E
	LD	C,8	;Zeilenanzahl
RAM1:	LD	B,8
	PUSH	HL
	CALL	OUTHL	;Anzeige Adresse
	CALL	OSPAC
	CALL	OSPAC
RAM3:	LD	A,(HL)
	CALL	OUTHX	;Ausgabe Byte
	CALL	OSPAC
	INC	HL
	DJNZ	RAM3
	CALL	OSPAC
	POP	HL
	LD	B,8
	CALL	COOUT	;Ausgabe ASCII
	CALL	OCRLF	;neue Zeile
	DEC	C
	JR	NZ, RAM1
	XOR	A
	RET
;
RAM2:	LD	(ARA2),DE
	CALL	EING	;Parameter holen
	JP	NZ, ERPAR	;keine Zahl
	JP	C, ERPAR	;Zahl zu gross
	EX	AF, AF'
	JP	NC, ERPAR	;Parameter folgt
;
	LD	HL,(ARA2)
	LD	(HL),E
	XOR	A
	RET
;
;***
;
	DB	"Volker Pohlers, Lomonossow"
	DB	"allee 41/81, Greifswald, 2200"
;
PEND:	EQU	$
	END
