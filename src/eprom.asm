; File Name   :	EPROM2A.ROM
; Format      :	Binary file
; Base Address:	0000h Range: 2A00h - 2E00h Loaded length: 0400h

; EPROM-Software f¸r Z9001 Programmier-Modul 690 023.6
; (c) robotron 1984/85
; reass: Volker Pohlers 16.08.2008; letzte ƒnderung: 19.08.2008 19:42

		cpu	Z80
		
		include	z9001.inc

; CALL5
CONSI		 = 1			; Eingabe eines	Zeichens von CONST
CONSO		 = 2			; Ausgabe eines	Zeichens zu CONST
READI		 = 3			; Eingabe eines	Zeichens von READ
GETST		 = 6			; Abfrage der Spielbebel
PRNST		 = 9			; Ausgabe einer	Zeichenkette zu	CONST
CSTS		 = 0Bh			; Abfrage Status CONST
GETCU		 = 11h			; Abfrage logische und physische Cursoradresse
SETCU		 = 12h			; Setzen logische Cursoradresse
DCU		 = 1Dh 			; Lˆschen Cursor


;------------------------------------------------------------------------------
; Ports
; die Datenleitungen gehen an A7..A0 der EPROM-Fassung und werden bei 
; Port D4(..D7) aktiv
;------------------------------------------------------------------------------


PIOAD		equ	0D0h		; PIO A Daten
					; 7 6 5 4 3 2 1 0
					; D7    ..      D0 an EPROM-Fassung

PIOBD		equ	0D1h		; PIO B Daten
					; 7 6 5 4 3 2 1 0
					;   | |   | | | |
					;   | |   | A10..A8 an EPROM-Fassung
					;   | |   PGM-Impuls aktivieren (max. 80ms per Monoflop, Pin /CS an EPROM-Fassung)
					;   | PGM-Spannung zuschalten (0: 24V bzw. 1: 5V an Pin Vpp an EPROM-Fassung)
					;   Pin /OE an EPROM-Fassung ( 1 beim Programmieren, 0 beim Lesen)

PIOAS		equ	0D2h		; PIO A Kommando

PIOBS 		equ	0D3h		; PIO B Kommando

PORTA		equ	0D4h		; A7..A0 der EPROM-Fassung

;------------------------------------------------------------------------------
; Achtung: es werden die RST 8..20 genutzt!
;------------------------------------------------------------------------------

; die verschiedenen Varianten

start		equ	2A00h		; eprom2a_com.tap der Kassette R0112 bzw. R0113
;start		equ	6A00h		; eprom6a_com.tap der Kassette R0112 bzw. R0113
;start		equ	0A200h		; eproma2_com.tap der Kassette R0112 bzw. R0113
;start		equ	0A000h		; EPROM M502
;start		equ	0E000h		; EPROM M502

; die Version des IDAS-Moduls weicht etwas ab, da hier noch der Startcode f¸r ZM und etwas mehr
; enthalten ist. Der Kern stimmt aber ¸berein.


		org 	start

;------------------------------------------------------------------------------
; Hauptprogramm
;------------------------------------------------------------------------------

		jp	eprom
aEprom2a:	db 	"EPROM\{hi(start)} ",0
		db    	0

eprom:		ld	a, 11111111b
		out	(PIOAS), a	; PIO-Mode Bit-E/A
		out	(PIOAS), a	; alle Bits Eingabe
		out	(PIOBS), a	; PIO-Mode Bit-E/A
		xor	a
		out	(PIOBS), a	; alle Bits Ausgabe
		ld	a, 10110111b	; EPROM lesen, PGM-Spannung aus, PGM-Impuls aus
		out	(PIOBD), a

; RST-Routinen initialisieren
		ld	hl, b_setcu
		ld	(9), hl
		ld	hl, b_conso
		ld	(11h), hl
		ld	hl, b_prnst
		ld	(19h), hl
		ld	hl, b_dcu
		ld	(21h), hl
		ld	a, 0C3h		; Code JP
		ld	(8), a		; rst 8	- SCU
		ld	(10h), a	; rst 10 - CONSO
		ld	(18h), a	; rst 18 - PRNST
		ld	(20h), a	; rst 20 - DCU
