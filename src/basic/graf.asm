; File Name   :	GRAF.rom
; Format      :	Binary File
; Base Address:	0000h Range: 8E60h - A860h Loaded length: 1A00h

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

GRAFZE		equ	192		; Anz. Zeilen
GRAFSP		equ	256		; Anz. Spalten

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

; lokale Speicher Grafikmodul

unk_7FDDh	equ	7FDDh		; Startpunkt xpos (nur für g_label)
g_memxpos       equ	7FDFh		; xpos
g_memypos       equ	7FE1h		; ypos
g_memxposhome   equ	7FE3h		; xpos-Home
g_memyposhome	equ 	7FE5h		; ypos-Home
unk_7FE7h       equ	7FE7h		; JP xxxx
unk_7FEAh       equ	7FEAh		; JP xxxx
g_bitmask	equ 	7FEDh		; aktuelle Bitmaske f. Byte im Grafikspeicher
g_memptr	equ 	7FEEh		; aktuelle Adresse im Grafikspeicher
unk_7FF0h	equ	7FF0h
unk_7FF2h	equ 	7FF2h
unk_7FF4h	equ 	7FF4h
unk_7FF6h	equ 	7FF6h
unk_7FF8h	equ 	7FF8h
unk_7FFAh	equ 	7FFAh
unk_7FFCh       equ	7FFCh
unk_7FFEh       equ	7FFEh


; Ansteuerung des Grafikzusatz
; 6144 Byte (0..17FFh) externer Speicher (256x192 Pixel), wird über Ports angesteuert
; Byte 0 wird links oben angezeigt: Pixel (191,0)-(191,7)
; Byte 17FF wird rechts unten angezeigt: Pixel (0,248)-(0,255)
; Farbe (Portausgabe) gilt für die gesamte Grafik

GR_CTRL		equ	0B8h		; Farbe + Grafik ein/aus
					; 7 6 5 4 3 2 1 0
					; | | | | | | | |
					; | --|-- | --|--
					; |   |   |   PAPER (BGR)
					; |   |   Grafik ein/aus
					; |   INK (BGR)
					; RAND
GR_ADRL		equ	0B9h		; Adresse (Low-Teil) für internen Speicher
					; die unteren Adressleitungen werden mit OUT (n)
					; direkt ausgegeben
GR_DATA		equ	0BAh		; Daten (8 Pixel), Ausgabe mit OUT (C),
					; die Adresse (High-Teil) liegt über Register B
					; auf dem Adressbus (Adr.15-8)

; IN r,(C), OUT (C),r, and the Block I/O instructions actually place the entire BC
; register on the address bus. Similarly IN A,(n) and OUT (n),A put A * 256 + n on
; the address bus.


;Farben
;000	schwarz
;001	rot
;010	grün
;011	gelb
;100	blau
;101	purpur 	(violett)
;110	cyan	(hellblau)
;111	weiß


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

		org	8E60h

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
plsvtab1:	dw g_set		; Funktion 01h
		dw g_line		; Funktion 02h usw.
		dw g_circle
		dw g_paint		; paint ist nicht implementiert
		dw g_label
		dw g_paint		; size ist nicht implementiert
		dw g_zero
		dw g_home
		dw g_gcls
		dw g_point		; Funktion 0Ah
		dw g_xpos
		dw g_ypos

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
		ld	b, a
		inc	a
		ld	c, a
		ld	(unk_7FF0h), bc
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
		ld	bc, 0F60Ah
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
		ld	bc, 0F8F8h
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
		or	4
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
		ld	hl, 800h
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
		ld	a, 0CFh
		out	(c), a
		ld	(unk_267), a	; Initialisierung merken
		ld	a, 20h
		out	(c), a
loc_95A4:	ld	a, (WINJP+1)	; Port f. Plotter
		ld	c, a
		ld	a, (unk_24E)
		out	(c), a
		or	40h
		out	(c), a
		in	a, (c)
		and	20h
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


		newpage
;*****************************************************************************
; GRAFIK-MODUL-TREIBER
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

g_set:		ex	de, hl
		call	g_koord		; Punktkoordinaten holen
		ld	a, (hl)		; stift
		ld	(pltparambuf+9), a	; aktuelle Stift-Farbe (1 VG, 0 BG)
		ld	bc, (pltparambuf+1)	; X
		ld	de, (pltparambuf+3)	; Y
		call	g_set8		; Beschränken Punktkoordinaten
		ld	(g_memxpos), bc
		ld	(g_memypos), de
		jr	nc, g_set1
		call	sub_99E8	; Umrechnung BC (X), DE (Y) zu g_memptr
		call	sub_9A12	; Byte in Grafikspeicher schreiben (Pixel setzen)
g_set1:		ret

; Punktkoordinaten holen und Offset addieren
; ab (HL) 1 Byte Offs-Mode, 2 Byte X, 2 Byte Y
g_koord:	ld	a, (hl)
		push	af
		inc	hl
		call	g_ldehl		; DE = 1. Wert (x)
		push	hl
		or	a
		jr	nz, g_koord1
		ld	e, a		; wenn a = 0 dann de := 0
		ld	d, a
g_koord1:	ld	hl, (g_memxpos)	; letzte Koordinate
		dec	a
		jr	nz, g_koord2	; wenn a = -1 (Step)
		ld	hl, (g_memxposhome)	; wenn a = 1
g_koord2:	add	hl, de		; Offset addieren
		ld	(pltparambuf+1), hl
		ld	(g_memxpos), hl
		ld	b, h
		ld	c, l
		pop	hl
		call	g_ldehl		; DE = 2. Wert (y)
		pop	af
		push	hl
		or	a
		jr	nz, g_koord3
		ld	e, a		; wenn a = 0 dann de := 0
		ld	d, a
g_koord3:	ld	hl, (g_memypos)	; letzte Koordinate
		dec	a
		jr	nz, g_koord4	; wenn a = -1 (Step)
		ld	hl, (g_memyposhome)	; wenn a = 1
g_koord4:	add	hl, de		; Offset addieren
		ld	(pltparambuf+3), hl
		ld	(g_memypos), hl
		ex	de, hl
		pop	hl
		ret

; DE = (HL+1)(HL), HL=HL+2; 'POP DE' mit HL als Stack
g_ldehl:	ld	e, (hl)
		inc	hl
		ld	d, (hl)
		inc	hl
		ret

; Beschränken Punktkoordinaten BC = Spalte X, DE = Zeile Y in Koordinaten im Grafikspeicher
g_set8:		push	bc		; Spalte auf Stack
		ld	b, 1		; Überlaufmerker
; Zeile
		ex	de, hl		; HL = Zeile
		ld	a, h
		add	a, a		; A=2*Zeile
		jr	nc, g_set9	; wenn kein Überlauf
		ld	hl, 0		; HL=Zeile=0, B=0
		jr	g_set10
