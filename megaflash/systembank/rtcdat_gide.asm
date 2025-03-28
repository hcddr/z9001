;------------------------------------------------------------------------------
; basiert auf Code von uz
; erweitert vp 
; Variante für GIDE-RTC und UZ-RTC
; Systemerweiterung XOS für UZ-RTC
; 21.07.2016
;------------------------------------------------------------------------------

; RTC 72421:
; 0 1-second digit register
; 1 10-seconds digit register
; 2 1-minute digit register
; 3 10-minute digit register
; 4 1-hour digit register
; 5 10-hours digit register
; 6 1-day digit register
; 7 10-days digit register
; 8 1-month digit register
; 9 10-months digit register
; A 1-year digit register
; B 10-years digit register
; C Day-of-the-week register
; D Control register D
; E Control register E
; F Control register F

	cpu	z80

; bws(zeile 0..23, spalte 0..39) analog print_at
bws		function z,s,z*40+s+0EC00h

MZBWS:		EQU	bws(0,39)	;Merkzelle im BWS (Suchzelle)
; f. Reset
TMBWS0:		equ	bws(2,38)	;Position Uhrzeit
DTBWS0:		equ	bws(2,20)	;Position Datum

; f. autom. Anzeige
TMBWS:		equ	bws(0,38)	;Position Uhrzeit
DTBWS:		equ	bws(1,31)	;Position Datum

currbank:	equ	0042h		; aktuelle Bank

; Hardware
uz		equ	0		; 1=UZ-RTC, 0=GIDE-RTC

; Port
	if	uz=1
RTCPORT		equ	60h		; erster Port
	else
GIDERTC		equ	55h		; lo Port, B = hi-Port
	endif

;;	if	uz=1
	org	0E400h
;;	else
;;	org	0A400h
;;	endif

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

	JP	RTCX	;Anzeigen der Systemuhr
	DB	"RTC     "	
	DB	0	
	JP	RTCIN	;Stellen der Systemuhr
	DB	"RTCIN   "	
	DB	0	
	JP	RTCEX	;Ausschalten der Uhranzeige
	DB	"RTCEX   "	
	DB	0	
	JP	DATX	;Anzeige des Datums (einmalig)
	DB	"DAT     "	
	DB	0	
	JP	DATIN	;Setzen des Datums
	DB	"DATIN   "	
	DW	00	
;Platz

;	if	uz=1
;	DB	"UZ"
;	else
;	DB	"GIDE"
;	endif
	
	if	uz=1
	
;Erweiterung des ROM-Bank-Systems
;
	org	0E460h		; bei Ändern dieser Adresse auch Bank0 anpassen (Patchen der Einsprünge)
	jp	reset		; bei reset
	jp	cold		; bei cold
	jp	gocpm		; bei gocpm


;------------------------------------------------------------------------------
; Ausführen bei Reset
;------------------------------------------------------------------------------
reset:	
	call	UHR
	ret

;------------------------------------------------------------------------------
; Ausführen bei GOCPM (Prompt)
;------------------------------------------------------------------------------

gocpm:	
;	ld	a,(currbank)
;	add	a, '0'
;	ld	(MZBWS), a
;	
	ret

;------------------------------------------------------------------------------
; Ausgabe bei Warmstart
;------------------------------------------------------------------------------
cold:	LD	DE,XOS		;XOS-Prompt ausgeben
	LD	C,9
	CALL	5
	ret

XOS:	DB	0BH		;Aussehen des Prompts:
	DB	14H		;"XOS" in der Farbe gelb
	DB	03H
	DB	"XOS"
	DB	14H
	DB	02H
	DB	0AH
	DB	0DH
	DB	00H


	endif

;------------------------------------------------------------------------------

OUTRTC	macro r
	if	uz=1
	out	RTCPORT+r,a
	else
	ld	b,r
	out	(c),a
	endif
	endm
	
INRTC	macro r
	if	uz=1
	out	RTCPORT+r,a
	else
	ld	b,r
	out	(c),a
	endif
	endm
	
