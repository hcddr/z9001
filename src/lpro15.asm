;-----------------------------------------------------------------------------
; File Name   :	hobby\z9001 lpro\lpro15.bin
; Format      :	Binary file
; Base Address:	0000h Range: 8800h - A000h Loaded length: 1800h
; reass 10.04.2008 vpohlers
;-----------------------------------------------------------------------------
;s. S E R V I C E REPARATURANLEITUNG HEIMCOMPUTER robotron Z9001
;6.7. Das Testprogramm LPRO (Gesamtprüfung)
;- Der Testprogramm-Modul ist in den Modulschacht einzustecken.
;- Über die Tastatur ist LPRO einzugeben und mit <ENTER> abzuschließen.
;- Die Prüfstecker X2 und X7 sind einzustecken.
;- Die Bedienerführung erfolgt über den Bildschirm!
;-----------------------------------------------------------------------------

		cpu	z80
		include	z9001.inc

; Interruptvektoren
		org	240h
iv_ctc0:	ds 2			; Interruptvekor CTC0
iv_ctc1:	ds 2			; Interruptvekor CTC1
		ds 2			; Interruptvekor CTC2
iv_ctc3:	ds 2			; Interruptvekor CTC3
iv_pio1a:	ds 2			; Interruptvekor PIO1A
iv_pio1b:	ds 2			; Interruptvekor PIO1B
iv_pio2a:	ds 2			; Interruptvekor PIO2A
iv_pio2b:	ds 2			; Interruptvekor PIO2B


; Arbeitsspeicher
unk_310:	equ	310h		; bitweise sind	die abzuarbeitenden Tests markiert
;		TPROM1	|TPROM2	|TPRAM1	|TPRAM2	|TPRAM3	|TPRAMB	|TPRAMF	|TPCEA	
unk_311:	equ	311h		; weitere Tests
;		TPSPH 	|TPBILD	|TPTAST |TPKAS1	|TPKAS2	|TPFARB |      |
unk_312:	equ	312h		; 2 Byte Zwischenspeicher für SP in sub_839B
unk_316:	equ	316h		; 1 = ROM-Test, 2 = RAM-Test, sonst Null
unk_317:	equ	317h		; '$' - Merker für Fehler bei ROM-Test
unk_318:	equ	318h		; '$' - Merker für Fehler bei RAM-Test
unk_320:	equ	320h		; Gesamtzanzahl der Fehler (3 Byte)
unk_322:	equ	322h		; Gesamtzanzahl der Fehler Teil 2
unk_323:	equ	323h		; Anzahl der Testdurchläufe (main5)
unk_324:	equ	324h		; 2 Byte (sub_82D3)
unk_326:	equ	326h		; (IR_CTC3)
unk_32A:	equ	32Ah		; wird in IR_PIO1B auf 1 gesetzt
unk_330:	equ	330h		; Ende Arbeitsspeicher


;-----------------------------------------------------------------------------
;
;-----------------------------------------------------------------------------


		org 8800h
		jp	lpro
aLpro:		db "LPRO    ",0
		db    0

; Sprungtabelle der einzelnen Tests
tp_tab:		jp	tprom1		; Testprogramm OS F000-FFFF
		jp	tprom2		; Testprogramm ROM-BASIC C000-E7FF
		jp	tpram1          ; Testprogramm RAM 0000-3FFF
		jp	tpram2          ; Testprogramm RAM 4000-7FFF
		jp	tpram3
		jp	tpramb          ; Testprogramm BWS EC00-EFFF
		jp	tpramf          ; Testprogramm Farb-BWS	E800-EBFF
		jp	tpcea           ; Testprogramm CTC u. E/A
		jp	tpsph           ; Testprogramm Tastatur
		jp	tpbild
		jp	tptast
		jp	tpkas1
		jp	tpkas2
		jp	tpfarb

; Prüfsummen von 2K Bereichen
; (vom oberen Speicher nach unten hin)
; "1"
word_8837:	dw 	0C488h		; ROM
		dw 	063B5h
word_883B:	dw 	033E0h		; ROM BASIC
		dw 	0A82Bh
		dw 	086FCh
		dw 	0A12Ah
		dw 	03EA4h
; "2"
		dw 	0B787h		; M504 OS 1.1
		dw 	07BB9h		; M503
		dw 	0FED1h       	; M501 BASIC 84
		dw 	02235h		; M500
		dw 	01109h		; M499
		dw 	00C2Dh		; M498
		dw 	02AA8h		; M497
; "3"
chksum_os12:	dw	06E87h		; Testdaten OS 1.2
		dw	050B8h		; Summe	F000-F7FF
chksum_basic85:	dw	060D0h		; M511 Testdaten BASIC-85
		dw	07934h		; M510 Summe D800-DFFF
		dw	08A08h		; M509 Summe D000-D7FF
		dw	0F72Ch		; M508 Summe C800-CFFF
		dw 	09EA6h		; M507 Summe C000-C7FF
; "8"
		dw 	06E87h       	; BM602 Testdaten OS 1.2          
		dw 	050B8h          ; BM602 Summe F000-F7FF           
		dw 	060D0h          ; Testdaten BASIC-85 (BM602) 
		dw 	07934h          ; Summe	D800-DFFF           
		dw 	08A08h          ; Summe	D000-D7FF           
		dw 	0F72Ch          ; Summe	C800-CFFF           
		dw 	05AA6h          ; Summe C000-C7FF (BM600)

inttab:		jp	loc_9106
		jp	loc_910C
loc_8875:	jp	loc_911A
		jp	loc_9114
		jp	loc_911D
		jp	loc_911B
		jp	loc_911C
		inc	b
		ei
		reti

; Textausgabe
; ab (HL) 1 Word Position, dann	1 Byte Länge Text, dann	Text
; Textausgabe (Pos, Länge, Text)
printx:		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		inc	hl
		push	bc
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		pop	bc
		djnz	printx		; Textausgabe (Pos, Länge, Text)
		ret

;-----------------------------------------------------------------------------
; Testprogramm 
;-----------------------------------------------------------------------------

tptast:		call	bckup_bws
		call	cls		; BWS löschen
		ld	hl, aTastaturpruefp
		ld	b, 8
		call	printx		; Textausgabe (Pos, Länge, Text)
		ld	de, 3A7h
		ld	hl, aBeginnenJ	; "BEGINNEN?   J  "
		call	print		; Textausgabe (HL) an BWS-Position (DE)
tptast1:
		call	consi		; Eingabe 1 Zeichen nach A
		ld	c, a
		cp	0Dh
		jp	z, no_shloc	; ShiftLock aus, Ende
		ld	a, c
		ld	b, 4
		and	b
		jp	nz, tptast1
tptast2:
		call	cls		; BWS löschen
		ld	hl, aTestDerAlphaNu
		ld	b, 4
		call	printx		; Textausgabe (Pos, Länge, Text)
tptast3:
		call	consi		; Eingabe 1 Zeichen nach A
		ld	c, a
		ld	(328h),	a
		cp	0Dh
		jp	z, tptast6
		ld	de, 128h
		ld	hl, 0EC00h
		add	hl, de
		ld	(hl), 20h ; ' '
		ld	a, 80h ; '€'
		and	c
		jr	z, tptast5
		push	hl
		ld	de, 176h
		ld	hl, aGrafikZeichen ; "GRAFIK-ZEICHEN"
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		pop	hl
tptast4:
		ld	de, 5
		add	hl, de
		ld	a, (328h)
		ld	(hl), a
		ld	hl, 0EC00h
		ld	de, 190h
		add	hl, de
		ld	d, h
		ld	e, l
		inc	de
		ld	a, (328h)
		ld	(hl), a
		ld	b, 2
		ld	c, 30h ; '0'
		ldir
		ld	de, 128h
		ld	hl, 0EC00h
		add	hl, de
		ld	(hl), 3Fh ; '?'
		jr	tptast3
