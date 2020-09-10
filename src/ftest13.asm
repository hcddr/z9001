;-----------------------------------------------------------------------------
; File Name   :	hobby\z9001 ftest\ftest.com
; Format      :	Binary file
; Base Address:	0000h Range: 8000h - 8800h Loaded length: 0800h
; reass 10.04.2008 vpohlers
; FRUEHAUSFALLTEST KC87 (Vers. 1.3)
; Prüfadapter am User-Port anschließen!
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
;default:	1	0	1	0	1	0	1	1	b
;		TPROM1	|TPROM2	|TPRAM1	|TPRAM2	|TPRAMB	|TPRAMF	|TPCEA	|TPTAST
unk_311:	equ	311h		; 0, nicht verwendet? (nur main)
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


		org 8000h

		jp	main
		db	"#       ",0
		db    0

; Sprungtabelle der einzelnen Tests
loc_800D:	jp	tprom1		; Testprogramm OS F000-FFFF
		jp	tprom2		; Testprogramm ROM-BASIC C000-E7FF
		jp	tpram1		; Testprogramm RAM 0000-3FFF
		jp	tpram2		; Testprogramm RAM 4000-7FFF
		jp	tpramb		; Testprogramm BWS EC00-EFFF
		jp	tpramf		; Testprogramm Farb-BWS	E800-EBFF
		jp	tpcea		; Testprogramm CTC u. E/A
		jp	tptast		; Testprogramm Tastatur

; Prüfsummen von 2K Bereichen
; (vom oberen Speicher nach unten hin)
chksum_os12:	dw	06E87h		; Testdaten OS 1.2
		dw	050B8h		; Summe	F000-F7FF
chksum_basic85:	dw	060D0h		; Testdaten BASIC-85 (M511)
		dw	07934h		; Summe	D800-DFFF
		dw	08A08h		; Summe	D000-D7FF
		dw	0F72Ch		; Summe	C800-CFFF
		dw	05AA6h		; Summe	C000-C7FF
chksum_os13:	dw	0B287h		; Testdaten OS 1.3
		dw	051B8h
chksum_basic86:	dw	0F603h		; Testdaten BASIC-86 (BM608)
		dw	07934h
		dw	08A08h
		dw	0F72Ch
		dw	05AA6h

inttab:		jp	IR_CTC0		; Interruptroutinen
		jp	IR_CTC1		; Interruptroutine CTC1
		jp	IR_CTC3		; Interruptroutine CTC3
		jp	IR_PIO1A	; Interruptroutine PIO1A (?)
		jp	IR_PIO1B	; Interruptroutine PIO1	B Anwenderport
		jp	IR_PIO2A	; Interruptroutine Tastatur-PIO2 A, setzt D:=1
		jp	IR_PIO2B	; Interruptroutine Tastatur-PIO2 B, setzt E:=1

; BWS löschen
cls:		ld	hl, 0EC00h
		ld	de, 0EC01h
		ld	(hl), 20h 	; ' '
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
		ld	c, (hl)		; Länge
		inc	hl
		ldir			; Text in BWS schreiben
		ret

aFruehausfallte:db	33,"FRUEHAUSFALLTEST KC87 (Vers. 1.3)"
aRam100003fff:	db	15,"RAM1: 0000-3FFF"
aRam240007fff:	db	15,"RAM2: 4000-7FFF"
aRom2C000E7ff:	db	15,"ROM2: C000-E7FF"
aRamfE800Ebff:	db	15,"RAMF: E800-EBFF"
aRambEc00Efff:	db	15,"RAMB: EC00-EFFF"
aRom1F000Ffff:	db	15,"ROM1: F000-FFFF"
aTestfolge:	db	10,"TESTFOLGE:"

; alle Testnamen müssen 6 Byte belegen (test_all)
; Reihenfolge wie loc_800D
aTprom1:	db	6,"TPROM1"
aTprom2:	db	6,"TPROM2"
aTpram1:	db	6,"TPRAM1"
aTpram2:	db	6,"TPRAM2"
aTpramb:	db	6,"TPRAMB"
aTpramf:	db	6,"TPRAMF"
aTpcea:		db	6,"TPCEA "
aTptast:	db	6,"TPTAST"