;------------------------------------------------------------------------------
; RTCIN Stellen der Systemuhr
;------------------------------------------------------------------------------

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
	if	uz=0
	ld	c,GIDERTC	;base port gide rtc
	endif
	LD	A,01H	;Setzen der Kontrollregister vom RTC
	OUTRTC	0DH
	LD	A,07H	
	OUTRTC	0FH	
	LD	A,H	
	OUTRTC	5	;Schreiben H10 in RTC
	LD	A,L	
	OUTRTC	4	;Schreiben H1 in RTC
	LD	A,D	
	OUTRTC	3	;Schreiben M10 in RTC
	LD	A,E	
	OUTRTC	2	;Schreiben M1 in RTC
	XOR	A	
	OUTRTC	1	;Setzen der Kontrollregister vom RTC
	OUTRTC	0	
	OUTRTC	0DH	
	LD	A,04H	
	OUTRTC	0EH	
	OUTRTC	0FH	;fertig
ENDE:	OR	A
	RET

T1:	DB	"EINGABE DER ZEIT (HHMM): "	
	DB	0	

;------------------------------------------------------------------------------
; RTCEX Ausschalten der Uhranzeige
;------------------------------------------------------------------------------

RTCEX:	LD	HL,0FCE4H	;Tastaturinterrupt
	LD	(208H),HL	;Interrupt-Zeiger zurückbiegen
	OR	A
	RET			;fertig


;------------------------------------------------------------------------------
; Setzen des Datums
;------------------------------------------------------------------------------

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
	if	uz=0
	ld	c,GIDERTC	;base port gide rtc
	endif
	LD	A,01	;Setzen der Kontrollregister vom RTC
	OUTRTC	0DH
	LD	A,07	
	OUTRTC	0FH
	LD	A,H	
	OUTRTC	7	;Schreiben D10 in RTC
	LD	A,L	
	OUTRTC	6	;Schreiben D1 in RTC
	LD	A,D	
	POP	DE	
	OUTRTC	9	;Schreiben M10 in RTC
	LD	A,E	
	OUTRTC	8	;Schreiben M1 in RTC
	POP	DE	
	LD	A,D	
	OUTRTC	0BH	;Schreiben Y10 in RTC
	LD	A,E	
	OUTRTC	0AH	;Schreiben Y1 in RTC
	XOR	A	
	OUTRTC	0DH	;Setzen der Kontrollregister vom RTC
	LD	A,04H	
	OUTRTC	0EH	
	OUTRTC	0FH	
	OR	A
	RET		;fertig

PPEND:	POP	DE	
PEND:	POP	DE
	RET
	
T2:	DB	"EINGABE DES DATUMS (YYMMDD): "	
	DB	0	

;------------------------------------------------------------------------------
; DAT
;------------------------------------------------------------------------------

DATX:	call DAT
	or	a
	ret	

;------------------------------------------------------------------------------
; RTC
;------------------------------------------------------------------------------

ZIEL:	EQU	0EBC0H	;die Zieladresse im Farbspeicher

RTCX:	LD	HL,ZIEL	;1. freie Adresse im Farbspeicher
	LD	A,58H	
	LD	(HL),A	
	INC	(HL)	
	LD	A,(HL)	
	CP	A, 59H	
	RET	NZ	; kein Farb-RAM
;
	
;
	LD	HL,START	;Anfang der Anzeigeroutine
	LD	DE,ZIEL
	LD	BC,ME-START	;Länge der Anzeigeroutine
	LDIR			;in den Farbspeicher kopieren

	LD	HL,ZIEL
	LD	(208H),HL	;Tastaturinterrupt-Zeiger
				;1. freie Adresse im Farbspeicher 
	;OR	A				
	;RET
	jp	(HL)
	
; DIE ISR	
	if uz=1
	
START:	PUSH	HL	;Register retten
	PUSH	BC	
	PUSH	AF	
	LD	HL,TMBWS	;Adresse Sekundeneiner im Bildspeicher
	LD	C,RTCPORT+0	;OUT-Adresse Sekundeneiner im RTC
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
	CP	A, RTCPORT+5	
	JR	C, M1	;Ausgabeende erreicht
	POP	AF	;Register wieder herstellen
	POP	BC	
	POP	HL	
	JP	0FCE4H	;zum Tastaturinterrupt

	else
	;gide