;
; Hauptschleife
eprom1:		ld	e, 0Ch
		rst	10h		; CONSO
		ld	de, aReadProgEndRPE ; "\x14\x02READ/PROG/END (R/P/E) :	"
		rst	18h		; PRNST
eprom2:		call	b_consi
		cp	'P'             ; "PROG"
		jr	z, prog
		cp	'R'             ; "READ"
		jr	z, read
		cp	'E'             ; "END"
		jr	nz, eprom2
		ld	e, 0Ch		; CLS
		rst	10h		; CONSO
		ret

;------------------------------------------------------------------------------
; Systemrufe, werden von RST 8..20 angesprungen
;------------------------------------------------------------------------------

b_setcu:	ld	c, SETCU	; Setzen logische Cursoradresse
		jr	bdos

b_conso:	ld	c, CONSO	; Ausgabe eines	Zeichens zu CONST
		jr	bdos

b_prnst:	ld	c, PRNST	; Ausgabe einer	Zeichenkette zu	CONST
		jr	bdos

b_dcu:		ld	c, DCU		; Lˆschen Cursor
		jr	bdos

b_consi:	ld	c, CONSI	; Eingabe eines	Zeichens von CONST
bdos:		jp	5		; System-BDOS Call


;------------------------------------------------------------------------------
; READ: EPROM auslesen
;------------------------------------------------------------------------------

read:		ld	de, aReading	; "\x14\x03READING\n\r\n"
		rst	18h		; PRNST
		call	gadr		; Abfrage der Speicheradressen
					; ret DE: Startadr. EPROM
					;     HL: Startadr. RAM
					;     BC: Anzahl Bytes
		cp	0Dh		; <ENTER>
		jr	nz, eprom1
;
		push	hl
		push	bc
read1:		call	gbyte		; get byte: Byte lesen von (DE)	nach A
		ld	(hl), a
		cp	(hl)
		jr	nz, read2
		inc	hl
		inc	de
		dec	bc
		ld	a, b
		or	c
		jr	nz, read1
		jp	prog6
;
read2:		ld	hl, aRamNotLoaded ; "\x14\x01 RAM NOT LOADED\n\r"
		jp	prog8

;------------------------------------------------------------------------------
; get byte: Byte lesen von (DE)	nach A
;------------------------------------------------------------------------------

gbyte:		ld	a, e
		out	(PORTA), a	; A7..A0
		di
		ld	a, d		; A10..A8
		or	00100000b	; EPROM lesen, PGM-Spannung 5V, kein PGM-Impuls
		out	(PIOBD), a
		in	a, (PIOAD)	; Datenbits einlesen
		ei
		ret

;------------------------------------------------------------------------------
; PROG: EPROM programmieren
;------------------------------------------------------------------------------

prog:		ld	de, aProgramming ; "\x14\x03PROGRAMMING"
		rst	18h		; PRNST
		call	gadr		; Abfrage der Speicheradressen
					; ret DE: Startadr. EPROM
					;     HL: Startadr. RAM
					;     BC: Anzahl Bytes
		cp	0Dh		; <ENTER>
		jr	nz, eprom1
;
		push	hl
		push	de
		push	bc
; EPROM testen		
prog1:		call	gbyte		; get byte: Byte lesen von (DE)	nach A
		cp	(hl)		; Vergleich mit zu brennendem Byte
		jr	z, prog2
		set	7, b		; Bit7: ungleich
prog2:		cp	0FFh
		jr	z, prog3
		set	6, b		; Bit6: leer
		cpl
		and	(hl)
		jr	z, prog3
		set	5, b		; Bit5: nicht kompatibel
