; File Name   :	GRPLOT.rom
; Format      :	Binary File
; Base Address:	0000h Range: 9800h - A800h Loaded length: 1000h

	cpu	Z80

GRAFVER 	EQU	'OS'		; für Z9001-OS (original)
;GRAFVER 	EQU	'CPM'		; Anpassung für CPM vp 2007

;für CPM:
; 1. basic_8k_kern kompilieren mit
; 	ROMTYP	EQU	"RAM"
; 	BASTYP	EQU	"BASIC_86"
; 	CPM	EQU	1
; 2. basg_as3 kompilieren
; 3. inc-Dateien  basg_as3.inc und basic_8k_kern.inc kopieren
; 4. graf passend zur bei 2 erstellten BASIC-Version kompileren

;GRPLOT ist ROM-fähig und verwendet den Speicherbereich von 234H bis 29AH als Arbeitsspeicher.
;GRAF ist ROM-fähig und verwendet die Speicherbereiche von 234H bis 29AH und von 7FDDH bis 7FFFH als Arbeitsspeicher.

unk_234	equ	0234h
unk_239	equ	0239h
unk_23B	equ	023Bh
unk_23D	equ	023Dh
unk_23F	equ	023Fh
pltxposhome	equ	0241h		; 2 Byte x-Home
pltyposhome	equ	0243h		; 2 Byte y-Home
pltxpos	equ	0245h			; 2 Byte x-Position
pltypos	equ	0247h			; 2 Byte y-Position
unk_249	equ	0249h
unk_24A	equ	024Ah
unk_24B	equ	024Bh
unk_24C	equ	024Ch
unk_24E	equ	024Eh
unk_24F	equ	024Fh
unk_250	equ	0250h
unk_252	equ	0252h
unk_254	equ	0254h
unk_256	equ	0256h
unk_258	equ	0258h
unk_25A	equ	025Ah
unk_25C	equ	025Ch
unk_25E	equ	025Eh
unk_260	equ	0260h
unk_261	equ	0261h
unk_263	equ	0263h
unk_265	equ	0265h
unk_267	equ	0267h
;
unk_268	equ	0268h
unk_26A	equ	026Ah
unk_26D	equ	026Dh
unk_273	equ	0273h
unk_278	equ	0278h
unk_27B	equ	027Bh
unk_27C	equ	027Ch

fscalex	equ	027Dh			; SCALE x-Faktor (4 Byte Float)
fscaley	equ	0281h			; SCALE y-Faktor (4 Byte Float)

pltparambuf	equ	0285h		; Buffer für Parameterübergabe für phys. Treiber
; ber  21

unk_29A		equ	029Ah
unk_29B		equ	029Bh
unk_29C		equ	029Ch

; Ansteuerung des Grafikzusatz
; Code in GRPLOT enthalten
GR_CTRL		equ	0B8h		; Farbe + Grafik ein/aus
					; 7 6 5 4 3 2 1 0
					; | | | | | | | |
					; | --|-- | --|--
					; |   |   |   PAPER (BGR)
					; |   |   Grafik ein/aus
					; |   INK (BGR)
					; RAND


	IF GRAFVER='OS'

; Betriebssystem
atrib		equ	0027h		; aktuelles Farbattribut
SYSBDS		equ	0005h
PRNST		equ	0F3E2h		; BIOS PRNST

	include	basic.inc

;DATEN AUS BASIC KERN

;WINJP		equ	035Ah
;WRA1		equ	03E5h		; ARITHMETIKREGISTER 1

;ADRESSEN AUS BASIC KERN86

;CPREG		equ	0C689h
;IOTEST		equ	0C697h
IOTEST_x5	equ	IOTEST + 5
;FOR1		equ	0C7F2h
FOR1_x14	equ	FOR1 + 14h
;TCHAR		EQU	0C8BDh
;TCHAR1		equ	0C8BEh
;CPCOMM		equ	0C8D6h
;EPRVL4		equ	0C96Ch
;EPRVL3		equ	0C96Fh
;SNALY		equ	0CD3Ah
;FRE3		equ	0D0B1h
;LEN1		equ	0D330h
;ARGVL1		equ	0D421h
;ADD2		equ	0D461h
;ADD3		equ	0D466h
;ADD5		equ	0D46Fh
;MUL1		equ	0D59Ah
;DIV1		equ	0D5F5h
;OPARST		equ	0D6C8h
;OPKOP		equ	0D6DDh
;OPKOP1		equ	0D6E0h
;OPLAD		equ	0D6EEh
;OPTRAN		equ	0D6F7h
;SQR		equ	0D91Fh
;COS		equ	0DA70h
;SIN		equ	0DA76h
;COSL		equ	0DABAh

;ADRESSEN AUS BASIC ERWEITERUNG BM608

; include	bm608_ROM86.inc

;snerr		equ	0E144H
;fcerr		equ	0E14BH

	ELSEIF GRAFVER='CPM'

; Betriebssystem
atrib		equ	0027h		; aktuelles Farbattribut
SYSBDS		equ	0F314h		; entspricht call 5 des Z9001-Systems
PRNST		equ	0F3E2h		; BIOS PRNST

		xinclude	basic_8k_kern_RAM86CPM.inc

IOTEST_x5	equ	IOTEST + 5
FOR1_x14	equ	FOR1 + 14h

;ADRESSEN AUS BASIC ERWEITERUNG

		xinclude	basg_as3.inc

;Versionstest
	if ROMTYP <> "RAM"
		ERROR "FALSCHER ROM-TYP!"
	endif

	if CPM <> 1
		ERROR "KEINE CP/M-VERSION!"
	endif


	ENDIF

;Versionstest
	if BASTYP <> "BASIC_86"
		ERROR "FALSCHER BASIC-TYP!"
	endif


;-----------------------------------------------------------------------------
; Start
;-----------------------------------------------------------------------------

	IF GRAFVER='OS'

		org	9800h

	ELSEIF GRAFVER='CPM'
;bei CP/M ist ein Loader-Programm nötig, der den Treiber
;an den originalen Platz im Speicher verschiebt
		org	100h

		ld	hl,grafstart
		ld	de,plsv
		ld	bc,grafend-grafstart+1
		ldir
		ld	de,grafmsg
		ld	c,9
		call	5
		ret

grafmsg		db	"GRAF.COM wurde geladen$"

grafstart	equ	$

		phase	8E60h
	ENDIF

;-----------------------------------------------------------------------------
; Sprungverteiler für physischen Treiber
; in:	C	Nummer des UP
;	(WINJP)	Bit0=1 => Plotter, sonst Vollgrafik
;-----------------------------------------------------------------------------

plsv:		ld	b, 0		; interner Sprungverteiler
		dec	c
		push	hl		; HL sichern
		ld	hl, plsv3	; Returnadresse
		push	hl		; kellern
		ld	a, (WINJP)
		bit	0, a
		jr	nz, plsv1
		ld	hl, plsvtab1
		jr	plsv2
plsv1:		ld	hl, plsvtab2
plsv2:		add	hl, bc
		add	hl, bc
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		jp	(hl)		; UP ausführen, Ret-Adr. ist plsv3
;
plsv3:		pop	hl		; HL restaurieren
		ret

; Sprungverteiler für SCREEN 0 (Vollgrafik)
plsvtab1:	dw locret_A32B
		dw locret_A32B
		dw locret_A32B
		dw locret_A32B
		dw locret_A32B
		dw locret_A32B
		dw locret_A32B
		dw locret_A32B
		dw locret_A32B
		dw locret_A32B
		dw locret_A32B
		dw locret_A32B

; Sprungverteiler für SCREEN 1 (PLOTTER)
plsvtab2:	dw pl_Set
		dw pl_line
		dw pl_circle
		dw pl_paint		; paint ist nicht implementiert
		dw pl_label
		dw pl_size
		dw pl_zero
		dw pl_home
		dw pl_gcls
		dw pl_point
		dw pl_xpos
		dw pl_ypos

		newpage
;*****************************************************************************
; PLOTTER-TREIBER
;*****************************************************************************

;-----------------------------------------------------------------------------
; Fkt. 01h Setzen eines Punktes
; DE = parambuf
; 	parambuf+0: Offs-Mode
; 	parambuf+1: 2 Byte X
; 	parambuf+3: 2 Byte Y
; 	parambuf+5: Stift
; Offs-Mode: 	-1 Step, 1 absolut
; Stift: 	1 Vordergrundfarbe, 0 Hintergrundfarbe
;-----------------------------------------------------------------------------

pl_Set:		ex	de, hl
		ld	a, (hl)		; Offs-Mode
		dec	a
		inc	hl
		call	pl_pset2	; 2 Werte nach DE und BC holen
		ld	a, (hl)		; Stift
		jr	z, pl_pset1	; wenn Offs.Mode absolut
		and	a
		jp	z, sub_9192	; wenn Stift heben
		jp	loc_91AE	; wenn Stift senken
;
pl_pset1:	and	a
		jp	z, sub_9134	; wenn Stift heben
		jp	loc_918D	; wenn Stift senken

; 2 Werte nach DE und BC holen
pl_pset2:	ld	e, (hl)
		inc	hl
		ld	d, (hl)
		inc	hl
		ld	c, (hl)
		inc	hl
		ld	b, (hl)
		inc	hl
		ret

;-----------------------------------------------------------------------------
; Fkt. 02h Zeichnen Linie oder Rechteck
; DE = parambuf
; 	parambuf+0: Offs-Mode 1. Punkt
; 	parambuf+1: 2 Byte X 1. Punkt
; 	parambuf+3: 2 Byte Y 1. Punkt
; 	parambuf+5: Offs-Mode 2. Punkt
; 	parambuf+6: 2 Byte X 2. Punkt
; 	parambuf+8: 2 Byte Y 2. Punkt
; 	parambuf+10: Stift
; 	parambuf+11: Box
; Offs-Mode: 	-1 Step, 1 absolut, 0 1. Punkt ist aktuelle Koord.
; Stift: 	1 Vordergrundfarbe, 0 Hintergrundfarbe
; Box:		0 Linie, 1 Rechteck, [2 ausgefülltes Rechteck ?]
;-----------------------------------------------------------------------------

pl_line:	push	de
		pop	ix
		ld	a, (ix+0)	; Offs-Mode 1. Punkt
		and	a
		push	ix
		pop	hl
		inc	hl
		jr	z, pl_line1	; wenn Offs.Mode aktuelle Koord.
		call	pl_pset2	; 2 Werte nach DE und BC holen
		dec	a
		jr	z, pl_line2	; wenn Offs.Mode absolut
		call	sub_9192
