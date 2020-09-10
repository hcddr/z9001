;-----------------------------------------------------------------------------
; reass. V. Pohlers 070716
;-----------------------------------------------------------------------------
;
; File Name   :	grtest.com
; Base Address:	0000h Range: 1000h - 1400h Loaded length: 0400h

; Ansteuerung des Grafikzusatz
; 6144 Byte (0..17FFh) externer	Speicher (256x192 Pixel), wird über Ports angesteuert
; der Speicheraufbau ist linear, dh. 20h Bytes = 256 Pixel pro Zeile, fortlaufend

		cpu	z80

port_0B8h	equ	0B8h		; Farbe	+ Grafik ein/aus
					; 7 6 5	4 3 2 1	0
					; | | |	| | | |	|
					; | --|-- | --|--
					; |   |	  |   PAPER (BGR)
					; |   |	  Grafik ein/aus
					; |   INK (BGR)
					; RAND
port_0B9h	equ	0B9h		; Adresse für internen Speicher
					; die unteren Adressleitungen werden mit OUT (C)
					; direkt ausgegeben, die oberen	Adressdaten liegen
					; über Register	B auf dem Adressbus
port_0BAh	equ	0BAh		; Daten

;Farben
;000	schwarz
;001	rot
;010	grün
;011	gelb
;100	blau
;101	purpur	(violett)
;110	cyan	(hellblau)
;111	weiá


;-----------------------------------------------------------------------------
; Sprungverteiler
;-----------------------------------------------------------------------------

		org 1000h

		jp	SPTEST
aSptest:	db	"SPTEST  ",0
		jp	UMSCHALT
aUmschalt:	db	"UMSCHALT",0
		jp	STIM
aStim:		db	"STIM    ",0
		jp	GRAFIK
aGrafik:	db	"GRAFIK  ",0

;-----------------------------------------------------------------------------
; Speichertest
; Testen des externen Speichers von 6144x8 Bit (0..17FFh)
;-----------------------------------------------------------------------------

SPTEST:		ld	c, 9
		ld	de, aSpeichertest ; "SPEICHERTEST\r\n"
		call	5
		ld	a, 8
		ld	hl, 0
		ld	(curbyte), a	; current value	in external RAM
		ld	(curadr), hl	; current address in external RAM
		ld	(cnterr), hl	; Anzahl Fehler
sptest1:	call	writeadr
		call	readadr
		call	testadr
		call	stoptst2	; Testen auf Drücken der 'STOP'-Taste
					; out: Cy=0 - 'STOP'-Taste gedrückt
		ret	nc		; wenn STOP gedrückt wurde
		ld	a, (curbyte)	; current value	in external RAM
		inc	a
		ld	(curbyte), a	; current value	in external RAM
		inc	hl
		ld	(curadr), hl	; current address in external RAM
		ld	a, 0
		cp	l
		jr	nz, sptest1
		ld	a, 18h		; Adresse 1800h	erreicht? Dann Ende
		cp	h
		jr	nz, sptest1
		ld	hl, (cnterr)	; Anzahl Fehler
		call	outhlx		; Ausgabe HL als Hex-Zahl incl 'H'
		ld	c, 9
		ld	de, aFehler	; " FEHLER"
		call	5
		ret

;-----------------------------------------------------------------------------
; Bildschirmumschaltung testen
; Mit den Tasten 'G' und 'A' wird zwischen den Bildschirmen umgeschaltet
; Ende mit 'STOP'
;-----------------------------------------------------------------------------

UMSCHALT:	ld	c, 9
		ld	de, aSchirmumschalt ; "\rSCHIRMUMSCHALTUNG\r\n"
		call	5
umschalt1:	ld	c, 0Bh
		call	5
		cp	0
		jr	z, umschalt1
		ld	c, 1
		call	5
		res	5, a
		cp	'A'
		jr	z, umschalt2	; alphanum. Bildschirm
		cp	'G'
		jr	z, umschalt3	; Grafikbildschirm
		cp	3		; STOP?
		jr	nz, umschalt1
		ret

umschalt2:	ld	a, 11100010b	; alphanum. Bildschirm
		out	(port_0B8h),	a
		ld	c, 9
		ld	de, aAlphaSchirm ; "\rALPHA SCHIRM"
		call	5
		jr	umschalt1

umschalt3:	ld	a, 10011100b	; Grafikbildschirm
		out	(port_0B8h),	a
		ld	c, 9
		ld	de, aGrafikSchirm ; "\rGRAFIK SCHIRM"
		call	5
		jr	umschalt1

;-----------------------------------------------------------------------------
; Stimulus-Programm
; zyklisches Ansteuern der Adreßleitungen
; Ende mit STOP
;-----------------------------------------------------------------------------