aTestlauf:	db	9,"TESTLAUF:"
aFehler:	db	6,"FEHLER"

; UP zu loc_8152, loc_815D
sub_8148:	inc	de
		inc	de
		ld	a, 30h ; '0'
		or	b
		ld	(de), a
		call	scroll_up	; Bildschirm scrollen
		ret

; UP zu tpcea
loc_8152:	call	print_errorcnt	; Anzeige der Fehleranzahl
		ld	b, 1
		call	sub_8148
		jp	loc_833D

; UP zu tpcea
loc_815D:	call	print_errorcnt	; Anzeige der Fehleranzahl
		ld	b, 2
		call	sub_8148
		jp	loc_833D

; Interruptvektoren ab 240h aufbauen
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

; Interruptroutine CTC0
IR_CTC0:	exx			
		ld	d, 0
		inc	b
		exx
		ld	a, 10000011b	; Interrupt ein
		out	(PIO1AS), a	; PIO1 A Kommando
		ei
		reti

; Interruptroutine CTC1		
IR_CTC1:	push	af		
		ld	a, 00000011b	; DI, RESET
		out	(CTC1), a	; CTC 1
		pop	af
		ei
		reti
 
; Interruptroutine PIO1A (?) CTC2 (?)
IR_PIO1A:	exx			
		inc	c
		ld	d, 1
		exx
		ld	a, 00000011b	; Interrupt aus
		out	(PIO1AS), a	; PIO1 A Kommando
		ei
		reti

; Interruptroutine CTC3
IR_CTC3:	di			
		push	af
		push	hl
		ld	hl, unk_326
		inc	(hl)
		ld	hl, unk_320
		xor	a
		cp	(hl)
		jr	nz, IR_CTC32
		inc	hl
		cp	(hl)
		jr	nz, IR_CTC32
		inc	hl
		cp	(hl)
		jr	nz, IR_CTC32
		ld	a, 10000111b
		out	(CTC1), a	; CTC 1
		ld	a, 00000101b
		out	(CTC1), a	; CTC 1
IR_CTC31:	pop	hl
		pop	af
		ei
		reti

IR_CTC32:	ld	a, 00000011b
		out	(CTC1), a	; CTC 1
		jr	IR_CTC31
 

; Interruptroutine PIO1	B Anwenderport
IR_PIO1B:	ld	a, 1		
		ld	(unk_32A), a
		ei
		reti

;-----------------------------------------------------------------------------
; Testprogramm CTC u. E/A
;-----------------------------------------------------------------------------

tpcea:		di			 
		ld	a, 00000011b	; Interrupt aus
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		call	build_ivtab	; Interruptvektoren ab 240h aufbauen
		ld	a, lo(iv_pio1b) ; Interruptvektor
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 11001111b	; Bit-E/A-Modus
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 10101010b	; E/A-Bits
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		xor	a
		ld	(unk_32A), a
		ld	bc, 8
		ld	de, 0FEFEh
		exx
		ld	bc, 9700h
		ld	de, 0FCFFh
		exx
;
tpcea1:		exx
		ld	a, b
		exx
		di
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, e
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ei
		exx
		ld	a, e
		exx
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		ld	a, d
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		call	wait14		; kurze	Warteschleife
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		exx
		cp	d
		exx
		jp	nz, loc_8152
		ld	a, (unk_32A)
		cp	0
		jp	z, loc_815D
		xor	a
		ld	(unk_32A), a
		rlc	e
		xor	a
		cp	b
		jp	z, tpcea2
		rlc	d
		rlc	d
		exx
		rlc	d
		rlc	d
		exx
;
tpcea2:		ld	a, 1
		xor	b
		ld	b, a
		dec	c
		jp	nz, tpcea1
		exx
		ld	a, 1
		cp	c
		exx
		jp	z, tpcea3
		di
		ld	a, 11001111b	; Bit-E/A-Modus
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 01010101b	; E/A-Bits
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ei
		ld	bc, 8
		ld	de, 2FEh
		exx
		ld	bc, 0B701h
		ld	de, 300h
		exx
		jp	tpcea1