prog3:		inc	hl
		inc	de
		dec	bc
		ld	a, b
		and	7
		or	c
		jr	nz, prog1
		ld	a, b
		add	a, a
		ld	de, aEqual	; "\x14\aEQUAL"
		jr	nc, prog4
		cp	80h
		ld	de, aBlank	; "\x14\aBLANK"
		jr	c, prog4
		ld	de, aNotBlank	; "\x14\aNOT BLANK"
		jr	z, prog4
		ld	de, aImpossible	; "\x14\x01IMPOSSIBLE"
prog4:		rst	18h		; PRNST

; programmieren
		ld	de, aProgrammingYN ; "\n\r\n\x14\x02PROGRAMMING	(Y/N) :	"
		rst	18h		; PRNST
		call	b_consi
		ld	e, a
		rst	10h		; CONSO
		pop	bc
		pop	de
		pop	hl
		cp	'Y'
		jr	nz, prog11
		push	hl
		push	bc
		exx
		ld	de, aEnter	; "\n\r\n"
		rst	18h		; PRNST
		ld	de, aWorking	; "\x14\x03	  ***WORKING***\x14\x02\r"
		rst	18h		; PRNST
		rst	20h		; DCU
		exx
prog5:		push	hl
		push	de
		push	bc
		ex	de, hl
		call	outhl		; Anzeige HL hexadezimal
		ld	e, 0Dh
		rst	10h		; CONSO
		rst	20h		; DCU
		pop	bc
		pop	de
		pop	hl
		call	pbyte		; ein Byte programmieren von (HL) an EPROM-Position DE
		cp	(hl)
		call	nz, pbyte	; im Fehlerfall ein zweiter Versuch
		cp	(hl)
		jr	nz, prog7
		inc	hl
		inc	de
		dec	bc
		ld	a, b
		or	c
		jr	nz, prog5
; CRC		
prog6:		ld	de, aCrc	; "\x14\x02CRC = "
		rst	18h		; PRNST
		pop	bc
		pop	de
		call	crc		; CRC berechnen
		ld	de, aReady	; "\x14\x03  ***READY***"
		push	de
		ld	a, 33h		; CRC eines leeren EPROM (alles FF) = 33D7h
		cp	h
		jr	nz, prog9
		ld	a, 0D7h
		cp	l
		jr	nz, prog9
		ld	de, aBlank	; "\x14\aBLANK"
		rst	18h		; PRNST
		jr	prog10
;
prog7:		ld	hl, aNotProgrammabl ; "\x14\x01	NOT PROGRAMMABLE"
prog8:		pop	bc
		ex	(sp), hl
		ex	de, hl
prog9:		call	outhl		; Anzeige HL hexadezimal
prog10:		pop	de
		rst	18h		; PRNST
;
prog11:		ld	a, 10110111b	; EPROM lesen, PGM-Spannung aus, PGM-Impuls aus
		out	(PIOBD), a
		ld	e, 7
		rst	10h		; CONSO
		call	exchg		; Aufforderung zum EPROM-Wechsel
		jp	eprom1

;------------------------------------------------------------------------------
; Texte
;------------------------------------------------------------------------------

aReadProgEndRPE:db 14h,2,"READ/PROG/END (R/P/E) :  ",0
aReading:	db 14h,3,"READING",0Ah
		db 0Dh,0Ah,0
aProgramming:	db 14h,3,"PROGRAMMING"
aEnter:		db 0Ah
		db 0Dh,0Ah,0
aSpaces:	db "              ",0Dh,0
aReady:		db 14h,3,"  ***READY***",0
aEqual:		db 14h,7,"EQUAL",0
aBlank:		db 14h,7,"BLANK",0
aNotBlank:	db 14h,7,"NOT BLANK",0
aImpossible:	db 14h,1,"IMPOSSIBLE",0
aProgrammingYN:	db 0Ah
		db 0Dh,0Ah
		db 14h,2,"PROGRAMMING (Y/N) : ",0
aCrc:		db 14h,2,"CRC = ",0
aRamNotLoaded:	db 14h,1," RAM NOT LOADED",0Ah
		db 0Dh,0