STIM:		ld	c, 9
		ld	de, aStimulusProg_ ; "\rSTIMULUS PROG."
		call	5
		ld	a, 55h ; 'U'
		ld	hl, 0
		ld	de, 400h
		ld	(curbyte), a	; current value	in external RAM
		ld	(curadr), hl	; current address in external RAM
		di
stim1:		call	writeadr
		call	stoptst1	; wurde	'STOP'-Taste gedrückt?
					; Out: Z=1, wenn 'STOP'-Taste gedrückt
		ret	z
		ld	a, (curbyte)	; current value	in external RAM
		cpl
		ld	(curbyte), a	; current value	in external RAM
		ld	b, 0F7h	; '÷'
		and	b
		out	(port_0B8h),	a
		ld	a, (curbyte)	; current value	in external RAM
		ld	hl, (curadr)	; current address in external RAM
		ld	l, a
		add	hl, de
		ld	(curadr), hl	; current address in external RAM
		jr	stim1

;-----------------------------------------------------------------------------
; Farbtest
; 'A' - alphanum. Bildschirm
; 'G' - 4 verschachtelte Rechtecke grün auf schwarz
; 'R' - 4 verschachtelte Rechtecke rot auf schwarz
; 'B' - 4 verschachtelte Rechtecke blau auf rot
; Ende mit 'STOP'
;-----------------------------------------------------------------------------

GRAFIK:		ld	c, 9
		ld	de, aTestprogrammGr ; "\rTESTPROGRAMM GRAFIK\r\n"
		call	5
grafik1:	ld	c, 0Bh
		call	5
		cp	0
		jr	z, grafik1
		ld	c, 1
		call	5
		res	5, a
		cp	'A'
		jr	z, grafik2	; alphanum. Bildschirm
		cp	'G'
		jr	z, grafik3	; grün auf schwarz
		cp	'R'
		jr	z, grafik4	; rot auf schwarz
		cp	'B'
		jr	z, grafik5	; blau auf rot
		cp	3
		jr	nz, grafik1
		ret

grafik2:	ld	a, 0		; alphanum. Bildschirm
		out	(port_0B8h),	a
		ld	c, 9
		ld	de, aAlphaSchirm ; "\rALPHA SCHIRM"
		call	5
		jr	grafik1

grafik3:	ld	a, 10101000b	; grün auf schwarz
		out	(port_0B8h),	a
		ld	c, 9
		ld	de, aGrafikSchirm ; "\rGRAFIK SCHIRM"
		call	5
		jr	grafik6

grafik4:	ld	a, 10011000b	; rot auf schwarz
		out	(port_0B8h),	a
		ld	c, 9
		ld	de, aGrafikSchirm ; "\rGRAFIK SCHIRM"
		call	5
		jr	grafik6

grafik5:	ld	a, 11001001b	; blau auf rot
		out	(port_0B8h),	a
		ld	c, 9
		ld	de, aGrafikSchirm ; "\rGRAFIK SCHIRM"
		call	5

grafik6:	call	clrmem		; externen Speicher löschen (mit 00)
		ld	hl, 0		; erste	Zeile
		ld	(curadr), hl	; current address in external RAM
		call	fillmem1	; eine Linie zeichnen
		ld	hl, 17E0h	; letzte Zeile
		ld	(curadr), hl	; current address in external RAM
		call	fillmem1	; eine Linie zeichnen
		ld	hl, 20h	; ' '   ; zweite Zeile
		ld	(curadr), hl	; current address in external RAM
		ld	e, 190
grafik7:	call	fillmem2	; vertikale Seiten des Rechtecks
		dec	e
		jr	nz, grafik7
;
		call	plotrows	; horizontale Linien zeichnen
		call	plotcols	; vertikale Linien zeichnen
		jp	grafik1


;-----------------------------------------------------------------------------
; Lesen und Schreiben im ext. Grafikspeicher
;
; IN r,(C), OUT (C),r, and the Block I/O instructions actually place the entire BC 
; register on the address bus. Similarly IN A,(n) and OUT (n),A put A * 256 + n on 
; the address bus.
;-----------------------------------------------------------------------------

writeadr:	ld	bc, (curadr)	; current address in external RAM
		ld	a, c
		ld	c, port_0BAh
		out	(port_0B9h), a	; out low address
		ld	a, (curbyte)	; current value	in external RAM
		out	(c), a		; out data and high address
		ret

readadr:	ld	bc, (curadr)	; current address in external RAM
		ld	a, c
		ld	c, port_0BAh
		out	(port_0B9h), a	; Adresse ausgeben
		in	a, (c)		; Datenbyte aus	Speicher lesen
		ld	(rdbyte), a	; gelesenes Byte
		ret

testadr:	ld	a, (curbyte)	; current value	in external RAM
		ld	b, a
		ld	a, (rdbyte)	; gelesenes Byte
		cp	b
		call	nz, anzfehler	; Anzeige fehlerhafte Adresse
		ret

