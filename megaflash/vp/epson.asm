	cpu	z80
;
;universeller Druckertreiber fuer ESCP an Z9001
;
;V.Pohlers, 2009
;

; Anschluss: 1-V24, 2-Centronics		1- V24-Modul (9600Baud, 8N1), 2 - UserPort lt. mp
; Arbeitsmodi: 1-Grafik, 2-ASCII, 3-IBM		1-Vollgrafik, 2-nur '*' bei Grafik, 3-Direktmodus
; unterstützte Drucker:	LX86, LQ400, K6313, K6304 (TS80)
; Im Megamodul gibt es das Programm "Zwinger", das ist für eine Bildschirmkopie gut geeignet...

; k6311 ESC K n1 n2  	Single density graphics (60 dpi) 
; 	ESC [ 1 e	Zeilenvorschub 1/12 Zoll (Halbzeilenvorschub)

; k6313 ESC K n1 n2  	Single density graphics (60 dpi) 
; 	ESC J	18 	ESC J n  Immediate n/216 inch line feed (Zeilenvorschub 1/12 Zoll)


; Drucker-Modul
SIOCA:	EQU	0B2H	
SIODA:	EQU	0B0H	
CTC0:	EQU	0A8H	

; Parallel-Port
PIOBC:	EQU	08BH 	;USER-Port
PIOBD:	EQU	089H 	

;
IOBYT:	EQU	0004H	
LISW:	EQU	0015H	
KEYBU:	EQU	0025H	
EOR:	EQU	0036H	
INTLN:	EQU	0100H	
ATTYL:	EQU	0EFE1H	
TXLST:	EQU	0EFEFH	
GOCPM:	EQU	0F089H	
GVAL:	EQU	0F1EAH	
ERPAR:	EQU	0F5E6H	
DECO0:	EQU	0FD33H	
;
ESC	equ	27
;

;	ORG	0B400H	
	ORG	0A400H	
;
PBEG:	
	JP	INIT0	
	DB	"ESCP    "	
	DW	0	


centr	db	0		; 0 - V24-Anschluss
				; 1 - CENTRONICS

txtab	dw	LX86_TAB	; Tabelle der ESC-Sequenzen

;;	Aufbau:
;;	dw	NAME	; ix+0	Bezeichnung des Druckers
;;	dw	INTX1	; ix+2	Initialisierung des Druckers
;;	dw	LTX1	; ix+4	Ausgabe ein Grafikzeichen
;;	dw	LTX2	; ix+6	Grafik Start
;;	dw	LTX3	; ix+8	Grafik neue Zeile
;;	dw	LTX4	; ix+10	Zeilenende
;;	dw	LTX5	; ix+12	Grafik Ende
	

INIT0:	call	dia1
;
INIT:	LD	HL,PBEG-100H	
	LD	(EOR),HL	
	LD	DE,INTX0	;Text
	LD	(TXLST),DE	;Zeichenkette fuer LIST eintragen
	
	ld	a, (centr)
	or	a
	call	z, v24init	; v24 init.
	
;
INI1:	LD	HL,TTYL		;TTY-Treiber
	LD	(ATTYL),HL	
	LD	HL,IOBYT	;LIST:=ATTYP
	RES	7,(HL)	
	RES	6,(HL)	
	XOR	A	
	LD	(LISW),A	;kein Copy
;;	LD	(0EFC8h),A	;Cursor an
	CALL	INUP1		;Drucker init.
	AND	A, A	
	RET		
;
INUP1:	LD	IX,(txtab)
	ld	L, (ix+2)
	ld	h, (ix+3)	;INTX1	;Initialisierung ESCP
	CALL	SOUT	
	AND	A, A	
	RET		
;
;Stringausgabe auf Druckerkanal
SOUT:	LD	B,(HL)		;Zeichenanzahl
SOUT1:	INC	HL	
	LD	C,(HL)	
	PUSH	BC	
	PUSH	HL	
	CALL	LO0		;direkte Zeichenausgabe
	POP	HL	
	POP	BC	
	DJNZ	SOUT1	
	RET		
	
	
	
;CTC+SIO initialisieren
v24init:
	LD	HL,INID1	;Steuerworttabelle
	LD	C,CTC0	
	LD	B,2	
	OTIR		
	LD	C,SIOCA	
	LD	B,8	
	OTIR		
	ret
;
INID1:	DB	17H	
	DB	1	
	DB	4	
	DB	46H	
	DB	1	
	DB	0	
	DB	3	
	DB	0C0H	
	DB	5	
	DB	68H	
;

	
INTX0:	DB	"ESCP "
MODUS:	DB	" "	
	DB	0	
;


; Parameter f. Druckertreiber abfragen

dia1	
	ld	de, aAnschluss
	ld	c, 9		; PRNST
	call	5
	ld	c, 1		; CONSI
dia2	call	5
	cp	'1'
	jr	z, dia3
	cp	'2'
	jr	nz, dia2
dia3	ld	e, a
	ld	c, 2		; CONSO
	call	5
	sub	a,'1'
	ld	(centr),a	; 0 - V24-Anschluss, 1 - CENTRONICS
;
	ld	de, aModus
	ld	c, 9		; PRNST
	call	5
	ld	c, 1		; CONSI
dia4	call	5
	cp	'1'
	ld	b, 'G'
	jr	z, dia5
	cp	'2'
	ld	b, 'A'
	jr	z, dia5
	cp	'3'
	ld	b, 'I'
	jr	nz, dia4
dia5	ld	e, a
	ld	c, 2		; CONSO
	call	5
	ld	a, b
	ld	(modus), a
;
	ld	de, aDrucker
	ld	c, 9		; PRNST
	call	5
	ld	c, 1		; CONSI
dia6	call	5
	cp	'1'
	ld	hl, LX86_TAB
	jr	z, dia7
	cp	'2'
	ld	hl, LQ400_TAB
	jr	z, dia7
	cp	'3'
	ld	hl, K6313_TAB
	jr	z, dia7
	cp	'4'
	ld	hl, K6304_TAB
	jr	nz, dia6
dia7	ld	e, a
	ld	c, 2		; CONSO
	call	5
	ld	(txtab),hl
;	
	ld	de, acrlf
	ld	c, 9		; PRNST
	call	5
	ret

aAnschluss
	db	"1-V24, 2-Centronics: ",0
aModus
	db	13,10,"1-Grafik, 2-ASCII, 3-IBM: ",0
aDrucker
	db	13,10,"1-LX86, 2-LQ400"
	db	13,10,"3-K6313, 4-K6304: ",0
acrlf
	db	13,10,0

;------------------------------------------------------------------------------
; Tabellen der Druckercodes
;------------------------------------------------------------------------------

;LX86
;
LX86_NAME:
	DB	"LX86",0
	
LX86_INTX1:
	DB	LX86_LTX1-LX86_INTX1-1	;Anzahl der Bytes
	DB	ESC	
	DB	"@"	;Grundzustand
	DB	ESC	
	DB	"8"	;Papierendekontrolle aus
	DB	ESC	
	DB	"l"	
	DB	6	;linker Rand
	DB	ESC	
	DB	"Q"	;rechter Rand
	DB	80	
;Ausgabe ein Grafikzeichen
LX86_LTX1:
	DB	LX86_LTX2-LX86_LTX1-1	;Anzahl
	DB	ESC	
	DB	"*"	
	DB	4	; CRT-Grafik 1 (80 Punkte/Zoll)
	DW	8	;8x Grafikdaten
;Grafik Start
LX86_LTX2:
	DB	LX86_LTX3-LX86_LTX2-1	;Anzahl
	DB	0AH	;LF
	DB	0DH	;CR
	DB	ESC	
	DB	"A"	;Zeilenabstand
	DB	8	;8/72-Zoll
;Grafik neue Zeile
LX86_LTX3:
	DB	LX86_LTX4-LX86_LTX3-1	;Anzahl
	DB	"    "	
	DB	ESC	
	DB	"*"	;Grafikmode
	DB	5	; Plottergrafik 72 Punkte/zoll
	DW	320	;320 Zeichen
;Zeilenende
LX86_LTX4:
	DB	LX86_LTX5-LX86_LTX4-1	;Anzahl
	DB	0AH	;LF
	DB	0DH	;CR
;Grafik Ende
LX86_LTX5:
	DB	LX86_TAB-LX86_LTX5-1	;Anzahl
	DB	ESC	
	DB	"2"	;Zeilenabstand 1/6-Zoll
	DB	0AH	;LF
	DB	0DH	;CR

LX86_TAB
	dw	LX86_NAME	; ix+0
	dw	LX86_INTX1	; ix+2
	dw	LX86_LTX1	; ix+4
	dw	LX86_LTX2	; ix+6
	dw	LX86_LTX3	; ix+8
	dw	LX86_LTX4	; ix+10
	dw	LX86_LTX5	; ix+12


;K6313
;
K6313_NAME:
	DB	"K6313",0
	
K6313_INTX1:
	DB	K6313_TAB-K6313_INTX1-1	;Anzahl der Bytes
	DB	ESC	
	DB	"@"	;Grundzustand
	DB	ESC	
	DB	"8"	;Papierendekontrolle aus
;	DB	ESC	
;	DB	"l"	
;	DB	6	;linker Rand
	DB	ESC	
	DB	"Q"	;rechter Rand
	DB	80	
; Rest wie LX86

K6313_TAB
	dw	K6313_NAME
	dw	K6313_INTX1
	dw	LX86_LTX1
	dw	LX86_LTX2
	dw	LX86_LTX3
	dw	LX86_LTX4
	dw	LX86_LTX5


;LQ400
;
LQ400_NAME:
	DB	"LQ400",0
	
LQ400_INTX1:
	DB	LQ400_LTX1-LQ400_INTX1-1	;Anzahl der Bytes
	DB	ESC	
	DB	"@"	;Grundzustand
;	DB	ESC	
;	DB	"8"	;Papierendekontrolle aus
	DB	ESC	
	DB	"l"	
	DB	6	;linker Rand
	DB	ESC	
	DB	"Q"	;rechter Rand
	DB	80	
;Ausgabe ein Grafikzeichen
LQ400_LTX1:
	DB	LQ400_LTX2-LQ400_LTX1-1	;Anzahl
	DB	ESC	
	DB	"*"	
	DB	4	; CRT-Grafik 1 (80 Punkte/Zoll)
	DW	8	;8x Grafikdaten
;Grafik Start
LQ400_LTX2:
	DB	LQ400_LTX3-LQ400_LTX2-1	;Anzahl
	DB	0AH	;LF
	DB	0DH	;CR
	DB	ESC	
	DB	"0"	;Zeilenabstand 1/8-Zoll
;Grafik neue Zeile
LQ400_LTX3:
	DB	LQ400_LTX4-LQ400_LTX3-1	;Anzahl
	DB	"    "	
	DB	ESC	
	DB	"*"	;Grafikmode
	DB	4	; Plottergrafik 80 Punkte/Zoll
	DW	320	;320 Zeichen
;Zeilenende
LQ400_LTX4:
	DB	LQ400_LTX5-LQ400_LTX4-1	;Anzahl
	DB	0AH	;LF
	DB	0DH	;CR
;Grafik Ende
LQ400_LTX5:
	DB	LQ400_TAB-LQ400_LTX5-1	;Anzahl
	DB	ESC	
	DB	"2"	;Zeilenabstand 1/6-Zoll
	DB	0AH	;LF
	DB	0DH	;CR

LQ400_TAB
	dw	LQ400_NAME	; ix+0
	dw	LQ400_INTX1	; ix+2
	dw	LQ400_LTX1	; ix+4
	dw	LQ400_LTX2	; ix+6
	dw	LQ400_LTX3	; ix+8
	dw	LQ400_LTX4	; ix+10
	dw	LQ400_LTX5	; ix+12


;k6304
;
K6304_NAME:
	DB	"K6304",0
	
K6304_INTX1:
	DB	K6304_LTX1-K6304_INTX1-1	;Anzahl der Bytes
	DB	ESC	
	DB	"@"	;Grundzustand
;Ausgabe ein Grafikzeichen
K6304_LTX1:
	DB	K6304_LTX2-K6304_LTX1-1	;Anzahl
	DB	ESC	
	DB	"K"
	DW	8	;8x Grafikdaten
;Grafik Start
K6304_LTX2:
	DB	K6304_LTX3-K6304_LTX2-1	;Anzahl
	DB	0AH	;LF
	DB	0DH	;CR
	DB	ESC	
	DB	"A"	;Zeilenabstand
	DB	8	;8
;Grafik neue Zeile
K6304_LTX3:
	DB	K6304_LTX4-K6304_LTX3-1	;Anzahl
	DB	"    "	
	DB	ESC	
	DB	"K"	;Grafikmode
	DW	320	;320 Zeichen
;Zeilenende
K6304_LTX4:
	DB	K6304_LTX5-K6304_LTX4-1	;Anzahl
	DB	0AH	;LF
	DB	0DH	;CR
;Grafik Ende
K6304_LTX5:
	DB	K6304_TAB-K6304_LTX5-1	;Anzahl
	DB	ESC	
	DB	"A"	;Zeilenabstand 1/6"
	DB	10	; ?? 12 ist zu viel	
	DB	0AH	;LF
	DB	0DH	;CR

K6304_TAB
	dw	K6304_NAME	; ix+0
	dw	K6304_INTX1	; ix+2
	dw	K6304_LTX1	; ix+4
	dw	K6304_LTX2	; ix+6
	dw	K6304_LTX3	; ix+8
	dw	K6304_LTX4	; ix+10
	dw	K6304_LTX5	; ix+12



;
;***
;
;Druckertreiber
; in A - Kommando
;    C - Zeichen
;
TTYL:	INC	A	;A=0FFH Drucker init. ?
	Jp	Z, INUP1	;Initialisieren und RET
	DEC	A	;A=0?
	JR	NZ, LOA	;nein
;
	ld	a,(centr)
	or	a
	jr	nz, cLOD1

; V24
LOD1:	AND	A, A	;Statusabfrage
	LD	A,10H	
	OUT	SIOCA, A	
	IN	A, SIOCA	
	BIT	5,A	
	RET	NZ	
	SCF		
	RET		;Status zurueck

; Centronics	
cLOD1:	LD	A,0FFH	
	OR	A	;Cy=0
	ret
;
;in C Zeichen
LOA:	LD	A,(MODUS)	
	CP	A, 'A'	
	JR	Z, ASCII	
	CP	A, 'G'	
	JP	Z, GRAFI	

;sonst direkte Ausgabe (IBM-Satz) 
LO0:	CALL	STPRQ		;>STOP<-Taste gedrueckt?
	JR	NC, LO1		;nein
	LD	(LISW),A	;sonst Drucker aus
	RET			;Cy=1
;
LO1:	CALL	LOD1		;Drucker bereit?
	JR	C, LO0		;noch warten
;
;Zeichenausgabe ueber Druckermodul
PSOUT:	
	ld	a,(centr)
	or	a
	jr	nz, cPSOUT
;
	LD	A,C	
	OUT	SIODA, A	
;
TIM:	PUSH	BC		; Verzoegerung
	LD	BC,540	
TIM1:	DEC	C	
	JR	NZ, TIM1	
	DJNZ	TIM1	
	POP	BC	
;
	AND	A, A	
	RET		
;
STPRQ:	CALL	DECO0	
	EI		
	SUB	3	
	OR	A		 ;>STOP< gedrueckt?
	RET	NZ	
	LD	(KEYBU),A	
	SCF		
	RET		

;Zeichenausgabe ueber CENTRONICS parallel
WTBYT:	DB	0FFH	
;
cPSOUT:	PUSH	HL	
	LD	HL,cINTR	
	LD	(0210H),HL	
	POP	HL	
	LD	A,0FH			;PIO-Mode 0
	OUT	PIOBC, A	
	LD	A,10H			;Interruptvektor
	OUT	PIOBC, A	
	LD	A,83H			;Int.freigabe
	OUT	PIOBC, A	
;
	LD	A,0FFH	
	LD	(WTBYT),A	
	LD	A,C			;Byte
	OUT	PIOBD, A	
;
cLO11:	LD	A,(WTBYT)	
	OR	A	
	JR	NZ, cLO11	
;
	AND	A, A	
	RET		
;
;Interruptroutine
cINTR:	PUSH	AF	
	XOR	A	
	LD	(WTBYT),A	
	POP	AF	
	EI		
	RETI		
;
	
;
;***
;
;ASCII-Modus
;    20H-7FH direkte Uebergabe
;    80H-FFH als '*'
;    08H (BS) --> 7FH (DEL)
;    17H (^W) --> 0CH (FORM FEED)
;    0EH (^N) --> Hardcopy
;    0CH (CLS) wird ignoriert
;    Rest wird uebergeben
;
ASCII:	LD	A,C	;Zeichen
;
	CP	A, ' '	
	JR	C, ASC1	;Steuerzeichen
	CP	A, 080H	
	JR	C, ASCOT	
	LD	A,'*'	;wenn Grafikzeichen
	JR	ASCOT	
;
ASC1:	CP	A, 8	;BS
	JR	NZ, ASC2	
	LD	A,7FH	;DEL
	JR	ASCOT	
;
ASC2:	CP	A, 17H	;^W
	JR	NZ, ASC3	
	LD	A,0CH	;FORM FEED
	JR	ASCOT	
;
ASC3:	CP	A, 0CH	;CLS
	JR	NZ, ASC4	
	AND	A, A	
	RET		;ignorieren
;
ASC4:	CP	A, 0EH	;^N
	JR	Z, BWCOP	
;
ASCOT:	LD	C,A	
	JP	LO0	
;
;Bildschirmkopie
BWCOP:	PUSH	HL	
	PUSH	BC	
	LD	HL,0EC00H	
	LD	B,24	;Zeilenanzahl
BWC1:	PUSH	BC	
	LD	B,40	;Zeichen/Zeile
BWC2:	LD	A,(HL)	
	CP	A, ' '	
	JR	NC, BWC3	
	LD	A,' '	
BWC3:	CP	A, 80H	
	JR	C, BWC4	
	LD	A,'*'	
BWC4:	LD	C,A	
	CALL	LO0	
	INC	HL	
	DJNZ	BWC2	
	LD	C,0DH	;CR
	CALL	LO0	
	LD	C,0AH	;LF
	CALL	LO0	
	POP	BC	
	DJNZ	BWC1	
	POP	BC	
	POP	HL	
	AND	A, A	
	RET		
;
;***
;
;GRAFIK
;   nur Grafikzeichen als Grafik
;   und Bildschirmkopie,
;   Rest wie im Modus ASCII
;
GRAFI:	LD	A,C	;Zeichen
	CP	A, 0EH	;^N
	JR	Z, CONN	;wenn Bildschirmkopie
	CP	A, 080H	;Grafikzeichen?
	JR	C, ASCII	;nein
;
;Ausgabe ein Grafikzeichen
	PUSH	BC	
	LD	IX,(txtab)
	ld	L, (ix+4)
	ld	h, (ix+5); LTX1	
	CALL	SOUT	;Stringausgabe 
	POP	BC	
;
;
LOZ1:	LD	HL,TAB	;Zeichentabelle
	LD	B,0	
	SLA	C	;C=Zeichen
	RL	B	
	SLA	C	
	RL	B	
	SLA	C	
	RL	B	;BC:=BC*8
	ADD	HL,BC	;Beginn Code
	LD	B,8	
LOZ2:	LD	C,(HL)	
	PUSH	HL	
	CALL	LO0	;Ausgabe
	POP	HL	
	INC	HL	
	DJNZ	LOZ2	
	RET		
;
CONN:	PUSH	HL	
	LD	IX,(txtab)
	ld	L, (ix+6)
	ld	h, (ix+7); LTX2	;Grafik anmelden
	CALL	SOUT	
	LD	B,24	;Zeilenanzahl
	LD	HL,0EC00H	
PRN4:	PUSH	BC	
	PUSH	HL	
	ld	L, (ix+8)
	ld	h, (ix+9); LTX3	;neue Zeile
	CALL	SOUT	
	POP	HL	
	LD	B,40	;Spaltenanzahl
PRN3:	PUSH	BC	
	PUSH	HL	
	LD	C,(HL)	
	CALL	LOZ1	;Zeichen ausgeben
	POP	HL	
	POP	BC	
	INC	HL	
	DJNZ	PRN3	
	PUSH	HL	
	ld	L, (ix+10)
	ld	h, (ix+11); LTX4	;Zeilenende
	CALL	SOUT	
	POP	HL	
	POP	BC	
	DJNZ	PRN4	
	ld	L, (ix+12)
	ld	h, (ix+13); LTX5
	CALL	SOUT	
	POP	HL	
	XOR	A	
	RET		
;
;
;
TAB:	EQU	$	

	binclude	"z9001charset.rom"

PEND:	EQU	TAB+800H	

	
	END		