;
tpcea3:		di
		ld	a, 11110111b	; Interruptsteuerwort: EI, AND,	LOW, MASK
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		xor	a		; MASKE	= 00h
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		xor	a
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		ei
		ld	a, 10101010b
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		call	wait14		; kurze	Warteschleife
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		cp	0FFh
		jp	nz, loc_8152
		ld	a, (unk_32A)
		cp	0
		jp	z, loc_815D
		jp	loc_833D


; kurze	Warteschleife
wait14:		push	bc
		ld	b, 14h
wait141:	dec	b
		ld	a, b
		cp	0
		jr	nz, wait141
		pop	bc
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

; Anzeige der auszuführenden Tests
sub_82BC:	rlc	c
		call	c, print1	; Textausgabe (HL) an Zeile 22,	Spalte 1 mit Retten der	Register
		ld	a, l
		add	a, 7
		ld	l, a
		jr	nc, loc_82C8
		inc	h
loc_82C8:	djnz	sub_82BC
		ret


; Textausgabe (HL) an Zeile 22,	Spalte 1 mit Retten der	Register
print1:		push	bc
		push	hl
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		pop	hl
		pop	bc
		ret

; UP zu main
sub_82D3:	call	scroll_up	; Bildschirm scrollen
		ld	de, 40*22+1	; Zeile 22, Spalte 1
		ld	hl, aTestlauf	; "TESTLAUF:"
		call	print		; Textausgabe (HL) an BWS-Position (DE)
		ld	hl, unk_324
		ld	b, 2
		call	tohex0		; B Bytes ab (HL) als Hex-Ascii	ablegen	ab (DE+1)
		ld	de, 40*22+21	; Zeile 22 Spalte 21
;
prnt_error:	ld	hl, aFehler	; "FEHLER"
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
		djnz	tohex		; B Bytes ab (HL) als Hex-Ascii	ablegen	ab (DE)
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
		djnz	test_all	; nachsten Test
		ret

; einzelnen Test ausführen
; HL = Sprungbefehl zum Test
; DE = Name Test
test_single:	push	bc
		push	de
		push	hl
		ex	de, hl
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		pop	hl
		push	hl
		jp	(hl)		; zum Test springen

;
loc_833D:	xor	a		; kein Speichertest
		ld	(unk_316), a	; setzen
		pop	hl
		pop	de
		pop	bc
		ret

; Anzeige der Fehleranzahl
print_errorcnt:	push	bc
		push	hl
; Auswertung Speicherfehler
		ld	a, (unk_316)	; Speichertest?
		cp	0
		jr	z, print_ecnt2	; nein
		cp	1		; ROM-Test ? 
		jr	z, print_ecnt1	; ja
		ld	a, '$'
		ld	(unk_318), a	; Merker für Fehler bei RAM-Test
		jr	print_ecnt2
print_ecnt1:	ld	a, '$'
		ld	(unk_317), a	; Merker für Fehler bei ROM-Test
; Anzahl der Fehler um 1 erhöhen und Anzahl anzeigen
print_ecnt2:	ld	de, 1
		ld	hl, (unk_320)	; Gesamtzanzahl der Fehler
		add	hl, de
		ld	(unk_320), hl
		jr	nc, print_ecnt3
		ld	hl, unk_322	; Gesamtzanzahl der Fehler (3. Byte)
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
		jp	loc_833D

; Teste, ob HL<DE
is_end:		inc	hl
		ld	a, d
		cp	h
		ret

; UP zu tpram
sub_8395:	rrc	b
		jp	is_end		; Teste, ob HL<DE

; UP zu tpram
sub_839A:	ld	b, l

; UP zu tpram
sub_839B:	push	de
		ld	(unk_312), sp
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
		pop	af
		pop	bc
		pop	hl
		pop	de
		ret