tptast5:
		ld	a, 60h ; '`'
		and	c
		jp	z, loc_8A30
		push	hl
		ld	de, 176h
		ld	hl, aAsciiZeichen ; " ASCII-ZEICHEN"
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		pop	hl
		jr	tptast4
tptast6:
		call	cls		; BWS löschen
		ld	hl, aTestDerFunktio
		ld	b, 2
		call	printx		; Textausgabe (Pos, Länge, Text)
		exx
		ld	b, 0
		ld	d, 0Ah
		ld	e, b
		ld	h, 0A1h	; '¡'
		ld	l, b
		exx
		ld	hl, aStop	; "\"STOP\"  "
tptast7:
		ld	b, 0
		exx
		ld	a, 2
		cp	e
		exx
		jp	z, loc_8B03
		ld	c, 8
tptast8:
		ld	de, 0B9h ; '¹'
		push	hl
		ld	hl, 0EC00h
		add	hl, de
		ex	de, hl
		pop	hl
		ldir
		ld	de, 0C5h ; 'Å'
		ld	(326h),	hl
		ld	hl, 0EC00h
		add	hl, de
		ld	(hl), 3Fh ; '?'
		call	consi		; Eingabe 1 Zeichen nach A
		ld	c, a
		cp	0Dh
		jp	z, no_shloc	; ShiftLock aus, Ende
		ld	(hl), 20h ; ' '
		ld	hl, (326h)
		ld	a, c
		cp	(hl)
		jp	nz, loc_89E4
		cp	a
		ld	b, 0
		ld	c, 8
		exx
		ld	a, 2
		cp	e
		exx
		jr	nz, tptast9
		inc	c
		inc	c
		inc	c
tptast9:
		sbc	hl, bc
		ld	de, 1A0h
		push	hl
		ld	hl, 0EC00h
		add	hl, de
		ex	de, hl
		pop	hl
		ldir
		exx
		ld	a, 1
		cp	e
		exx
		jp	z, loc_8ACB
tptast10:
		jp	loc_8A5E
tptast11:
		push	hl
		ld	de, 0E2h ; 'â'
		ld	hl, 0EC00h
		add	hl, de
		ld	(hl), 20h ; ' '
		ld	de, 0F0h ; 'ð'
		ld	hl, aUndGleichzeiti ; "UND GLEICHZEITIG	DIE TASTE \"A\""
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		pop	hl
		exx
		dec	c
		exx
		jp	nz, tptast7
		jp	loc_8AF1

;-----------------------------------------------------------------------------
; 
;-----------------------------------------------------------------------------

; BWS löschen
cls:		ld	hl, 0EC00h
		ld	de, 0EC01h
		ld	(hl), 20h ; ' '
		ld	bc, 40*24
		ldir
		ret

; Textausgabe (HL) an BWS-Position (DE)
print:		push	hl
		ld	hl, 0EC00h
		add	hl, de
		ex	de, hl
		pop	hl
		ld	b, 0
		ld	c, (hl)
		inc	hl
		ldir
		ret

; Eingabe 1 Zeichen nach A
consi:		push	bc
		ld	c, 1		; CONSI
		call	5
		pop	bc
		ret

no_shloc:	xor	a		; ShiftLock aus, Ende
		ld	(26h), a	; SHIFT	LOCK aus
		jp	rst_bws

loc_89E4:	ld	hl, aFehler_0
		ld	b, 3
		call	printx		; Textausgabe (Pos, Länge, Text)
		call	consi		; Eingabe 1 Zeichen nach A
		ld	c, a
		cp	0Dh
		jp	z, no_shloc	; ShiftLock aus, Ende
		call	sub_8AA3
		ld	a, c
		ld	b, 4
		and	b
		jr	z, loc_8A19
		exx
		ld	a, e
		exx
		cp	1
		jp	nz, tptast10
		exx
		ld	a, l
		exx
		cp	1
		jp	z, loc_8AE6
		exx
		ld	d, 1
		ld	l, 1
		ld	h, 9Ah ; 'š'
		exx
		jp	tptast10

loc_8A19:	ld	hl, (326h)
		ld	c, 8
		exx
		ld	a, 2
		cp	e
		exx
		jr	nz, loc_8A28
		inc	c
		inc	c
		inc	c
loc_8A28:	ld	b, 0
		cp	a
		sbc	hl, bc
		jp	tptast7

loc_8A30:	ld	hl, 0EC00h
		ld	de, 168h
		add	hl, de
		ld	d, h
		ld	e, l
		inc	de
		ld	(hl), 20h ; ' '
		ld	bc, 258h
		ldir
		ld	hl, 0EC00h
		ld	de, 12Dh
		add	hl, de
		ld	(hl), 20h ; ' '
		ld	hl, aFehler_0
		ld	b, 2
		call	printx		; Textausgabe (Pos, Länge, Text)
		ld	de, 128h
		ld	hl, 0EC00h
		add	hl, de
		ld	(hl), 3Fh ; '?'
		jp	tptast3

loc_8A5E:	ld	de, 1EAh
		ld	hl, aTestFortsetzen ; "TEST FORTSETZEN?	  J/N"
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		call	consi		; Eingabe 1 Zeichen nach A
		ld	c, a
		cp	0Dh
		jp	z, no_shloc	; ShiftLock aus, Ende
		ld	a, c
		ld	b, 4
		and	b
		jp	nz, no_shloc	; ShiftLock aus, Ende
		exx
		ld	a, 2
		cp	e
		exx
		jp	z, no_shloc	; ShiftLock aus, Ende
		ld	de, 12Ch
		ld	hl, 0EC00h
		add	hl, de
		ld	b, 0DCh	; 'Ü'
loc_8A88:	ld	(hl), 20h ; ' '
		inc	hl
		dec	b
		jr	nz, loc_8A88
		ld	hl, (326h)
		inc	hl
		exx
		ld	a, b
		cp	0
		exx
		jp	nz, tptast11
		exx
		dec	d
		exx
		jp	nz, tptast7
		jp	loc_8AB7

sub_8AA3:	ld	hl, 0EC00h
		ld	de, 190h
		add	hl, de
		ld	d, h
		ld	e, l
		inc	de
		ld	(hl), 20h ; ' '
		push	bc
		ld	bc, 0A0h ; ' '
		ldir
		pop	bc
		ret

loc_8AB7:	push	hl
		ld	de, 0E2h ; 'â'
		ld	hl, 0EC00h
		add	hl, de
		exx
		ld	a, h
		exx
		ld	(hl), a
		exx
		ld	e, 1
		exx
		pop	hl
		jp	tptast7

loc_8ACB:	ld	de, 1C9h
		ld	hl, 0EC00h
		add	hl, de
		exx
		ld	a, h
		exx
		ld	(hl), a
		exx
		ld	a, 1
		cp	l
		jr	z, loc_8AE6
		exx
		ld	d, 1
		ld	l, d
		ld	h, 9Ah ; 'š'
		exx
		jp	tptast10

loc_8AE6:	exx
		ld	e, 0
		ld	b, 1
		ld	c, 3
		exx
		jp	tptast10

loc_8AF1:	push	hl
		ld	de, 0F0h ; 'ð'
		ld	hl, aUndAnschliesse ; "UND ANSCHLIESSEND DIE TASTE \"A\""
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		pop	hl
		exx
		ld	e, 2
		exx
		jp	tptast7

loc_8B03:	ld	c, 0Bh
		jp	tptast8

aTastaturpruefp:dw 7
		db 26,"TASTATURPRUEFPROGRAMM FUER"
		dw 60h
		db 7,"HC 9001"
		dw 140h
		db 35,"DAS PROGRAMM BESTEHT AUS DEN TEILEN"
		dw 1B8h
		db 35,"1.TEST DER ALPHA-NUMERISCHEN TASTEN"
		dw 230h
		db 26,"2.TEST DER FUNKTIONSTASTEN"
		dw 2D3h
		db 34,"SIE VERLASSEN DIE TEILPROGRAMME AN"
		dw 2FBh
		db 32,"BELIEBIGER STELLE DURCH DRUECKEN"
		dw 323h
		db 19,"DER TASTE   \"ENTER\""
