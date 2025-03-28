;------------------------------------------------------------------------------
; Zeichen-Gerätetreiber f. Mini-CPM
; Nutzt das OS-I/O-Konzept nicht!
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
;CONST		equ	chrdrv._const	; 
;CONIN		equ			; 
;CONOUT		equ	chrdrv._conout	; 
;LIST		equ			; 
;PUNCH		equ			; 
;READER		equ			; 
;LISTST		equ			; 

;Ports
CTC0		equ	80h	; System CTC0
CTC1		equ	81h	; System CTC1
CTC3		equ	83h	; System CTC3

PIO1AD		equ	88h	; System PIO1AD
PIO1BD		equ	89h	; System PIO1BD	Anwenderport
PIO1BC		equ	8bh	; System PIO1BC Anwenderport

keybu	equ	0025h

	elseif codesec=biossec


;CONIN:
chrdrv.CONIN0:		;console character into register a
		LD	A,(KEYBU)	;TASTATUREINGABE
		OR	A
		JR	Z,chrdrv.CONIN0	;WARTEN AUF ZEICHEN, 01 Eingabe Zeichen
		PUSH	AF
		XOR	A
		LD	(KEYBU),A	;TASTATURPUFFER LOESCHEN
		POP	AF
;;		AND	7FH	;strip parity bit
		RET
;

CONST:		LD	A,(KEYBU)	;STATUS ABFRAGEN
		or	a
		ret	z
		ld	a, 0FFh
		ret
;
LIST:		;list character from register c
		RET		;null subroutine
;
LISTST:		;return list status (0 if not ready, 1 if ready)
		XOR	A	;0 is always ok to return
		RET
;
PUNCH:		;punch character from register c
		LD	A,C	;character to register a
		RET	;null subroutine
;
;
READER:		;read character into register a from reader device
		LD	A,1AH	;enter end of file for now (replace later)
		AND	7FH	;remember to strip parity bit
		RET
;

;-----------------------------------------------------------------------------
; erweiterter Treiber für CONIN
; Beep + Gross<=>Klein-Wandlung
;-----------------------------------------------------------------------------

CONIN:		

; Kommandocode 'Eingabe Zeichen'
chrdrv.uttyc2:	call	chrdrv.CONIN0
		call	chrdrv.bell
		ld	hl, chrdrv.lstflag
		cp	1Ch		; jetzt LIST-Taste gedrückt?
		jr	nz, chrdrv.uttyc3	; nein
		ld	a, 1		; LIST merken in lstflag
		ld	(hl), a
		jr	chrdrv.uttyc2		; und nächstes Zeichen holen

chrdrv.uttyc3:	bit	0, (hl)		; listflag gesetzt?
		jr	z, chrdrv.uttyc4	; nein -> weiter mit Groß<->Klein
		ld	(hl), 0		; listflag rücksetzen

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
chrdrv.uttyc5:	cp	'a'
		ret	c
		cp	'z'+1
		ret	nc
		sub	20h
		ret
chrdrv.uttyc6:	or	a
		ret

;
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
; console character out
;-----------------------------------------------------------------------------

CONOUT:		;console character output from register c

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
;		ld	hl, (0F069h)	; Z9001-OS: Adr. Setzen log. Cursor
		ld	hl, 0F8F1h	; Z9001-OS: CRT-Treiber
		push	hl		; auf Stack
;		ld	l, 3		; Anfangswert fuer Cursorrufe (BOS)
		ld	a, 6		; Funktion: SETCU
		ld	de, (chrdrv._con_escp1)	; DE := Zeile/Spalte
		ret			; und Cursor setzen
;
chrdrv._conout1:
		ld	hl, chrdrv._con_escp2	; Pointer in Liste
		ld	(chrdrv._con_escp), hl	; auf Anfang-1 setzen
;
chrdrv._conout2:
		or	a
		ret
;
chrdrv._conout3:
		ld	a, (25h)	; KEYBU	(Tastaturbuffer)
		cp	13h		; PAUSE-Taste?
		jr	nz, chrdrv._conout4
		push	bc
;		call	0F009h		; Z9001-OS: Eingabe Zeichen von CONST, PAUSE-Taste holen
;		call	0F009h		; Z9001-OS: Eingabe Zeichen von CONST, Warten auf Tastendruck
		call	chrdrv.CONIN0		; PAUSE-Taste holen
		call	chrdrv.CONIN0		; Warten auf Tastendruck
		pop	bc
chrdrv._conout4:	
		ld	a, 1Bh		; ESC?
		cp	c
;;		jp	nz, 0F00Ch	; Z9001-OS: Ausgabe Zeichen zu CONST
;		jp	nz, 0F97DH	; OC	

		LD	HL,17h		; COLSW
		jp	nz, 0F88Dh	; Z9001-OS: OCHAR Ausgabe Zeichen C
; Cursor-Positionierung 1Bh Zeile+128 Spalte+128 (kompatibel zum PC 1715)
		ld	a, 2		;escape flag setzen
		ld	(chrdrv._con_esc), a
		jr	chrdrv._conout1


;-----------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------


	elseif codesec=ubiossec
;RAM

chrdrv.lstflag:	db	0		; wenn vorher LIST gedrückt, dann steht hier 1 bzw. 1Ch

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

		ld	a, hi(intvectab); Interrupttabelle
		ld	i, a		; Interruptregister setzen
		im	2
		
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


chrdrv.BOOTMSG	macro
                db      0dh,0ah
                dw	gelb
                db      "I/O-Devices:", 0Dh, 0Ah
                dw	gruen
                db      "CON: Beep + Gross<=>Klein", 0Dh, 0Ah
		endm

	endif