g_set9:		ld	de, GRAFZE	; Anz. Zeilen
		call	CPREG		; vergleiche DE mit HL
		jr	c, g_set11	; wenn HL<DE, dann B=1
		ex	de, hl		; andernfalls Zeile beschränken
		dec	hl		; HL := GRAFZE-1
g_set10:	ld	b, 0
; Spalte
g_set11:	ex	(sp), hl	; HL = Spalte, Zeile auf Stack
		ld	a, h
		add	a, a		; A=2*Spalte
		jr	nc, g_set12	; wenn kein Überlauf
		ld	hl, 0		; HL=Spalte=0, B=0
		jr	g_set13
g_set12:	ld	de, GRAFSP	; Anz. Spalten
		call	CPREG		; vergleiche DE mit HL
		jr	c, g_set14	; wenn HL<DE
		ex	de, hl		; andernfalls Spalte beschränken
		dec	hl		; HL := GRAFSP-1
g_set13:	ld	b, 0
;
g_set14:	pop	de		; Zeile von Stack
		ld	a, b		; Überlaufmerker
		rrca			; in Cy-Flag schieben
		ld	b, h		; Spalte aus HL
		ld	c, l
		ret


; Umrechnung BC (X), DE (Y) zu g_memptr

sub_99E8_tab:	db  10000000b
		db  01000000b
		db  00100000b
		db  00010000b
		db  00001000b
		db  00000100b
		db  00000010b
		db  00000001b

; Bitmaske ermitteln
sub_99E8:	ld	d, c		; orig. X-Wert sichern
		ld	a, c
		and	7		; unteren 3 Bit maskieren
		ld	c, a
		ld	hl, sub_99E8_tab
		add	hl, bc		; Bitmaske ermitteln
		ld	a, (hl)		; B ist 0 beim Aufruf
		ld	(g_bitmask), a	; Bitmaske ablegen

;subroutine zu g_point
;Umrechnung BC (D)-xpos Spalte , E-ypos Zeile zu g_memptr
loc_99F5:	ld	a, d
		rrca
		rrca
		rrca			; xpos/8 = Byte-Position Spaltenoffset
		and	1Fh
		ld	c, a		; B=0 bei Aufruf
		ld	d, e
		xor	a
		rr	d
		rra
		rr	d
		rra
		rr	d
		rra
		ld	e, a
		ld	hl, 17E0h	; (GRAFZE-1)*(GRAFSP/8); Anf.Adr. unterste Zeile
		sbc	hl, de		; Zeilen abziehen
		add	hl, bc		; Spaltenoffset addieren
		ld	(g_memptr), hl	; aktuelle Adresse im Grafikspeicher
		ret

; Byte in Grafikspeicher schreiben (Pixel setzen)
sub_9A12:	call	g_readbyte	; Byte an aktueller Adresse lesen
		push	bc
		ld	c, a		; Byte sichern
		ld	a, (pltparambuf+9)	; aktuelle Stift-Farbe (1 VG, 0 BG)
		or	a
		ld	a, (g_bitmask)
		jr	z, loc_9A23	; wenn Hintergrund (Pixel Löschen)
		or	c		; sonst Bits setzen
		jr	loc_9A25
loc_9A23:	cpl			; sonst Maske negieren
		and	c		; und Bits rücksetzen
loc_9A25:	pop	bc
		jp	g_writebyte

; Lesen eines Bytes aus dem Grafikzusatz-Speicher
g_readbyte:	push	bc
		ld	bc, (g_memptr)	; aktuelle Adresse im Grafikspeicher
		ld	a, c
		ld	c, GR_DATA
		out	(GR_ADRL), a	; Ausgabe Adresse (Low-Byte)
		in	a, (c)		; Lesen des Wertes, dabei auch Ausgabe des Hi-Bytes (B) der Adresse
		pop	bc
		ret

; Schreiben eines Bytes aus dem Grafikzusatz-Speicher
g_writebyte:	push	bc
		push	af
		ld	bc, (g_memptr)	; aktuelle Adresse im Grafikspeicher
		ld	a, c
		ld	c, GR_DATA
		out	(GR_ADRL),a	; Ausgabe Adresse (Low-Byte)
		pop	af
		out	(c), a		; Schreiben des Wertes, dabei auch Ausgabe des Hi-Bytes (B) der Adresse
		pop	bc
		ret

; g_bitmask und g_memptr nach A und HL
g_getmemval:	ld	a, (g_bitmask)
		ld	hl, (g_memptr)	; aktuelle Adresse im Grafikspeicher
		ret

; A und HL nach g_bitmask und g_memptr (UP zu g_line1)
g_setmemval:	ld	(g_bitmask), a
		ld	(g_memptr), hl	; aktuelle Adresse im Grafikspeicher
		ret

;UP's zu line

;nächste Spalte
g_nxtcol:	push	hl
		call	g_getmemval	; g_bitmask und g_memptr nach A und HL
		rrca
		jr	nc, g_prvcol2
		inc	hl
		jr	g_prvcol1

;vorherige Spalte
g_prvcol:	push	hl
		call	g_getmemval	; g_bitmask und g_memptr nach A und HL
		rlca
		jr	nc, g_prvcol2
		dec	hl
g_prvcol1:	ld	(g_memptr), hl	; aktuelle Adresse im Grafikspeicher
g_prvcol2:	ld	(g_bitmask), a
		and	a
		pop	hl
		ret

;vorherige Zeile (??? ungenutzt)
g_prvrow:	push	hl
		push	de
		ld	hl, (g_memptr)	; aktuelle Adresse im Grafikspeicher
		ld	de, 20h		; GRAFSP/8
		add	hl, de		; nächste Zeile
		jr	g_nxtrow1

;nächste Zeile
g_nxtrow:	push	hl
		push	de
		ld	hl, (g_memptr)	; aktuelle Adresse im Grafikspeicher
		ld	de, 20h		; GRAFSP/8
		and	a		; Cy=0
		sbc	hl, de		; vorherige Zeile
g_nxtrow1:	ld	(g_memptr), hl	; aktuelle Adresse im Grafikspeicher
		and	a
		pop	de
		pop	hl
		ret

;-----------------------------------------------------------------------------
; Fkt. 09h Bildschirm löschen, Pointer auf (0,0) setzen
;-----------------------------------------------------------------------------

g_gcls:
; Pointer auf (0,0) setzen
		ld	hl, 0
		ld	(g_memxpos), hl
		ld	(g_memypos), hl