aTestDerAlphaNu:dw 2
		db 33,"TEST DER ALPHA-NUMERISCHEN TASTEN"
		dw 79h
		db 26,"DRUECKEN SIE DIE TASTEN IN"
		dw 94h
		db 24,"BELIEBIGER   REIHENFOLGE"
		dw 122h
		db 7,"TASTE ?"
aTestDerFunktio:dw 8
		db 24,"TEST DER FUNKTIONSTASTEN"
		dw 0A0h
		db 23,"DRUECKEN SIE DIE TASTE:"
aFehler_0:	dw 1A0h
		db 8,"FEHLER  "
		dw 1C8h
		db 6,"______"
		dw 212h
aWiederholenJN:	db 18,"WIEDERHOLEN?   J/N"
aBeginnenJ:	db 15,"BEGINNEN?   J  "
aStop:		db "\"STOP\"  "
		db    3
aList:		db "\"LIST\"  "
		db  1Ch
aRun:		db "\"RUN\"   "
		db  1Dh
aPause:		db "\"PAUSE\" "
		db  13h
aIns:		db "\"INS\"   "
		db  1Ah
aEsc:		db "\"ESC\"   "
		db  1Bh
aColor:		db "\"COLOR\" "
		db  14h
aI:		db "\"I<-\"   "
		db  19h
		db "\"<-\"    "
		db    8
		db "\"->\"    "
		db    9
		db "\"^\"     "
		db  0Bh
aB:		db '"',0A1h,"\"     "
		db  0Ah
aContr:		db "\"CONTR\" "
		db    1
aShift:		db "\"SHIFT\" "
		db  61h	; a
aShiftlock:	db "\"SHIFTLOCK\""
		db  61h	; a
aLeitprogramm:	db 12,"LEITPROGRAMM"
aUndGleichzeiti:db 30,"UND GLEICHZEITIG DIE TASTE \"A\""
aTestFortsetzen:db 22,"TEST FORTSETZEN?   J/N"
aUndAnschliesse:db 31,"UND ANSCHLIESSEND DIE TASTE \"A\""
aAsciiZeichen:	db 14," ASCII-ZEICHEN"
aGrafikZeichen:	db 14,"GRAFIK-ZEICHEN"
		jp	tptast2

		
aTestprogrammZ9:db 30,"TESTPROGRAMM Z9001 (VERS. 1.5)"
aRam100003fff:	db 15,"RAM1: 0000-3FFF"
aRam240007fff:	db 15,"RAM2: 4000-7FFF"
aRam38000Bfff:	db 15,"RAM3: 8000-BFFF"
aRom2C000E7ff:	db 15,"ROM2: C000-E7FF"
aRamfE800Ebff:	db 15,"RAMF: E800-EBFF"
aRambEc00Efff:	db 15,"RAMB: EC00-EFFF"
aRom1F000Ffff:	db 15,"ROM1: F000-FFFF"
aVariante:	db 11,"VARIANTE ?:"
aDauertestJN:	db 14,"DAUERTEST J/N:"
aTestfolge:	db 10,"TESTFOLGE:"

; alle Testnamen müssen 6 Byte belegen (test_all)
; Reihenfolge wie tp_tab
aTprom1:	db 6,"TPROM1"
aTprom2:	db 6,"TPROM2"
aTpram1:	db 6,"TPRAM1"
aTpram2:	db 6,"TPRAM2"
aTpram3:	db 6,"TPRAM3"
aTpramb:	db 6,"TPRAMB"
aTpramf:	db 6,"TPRAMF"
aTpcea:		db 6,"TPCEA "
aTpsph:		db 6,"TPSPH "
aTpbild:	db 6,"TPBILD"
aTptast:	db 6,"TPTAST"
aTpkas1:	db 6,"TPKAS1"
aTpkas2:	db 6,"TPKAS2"
aTpfarb:	db 6,"TPFARB"

aStartJN:	db 10,"START J/N:"
aTestlauf:	db 9,"TESTLAUF:"
aFehler:	db 6,"FEHLER"
aEinzeltest:	db 11,"EINZELTEST:"
aTestgenerierun:db 16,"TESTGENERIERUNG:"
aWeiterDurchDru:db 34,"WEITER DURCH DRUECKEN EINER TASTE !"
aEsGehtGleichWe:db 23,"ES GEHT GLEICH WEITER !"
aSpielhebel1Spi:db 35,"SPIELHEBEL 1 = *   SPIELHEBEL 2 = #"
aAbbruchMitEnte:db 19,"ABBRUCH MIT \"ENTER\""
aAchtungKeineFe:db 33,"ACHTUNG, KEINE FEHLERAUSWERTUNG !"

;------------------------------------------------------------------------------
; Testprogramm Kassette
;------------------------------------------------------------------------------

tpkas1:		ld	a, (311h)
		bit	0, a
		jr	z, tpkas11
		di
		ld	a, 7
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 40h ; '@'
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ei
		call	sub_9A4C
		call	scroll_up
		ld	hl, aWeiterDurchDru ; "WEITER DURCH DRUECKEN EINER TASTE "
		call	print0
		call	scroll_up
		ld	hl, aAchtungKeineFe ; "ACHTUNG,	KEINE FEHLERAUSWERTUNG !"
		call	print0
		call	consi		; Eingabe 1 Zeichen nach A
		ld	a, 3
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ei
		jp	loc_95B8

tpkas11:	call	sub_9A1F
		call	build_ivtab
		exx
		ld	d, 0
		ld	c, d
		ld	b, d
		exx
		ld	hl, loc_8875+1
		ld	(iv_ctc0), hl
		di
		ld	a, 40h ; '@'
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 87h ; '‡'
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 0FFh
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	b, 0
		ei
tpkas12:	ld	a, b
		cp	0FFh
		jr	nz, tpkas12
		di
		call	loc_9A40
		ld	hl, inttab
		ld	(iv_ctc0),	hl
		ld	bc, 200h
		call	tpkas1_initpio
		call	tpkas1_initctc
tpkas13:	dec	bc
		ld	a, b
		cp	0
		jr	nz, tpkas13
		ld	a, c
		cp	0
		jr	nz, tpkas13
		ld	a, 3
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 7
		out	(PIO1AS), a	; PIO1 A Kommando
		exx
		ld	a, b
		sub	d
		exx
		jr	z, tpkas14
		cp	1
		jr	z, tpkas14
		add	a, 1
		jp	nz, loc_90A5
tpkas14:	exx
		ld	a, 20h ; ' '
		cp	b
		exx
		jp	p, loc_9088
		call	sub_9A1F
		call	inita		; Initialisierung der Tastatur und der Systemuhr
		jp	loc_95B8

tpkas1_initpio:
		di
		ld	a, 3
		out	(PIO1AS), a	; PIO1 A Kommando
		ld	a, 01001000b
		out	(PIO1AS), a	; PIO1 A Kommando
		ld	a, 00001111b
		out	(PIO1AS), a	; PIO1 A Kommando
		ld	a, 10000011b
		out	(PIO1AS), a	; PIO1 A Kommando
		ei
		ret

tpkas1_initctc:
		di
		ld	a, 40h ; '@'
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 87h ; '‡'
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 28h ; '('
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ei
		ret

sub_907E:	inc	de
		inc	de
		ld	a, 30h ; '0'
		or	b
		ld	(de), a
		call	scroll_up
		ret