; STEP 1. Punkt
pl_line1:	ld	hl, (pltxpos)
		ld	de, (pltxposhome)
		and	a
		sbc	hl, de
		ld	(ix+1),	l
		ld	(ix+2),	h
		ld	hl, (pltypos)
		ld	de, (pltyposhome)
		and	a
		sbc	hl, de
		ld	(ix+3),	l
		ld	(ix+4),	h
		jr	pl_line3
pl_line2:	call	sub_9134
;
pl_line3:	ld	a, (ix+5)	; Offs-Mode 2. Punkt
		dec	a
		jr	z, pl_line4
; STEP 2. Punkt
		ld	hl, (pltxpos)
		ld	de, (pltxposhome)
		and	a
		sbc	hl, de
		ld	e, (ix+6)
		ld	d, (ix+7)
		add	hl, de
		ld	(ix+6),	l	; X2 mit Offset
		ld	(ix+7),	h
		ld	hl, (pltypos)
		ld	bc, (pltyposhome)
		and	a
		sbc	hl, bc
		ld	c, (ix+8)
		ld	b, (ix+9)
		add	hl, bc
		ld	(ix+8),	l	; Y2 mit Offset
		ld	(ix+9),	h
;
pl_line4:	ld	a, (ix+0Bh)	; BOX
		and	a
		ld	b, (ix+0Ah)	; Stift
		jr	nz, pl_line5	; wenn Rechteck zeichnen
		ld	a, b
		and	a
		jr	z, pl_line6
; Linie zeichnen
		call	pl_line7	; DE=X2, BC=Y2
		jp	sub_9188	; Linie zeichnen nach (X2,Y2)
; Rechteck zeichnen
pl_line5:	ld	a, b
		and	a
		jr	z, pl_line6
		ld	e, (ix+6)	; DE=X2
		ld	d, (ix+7)
		push	de
		ld	c, (ix+3)	; BC=Y1
		ld	b, (ix+4)
		call	sub_9188	; Linie zeichnen nach (X2,Y1)
		pop	de		; DE=X2
		ld	c, (ix+8)	; BC=Y2
		ld	b, (ix+9)
		push	bc
		call	sub_9188	; Linie zeichnen nach (X2,Y2)
		pop	bc		; BC=Y2
		ld	e, (ix+1)	; DE=X1
		ld	d, (ix+2)
		push	de
		call	sub_9188	; Linie zeichnen nach (X1,Y2)
		pop	de		; DE=X1
		ld	c, (ix+3)	; BC=Y1
		ld	b, (ix+4)
		call	sub_9188	; Linie zeichnen nach (X1,Y1)
pl_line6:	call	pl_line7
		jr	pl_home1
pl_line7:	ld	e, (ix+6)	; DE=X2, BC=Y2
		ld	d, (ix+7)
		ld	c, (ix+8)
		ld	b, (ix+9)
		ret

;-----------------------------------------------------------------------------
; Fkt. 07h Nullpunkt festlegen
; DE = parambuf
; 	parambuf+0: Offs-Mode
; 	parambuf+1: 2 Byte X
; 	parambuf+3: 2 Byte Y
; Offs-Mode: 	-1 Step, 1 absolut
;-----------------------------------------------------------------------------

pl_zero:	ex	de, hl
		ld	a, (hl)		; STEP?
		dec	a
		inc	hl
		call	pl_pset2	; 2 Werte nach DE und BC holen
		jr	z, pl_zero1	; wenn kein Step
		ld	hl, (pltxposhome)
		add	hl, de		; sonst STEP-Offset X addieren
		ld	(pltxposhome), hl
		ld	hl, (pltyposhome)
		add	hl, bc		; STEP-Offset Y addieren
		ld	(pltyposhome), hl
		ret
pl_zero1:	ld	(pltxposhome), de
		ld	(pltyposhome), bc
		ret

;-----------------------------------------------------------------------------
; Fkt. 09h Bildschirm löschen, Pointer auf (0,0) setzen
;-----------------------------------------------------------------------------

pl_gcls1:	ld	bc, 0
		ld	d, b
		ld	e, c
		ret

pl_gcls:	call	pl_gcls1
		call	pl_zero1

;-----------------------------------------------------------------------------
; Fkt. 08h Pointer auf Home setzen
;-----------------------------------------------------------------------------

pl_home:	call	pl_gcls1
pl_home1:	jp	sub_9134

;-----------------------------------------------------------------------------
; Fkt. 04h Paint
; DE = parambuf
; 	parambuf+0: Offs-Mode
; 	parambuf+1: 2 Byte X
; 	parambuf+3: 2 Byte Y
; 	parambuf+5: c
; 	parambuf+6: d
; Offs-Mode: 	-1 Step, 1 absolut
;-----------------------------------------------------------------------------

pl_paint:	ret

;-----------------------------------------------------------------------------
; Fkt. 03h Circle
; DE = parambuf
; 	parambuf+0: Offs-Mode
; 	parambuf+1: 2 Byte Integer X
; 	parambuf+3: 2 Byte Integer Y
; 	parambuf+5: 4 Byte Float radius
; 	parambuf+9: stift
; 	parambuf+10: 4 Byte Float anf-winkel
; 	parambuf+14: 4 Byte Float end-winkel
; 	parambuf+18: 4 Byte Float ellip
; Offs-Mode: 	-1 Step, 1 absolut
; Stift: 	1 Vordergrundfarbe, 0 Hintergrundfarbe
;-----------------------------------------------------------------------------

pl_circle:	ex	de, hl
		ld	a, (hl)
		dec	a
		push	af
		inc	hl
		call	pl_pset2	; 2 Werte nach DE und BC holen
		ld	hl, (pltypos)
		jr	nz, pl_circle1
		ld	hl, 0
pl_circle1:	add	hl, bc
		ld	(pltparambuf+3), hl
		pop	af
		push	hl
		ld	hl, (pltxpos)
		jr	nz, pl_circle2
		ld	hl, 0
pl_circle2:	add	hl, de
		ld	(pltparambuf+1), hl
		ex	de, hl
		pop	bc
		ld	a, (pltparambuf+9)
		or	a
		jp	z, sub_9134
		ld	hl, pltparambuf+5
		call	OPKOP
		call	SQR
		ld	bc, 8240h
		ld	de, 0
		call	DIV1
		ld	hl, unk_29B
		call	OPTRAN
		xor	a
		ld	(pltparambuf), a
		inc	a
		ld	c, a
		ld	hl, pltparambuf+10
		call	sub_9AA8
		push	de
		ld	c, 80h
		ld	hl, pltparambuf+14
		call	sub_9AA8
		pop	hl
		xor	a
		ex	de, hl
		call	CPREG		; vergleiche DE mit HL
		jr	nc, pl_circle3
		ld	hl, pltparambuf+14
		push	hl
		call	OPKOP
		ld	bc, 8349h
		ld	de, 0FDBh
		call	ADD5
		pop	hl
		call	OPTRAN
pl_circle3:	call	sub_90BF
		push	bc
		push	de
		ld	a, (pltparambuf)
		rra
		jr	nc, pl_circle4
		ld	bc, (pltparambuf+3)
		ld	de, (pltparambuf+1)
		call	sub_9134
		pop	de
		pop	bc
		call	sub_9188	; Linie zeichnen
		jr	pl_circle5
pl_circle4:	pop	de
		pop	bc
		call	sub_9134
pl_circle5:	ld	hl, pltparambuf+10
		call	OPKOP
		ld	hl, unk_29B
		call	OPLAD
		call	ADD5
		ld	hl, pltparambuf+14
		call	OPLAD
		ld	hl, WRA1+3
		ld	a, b
		cp	(hl)
		jr	nz, pl_circle6
		dec	hl
		ld	a, c
		cp	(hl)
		jr	nz, pl_circle6
		dec	hl
		ld	a, d
		cp	(hl)
		jr	nz, pl_circle6
		dec	hl
		ld	a, e
		cp	(hl)
pl_circle6:	push	af
		jr	nc, pl_circle7
		call	OPKOP1
pl_circle7:	ld	hl, pltparambuf+10
		call	OPTRAN
		call	sub_90BF
		call	sub_9188	; Linie zeichnen
		pop	af
		jr	z, pl_circle8
		jr	nc, pl_circle5
pl_circle8:	ld	a, (pltparambuf)
		rla
		ld	bc, (pltparambuf+3)
		ld	de, (pltparambuf+1)
		jr	nc, pl_circle9
		call	sub_9188	; Linie zeichnen
		jr	pl_circle10
pl_circle9:	call	sub_9134
pl_circle10:	ret

sub_90BF:	ld	hl, pltparambuf+10
		call	OPKOP
		call	SIN
		ld	hl, pltparambuf+5
		call	OPLAD
		call	MUL1
		ld	a, (unk_29A)
		cp	81h
		push	af
		jr	nc, loc_90E2
		ld	hl, pltparambuf+18
		call	OPLAD
		call	MUL1
loc_90E2:	call	EPRVL3
		ld	hl, (pltparambuf+3)
		add	hl, de
		ex	(sp), hl
		push	hl
		ld	hl, pltparambuf+10
		call	OPKOP
		call	COS
		ld	hl, pltparambuf+5
		call	OPLAD
		call	MUL1
		pop	af
		jr	c, loc_910E
		call	OPARST
		ld	hl, pltparambuf+18
		call	OPKOP
		pop	bc
		pop	de
		call	DIV1
loc_910E:	call	EPRVL3
		ld	hl, (pltparambuf+1)
		add	hl, de
		ex	de, hl
		pop	bc
		ret

;-----------------------------------------------------------------------------
; Fkt. 0Bh x-Position abfragen
;-----------------------------------------------------------------------------

pl_xpos:	ld	hl, (pltxpos)
		ld	de, (pltxposhome)
pl_xpos1:	and	a
		sbc	hl, de
		ld	b, l
		ld	a, h
pl_xpos2:	jp	FRE3

;-----------------------------------------------------------------------------
; Fkt. 0Ch  y-Position abfragen
;-----------------------------------------------------------------------------

pl_ypos:	ld	hl, (pltypos)
		ld	de, (pltyposhome)
		jr	pl_xpos1

;-----------------------------------------------------------------------------
; Fkt. 0Ah Punkt abfragen
; DE = parambuf
; 	parambuf+0: Offs-Mode
; 	parambuf+1: 2 Byte X
; 	parambuf+3: 2 Byte Y
; Offs-Mode: 	-1 Step, 1 absolut
;-----------------------------------------------------------------------------

pl_point:	xor	a
		ld	b, a
		jr	pl_xpos2

;-----------------------------------------------------------------------------

sub_9134:	ld	a, 0
		ld	l, a
		ld	h, a
loc_9138:	push	hl
		call	sub_9566
		pop	hl
		ld	(unk_24C), hl
		ld	hl, (pltxposhome)
		add	hl, de
		ld	(unk_250), hl
		ld	hl, (pltyposhome)