; Speicher löschen
g_gcls1:	xor	a
		ld	(g_memptr), hl	; aktuelle Adresse im Grafikspeicher
		call	g_writebyte
		inc	hl
		ld	a, l
		or	a
		jr	nz, g_gcls1
		ld	a, 18h		;(= hi(256x192/8Bit)
		cp	h
		jr	nz, g_gcls1	; 1800h Null-Bytes schreiben
		ret

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

; UP zu g_circle
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
		ld	hl, (unk_7FF0h)
		add	hl, hl
		add	hl, hl
		add	hl, hl
		ld	a, h
		ld	b, l
		call	FRE3
		pop	bc
		pop	de
		call	MUL1
		call	EPRVL3
loc_9AF5:	pop	hl
		ret


g_circle:	ex	de, hl
		call	g_koord		; Punktkoordinaten holen
		push	hl
		call	OPKOP
		call	EPRVL3
		ex	de, hl
		ld	(pltparambuf+1), hl
		pop	hl
		call	OPKOP
		push	hl
		ld	bc, 8035h
		ld	de, 4F3h
		call	MUL1
		call	EPRVL3
		ld	(unk_7FF0h), de
		xor	a
		ld	(pltparambuf), a
		ld	(unk_29B), a
		pop	hl
		inc	hl
		ld	c, 1
		call	sub_9AA8
		push	de
		ld	c, 80h
		ld	hl, pltparambuf+14
		call	sub_9AA8
		pop	hl
		xor	a
		ex	de, hl
		call	CPREG		; vergleiche DE mit HL
		ld	a, 0
		jr	nc, g_circle1
		dec	a
		ex	de, hl
		push	af
		ld	a, (pltparambuf)
		ld	c, a
		rlca
		rlca
		or	c
		rrca
		ld	(pltparambuf), a
		pop	af
g_circle1:	ld	(unk_29C), a
		ld	(pltparambuf+10), de
		ld	(pltparambuf+12), hl
		ld	hl, pltparambuf+18
		call	OPKOP
		ld	a, (WRA1+3)
		cp	81h
		ld	a, 0
		jr	c, g_circle2
		inc	a
		ld	(unk_29B), a
		call	sub_9CF1
g_circle2:	ld	bc, 8900h
		ld	de, 0
		call	MUL1
		call	EPRVL3
		ex	de, hl
		ld	(pltparambuf+18), hl
		ld	de, 0
		ld	(unk_7FF2h), de
		ld	hl, (pltparambuf+1)
		add	hl, hl
g_circle3:	ld	a, e
		rra
		jr	c, g_circle4
		push	de
		push	hl
		inc	hl
		ex	de, hl
		call	sub_9CE3	; DE=DE/2
		ex	de, hl
		inc	de
		call	sub_9CE3	; DE=DE/2
		call	g_circle7
		pop	de
		pop	hl
		call	CPREG		; vergleiche DE mit HL
		ret	nc
		ex	de, hl
g_circle4:	ld	b, h
		ld	c, l
		ld	hl, (unk_7FF2h)
		inc	hl
		add	hl, de
		add	hl, de
		ld	a, h
		add	a, a
		jr	c, g_circle5
		push	de
		ex	de, hl
		ld	h, b
		ld	l, c
		add	hl, hl
		dec	hl
		ex	de, hl
		or	a
		sbc	hl, de
		dec	bc
		pop	de
g_circle5:	ld	(unk_7FF2h), hl
		ld	h, b
		ld	l, c
		inc	de
		jr	g_circle3

g_circle6:	push	de
		call	g_circle20
		pop	hl
		ld	a, (unk_29B)
		or	a
		ret	z
		ex	de, hl
		ret

g_circle7:	ld	(unk_7FF6h), de
		push	hl
		ld	hl, 0
		ld	(unk_7FF4h), hl
		call	g_circle6
		ld	(unk_7FFAh), hl
		pop	hl
		ex	de, hl
		push	hl
		call	g_circle6
		ld	(unk_7FF8h), de
		pop	de
		call	sub_9CEB
		call	g_circle8
		push	hl
		push	de
		ld	hl, (unk_7FF0h)
		ld	(unk_7FF4h), hl
		ld	de, (unk_7FF6h)
		or	a
		sbc	hl, de
		ld	(unk_7FF6h), hl
		ld	hl, (unk_7FFAh)
		call	sub_9D06	; HL negieren
		ld	(unk_7FFAh), hl
		pop	de
		pop	hl
		call	sub_9CEB

g_circle8:	ld	a, 4
g_circle9:	push	af
		push	hl
		push	de
		push	hl
		push	de
		ld	de, (unk_7FF4h)
		ld	hl, (unk_7FF0h)
		add	hl, hl
		add	hl, de
		ld	(unk_7FF4h), hl
		ld	hl, (unk_7FF6h)
		add	hl, de
		ex	de, hl
		ld	hl, (pltparambuf+10)
		call	CPREG		; vergleiche DE mit HL
		jr	z, g_circle12
		jr	nc, g_circle10
		ld	hl, (pltparambuf+12)
		call	CPREG		; vergleiche DE mit HL
		jr	z, g_circle11
		jr	nc, g_circle14
g_circle10:	ld	a, (unk_29C)
		or	a
		jr	nz, g_circle16
		jr	g_circle15
g_circle11:	ld	a, (pltparambuf)
		add	a, a
		jr	nc, g_circle16
		jr	g_circle13
g_circle12:	ld	a, (pltparambuf)
		rra
		jr	nc, g_circle16
g_circle13:	pop	de
		pop	hl
		call	g_circle19
		call	g_circle18
		jr	g_circle17
g_circle14:	ld	a, (unk_29C)
		or	a
		jr	z, g_circle16
g_circle15:	pop	de
		pop	hl
		jr	g_circle17
g_circle16:	pop	de
		pop	hl
		call	g_circle19
		call	g_set8		; Beschränken Punktkoordinaten
		jr	nc, g_circle17
		call	sub_99E8	; Umrechnung BC (X), DE (Y) zu g_memptr
		call	sub_9A12	; Byte in Grafikspeicher schreiben (Pixel setzen)
g_circle17:	pop	de
		pop	hl
		pop	af
		dec	a
		ret	z
		push	af
		push	de
		ld	de, (unk_7FFAh)
		call	sub_9CEB
		ld	(unk_7FFAh), hl
		ex	de, hl
		pop	de
		push	hl
		ld	hl, (unk_7FF8h)
		ex	de, hl
		ld	(unk_7FF8h), hl
		call	sub_9CEB
		pop	hl
		pop	af
		jp	g_circle9

g_circle18:	ld	hl, (g_memxpos)
		ld	(pltparambuf+1), hl
		ld	hl, (g_memypos)
		ld	(pltparambuf+3), hl
		jp	sub_9DC4

g_circle19:	push	de
		ld	de, (g_memxpos)
		add	hl, de
		ld	b, h
		ld	c, l
		pop	de
		ld	hl, (g_memypos)
		xor	a
		sbc	hl, de
		ex	de, hl
		ret

g_circle20:	ld	hl, (pltparambuf+18)
		ld	a, l
		or	a
		jr	nz, g_circle21
		or	h
		ret	nz
		ex	de, hl
		ret

g_circle21:	ld	c, d
		ld	d, 0
		push	af
		call	g_circle22
		ld	e, 80h
		add	hl, de
		ld	e, c
		ld	c, h
		pop	af
		call	g_circle22
		ld	e, c
		add	hl, de
		ex	de, hl
		ret

g_circle22:	ld	b, 8
		ld	hl, 0
g_circle23:	add	hl, hl
		add	a, a
		jr	nc, g_circle24
		add	hl, de
g_circle24:	djnz	g_circle23
		ret

; DE=DE/2
sub_9CE3:	ld	a, d
		or	a		; Cy:=0
		rra
		ld	d, a
		ld	a, e
		rra
		ld	e, a
		ret

sub_9CEB:	ex	de, hl
		call	sub_9D06	; HL negieren
		ex	de, hl
		ret

sub_9CF1:	ld	de, 0
		ld	bc, 8100h	; 1.0f
		call	DIV1
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

nullsub_1:	ret

; Anstieg X ermitteln
; ret: HL Anstieg (absolut), Cy=0 wenn steigend, =1 wenn fallend
sub_9CFC:	ld	hl, (pltparambuf+1)	; X 1. Punkt
		ld	a, l
		sub	c
		ld	l, a
		ld	a, h
		sbc	a, b
		ld	h, a		; HL := HL-BC
loc_9D05:	ret	nc		; wenn kein Überlauf, d.h. HL > BC
; HL negieren
sub_9D06:	xor	a		; A := 0, Cy := 0
		sub	l
		ld	l, a
		sbc	a, h
		sub	l
		ld	h, a		; HL := -HL
		scf
		ret

; Anstieg Y ermitteln
; ret: HL Anstieg (absolut), Cy=0 wenn steigend, =1 wenn fallend
sub_9D0E:	ld	hl, (pltparambuf+3)	; Y 1. Punkt
		ld	a, l
		sub	e
		ld	l, a
		ld	a, h
		sbc	a, d
		ld	h, a		; HL := HL-DE
		jr	loc_9D05

; Y 1. Punkt auf DE setzen
sub_9D19:	push	hl
		ld	hl, (pltparambuf+3)	; Y 1. Punkt
		ex	de, hl
		ld	(pltparambuf+3), hl	; Y 1. Punkt
		pop	hl
		ret

; 1. Punkt auf (BC,DE) setzen
sub_9D23:	call	sub_9D19	; Y 1. Punkt auf DE setzen
; X 1. Punkt auf BC setzen
loc_9D26:	push	hl
		push	bc
		ld	hl, (pltparambuf+1)	; X 1. Punkt
		ex	(sp), hl
		ld	(pltparambuf+1), hl	; X 1. Punkt
		pop	bc
		pop	hl
		ret


g_line:		ex	de, hl
		call	g_koord		; Punktkoordinaten holen 1. Punkt
		push	bc
		push	de
		call	g_koord		; Punktkoordinaten holen 2. Punkt
		ld	a, (hl)
		ld	(pltparambuf+9), a	; aktuelle Stift-Farbe (1 VG, 0 BG)
		inc	hl
		pop	de
		pop	bc
		ld	a, (hl)		; BOX
		or	a
		jr	z, sub_9D84	; Linie
		dec	a
		jr	z, loc_9D9A	; Rechteck
; ausgefülltes Rechteck ???
		push	hl
		call	g_set8		; Beschränken Punktkoordinaten
		call	sub_9D23	; 1. Punkt auf (BC,DE) setzen
		call	g_set8		; Beschränken Punktkoordinaten
		call	sub_9D0E
		call	c, sub_9D19	; Y 1. Punkt auf DE setzen
		inc	hl
		push	hl
		call	sub_9CFC
		call	c, loc_9D26	; X 1. Punkt auf BC setzen
		inc	hl
		push	hl
		call	sub_99E8	; Umrechnung BC (X), DE (Y) zu g_memptr
		pop	de
		pop	bc
g_line1:	push	de
		push	bc
		call	g_getmemval	; g_bitmask und g_memptr nach A und HL
		push	af
		push	hl
		ex	de, hl
		call	nullsub_1
		pop	hl
		pop	af
		call	g_setmemval	; A und HL nach g_bitmask und g_memptr
		call	g_nxtrow
		pop	bc
		pop	de
		dec	bc
		ld	a, b
		or	c
		jr	nz, g_line1
		pop	hl
		ret

; Linie zeichnen
sub_9D84:	push	bc
		push	de
		push	hl
		call	sub_9DC4
		; Endpunkt als neuen Startpunkt merken
		ld	hl, (g_memxpos)
		ld	(pltparambuf+1), hl
		ld	hl, (g_memypos)
		ld	(pltparambuf+3), hl
		pop	hl
		pop	de
		pop	bc
		ret

; Rechteck zeichnen
loc_9D9A:	push	hl
		ld	hl, (pltparambuf+3)
		push	hl
		push	de
		ex	de, hl
		call	sub_9D84	; Linie zeichnen
		pop	hl
		ld	(pltparambuf+3), hl
		ex	de, hl
		call	sub_9D84	; Linie zeichnen
		pop	hl
		ld	(pltparambuf+3), hl
		ld	hl, (pltparambuf+1)
		push	bc
		ld	b, h
		ld	c, l
		call	sub_9D84	; Linie zeichnen
		pop	hl
		ld	(pltparambuf+1), hl
		ld	b, h
		ld	c, l
		call	sub_9D84	; Linie zeichnen
		pop	hl
		ret

; Linie zeichnen
sub_9DC4:	call	g_set8		; Beschränken Punktkoordinaten
		call	sub_9D23	; 1. Punkt auf (BC,DE) setzen
		call	g_set8		; Beschränken Punktkoordinaten
		call	sub_9D0E	; Anstieg Y ermitteln
		call	c, sub_9D23	; wenn falled, 1. Punkt neu setzen
		push	de
		push	hl
		call	sub_9CFC	; Anstieg X ermitteln
		ex	de, hl
		ld	hl, g_nxtcol	; Fkt. nächste Spalte
		jr	nc, loc_9DE1	; wenn Anstieg positiv
		ld	hl, g_prvcol	; Fkt. vorherige Spalte
loc_9DE1:	ex	(sp), hl
		call	CPREG		; vergleiche DE mit HL
		jr	nc, loc_9DF7
;
		ld	(unk_7FFCh), hl
		pop	hl
		ld	(unk_7FE7h+1), hl	; Spaltenfunktion
		ld	hl, g_nxtrow	; Fkt. nächste Zeile
		ld	(unk_7FEAh+1), hl	; Zeilenfunktion
		ex	de, hl
		jr	loc_9E06
;		
loc_9DF7:	ex	(sp), hl
		ld	(unk_7FEAh+1), hl	; Zeilenfunktion
		ld	hl, g_nxtrow	; Fkt. nächste Zeile
		ld	(unk_7FE7h+1), hl	; Spaltenfunktion
		ex	de, hl
		ld	(unk_7FFCh), hl
		pop	hl
;
loc_9E06:	pop	de
		push	hl
		call	sub_9D06	; HL negieren
		ld	(unk_7FFEh), hl
		call	sub_99E8	; Umrechnung BC (X), DE (Y) zu g_memptr
		pop	de
		push	de
		call	sub_9CE3	; DE=DE/2
		pop	bc
		inc	bc
		jr	loc_9E21
;
loc_9E1A:	pop	hl
		ld	a, b
		or	c
		ret	z
loc_9E1E:	call	unk_7FE7h	; nächste Spalte
loc_9E21:	call	sub_9A12	; Byte in Grafikspeicher schreiben (Pixel setzen)
		dec	bc
		push	hl
		ld	hl, (unk_7FFCh)
		add	hl, de
		ex	de, hl
		ld	hl, (unk_7FFEh)
		add	hl, de
		jr	nc, loc_9E1A
		ex	de, hl
		pop	hl
		ld	a, b
		or	c
		ret	z
		call	unk_7FEAh	; nächste Zeile
		jr	loc_9E1E

;-----------------------------------------------------------------------------
; Fkt. 05h Ausgabe einer Zeichenkette
; DE = parambuf
; 	parambuf+0: 2 Byte Länge Zeichenkette (max. 255!)
; 	parambuf+2: 2 Byte Adr. Zeichenkette
; 	parambuf+4: Stift
; Stift: 	1 Vordergrundfarbe, 0 Hintergrundfarbe
; vp: stift wird ignoriert
;-----------------------------------------------------------------------------

g_label:	ld	hl, (g_memxpos)
		ld	(unk_7FDDh), hl	; aktuelle xpos merken
		ex	de, hl		; HL = Adr. Stringvariable
		ld	a, (hl)		; A = Länge
		inc	hl
		inc	hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)		; DE=Adr. String
		inc	a
		dec	de
		push	af
		push	de
