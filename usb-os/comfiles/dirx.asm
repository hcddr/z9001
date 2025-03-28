; TEST CALL 5 DIR mit Ablage im Speicher
; mit/ohne Filter möglich
; keine Aufbereitung Dateiname 

;-----------------------------------------------------------
;>DIRX
;ASM      MCCOM   1000 37FF FFFF	MC aadr eadr sadr
;ASM      MCHLP G 726F 412F 7373	(HLP ist wenig sinnvoll)
;BASIC    MCCOM   0300 2AFF 0300
;EPROM2A  MCCOM   2A00 2DA1 2A00
;EPROM6A  MCCOM   6A00 6DA1 6A00
;EPROMA2  MCCOM   A200 A5A1 A200
;IDAS     MCCOM   0400 1C00 0400
;INSCRIPT MCCOM   0400 5341 0400
;K6311G1  MCCOM   B600 0000 B600
;K6313G1  MCCOM   B600 0000 B600
;R#BUDGEN BASIC   FELD     25533	Basic Feld-Länge dez.
;R#BUDGEZ BASIC   FELD     19936
;R-AFRI1  BASIC   PROGR.   13684	Basic Programm-Länge dez.
;R-AUTOCR BASIC G PROGR.   04404	G geschütztes BASIC-Programm
;R-BRUCH1 BASIC   PROGR.   07644
;R-BRUCH2 BASIC   PROGR.   14350
;R-BUDGET BASIC   PROGR.   10578         
;-----------------------------------------------------------


	cpu	z80
	org	300h

CSTS:		equ	0F006h		;STATUS CONST
CONSI:		equ	0F009h		;EINGABE ZEICHEN VON CONST

OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H
PRNST:		EQU	0F3E2H	;Stringausgabe
CONBU:		EQU	080h
FCB:		EQU	05Ch
GVAL    	EQU	0F1EAh

INTLN:		equ	0100h		; interner Zeichenkettenpuffer

;-----------------------------------------------------------------------------
	jp	start
	db	"DIRX    ",0
	db	0
;-----------------------------------------------------------------------------
	
;
start:	
		;Parameterauswertung
		;; call	GVAL			; GVAL wurde in GOCPM schon aufgerufen (f. Kommandoname)
		ex	af,af'			; Cy'=1 kein weiterer Parameter in CONBU
		jr	c,dirkdo0		; wenn kein Parameter
		; Parameter Suchstr 
		call	GVAL
		xor	a
		cp	b			; Länge = 0?
		jr	z, dirkdo0
;
dirkdoz:	ld	a,0A0h	;merken, dass Suchmuster übergeben wurde
		jr	dirkdo1
dirkdo0:	ld	a,20h			; alles in Speicher 
dirkdo1:

; DIR einlesen
	;ld	a,0E0h		; mit Suchmuster, keine Ext. anzeigen
	;ld	a,0h		; alles anzeigen
	;ld	a,0A0h		; mit Suchmuster in Speicher 
	;ld	a,020h		; alles in Speicher 
	ld	de,INTLN+1	; Suchmuster
	ld	hl,dirbuf	; Speicherablage
	ld	c,19		; DIRS
	call	5		

; anzeigen

		ld	hl,dirbuf
rda:		ld	a,(hl)
		cp	0
		ret	z	; Ende

		cp	'D'	; Dir?
		
		inc	hl	; übergehe Typ
		ld	a,(hl)	; 1. Zeichen

		jr	nz, file

;Dir übergehen
dir:		; keine Ausgabe
		inc	hl
		ld	a,(hl)
		cp	0
		jr	nz, dir
		inc	hl	; 0-Byte am Ende
		jr	rda
		
; filename anzeigen	
; PRST müsste auch gehen...
file:		
;		push	hl
;		pop	de
;		ld	c,9
;		call	5	
;		call	ocrlf

;;		jr	dir	; hl anpassen

;file öffnen (0-Block)
		; FCB füllen
		call	prepfcb
		ld	c,13	; OPENR
		call	5

		ld	c,14	; CLOSR
		call	5