;-----------------------------------------------------------------------------
; Einsprung bei	Kaltstart (Kdo "#      ")
;-----------------------------------------------------------------------------

main:		xor	a
		ld	(unk_316), a
		ld	a, ' '
		ld	(unk_317), a	; Merker für Fehler bei ROM-Test
		ld	(unk_318), a	; Merker für Fehler bei RAM-Test
		call	cls		; BWS löschen
		ld	bc, 40*24 + 20	; 40*24 + 20
		ld	hl, 0E800h
		ld	de, 0E800h+1
		ld	(hl), 00110000b	; gelb auf schwarz
		ldir
		ld	hl, aFruehausfallte ; "FRUEHAUSFALLTEST KC87 (Vers. 1.3)"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	scroll_up	; Bildschirm scrollen
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		ld	a, 10101011b
		ld	(unk_310), a	; bitweise sind	die abzuarbeitenden Tests markiert
		xor	a
		ld	(unk_311), a
; Test RAM2 nötig?
		ld	hl, 7FFFh
		call	is_ram		; test,	ob auf (HL) RAM	vorliegt
		jr	nz, main1
		ld	hl, aRam240007fff ; "RAM2: 4000-7FFF"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		ld	a, 00010000b
		call	mark_test	; Bitweises markieren der zu erfolgenden Tests
; Test TPROM2 nötig?
main1:		ld	hl, 0C007h	; Test,	ob ROM-BASIC vorhanden ist
		ld	a, 42h ; 'B'    ; 'B' des Startkommandos 7F 7F 'BASIC'
		cp	(hl)
		jr	nz, main2
		ld	hl, aRom2C000E7ff ; "ROM2: C000-E7FF"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		ld	a, 01000000b
		call	mark_test	; Bitweises markieren der zu erfolgenden Tests
; Test TPRAMF nötig?
main2:		ld	hl, 0EBFFh
		call	is_ram		; test,	ob auf (HL) RAM	vorliegt
		jr	nz, main3
		ld	hl, aRamfE800Ebff ; "RAMF: E800-EBFF"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		ld	a, 00000100b
		call	mark_test	; Bitweises markieren der zu erfolgenden Tests

main3:		ld	hl, aRambEc00Efff ; "RAMB: EC00-EFFF"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	scroll_up	; Bildschirm scrollen
;
		ld	hl, aTestfolge	; "TESTFOLGE:"
		call	print0		; Textausgabe (HL) an Zeile 22,	Spalte 1
		call	scroll_up	; Bildschirm scrollen
;
		ld	hl, unk_310	; bitweise sind	die abzuarbeitenden Tests markiert
		ld	c, (hl)
		ld	hl, aTprom1	; "TPROM1"
		ld	b, 8
		call	sub_82BC	; Anzeige der auszuführenden Tests
;
		ld	hl, unk_320
		ld	b, 5
		ld	a, 0
main4:		ld	(hl), a
		inc	hl
		djnz	main4
		call	sub_82D3
		call	scroll_up	; Bildschirm scrollen
;
		di
		call	build_ivtab	; Interruptvektoren ab 240h aufbauen
		call	init_ctc	; CTC programmieren
		ei
;
main5:		ld	hl, loc_800D	; Tabelle der Testprogramme
		ld	a, (unk_310)	; bitweise sind	die abzuarbeitenden Tests markiert
		ld	c, a
		ld	de, aTprom1	; "TPROM1"
		ld	b, 8		; Anzahl der Testprogramme
		call	test_all	; Tests abarbeiten
		ld	hl, (unk_323)
		inc	hl
		ld	(unk_323), hl
		call	sub_82D3
		call	scroll_up	; Bildschirm scrollen
		jp	main5

;-----------------------------------------------------------------------------
; Testprogramm OS F000-FFFF
;-----------------------------------------------------------------------------

tprom1:		ld	a, (0F3F4h)	; OS-Version (lo-Teil)
		ld	de, chksum_os12	; Prüfsummen OS	1.2
		cp	2
		jr	z, tprom11	; wenn OS 1.2
		ld	de, chksum_os13	; Prüfsummen OS	1.3