loc_914A:	add	hl, bc
		ld	(unk_252), hl
		xor	a
		ld	(unk_254), a
		ld	hl, unk_250
		call	sub_935B
loc_9158:	ld	a, (unk_254)
		and	a
		jr	nz, loc_916A
		ld	a, (unk_24C)
		and	a
		ret	z
		call	sub_954C
		xor	a
		jp	sub_954C

; [X][Y] OUT OF RANGE
loc_916A:	ld	de, 'YX'
		cp	3
		jr	z, loc_9177
		ld	e, ' '		; nur 'Y '
		rrca
		jr	nc, loc_9177
		dec	d		; nur 'X '
loc_9177:	ld	(unk_234), de
		ld	de, unk_234
		call	PRNST
		ld	de, aOutOfRange	; " OUT OF RANGE\r\n"
		call	PRNST
		ret

; Linie zeichnen nach (DE,BC)
sub_9188:	call	sub_91B3
		jr	loc_9138

loc_918D:	ld	hl, 80h
		jr	loc_9138

sub_9192:	ld	hl, 0
loc_9195:	push	hl
		call	sub_9566
		pop	hl
		ld	(unk_24C), hl
		ld	hl, (pltxpos)
		add	hl, de
		ld	(unk_250), hl
		ld	hl, (pltypos)
		jr	loc_914A

sub_xxx1:	call	sub_91B3
		jr	loc_9195

loc_91AE:	ld	hl, 80h
		jr	loc_9195

sub_91B3:	call	sub_9566
		ld	hl, (unk_24A)
		ld	l, 0
		ret

;-----------------------------------------------------------------------------
; Fkt. 06h Size, Festlegung der Schriftart
; DE = parambuf
;	parambuf+8: a
; 	parambuf+9: 4 Byte Float b
; 	parambuf+13: 4 Byte Float l
; 	parambuf+17: 4 Byte Float r
; a: Abstand 0 - gleichabständig, 80h - proportional
;-----------------------------------------------------------------------------

pl_size:	call	sub_9566
		ex	de, hl
		ld	bc, 8
		ld	de, unk_239
		ldir
		ld	a, (hl)
		ld	(unk_249), a
		ret

;-----------------------------------------------------------------------------
; Fkt. 05h Ausgabe einer Zeichenkette
; DE = parambuf
; 	parambuf+0: 2 Byte Länge Zeichenkette (max. 255!)
; 	parambuf+2: 2 Byte Adr. Zeichenkette
; 	parambuf+4: Stift
; Stift: 	1 Vordergrundfarbe, 0 Hintergrundfarbe
;-----------------------------------------------------------------------------

pl_label:	ex	de, hl
		ld	a, (hl)
		inc	hl
		inc	hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		inc	a
		push	af
		push	de
		call	sub_9566
		ld	hl, 0
		ld	(unk_24C), hl
		ld	hl, (pltxpos)
		ld	(unk_256), hl
		ld	(unk_25A), hl
		ld	hl, (pltypos)
		ld	(unk_258), hl
		ld	(unk_25C), hl
pl_label1:	pop	hl
		pop	de
		dec	d
		jp	z, loc_9352
		ld	a, (hl)		; nächstes auszugebendes Zeichen
		push	de
		push	hl
		cp	0Dh		; Zeilenwechsel speziell behandeln
		jp	z, pl_label17
		cp	18h
		jr	c, pl_label2	; gültiges Zeichen? (18h..7Fh)
		cp	80h
		jr	c, pl_label3
pl_label2:	ld	a, ' '		; sonst Leerzeichen
;
pl_label3:	sub	10h
		ld	hl, labeltab
		ld	b, 0
		ld	d, a		; D = zu zeichnendes Zeichen (-10h)
pl_label4:	ld	a, (hl)
		and	8Fh
		inc	a
		rlca			; Bit7 nach Cy kopieren
		sra	a		; A enthält jetzt wieder die unteren 4 Bit
		dec	d		; nächste Zeichenposition
		jr	z, pl_label6	; gesuchte Zeichenposition erreicht
		jr	nc, pl_label5	; wenn Bit7 nicht gesetzt war, dann kein Byte weiter in Liste
		inc	hl		; sonst ein Byte weiter in Liste
pl_label5:	ld	c, a		; Anzahl genutzter Bytes für Zeichen
		add	hl, bc		; überspringen
		jr	pl_label4	; Adr. des nächsten Zeichens
pl_label6:	ld	e, b		; B ist 0
		jr	nc, pl_label7
		inc	e
pl_label7:	ld	d, a
		ex	de, hl
		ld	(unk_265), hl
		pop	hl
		push	hl
		ld	a, (hl)
		cp	18h		; Umlautcode
		jr	nz, pl_label8
;
		inc	hl		; nächstes Zeichen holen
		ld	a, (hl)
		ld	c, 3
		ld	hl, umlauttab
		cpir			; zulässsig als Umlaut?
pl_label8:	ld	a, (de)
		push	de
		jr	nz, pl_label9
		or	50h
pl_label9:	ld	d, b
		ld	e, b
		rlca
		rlca
		jr	nc, pl_label10
		ld	d, 0FCh
pl_label10:	rlca
		jr	nc, pl_label11
		ld	e, 0FDh
pl_label11:	ld	hl, unk_249
		and	(hl)
		rlca
		jr	nc, pl_label12
		dec	e
pl_label12:	ex	de, hl
		ld	(unk_263), hl
pl_label13:	ld	hl, unk_265+1
		dec	(hl)
		pop	hl
		inc	hl
		jr	z, pl_label14
		push	hl
		ld	a, (hl)
		push	af
		rlca
		rlca
		rlca
		rlca
		and	7
		ld	hl, unk_263
		add	a, (hl)
		call	sub_9319
		pop	af
		push	af
		and	0Fh
		ld	hl, unk_263+1
		add	a, (hl)
		call	sub_9335
		ld	hl, (unk_258)
		add	hl, de
		ld	(unk_252), hl
		ld	hl, (unk_256)
		pop	de
		add	hl, de
		ld	(unk_250), hl
		pop	af
		ld	hl, unk_24C
		or	(hl)
		dec	hl
		and	(hl)
		ld	(unk_24C+1), a
		ld	hl, unk_250
		call	sub_935B
		ld	a, (unk_24B)
		call	sub_954C
		xor	a
		ld	(unk_24C), a
		jr	pl_label13
pl_label14:	ld	a, (unk_265)
		and	a
		jr	z, pl_label15
		ld	a, (hl)
		and	80h
		ld	(unk_24C), a
		ld	a, (hl)
		and	7Fh
		jp	pl_label3
pl_label15:	xor	a
		call	sub_954C
		pop	hl
		push	hl
		ld	a, (hl)
		cp	20h ; ' '
		jr	c, pl_label16
		ld	a, (unk_263)
		add	a, a
		add	a, 8
		call	sub_9319
		ld	hl, (unk_256)
		add	hl, bc
		ld	(unk_256), hl
		ld	hl, (unk_258)
		add	hl, de
		ld	(unk_258), hl
pl_label16:	pop	hl
		inc	hl
		push	hl
		ld	c, 0Bh		;CSTS, Abfrage Status CONST
		call	SYSBDS
		cp	3
		jp	nz, pl_label1
;
		ld	hl, unk_256
		call	sub_935B
		ld	a, 11100010b	; RAND, cyan auf grün, Grafik aus
		out	(GR_CTRL), a
		jp	FOR1_x14	; ??? mittenrein in einen Befehl von FOR ???

; Ausgabe Zeilenwechsel (0Dh)
pl_label17:	ld	a, (unk_24F)
		ld	de, 0
		ld	b, d
		ld	c, d
		call	sub_9335
		ld	hl, (unk_25C)
		add	hl, de
		ld	(unk_258), hl
		ld	(unk_25C), hl
		pop	de
		ld	hl, (unk_25A)
		add	hl, de
		ld	(unk_256), hl
		ld	(unk_25A), hl
		jr	pl_label16

sub_9319:	push	af
		ld	hl, (unk_239)
		call	loc_94FA
		ld	a, 6
		call	sub_94CF
		ld	b, h
		ld	c, l
		pop	af
		ld	hl, (unk_23B)
		call	loc_94FA
		ld	a, 6
		call	sub_94CF
		ex	de, hl
		ret

sub_9335:	push	af
		ld	hl, (unk_23F)
		call	loc_94FA
		ld	a, 0Ah
		call	sub_94CF
		add	hl, de
		ex	de, hl
		pop	af
		ld	hl, (unk_23D)
		call	loc_94FA
		ld	a, 0Ah
		call	sub_94CF
		add	hl, bc
		ex	(sp), hl
		jp	(hl)

loc_9352:	ld	hl, unk_256
		call	sub_935B
		jp	loc_9158

sub_935B:	push	hl
		call	sub_9566
		ld	de, unk_26A
		ld	hl, loc_95EA
		ld	bc, 11h
		ldir
		ld	a, 3Dh ; '='
		ld	(unk_27B), a
		ld	de, (pltxpos)
		pop	hl
		push	hl
		ld	bc, 0F60Ah	; -2550
		call	sub_948B
		ld	(unk_268), hl
		ex	de, hl
		ex	(sp), hl
		push	hl
		ld	hl, unk_254
		or	(hl)
		ld	(hl), a
		ld	h, b
		ld	a, c
		xor	2
		ld	l, a
		ld	(unk_26D), hl
		ld	de, (pltypos)
		pop	hl
		inc	hl
		inc	hl
		ld	bc, 0F8F8h	; -1800
		call	sub_948B
		ld	(unk_273), hl
		rlca
		ld	hl, unk_254
		or	(hl)
		ld	(hl), a
		ld	(unk_278), bc
		call	sub_952A
		ld	bc, unk_24C+1
		ld	hl, unk_26D
		ld	a, (bc)
		or	(hl)
		ld	(hl), a
		ld	a, (bc)
		ld	hl, unk_278
		or	(hl)
		ld	(hl), a
		pop	hl
		push	hl
		or	a
		sbc	hl, de
		pop	hl
		jp	p, loc_93C4
		ex	de, hl
loc_93C4:	push	hl
		push	de
		ld	hl, unk_273
		ld	de, unk_268
		ld	b, 7
		call	m, sub_9520
		ld	hl, (unk_268)
		ex	de, hl
		ld	hl, (unk_261+1)
		ld	h, 0
		add	hl, hl
		add	hl, hl
		push	hl
		add	hl, hl
		pop	hl
		jr	c, loc_9430
		add	hl, de
