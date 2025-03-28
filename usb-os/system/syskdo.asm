;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M-Modul)
; (c) V. Pohlers 2011
; letzte Änderung 12.01.2012
; 10.10.2018 load/save haben neuen letzten Parameter. Wenn <> 0, wird der Kopfblock
;            0 nicht geschrieben bzw. der erste Block nicht gelesen (usb/dosx, fcb+24)
; 08.05.2023 in/out mit 16 Bit
;------------------------------------------------------------------------------
; Systembank: diverse Kommandos
;------------------------------------------------------------------------------


;******************************************************************************
;vom z1013
;******************************************************************************


;Kommandoparameter aufbereiten

KDOPAR:		LD	DE,CONBU+2
		CALL	SPACE			;Leerzeichen uebergehen
		LD	A,(DE)
		CP	A, ':'			;die alten Werte nehmen ?
		RET	Z
		CALL	INHEX
		LD	(ARG1),HL		;neue Argumente holen
		CALL	INHEX
		LD	(ARG2),HL
		CALL	INHEX
		LD	(ARG3),HL
		CALL	INHEX
		LD	(ARG4),HL
;
PARA:		LD	HL,(ARG1)
		LD	DE,(ARG2)
		LD	BC,(ARG3)
		LD	A,(ARG4)
		RET
;
;-------------------------------------------------------------------------------
;fuehrende Leerzeichen ueberlesen
;-------------------------------------------------------------------------------
;
SPACE:		LD	A,(DE)
		CP	A, ' '
		RET	NZ
		INC	DE
		JR	SPACE
;
;-------------------------------------------------------------------------------
;letzen vier Zeichen als Hexzahl konvertieren
;und in DATA ablegen
;-------------------------------------------------------------------------------
;

KONVX:		CALL	SPACE
		XOR	A
		LD	HL,DATA
		LD	(HL),A			;DATA=0
		INC	HL
		LD	(HL),A
KON1:		LD	A,(DE)
		DEC	HL
		SUB	30H			;Zeichen<"0"?
		RET	M
		CP	A, 0AH			;Zeichen<="9"?
		JR	C, KON2
		SUB	7
		CP	A, 0AH			;Zeichen<"A"?
		RET	M
		CP	A, 10H			;Zeichen>"F"?
		RET	P
KON2:		INC	DE			;Hexziffer eintragen
		RLD
		INC	HL
		RLD
		JR	KON1			;naechste Ziffer
;
;-------------------------------------------------------------------------------
;Konvertierung ASCII-Hex ab (DE) --> (HL)
;-------------------------------------------------------------------------------
;
INHEX:		PUSH	BC
		CALL	KONVX			;Konvertierung
		LD	B,H			;BC=HL=DATA
		LD	C,L
		LD	L,(HL)			;unteres Byte
		INC	BC
		LD	A,(BC)
		LD	H,A			;oberes Byte
		OR	L			;Z-Flag setzen
		POP	BC
		RET
;
;-------------------------------------------------------------------------------
;Ausgabe String bis Bit7=1
;-------------------------------------------------------------------------------
;
PRST7:		EX	(SP),HL			;Adresse hinter CALL
PRS1:		LD	A,(HL)
		INC	HL
		PUSH	AF
		and	7FH
		CALL	OUTA
		POP	AF
		BIT	7,A			;Bit7 gesetzt?
		JR	Z, PRS1			;nein
		EX	(SP),HL			;neue Returnadresse
		RET
;
;-------------------------------------------------------------------------------
;Eingabe einer Zeile mit Promptsymbol
;-------------------------------------------------------------------------------
;
INLIN:		CALL	PRST7
		DB	" #"
		DB	' '+80H
		LD	C,10			; RCONB
		LD	DE,CONBU
;
		LD	A,80
		LD	(DE),A			;initialisieren max. Zeichenzahl
		CALL	5
		ret	c
		; Leerzeichen + 0 ans Pufferende
		inc	de			;de=CONBU+1
		ld	a,(de)			; gelesene Anzahl
		add	a,e
		ld	e,a			;de=CONBU+1+Länge=ende
		ld	a,' '			; 00-Byte
		inc	de			;de=Ende+1
		ld	(de),a
		ld	a,0			; 00-Byte
		inc	de			;de=Ende+1
		ld	(de),a
		RET