;
tprom11:	ld	hl, 0FFFFh
		ld	b, 2		; Anzahl der 2K-Bereiche
		jr	tprom22

;-----------------------------------------------------------------------------
; Testprogramm ROM-BASIC C000-E7FF
;-----------------------------------------------------------------------------

tprom2:		ld	a, (0E05Dh)	; Basic-Werweiterung
		ld	de, chksum_basic85
		cp	43h ; 'C'       ; mittleres C von "CIRCLE"? Dann BM608 testen
		jr	nz, tprom21
		ld	de, chksum_basic86
;
tprom21:	ld	a, (unk_317)	; Merker für Fehler bei ROM-Test (' ' oder '$')
		ld	(0EC00h+21*40+21), a	; BWS Zeile 21, Spalte 21
		ld	a, 1
		ld	(unk_316), a	; Speichertest ROM merken
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
		jp	loc_833D
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

tpramb:		call	bckup_bws	; Testprogramm BWS EC00-EFFF
		ld	hl, 0EC00h
		ld	de, 0F000h
		call	tpram21
		jp	rst_bws


;-----------------------------------------------------------------------------
; Testprogramm Farb-BWS	E800-EBFF
;-----------------------------------------------------------------------------

tpramf:		call	bckup_bws	; Testprogramm Farb-BWS	E800-EBFF
		ld	hl, 0E800h
		ld	de, 0EC00h
		call	tpram21
		jp	rst_bws


;-----------------------------------------------------------------------------
; Testprogramm RAM 0000-3FFF
;-----------------------------------------------------------------------------

tpram1:		ld	hl, unk_330	; Testprogramm RAM 0330-3FFF
		ld	de, 4000h
;
tpram11:	call	tpram21
		jp	loc_833D


;-----------------------------------------------------------------------------
; Testprogramm RAM 4000-7FFF
;-----------------------------------------------------------------------------

tpram2:		ld	hl, 4000h	; Testprogramm RAM 4000-7FFF
		ld	a, (unk_318)	; Merker für Fehler bei RAM-Test (' ' oder '$')
		ld	(0EFD5h), a	
		;; vp: eigentlich Adresse UR1-Treiber für READER
		;; Schreibfehler ?? richtig ist wohl 0EF5Dh, das wäre 
		;; ld	(0EC00h+21*40+21), a	; BWS Zeile 21, Spalte 21
		ld	a, 2	
		ld	(unk_316), a	; Speichertest RAM merken
		ld	de, 8000h
		jp	tpram11
;

tpram21:	ld	b, 0
tpram22:	push	hl
tpram23:	ld	(hl), b
		call	is_end		; Teste, ob HL<DE
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
		call	nz, sub_839B
		call	is_end		; Teste, ob HL<DE
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
		call	sub_8395
		jr	nz, tpram26
		pop	hl
		push	hl
		ld	b, 55h ; 'U'
tpram27:	ld	a, (hl)
		cp	b
		call	nz, sub_839B
		call	sub_8395
		jr	nz, tpram27
		pop	hl
		push	hl
tpram28:	ld	(hl), l
		call	is_end		; Teste, ob HL<DE
		jr	nz, tpram28
		pop	hl
tpram29:	ld	a, (hl)
		cp	l
		call	nz, sub_839A
		call	is_end		; Teste, ob HL<DE
		jr	nz, tpram29
		ret

;-----------------------------------------------------------------------------
; Testprogramm Tastatur
;-----------------------------------------------------------------------------