loc_9088:	call	sub_9A1F
		call	inita		; Initialisierung der Tastatur und der Systemuhr
		call	print_errorcnt
		ld	a, (290h)
		cp	1
		call	z, sub_94D2
		ld	b, 1
		call	sub_907E
		xor	a
		ld	(290h),	a
		jp	loc_95B8

loc_90A5:	call	sub_9A1F
		call	inita		; Initialisierung der Tastatur und der Systemuhr
		call	print_errorcnt
		ld	b, 2
		call	sub_907E
		xor	a
		ld	(290h),	a
		jp	loc_95B8

loc_90BA:	call	sub_9A1F
		call	inita		; Initialisierung der Tastatur und der Systemuhr
		call	print_errorcnt
		ld	b, 3
		call	sub_907E
		xor	a
		ld	(290h),	a
		jp	loc_95B8

loc_90CF:	call	sub_9A1F
		call	inita		; Initialisierung der Tastatur und der Systemuhr
		call	print_errorcnt
		ld	b, 4
		call	sub_907E
		xor	a
		ld	(290h),	a
		jp	loc_95B8

; Interruptvektoren ab iv_ctc0 aufbauen
build_ivtab:	ld	de, 3
		ld	hl, inttab	; Interruptroutinen
		ld	(iv_ctc0), hl	; Interruptvekor CTC0
		add	hl, de
		ld	(iv_ctc1), hl	; Interruptvekor CTC1
		add	hl, de
		ld	(iv_ctc3), hl	; Interruptvekor CTC3
		add	hl, de
		ld	(iv_pio1a), hl	; Interruptvekor PIO1A
		add	hl, de
		ld	(iv_pio1b), hl	; Interruptvekor PIO1B
		add	hl, de
		ld	(iv_pio2a), hl	; Interruptvekor PIO2A
		add	hl, de
		ld	(iv_pio2b), hl	; Interruptvekor PIO2B
		ret

; Interruptroutine
loc_9106:	exx
		inc	b
		exx
		ei
		reti

; Interruptroutine
loc_910C:	ld	a, 1
		ld	(294h),	a
		ei
		reti

; Interruptroutine
loc_9114:	exx
		inc	d
		exx
		ei
		reti

; Interruptroutine
loc_911A:	nop
loc_911B:	nop
loc_911C:	nop
loc_911D:	ld	a, 1
		ld	(293h),	a
		ei
		reti


tpkas2:		call	bckup_bws
		ld	bc, 0FFFFh
tpkas21:	cpi
		jp	pe, tpkas21
		call	cls		; BWS löschen
		ld	hl, aPruefprogrammF
		ld	b, 2
		call	printx		; Textausgabe (Pos, Länge, Text)
		ld	hl, 32Ah
		ld	e, 1
		ld	bc, 400h
tpkas22:	ld	(hl), e
		inc	hl
		rlc	e
		dec	bc
		ld	a, b
		cp	0
		jr	nz, tpkas22
		ld	a, c
		cp	0
		jr	nz, tpkas22
		ld	hl, aBereitenSieDen
		ld	b, 4
		call	printx		; Textausgabe (Pos, Länge, Text)
tpkas23:	call	consi		; Eingabe 1 Zeichen nach A
		cp	0Dh
		jr	nz, tpkas23
		call	sub_91F0
		call	sub_920C
		call	inita		; Initialisierung der Tastatur und der Systemuhr
		ld	hl, aUebertragungBe
		ld	b, 2
		call	printx		; Textausgabe (Pos, Länge, Text)
		call	consi		; Eingabe 1 Zeichen nach A
		cp	'J'
		jp	nz, rst_bws
		call	sub_91F0
		ld	hl, aBereitenSieD_0
		ld	b, 3
		call	printx		; Textausgabe (Pos, Länge, Text)
		ld	hl, aBeginnDerUeber
		ld	b, 2
		call	printx		; Textausgabe (Pos, Länge, Text)
tpkas24:	call	consi		; Eingabe 1 Zeichen nach A
		cp	0Dh
		jp	nz, tpkas24
		call	sub_91F0
		ld	bc, 400h
		ld	hl, 72Ah
		ld	d, h
		ld	e, l
		ld	(hl), 0
		inc	de
		ldir
		call	sub_9229
		call	inita		; Initialisierung der Tastatur und der Systemuhr
		jp	c, loc_9202
		ld	bc, 400h
		ld	hl, 32Ah
		ld	de, 72Ah
tpkas25:	ld	a, (de)
		cp	(hl)
		jp	nz, loc_9202
		inc	hl
		inc	de
		dec	bc
		ld	a, b
		cp	0
		jr	nz, tpkas25
		ld	a, c
		cp	0
		jr	nz, tpkas25
		ld	de, 14Fh
		ld	hl, aFehlerfrei	; "FEHLERFREI"
		call	print		; Textausgabe (HL) an BWS-Position (DE)
tpkas26:	ld	de, 238h
		ld	hl, aTestWiederhole ; "TEST WIEDERHOLEN	?   J/N"
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		call	consi		; Eingabe 1 Zeichen nach A
		cp	4Ah ; 'J'
		jp	z, tpkas2
		jp	rst_bws
		ret
		ret


; Initialisierung der Tastatur und der Systemuhr
inita:		push	bc
		ld	c, 25		; INITA	  Initialisierung der Tastatur und der Systemuhr
		call	5
		pop	bc
		ret

sub_91F0:	ld	hl, 0EC00h
		ld	de, 118h
		add	hl, de
		ld	d, h
		ld	e, l
		inc	de
		ld	(hl), 20h ; ' '
		ld	bc, 1F4h
		ldir
		ret

loc_9202:	ld	hl, aFehler_0
		ld	b, 2
		call	printx		; Textausgabe (Pos, Länge, Text)
		jr	tpkas26

sub_920C:	ld	bc, 0BB0h
		ld	de, 32Ah
		exx
		ld	b, 0Ah
		exx
loc_9216:	ld	(1Bh), de
		call	0FED6h		; KARAM
		exx
		dec	b
		exx
		jr	z, locret_9228
		ex	de, hl
		ld	bc, 0A0h ; ' '
		jr	loc_9216
locret_9228:	ret

sub_9229:	ld	de, 72Ah
		exx
		ld	b, 0Ah
		exx
loc_9230:	ld	(1Bh), de
		call	0FF59h		; MAREK
		exx
		ret	c
		dec	b
		exx
		jr	z, locret_9240
		ex	de, hl
		jr	loc_9230
locret_9240:	ret

aPruefprogrammF:dw 3
		db 32,"PRUEFPROGRAMM FUER ANSCHLUSS DES"
		dw 53h
		db 33,"KASSETTENRECORDERS AN DEN HC 9001"
aBereitenSieDen:dw 11Bh
		db 29,"BEREITEN SIE DEN RECORDER ZUR"
		dw 16Bh
		db 14,"AUFNAHME VOR !"
aBeginnDerUeber:dw 233h
		db 29,"BEGINN DER UEBERTRAGUNG DURCH"
		dw 283h
		db 27,"DRUECKEN DER TASTE  \"ENTER\""
aBereitenSieD_0:dw 118h
		db 25,"BEREITEN SIE DEN RECORDER"
		dw 133h
		db 13,"ZUM ABSPIELEN"
		dw 168h
		db 35,"DER UEBERTRAGENEN INFORMATION VOR !"
aUebertragungBe:dw 190h
		db 20,"UEBERTRAGUNG BEENDET"
		dw 1A8h
		db 16,"FORTSETZEN?  J/N"
aFehlerfrei:	db 10,"FEHLERFREI"
aTestWiederhole:db 24,"TEST WIEDERHOLEN ?   J/N"

;-----------------------------------------------------------------------------
; Testprogramm CTC u. E/A
;-----------------------------------------------------------------------------