;
;-------------------------------------------------------------------------------
;Speicherinhalt anzeigen
;DUMP von [bis]
;-------------------------------------------------------------------------------
;
D_KDO:		call	KDOPAR
; ARG2=0? Dann ARG1
		ld	a,d
		or	e
		jr	nz, DKO1
		ld	(ARG2), hl
DKO1:		LD	DE,(ARG2)
		SCF
		PUSH	HL
		SBC	HL,DE
		POP	HL
		RET	NC			;wenn EADR<AADR
		call 	OuTHL
		call	ospac
		LD	B,8
		push	hl
DKO2:		call	ospac
		LD	A,(HL)
		call	OuTHX
		LD	A,(HL)
		INC	HL
		DJNZ	DKO2
		call	ospac
		call	ospac
		POP	HL
		call	c_white
		LD	B,8
		CALL	COOUT			;Ausgabe ASCII
		call	c_gruen
		CALL	OCRLF			;neue Zeile
		push	hl
		CALL	WAIT			;Bei STOP -> GOCPM
		pop	hl
		JR	DKO1			; wenn nicht STOP
;
;-------------------------------------------------------------------------------
;Speicherbereich mit Byte beschreiben
; FILL von bis wert
;-------------------------------------------------------------------------------
;
K_KDO:		call	KDOPAR
		; test auf von bis = 0000 0000
		ld	a,h
		or	l
		or	d
		or	e
		jr	nz,K_KDO1
		; alles 0? dann Default-Bereich
		ld	hl,300h
		ld	de,0BFFFh

K_KDO1:		LD	(HL),C			;C=Fuellbyte
		PUSH	HL
		XOR	A
		EX	DE,HL
		SBC	HL,DE
		LD	B,H
		LD	C,L			;BC=Laenge
		POP	HL
		LD	D,H
		LD	E,L
		INC	DE
		LDIR
		RET
;
;-------------------------------------------------------------------------------
;Speicherbereich verschieben
; TRANS von nach laenge
;-------------------------------------------------------------------------------
;
T_KDO:		call	KDOPAR
		XOR	A
		PUSH	HL
		SBC	HL,DE
		POP	HL
		JR	C, TKO1			;wenn Zieladr. groesser
		LDIR				;Vorwaertstransfer
		RET
TKO1:		ADD	HL,BC
		EX	DE,HL
		ADD	HL,BC
		EX	DE,HL
		DEC	HL
		DEC	DE
		LDDR				;Rueckwaertstransfer
		RET
;
;
;-------------------------------------------------------------------------------
;Programm starten
;RUN adr [bank]
;-------------------------------------------------------------------------------
;
J_KDO:		call	KDOPAR
		jp	(HL)			;und Pgm. starten
;

;
;-------------------------------------------------------------------------------
;Portein- und -ausgabe
;-------------------------------------------------------------------------------
;

I_KDO:		CALL	KDOPAR
;		LD	A,L			;Portadresse
;		LD	C,A
		ld	c,l			;Portadresse 16 bit
		ld	b,h
		IN	a,(C)
		call	OUTHX
		call	ocrlf
		RET

O_KDO:		CALL	KDOPAR
;		LD	A,L			;Portadresse
;		LD	C,A
		ld	c,l			;Portadresse  16 bit
		ld	b,h
		LD	A,E			;Wert
		OUT	(C),A
		RET
;
;-------------------------------------------------------------------------------
;Speicherinhalt modifizieren
;-------------------------------------------------------------------------------
;
MEM:		CALL	KDOPAR
MEM1:		call	OuTHL			;Ausgabe Adresse
		PUSH	HL
		call	OSPAC			;Leerzeichen
		LD	A,(HL)
		call	OuTHX			;Ausgabe Byte
		CALL	INLIN
		jr	C,memend		; Ende bei Stop
		LD	DE, CONBU+2		; 1. Zeichen
		LD	A,(DE)
		EX	AF, AF'			;'
		POP	HL
		DEC	HL
