;Das Teilprogramm "Anzeigen der Systemuhr" (RTC) wird in den freien Farbspeicher 
;geladen und funktioniert ohne Farbkarte nicht!
;NEU:
;Abspeichern bei Aufruf in TIME-Zellen, sinnvoll nur mit RTC-Uhr
;Prüfen auf Farbkarte --> nein=raus, ja=Ausgabe 

	cpu	z80

	;PN	RTCDAT	;Stellen und Anzeigen der Systemuhr
	ORG	0BD00H	

DIFF:	EQU	RTCEX-START	;wird in den Farbspeicher geladen
ZIEL:	EQU	0EBC0H	;die Zieladresse im Farbspeicher
SEC:	EQU	001FH	;Sekundenzelle der Systemuhr

	JP	RTC	;Anzeigen der Systemuhr
	DB	"RTC     "	
	DB	0	
	JP	RTCIN	;Stellen der Systemuhr
	DB	"RTCIN   "	
	DB	0	
	JP	RTCEX	;Ausschalten der Uhranzeige
	DB	"RTCEX   "	
	DB	0	
	JP	DATIN	;Setzen des Datums
	DB	"DATIN   "	
	DB	0	
	JP	DAT	;Anzeige des Datums (einmalig)
	DB	"DAT     "	
	DW	00	

RTCIN:	LD	C,9	;Systemruf PRNST
	LD	DE,T1	
	CALL	5	;Ausgabe des Uhrzeitformates
E1:	LD	C,1	;Systemruf Eingabe (Stundenzehner H10)
	CALL	5	;Abfrage der ersten Eingabe
	CP	A, 03H	
	JP	Z, ENDE	;STOP gedrückt
	CP	A, 30H	
	JR	C, E1	;H10 < 0?
	CP	A, 33H	
	JR	NC, E1	;H10 > 2?
	LD	C,2	;Ausgabe (H10)
	LD	E,A	
	LD	H,A	;Retten von H10 nach H
	CALL	5	;Ausgabe von H10
E2:	LD	C,1	;Systemruf Eingabe (Stundeneiner H1)
	CALL	5	
	CP	A, 03H	
	JP	Z, ENDE	;STOP gedrückt
	CP	A, 30H	
	JR	C, E2	;H1 < 0?
	PUSH	AF	
	LD	A,E	;H10
	CP	A, 32H	;H10 > 2?
	JR	NZ, E21	;H10 ist 0 oder 1
	POP	AF	
	CP	A, 34H	;da H10 = 2 , muß H1 < oder = 4 sein
	JR	NC, E2	;falsche Eingabe
	JR	E22	
E21:	POP	AF	
	CP	A, 3AH	;da H10 = 1 , darf H1 < oder = 9 sein
	JR	NC, E2	
E22:	LD	C,2	;Ausgabe (H1)
	LD	E,A	
	LD	L,A	;Retten von H1 nach L
	CALL	5	;Ausgabe von H1
E3:	LD	C,1	;Systemruf Eingabe (Minutenzehner M10)
	CALL	5	
	CP	A, 03H	
	JR	Z, ENDE	;STOP gedrückt
	CP	A, 30H	
	JR	C, E3	;Eingabe < 0
	CP	A, 37H	
	JR	NC, E3	;Eingabe > 6
	LD	C,2	;Ausgabe (M10)
	LD	E,A	
	LD	D,A	;Retten von M10 nach D
	CALL	5	
E4:	LD	C,1	;Systemruf Eingabe (Minuteneiner M1)
	CALL	5	
	CP	A, 03H	
	JR	Z, ENDE	;STOP gedrückt
	CP	A, 30H	;
	JR	C, E4	;Eingabe < 0
	CP	A, 3AH	
	JR	NC, E4	;Eingabe > 9
	LD	C,2	;Ausgabe (M1)
	LD	E,A	
	CALL	5	
	LD	A,01H	;Setzen der Kontrollregister vom RTC
	OUT	6DH, A	
	LD	A,07H	
	OUT	6FH, A	
	LD	A,H	
	OUT	65H, A	;Schreiben H10 in RTC
	LD	A,L	
	OUT	64H, A	;Schreiben H1 in RTC
	LD	A,D	
	OUT	63H, A	;Schreiben M10 in RTC
	LD	A,E	
	OUT	62H, A	;Schreiben M1 in RTC
	XOR	A	
	OUT	61H, A	;Setzen der Kontrollregister vom RTC
	OUT	60H, A	
	OUT	6DH, A	
	LD	A,04H	
	OUT	6EH, A	
	OUT	6FH, A	;fertig
PPEND:	POP	DE	
PEND:	POP	DE	
ENDE:	JP	0F089H	;zum Kaltstart

RTC:	LD	HL,SEC	;Sekundenzelle der Systemuhr
	LD	C,60H	;Einer
	LD	B,3	;Sekunden, Minuten, Stunden = 3 Stellen