tpcea:		call	sub_9A4C
		call	sub_9A1F
		call	build_ivtab
		xor	a
		ld	(293h),	a
		ld	bc, 8
		ld	de, 0FEFEh
		ld	a, 0AAh	; 'ª'
		ld	(292h),	a
		ld	a, 97h ; '—'
		ld	(32Bh),	a
		ld	a, 0FCh	; 'ü'
		ld	(32Ch),	a
		xor	a
		ld	(32Dh),	a
		ld	a, 0FFh
		ld	(32Eh),	a
		ld	a, 1
		ld	(290h),	a
loc_93C7:	di
		ld	a, 4Ah ; 'J'
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 0CFh	; 'Ï'
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, (292h)
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, (32Bh)
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, e
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, (32Eh)
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		ei
		ld	a, d
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		call	sub_94C7
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		ld	(291h),	a
		ld	hl, 32Ch
		cp	(hl)
		jp	nz, loc_9088
		ld	a, (293h)
		cp	0
		jp	z, loc_90A5
		xor	a
		ld	(293h),	a
		rlc	e
		xor	a
		cp	b
		jp	z, loc_9418
		rlc	d
		rlc	d
		ld	a, (32Ch)
		rlc	a
		rlc	a
		ld	(32Ch),	a
loc_9418:	ld	a, 1
		xor	b
		ld	b, a
		dec	c
		jp	nz, loc_93C7
		ld	hl, 32Dh
		ld	a, 1
		cp	(hl)
		jp	z, loc_944A
		ld	bc, 8
		ld	de, 2FEh
		ld	a, 0B7h	; '·'
		ld	(32Bh),	a
		ld	a, 3
		ld	(32Ch),	a
		ld	a, 1
		ld	(32Dh),	a
		xor	a
		ld	(32Eh),	a
		ld	a, 55h ; 'U'
		ld	(292h),	a
		jp	loc_93C7
;
loc_944A:	di
		ld	a, 4Ah ; 'J'
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 0CFh	; 'Ï'
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, (292h)
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 0F7h	; '÷'
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		xor	a
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		xor	a
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		ei
		ld	a, 0AAh	; 'ª'
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		call	sub_94C7
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		ld	(291h),	a
		cp	0FFh
		jp	nz, loc_9088
		ld	a, (293h)
		cp	0
		jp	z, loc_90A5
		call	sub_9A1F
		xor	a
		ld	(290h),	a
		di
		ld	a, 4Ah ; 'J'
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 4Fh ; 'O'
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 97h ; '—'
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 0FFh
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 40h ; '@'
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 87h ; '‡'
		out	(CTC1),	a	; System CTC1 Anwenderport
		ld	a, 0Ah
		out	(CTC1),	a	; System CTC1 Anwenderport
		xor	a
		ld	(293h),	a
		xor	a
		ld	(294h),	a
		ei
		call	sub_94C7
		call	sub_9A1F
		ld	a, (293h)
		cp	0
		jp	z, loc_90BA
		ld	a, (294h)
		cp	0
		jp	z, loc_90CF
		call	inita		; Initialisierung der Tastatur und der Systemuhr
		jp	loc_95B8
;
sub_94C7:	push	bc
		ld	b, 14h
loc_94CA:	dec	b
		ld	a, b
		cp	0
		jr	nz, loc_94CA
		pop	bc
		ret

sub_94D2:	push	hl
		push	de
		ld	de, 0
		ld	b, d
		ld	a, (291h)
		ld	c, a
		ld	a, (32Ch)
		xor	c
		ld	c, a
loc_94E1:	bit	0, c
		call	nz, sub_94F1
		rrc	c
		inc	b
		ld	a, 8
		cp	b
		jr	nz, loc_94E1
		pop	de
		pop	hl
		ret

sub_94F1:	ld	hl, 0EF85h
		add	hl, de
		ld	a, 30h ; '0'
		or	b
		ld	(hl), a
		inc	de
		inc	de
		ret

; Textausgabe (HL) an Zeile 22,	Spalte 1
print0:		ld	de, 40*22+1	; Zeile 22, Spalte 1
		call	print		; Textausgabe (HL) an BWS-Position (DE)

; Bildschirm scrollen
scroll_up:	push	hl
		push	de
		ld	hl, 0EC00h+40
		ld	de, 0EC00h
		ld	bc, 40*23
		ldir
		pop	de
		pop	hl
		ret

; test,	ob auf (HL) RAM	vorliegt
is_ram:		ld	a, (hl)
		cpl
		ld	(hl), a
		cp	(hl)
		ret

; Bitweises markieren der zu erfolgenden Tests
mark_test:	ld	hl, unk_310	; bitweise sind	die abzuarbeitenden Tests markiert
		or	(hl)
		ld	(hl), a
		ret

; J/N-Abfrage
inp_jn:		call	consi		; Eingabe 1 Zeichen nach A
		ld	hl, 0FFD9h
		add	hl, de
		ld	(hl), a
		cp	'J'
		ret

; Anzeige der auszuführenden Tests
sub_9528:	rlc	c
		call	c, print1	; Textausgabe (HL) an Zeile 22,	Spalte 1 mit Retten der	Register
		ld	a, l
		add	a, 7
		ld	l, a
		jr	nc, loc_9534
		inc	h
loc_9534:	djnz	sub_9528
		ret

; Textausgabe (HL) an Zeile 22,	Spalte 1 mit Retten der	Register
print1:		push	bc
		push	hl
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		pop	hl
		pop	bc
		ret

; UP zu main
sub_953F:	call	scroll_up
		ld	de, 40*22+1	; Zeile 22, Spalte 1
		ld	hl, aTestlauf	; "TESTLAUF:"
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		ld	hl, unk_324
		ld	b, 2
		call	tohex0		; B Bytes ab (HL) als Hex-Ascii	ablegen	ab (DE+1)
		ld	de, 40*22+21	; Zeile 22 Spalte 21
prnt_error:
		ld	hl, aFehler	; "FEHLER"
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		ld	hl, unk_322	; Gesamtzanzahl der Fehler
		ld	b, 3
		call	tohex0		; B Bytes ab (HL) als Hex-Ascii	ablegen	ab (DE+1)
		ret

; B Bytes ab (HL) als Hex-Ascii	ablegen	ab (DE+1)
tohex0:		inc	de
tohex:		ld	c, (hl)		; B Bytes ab (HL) als Hex-Ascii	ablegen	ab (DE)
		ld	a, 0F0h
		and	c
		rlc	a
		rlc	a
		rlc	a
		rlc	a
		call	to_ascii	; Umwandeln A (00-0FH) nach ASCII und ablegen ab (DE)
		ld	a, 0Fh
		and	c
		call	to_ascii	; Umwandeln A (00-0FH) nach ASCII und ablegen ab (DE)
		dec	hl
		djnz	tohex
		ret

; Umwandeln A (00-0FH) nach ASCII und ablegen ab (DE)
to_ascii:	cp	0Ah
		jp	p, to_ascii2
		or	30h ; '0'
to_ascii1:	ld	(de), a
		inc	de
		ret
to_ascii2:	add	a, 37h ; '7'
		jr	to_ascii1

; Tests abarbeiten
; HL: Tabelle der Tests (jp xxx)
; DE: Tabelle der Texte (aTprom1)
; B: Anzahl der Tests
; C: Bitweise Markierung der Tests (unk_310)
test_all:	rlc	c		; Testbit
		call	c, test_single	; Test ausführen, wenn Testbit=1
		inc	hl		; Sprungbefehl übergehen
		inc	hl
		inc	hl
		push	hl
		ld	hl, 7
		add	hl, de
		ex	de, hl		; DE=Name nächster Test
		pop	hl
		call	csts0		; Abfrage Status CONST
		cp	13h
		jr	z, locret_95A5
		djnz	test_all	; nachsten Test
locret_95A5:	ret

; Abfrage Status CONST
csts0:		push	bc
		ld	c, 11		; CSTS	  Abfrage Status CONST
		call	5
		pop	bc
		ret