START:	PUSH	HL	;Register retten
	PUSH	DE
	PUSH	BC	
	PUSH	AF	
	LD	HL,TMBWS	;Adresse Sekundeneiner im Bildspeicher
	LD	B,0	;OUT-Adresse Sekundeneiner im RTC
	LD	C,GIDERTC
	JR	M2	
M1:	LD	A,3AH	;Doppelpunkt zwischen den Ziffern
	LD	(HL),A	;in den Bildspeicher
	DEC	HL	;nächste Adresse links
M2:	LD	D,2	;2 Ziffern
M3:	IN	A, (C)	;aus dem RTC lesen
	AND	A, 0FH	
	ADD	A, 30H	
	LD	(HL),A	;in den Bildspeicher
	DEC	HL	;nächste Adresse links
	INC	B	;nächste OUT-Adresse des RTCs
	DEC	D
	JR	NZ,M3	
	LD	A,B	
	CP	A, 5	
	JR	C, M1	;Ausgabeende erreicht
	POP	AF	;Register wieder herstellen
	POP	BC	
	POP	DE
	POP	HL	
	JP	0FCE4H	;zum Tastaturinterrupt
	endif

ME:	EQU $



;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

; UNTERPROGRAMME --------------------------------------------------------

SEC:	EQU	001FH		;Speicherzelle Sekunden			(neu)

;--------------------------------
;
;
UHR:	if	uz=1
	LD	C,RTCPORT+0	;Port Sekundeneiner
	else
	LD	C,GIDERTC
	ld	b,0		;Port Sekundeneiner
	endif
	IN	A, (c)		;Sekunde Einer lesen
;Test, ob der RTC installiert ist
	and	0fh
	cp	10		; <10?
	ret	nc		;nein, also keine UZ-Uhr
;
	LD	HL,TMBWS0	;Anzeigeadresse im Bildspeicher
	call	RTC0
	LD	HL,DTBWS0	;Anzeigeadresse im Bildspeicher	
	call	DAT0
	call	R0
	ret
		
;--------------------------------
;Uhrzeit anzeigen
;
RTC:	LD	HL,TMBWS	;Anzeigeadresse im Bildspeicher

	if	uz=1
RTC0:	LD	C,RTCPORT+0	;Port Sekundeneiner
	JR	RTC2
RTC1:	LD	A,3AH		;Doppelpunkt
	LD	(HL),A		;ausgeben
	DEC	HL		;naechste BWS-Adresse
RTC2:	LD	B,2		;Anzahl der anzuzeigenden Stellen
RTC3:	IN	A, (c)		;Sekundeneiner lesen (Minute,Stunde)
	AND	0FH		;letzte Stelle toren
	ADD	a,30H		;in Dezimalzahl wandeln
	LD	(HL),A		;im BWS speichern
	DEC	HL		;naechste BWS-Adresse
	INC	C		;Port Sekundenzehner (Minute,Stunde)
	DJNZ	RTC3		;es war schon die zweite Stelle
	LD	A,C		;aktueller RTC-Port
	CP	RTCPORT+5	;Anzeigenende erreicht?
	JR	C,RTC1		;nein, zum Doppelpunkt ausgeben
	ret
	else
	;gide
RTC0:	LD	B,0		;Port Sekundeneiner
	LD	C,GIDERTC
	JR	RTC2
RTC1:	LD	A,3AH		;Doppelpunkt
	LD	(HL),A		;ausgeben
	DEC	HL		;naechste BWS-Adresse
RTC2:	LD	D,2		;Anzahl der anzuzeigenden Stellen
RTC3:	IN	A, (c)		;Sekundeneiner lesen (Minute,Stunde)
	AND	0FH		;letzte Stelle toren
	ADD	a,30H		;in Dezimalzahl wandeln
	LD	(HL),A		;im BWS speichern
	DEC	HL		;naechste BWS-Adresse
	INC	B		;Port Sekundenzehner (Minute,Stunde)
	DEC	D
	JR	NZ,RTC3		;es war schon die zweite Stelle
	LD	A,B		;aktueller RTC-Port
	CP	A, 5		;Anzeigenende erreicht?
	JR	C,RTC1		;nein, zum Doppelpunkt ausgeben
	ret
	endif