; nächstes Zeichen ausgeben
g_label1:	pop	hl		; Adr. auszugebendes Zeichen im String
		pop	de		; D = Anzahl der noch auchzugebenden Zeichen
		inc	hl
		dec	d
		ret	z		; Ende, wenn alle Zeichen ausgegeben
		ld	a, (hl)		; A= auszugebendes Zeichen
		push	de
		push	hl
		;Sonderzeichen
		cp	20h ; ' '
		jr	nc, g_label2	; erlaubtes Text-Zeichen
		cp	0Dh		; 0Dh => neue Zeile
		jp	z, g_label_nl
		cp	17h		; 17h => Zeichen löschen
		jp	z, g_label_del
		cp	18h		; 18h + nächstes Zeichen => Umlaut
		jr	z, g_label_umlaut
		jp	nc, g_label_poly	; bleiben 19h-1FH Polygonzug-Sonderzeichen
		ld	(hl), ' '	; alle anderen Steuerzeichen werden Leerzeichen
		jr	g_label3
g_label2:	rla			; Bit 7 holen
		jr	nc, g_label3
		ld	(hl), ' '	; Grafikzeichen werden Leerzeichen

		;normale Zeichen ausgeben
g_label3:	call	g_label_chpos	; Adresse Zeichen in Zeichensatztabelle holen
		push	hl
		call	sub_9EB7
		ld	(g_memxpos), hl