; einzelnen Test ausführen
; HL = Sprungbefehl zum Test
; DE = Name Test
test_single:
		push	bc
		push	de
		push	hl
		ex	de, hl
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		pop	hl
		push	hl
		jp	(hl)		; zum Test springen


loc_95B8:	pop	hl
		pop	de
		pop	bc
		ret

; Anzeige der Fehleranzahl
print_errorcnt:	push	bc
		push	hl
; Auswertung Speicherfehler
		ld	de, 1
		ld	hl, (320h)
		add	hl, de
		ld	(320h),	hl
		jr	nc, print_ecnt3
		ld	hl, unk_322
		inc	(hl)
print_ecnt3:	ld	de, 40*22+1	; Zeile 22, Spalte 1
		call	prnt_error
		pop	hl
		pop	bc
		ret

; BWS-Speicher nach 3000 sichern
bckup_bws:	ld	hl, 0E800h
		ld	de, 3000h
		ld	bc, 7FFh
		ldir
		ret

; BWS-Speicher von 3000h restaurieren
rst_bws:	ld	hl, 3000h
		ld	de, 0E800h
		ld	bc, 7FFh
		ldir
		jp	loc_95B8

; Teste, ob HL<DE
is_end:		inc	hl
		ld	a, d
		cp	h
		ret

; UP zu tpram
sub_95F5:	rrc	b
		jp	is_end

; UP zu tpram
sub_95FA:	ld	b, l

; UP zu tpram
sub_95FB:	push	de
		ld	(unk_312),	sp
		push	hl
		push	bc
		push	af
		call	print_errorcnt	; Anzeige der Fehleranzahl
		inc	de
		ld	b, 2
		ld	hl, (unk_312)
		dec	hl
		call	tohex0		; B Bytes ab (HL) als Hex-Ascii	ablegen	ab (DE+1)
		ld	b, 1
		call	tohex0		; B Bytes ab (HL) als Hex-Ascii	ablegen	ab (DE+1)
		ld	b, 1
		dec	hl
		call	tohex0		; B Bytes ab (HL) als Hex-Ascii	ablegen	ab (DE+1)
		call	scroll_up	; Bildschirm scrollen
loc_961E:	call	csts0		; Abfrage Status CONST
		cp	0
		jr	z, loc_9629
		cp	0Dh
		jr	nz, loc_961E
loc_9629:	pop	af
		pop	bc
		pop	hl
		pop	de
		ret

sub_962E:	ld	(hl), 0
		ld	bc, 28h	; '('
		ldir
		ret

;-----------------------------------------------------------------------------
; Einsprung bei	Start (Kdo "LPRO      ")
;-----------------------------------------------------------------------------

lpro0:		call	consi		; Eingabe 1 Zeichen nach A
lpro:		call	cls		; BWS löschen
		ld	bc, 40*24 + 20	; 40*24 + 20
		ld	hl, 0E800h
		ld	de, 0E800h+1
		ld	(hl), 00110000b	; gelb auf schwarz
		ldir
		ld	hl, aTestprogrammZ9 ; "TESTPROGRAMM Z9001 (VERS. 1.5)"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	scroll_up
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		ld	a, 10100101b
		ld	(310h),	a
		ld	a, 50h ; 'P'
; Test RAM2 nötig?
		ld	(311h),	a
		ld	hl, 7FFFh
		call	is_ram		; test,	ob auf (HL) RAM	vorliegt
		jr	nz, lpro1
		ld	hl, aRam240007fff ; "RAM2: 4000-7FFF"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		ld	a, 00010000b
		call	mark_test	; Bitweises markieren der zu erfolgenden Tests
; Test RAM3 nötig?
lpro1:		ld	hl, 0BFFFh
		call	is_ram
		jr	nz, lpro2
		ld	hl, aRam38000Bfff ; "RAM3: 8000-BFFF"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		ld	a, 00001000b
		call	mark_test	; Bitweises markieren der zu erfolgenden Tests
; Test TPROM2 nötig?
lpro2:		ld	hl, 0C007h	; Test,	ob ROM-BASIC vorhanden ist
		ld	a, 42h ; 'B'	; 'B' des Startkommandos 7F 7F 'BASIC'
		cp	(hl)
		jr	nz, lpro3
		ld	hl, aRom2C000E7ff ; "ROM2: C000-E7FF"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		ld	a, 01000000b
		call	mark_test
; Test TPRAMF nötig?
lpro3:		ld	hl, 0EBFFh
		call	is_ram		; test,	ob auf (HL) RAM	vorliegt
		jr	nz, lpro4
		ld	hl, aRamfE800Ebff ; "RAMF: E800-EBFF"
		call	print0
		ld	a, 000000010b
		call	mark_test
		ld	a, 54h ; 'T'
		ld	(311h),	a
;
lpro4:		ld	hl, aRambEc00Efff ; "RAMB: EC00-EFFF"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	scroll_up
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	consi		; Eingabe 1 Zeichen nach A
		cp	3
		jp	z, 0
;
		push	hl
		ld	hl, 0FFD9h
		add	hl, de
		ld	(hl), a
		ld	(315h),	a
		pop	hl
		call	scroll_up
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	inp_jn		; J/N-Abfrage
		jp	nz, einzel

loc_96DD:	call	scroll_up
		ld	hl, aTestfolge	; "TESTFOLGE:"
		call	print0
		call	scroll_up
		ld	hl, 310h
		ld	c, (hl)
		ld	hl, aTprom1	; "TPROM1"
		ld	b, 8
		call	sub_9528
		ld	hl, 311h
		ld	c, (hl)
		ld	hl, aTpsph	; "TPSPH "
		ld	b, 7
		call	sub_9528
		ld	hl, 320h
		ld	b, 5
		ld	a, 0
loc_9708:	ld	(hl), a
		inc	hl
		djnz	loc_9708

loc_970C:	call	sub_953F
		call	scroll_up
		ld	hl, aStartJN	; "START J/N:"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
loc_9718:	call	inp_jn		; J/N-Abfrage
		jr	z, loc_9724
		cp	0Dh
		jr	z, loc_9718
		jp	lpro

loc_9724:	call	scroll_up
main5:		ld	hl, tp_tab	; Sprungtabelle	Testprogramme
		ld	a, (310h)
		ld	c, a
		ld	de, aTprom1	; "TPROM1"
		ld	b, 8
		call	test_all
		cp	13h
		jp	z, lpro0
		ld	a, (311h)
		ld	c, a
		ld	b, 6
		call	test_all
		cp	13h
		jp	z, lpro0
		ld	hl, (323h)
		inc	hl
		ld	(323h),	hl
		bit	6, c
		jr	nz, loc_970C
		call	sub_953F
		call	scroll_up
		jp	main5

einzel:		call	scroll_up
		ld	hl, aEinzeltest	; "EINZELTEST:"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	scroll_up
		ld	hl, aTprom1	; "TPROM1"
		ld	c, 'A'
		ld	b, 14		; Anzahl der verschiedenen Tests
einzel1:	ld	de, 371h
		push	bc
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		pop	bc
		inc	de
		ld	a, c
		ld	(de), a
		inc	c
		push	bc
		call	scroll_up
		pop	bc
		djnz	einzel1
		call	scroll_up
		ld	hl, aTestgenerierun ; "TESTGENERIERUNG:"
		call	print0
		xor	a
		ld	(310h),	a
		inc	a
		ld	(311h),	a
		ld	hl, 0FFD8h
		add	hl, de
		ex	de, hl
einzel2:	call	consi		; Eingabe 1 Zeichen nach A
		cp	1Ch
		jr	nz, einzel3
		ld	a, (311h)
		and	0FEh ; 'þ'
		ld	(311h),	a
		jp	loc_96DD

einzel3:	cp	0Dh
		jp	z, loc_96DD
		ld	(de), a
		ld	hl, 310h
		ld	bc, 841h
		push	de
		ld	d, 80h ; '€'