aNotProgrammabl:db 14h,1," NOT PROGRAMMABLE",0
aWorking:	db 14h,3,"       ***WORKING***",14h,2,0Dh,0
aEpromRamBytes:	db 14h,2,"EPROM:        RAM:       BYTES:",0
aExchangeEprom:	db 14h,6,"EXCHANGE EPROM",0Dh,0

;------------------------------------------------------------------------------
; ein Byte programmieren von (HL) an EPROM-Position DE
;------------------------------------------------------------------------------


pbyte:		ld	a, 00001111b
		out	(PIOAS), a	; PIO-Modus 0, Byte-Ausgabe
		ld	a, (hl)
		out	(PIOAD), a	; zu schreibendes Datenbyte anlegen
		ld	a, e
		out	(PORTA), a	; Adressbits A7..A0
		di
		ld	a, d
		or	01000000b	
		out	(PIOBD), a	; EPROM Programmieren
		push	bc
; Zeitschleife t_css >= 2µs
		ld	b, 0
pbyte1:		ld	ix, (0)		; dauert 20 Takte
		djnz	pbyte1
;
		or	00001000b
		out	(PIOBD), a	; PGM-Impuls
; Zeitschleife t_pw = 50ms
		ld	a, 35
pbyte2:		ld	b, 249
pbyte3:		dec	b		; 4 Takte
		jp	nz, pbyte3	; 10 Takte
					; also insg. 249*(4+10)=3486 Takte, durch 2.4576 Mhz ~ 1,4ms
		dec	a		; ‰uﬂere Schleife
		jp	nz, pbyte2	; 35*1,4ms ~ 50ms
;
		pop	bc
		ld	a, d
		or	01000000b	; EPROM Programmieren, PGM-Impuls aus
		out	(PIOBD), a
; Kontrolllesen
		ld	a, 11111111b
		out	(PIOAS), a	; PIO-Mode Bit-E/A
		out	(PIOAS), a	; alle Bits Eingabe
		ld	a, e
		out	(PORTA), a	; A0..A7 ausgeben
		ld	a, d
		out	(PIOBD), a	; EPROM lesen, A8..A10 ausgeben
		in	a, (PIOAD)	; Datenbits einlesen
		ei
		ret

;------------------------------------------------------------------------------
; Abfrage der Speicheradressen
; ret DE: Startadr. EPROM
;     HL: Startadr. RAM
;     BC: Anzahl Bytes
;------------------------------------------------------------------------------


gadr:		ld	de, aEpromRamBytes ; "\x14\x02EPROM:        RAM:       BYTES:"
		rst	18h		; PRNST
gadr1:		ld	hl, 0		; Standardwert EPROM 0000H
		ld	a, 7		; 1 Zeichen hinter "EPROM:"
		call	atoh		; Anzeige HL hexadezimal an Position A in aktueller Zeile
					; Eingabe neuer	Wert
		jr	c, oCRLF	; Ausgabe CRLF
		ld	a, h
		and	011111000b	; nicht erlaubte Bits (H muss <= 7 bleiben)
		jr	nz, gadr1	; Wert zu groﬂ
		push	hl
		ld	de, 1000h	; Standardwert RAM 1000H
		add	hl, de		; + EPROM-Offset
		ld	a, 19		; 1 Zeichen hinter "RAM:"
		call	atoh		; Anzeige HL hexadezimal an Position A in aktueller Zeile
					; Eingabe neuer	Wert
		pop	de
		jr	c, oCRLF	; Ausgabe CRLF
gadr2:		push	hl
		push	de
		ld	hl, 800h	; Standardwert BYTES 800H
		and	a
		sbc	hl, de
		ld	a, 32		; 1 Zeichen hinter "BYTES:"
		call	atoh		; Anzeige HL hexadezimal an Position A in aktueller Zeile
					; Eingabe neuer	Wert
		ld	b, h
		ld	c, l
		pop	de
		pop	hl
		jr	c, oCRLF	; Ausgabe CRLF
		dec	bc
		ld	a, c
		add	a, e
		ld	a, b
		adc	a, d
		jr	c, gadr2
		and	011111000b	; nicht erlaubte Bits (H muss <= 7 bleiben)
		jr	nz, gadr2	; Wert zu groﬂ
		inc	bc
		call	exchg		; Aufforderung zum EPROM-Wechsel
		ret