g_label4:	call	sub_99E8	; Umrechnung BC (X), DE (Y) zu g_memptr
		pop	hl
;
		ld	b, 8
g_label5:	push	hl
		ld	d, (hl)
		ld	e, 0
		ld	a, (g_bitmask)
g_label6:	rla
		jr	c, g_label7
		srl	d
		rr	e
		jr	g_label6
g_label7:	call	g_readbyte
		or	d
		call	g_writebyte
		ld	hl, (g_memptr)	; aktuelle Adresse im Grafikspeicher
		inc	hl
		ld	(g_memptr), hl	; aktuelle Adresse im Grafikspeicher
		call	g_readbyte
		or	e
		call	g_writebyte
		ld	hl, (g_memptr)	; aktuelle Adresse im Grafikspeicher
		ld	de, GRAFSP/8-1
		add	hl, de
		ld	(g_memptr), hl	; aktuelle Adresse im Grafikspeicher
		pop	hl
		inc	hl
		djnz	g_label5
;
g_label8:	jr	g_label1

;
sub_9EB7:	ld	hl, (g_memypos)
		ld	bc, 7
		add	hl, bc
		push	hl
		ex	de, hl
		ld	hl, (g_memxpos)
		push	hl
		ld	bc, 5
		add	hl, bc
		ld	b, h
		ld	c, l
		inc	hl
		push	hl
		call	g_set8		; Beschränken Punktkoordinaten
		pop	hl
		pop	bc
		pop	de
		ret	c
		pop	hl
loc_9ED4:	pop	hl
		pop	hl
		pop	hl
		ret

;18h + nächstes Zeichen => Umlaut
g_label_umlaut:	call	g_label_chpos		; Adresse Zeichen in Zeichensatztabelle holen
		push	hl
		call	sub_9EB7
		jr	g_label4

;0Dh => neue Zeile
g_label_nl:	ld	hl, (unk_7FDDh)		; aktuelle xpos vor label
		ld	(g_memxpos), hl		; xpos wieder auf Anfang setzen
		ld	hl, (g_memypos)
		ld	de, 8
		xor	a
		sbc	hl, de
		ld	(g_memypos), hl		; ypos 8 Zeilen tiefer (Nullpunkt ist li.u.!)
		jr	g_label8

;17h => Zeichen löschen
g_label_del:	call	sub_9EB7
		ld	(g_memxpos), hl
		call	sub_99E8		; Umrechnung BC (X), DE (Y) zu g_memptr
		ld	de, 3FFh
		ld	a, (g_bitmask)
g_label_del1:	rla
		jr	c, g_label_del2
		ccf
		rr	d
		rr	e
		jr	g_label_del1
g_label_del2:	ld	b, 8
g_label_del3:	call	g_readbyte
		and	d
		call	g_writebyte
		ld	hl, (g_memptr)	; aktuelle Adresse im Grafikspeicher
		inc	hl
		ld	(g_memptr), hl
		call	g_readbyte
		and	e
		call	g_writebyte
		ld	hl, (g_memptr)	; aktuelle Adresse im Grafikspeicher
		push	bc
		ld	bc, GRAFSP/8-1
		add	hl, bc
		pop	bc
		ld	(g_memptr), hl	; aktuelle Adresse im Grafikspeicher
		djnz	g_label_del3
		jr	g_label8