einzel4:	cp	c
		jr	z, einzel6
		rrc	d
		inc	c
		djnz	einzel4
		ld	b, 7
		inc	hl
		ld	d, 80h ; '€'
einzel5:	cp	c
		jr	z, einzel6
		rrc	d
		inc	c
		djnz	einzel5
einzel6:	ld	a, d
		or	(hl)
		ld	(hl), a
		pop	de
		inc	de
		jp	einzel2

;-----------------------------------------------------------------------------
; Testprogramm OS F000-FFFF
;-----------------------------------------------------------------------------

tprom1:		ld	hl, word_8837	; Testprogramm OS F000-FFFF
		call	sub_9B91
		ld	hl, 0FFFFh
		ld	b, 2		; Anzahl der 2K-Bereiche
		jp	tprom22
		
;-----------------------------------------------------------------------------
; Testprogramm ROM-BASIC C000-E7FF
;-----------------------------------------------------------------------------

tprom2:		ld	hl, word_883B	; Testprogramm ROM-BASIC C000-E7FF
		call	sub_9B91
		ld	hl, 0E7FFh
		ld	b, 5		; Anzahl der 2K-Bereiche

; Summen bilden: ab HL abwärts 800h Bytes summieren
tprom22:	push	ix
		push	bc
		push	de
		ld	ix, 0		; Prüfsumme := 0
		ld	de, 0
		ld	b, d		; B := 0
		ld	a, 8		; 800H,	d.h. 2K	aufsummieren

tprom23:	ld	c, (hl)
		add	ix, bc		; ab (hl) abwärts Bytes	aufaddieren, bis Anzahl	A*100h erreicht
		dec	hl
		inc	de
		cp	d		; D = 8?
		jr	nz, tprom23
; Vergleich mit Sollwert (DE)
		pop	de
		push	hl
		push	ix
		pop	hl
		ld	a, (de)		; Vergleiche Prüfsumme mit (DE)
		inc	de
		cp	h
		jr	nz, tprom25	; wenn ungleich
		ld	a, (de)
		cp	l
		jr	nz, tprom25	; wenn ungleich
;
tprom24:	inc	de
		pop	hl
		pop	bc
		pop	ix
		djnz	tprom22		; alle 2K-Bereiche abarbeiten
		jp	loc_95B8
; ROM-Fehler
tprom25:	pop	hl
		pop	bc
		push	de
		call	print_errorcnt	; Anzeige der Fehleranzahl
		inc	de
		inc	de
		ld	a, 30h ; '0'
		or	b		; B = Nr des fehlerhaften 2K-Bereichs
		ld	(de), a		; Anzeige als ASCII
		pop	de
		push	bc
		push	hl
		call	scroll_up	; Bildschirm scrollen
		jp	tprom24

;-----------------------------------------------------------------------------
; Testprogramm BWS EC00-EFFF
;-----------------------------------------------------------------------------

tpramb:		call	bckup_bws
		ld	hl, 0EC00h
		ld	de, 0F000h
		call	tpram21
		jp	rst_bws

;-----------------------------------------------------------------------------
; Testprogramm Farb-BWS	E800-EBFF
;-----------------------------------------------------------------------------

tpramf:		call	bckup_bws
		ld	hl, 0E800h
		ld	de, 0EC00h
		call	tpram21
		jp	rst_bws

;-----------------------------------------------------------------------------
; Testprogramm RAM 0000-3FFF
;-----------------------------------------------------------------------------

tpram1:		ld	hl, 330h
		ld	de, 4000h
tpram11:	call	tpram21
		jp	loc_95B8

;-----------------------------------------------------------------------------
; Testprogramm RAM 4000-7FFF
;-----------------------------------------------------------------------------

tpram2:		ld	hl, 4000h
		ld	de, 8000h
		jp	tpram11

;-----------------------------------------------------------------------------
; Testprogramm RAM 8000-BFFF
;-----------------------------------------------------------------------------

tpram3:		ld	hl, 8000h
		ld	de, 0C000h
		jp	tpram11
;
tpram21:	ld	b, 0
tpram22:	push	hl
tpram23:	ld	(hl), b
		call	is_end
		jr	nz, tpram23
		ld	hl, 0
tpram24:	inc	hl
		ld	a, 0FFh
		cp	h
		jr	nz, tpram24
		pop	hl
		push	hl
tpram25:	ld	a, (hl)
		cp	b
		call	nz, sub_95FB
		call	is_end
		jr	nz, tpram25
		pop	hl
		ld	a, 11h
		add	a, b
		ld	b, a
		cp	10h
		jr	nz, tpram22
		ld	b, 55h ; 'U'
		push	hl
tpram26:	ld	(hl), b
		call	sub_95F5
		jr	nz, tpram26
		pop	hl
		push	hl
		ld	b, 55h ; 'U'
tpram27:	ld	a, (hl)
		cp	b
		call	nz, sub_95FB
		call	sub_95F5
		jr	nz, tpram27
		pop	hl
		push	hl
tpram28:	ld	(hl), l
		call	is_end
		jr	nz, tpram28
		pop	hl
tpram29:	ld	a, (hl)
		cp	l
		call	nz, sub_95FA
		call	is_end
		jr	nz, tpram29
		ret
		pop	hl
		ret

;-----------------------------------------------------------------------------
; Testprogramm 
;-----------------------------------------------------------------------------

tpbild:		call	bckup_bws
		ld	a, (311h)
		bit	0, a
		jr	z, tpbild3
		call	cls		; BWS löschen
		call	consi		; Eingabe 1 Zeichen nach A
		ld	hl, 0EC00h
		ld	de, 14h
		ld	c, 18h
tpbild1:	ld	b, 14h
tpbild2:	ld	(hl), 7Fh ; ''
		inc	hl
		djnz	tpbild2
		add	hl, de
		dec	c
		jr	nz, tpbild1
		call	consi		; Eingabe 1 Zeichen nach A