;-----------------------------------------------------------------------------
; Anzeige fehlerhafte Adresse
;-----------------------------------------------------------------------------

anzfehler:	ld	c, 9
		ld	de, aAdresse	; "\r\nADRESSE "
		call	5
		ld	hl, (curadr)	; current address in external RAM
		call	outhlx		; Ausgabe HL als Hex-Zahl incl 'H'
		ld	c, 9
		ld	de, aSollwert	; "\r\nSOLLWERT "
		call	5
		ld	a, (curbyte)	; current value	in external RAM
		ld	d, a
		call	outax		; Ausgabe A als	Hex-Zahl incl 'H'
		ld	c, 9
		ld	de, aIstwert	; "\r\nISTWERT "
		call	5
		ld	a, (rdbyte)	; gelesenes Byte
		ld	a, d
		call	outax		; Ausgabe A als	Hex-Zahl incl 'H'
		ld	c, 2
		ld	e, 0Dh
		call	5
		ld	e, 0Ah
		call	5
		push	hl
		ld	hl, (cnterr)	; Anzahl Fehler
		inc	hl
		ld	(cnterr), hl	; Anzahl Fehler
		pop	hl
		ret

;-----------------------------------------------------------------------------
; hexadezimale Anzeige
;-----------------------------------------------------------------------------

; Ausgabe HL als Hex-Zahl incl 'H'
outhlx:		call	outhl		; Ausgabe HL als Hex-Zahl
		ld	e, 'H'
		ld	c, 2
		call	5
		ret

; Ausgabe A als	Hex-Zahl incl 'H'
outax:		call	outhx		; Ausgabe A als	Hex-Zahl
		ld	e, 'H'
		ld	c, 2
		call	5
		ret

; Ausgabe HL als Hex-Zahl
outhl:		ld	d, h
		call	outhx		; Ausgabe A als	Hex-Zahl
		ld	d, l

; Ausgabe A als	Hex-Zahl
outhx:		ld	a, d
		rrca
		rrca
		rrca
		rrca
		call	outhx1
		ld	a, d
outhx1:		and	0Fh
		cp	0Ah
		jr	c, outhx2
		add	a, 7
outhx2:		add	a, 30h 		; '0'
		ld	e, a
		ld	c, 2
		call	5
		ret

;-----------------------------------------------------------------------------
; Testen auf Drücken der 'STOP'-Taste
;-----------------------------------------------------------------------------

; Testen auf Drücken der 'STOP'-Taste
; out: Cy=0 - 'STOP'-Taste gedrückt

stoptst2:	push	bc
		ld	b, a
		ld	c, 11		; CSTS
		call	5
		and	a
		jr	z, stoptst21	; wenn keine Taste gedrückt
		ld	c, 1		; CONSI
		call	5
		cp	3		; 'STOP' ?
		scf
		jr	nz, stoptst22
stoptst21:	ccf
stoptst22:	ld	a, b
		pop	bc
		ret

; wurde	'STOP'-Taste gedrückt?
; Out: Z=1, wenn 'STOP'-Taste gedrückt

stoptst1:	ld	a, 10111111b
		out	(90h), a	; Tastatur-PIO2A
		nop
		in	a, (91h)
		cp	10111111b	; Tastatur-PIO2B
		ret	nz		; Test Taste S77 ('STOP')
		ei
		ret

;-----------------------------------------------------------------------------
; externen Speicher löschen (mit 00)
;-----------------------------------------------------------------------------

clrmem:		ld	a, 0
		ld	hl, 0
		ld	(curbyte), a	; current value	in external RAM
		ld	(curadr), hl	; current address in external RAM
clrmem1:	call	writeadr
		inc	hl
		ld	(curadr), hl	; current address in external RAM
		ld	a, 0
		cp	l
		jr	nz, clrmem1
		ld	a, 18h
		cp	h		; Adresse 1800h	erreicht? Dann Ende
		jr	nz, clrmem1
		ret

;-----------------------------------------------------------------------------
; externen Speicher füllen
;-----------------------------------------------------------------------------

; schreibt 32 x	0FFh ab	curadr in Speicher (eine Zeile,	alle Pixel setzen)

fillmem1:	ld	a, 0FFh
		ld	(curbyte), a	; current value	in external RAM
		ld	hl, (curadr)	; current address in external RAM
		ld	d, 32
fillmem11:	call	writeadr
		inc	hl
		ld	(curadr), hl	; current address in external RAM
		dec	d
		jr	nz, fillmem11
		ret


; schreibt linken und rechten Rand einer Zeile (für vertikale Seiten des Rechtecks)