tptast:		di			; Testprogramm Tastatur
		ld	a, lo(iv_pio2a) ; Interruptvektor
		out	(PIO2AS), a	; Tastatur-PIO2	A Kommando
		ld	a, 11001111b	; Bit-E/A-Modus
		out	(PIO2AS), a	; Tastatur-PIO2	A Kommando
		xor	a		; alle Leitungen Ausgabe
		out	(PIO2AS), a	; Tastatur-PIO2	A Kommando
		ld	a, 00010111b	; DI, OR, LOW, Maske folgt
		out	(PIO2AS), a	; Tastatur-PIO2	A Kommando
		xor	a		; Interruptmaske 0 (alle Leitungen können Int. auslösen)
		out	(PIO2AS), a	; Tastatur-PIO2	A Kommando
		ld	a, lo(iv_pio2b) ; Interruptvektor
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		ld	a, 11001111b	; Bit-E/A-Modus
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		ld	a, 11111111b	; alle Leitungen Eingabe
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		ld	a, 10010111b	; EI, OR, LOW, Maske folgt
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		xor	a		; Interruptmaske 0 (alle Leitungen können Int. auslösen)
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		ld	a, 11111111b	; alle Tastatur-Spalten	auf High
		out	(PIO2AD), a	; Tastatur-PIO2	A Daten
		ei
		ld	c, 11111110b	; Spalte 8 aktivieren
		ld	b, 8
;
tptast1:	ld	de, 0
		ld	a, c		; Spalte aktivieren
		out	(PIO2AD), a	; Tastatur-PIO2	A Daten
		push	bc
		ld	c, 0Ah		; kurze	Pause
;
tptast2:	dec	c
		ld	a, c
		cp	0
		jr	nz, tptast2
		pop	bc
		ld	a, d		; PIO2A-Interrupt? (Spalte)
		cp	0		; wird von Interruptroutine auf	1 gesetzt
		jr	nz, tptast4	; Interupt von Spalte ist ein Fehler
		ld	a, e		; PIO2B-Interrupt? (Zeile)
		cp	0		; wird von Interruptroutine auf	1 gesetzt
		jr	z, tptast4	; keine	Taste gedrückt -> Fehler
		rlc	c		; nächste Spalte (nach links)
		djnz	tptast1		; bis 8	Spalten	fertig
		di
		ld	a, 11001111b	; Bit-E/A-Modus
		out	(PIO2AS), a	; Tastatur-PIO2	A Kommando
		ld	a, 11111111b	; alle Leitungen Eingabe
		out	(PIO2AS), a	; Tastatur-PIO2	A Kommando
		ld	a, 11001111b	; Bit-E/A-Modus
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		xor	a		; alle Leitungen Ausgabe
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		ei
		ld	bc, 801h	; 8 Zeilen, Beginn mit oberster	Zeile
;
tptast3:	ld	a, c		; Zeile	aktivieren
		out	(PIO2BD), a	; Tastatur-PIO2	B Daten
		call	wait14		; kurze	Warteschleife
		in	a, (PIO2AD)	; Tastatur-PIO2	A Daten
		cp	c
		jr	nz, tptast4
		rlc	c
		djnz	tptast3
		jp	loc_833D
;
tptast4:	call	print_errorcnt	; Anzeige der Fehleranzahl
		jp	loc_833D

IR_PIO2B:	ld	e, 1		; Interruptroutine Tastatur-PIO2 B, setzt E:=1
		ei
		reti

IR_PIO2A:	ld	d, 1		; Interruptroutine Tastatur-PIO2 A, setzt D:=1
		ei
		reti

; CTC programmieren
init_ctc:	ld	a, lo(iv_ctc0) 	; Interruptvektor
		out	(CTC0), a	; CTC0
		ld	a, 00000011b	; DI,Zeitgeber,Vorteiler 16,Zeitkonstantenstart,keine Zeitkonstante, Reset
		out	(CTC0), a	; CTC0
		out	(CTC1), a	; CTC1
		ld	a, 00000111b	; DI,Zeitgeber,Vorteiler 16,Zeitkonstantenstart,Zeitkonstante folgt, Reset
		out	(CTC2), a	; CTC2
		ld	a, 0Eh		; Zeitkonstante
		out	(CTC2), a	; CTC2
		ld	a, 11000111b	; EI,Zähler,Vorteiler 16,Zeitkonstantenstart,Zeitkonstante folgt, Reset
		out	(CTC3), a	; CTC3
		ld	a, 0Bh		; Zählwert
		out	(CTC3), a	; CTC3
		ret

		end