tpbild3:	call	cls		; BWS löschen
		ld	hl, 0EF97h
		ld	de, 0EF98h
		call	sub_962E
		ld	hl, 0EC00h
		ld	de, 0EC01h
		call	sub_962E
		ld	b, 15h
		ld	de, 27h	; '''
tpbild4:	add	hl, de
		ld	(hl), 0
		inc	hl
		ld	(hl), 0
		djnz	tpbild4
		ld	hl, 0EECEh
		ld	de, 4
		ld	a, 70h ; 'p'
tpbild5:	add	hl, de
		ld	b, 24h ; '$'
tpbild6:	ld	(hl), a
		inc	hl
		inc	a
		jr	z, tpbild7
		djnz	tpbild6
		jp	tpbild5
tpbild7:	ld	hl, 0EC52h
		ld	a, 1
		ld	c, 20h ; ' '
tpbild8:	ld	b, 12h
tpbild9:	ld	(hl), c
		inc	hl
		inc	hl
		inc	c
		jr	z, tpbild10
		djnz	tpbild9
		push	de
		add	a, e
		ld	e, a
		add	hl, de
		pop	de
		sub	e
		neg
		jp	tpbild8

tpbild10:	ld	de, 282h
		ld	a, (311h)
		bit	0, a
		jr	z, tpbild11
		ld	hl, aWeiterDurchDru ; "WEITER DURCH DRUECKEN EINER TASTE "
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		call	consi		; Eingabe 1 Zeichen nach A
		jp	rst_bws

tpbild11:	ld	hl, aEsGehtGleichWe ; "ES GEHT GLEICH WEITER !"
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		ld	b, 0
		ld	c, 0
tpbild12:	dec	c
		jr	nz, tpbild12
		dec	b
		jr	nz, tpbild12
		jp	rst_bws

;-----------------------------------------------------------------------------
; Testprogramm Spielhebel
;-----------------------------------------------------------------------------

tpsph:		call	bckup_bws
		call	cls		; BWS löschen
		ld	hl, aSpielhebel1Spi ; "SPIELHEBEL 1 = *	  SPIELHEBEL 2 = #"
		call	print0
		call	print0
		ld	hl, 0ED00h
		ld	(313h),	hl
		ld	hl, 0ED20h
		ld	(315h),	hl
tpsph1:		ld	c, 6
		call	5
		ld	a, b
		ld	b, 23h ; '#'
		ld	hl, (313h)
		call	sph
		ld	(313h),	hl
		ld	a, c
		ld	b, 2Ah ; '*'
		ld	hl, (315h)
		call	sph
		ld	(315h),	hl
		cp	20h ; ' '
		jp	z, rst_bws
		ld	b, 14h
tpsph2:		ld	c, 0
tpsph3:		dec	c
		jr	nz, tpsph3
		dec	b
		jr	nz, tpsph2
		jp	tpsph1

sph:		cp	0
		ret	z
		cp	20h ; ' '
		ret	z
		ld	(hl), 20h ; ' '
		cp	0Fh
		ret	p
		cp	1
		jr	nz, sph5
		ld	de, 1
sph1:		add	hl, de
		push	af
		ld	a, 0EBh	; 'ë'
		cp	h
		jr	nz, sph4
		ld	de, 2F8h
sph2:		add	hl, de
sph3:		pop	af
		ld	(hl), b
		ret

sph4:		ld	a, 0EFh	; 'ï'
		cp	h
		jr	nz, sph3
		ld	de, 0FD08h
		jp	sph2

sph5:		cp	2
		jr	nz, sph6
		ld	de, 0FFFFh
		jp	sph1

sph6:		cp	4
		jr	nz, sph7
		ld	de, 28h	; '('
		jp	sph1

sph7:		cp	5
		jr	nz, sph8
		ld	de, 29h	; ')'
		jp	sph1

sph8:		cp	6
		jr	nz, sph9
		ld	de, 27h	; '''
		jp	sph1

sph9:		cp	8
		jr	nz, sph10
		ld	de, 0FFD8h
		jp	sph1

sph10:		cp	9
		jr	nz, sph11
		ld	de, 0FFD9h
		jp	sph1

sph11:		cp	0Ah
		ret	nz
		ld	de, 0FFD7h
		jp	sph1

sub_9A1F:	di
		ld	a, 17h
		out	(PIO1AS), a	; PIO1 A Kommando
		ld	a, 0FFh
		out	(PIO1AS), a	; PIO1 A Kommando
		ld	a, 17h
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 0FFh
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 17h
		out	(PIO2AS), a	; Tastatur-PIO2	A Kommando
		ld	a, 0FFh
		out	(PIO2AS), a	; Tastatur-PIO2	A Kommando
		ld	a, 17h
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		ld	a, 0FFh
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
loc_9A40:	ld	a, 3
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		out	(CTC1),	a	; System CTC1 Anwenderport
		out	(CTC2),	a	; System CTC2 Systemuhr
		out	(CTC3),	a	; System CTC3 Systemuhr
		ei
		ret

sub_9A4C:	push	bc
		push	de
		ld	d, 3
		ld	bc, 0FFFFh
loc_9A53:	dec	b
		jr	nz, loc_9A53
		dec	c
		jr	nz, loc_9A53
		dec	d
		jr	nz, loc_9A53
		pop	de
		pop	bc
		ret

;-----------------------------------------------------------------------------
; Testprogramm 
;-----------------------------------------------------------------------------

tpfarb:		call	bckup_bws
		ld	hl, 0E800h
		ld	de, 0E801h
		ld	bc, 400h
		xor	a
		ld	(hl), a
		ldir
		ld	a, 20h ; ' '
		ld	(hl), a
		ld	bc, 3C0h
		ldir
		ld	hl, 0EBD7h
		ld	b, 27h ; '''
		ld	c, 17h
		ld	a, 1
		call	tpfarb1
		ld	a, 23h ; '#'
		call	tpfarb1
		ld	a, 45h ; 'E'
		call	tpfarb1
		ld	a, 67h ; 'g'
		call	tpfarb1
		jp	tpfarb2

tpfarb1:	ld	de, 0FC29h
		add	hl, de
		push	bc
		ld	de, 1
		call	sub_9B43
		ld	de, 28h	; '('
		ld	b, c
		call	sub_9B43
		ld	de, 0FFFFh
		pop	bc
		push	bc
		call	sub_9B43
		ld	de, 0FFD8h
		ld	b, c
		call	sub_9B43
		ld	a, 0B6h	; '¶'
		ld	de, 400h
		add	hl, de
		ld	(hl), 0BCh ; '¼'
		ld	de, 1
		pop	bc
		push	bc
		call	sub_9B44
		ld	(hl), 0BDh ; '½'
		ld	de, 28h	; '('
		ld	a, 0B5h	; 'µ'
		ld	b, c
		call	sub_9B44
		ld	(hl), 0BAh ; 'º'
		ld	de, 0FFFFh
		ld	a, 0FBh	; 'û'
		pop	bc
		push	bc
		call	sub_9B44
		ld	(hl), 0BBh ; '»'
		ld	de, 0FFD8h
		ld	a, 0B4h	; '´'
		ld	b, c
		call	sub_9B44
		pop	bc
		dec	b
		dec	b
		dec	c
		dec	c
		ret

tpfarb2:	ld	hl, 0E8A4h
		ld	de, 8
		xor	a
		call	sub_9B58
		ld	de, 0ECA4h
		ld	b, 8
tpfarb3:	push	bc
		ld	a, 4
tpfarb4:	ld	hl, aFarbtest	; "FARBTEST"
		ld	bc, 8
		ldir
		dec	a
		jr	nz, tpfarb4
		push	hl
		ld	hl, 8
		add	hl, de
		ex	de, hl
		pop	hl
		pop	bc
		djnz	tpfarb3
		call	loc_9B84
		ld	a, 81h ; 'ü'
		ld	hl, 0EA88h
		ld	de, 0EA89h
		ld	bc, 18h
		ld	(hl), a
		ldir
		ld	a, (311h)
		bit	0, a
		jr	z, tpfarb5
		ld	hl, aWeiterNachTast ; "WEITER NACH TASTENDRUCK"
		ld	de, 0EE88h
		ld	bc, 18h
		ldir
		call	consi		; Eingabe 1 Zeichen nach A
tpfarb5:	jp	rst_bws

tpfarb6:	ld	(hl), a
		inc	hl
		djnz	tpfarb6
		ret

sub_9B43:	ld	(hl), a
sub_9B44:	or	a
		add	hl, de
		djnz	sub_9B43
		ret

sub_9B49:	ld	b, 8
loc_9B4B:	push	bc
		ld	b, 4
loc_9B4E:	ld	(hl), a
		inc	hl
		djnz	loc_9B4E
		add	a, 10h
		pop	bc
		djnz	loc_9B4B
		ret

sub_9B58:	push	af
		call	sub_9B49
		pop	af
		or	a
		add	hl, de
		inc	a
		cp	8
		jr	nz, sub_9B58
		ret

aFarbtest:	db "FARBTEST"
aWeiterNachTast:db "WEITER NACH TASTENDRUCK"

loc_9B84:	xor	a
		ld	b, 8

loc_9B87:	out	(88h), a
		call	sub_9A4C
		add	a, 8
		djnz	loc_9B87
		ret

sub_9B91:	ld	de, 0Eh
		ld	a, (315h)
		cp	31h ; '1'
		jr	z, loc_9BA6
		add	hl, de
		cp	32h ; '2'
		jr	z, loc_9BA6
		add	hl, de
		cp	33h ; '3'
		jr	z, loc_9BA6
		add	hl, de

loc_9BA6:	ex	de, hl
		ret
	
; end of "ROM"
		end