fillmem2:	ld	d, 31
		ld	a, 80h ; '€'
		ld	(curbyte), a	; current value	in external RAM
		ld	hl, (curadr)	; current address in external RAM
		call	writeadr
		inc	hl
		ld	(curadr), hl	; current address in external RAM
		dec	d
		ld	a, 0
		ld	(curbyte), a	; current value	in external RAM
fillmem21:	call	writeadr
		inc	hl
		ld	(curadr), hl	; current address in external RAM
		dec	d
		jr	nz, fillmem21
		ld	a, 1
		ld	(curbyte), a	; current value	in external RAM
		call	writeadr
		inc	hl
		ld	(curadr), hl	; current address in external RAM
		ret

;-----------------------------------------------------------------------------
; Linien zeichnen
;-----------------------------------------------------------------------------

; zeichnet (H) Bytes lange horizontale Linie ab	(IX)

plotrow:	ld	l, 0
		ld	(curadr), ix	; current address in external RAM
plotrow1:	call	writeadr
		inc	ix
		ld	(curadr), ix	; current address in external RAM
		inc	l
		ld	a, h
		cp	l
		jr	nz, plotrow1
		ret

; zeichnet (H) Zeilen lange vertikale Linie ab (IX)

plotcol:	ld	l, 0
		ld	de, 20h	; ' '   ; Offset zur nächsten Bildzeile
		ld	(curadr), ix	; current address in external RAM
plotcol1:	call	writeadr
		add	ix, de
		ld	(curadr), ix	; current address in external RAM
		inc	l
		ld	a, h
		cp	l
		jr	nz, plotcol1
		ret

; horizontale Linien zeichnen

plotrows:	ld	a, 0FFh
		ld	(curbyte), a	; current value	in external RAM
		ld	ix, 0B70h
		ld	h, 1
		call	plotrow		; zeichnet (H) Bytes lange horizontale Linie ab	(IX)
		ld	ix, 96Eh
		ld	h, 5
		call	plotrow		; zeichnet (H) Bytes lange horizontale Linie ab	(IX)
		ld	ix, 76Ch
		ld	h, 9
		call	plotrow		; zeichnet (H) Bytes lange horizontale Linie ab	(IX)
		ld	ix, 0C90h
		ld	h, 1
		call	plotrow		; zeichnet (H) Bytes lange horizontale Linie ab	(IX)
		ld	ix, 0E6Eh
		ld	h, 5
		call	plotrow		; zeichnet (H) Bytes lange horizontale Linie ab	(IX)
		ld	ix, 106Ch
		ld	h, 9
		call	plotrow		; zeichnet (H) Bytes lange horizontale Linie ab	(IX)
		ret

; vertikale Linien zeichnen

plotcols:	ld	a, 1
		ld	(curbyte), a	; current value	in external RAM
		ld	ix, 0B8Fh
		ld	h, 8
		call	plotcol		; zeichnet (H) Zeilen lange vertikale Linie ab (IX)
		ld	ix, 98Dh
		ld	h, 39
		call	plotcol		; zeichnet (H) Zeilen lange vertikale Linie ab (IX)
		ld	ix, 78Bh
		ld	h, 71
		call	plotcol		; zeichnet (H) Zeilen lange vertikale Linie ab (IX)
		nop
		ld	a, 1
		ld	(curbyte), a	; current value	in external RAM
		ld	ix, 0B90h
		ld	h, 8
		call	plotcol		; zeichnet (H) Zeilen lange vertikale Linie ab (IX)
		ld	ix, 992h
		ld	h, 39
		call	plotcol		; zeichnet (H) Zeilen lange vertikale Linie ab (IX)
		ld	ix, 794h
		ld	h, 71
		call	plotcol		; zeichnet (H) Zeilen lange vertikale Linie ab (IX)
		ret


;-----------------------------------------------------------------------------
; Texte
;-----------------------------------------------------------------------------

aSpeichertest:	db	"SPEICHERTEST\r\n",0
aAdresse:	db	"\r\nADRESSE ",0
aSollwert:	db	"\r\nSOLLWERT ",0
aIstwert:	db	"\r\nISTWERT ",0
aFehler:	db	" FEHLER",0
aAlphaSchirm:	db	"\rALPHA SCHIRM",0
aGrafikSchirm:	db	"\rGRAFIK SCHIRM",0
aSchirmumschalt:db	"\rSCHIRMUMSCHALTUNG\r\n",0
aStimulusProg_:	db	"\rSTIMULUS PROG.",0
aTestprogrammGr:db	"\rTESTPROGRAMM GRAFIK\r\n",0

;-----------------------------------------------------------------------------
; Arbeitsspeicher
;-----------------------------------------------------------------------------

		org 3FFAh

rdbyte:		ds 1			; gelesenes Byte
curbyte:	ds 1			; current value	in external RAM
cnterr:		ds 1			; Anzahl Fehler
		ds 1
curadr:		ds 1			; current address in external RAM


		end