R1:	IN	A, (C)	
	AND	A, 0FH	
	LD	(HL),A	
	INC	C	;Zehner
	IN	A, (C)	
	AND	A, 0FH	
	OR	A	;wenn 0, dann kein Faktor
	JR	Z, R3	
	PUSH	BC	
	LD	B,A	
	XOR	A	
R2:	ADD	A, 0AH	;10 dazuzählen
	DJNZ	R2	
	POP	BC	
R3:	ADD	A, (HL)	
	LD	(HL),A	
	INC	C	
	DEC	HL	
	DJNZ	R1	
NOFK:	LD	HL,ZIEL	;1. freie Adresse im Farbspeicher
	LD	A,58H	
	LD	(HL),A	
	INC	(HL)	
	LD	A,(HL)	
	CP	A, 59H	
	JR	NZ, ENDE	
	LD	(208H),HL	;Tastaturinterrupt-Zeiger
				;1. freie Adresse im Farbspeicher 
	PUSH	HL	
;
	PUSH	HL	
	POP	DE	
	LD	HL,START	;Anfang der Anzeigeroutine
	LD	BC,DIFF	;Länge der Anzeigeroutine
	LDIR		;in den Farbspeicher kopieren
	POP	HL	
	JP	(HL)	;und ausführen
			;Bildspeicher wird von rechts 
			;nach links beschrieben
START:	PUSH	HL	;Register retten
	PUSH	BC	
	PUSH	AF	
	LD	HL,0EC26H	;Adresse Sekundeneiner im Bildspeicher
	LD	C,60H	;OUT-Adresse Sekundeneiner im RTC
	JR	M2	
M1:	LD	A,3AH	;Doppelpunkt zwischen den Ziffern
	LD	(HL),A	;in den Bildspeicher
	DEC	HL	;nächste Adresse links
M2:	LD	B,2	;2 Ziffern
M3:	IN	A, (C)	;aus dem RTC lesen
	AND	A, 0FH	
	ADD	A, 30H	
	LD	(HL),A	;in den Bildspeicher
	DEC	HL	;nächste Adresse links
	INC	C	;nächste OUT-Adresse des RTCs
	DJNZ	M3	
	LD	A,C	
	CP	A, 65H	
	JR	C, M1	;Ausgabeende erreicht
	POP	AF	;Register wieder herstellen
	POP	BC	
	POP	HL	
	JP	0FCE4H	;zum Tastaturinterrupt


RTCEX:	LD	HL,0FCE4H	;Tastaturinterrupt
	LD	(208H),HL	;Interrupt-Zeiger zurückbiegen
	JR	Z, ENDE	;fertig
T1:	DB	"EINGABE DER ZEIT (HHMM): "	
	DB	0	


DATIN:	LD	C,9	;Ausgabe des Datumformates
	LD	DE,T2	
	CALL	5	
Y10:	LD	C,1	;Systemruf Eingabe (Jahreszehner Y10)
	CALL	5	
	CP	A, 03H	
	JP	Z, ENDE	;STOP gedrückt
	CP	A, 30H	
	JR	C, Y10	;Y10 < 0
	CP	A, 3AH	
	JR	NC, Y10	;Y10 > 9
	LD	C,2	;Ausgabe Y10
	LD	D,A	;Retten Y10 nach D
	LD	E,A	
	CALL	5	
Y1:	LD	C,1	;Systemruf Eingabe (Jahreseiner Y1)
	CALL	5	
	CP	A, 03H	
	JP	Z, ENDE	;STOP gedrückt
	CP	A, 30H	
	JR	C, Y1	;Y1 < 0
	CP	A, 3AH	
	JR	NC, Y1	;Y1 > 9
	LD	C,2	;Ausgabe Y1
	LD	E,A	;Y1 nach E
	CALL	5	
	PUSH	DE	;DE (Jahr) auf den Stack
M10:	LD	C,1	;Systemruf Eingabe (Monatszehner M10)
	CALL	5	
	CP	A, 03H	
	JP	Z, PEND	;STOP gedrückt
	CP	A, 30H	
	JR	C, M10	;M10 < 0
	CP	A, 32H	
	JR	NC, M10	;M10 > 1
	LD	C,2	;Vorbereiten Ausgabe M10
	LD	E,A	
	XOR	A	;1. Monatsziffer nach hex wandeln
	LD	B,A	;und in B sichern:
	BIT	0,E	
	JR	Z, M101	
	LD	A,0AH	
	LD	B,A	
M101:	LD	D,E	;Retten M10 nach D
	CALL	5	
