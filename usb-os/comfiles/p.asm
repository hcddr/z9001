	cpu	z80
;-------------------------------------------------------
;
;ASCII- Druckertreiber für Z9001
;Unterstützt Bildschirmkopie Ctrl-N
;V.Pohlers, 2009
;
;-------------------------------------------------------
; Anschluss: V24-Modul (9600Baud, 8N1)

; Drucker-Modul
SIOCA:	EQU	0B2H	
SIODA:	EQU	0B0H	
CTC0:	EQU	0A8H	

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
;02.03.2019 10:47:50
AUP2		equ	0EFDFh		; Eigentlich Adresse UP2-Treiber für PUNCH
AUR2		equ	0EFD7h		; Eigentlich Adresse UR2-Treiber für READER
					; hier f. Re-Init ON_COLD genutzt
;
ESC	equ	27
;

;-------------------------------------------------------
	ORG	0BF00H	
;	ORG	0BE00H	
;
PBEG:	
	JP	INIT	
INTX0:	DB	"P       ",0	
;	JP	TEST
;	DB	"T       ",0	
	DB	0	

;-------------------------------------------------------

;test	ld	e,'X'
;	ld	c,5
;	jp	5
	
;
INIT:	LD	HL,PBEG-101H	
	LD	(EOR),HL	
	LD	DE,INTX0	;Text
	LD	(TXLST),DE	;Zeichenkette fuer LIST eintragen
	
	; f. Flash-Modul, on_cold
	; autom. reinit. nach Ctrl-C bzw. Warmstart
	ld	hl, init
	ld	(aur2),hl
	
	call	v24init	; v24 init.
	
;
INI1:	LD	HL,TTYL		;TTY-Treiber
	LD	(ATTYL),HL	
	LD	HL,IOBYT	;LIST:=ATTYP
	RES	7,(HL)	
	RES	6,(HL)	
	XOR	A	
	LD	(LISW),A	;kein Copy
;;	LD	(0EFC8h),A	;Cursor an
	AND	A, A	
	RET		

;Treiberfkt FF: Initialisieren und RET
INUP1:	AND	A, A	
	RET		
;

	
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
	
;-------------------------------------------------------
;
;***
;
;Druckertreiber
; in A - Kommando
;    C - Zeichen
;
TTYL:	INC	A	;A=0FFH Drucker init. ?
	Jp	Z, INUP1	;Initialisieren und RET
	DEC	A	;A=0 Status?
	JR	NZ, LOA	;sonst Zeichenausgabe
;
; V24
;Treiberfkt 0: Status
LOD1:	AND	A, A	;Statusabfrage
	LD	A,10H	
	OUT	SIOCA, A	
	IN	A, SIOCA	
	BIT	5,A	
	RET	NZ	
	SCF		
	RET		;Status zurueck

;
;Treiberfkt 1: Zeichenausgabe
;direkte Ausgabe 
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

; Stop-Request?
STPRQ:	CALL	DECO0	
	EI		
	SUB	3	
	OR	A		 ;>STOP< gedrueckt?
	RET	NZ	
	LD	(KEYBU),A	
	SCF		
	RET		
;-------------------------------------------------------
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
;in C Zeichen
LOA:	
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
	
	cp	a,0ah
	JR	z,ASCOT	
		
	cp	a,0dh
	JR	z,ASCOT	
	
	;sonst
	and	a,a	;cy=0
	ret
;
ASCOT:	LD	C,A	
	JP	LO0	;Ausgabe an Drucker
;-------------------------------------------------------
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
;-------------------------------------------------------

PEND:	EQU	$
	
	END		