;Adresse Zeichen in Zeichensatztabelle holen
g_label_chpos:	ld	b, 0
		ld	c, (hl)		; Zeichen
		sla	c
		rl	b
		sla	c
		rl	b
		sla	c
		rl	b		; BC=Zeichen*8
		ld	hl, tab_charset-(18h*8)	;Tabelle tab_charset beginnt erst ab Code 18h
		add	hl, bc
		ret

;19h-1FH => Polygonzug-Sonderzeichen
g_label_poly:	call	g_label_chpos	; Adresse Zeichen in Zeichensatztabelle holen
		push	hl
		ld	de, (g_memypos)
		push	de
		ld	bc, (g_memxpos)
		push	bc
		inc	de
		inc	bc
		call	g_set8		; Beschränken Punktkoordinaten
		pop	bc
		pop	de
g_label_poly1:	jp	nc, loc_9ED4
		push	de
		dec	de
		dec	bc
		call	g_set8		; Beschränken Punktkoordinaten
		pop	de
		jr	nc, g_label_poly1
		inc	de
		call	sub_99E8	; Umrechnung BC (X), DE (Y) zu g_memptr
		pop	hl
		ld	b, 3
		jp	g_label5

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

; nicht implementiert
g_paint:	ret

;-----------------------------------------------------------------------------
; Fkt. 07h Nullpunkt festlegen
; DE = parambuf
; 	parambuf+0: Offs-Mode
; 	parambuf+1: 2 Byte X
; 	parambuf+3: 2 Byte Y
; Offs-Mode: 	-1 Step, 1 absolut
;-----------------------------------------------------------------------------

g_zero:		ex	de, hl
		ld	a, (hl)		; STEP?
		inc	hl
		dec	a
		push	af
		call	g_ldehl		; DE = (HL+1)(HL), HL=HL+2
		push	hl
		jr	z, g_zero1	; wenn absolute Angabe
		ld	hl, (g_memxposhome)
		add	hl, de		; sonst STEP-Offset addieren
		ex	de, hl
g_zero1:	ld	(g_memxposhome), de
		pop	hl
		pop	af
		call	g_ldehl		; DE = (HL+1)(HL), HL=HL+2
		jr	z, g_zero2	; wenn absolute Angabe
		ld	hl, (g_memyposhome)
		add	hl, de		; sonst STEP-Offset addieren
		ex	de, hl
g_zero2:	ld	(g_memyposhome), de
		ret

;-----------------------------------------------------------------------------
; Fkt. 08h Pointer auf Home setzen
;-----------------------------------------------------------------------------

g_home:		ld	hl, (g_memxposhome)
		ld	(g_memxpos), hl
		ld	hl, (g_memyposhome)
		ld	(g_memypos), hl
		ret

;-----------------------------------------------------------------------------
; Fkt. 0Ah Punkt abfragen
; DE = parambuf
; 	parambuf+0: Offs-Mode
; 	parambuf+1: 2 Byte X
; 	parambuf+3: 2 Byte Y
; Offs-Mode: 	-1 Step, 1 absolut
;-----------------------------------------------------------------------------

g_point:	ex	de, hl
		call	g_koord		; Punktkoordinaten holen
		ld	bc, (g_memxpos)
		push	bc
		ld	de, (g_memypos)
		ld	d, c
		call	loc_99F5	; Umrechnung BC (X), DE (Y) zu g_memptr
		call	g_readbyte
		pop	bc
		push	af
		ld	a, c
		and	7		; die unteren 3 Bit der X-Koordinate
		inc	a		; A ist Bit-Position im membyte
		ld	b, a
		pop	af
g_point1:	rla			; Bit herausschieben
		djnz	g_point1
		jr	nc, g_point2 	; Wenn Bit nicht gesetzt (B = 0)
		inc	b		; wenn Bit gesetzt (B=1)
g_point2:	xor	a		; A := 0
		jr	g_xpos2		; Wert (AB) an BASIC zurückgeben

;-----------------------------------------------------------------------------
; Fkt. 0Bh x-Position abfragen
;-----------------------------------------------------------------------------

g_xpos:		ld	hl, (g_memxpos)
		ld	de, (g_memxposhome)
g_xpos1:	and	a
		sbc	hl, de
		ld	b, l
		ld	a, h
g_xpos2:	jp	FRE3		; Wert an BASIC zurückgeben

;-----------------------------------------------------------------------------
; Fkt. 0Ch  y-Position abfragen
;-----------------------------------------------------------------------------

g_ypos:		ld	hl, (g_memypos)
		ld	de, (g_memyposhome)
		jr	g_xpos1
		ret


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
		jp	nz, snerr
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
		jp	nz, snerr
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
		jp	nz, snerr
; Box
line9:		ld	b, 0
		call	TCHAR		; Token konsumieren
		cp	'B'
		jp	nz, snerr
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
		jp	nz, snerr
; radius
		call	TCHAR		; Token konsumieren
		call	SNALY		; Parameter übernehmen
		ld	de, pltparambuf+5
		call	size7		; float-Wert nach (DE)
		call	TCHAR1
		jr	z, circle10	; wenn kein weiteres Zeichen folgt
		cp	','		; folgt Komma ?
		jp	nz, snerr	; Fehler wenn kein Komma
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
		jp	nz, snerr
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
		jp	nz, snerr
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
		jr	nz, screen21
		set	7, a
		ld	(WINJP), a
; 8 Byte ab g_memxpos mit 00 init. (mempos, memposhome)
		xor	a
		ld	de, g_memxpos
		ld	b, 8
screen1:	ld	(de), a
		inc	de
		djnz	screen1
;
		call	sub_A386	; SCALE-Faktor 1
		ld	a, 0C3h		; JP
		ld	(unk_7FE7h), a	; UP-Sprung f. g_line
		ld	(unk_7FEAh), a	; UP-Sprung f. g_line
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
		ld	b, a
		ld	c, 0
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


; Zeichensatztabelle für g_label
tab_charset:
; Char 18
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 19
	DB	11100000B	;"###     "
	DB	10100000B	;"# #     "
	DB	11100000B	;"###     "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 1A
	DB	01000000B	;" #      "
	DB	10100000B	;"# #     "
	DB	01000000B	;" #      "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 1B
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	11100000B	;"###     "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 1C
	DB	11100000B	;"###     "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 1D
	DB	01000000B	;" #      "
	DB	11100000B	;"###     "
	DB	01000000B	;" #      "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 1E
	DB	10100000B	;"# #     "
	DB	01000000B	;" #      "
	DB	10100000B	;"# #     "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 1F
	DB	11100000B	;"###     "
	DB	11100000B	;"###     "
	DB	11100000B	;"###     "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 20 ( )
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 21 (!)
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "

; Char 22 (")
	DB	00101000B	;"  # #   "
	DB	00101000B	;"  # #   "
	DB	00101000B	;"  # #   "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 23 (#)
	DB	00101000B	;"  # #   "
	DB	00101000B	;"  # #   "
	DB	01111100B	;" #####  "
	DB	00101000B	;"  # #   "
	DB	01111100B	;" #####  "
	DB	00101000B	;"  # #   "
	DB	00101000B	;"  # #   "
	DB	00000000B	;"        "

; Char 24 ($)
	DB	00010000B	;"   #    "
	DB	00111100B	;"  ####  "
	DB	01010000B	;" # #    "
	DB	00111000B	;"  ###   "
	DB	00010100B	;"   # #  "
	DB	01111000B	;" ####   "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "

; Char 25 (%)
	DB	01100000B	;" ##     "
	DB	01100100B	;" ##  #  "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	01001100B	;" #  ##  "
	DB	00001100B	;"    ##  "
	DB	00000000B	;"        "

; Char 26 (&)
	DB	00010000B	;"   #    "
	DB	00101000B	;"  # #   "
	DB	00101000B	;"  # #   "
	DB	00110000B	;"  ##    "
	DB	01010100B	;" # # #  "
	DB	01001000B	;" #  #   "
	DB	00110100B	;"  ## #  "
	DB	00000000B	;"        "

; Char 27 (')
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 28 (()
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	00100000B	;"  #     "
	DB	00100000B	;"  #     "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000000B	;"        "

; Char 29 ())
	DB	00100000B	;"  #     "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	00000000B	;"        "

; Char 2A (*)
	DB	00000000B	;"        "
	DB	00010000B	;"   #    "
	DB	01010100B	;" # # #  "
	DB	00111000B	;"  ###   "
	DB	01010100B	;" # # #  "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 2B (+)
	DB	00000000B	;"        "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	01111100B	;" #####  "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 2C (,)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	00000000B	;"        "

; Char 2D (-)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01111100B	;" #####  "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 2E (.)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00110000B	;"  ##    "
	DB	00110000B	;"  ##    "
	DB	00000000B	;"        "

; Char 2F (/)
	DB	00000000B	;"        "
	DB	00000100B	;"     #  "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	01000000B	;" #      "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 30 (0)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01001100B	;" #  ##  "
	DB	01010100B	;" # # #  "
	DB	01100100B	;" ##  #  "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 31 (1)
	DB	00010000B	;"   #    "
	DB	00110000B	;"  ##    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 32 (2)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	00000100B	;"     #  "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	01111100B	;" #####  "
	DB	00000000B	;"        "

; Char 33 (3)
	DB	01111100B	;" #####  "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000100B	;"     #  "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 34 (4)
	DB	00001000B	;"    #   "
	DB	00011000B	;"   ##   "
	DB	00101000B	;"  # #   "
	DB	01001000B	;" #  #   "
	DB	01111100B	;" #####  "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	00000000B	;"        "

; Char 35 (5)
	DB	01111100B	;" #####  "
	DB	01000000B	;" #      "
	DB	01111000B	;" ####   "
	DB	00000100B	;"     #  "
	DB	00000100B	;"     #  "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 36 (6)
	DB	00011000B	;"   ##   "
	DB	00100000B	;"  #     "
	DB	01000000B	;" #      "
	DB	01111000B	;" ####   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 37 (7)
	DB	01111100B	;" #####  "
	DB	00000100B	;"     #  "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	00100000B	;"  #     "
	DB	00100000B	;"  #     "
	DB	00000000B	;"        "

; Char 38 (8)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 39 (9)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111100B	;"  ####  "
	DB	00000100B	;"     #  "
	DB	00001000B	;"    #   "
	DB	00110000B	;"  ##    "
	DB	00000000B	;"        "

; Char 3A (:)
	DB	00000000B	;"        "
	DB	00110000B	;"  ##    "
	DB	00110000B	;"  ##    "
	DB	00000000B	;"        "
	DB	00110000B	;"  ##    "
	DB	00110000B	;"  ##    "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 3B (;)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	00000000B	;"        "

; Char 3C (<)
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	01000000B	;" #      "
	DB	00100000B	;"  #     "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000000B	;"        "

; Char 3D (=)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01111100B	;" #####  "
	DB	00000000B	;"        "
	DB	01111100B	;" #####  "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 3E (>)
	DB	00100000B	;"  #     "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000100B	;"     #  "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	00000000B	;"        "

; Char 3F (?)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	00000100B	;"     #  "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "

; Char 40 (@)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01011100B	;" # ###  "
	DB	01010100B	;" # # #  "
	DB	01011100B	;" # ###  "
	DB	01000000B	;" #      "
	DB	00111100B	;"  ####  "
	DB	00000000B	;"        "

; Char 41 (A)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01111100B	;" #####  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 42 (B)
	DB	01111000B	;" ####   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01111000B	;" ####   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01111000B	;" ####   "
	DB	00000000B	;"        "

; Char 43 (C)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 44 (D)
	DB	01111000B	;" ####   "
	DB	00100100B	;"  #  #  "
	DB	00100100B	;"  #  #  "
	DB	00100100B	;"  #  #  "
	DB	00100100B	;"  #  #  "
	DB	00100100B	;"  #  #  "
	DB	01111000B	;" ####   "
	DB	00000000B	;"        "

; Char 45 (E)
	DB	01111100B	;" #####  "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01111000B	;" ####   "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01111100B	;" #####  "
	DB	00000000B	;"        "

; Char 46 (F)
	DB	01111100B	;" #####  "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01111000B	;" ####   "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	00000000B	;"        "

; Char 47 (G)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01001100B	;" #  ##  "
	DB	01000100B	;" #   #  "
	DB	00111100B	;"  ####  "
	DB	00000000B	;"        "

; Char 48 (H)
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01111100B	;" #####  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 49 (I)
	DB	00111000B	;"  ###   "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 4A (J)
	DB	00011100B	;"   ###  "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	01001000B	;" #  #   "
	DB	00110000B	;"  ##    "
	DB	00000000B	;"        "

; Char 4B (K)
	DB	01000100B	;" #   #  "
	DB	01001000B	;" #  #   "
	DB	01010000B	;" # #    "
	DB	01100000B	;" ##     "
	DB	01010000B	;" # #    "
	DB	01001000B	;" #  #   "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 4C (L)
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01111100B	;" #####  "
	DB	00000000B	;"        "

; Char 4D (M)
	DB	01000100B	;" #   #  "
	DB	01101100B	;" ## ##  "
	DB	01010100B	;" # # #  "
	DB	01010100B	;" # # #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 4E (N)
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01100100B	;" ##  #  "
	DB	01010100B	;" # # #  "
	DB	01001100B	;" #  ##  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 4F (O)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 50 (P)
	DB	01111000B	;" ####   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01111000B	;" ####   "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	00000000B	;"        "

; Char 51 (Q)
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01010100B	;" # # #  "
	DB	01001000B	;" #  #   "
	DB	00110100B	;"  ## #  "
	DB	00000000B	;"        "

; Char 52 (R)
	DB	01111000B	;" ####   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01111000B	;" ####   "
	DB	01010000B	;" # #    "
	DB	01001000B	;" #  #   "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 53 (S)
	DB	00111100B	;"  ####  "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	00111000B	;"  ###   "
	DB	00000100B	;"     #  "
	DB	00000100B	;"     #  "
	DB	01111000B	;" ####   "
	DB	00000000B	;"        "

; Char 54 (T)
	DB	01111100B	;" #####  "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "

; Char 55 (U)
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 56 (V)
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00101000B	;"  # #   "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "

; Char 57 (W)
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01010100B	;" # # #  "
	DB	01010100B	;" # # #  "
	DB	01101100B	;" ## ##  "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 58 (X)
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00101000B	;"  # #   "
	DB	00010000B	;"   #    "
	DB	00101000B	;"  # #   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 59 (Y)
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00101000B	;"  # #   "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "

; Char 5A (Z)
	DB	01111100B	;" #####  "
	DB	00000100B	;"     #  "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	01000000B	;" #      "
	DB	01111100B	;" #####  "
	DB	00000000B	;"        "

; Char 5B ([)
	DB	00111000B	;"  ###   "
	DB	00100000B	;"  #     "
	DB	00100000B	;"  #     "
	DB	00100000B	;"  #     "
	DB	00100000B	;"  #     "
	DB	00100000B	;"  #     "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 5C (\)
	DB	00000000B	;"        "
	DB	01000000B	;" #      "
	DB	00100000B	;"  #     "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000100B	;"     #  "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 5D (])
	DB	00111000B	;"  ###   "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	00001000B	;"    #   "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 5E (^)
	DB	00010000B	;"   #    "
	DB	00101000B	;"  # #   "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 5F (_)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01111100B	;" #####  "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 60 (`)
	DB	00000000B	;"        "
	DB	00100000B	;"  #     "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 61 (a)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00110100B	;"  ## #  "
	DB	01001100B	;" #  ##  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111010B	;"  ### # "
	DB	00000000B	;"        "

; Char 62 (b)
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01011000B	;" # ##   "
	DB	01100100B	;" ##  #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01111000B	;" ####   "
	DB	00000000B	;"        "

; Char 63 (c)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000000B	;" #      "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 64 (d)
	DB	00000100B	;"     #  "
	DB	00000100B	;"     #  "
	DB	00110100B	;"  ## #  "
	DB	01001100B	;" #  ##  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111010B	;"  ### # "
	DB	00000000B	;"        "

; Char 65 (e)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01111100B	;" #####  "
	DB	01000000B	;" #      "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 66 (f)
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00111000B	;"  ###   "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "

; Char 67 (g)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00110100B	;"  ## #  "
	DB	01001100B	;" #  ##  "
	DB	01000100B	;" #   #  "
	DB	00111100B	;"  ####  "
	DB	00000100B	;"     #  "
	DB	00111000B	;"  ###   "

; Char 68 (h)
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01011000B	;" # ##   "
	DB	01100100B	;" ##  #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 69 (i)
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000000B	;"        "

; Char 6A (j)
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "

; Char 6B (k)
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01001000B	;" #  #   "
	DB	01010000B	;" # #    "
	DB	01110000B	;" ###    "
	DB	01001000B	;" #  #   "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 6C (l)
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000000B	;"        "

; Char 6D (m)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01101000B	;" ## #   "
	DB	01010100B	;" # # #  "
	DB	01010100B	;" # # #  "
	DB	01010100B	;" # # #  "
	DB	01010100B	;" # # #  "
	DB	00000000B	;"        "

; Char 6E (n)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01011000B	;" # ##   "
	DB	01100100B	;" ##  #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 6F (o)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00111000B	;"  ###   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111000B	;"  ###   "
	DB	00000000B	;"        "

; Char 70 (p)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01011000B	;" # ##   "
	DB	01100100B	;" ##  #  "
	DB	01000100B	;" #   #  "
	DB	01111000B	;" ####   "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "

; Char 71 (q)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00110100B	;"  ## #  "
	DB	01001100B	;" #  ##  "
	DB	01000100B	;" #   #  "
	DB	00111100B	;"  ####  "
	DB	00000100B	;"     #  "
	DB	00000100B	;"     #  "

; Char 72 (r)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01011000B	;" # ##   "
	DB	01100100B	;" ##  #  "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	01000000B	;" #      "
	DB	00000000B	;"        "

; Char 73 (s)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00111000B	;"  ###   "
	DB	01000000B	;" #      "
	DB	00111000B	;"  ###   "
	DB	00000100B	;"     #  "
	DB	01111000B	;" ####   "
	DB	00000000B	;"        "

; Char 74 (t)
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00111000B	;"  ###   "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000000B	;"        "

; Char 75 (u)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01001100B	;" #  ##  "
	DB	00110100B	;"  ## #  "
	DB	00000000B	;"        "

; Char 76 (v)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00101000B	;"  # #   "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "

; Char 77 (w)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01010100B	;" # # #  "
	DB	01010100B	;" # # #  "
	DB	01010100B	;" # # #  "
	DB	01010100B	;" # # #  "
	DB	00101000B	;"  # #   "
	DB	00000000B	;"        "

; Char 78 (x)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01000100B	;" #   #  "
	DB	00101000B	;"  # #   "
	DB	00010000B	;"   #    "
	DB	00101000B	;"  # #   "
	DB	01000100B	;" #   #  "
	DB	00000000B	;"        "

; Char 79 (y)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	00111100B	;"  ####  "
	DB	00000100B	;"     #  "
	DB	00111000B	;"  ###   "

; Char 7A (z)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	01111100B	;" #####  "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	01111100B	;" #####  "
	DB	00000000B	;"        "

; Char 7B ({)
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00000000B	;"        "

; Char 7C (|)
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00000000B	;"        "

; Char 7D (})
	DB	00100000B	;"  #     "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00001000B	;"    #   "
	DB	00010000B	;"   #    "
	DB	00010000B	;"   #    "
	DB	00100000B	;"  #     "
	DB	00000000B	;"        "

; Char 7E (~)
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00110010B	;"  ##  # "
	DB	01001100B	;" #  ##  "
	DB	00000000B	;"        "
	DB	00000000B	;"        "
	DB	00000000B	;"        "

; Char 7F ()
	DB	00110000B	;"  ##    "
	DB	01001000B	;" #  #   "
	DB	01001000B	;" #  #   "
	DB	01111000B	;" ####   "
	DB	01000100B	;" #   #  "
	DB	01000100B	;" #   #  "
	DB	01111000B	;" ####   "
	DB	01000000B	;" #      "

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