oCRLF:		ld	de, aEnter	; Ausgabe CRLF
		rst	18h		; PRNST
		ret
;------------------------------------------------------------------------------
; Anzeige HL hexadezimal an Position A in aktueller Zeile
; Eingabe neuer	Wert
;------------------------------------------------------------------------------

atoh:		ld	c, GETCU	; Abfrage logische und physische Cursoradresse
		call	5
		ld	e, a
atoh1:		rst	8		; SCU
		push	de
		call	outhl		; Anzeige HL hexadezimal
		pop	de
		call	b_consi		; Einlesen einer Ziffer
		sub	30h ; '0'
		cp	0Ah
		jr	c, atoh2	; wenn 0..9
		sub	11h
		cp	6
		jr	nc, atoh3	; wenn nicht A..F
		add	a, 0Ah
atoh2:		add	hl, hl
		add	hl, hl
		add	hl, hl
		add	hl, hl
		add	a, l
		ld	l, a
		jr	atoh1
atoh3:		cp	0CCh 	      	; CCh+30h+11h = 10Dh, also <ENTER>
		ret	z		; Ende bei <ENTER> mit Z=0
		cp	0C2h		; C2h+30h+11h = 103h, also <STOP>
		jr	nz, atoh1
		scf			; Ende bei <STOP> mit Cy=1
		ret

;------------------------------------------------------------------------------
; Anzeige HL hexadezimal
;------------------------------------------------------------------------------

outhl:		call	outhl1		; Anzeige HL hexadezimal
		ld	e, 'H'
		rst	10h		; CONSO
		ret

outhl1:		ld	d, h
		call	outa		; Anzeige A hexadezimal
		ld	d, l

; Anzeige A hexadezimal

outa:		ld	a, d
		rrca
		rrca
		rrca
		rrca
		call	outa1
		ld	a, d
outa1:		and	0Fh
		cp	0Ah
		jr	c, outa2
		add	a, 7
outa2:		add	a, 30h 		; '0'
		ld	e, a
		rst	10h		; CONSO
		ret

;------------------------------------------------------------------------------
; CRC berechnen
;------------------------------------------------------------------------------

crc:		ld	hl, 0FFFFh
crc1:		ld	a, (de)
		xor	h
		ld	h, a
		rrca
		rrca
		rrca
		rrca
		and	0Fh
		xor	h
		ld	h, a
		rrca
		rrca
		rrca
		push	af
		and	1Fh
		xor	l
		ld	l, a
		pop	af
		push	af
		rrca
		and	0F0h
		xor	l
		ld	l, a
		pop	af
		and	0E0h
		xor	h
		ld	h, l
		ld	l, a
		inc	de
		dec	bc
		ld	a, b
		or	c
		jr	nz, crc1
		ret

;------------------------------------------------------------------------------
; Aufforderung zum EPROM-Wechsel
;------------------------------------------------------------------------------

exchg:		push	de
		push	bc
		ld	de, aEnter	; "\n\r\n"
		rst	18h		; PRNST
exchg1:		ld	de, aExchangeEprom ; "\x14\x06EXCHANGE EPROM\r"
		rst	18h		; PRNST
		rst	20h		; DCU
		call	wait
		ld	de, aSpaces	; "		 \r"
		rst	18h		; PRNST
		rst	20h		; DCU
		call	wait
		jr	z, exchg1	; solange bis Taste gedrÅckt
		call	b_consi
		pop	bc
		pop	de
		ret

; Warteschleife, vorzeitiger Abbruch bei Tastendruck (Z=1)

wait:		ld	d, 4
wait1:		ld	b, 0FFh
wait2:		ld	c, CSTS		; Abfrage Status CONST
		call	5
		or	a
		ret	nz
		djnz	wait2
		dec	d
		jr	nz, wait1
		ret



		end