loc_93E2:	ld	(unk_25E), hl
		pop	hl
		call	sub_94C6
		ex	de, hl
		pop	bc
		ld	hl, 0
		push	hl
		di
loc_93F0:	ld	hl, unk_268
		call	sub_9438
		xor	a
		pop	hl
		add	hl, de
		or	h
		ld	a, (unk_261)
		push	hl
		jp	p, loc_940C
		add	hl, bc
		ex	(sp), hl
		ld	hl, unk_273
		call	sub_9438
		ld	a, (unk_260)
loc_940C:	dec	a
		jr	nz, loc_940C
		ld	hl, unk_25E
		inc	(hl)
		jr	nz, loc_941E
		inc	hl
		inc	(hl)
		jr	nz, loc_941E
		ld	a, 3Ch ; '<'
		ld	(unk_27B), a
loc_941E:	push	bc
		ld	hl, tab_xxx2-1
		ld	a, (unk_261+1)
		ld	b, 0
		ld	c, a
		add	hl, bc
		pop	bc
		ld	a, (hl)
loc_942B:	dec	a
		jr	nz, loc_942B
		jr	loc_93F0
loc_9430:	ex	de, hl
		ld	a, 2
		call	sub_94CF
		jr	loc_93E2

sub_9438:	inc	(hl)
		ld	a, (hl)
		inc	hl
		jr	nz, loc_9440
		inc	(hl)
		jr	z, loc_9469
loc_9440:	rrca
		ret	nc
		rrca
		ret	nc
		inc	hl
		push	de
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		inc	hl
		push	de
		push	hl
		ex	de, hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ld	hl, loc_9455
		ex	(sp), hl
		jp	(hl)

loc_9455:	pop	hl
		ld	(hl), e
		inc	hl
		ld	(hl), d
		pop	de
sub_945A:	push	bc
		ld	b, a
		ld	a, (WINJP+1)	; Port f. Plotter
		ld	c, a
		ld	a, b
		out	(c), a
		or	4		; Bit2 := 1 MOVE
		out	(c), a
		pop	bc
		ret

loc_9469:	pop	de
		pop	de
		ei
		ld	a, (unk_254)
		and	a
		ld	a, 80h ; '€'
		jr	z, loc_9475
		xor	a
loc_9475:	ld	(unk_24B), a
		ld	hl, 300h
		jp	loc_9560

sub_947E:	ld	hl, unk_261+1
		push	af
		ld	a, (hl)
		call	unk_27B
		jr	z, loc_9489
		ld	(hl), a
loc_9489:	pop	af
		ret

sub_948B:	push	de
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		pop	hl
		call	sub_94C6
		add	hl, de
		call	sub_94C3
		push	hl
		ld	hl, 1301h
		jp	p, loc_94A1
		ld	hl, 1B00h
loc_94A1:	ex	(sp), hl
		ld	a, d
		and	a
		ex	de, hl
		jp	m, loc_94AE
		add	hl, bc
		jr	nc, loc_94BF
		call	sub_94C6
loc_94AE:	add	hl, de
loc_94AF:	call	sub_94C6
		push	hl
		add	hl, de
		ld	a, l
		or	h
		pop	hl
		add	hl, hl
		add	hl, hl
		dec	hl
		pop	bc
		ret	z
		ld	a, 1
		ret
loc_94BF:	ld	h, d
		ld	l, e
		jr	loc_94AF

sub_94C3:	ld	a, h
		and	a
		ret	p

sub_94C6:	push	af
		xor	a
		sub	l
		ld	l, a
		sbc	a, a
		sub	h
		ld	h, a
		pop	af
		ret

sub_94CF:	push	bc
		push	de
		ld	c, a
		call	sub_94C3
		ld	a, c
		push	af
		ld	de, 0
		ld	b, 8
loc_94DC:	ld	a, h
		sub	c
		jr	c, loc_94E4
		inc	de
		ld	h, a
		jr	loc_94DC
loc_94E4:	add	hl, hl
		ex	de, hl
		add	hl, hl
		ex	de, hl
		dec	b
		jr	nz, loc_94DC
		ld	a, h
		sub	c
		jr	c, loc_94F1
		inc	de
		ld	h, a
loc_94F1:	ld	a, h
		add	a, a
		sub	c
		jr	c, loc_94F7
		inc	de
loc_94F7:	ex	de, hl
		jr	loc_9519
loc_94FA:	push	bc
		push	de
		ld	d, a
		xor	h
		ld	a, d
		push	af
		call	sub_94C3
		ld	e, 0
		ld	b, 7
		ex	de, hl
		call	sub_94C3
		ld	a, h
		ld	h, l
loc_950D:	add	a, a
		jr	nc, loc_9511
		add	hl, de
loc_9511:	add	hl, hl
		dec	b
		jr	nz, loc_950D
		add	a, a
		jr	nc, loc_9519
		add	hl, de
loc_9519:	pop	af
		call	m, sub_94C6
		pop	de
		pop	bc
		ret

sub_9520:	ld	a, (de)
		ld	c, (hl)
		ex	de, hl
		ld	(hl), c
		ld	(de), a
		inc	hl
		inc	de
		djnz	sub_9520
		ret


; Computerseite		       Plotterseite
; PIO B7  o--------------o   1 (XP15) PEN
; PIO B6  o--|<|--+------o   5 (XP13) /READY
;           SAY17 |
; PIO B5  o-------+
; PIO B2  o--------------o   2 (XP11)/MOVE
; PIO B1  o--------------o   3 (XP7)  X/Y
; PIO B0  o--------------o   4 (XP9)  +/-

;sub_954C Ausgabe A auf Plotter
sub_952A:	ld	a, (unk_24C+1)
		ld	hl, 351Ch
		push	af
		ld	a, (unk_254)
		and	a
		jr	z, loc_953A
		ld	hl, 18Fh
loc_953A:	ld	(unk_261), hl
		ld	c, l
		ld	h, 0
		add	hl, hl
		ld	a, 5
		call	sub_94CF
		add	hl, bc
		ld	a, l
		ld	(unk_260), a
		pop	af
sub_954C:	ld	hl, unk_24E
		cp	(hl)
		ld	(hl), a
		dec	hl
		ld	(hl), a
		push	bc
		ld	b, a
		ld	a, (WINJP+1)	; Port f. Plotter
		ld	c, a
		out	(c), b
		pop	bc
		ret	z
		ld	hl, 800h	; Warteschleife
loc_9560:	dec	hl
		ld	a, h
		or	l
		jr	nz, loc_9560
		ret

; Initialisierung Plotter
sub_9566:	push	bc
		push	de
		call	sub_9589
		jr	z, loc_9586
		call	sub_95B6
		jr	z, loc_9586
		ld	de, a_po	; "?PO"
		call	PRNST		; BIOS:	PRNST
		ld	a, 11100010b	; RAND, cyan auf grün, Grafik aus
		out	(GR_CTRL), a
		xor	a
		ld	(WINJP), a
		ld	(unk_267), a
		jp	IOTEST_x5
loc_9586:	pop	de
		pop	bc
		ret

; Initialisierung E/A-Modul
sub_9589:	ld	a, (unk_267)	; schon initialisiert ?
		cp	0CFh
		jr	z, loc_95A4	; ja
		call	sub_95FD
		ld	a, (WINJP+1)	; Port f. Plotter
		inc	a
		inc	a
		ld	c, a
		ld	a, 0CFh		; Pio Mode 3
		out	(c), a
		ld	(unk_267), a	; Initialisierung merken
		ld	a, 20h		; Bit 5 = Eingabe
		out	(c), a
loc_95A4:	ld	a, (WINJP+1)	; Port f. Plotter
		ld	c, a
		ld	a, (unk_24E)
		out	(c), a
		or	40h		; READY out
		out	(c), a
		in	a, (c)
		and	20h		; READY in
		ret

; UP zu Plotter Init
sub_95B6:	ld	hl, 2000
		xor	a
		ld	(unk_24E), a
loc_95BD:	ld	a, 0
		call	sub_95E2
		call	sub_9589
		jr	z, loc_95CE
		dec	hl
		ld	a, h
		or	l
		jr	nz, loc_95BD
		inc	a
		ret
loc_95CE:	ld	hl, 0
		ld	(pltxpos), hl
		ld	(pltypos), hl
		ld	c, 0Fh
loc_95D9:	ld	a, 1
		call	sub_95E2
		dec	c
		jr	nz, loc_95D9
		ret

sub_95E2:	ld	b, 0FFh
		call	sub_945A
loc_95E7:	djnz	$
		ret

loc_95EA:	ld	b, l
		ld	(bc), a
		ld	a, 3
		inc	de
		call	sub_947E
		ret

; ?? Bedeutung unklar, wird nicht verwendet ??
tab_xxx1:	db    0	;
		db    0	;
		db  47h	; G
		db    2	;
		db  3Eh	; >
		db    1	;
		db  13h	;
		db 0C9h	; É
		db  3Dh	; =
		db 0C9h	; É

; UP zu sub_9589 Initialisierung E/A-Modul
sub_95FD:	ld	hl, unk_234	; Speicher init.
		ld	(hl), 0		; unk_234..unk_267 mit 00 füllen
		ld	d, h
		ld	e, l
		inc	de
		ld	bc, 34h
		ldir
;
		ld	hl, 5859h	; "XY"
		ld	(unk_234), hl
		ld	a, 24
		ld	(unk_239), a
		ld	a, 40
		ld	(unk_23F), a
		ld	a, 80h
		ld	(unk_24B), a
		ld	a, 0EEh
		ld	(unk_24F), a
		ld	a, 0C9h
		ld	(unk_27C), a
		ret