MEM2:		INC	HL
		PUSH	HL
		CALL	INHEX
		JR	Z, MEM4			;wenn 0, d.h. Nullbyte oder Trennzeichen
MEM3:		LD	A,L
		POP	HL
		LD	(HL),A
		CP	A, (HL)			;RAM-Test
		JR	Z, MEM2			;i.O.
		call	PRST7
		DB	"ER"
		DB	' '+80H
		JR	MEM1
;
MEM4:		LD	A,(DE)			;Test nachfolgendes Zeichen
		CP	A, ' '			;wenn ja --> Z=1
		JR	Z, MEM3
		POP	HL
		INC	HL
		LD	(ARG2),HL		;1. nichtbearb. Adr.
		CP	A, ';'
		RET	Z			;Return, wenn ";" gegeben
		EX	AF, AF'			;'
		cp	a, ' '			;Leer-Zeile?
		JR	z, MEM1			;ja
		cp	a, 0			;Leer-Zeile?
		JR	z, MEM1			;ja
		DEC	HL
		CP	A, 'R'			;"R" gegeben?
		JR	NZ, MEM1		;nein
		DEC	HL			;sonst eine Adresse
		JR	MEM1			;zurueck
;
memend		pop	hl
		ret
;
;-------------------------------------------------------------------------------
;EOR anzeigen/setzen
;-------------------------------------------------------------------------------
;
EOR:		CALL	KDOPAR
		ld	a,h
		or	l
		jr	z,eor1
		ld	(36h),hl
eor1:		ld	hl,(36h)
		call	PRST7
		db	"EOR",'='+80h
		call	OuTHL			;Ausgabe Adresse
		call	ocrlf
		RET
;
;-------------------------------------------------------------------------------
;SAVE aadr eadr [sadr] [1], Filename "Name[.Typ]" wird erfragt
;SAVE (ohne Parameter) aktuellen FCB-Inhalt nutzen
;-------------------------------------------------------------------------------
;
KDO_SAVE:	CALL	KDOPAR
		
		or	a			; 4. Parameter
		jr	z, kdo_save0
		ld	a,'N'
		ld	(fcb+24), a
kdo_save0:	
		ld	a,h		; aadr = 0 (d.h. keine Parameter)?
		or	l
		push	af
		call	z,kdo_fcb
		pop	af
		jr	z,kdo_save2	; A ist 0,  Dateiname+Typ ist bereits im FCB eingetragen
;
		ld	(fcb+17), hl	; aadr 
		ld	(fcb+19), de	; eadr
		ld	(fcb+21), bc	; sadr 
		ld	a,b		; sadr = 0? Dann aadr nehmen
		or	c
		jr	nz, KDO_SAVE1
		ld	(fcb+21), hl	; sadr 
KDO_SAVE1	ld	a,2		;A=2 => Filename abfragen
kdo_save2:	call	CSAVE
		ret
;
;-------------------------------------------------------------------------------
;LOAD [aadr] [1], Filename "Name[.Typ]" wird erfragt
;-------------------------------------------------------------------------------
;
KDO_LOAD:	CALL	KDOPAR		; hl := aadr

		ld	a,e		; 2. Parameter
		or	a
		jr	z, kdo_load0
		ld	a,'N'
		ld	(fcb+24), a
kdo_load0:

		ld	a,2		;A=2 => Filename abfragen
		CALL	cload
		ret
;
;-------------------------------------------------------------------------------
;FCB
;-------------------------------------------------------------------------------
;
KDO_FCB:	ld	hl,fcb
		;Dateiname
		ld	b,8
		call	COOUT
		call	ospac
		;Dateityp
		ld	b,3
		call	COOUT
		call	ospac
		;aadr
		ld	hl,(FCB+17)
		call	OUTHL
		call	ospac
		;eadr
		ld	hl,(FCB+19)
		call	OUTHL
		call	ospac
		;sadr
		ld	hl,(FCB+21)
		call	OUTHL
		call	ospac
		;ende
		call	OCRLF
		or	a
		ret
	