M01:	LD	C,1	;Systemruf Eingabe (Monatseiner M1)
	CALL	5	
	CP	A, 03H	
	JP	Z, PEND	;STOP gedrückt
	CP	A, 30H	
	JR	C, M01	;M1 < 0
	PUSH	AF	
	SUB	30H	
	ADD	A, B	;2. Monatsziffer in B addieren
	LD	B,A	
	LD	A,E	
	CP	A, 30H	
	JR	Z, M02	;war M10 = 0?
	POP	AF	
	CP	A, 33H	
	JR	NC, M01	;M10 > 2
	JR	M03	;M1 ist 0, 1 oder 2
M02:	POP	AF	;M1
	CP	A, 31H	
	JR	C, M01	;M1 < 0
	CP	A, 3AH	
	JR	NC, M01	;M1 > 9
M03:	LD	C,2	;Ausgabe M1
	LD	E,A	;M1 nach E
	CALL	5	
	PUSH	DE	;DE (Monat) auf den Stack
D10:	LD	C,1	;Systemruf Eingabe (Tageszehner D10)
	CALL	5	
	CP	A, 03H	
	JP	Z, PPEND	;STOP gedrückt
	CP	A, 30H	
	JR	C, D10	;D10 < 0
	CP	A, 34H	
	JR	NC, D10	;D10 > 3
	LD	C,2	;Ausgabe D10
	LD	E,A	
	LD	H,A	;D10 nach H
	LD	A,B	;Monat in hex
	CP	A, 2	
	JR	NZ, D101	;kein Februar
	LD	A,E	
	CP	A, 33H	
	JR	NC, D10	;im Februar 3 unzulässig
D101:	CALL	5	
D1:	LD	C,1	;Systemruf Eingabe (Tageseiner D1)
	CALL	5	
	CP	A, 03H	
	JP	Z, PPEND	;STOP gedrückt
	CP	A, 30H	
	JR	C, D1	;D1 < 0
	CP	A, 3AH	
	JR	NC, D1	;D1 > 9
	LD	C,2	;Ausgabe D1
	LD	L,A	;D1 nach L
	CP	A, 30H	
	JR	NZ, D11	;D1 nicht 0
	LD	A,H	;D10
	CP	A, 30H	
	JR	Z, D1	;D10 = 0
D11:	LD	A,H	
	CP	A, 33H	
	JR	NZ, D12	;D10 nicht 3
	LD	A,B	
	CP	A, 04H	
	JR	Z, D13	;April
	CP	A, 06H	
	JR	Z, D13	;Juni
	CP	A, 09H	
	JR	Z, D13	;September
	CP	A, 0BH	
	JR	Z, D13	;November
	JR	D12	
D13:	LD	A,L	;D1, wenn Monat 4,6,9,11
	CP	A, 31H	
	JR	Z, D1	;nur 30 Tage, D1 nur 0
	CP	A, 32H	;D1 ungültig
	JR	NC, D1	
D12:	LD	E,L	;D1 nach E
	CALL	5	;
	LD	A,01	;Setzen der Kontrollregister vom RTC
	OUT	6DH, A	
	LD	A,07	
	OUT	6FH, A	
	LD	A,H	
	OUT	67H, A	;Schreiben D10 in RTC
	LD	A,L	
	OUT	66H, A	;Schreiben D1 in RTC
	LD	A,D	
	POP	DE	
	OUT	69H, A	;Schreiben M10 in RTC
	LD	A,E	
	OUT	68H, A	;Schreiben M1 in RTC
	POP	DE	
	LD	A,D	
	OUT	6BH, A	;Schreiben Y10 in RTC
	LD	A,E	
	OUT	6AH, A	;Schreiben Y1 in RTC
	XOR	A	
	OUT	6DH, A	;Setzen der Kontrollregister vom RTC
	LD	A,04H	
	OUT	6EH, A	
	OUT	6FH, A	
	JP	ENDE	;fertig
T2:	DB	"EINGABE DES DATUMS (YYMMDD): "	
	DB	0	


DAT:	LD	HL,0EC47H	;Adresse der 1. Ziffer im Bild-
			;speicher unter der Uhranzeige
	LD	C,67H	;OUT-Adresse Tageszehner im RTC
	JR	N2	
N1:	LD	A,2EH	;Punkt zwischen den Ziffern
	LD	(HL),A	;in den Bildspeicher
	INC	HL	;nächste Adresse rechts
N2:	LD	B,2	;2 Ziffern
N3:	IN	A, (C)	;aus dem RTC lesen
	AND	A, 0FH	
	ADD	A, 30H	
	LD	(HL),A	;in den Bildspeicher
	INC	HL	;nächste Adresse rechts
	DEC	C	;nächste OUT-Adresse des RTCs
	DJNZ	N3	
	INC	C	;für deutsches Anzeigeformat
	INC	C	;OUT-Adresse für RTC einstellen
	INC	C	
	INC	C	
	LD	A,C	;OUT-Adresse Monats-/Tageszehner im RTC
	CP	A, 6DH	;Ende der Ausgabe erreicht?
	JR	C, N1	;nein
	JP	ENDE	;fertig

	END		