; s. loc_941E, Bedeutung unklar, 54 Byte
tab_xxx2:	db    1	;
		db    2	;
		db    2	;
		db    3	;
		db    3	;
		db    4	;
		db    4	;
		db    5	;
		db    5	;
		db    6	;
		db    7	;
		db    8	;
		db    9	;
		db  0Ah	;
		db  0Bh	;
		db  0Ch	;
		db  0Dh	;
		db  0Eh	;
		db  0Fh	;
		db  10h	;
		db  11h	;
		db  12h	;
		db  13h	;
		db  14h	;
		db  15h	;
		db  16h	;
		db  18h	;
		db  1Ah	;
		db  1Ch	;
		db  1Eh	;
		db  20h	;
		db  22h	; "
		db  24h	; $
		db  26h	; &
		db  28h	; (
		db  2Ah	; *
		db  2Ch	; ,
		db  30h	; 0
		db  32h	; 2
		db  34h	; 4
		db  38h	; 8
		db  3Ch	; <
		db  40h	; @
		db  44h	; D
		db  48h	; H
		db  4Ch	; L
		db  50h	; P
		db  54h	; T
		db  58h	; X
		db  5Ch
		db  60h	; `
		db  64h	; d
		db  6Ah	; j
		db  70h	; p

aOutOfRange:	db " OUT OF RANGE",0dh,0ah,0
a_po:		db "?PO",0

umlauttab:	db  61h	; a
		db  6Fh	; o
		db  75h	; u

; 104 Zeichen (18h-7Fh)
; speziell: 7Fh => ß
;	0Dh => neue Zeile
;	18h + nächstes Zeichen => Umlaut
;	19h..1Fh Polygonzug-Sonderzeichen
labeltab:
; 11h obere Kugel der 8			; 11..17 Teilstücke für andere Zeichen
		db 00001001b		; hintere 4 Bit = Länge des Zeichens
		db 00100101b
		db 11000101b
		db 11100110b
		db 11101000b
		db 11001010b
		db 10101010b
		db 10001000b
		db 10000110b
		db 10100101b
; 12h
		db 00001001b
		db 01100101b
		db 11101001b
		db 11001010b
		db 10101010b
		db 10001001b
		db 10000001b
		db 10100000b
		db 11000000b
		db 11100001b
; 13h
		db 00010101b
		db 00010101b
		db 10100110b
		db 11000110b
		db 11010101b
		db 11010000b
; 14h
		db 00010111b
		db 00010000b
		db 11000000b
		db 11010001b
		db 11010101b
		db 11000110b
		db 10100110b
		db 10010101b
; 15h
		db 00001011b
		db 00010111b
		db 10001000b
		db 10001001b
		db 10011010b
		db 10101010b
		db 10111001b
		db 10111000b
		db 10100111b
		db 10010111b
		db 00000000b
		db 11101010b
; 16h
		db 00000100b
		db 00100000b
		db 10101010b
		db 01001010b
		db 11000000b
; 17h senkrechter Strich in I
		db 00010010b
		db 00111010b
		db 10110000b
; 18h Umlautstriche
		db 00000100b
		db 00101100b
		db 10101101b
		db 01001101b
		db 11001100b
; 19h
		db 01100101b
		db 00000001b
		db 11100001b
		db 11100111b
		db 10000111b
		db 10000001b
; 1Ah
		db 01100101b
		db 00110001b
		db 11100100b
		db 10110111b
		db 10000100b
		db 10110001b
; 1Bh
		db 01100100b
		db 00000010b
		db 11100010b
		db 10110111b
		db 10000010b
; 1Ch
		db 01100100b
		db 00000110b
		db 10110001b
		db 11100110b
		db 10000110b
; 1Dh
		db 01100100b
		db 00000100b
		db 11100100b
		db 00110111b
		db 10110001b
; 1Eh
		db 01100100b
		db 00000001b
		db 11100111b
		db 00000111b
		db 11100001b
; 1Fh
		db 01100110b
		db 00110001b
		db 10110111b
		db 01100110b
		db 10000010b
		db 00000110b
		db 11100010b
; ' ' (20h)
		db 00000000b
; 21h
		db 00010100b
		db 00111010b
		db 10110011b
		db 00110001b
		db 10110000b
; 
		db 00000100b
		db 00100111b
		db 10101010b
		db 01001010b
		db 11000111b
		db 10000100b
		db 00010111b
		db 11010111b
		db 01010011b
		db 10010011b
		db 00010110b
		db 10001010b
		db 01100111b
		db 11011001b
		db 10101001b
		db 10000111b
		db 10000110b
		db 11100100b
		db 11100011b
		db 11000001b
		db 10010001b
		db 10000011b
		db 00010110b
		db 10001001b
		db 01000000b
		db 10110001b
		db 10110010b
		db 11000011b
		db 11010011b
		db 11100010b
		db 11100001b
		db 11010000b
		db 11000000b
		db 00010101b
		db 00001011b
		db 01100000b
		db 10011000b
		db 10101010b
		db 11001010b
		db 11011000b
		db 10010100b
		db 10010001b
		db 10100000b
		db 11000000b
		db 11010100b
		db 11100100b
		db 00010010b
		db 00111010b
		db 10111000b
		db 00001000b
		db 01001010b
		db 10111010b
		db 10101001b
		db 10010111b
		db 10010011b
		db 10100001b
		db 10110000b
		db 11000000b
		db 00001000b
		db 00101010b
		db 10111010b
		db 11001001b
		db 11010111b
		db 11010011b
		db 11000001b
		db 10110000b
		db 10100000b
		db 10000100b
		db 00010001b
		db 11010111b
		db 00010111b
		db 11010001b
		db 00101101b
		db 10000010b
		db 00110001b
		db 10110111b
		db 00101101b
		db 01010011b
		db 00110110b
		db 10110100b
		db 10100011b
		db 00000010b
		db 00000100b
		db 11100100b
		db 00010001b
		db 00110000b
		db 00000010b
		db 00000000b
		db 11101010b
		db 10000010b
		db 00010001b
		db 11011001b
		db 01001111b
		db 00000011b
		db 00011001b
		db 11011010b
		db 11010000b
		db 00001000b
		db 00001000b
		db 10011010b
		db 11001010b
		db 11101000b
		db 11100110b
		db 10000010b
		db 10000000b
		db 11100000b
		db 00001101b
		db 00000010b
		db 10010000b
		db 11000000b
		db 11100010b
		db 11100100b
		db 11000101b
		db 10100101b
		db 11000101b
		db 11100110b
		db 11101000b
		db 11001010b
		db 10011010b
		db 10001000b
		db 00000101b
		db 00111010b
		db 10000011b
		db 11100011b
		db 01011010b
		db 11010000b
		db 00001010b
		db 01101010b
		db 10011010b
		db 10000101b
		db 10110110b
		db 11010110b
		db 11100100b
		db 11100010b
		db 11000000b
		db 10010000b
		db 10000010b
		db 00001100b
		db 01101000b
		db 11011010b
		db 10101010b
		db 10001000b
		db 10000010b
		db 10100000b
		db 11010000b
		db 11100010b
		db 11100100b
		db 11010110b
		db 10100110b
		db 10000100b
		db 00000011b
		db 00001010b
		db 11101010b
		db 10010000b
		db 10000111b
		db 01000101b
		db 11100100b
		db 11100010b
		db 11000000b
		db 10100000b
		db 10000010b
		db 10000100b
		db 10010001b
		db 00001100b
		db 00000010b
		db 10010000b
		db 11000000b
		db 11100010b
		db 11101000b
		db 11001010b
		db 10011010b
		db 10001000b
		db 10000110b
		db 10010100b
		db 11000100b
		db 11100110b
		db 00010010b
		db 00110101b
		db 00110010b
		db 10010001b
		db 00110100b
		db 00101100b
		db 00000011b
		db 01010111b
		db 10010100b
		db 11010001b
		db 00000100b
		db 00010101b
		db 11010101b
		db 01010011b
		db 10010011b
		db 00000011b
		db 00010111b
		db 11010100b
		db 10010001b
		db 00001010b
		db 00011000b
		db 10011001b
		db 10101010b
		db 11001010b
		db 11011001b
		db 11010111b
		db 10110101b
		db 10110011b
		db 00110001b
		db 10110000b
		db 10000111b
		db 01000011b
		db 11000111b
		db 10110111b
		db 10100110b
		db 10100100b
		db 10110011b
		db 11010011b
		db 10010010b
		db 00000101b
		db 00000000b
		db 10111010b
		db 11100000b
		db 00010011b
		db 11010011b
		db 00001100b
		db 00000000b
		db 10001010b
		db 11001010b
		db 11101000b
		db 11100111b
		db 11000101b
		db 10000101b
		db 11000101b
		db 11100100b
		db 11100010b
		db 11000000b
		db 10000000b
		db 00001000b
		db 01100001b
		db 11000000b
		db 10100000b
		db 10000010b
		db 10001000b
		db 10101010b
		db 11001010b
		db 11101001b
		db 00000111b
		db 00000000b
		db 10001010b
		db 11001010b
		db 11101000b
		db 11100010b
		db 11000000b
		db 10000000b
		db 10000001b
		db 01100000b
		db 11000110b
		db 00000101b
		db 00000000b
		db 10001010b
		db 11011010b
		db 00000101b
		db 11010101b
		db 00001001b
		db 00110101b
		db 11100101b
		db 11100000b
		db 10100000b
		db 10000010b
		db 10001000b
		db 10101010b
		db 11001010b
		db 11101001b
		db 00000110b
		db 00000000b
		db 10001010b
		db 00000101b
		db 11100101b
		db 01101010b
		db 11100000b
		db 10010100b
		db 00100000b
		db 11000000b
		db 00101010b
		db 11001010b
		db 00010111b
		db 00000101b
		db 00000010b
		db 10010000b
		db 11000000b
		db 11100010b
		db 11101010b
		db 00000101b
		db 00000000b
		db 10001010b
		db 01011010b
		db 10000101b
		db 11100000b
		db 00000011b
		db 00001010b
		db 10000000b
		db 11100000b
		db 00000101b
		db 00000000b
		db 10001010b
		db 10110101b
		db 11101010b
		db 11100000b
		db 00000100b
		db 00000000b
		db 10001010b
		db 11100000b
		db 11101010b
		db 00001001b
		db 01000000b
		db 10100000b
		db 10000010b
		db 10001000b
		db 10101010b
		db 11001010b
		db 11101000b
		db 11100010b
		db 11000000b
		db 00000111b
		db 00000000b
		db 10001010b
		db 11001010b
		db 11101001b
		db 11100110b
		db 11000101b
		db 10000101b
		db 10000010b
		db 01000010b
		db 11100000b
		db 01001111b
		db 10000010b
		db 01000101b
		db 11100000b
		db 01010000b
		db 00001010b
		db 00000010b
		db 10010000b
		db 11000000b
		db 11100010b
		db 11100100b
		db 10000110b
		db 10001000b
		db 10101010b
		db 11011010b
		db 11101000b
		db 00000100b
		db 00001010b
		db 11101010b
		db 00111010b
		db 10110000b
		db 00000110b
		db 00001010b
		db 10000010b
		db 10100000b
		db 11000000b
		db 11100010b
		db 11101010b
		db 00000011b
		db 00001010b
		db 10110000b
		db 11101010b
		db 00000101b
		db 00001010b
		db 10010000b
		db 10110110b
		db 11010000b
		db 11101010b
		db 10000010b
		db 00001010b
		db 11100000b
		db 00101111b
		db 00000101b
		db 00001010b
		db 10110101b
		db 11101010b
		db 00110101b
		db 10110000b
		db 00000100b
		db 00011010b
		db 11101010b
		db 10000000b
		db 11100000b
		db 00000100b
		db 01011010b
		db 10101010b
		db 10100000b
		db 11010000b
		db 00000010b
		db 00001010b
		db 11100000b
		db 00000100b
		db 00011010b
		db 11001010b
		db 11000000b
		db 10010000b
		db 00000011b
		db 00010110b
		db 10111001b
		db 11010110b
		db 00000010b
		db 00000000b
		db 11100000b
		db 00010010b
		db 00111010b
		db 11001000b
		db 00011010b
		db 01010011b
		db 11000100b
		db 10100100b
		db 10010011b
		db 10010001b
		db 10100000b
		db 11010000b
		db 11010101b
		db 11000110b
		db 10010110b
		db 10010001b
		db 00011010b
		db 10010100b
		db 00010111b
		db 01010101b
		db 11000110b
		db 10100110b
		db 10010101b
		db 10010001b
		db 10100000b
		db 11010000b
		db 10010010b
		db 01010000b
		db 11011010b
		db 01100011b
		db 10010010b
		db 00010011b
		db 11010011b
		db 11100011b
		db 01010110b
		db 00011010b
		db 11001010b
		db 01001110b
		db 10111110b
		db 10101101b
		db 10100001b
		db 11010100b
		db 00010001b
		db 11000001b
		db 11010011b
		db 11011010b
		db 01100011b
		db 10010010b
		db 00010000b
		db 10011010b
		db 00010011b
		db 00010110b
		db 00010000b
		db 11000000b
		db 00110000b
		db 10110110b
		db 10010110b
		db 00111000b
		db 01010110b
		db 00010001b
		db 10100001b
		db 10110011b
		db 10111010b
		db 10011010b
		db 00111100b
		db 00010101b
		db 00010000b
		db 10011010b
		db 01010110b
		db 10010011b
		db 11010000b
		db 10010011b
		db 00010000b
		db 11000000b
		db 00011010b
		db 10010111b
		db 00001100b
		db 00000000b
		db 10000110b
		db 00000101b
		db 10010110b
		db 10100110b
		db 10110101b
		db 10110000b
		db 00110101b
		db 11000110b
		db 11010110b
		db 11100101b
		db 11100000b
		db 10010010b
		db 00010000b
		db 10010110b
		db 00010011b
		db 00011001b
		db 00010001b
		db 10010101b
		db 10100110b
		db 11000110b
		db 11010101b
		db 11010001b
		db 11000000b
		db 10100000b
		db 10010001b
		db 11010010b
		db 00010001b
		db 10011010b
		db 00010100b
		db 11010010b
		db 01010001b
		db 11011010b
		db 01100011b
		db 00010101b
		db 00100000b
		db 10100110b
		db 00100101b
		db 11000110b
		db 11010101b
		db 00011010b
		db 00010001b
		db 10100000b
		db 11000000b
		db 11010001b
		db 11010010b
		db 10010100b
		db 10010101b
		db 10100110b
		db 11000110b
		db 11010101b
		db 00010110b
		db 00010110b
		db 11000110b
		db 00101000b
		db 10100001b
		db 10110000b
		db 11000000b
		db 00010101b
		db 00010110b
		db 10010001b
		db 10100000b
		db 11010000b
		db 11010110b
		db 00010011b
		db 00010110b
		db 10110000b
		db 11010110b
		db 00000101b
		db 00000110b
		db 10010000b
		db 10110100b
		db 11010000b
		db 11100110b
		db 00010100b
		db 00010000b
		db 11010110b
		db 00010110b
		db 11010000b
		db 01010101b
		db 00010001b
		db 10100001b
		db 11011010b
		db 00011010b
		db 10110100b
		db 00010100b
		db 00010110b
		db 11010110b
		db 10010000b
		db 11010000b
		db 00001001b
		db 01011010b
		db 11001010b
		db 10111001b
		db 10110110b
		db 10010101b
		db 10110100b
		db 10110001b
		db 11000000b
		db 11010000b
		db 00010100b
		db 00111010b
		db 10110111b
		db 00110011b
		db 10110000b
		db 00001001b
		db 00011010b
		db 10101010b
		db 10111001b
		db 10110110b
		db 11010101b
		db 10110100b
		db 10110001b
		db 10100000b
		db 10010000b
		db 00000110b
		db 00000100b
		db 10010101b
		db 10100101b
		db 11000011b
		db 11010011b
		db 11100100b
		db 00001100b
		db 00010000b
		db 10011001b
		db 10101010b
		db 11001010b
		db 11011001b
		db 11010111b
		db 10110110b
		db 11010101b
		db 11100100b
		db 11100010b
		db 11010001b
		db 10110000b

; UP zu pl_circle
sub_9AA8:	push	hl
		push	bc
		call	OPKOP
		pop	bc
		ld	de, 0
		ld	hl, WRA1+3
		ld	a, (hl)
		or	a
		jp	z, loc_9AF5
		dec	hl
		ld	a, (hl)
		or	a
		jp	p, loc_9ACD
		and	7Fh
		ld	(hl), a
		ld	hl, pltparambuf
		ld	a, (hl)
		or	c
		ld	(hl), a
		pop	hl
		call	OPTRAN
		push	hl
loc_9ACD:	ld	bc, 7E22h
		ld	de, 0F983h
		call	MUL1
		ld	hl, WRA1+3
		ld	a, 81h
		cp	(hl)
		jp	c, fcerr
		call	OPARST
		xor	a
		ld	b, 8
		call	FRE3
		pop	bc
		pop	de
		call	MUL1
		call	EPRVL3
loc_9AF5:	pop	hl
		ret

locret_A32B:	ret

		newpage
;*****************************************************************************
; BASIC-Interface
;*****************************************************************************

;-----------------------------------------------------------------------------
; PSET(x,y)[,stift]
; Setzen eines Punktes
; stift - 0 Hintergrundfarbe (Löschen), 1 Vordergrundfarbe, (Standard: stift = 1)
;-----------------------------------------------------------------------------

pset:		ld	a, (hl)
		cp	0ABh		; Token für STEP
		ld	b, -1		; Offset-Mode -1
		jr	nz, pset1	; kein STEP
		call	TCHAR		; Token konsumieren
		jr	pset2
pset1:		ld	b, 1		; Offset-Mode 1
pset2:		ld	de, pltparambuf
		push	de
		ld	a, b
		ld	(de), a		; Offset-Mode übergeben
		inc	de
		call	point3		; Koordinaten ermitteln
		jr	nz, pset3
		inc	a
		jr	pset4
pset3:		call	CPCOMM		; Test auf Komma
		call	sub_A489	; 0/1-Parameter holen
pset4:		ld	(de), a		; Stift-Mode
		pop	de
		ld	c, 1		; Fkt. 01h / (DE): 1 Byte Offs-Mode, 2 Byte X, 2 Byte Y, 1 Byte Stift
		jp	plsv		; interner Sprungverteiler

;-----------------------------------------------------------------------------
; LINE [(x1,y1)]-(x2,y2)[,[stift][,B[F]]]
; Zeichnen von Linie oder Rechteck
; stift - 0 Hintergrundfarbe (Löschen), 1 Vordergrundfarbe, (Standard: stift = 1)
; B - Zeichnen eines Rechteckes (box)
;-----------------------------------------------------------------------------

line:		ld	b, 1
		ld	a, (hl)
		cp	0ADh      	; Token für -
		jr	z, line1	; dann b=0 (1.Punkt := aktuelle Koord)
		cp	0ABh		; Token für STEP
		jr	nz, line2	; kein Step, b=1
		dec	b		; STEP, b=-1
line1:		dec	b
		call	TCHAR		; Token konsumieren
line2:		ld	de, pltparambuf
		push	de
		ld	a, b		; Offset-Mode
		ld	(de), a
		inc	de
		and	a
		jr	nz, line3
		ld	de, pltparambuf+5	; bei b=0 geht es weiter mit 2. Punkt
		jr	line4
line3:		call	point3		; Koordinaten ermitteln
		cp	0ADh		; Token fuer '-'
;		jp	nz, snerr
		jr	nz, circle3
		call	TCHAR		; Token konsumieren
; 2. Punkt
line4:		ld	a, (hl)
		cp	0ABh		; Token fuer STEP
		jr	nz, line5	; kein STEP
		ld	b, -1		; STEP, b=-1
		call	TCHAR		; Token konsumieren
		jr	line6
line5:		ld	b, 1		; kein STEP, b=1
line6:		ld	a, b
		ld	(de), a		; Offset-Mode
		inc	de
		call	point3		; Koordinaten ermitteln
		jr	nz, line7
		ld	a, 1
		jr	line11		; wenn keine weiteren Werte kommen
; Stift-Mode
line7:		cp	','
		;jp	nz, snerr
		jr	nz, circle3
		call	TCHAR		; Token konsumieren
		cp	','		; folgt gleich ein weiteres Komma?
		jr	nz, line8
		ld	a, 1		; Stift-mode ist ausgelassen
		ld	(de), a		; dann Stift-Mode 1
		inc	de
		jr	line9
line8:		call	sub_A489	; 0/1-Parameter holen
		ld	(de), a		; Stift-mode
		inc	de
		dec	hl
		call	TCHAR		; Token konsumieren
		jr	z, line12	; wenn kein weiteres Zeichen in Eingabezeile
		cp	','
		;jp	nz, snerr
		jr	nz, circle3
; Box
line9:		ld	b, 0
		call	TCHAR		; Token konsumieren
		cp	'B'
		;jp	nz, snerr
		jr	nz, circle3
		inc	b		; bei 'B' b=1
		call	TCHAR		; Token konsumieren
		cp	'F'		; folgt noch ein 'F'?
		jr	nz, line10
		call	TCHAR		; Token konsumieren
		inc	b		; dann b=2
		ld	a, b
		jr	line13
;
line10:		ld	a, b
		jr	line13
line11:		ld	(de), a		; Ablegen Stift
		inc	de
line12:		xor	a		; Default Box=0
line13:		ld	(de), a		; Ablegen Box
		pop	de
		ld	c, 2
		jp	plsv		; interner Sprungverteiler

;-----------------------------------------------------------------------------
; CIRCLE(x,y),radius[,stift[,anf-winkel[,end-winkel[,ellip]]]]
; CIRCLE(x,y),radius[,stift],[anf-winkel],[end-winkel],ellip
; Zeichnen eines Kreises
; stift - 0 Hintergrundfarbe (Löschen), 1 Vordergrundfarbe, (Standard: stift = 1)
; anf-winkel - Anfangswinkel für Kreisbogen (Bogenmaß)
; end-winkel - Endwinkel für Kreisbogen (Bogenmaß)
; ellip - Ellipsenparameter (Standard: ellip = 1)
;-----------------------------------------------------------------------------

circle:		ld	a, (hl)
		cp	0ABh		; Token fuer STEP
		ld	b, -1		; STEP, b=-1
		jr	nz, circle1	; kein STEP
		call	TCHAR		; Token konsumieren
		jr	circle2
circle1:	ld	b, 1		; kein STEP, b=1
circle2:	ld	de, pltparambuf
		push	de
		ld	a, b
		ld	(de), a		; Offset-Mode
		inc	de
; (x,y)
		call	point3		; Koordinaten (x,y) ermitteln
		cp	','
circle3:	jp	nz, snerr
; radius
		call	TCHAR		; Token konsumieren
		call	SNALY		; Parameter übernehmen
		ld	de, pltparambuf+5
		call	size7		; float-Wert nach (DE)
		call	TCHAR1
		jr	z, circle10	; wenn kein weiteres Zeichen folgt
		cp	','		; folgt Komma ?
		;jp	nz, snerr	; Fehler wenn kein Komma
		jr	nz, circle3
; Stift
		call	TCHAR		; Token konsumieren
		cp	','		; folgt Komma ?
		jr	nz, circle4	; nein
		ld	de, pltparambuf+9
		call	sub_A19A	; Default 1 nach (DE) schreiben
		jr	circle5
circle4:	call	sub_A489	; 0/1-Parameter holen
		ld	(de), a		; Stift nach (DE) schreiben
		call	TCHAR1
		jr	z, circle11	; wenn kein weiteres Zeichen folgt
; anf-winkel
circle5:	call	TCHAR		; Token konsumieren
		cp	','		; folgt Komma ?
		jr	nz, circle6
		call	sub_A19F	; anf-winkel 0 schreiben
		jr	circle7
circle6:	call	SNALY		; Parameter übernehmen
		ld	de, pltparambuf+10
		call	size7		; float-Wert nach (DE)
		call	TCHAR1
		jr	z, circle12	; wenn kein weiteres Zeichen folgt
		cp	','		; folgt Komma ?
		;jp	nz, snerr
		jr	nz, circle3
; end-winkel
circle7:	call	TCHAR		; Token konsumieren
		cp	','		; folgt Komma ?
		jr	nz, circle8
		call	sub_A1A5	; end-winkel Float Wert 2*PI schreiben
		jr	circle9
circle8:	call	SNALY		; Parameter übernehmen
		ld	de, pltparambuf+14
		call	size7		; float-Wert nach (DE)
		call	TCHAR1
		jr	z, circle13
		cp	','		; folgt Komma ?
		;jp	nz, snerr
		jr	nz, circle3
; ellip
circle9:	call	TCHAR		; Token konsumieren
		call	SNALY		; Parameter übernehmen
		push	hl
		ld	hl, WRA1+2	; es muß 0<=ellip<=1 gelten, sonst Fehler
		bit	7, (hl)
		jp	nz, fcerr
		ld	hl, WRA1+3
		ld	a, (hl)
		and	a
		jp	z, fcerr
		pop	hl
		ld	de, pltparambuf+18
		call	size7		; float-Wert nach (DE)
		jr	circle14
; Defaultwerte
circle10:	call	sub_A19A	; Stift 1 nach (DE) schreiben
circle11:	call	sub_A19F	; anf-winkel 0 schreiben
circle12:	call	sub_A1A5	; end-winkel Float Wert 2*PI schreiben
circle13:	call	sub_A1B6	; ellip Float Wert 1.0f schreiben
; Parameter skalieren
circle14:	push	hl
		ld	hl, fscalex
		call	OPKOP
		ld	hl, pltparambuf+18	; ellip
		push	hl
		call	OPLAD
		call	DIV1
		ld	hl, fscaley
		call	OPLAD
		call	MUL1
		ld	hl, WRA1+2
		ld	a, (hl)
		and	7Fh
		ld	(hl), a
		pop	hl
		call	OPTRAN
		ld	hl, fscalex
		ld	a, (WRA1+3)
		cp	81h		; 1.0f
		jr	c, circle15
		ld	hl, fscaley
circle15:	call	OPKOP
		ld	hl, pltparambuf+5	; radius
		push	hl
		call	OPLAD
		call	MUL1
		pop	hl
		call	OPTRAN
		pop	hl
		pop	de
		ld	c, 3
		jp	plsv		; interner Sprungverteiler

; 1 nach (DE) schreiben
sub_A19A:	ld	a, 1
		ld	(de), a
		inc	de
		ret

; 0 nach anf-winkel schreiben (pltparambuf+10..pltparambuf+12 sind 0)
sub_A19F:	ld	de, pltparambuf+13
		xor	a
		ld	(de), a
		ret

; Float Wert 6.28319f (2*PI) nach end-winkel schreiben
sub_A1A5:	push	hl
		ld	hl, pltparambuf+14
		ld	(hl), 0DBh
		inc	hl
		ld	(hl), 0Fh
		inc	hl
		ld	(hl), 49h
		inc	hl
		ld	(hl), 83h
		pop	hl
		ret

; Float Wert 1.0f nach ellip schreiben
sub_A1B6:	ld	de, pltparambuf+18
		xor	a
		ld	(de), a
		inc	de
		ld	(de), a
		inc	de
		ld	(de), a
		inc	de
		ld	a, 81h
		ld	(de), a
		ret

;-----------------------------------------------------------------------------
; PAINT(x,y)[,c[,d]]
; c default 1
; d default 1
;-----------------------------------------------------------------------------

paint:		ld	a, (hl)
		cp	0ABh		; Token fuer STEP
		ld	b, -1		; STEP, b=-1
		jr	nz, paint1	; kein STEP
		call	TCHAR		; Token konsumieren
		jr	paint2
paint1:		ld	b, 1		; kein STEP, b=1
paint2:		ld	de, pltparambuf
		push	de
		ld	a, b
		ld	(de), a		; Offset-Mode
		inc	de
; (x,y)
		call	point3		; Koordinaten ermitteln
		jr	z, paint5	; wenn kein weiteres Zeichen folgt
		cp	','		; folgt Komma ?
		jp	nz, snerr
; c
		call	TCHAR		; Token konsumieren
		cp	','		; folgt Komma ?
		jr	nz, paint3	; wenn kein Komma
		ld	a, 1		; sonst Std.-Wert 1
		ld	(de), a
		inc	de
		jr	paint4
paint3:		call	sub_A489	; 0/1-Parameter holen
		ld	(de), a
		inc	de
		ld	a, (hl)		; nächstes Zeichen
		and	a
		jr	z, paint6	; wenn kein weiteres Zeichen folgt
		cp	','		; folgt Komma ?
		jp	nz, snerr
; d
paint4:		call	TCHAR		; Token konsumieren
		push	de
		call	ARGVL1		; numerischen Parameter übernehmen
		pop	de
		jr	paint7
paint5:		ld	a, 1		; c Default 1
		ld	(de), a
		inc	de
paint6:		ld	a, 1		; d Default 1
paint7:		ld	(de), a
		pop	de
		ld	c, 4
		jp	plsv		; interner Sprungverteiler

;-----------------------------------------------------------------------------
; LABEL	string[,stift]
; Ausgabe einer Zeichenkette ab aktueller Stiftposition
;-----------------------------------------------------------------------------

label:		call	SNALY		; Parameter übernehmen
		push	hl
		call	LEN1
		ld	de, pltparambuf
		ld	bc, 4		; 2 Byte Länge, 2 Byte Adr. String
		ldir
		pop	hl
		dec	hl
		call	TCHAR		; Token konsumieren
		jr	z, label1	; keine weiteren Zeichen mehr
		cp	','
		jp	nz, snerr
		call	TCHAR		; Token konsumieren
		call	sub_A489	; 0/1-Parameter holen
		jr	label2
label1:		ld	a, 1		; Std. Stift := 1
label2:		ld	(de), a		; Stift
		ld	de, pltparambuf
		ld	c, 5
		jp	plsv		; interner Sprungverteiler

;-----------------------------------------------------------------------------
; SIZE b,l[,r[,s[,a]]]
; SIZE b,l,[r],[s],a
; Festlegung der Schriftart (nur für PLOTTER)
; b Breite der Buchstaben (Geräteeinheiten)
; I Länge (Geräteeinheiten)
; r Schreibrichtung (Bogenmaß)
; s Schräglage (Bogenmaß)
; a Abstand 0 - gleichabständig (Standard), 1 - proportional
;-----------------------------------------------------------------------------

size:		push	hl
		ld	hl, pltparambuf+9
		ld	(hl), 0
		ld	de, pltparambuf+10
		ld	bc, 11
		ldir			; Buffer mit 00 füllen (r = s = a = 0)
		pop	hl
; b
		call	SNALY		; Parameter übernehmen
		ld	de, pltparambuf+9
		call	size7		; float-Wert nach (DE)
		call	CPCOMM		; Test auf Komma
; l
		call	SNALY		; Parameter übernehmen
		ld	de, pltparambuf+13
		call	size7		; float-Wert nach (DE)
		call	TCHAR1
		jr	z, size1	; keine weiteren Zeichen
; r
		call	CPCOMM		; Test auf Komma
		call	TCHAR1
		cp	','		; Komma ?
		jr	z, size1
		call	SNALY		; Parameter übernehmen
		ld	de, pltparambuf+17
		call	size7		; float-Wert nach (DE)
; mit r skalieren
size1:		push	hl
		ld	hl, pltparambuf+17
		call	size8		; float-Wert nach (DE)
		call	COS
		ld	hl, pltparambuf+9
		call	size9		; skalieren
		ld	(pltparambuf), hl
		ld	hl, pltparambuf+17
		call	size8		; float-Wert nach (DE)
		call	SIN
		ld	hl, pltparambuf+9
		call	size9		; skalieren
		ld	(pltparambuf+2), hl
		pop	hl
; s
		call	TCHAR1
		jr	z, size2
		call	CPCOMM		; Test auf Komma
		call	TCHAR1
		cp	','		; Komma ?
		jr	nz, size3
size2:		xor	a		; wenn default-Wert (= 0)
		ld	(pltparambuf+12), a	; so b auf 0 setzen
		jr	size4
size3:		call	SNALY		; Parameter übernehmen
		ld	de, pltparambuf+9	; b
		call	size7		; float-Wert nach (DE)
; mit s skalieren
size4:		push	hl
		ld	hl, pltparambuf+9
		call	size8		; float-Wert nach (DE)
		ld	hl, pltparambuf+17	; r
		call	ADD3
		ld	hl, COSL
		call	ADD2
		ld	de, pltparambuf+9
		call	size7		; float-Wert nach (DE)
		call	COS
		ld	hl, pltparambuf+13	; l
		call	size9		; skalieren
		ld	(pltparambuf+4), hl
		ld	hl, pltparambuf+9
		call	size8		; float-Wert nach (DE)
		call	SIN
		ld	hl, pltparambuf+13
		call	size9		; skalieren
		ld	(pltparambuf+6), hl
		pop	hl
; a
		call	TCHAR1
		jr	z, size5
		call	CPCOMM		; Test auf Komma
		call	sub_A489	; 0/1-Parameter holen
		jr	z, size5
		ld	a, 80h		; wenn 1
		jr	size6
size5:		xor	a		; Abstand Standard 0
size6:		ld	(pltparambuf+8), a
;
		ld	de, pltparambuf
		ld	c, 6
		jp	plsv		; interner Sprungverteiler

; Float-Wert nach (DE) transportieren (4 Byte)
size7:		push	hl
		ld	hl, WRA1	; ARITHMETIKREGISTER 1
		ld	bc, 4
		ldir
		pop	hl
		ret

; Float-Wert nach (DE) transportieren (4 Byte)
size8:		ld	de, WRA1	; ARITHMETIKREGISTER 1
		ld	bc, 4
		ldir
		ret

; Skalieren (Multiplikation mit Skalefaktor (HL))
size9:		call	OPLAD
		call	MUL1
		call	EPRVL3
		ex	de, hl
		ret

;-----------------------------------------------------------------------------
; ZERO (x,y)
; Der Nullpunkt des aktuellen Koordinatensystems wird in den Punkt (x,y) gelegt.
;-----------------------------------------------------------------------------

zero:		ld	a, (hl)
		cp	0ABh		; Token für STEP
		ld	b, -1		; STEP => b=-1
		jr	nz, zero1	; kein STEP
		call	TCHAR		; Token konsumieren
		jr	zero2
zero1:		ld	b, 1		; kein STEP => b=1
zero2:		ld	de, pltparambuf
		push	de
		ld	a, b
		ld	(de), a		; Step
		inc	de
		call	point3		; Koordinaten (x,y)
		pop	de
		ld	c, 7
		jr	ypos1

;-----------------------------------------------------------------------------
; HOME
; Die Koordinaten des letzten erreichbaren Punktes werden in den
; Koordinatenursprung, den Punkt (0,0) des aktuellen Koordinatensystems, gelegt.
; HOME ist gleichbedeutend mit PSET(0,0),0.
;-----------------------------------------------------------------------------

home:		ld	c, 8
		jr	ypos1

;-----------------------------------------------------------------------------
; GCLS
;-----------------------------------------------------------------------------

gcls:		ld	c, 9
		call	sub_A386	; SCALE-Faktor 1
		jr	ypos1

;-----------------------------------------------------------------------------
; XPOS
; XPOS liefert als Rückgabeparameter die x-Koordinate des letzten erreichten Punktes
;-----------------------------------------------------------------------------

xpos:		ld	c, 0Bh
		jr	ypos1

;-----------------------------------------------------------------------------
; YPOS
; YPOS liefert als Rückgabeparameter die y-Koordinate des letzten erreichten Punktes
;-----------------------------------------------------------------------------

ypos:		ld	c, 0Ch
		jr	ypos1
ypos1:		jp	plsv		; interner Sprungverteiler

;-----------------------------------------------------------------------------
; SCALE	xfaktor,yfaktor
; Mit SCALE erfolgt eine Maßstabsfestlegung in x- bzw. y-Richtung (unabhängig voneinander).
; Alle Koordinatenangaben werden vor der Verarbeitung mit xfaktor bzw. yfaktor multipliziert.
;-----------------------------------------------------------------------------

scale:		call	SNALY		; Parameter übernehmen
		ld	de, fscalex
		call	size7		; float-Wert nach (DE)
		ld	a, (hl)
		cp	','
		jp	nz, snerr
		call	TCHAR		; Token konsumieren
		call	SNALY		; Parameter übernehmen
		ld	de, fscaley
		call	size7		; float-Wert nach (DE)
		ret

;-----------------------------------------------------------------------------
; SCREEN [0],plotter
; plotter = 0 => Abschalten des Plotters
; SCREEN 1	=> Grafikbildschirm
; Wird die SCREEN-Anweisung erst nach den Anweisungen zum Zeichnen gegeben,
; zeichnet der Grafik-Zusatz "im Hintergrund".
;-----------------------------------------------------------------------------

; UP, für screen1 und gcls
; SCALE-Faktor 1 einstellen
sub_A386:	ex	de, hl		; hl sichern
		ld	hl, 0
		ld	(fscalex), hl	; SCALE x-Faktor
		ld	(fscaley), hl	; SCALE y-Faktor
		ld	h, 81h 		; hl=8100h <=> "1.0f"
		ld	(fscalex+2), hl
		ld	(fscaley+2), hl
		ex	de, hl		; hl rücksichern
		ret

; mögliche Ports zum Anschluß des Plotters
porttab:	db  89h	; Plotter 1 - E/A-Buchse
		db 0C8h	; Plotter 2 - E/-Modul, Adr. 0C8h, Port A
		db 0C9h	; Plotter 3 - E/-Modul, Adr. 0C8h, Port B
		db 0CCh	; Plotter 4 - E/-Modul, Adr. 0CCh, Port A
		db 0CBh	; Plotter 5 - E/-Modul, Adr. 0CCh, Port B

;
screen:		ld	a, (WINJP)
		bit	7, a
		set	7, a
;
		call	z,sub_A386	; SCALE-Faktor 1
screen21:	call	TCHAR1
		jr	z, screen5	; wenn kein weiteres Zeichen
		cp	','		; Komma?
		jr	nz, screen22
		call	screen10	; wenn Komma, Grafik aus
		jr	screen4		; Plotter init.
;
screen22:	call	sub_A489	; 0/1-Parameter holen
		jr	nz, screen2	; 1 - Grafik ein
		call	screen10	; sonst Plotter: Grafik aus
		jr	screen3
screen2:	call	screen11	; Grafik ein
; zweiter Parameter
screen3:	call	TCHAR1
		jr	z, screen6	; wenn kein weiteres Zeichen
		cp	','		; folgt Komma?
		jp	nz, snerr	; Fehler, wenn kein Komma
; Plotter init.
screen4:	call	TCHAR		; Token konsumieren
		call	ARGVL1		; numerischen Parameter übernehmen
		and	a
		jr	z, screen7	; 0 - Abschalten Plotter
		cp	6		; max. Wert 5
		jp	nc, fcerr
		dec	a
		ld	c, a
		ld	b, 0
		ex	de, hl		; HL sichern
		ld	hl, porttab
		add	hl, bc
		ld	a, (hl)		; Port aus Porttabelle holen
		ex	de, hl		; HL restaurieren
		ld	(WINJP+1), a	; aktuellen Port f. Plotter merken
		and	a
		jr	screen7
;
screen5:	call	screen10	; Grafik aus
screen6:	xor	a		; 0 - Abschalten Plotter
;
screen7:	ld	a, (WINJP)
		jr	z, screen8
		set	0, a		; Bit0=1 setzen => Plotter
		jr	screen9
screen8:	res	0, a		; Bit0=0 setzen => Grafikzusatz
screen9:	ld	(WINJP), a
		ret
;
screen10:	ld	a, 11100010b	; RAND, Ink cyan, Grafik aus, Paper Grün
		jr	screen12
;
screen11:	ld	a, (atrib)	; aktuelles Farbattribut
		or	10001000b	; RAND ein, Grafik ein
screen12:	out	(GR_CTRL), a
		ret

;-----------------------------------------------------------------------------
; POINT(X,Y)
; Bestimmen des Punktzustandes
; POINT liefert als Rückgabeparameter 0, wenn der Abfragepunkt die
; Hintergrundfarbe, und 1, wenn der Abfragepunkt die Vordergrundfarbe hat.
;-----------------------------------------------------------------------------

point:		ld	a, (hl)
		cp	0ABh		; Token fuer STEP
		ld	b, -1		; Offset-Mode -1
		jr	nz, point1	; kein STEP
		call	TCHAR		; Token konsumieren
		jr	point2
point1:		ld	b, 1		; Offset-Mode 1
point2:		ld	de, pltparambuf
		push	de
		ld	a, b
		ld	(de), a		; Step
		inc	de
		call	point3		; Koordinaten parsen
		pop	de
		ld	c, 0Ah
		jp	plsv		; interner Sprungverteiler

; Koordinaten zu einem Punkt aus Eingabezeile parsen und skalieren
point3:		ld	a, (hl)
		cp	'('
		jp	nz, snerr
		call	TCHAR		; '(' holen
		push	de
		call	SNALY		; X-Koordinate
		push	hl
		ld	hl, fscalex
		call	size9		; skalieren
		ex	de, hl
		pop	hl
		ex	(sp), hl
		ld	(hl), e		; in (HL) ablegen
		inc	hl
		ld	(hl), d
		inc	hl
		ex	(sp), hl
		call	CPCOMM		; ',' holen
		call	SNALY		; Y-Koordinate
		push	hl
		ld	hl, fscaley
		call	size9		; skalieren
		ex	de, hl
		pop	hl
		ex	(sp), hl
		ld	(hl), e		; in (HL) ablegen
		inc	hl
		ld	(hl), d
		inc	hl
		pop	de
		ex	de, hl
		ld	a, (hl)
		cp	')'
		jp	nz, snerr
		call	TCHAR		; ')' holen
		ret

; ungenutzter Code ???
unk_xxx2:	push	de
		call	EPRVL4
		ex	(sp), hl
		ld	(hl), e
		inc	hl
		ld	(hl), d
		inc	hl
		ex	(sp), hl
		pop	de
		ret

; 0/1-Parameter holen
sub_A489:	push	de
		call	ARGVL1		; numerischen Parameter übernehmen
		pop	de
		and	a
		ret	z		; wenn A = 0
		dec	a
		jp	nz, fcerr	; wenn A <> 1
		inc	a		; A = 1 restaurieren
		ret

;-----------------------------------------------------------------------------
; Sprungverteiler für BASIC, vorgegeben in BM608 (2K-Erweiterung f. Grafik)
;-----------------------------------------------------------------------------

		if 	$>0A7D6H
			ERROR "Speicherbereich überschritten!"
		endif


	IF GRAFVER='OS'
		org	0A7D6H
	ELSEIF GRAFVER='CPM'
		db	0A7D6H-$ dup (0)		; mit 00 auffüllen
	ENDIF

vertei:		jp	pset
		jp	line
		jp	circle
		jp	paint
		jp	label
		jp	size
		jp	zero
		jp	home
		jp	gcls
		jp	scale
		jp	screen
		jp	point
		jp	xpos
		jp	ypos

	IF GRAFVER='CPM'
		dephase
	ENDIF

grafend		equ	$

		end	0ffffh		; kein autostart