;--------------------------------
;Datum anzeigen
;
DAT:	LD	HL,DTBWS	;Anzeigeadresse im Bildspeicher	;
	if	uz=1
DAT0:	LD	C,RTCPORT+7	;Port Jahreseiner
	JR	DAT2
DAT1:	LD	A,2EH		;Punkt
	LD	(HL),A		;ausgeben
	INC	HL		;naechste BWS-Adresse
DAT2:	LD	B,2		;Anzahl der anzuzeigenden Stellen
DAT3:	IN	A,(c)		;Jahreseiner lesen (Monat,Tag)
	AND	0FH		;letzte Stelle toren
	ADD	a,30H		;in Dezimalzahl wandeln
	LD	(HL),A		;im BWS speichern
	INC	HL		;naechste BWS-Adresse
	DEC	C		;Port Jahreszehner (Monat,Tag)
	DJNZ	DAT3		;es war schon die zweite Stelle
	INC	C
	INC	C
	INC	C
	INC	C
	LD	A,C		;aktuelle Portadresse
	CP	RTCPORT+0DH		;Port Tageszehner?
	JR	C,DAT1		;nein, zum Punkt ausgeben
				;Ausgabe beendet
	ret
	else
DAT0:	LD	C,GIDERTC
	LD	B,7		;Port Jahreseiner
	JR	DAT2
DAT1:	LD	A,2EH		;Punkt
	LD	(HL),A		;ausgeben
	INC	HL		;naechste BWS-Adresse
DAT2:	LD	D,2		;Anzahl der anzuzeigenden Stellen
DAT3:	IN	A,(c)		;Jahreseiner lesen (Monat,Tag)
	AND	0FH		;letzte Stelle toren
	ADD	a,30H		;in Dezimalzahl wandeln
	LD	(HL),A		;im BWS speichern
	INC	HL		;naechste BWS-Adresse
	DEC	B		;Port Jahreszehner (Monat,Tag)
	DEC	D
	JR	NZ,DAT3		;es war schon die zweite Stelle
	INC	B
	INC	B
	INC	B
	INC	B
	LD	A,B		;aktuelle Portadresse
	CP	0DH		;Port Tageszehner?
	JR	C,DAT1		;nein, zum Punkt ausgeben
				;Ausgabe beendet
	ret
	endif



;--------------------------------
;Zeit ins System uebernehmen:
;
	if uz=1
R0:	LD	HL,SEC		;Systemzelle Sekunden fuer PRITI
	LD	C,RTCPORT+0	;Port Sekundeneiner
	LD	B,3
R1:	IN	A, (c)		;Sekundeneiner lesen (Minute,Stunde)
	AND	a,0FH		;letzte Stelle toren
	LD	(HL),A		;in Systemzelle speichern
	INC	C		;naechste Stelle
	IN	A, (c)		;Sekundenzehner lesen
	AND	a,0FH
	OR	A		;=0?
	JR	Z, R3
	PUSH	BC
	LD	B,A
	XOR	A
R2:	ADD	a,0AH
	DJNZ	R2
	POP	BC
R3:	ADD	A,(HL)
	LD	(HL),A
	INC	C
	DEC	HL
	DJNZ	R1
	RET
	else
R0:	LD	HL,SEC		;Systemzelle Sekunden fuer PRITI
	LD	B,GIDERTC
	LD	C,0		;Port Sekundeneiner
	LD	D,3
R1:	IN	A, (c)		;Sekundeneiner lesen (Minute,Stunde)
	AND	a,0FH		;letzte Stelle toren
	LD	(HL),A		;in Systemzelle speichern
	INC	B		;naechste Stelle
	IN	A, (c)		;Sekundenzehner lesen
	AND	a,0FH
	OR	A		;=0?
	JR	Z, R3
	PUSH	BC
	LD	B,A
	XOR	A
R2:	ADD	a,0AH
	DJNZ	R2
	POP	BC
R3:	ADD	A,(HL)
	LD	(HL),A
	INC	B
	DEC	HL
	DEC	D
	JR	NZ, R1
	RET
	endif	