;		
		push	hl
		call	KDO_FCB
		call	wait
		pop	hl

		jr	rda


dirz:	db	"?HLP",0	; entspricht *.HLP

;-----------------------------------------------------------------------------

prepfcb:
		ld	de,FCB
		ld	b,8
		call	MOV
;ggf "." übergehen
		ld	a,(hl)
		cp	0
		jr	z,prepfcb1
		inc	hl
;ext
prepfcb1:	ld	b,3
		call	MOV
;
		inc	hl	; End 00
		ret

; ab HL B zeichen kopieren
MOV:		ld	a,(hl)
		inc	hl
		cp	0
		jr	z,MOV8
		cp	'.'
		jr	nz,MOV7
MOV8:		dec	hl
		ld	a,0
MOV7:		ld	(de),a
		inc	de
		djnz	MOV
		ret
;-----------------------------------------------------------------------------

AADR:	EQU	FCB+17	;Anfangsadresse
EADR:	EQU	FCB+19	;Endadresse
SADR:	EQU	FCB+21	;Startadresse
SBY:	EQU	FCB+23	;Schutzbyte

; die Adressen wurden in OPENR übertragen
; auf CONBU steht der orig. gelesene Block 

KDO_FCB:	

; wenn Dateityp = 'ZBS' dann Basic

;Ermitteln BASIC-Typ
;
CLIS4:	LD	HL,CONBU
	LD	A,(HL)
	CP	0DAH
	JP	NC, CLMC
	CP	0D3H
	JP	C, CLMC	;evtl MC-Pgm ?
	INC	HL	;3x dasselbe Zeichen ?
	CP	(HL)
	JP	NZ, CLMC
	INC	HL
	CP	(HL)
	JP	NZ, CLMC
;
	SUB	0D3H
	PUSH	AF
;
	LD	HL,CONBU+3
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
	AND	011B
	OR	A
	JR	Z, BAPRO
	CP	1
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
	call	hlkon
BAEND:	CALL	OCRLF
	ret

; sonst MC

;MC-Files
CLMC:	LD	HL,FCB+0
	LD	B,8
	CALL	COOUT	;Anzeige Name
	LD	DE,CLTX6	;Anzeige MC
	CALL	PRNST
	LD	HL,FCB+8
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
	LD	DE,(CONBU+17)	;AADR
	CALL	CLMOT	;ausgeben
	LD	DE,(CONBU+19)	;EADR
	CALL	CLMOT
	LD	DE,(CONBU+21)	;SADR
	CALL	CLMOT
	CALL	OCRLF
	ret
;
CLMOT:	CALL	OSPAC
	ld	C,38		; OUTDE
	call	5
	RET

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


;COOUT Ausgabe ab (HL) (B) Zeichen, nur Buchstaben
COOUT:		LD	A,(HL)
		CP	' '
		JR	C, COUT2		; A<' '
		cp	5Fh			; A<5F
		jr	c, COUT1
COUT2:		LD	A,' '
COUT1:		CALL	OUTA			;Zeichen ausgeben
		INC	HL
		DJNZ	COOUT
		RET
	
;WAIT Unterbrechung Programm, wenn <PAUSE> gedrueckt,
;     weiter mit beliebiger Taste
WAIT:		CALL	CSTS			;Abfrage Status
		OR	A
		RET	Z			;keine Taste gedrueckt
		CALL	CONSI			;Eingabe
		CP	03H			;<STOP>?
		;;JP	Z, GOCPM
		jr	z,wait0
;
		CP	013H			;<PAUSE>?
		RET	NZ			;nein
		CALL	CONSI			;Eingabe
		RET
;Ende
wait0:		ld	hl,(200h-2)		;GOCPM
		jp (hl)

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
;	ld	(de),a   
	CALL	OUTA
	inc	de
	ret              

; Speicher für DIR-Einträge
dirbuf	equ	$

	end	0ffffh
