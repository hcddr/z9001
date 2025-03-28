; File Name   :	m112.rom / bm608.rom
; Format      :	Binary File
; Base Address:	0000h Range: E000h - E800h Loaded length: 0800h


;Lutz-El�ner-Erweiterung
;-----------------------
;2 Varianten bekannt:
;BASEA.ROM	von Kassette
;basic-2le.rom	aus 192k-Modul
;Beschrieben im Softwarekatalog 1/88

;ERWTYP	equ	"BM608"
ERWTYP	equ	"LE192K"
;ERWTYP	equ	"BASEA"

;bei LE verwendete Adressen
;340h	nur rcons4
;308h	nur wtape2
;0DE6Bh	???? nur im ungenutzten (?) marke-teil
;309h	???? nur im ungenutzten (?) marke-teil


		cpu	z80

;Z9001-OS
DMA		equ	001BH 	;Zeiger auf Puffer f�r Kassetten-E/A
ATRIB		EQU	0027H	;aktuelles Farbattribut
BLNR		equ	006Bh	;Blocknummer
LBLNR		equ	006Ch	;gesuchte Blocknummer bei Lesen
M005A		equ	005Ah
M006E		equ	006Eh	;Position im Buffer
M0075		equ	0075h	;Modus beim Speichern/Lesen (D3..D5)
M0077		equ	0077h	;Merkzelle HL (f�r tape)
CONBU		equ	0080h	;Standardpuffer f�r Kassetten-E/A

port88		equ	088h	;Farbattribut
portB8		equ	0B8h	;Pixelgrafik

OSPAC		equ	0F310h	;Leerzeichen ausgeben
;PRNST		equ	0F3E2h
KARAM		equ	0FED6h
MAREK		equ	0FF59h


;ADRESSEN UND DATEN AUS BASIC KERN
GTOTOK		equ	88h
RSTTOK		equ	8Bh
GSBTOK		equ	8Ch
THNTOK		equ	0A9h
SGNTOK		EQU	0B6H
LODTOK		EQU	0D0H
ELSTOK		equ	0D4h

		include	basic_8k_kern.inc

; wesentliche Funktionen des Interpreterkernes:
;       ARGVL1          numerischen Parameter �bernehmen
;       SNALY           String-Parameter �bernehmen
;       LEN1            L�nge und Adresse String-Parameter bestimmen
;       STROP           Platz im Stringpool reservieren, Adr. neuer String in DE
;       STRMV1          String eintragen in Stringpool
;	CPSTX		Test auf '('
;	CPCOMM		Test auf Komma
;	CPBRGT		Test auf ')'
;
;	HL		;ZEILENZEIGER


;AS-Funktionen
hi              function x,(x>>8)&255
lo              function x, x&255
nextpage	function x, ((x+0ffh)/100h)*100h

		org 	EXTBEG

;-----------------------------------------------------------------------------
; BASIC-Erweiterung
;-----------------------------------------------------------------------------

		db	0FFh
		db	0FFh
		db	0FFh

		jp	erw1
sub_0_E006:	jp	erw2
		jp	erw3

		dw	mntab
		jp	vertei

MNTAB:		db	'I'+80h, "NKEY$"
IKTOK		EQU	0D5H	;INKEY$
		db	'J'+80h, "OYST"
JOTOK		EQU	0D6H	;JOYST
		db	'S'+80h, "TRING$"
STROK		EQU	0D7H	;STRING$
		db	'I'+80h, "NSTR"
ISTOK		EQU	0D8H	;INSTR
	IF ERWTYP == "BM608"
		db	'R'+80h, "ENUM"
	ELSEIF (ERWTYP == "LE192K") || (ERWTYP == "BASEA")
		db	'R'+80h, "ESET"
	ENDIF
RETOK		EQU	0D9H	;RENUMBER
		db	'D'+80h, "ELETE"
DETOK		EQU	0DAH	;DELETE
		db	'P'+80h, "AUSE"
PATOK		EQU	0DBH	;PAUSE
		db	'B'+80h, "EEP"
BETOK		EQU	0DCH	;BEEP
		db	'W'+80h, "INDOW"
WITOK		EQU	0DDH	;WINDOW
		db	'B'+80h, "ORDER"
BOTOK		EQU	0DEH	;BORDER
		db	'I'+80h, "NK"
INTOKE		EQU	0DFH	;INK
		db	'P'+80h, "APER"
PPTOK		EQU	0E0H	;PAPER
		db	'A'+80h, "T"
ATTOK		EQU	0E1H	;AT
;
		db	'P'+80h, "SET"
		;equ	0E2h
		db	'L'+80h, "INE"
		;equ	0E3h
		db	'C'+80h, "IRCLE"
		;equ	0E4h
		db	'!'+80h
		;equ	0E5h
		db	'P'+80h, "AINT"
		;equ	0E6h
		db	'L'+80h, "ABEL"
		;equ	0E7h
		db	'S'+80h, "IZE"
		;equ	0E8h
		db	'Z'+80h, "ERO"
		;equ	0E9h
		db	'H'+80h, "OME"
		;equ	0EAh
		db	'!'+80h
		;equ	0EBh
		db	'G'+80h, "CLS"
		;equ	0ECh
		db	'S'+80h, "CALE"
		;equ	0EDh
		db	'S'+80h, "CREEN"
		;equ	0EEh
		db	'P'+80h, "OINT"
		;equ	0EFh
		db	'X'+80h, "POS"
		;equ	0F0h
		db	'!'+80h
		;equ	0F1h
		db	'Y'+80h, "POS"
		;equ	0F2h
		db	80h

adrtbe:		dw	inkey
		dw	joyst
		dw	string
		dw	instr

adrtab1:	
	IF ERWTYP == "BM608"
		dw	renum
	ELSEIF (ERWTYP == "LE192K") || (ERWTYP == "BASEA")
		dw	reset
	ENDIF
		dw	delete
		dw	pause
		dw	beep
		dw	window
		dw	border
		dw	ink
		dw	paper
		dw	at
;
adrtab2:	dw	0A7D6h		;PSET
		dw	0A7D9h		;LINE
		dw	0A7DCh		;CIRCLE
		dw	REM   		;!
		dw	0A7DFh		;PAINT
		dw	0A7E2h		;LABEL
		dw	0A7E5h		;SIZE
		dw	0A7E8h		;ZERO
		dw	0A7EBh		;HOME
		dw	REM   		;!
		dw	0A7EEh		;GCLS
		dw	0A7F1h		;SCALE
		dw	0A7F4h		;SCREEN
		dw	0A7F7h		;POINT
		dw	0A7FAh		;XPOS
		dw	REM   		;!
		dw	0A7FDh		;YPOS

;-----------------------------------------------------------------------------
; ERWEITERUNG 1
;*  E: <B>:TOKEN-LODTOK
;*     <HL> :  AUF TOKEN
;*  A:   <<SP>>: STARTADRESSE ROUTINE
;*     <HL>:  AUF TOKEN
;
;-----------------------------------------------------------------------------

erw1:		ld	a, b
		sub	RETOK-LODTOK
		jr	c, snerr
		cp	ATTOK-RETOK+1
		jr	c, ERW11
		call	erw12
		cp	16h
		jr	nc, snerr
;
ERW11:		rlca
		ld	c, a
		ld	b, 0
		ex	de, hl
		ld	hl, adrtab1
		add	hl, bc
		ld	c, (hl)
		inc	hl
		ld	b, (hl)
		push	bc
		ex	de, hl
		jp	TCHAR

;-----------------------------------------------------------------------------
; ERWEITERUNG 2
;*  E:   <HL> AUF SIGNIF. ZEICHEN NACH PRTOK
;*  WENN  PRTFLG<>0 , DANN JP SNER
;*  A:   <HL> AUF ZEILENENDE
;-----------------------------------------------------------------------------

ERW2:		ld	a, (hl)
		cp	INTOKE		;ZULAESSIG?
		ret	c
		cp	ATTOK+1		;PRINT-ERWEITERUNGEN
		ret	nc		;KEINS FUER PRINT
		cp	ATTOK
		jp	z, AT		;START PRINTAT
		ld	a, (PRTFLG)	;DOPPELTES AUFTRETEN ABBLOCKEN
		and	a
		jr	nz, snerr
		inc	a
		ld	(PRTFLG),a
		ld	a, (ATRIB)
		push	af		;FARBE RETTEN
		ld	a, (hl)
		cp	INTOKE
		jr	z, INPRT
		call	TCHAR
		call	PAPER
		ld	a, (hl)
		cp	';'		;PAPER n ;
		jr	z, CLRG1
		jr	snerr

INPRT:		call	TCHAR
		call	INK
		ld	a, (hl)
		cp	';'
		jr	z, CLRG1
		call	CPCOMM
		cp	PPTOK
		jr	nz, snerr
		call	TCHAR		;INK n,PAPER n;
		call	PAPER
		call	CPSTX
		db	';'

CLREG:		call	PRINT2
		pop	af
		ld	(ATRIB), a
		pop	bc
		ret

snerr:		ld	a, 0E2h
		out	(portB8), a	;Pixelgrafik abschalten
		jp	SNER

fcerr:		ld	a, 0E2h
		out	(portB8), a	;Pixelgrafik abschalten
		jp	FCER

CLRG1:		call	TCHAR
		jr	CLREG

;-----------------------------------------------------------------------------
; ERWEITERUNG 3
;* VERTEILER ZU ZUSAETZLICHEN STANDARTFUNKTIONEN
;* E: <HL> AUF SIGN. ZEICHEN NACH TOKEN
;*    <BC> =<<SP>>  (TOKEN-SGNTOK)*2
;* A: <HL> AUF SIGN. ZEICHEN NACH TOKEN
;-----------------------------------------------------------------------------

erw3:		ld	a, c			;ZULAESSIG?
		sub	3Eh
		jr	c, snerr
		cp	7
		jr	c, erw31
		call	erw12
		cp	32h
		jr	c, snerr
		cp	3Bh
		jr	nc, snerr
;
erw31:		ex	de, hl
		ld	bc, adrtbe		;NEIN
		pop	hl
		ld	l, a
		add	hl, bc
		ld	c, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, c
		push	hl
		ex	de, hl
		ret				;ABSPRUNG ZUR ROUTINE

;-----------------------------------------------------------------------------
; BORDER i
; legt die Bildschirmrandfarbe fest.
; i =  1 schwarz ..  8 wei�
;-----------------------------------------------------------------------------

border:		ld	a, 1
		jr	paper0

;-----------------------------------------------------------------------------
; INK i
; legt die Vordergrundfarbe f�r alle nachfolgenden auszugebenden Zeichen fest.
; i =  1 schwarz ..  8 wei�
;-----------------------------------------------------------------------------

ink:		db	0F6h ; mit nachfolgendem Befehl: OR 0AFH

;-----------------------------------------------------------------------------
; PAPER i
; legt die Hintergrundfarbe f�r alle nachfolgenden auszugebenden Zeichen fest.
; i =  1 schwarz ..  8 wei�
;-----------------------------------------------------------------------------

paper:		xor	a

paper0:		push	af
		call	ARGVL1		;PARAMETER ERF.
		cp	1		;1..8?
		jr	c, window2
		cp	9
		jr	nc, window2
		dec	a
		ld	c, a		;C=i (0..7)
;
		pop	af		;Funktion
		or	a
		jr	z, paper1	;wenn PAPER
		sla	c		;i auf Bit 5..3 verschieben
		sla	c
		sla	c
		dec	a
		jr	z, paper4	;wenn BORDER
		sla	c		;i auf Bit 6..4 verschieben
paper1:		ld	b, c
		or	a
		ld	a, (ATRIB)
		jr	z, paper3	;wenn BORDER
		and	7		;sonst INK
paper2:		or	b
		ld	(ATRIB), a	;Farbattribut setzen
		ld	(ATRIB+1), a	;???
		ret
paper3:		and	70h
		jr	paper2
;
paper4:		ld	a, c
		out	(port88), a	;Farbe setzen
		ret

;-----------------------------------------------------------------------------
; WINDOW erste_zeile, letzte_zeile, erste_spalte, letzte_spalte
; WINDOW ist gleich WINDOW 0,23,0,39
;-----------------------------------------------------------------------------

WINDOW:		ld	c, 29		; DCU - Cursor l�schen
		call	5
		call	TCHAR1		;Pointer auf n�chstes signifikantes Zeichen
		jr	z, window3	;wenn keine Parameter
		call	param		;Argument holen
		push	af
		call	param		;Argument holen
		push	af
		call	param		;Argument holen
		push	af
		call	ARGVL1		;Argument holen
		inc	a
		inc	a
		ld	d, a		;d=letzte_spalte+2
		cp	42		;letzte_spalte+2 < 42 ?
		jr	nc, window2	;nein, d.h. letzte_spalte >= 40
		pop	af
		ld	e, a		;e=erste_spalte
		pop	af
		inc	a
		inc	a
		ld	b, a		;b=letzte_zeile+2
		cp	26		;letzte_zeile+2 < 26?
		jr	nc, window2	;nein, d.h. letzte_zeile >= 24
		pop	af
		ld	c, a
		inc	a
		cp	b		;erste_zeile+1 < letzte_zeile+2 ?
		jr	nc, window2	;nein, d.h. erste_zeile > letzte_zeile
		ld	a, e
		inc	a
		cp	d		;erste_spalte+1 < letzte_spalte+2 ?
		jr	nc, window2	;nein, d.h. erste_spalte > letzte_spalte
		jr	window1
;
window3:	ld	bc, 1900h	;Zeilen 1 - 18h=24
		ld	de, 2900h	;Spalten 1 - 28h=40
window1:	jp	window4
;
window2:	jp	fcerr

	IF ERWTYP == "BM608"

;-----------------------------------------------------------------------------
; RENUM [zlnralt1 [,zlnralt2 [,zlnrneu1 [,schrittweite]]]]
; Neunumerieren von Programmzeilen
; zlnralt1,2 - kennzeichnet niedrigste bzw. h�chste alte Zeilennummer
; des neu zu numerierenden Programmabschnittes
; Standardwerte: zlnralt1: niedrigste vorhandene Zeilennummer
; zlnralt2 - h�chste vorhandene Zeilennummer
; zlnrneu1 - kennzeichnet niedrigste Zeilennummer des neu numerierten
; Programmabschnittes (Standardwert: zlnralt1)
; schrittweite - Differenz zweier aufeinanderfolgender Zeilennummern
; (Standardwert: 10)
;-----------------------------------------------------------------------------

renum:		ld	bc, 10
		push	bc
		ld	d, b
		ld	e, b
		jr	z, renum2
		cp	2Ch
		jr	z, renum1
		push	de
		call	DCHEX
		ld	b, d
		ld	c, e
		pop	de
		jr	z, renum2

renum1:		call	CPCOMM
		call	DCHEX
		jr	z, renum2
		pop	af
		call	CPCOMM
		push	de
		call	DCHEX
		jp	nz, snerr
		ld	a, d
		or	e
		jr	z, window2
		ex	de, hl
		ex	(sp), hl
		ex	de, hl

renum2:		push	de
		push	bc
		call	ZPOIT
		pop	de
		push	de
		push	bc
		call	ZPOIT
		ld	h, b
		ld	l, c
		pop	de
		call	CPREG
		ex	de, hl

renum3:		jr	c, window2
		pop	de
		pop	af
		pop	bc
		push	de
		push	af
		jr	renum5

renum4:		add	hl, bc
		jr	c, renum3
		ex	de, hl
		push	hl
		ld	hl, 0FFF9h
		call	CPREG
		pop	hl
		jr	c, renum3

renum5:		push	de
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ld	a, d
		or	e
		ex	de, hl
		pop	de
		jr	z, renum6
		ld	a, (hl)
		inc	hl
		or	(hl)
		dec	hl
		ex	de, hl
		jr	nz, renum4

renum6:		push	bc
		ld	c, 80h
		call	TMEMO
		xor	a
		call	renum10
		xor	a
		inc	a
		call	renum10
		pop	bc
		pop	de
		push	bc
		call	ZPOIT
		ld	h, b
		ld	l, c
		pop	bc
		pop	de
		pop	af

renum7:		push	de
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ld	a, d
		or	e
		jr	z, renum8
		ex	de, hl
		ex	(sp), hl
		ex	de, hl
		inc	hl
		ld	(hl), e
		inc	hl
		ld	(hl), d
		ex	de, hl
		add	hl, bc
		ex	de, hl
		pop	hl
		jr	renum7

renum8:		dec	a
		call	renum10

renum9:		ld	bc, LIN10
		push	bc
		ld	a, 2

renum10:	ld	(ANF),	a
		ld	hl, (PSTBEG)
		dec	hl
		push	bc
		push	bc

renum11:	inc	hl
		pop	bc
		pop	bc
		ld	b, h
		ld	c, l
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ld	a, d
		or	e
		ret	z
		push	bc
		push	de
		inc	hl
		inc	hl

renum12:	call	TCHAR
		or	a
		jr	z, renum11
		ld	c, a
		ld	a, (ANF)
		or	a
		ld	a, c
		jr	z, renum15
		cp	0Dh
		jr	nz, renum12
		push	hl
		push	hl
		inc	hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ld	a, (ANF)
		dec	a
		jr	z, renum19
		dec	a
		jr	z, renum13
		ex	de, hl
		inc	hl
		inc	hl
		dec	de
		ldi
		ldi
		ex	de, hl
		pop	de
		pop	de
		dec	hl
		jr	renum12

renum13:	push	de
		ex	de, hl
		inc	de
		ld	hl, (SVARPT)
		sbc	hl, de
		ld	b, h
		ld	c, l
		pop	hl
		ex	(sp), hl
		ex	de, hl
		push	bc
		ldir
		pop	bc
		pop	de
		pop	hl
		push	hl
		push	bc
		xor	a
		ld	b, 98h
		call	SGN1
		call	NUMKON
		pop	bc
		pop	de
		inc	hl

renum14:	ld	a, (hl)
		ex	de, hl
		dec	hl
		or	a
		jr	z, renum12
		inc	hl
		ex	de, hl
		push	bc
		push	hl
		ex	de, hl
		add	hl, bc
		ld	d, h
		ld	e, l
		inc	de
		ld	(SVARPT), de
		dec	de
		dec	hl
		lddr
		pop	hl
		ldi
		pop	bc
		jr	renum14

renum15:	cp	GTOTOK
		jr	z, renum17
		cp	GSBTOK
		jr	z, renum17
		cp	RSTTOK
		jr	z, renum17
		cp	ELSTOK
		jr	z, renum17
		cp	DETOK
		jr	z, renum17
		cp	0D3h
		jr	z, renum17
		cp	THNTOK

renum16:	jp	nz, renum12

renum17:	call	DCHEX1
		push	hl
		call	ZPOIT
		pop	hl
		jr	c, renum20

renum18:	ld	a, (hl)
		cp	2Ch
		jr	z, renum17
		dec	hl
		jr	renum16

renum19:	call	ZPOIT
		pop	hl
		inc	hl
		ld	(hl), c
		inc	hl
		ld	(hl), b
		pop	de
		jp	renum12

renum20:	push	de
		ex	de, hl
		ld	hl, (SVARPT)
		sbc	hl, de
		inc	hl
		push	hl

renum21:	pop	bc
		ld	h, d
		ld	l, e
		dec	de
		ld	a, (de)
		cp	2Ch
		jr	z, renum22
		cp	3Ah
		jr	nc, renum22
		pop	af
		ex	(sp), hl
		dec	hl
		ex	(sp), hl
		push	af
		push	bc
		push	de
		ldir
		pop	de
		jr	renum21

renum22:	ex	de, hl
		add	hl, bc
		ld	d, h
		ld	e, l
		inc	de
		inc	de
		inc	de
		inc	de
		ld	(SVARPT), de
		dec	de
		lddr
		ld	a, 0Dh
		inc	hl
		ld	(hl), a
		inc	hl
		pop	de
		ld	(hl), e
		inc	hl
		ld	(hl), d
		pop	de
		ex	(sp), hl
		inc	de
		inc	de
		inc	de
		ld	(hl), e
		inc	hl
		ld	(hl), d
		dec	hl
		ex	(sp), hl
		push	de
		push	hl
		call	LIN11
		pop	hl
		inc	hl
		jr	renum18

	ELSEIF (ERWTYP == "LE192K") || (ERWTYP == "BASEA")

;-----------------------------------------------------------------------------
; RESET TTY-Treiber initialisieren
;-----------------------------------------------------------------------------

reset:		push	hl
		call	init_ttydrv
		ld	hl, ttydrv
		ld	(0EFE1h), hl
		pop	hl
		ret

;-----------------------------------------------------------------------------
; BASIC-Kaltstart
;-----------------------------------------------------------------------------

nbasic:		call	init_ttydrv	; BASIC-Neustart
		jp	PRIST1

;-----------------------------------------------------------------------------
; TTY-Treiber 
;-----------------------------------------------------------------------------

	IF ERWTYP == "LE192K"
init_ttydrv:	ld	a, 0FFh		; Initialisieren des Treibers
ttydrv:		ld	l, a
		ld	a, i		; I ist	normalerweise beim Z9001 = 02h
		ld	h, a
		ld	a, l
		ld	l, 7Ch		; HL =(I)7Ch
		inc	a
		jr	nz, nbasic3	; wenn A<>FF war
	ELSEIF ERWTYP == "BASEA"
ttydrv:		ld      hl, 68h
		inc     a
		jr      nz, nbasic3
init_ttydrv:
	ENDIF
; Initialisierung Treiber
	IF ERWTYP == "LE192K"
		ld	(hl), 4
	ENDIF
		ld	hl, ttydrv
		ld	(0EFD1h), hl	; Adr. TTY-Treiber f�r READER
		ld	(0EFD9h), hl	; Adr. TTY-Treiber f�r PUNCH
		ld	hl, aBasicTape ; "BASIC-TAPE 1.00"
		ld	(0EFEBh), hl	; Zeichenkette f�r READER
		ld	(0EFEDh), hl	; Zeichenkette f�r PUNCH
	IF ERWTYP == "BASEA"
		xor     a
		ld      (68h), a
	ENDIF
		ld	c, 7		; GETIO
		call	5
		ret	c
		and	11000011b	; READER und PUNCH auf TTY-Treiber setzen
		ld	e, a
		ld	c, 8		; SETIO
		jp	5

nbasic3:	
	IF ERWTYP == "LE192K"
		bit	2, (hl)
		jr	z, nbasic9
	ENDIF
		dec	a
		jr	nz, nbasic8
		bit	0, (hl)
		jp	z, nbasic24
		call	nbasic4
		ret	nc
		or	a
		ret	z
		scf
		ret

nbasic4:	
	IF ERWTYP == "LE192K"
		inc	hl
	ELSEIF ERWTYP == "BASEA"
		ld      hl, 67h
	ENDIF
		ld	de, 80h	; '�'
		ld	a, 7Fh ; ''
		cp	(hl)
		jr	nc, nbasic6
		ld	a, (6Bh)
		inc	a
		ret	z

nbasic5:	ld	c, 26		; SETDM
		call	5
		ret	c
		ld	c, 20		; READS
		call	5
		jr	c, nbasic7
		ld	(hl), 0

nbasic6:	push	hl
		ld	l, (hl)
		ld	h, 0
		add	hl, de
		ld	a, (hl)
		pop	hl
		or	a
		ret	nz
		dec	a
		ret

nbasic7:	ld	c, 1		; CONSI
		call	5
		ret	c
		cp	0Dh
		jr	z, nbasic5
		sub	3
		jr	nz, nbasic7
		scf
		ret

nbasic8:	dec	a
		jr	nz, nbasic12
		bit	0, (hl)
nbasic9:	jr	z, nbasic18
nbasic10:	call	nbasic4
		ret	c
nbasic11:	ld	a, (hl)
		inc	(hl)
		ld	l, a
		ld	h, 0
		ld	de, 80h	; '�'
		add	hl, de
		ld	a, (hl)
		ld	(hl), c
		ret

nbasic12:	dec	a
		jr	nz, nbasic13
		push	bc
		call	nbasic24
		pop	bc
		ret	c
		jr	nbasic11

nbasic13:	sub	0Fh
		jr	nz, nbasic16
nbasic14:	ld	de, 80h	; '�'
		ld	c, 26		; SETDM
		call	5
		ret	c

	IF ERWTYP == "LE192K"
		ld	c, 13		; outcr
		call	5
		jr	c, nbasic15
		set	0, (hl)
		inc	hl
		ld	(hl), 80h ; '�'
		dec	hl
		ret
	ELSEIF ERWTYP == "BASEA"
		ld      hl, 67h ; 'g'
		ld      (hl), 0
		ld      c, 0Dh
		call    5
		jr      c, nbasic15
		ld      (hl), 80h ; '�'
		ld      a, 1
		ld      (68h), a
		ret
	ENDIF

nbasic15:	or	a
		scf
		ret	z
		ld	c, 1		; CONSI
		call	5
		ret	c
		cp	0Dh
		jr	z, nbasic14
		sub	3
		jr	nbasic15

nbasic16:	dec	a
		jr	nz, nbasic17
		ld	c, 15		; OPENW
		call	5
		ret	c
	IF ERWTYP == "LE192K"
		set	1, (hl)
		inc	hl
	ELSEIF ERWTYP == "BASEA"
		ld      a, 2
		ld      (68h), a
	ENDIF
		jr	nbasic25

nbasic17:	dec	a
		jr	nz, nbasic20
		bit	0, (hl)
nbasic18:	jr	z, nbasic23
nbasic19:	ld	c, 14		; CLOSER
		call	5
	IF ERWTYP == "LE192K"
		res	0, (hl)
	ELSEIF ERWTYP == "BASEA"
		ret	c
		xor     a
		ld      (68h), a
	ENDIF
		ret

nbasic20:	dec	a
		jr	nz, nbasic22
		bit	1, (hl)
		jr	z, nbasic23
		ld	de, 80h	; '�'
		ld	c, 26		; SETDM
		call	5
		ret	c
		ld	c, 16		; CLOSW
		call	5
		ret	c
		call	nbasic27	; ein Leerzeichen ausgeben
		ret	c
	IF ERWTYP == "LE192K"
		res	1, (hl)
		ld	a, (25h)
		cp	1Bh
		ret	z
	ELSEIF ERWTYP == "BASEA"
		xor     a
		ld      (68h), a
	ENDIF
		ld	de, aVerifyAbbruch ; "\r\nVERIFY (Abbruch mit STOP)"
		ld	c, 9		; PRNST
		call	5
		ret	c
		call	nbasic14
		jr	nc, nbasic21
		or	a
		ret	z
		scf
		ret

nbasic21:
	IF ERWTYP == "LE192K"
		push	hl
	ENDIF
		call	nbasic10
	IF ERWTYP == "LE192K"
		pop	hl
	ENDIF
		jr	nc, nbasic21
		or	a
		jr	z, nbasic19
		scf
		ret

nbasic22:	or	a
		ret

nbasic23:	ld	de, aFileNotOpen ; "File not OPEN"
		ld	c, 9		; PRNST
		call	5
		scf
		ret

nbasic24:	bit	1, (hl)
		jr	z, nbasic23
	IF ERWTYP == "LE192K"
		inc	hl
	ELSEIF ERWTYP == "BASEA"
		ld      hl, 67h
	ENDIF
		ld	a, 7Fh ; ''
		cp	(hl)
		ld	a, 0FFh
		ret	nc
		ld	de, 80h	; '�'
		ld	c, 26		; SETDM
		call	5
		ret	c
		ld	c, 21		; WRITS
		call	5
		ret	c
nbasic25:	ld	de, 80h	; '�'
		ld	b, 80h ; '�'
		xor	a
nbasic26:	ld	(de), a
		inc	de
		djnz	nbasic26
	IF ERWTYP == "BASEA"
		ld      hl, 67h
	ENDIF
		ld	(hl), a
		dec	a
; ein Leerzeichen ausgeben
nbasic27:	ld	e, ' '
		ld	c, 2
		jp	5

aVerifyAbbruch:	db "\r\n"
		db "VERIFY (Abbruch mit STOP)",0
	IF ERWTYP == "LE192K"
aFileNotOpen:	db "File not OPEN",0
aBasicTape:	db "BASIC-TAPE 1.00",0
	ELSEIF ERWTYP == "BASEA"
aFileNotOpen:	db "NO OPEN ",0
aBasicTape:	db "BASIC-TAPE",0
                db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
	ENDIF
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh
		db 0FFh

	ENDIF

;-----------------------------------------------------------------------------
; PAUSE [n]
; Die PAUSE-Anweisunmg unterbricht die Ausf�hrung eines Programmes.
; Ist ein Parameter angegeben, dann f�r n Zehntelsekunden.
;-----------------------------------------------------------------------------

PAUSE:		call	TCHAR1		;PARAM.VORH.
		jr	nz, pause3	;PARAMETER VORH.
;
pause1:		call	CSTS		;OHNE PARAMETER
		jr	nz, pause1
		; Testen Tastaturstatus, gedr�ckte Taste in A
		cp	3		; <STOP> ?
		jr	z, pause2
		cp	1Eh		; <CONT> ?
		jr	nz, pause1
		call	CI		;TASTATUREINGABE
pause2:		ret
;
pause3:		call	EPRVL1		;Argument holen
		ld	a, d
		or	e
		ret	z		;wenn = 0
;Zeitschleife
;de=Wartezeit
		push	hl
		ld	hl, 1
pause4:		ld	ix, paus_val
		ld	a, 5
pause5:		ld	c, 8Dh
pause6:		ld	b, 0Ah
pause7:		add	a, (ix+0)
		djnz	pause7
		dec	c
		jr	nz, pause6
		dec	a
		jr	nz, pause5
		and	a
		ex	de, hl
		sbc	hl, de
		ex	de, hl
		jr	z, pause11	;Zeitende erreicht
		;sonst Test auf Abbruch durch Tastendruck
		push	af
		push	bc
		push	de
		call	CSTS
		jr	nz, pause8
		cp	1Eh		; <CONT> ?
		jr	z, pause9
		cp	3		; <STOP> ?
		jr	z, pause10
pause8:		pop	de
		pop	bc
		pop	af
		jr	pause4
;
pause9:		call	CI
pause10:	pop	de
		pop	bc
		pop	af
pause11:	pop	hl
		ret

;-----------------------------------------------------------------------------
; Z9001-OS-Kommando-Rahmen
; Start von BASIC aus dem OS heraus
;-----------------------------------------------------------------------------

		org	nextpage($)

	IF ERWTYP == "BM608"
		jp	PRIST1
	ELSEIF (ERWTYP == "LE192K") || (ERWTYP == "BASEA")
		jp	nbasic
	ENDIF
aBasic:		db	"BASIC   "
paus_val:	db	0
loc_0_E40C:	jp	SECST
aWbasic:	db	"WBASIC  "
		db	0
		db	0

;-----------------------------------------------------------------------------
; INKEY$
; Ermittlung einer Tastenbet�tigung
;-----------------------------------------------------------------------------

INKEY:		push	hl		;ZEILENZEIGER RETTEN
		call	CSTS		;EINGABE?
		jr	nz, inkey2
		ld	a, 1
		call	STADTB		;VARIABLE BELEGEN
		call	CI
		ld	hl, (STRDAT+2)	;WERT EINTRAGEN
		ld	(hl), a
inkey1:		jp	SLEN3
inkey2:		xor	a
		call	STADTB		;STRING MIT LAENGE 0
		jr	inkey1

;-----------------------------------------------------------------------------
; BEEP
;-----------------------------------------------------------------------------

BEEP:		ld	c, 2		; CONSO
		ld	e, 7		; BEEP
		call	5
		ret

;-----------------------------------------------------------------------------
;STRING$ (i,j$)
; Die Funktion liefert eine Zeichenkette, die durch i-fache Wiederholung des
; Zeichenkettenausdrucks j$ entsteht. i kann Werte zwischen 0 und 255 (einschlie�lich)
; annehmen. Der Zeichenkettenausdruck, der durch die Funktion STRING$ geliefert wird,
; darf h�chstens 255 byte lang sein.
;-----------------------------------------------------------------------------

STRING:		call	CPSTX		;'('?
		db	'('
		call	param		;PARAMETER 1
		push	af
		call	string8		;PARAMETER 2 (STRING)
		push	af
		call	CPBRGT		;')'?
		pop	af
		ex	(sp), hl	;ZEILENZEIGER
		ld	b, h
		push	hl
		push	af
		push	de
		ld	c, a		;LAENGE NEUER STRING BERECHNEN
		xor	a
		cp	c
		jr	z, string2
		cp	b
		jr	z, string2
		ld	a, c
		dec	b
		jr	z, string2
string1:	add	a, c
		jr	c, string6
		djnz	string1
string2:	ld	b, a		;LAENGE IN A UND BC
		ld	c, 0
		call	STROP		;PLATZ IN STRINGPOOL RESERVIEREN
					;ADR.NEUER STRING IN DE
		pop	bc		;LAENGE NEUER STRING IN BC
		push	bc
		call	SADTB1		;EINTRAGEN IN STRDAT.
		pop	hl
		ex	(sp), hl	;ALTE LAENGE IN H
		ld	a, h
		pop	hl
		ex	(sp), hl
		ld	l, a
		inc	h
string3:	dec	h		;STRING EINTRAGEN
		push	hl
		push	bc
		jr	z, string4
		call	STRMV1		;String eintragen in Stringpool
		pop	bc
		pop	hl
		jr	string3
string4:	pop	bc
		pop	hl
		pop	de		;FERTIG ABSCHLUSS
		call	STRZS3
		jp	SLEN3
string6:	ld	e, 28
		jp	ERROO
;
string8:	call	SNALY		;PARAMETER (STRING)
		push	hl
		call	LEN1		;LAENGE UND ADRESSE PARAM
		inc	hl		;IN A UND HL
		inc	hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		pop	hl
		ret

;-----------------------------------------------------------------------------
; INSTR (x$,y$)
; Diese Anweisung liefert die Position des ersten Auftretens des
; Zeichenkettenausdruckes x$ im Zeichenkettenausdruck y$.
; Ist x$ nicht in y$ enthalten, so den Wert 0.
; Der Funktionswert ist ein numerischer Wert zwischen 0 und 255.
;-----------------------------------------------------------------------------

instr6:		inc	hl
		push	hl
		dec	hl
		dec	c
		push	bc
		inc	c
instr7:		inc	de
		dec	b
		jr	z, instr9
		inc	hl
		dec	c
		jr	z, instr8
		ld	a, (de)
		cp	(hl)
		jr	z, instr7
		pop	bc
		pop	hl
		pop	de
		jr	instr1
;
instr8:		pop	hl
		pop	hl
		jr	instr3
;
instr9:		pop	de
		pop	hl
		pop	de
		pop	de
		and	a
		sbc	hl, de
		ld	a, l
		jr	instr4

;Start
instr:		call	CPSTX		;Test '('
		db	'('
		call	string8		;PARAMETER (STRING)
		push	de
		push	af
		call	CPCOMM		;KOMMA ?
		call	string8		;PARAMETER (STRING)
		push	af
		call	CPBRGT		;Test auf rechte Klammer
		pop	af
		jr	z, instr5
		ld	c, a
		pop	af
		jr	z, at1
		ld	b, a
		ex	(sp), hl
		ex	de, hl
;
		push	hl
instr1:		push	de
		ld	a, (de)
instr2:		cp	(hl)		;erstes Zeichen gleich?
		jr	z, instr6
		inc	hl
		dec	c
		jr	nz, instr2
;
instr3:		xor	a		;nicht gefunden -> R�ckgabewert 0
		pop	hl
		pop	hl
instr4:		ld	de, SNLY16
		push	de
		jr	joyst2
;
instr5:		pop	de
		ex	(sp), hl
		jr	instr4

;-----------------------------------------------------------------------------
; JOYST [i]
; Diese Funktion dient zur Ermittlung der Spielhebelstellung
; i=1: Spielhebel1, i=2: Spielhebel2
; Der gelieferte Funktionswert ist ein numerischer Wert von 0..16
;-----------------------------------------------------------------------------

JOYST:		call	SNLY14
		push	hl
		ld	de, SNLY16
		push	de
		call	ARGVL2
		and	a		; A=Spielhebel-Nr.
		jr	z, at1		; A=0, so Fehler
		cp	3		; A<3 ?
		jr	nc, at1		; wenn nein, d.h. A>=3, so Fehler
		ld	c, 6		; GETST Joystick-Abfrage
		call	5
		jr	c, at1		; bei Fehler
		cp	1		; Spielhebel 1?
		jr	z, joyst1
		ld	c, b		; Spielhebel 2 -> R�ckgabewert in B
joyst1:		ld	a, c		; Spielhebel 1 -> R�ckgabewert in C
joyst2:		jp	POS1		; Funktionswert zur�ckgeben

;-----------------------------------------------------------------------------
;PRINT AT (Zeile,Spalte);Ausdruck ,Ausdruck ...
;Die angegebenen Ausdr�cke werden auf dem Bildschirm an der durch Zeile und Spalte
;festgelegten Position hintereinander angezeigt.
;Die Parameter Zeile (0 bis 23) und Spalte (0 bis 39) sind ganzzahlige Ausdr�cke.
;-----------------------------------------------------------------------------

AT:		ld	a, (PRTFLG)
		bit	1, a
		set	1, a		;PRINTFLAG SETZEN
		ld	(PRTFLG), a
		jr	nz, at1		;FEHLER
		call	TCHAR
		call	CPSTX		;'('?
		db	'('
		call	param		;Parameter1: Zeile
		push	af
		call	ARGVL1		;Parameter2: Spalte
		push	af
		call	CPBRGT		;')'?
;
		call	CPSTX		;';'?
		db	';'
		pop	af
		ld	c, a		;C=Spalte
		pop	af
		push	hl
		ld	b, a		;B=Zeile
		ld	a, b
		cp	24		;Zeile<24?
		jr	nc, at1		;Nein -> SN ERROR
		ld	a, c
		cp	40		;Spalte<40?
		jr	c, at2		;ja
at1:		jp	fcerr		;SN ERROR
;
at2:		ld	l, 0
		ld	h, l		;HL=0
		ld	d, l
		ld	e, 40		;L�nge Bildschirmzeile
		inc	b
		dec	b
		jr	z, at4		;wenn B=0
at3:		add	hl, de		;HL=Zeile*40
		djnz	at3
;
at4:		ld	e, c		;Spalte
		add	hl, de		;HL=Offset im BWS
		ld	de, 0EC00h
		add	hl, de
		ld	d, h
		ld	e, l		;DE=Position im BWS
		ld	bc, 0FC00h
		add	hl, bc
		ex	(sp), hl	;(SP)=Position im FarbBWS, HL=gesicherter Wert
		push	de		;original: Position im BWS
at5:		cp	IKTOK		;0D5h
		jr	c, at6
		ld	a, (EXTFLG)
		and	a
		jr	z, at6
		call	sub_0_E006
at6:		call	SNALY
		push	hl
		ld	a, (DATYPE)
		or	a
		jr	nz, at7
		call	NUMKON
		call	SLEN0
		ld	(hl), 20h
		ld	hl, (WRA1)
		inc	(hl)
at7:		call	STRZS1
		call	OPLAD
		pop	hl
		pop	ix
		pop	iy
		ld	a, (ATRIB)
		ld	d, a
		inc	e
at8:		dec	e
		jr	z, at9
		ld	a, (bc)
		call	at11
		jr	nc, at9
		ld	(ix+0), a
		ld	(iy+0), d
		inc	ix
		inc	iy
		inc	bc
		jr	at8
at9:		call	TCHAR1
		jr	nz, at10
		pop	bc
		ret
at10:		call	CPCOMM		;KOMMA?
		push	iy
		push	ix
		jr	at5
;
at11:		push	hl
		push	ix
		pop	hl
		push	de
		ld	de, 0EFC0h
		and	a
		sbc	hl, de
		pop	de
		pop	hl
		ret

;-----------------------------------------------------------------------------
; DELETE zeilennummer1 [,zeilennummer2]
; Streichen von Programmzeilen
; zeilennummer1,2 - kennzeichnet niedrigste bzw. h�chste zu streichende BASIC-Zeile
;-----------------------------------------------------------------------------

DELETE:		ret	z
		call	DCHEX
		jp	z, LIN13
		call	CPCOMM		;KOMMA?
		push	de
		call	DCHEX
		pop	hl
		ret	nz
		ex	de, hl
		push	hl
		call	ZPOIT
delete1:	jp	nc, LIN15
		pop	de
		push	af
		push	bc
		call	ZPOIT1
		jr	nc, delete1
		pop	bc
		jp	LIN6


; ERW1: extra Grafikbefehle
erw12:		ld	b, a
		push	hl
		ld	hl, (adrtab2)	; Test, ob Erweiterung installiert ist
		ld	a, 0C3h
		cp	(hl)		; dann mu� im Speicher ein JP stehen
		ld	a, b
		pop	hl		; ok? dann ausf�hren
		ret	z
		jp	snerr		; sonst Fehler

;		db	0FFh

;-----------------------------------------------------------------------------
; IO-Schnittstelle
; Das zu �bertragende Zeichen steht entweder in den Registern A
; und D oder wird in diesen erwartet, Die Kanalinformation steht
; in Register E:
;
;  bit0            0    - Eingabekanal
;                  1    - Ausgabekanal
;     1 \          00   - Konsolenkanal
;     2 /          01   - Magnetbandkassette
;                  10   - Drucker
;                  11   - frei
;     3                   Initialisierungsbit
;     4            0    - E/A im ASCII-Code
;                  1    - E/A im internen Code
;     5            1    - R�cksprung zum Steuerprogramm
;     6                   Endebit
;     7                   immediate-return-bit
;
;-----------------------------------------------------------------------------

		org	nextpage($)
	IF ERWTYP == "BM608"

VERTEI:		bit	5, e		; BYE ?
		jp	nz, 0		; dann Systemneustart
		ld	(M0077), hl
		push	hl		; HL sichern
		push	bc
		ld	hl, vertei1	; R�ckehradresse kellern
		push	hl
		ld	a, e
		and	7
		rla
		ld	c, a
		ld	b, 0
		ld	hl, vertab
		add	hl, bc
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		jp	(hl)		; Start der IO-Routine
;
vertei1:	pop	bc
		pop	hl		; HL restaurieren
		ret			; und zur�ck zum BASIC

aVerifyYN:	db	0Ah
		db	0Dh
		db	"Verify ((Y)/N)?:"
		db	0
aRewind:	db	0Ah
		db	"Rewind <=="
		db	0Ah
		db	0Dh
		db	0

vertab:		dw	rcons		;Kanal#0: Console
		dw	conso
		dw	rtape		;Kanal#1: Tape
		dw	wtape
		dw	IOERR		;Kanal#2: Drucker
		dw	listo
		dw	IOERR		;Kanal#3: frei
		dw	IOERR

;-----------------------------------------------------------------------------
; read console
;-----------------------------------------------------------------------------

rcons:		bit	7, e		; nur Status-Abfrage?
		jr	z, rcons1
		ld	c, 11		; CSTS: Abfrage Status CONST
		call	5
		or	a
		jr	z, rcons2	; wenn nix eingegeben wurde
		res	7, e
		jr	rcons2

prnst:		ld	c, 9		; PRNST: Ausgabe einer Zeichenkette zu CONST
		call	5

rcons1:		ld	c, 1		; CONSI: Eingabe eines Zeichens von CONST
		call	5
rcons2:		ld	d, a
		ret

;-----------------------------------------------------------------------------
; list output
;-----------------------------------------------------------------------------

listo:		ld	c, 5		; LISTO: Ausgabe eines Zeichens zu LIST
		jr	conso1

;-----------------------------------------------------------------------------
; console output
;-----------------------------------------------------------------------------

conso:		ld	c, 2		; CONSO: Ausgabe eines Zeichens zu CONST
conso1:		push	de
		ld	e, d		; auzugebendes Zeichen
		call	5
		pop	de
		res	7, e
		ret

;---

outlf:		ld	d, 10		; Ausgabe 0Ah
		jr	conso

outcr:		ld	d, 13		; Ausgabe 0Dh
		jr	conso

;-----------------------------------------------------------------------------
; write tape
;-----------------------------------------------------------------------------

;BASIC-Kopf:
; 3 Byte Dateityp (D3, D4, D5 bzw. D7, D8, D9)
; 8 Byte Dateiname, wenn k�rzer, dann mu� mind. 1 Leerzeichen folgen
; 2 Byte Adresse1
; 2 Byte Adresse2

wtape:		push	de
		bit	3, e		; init?
		jr	z, wtape1	; nein, also Byte in Buffer schreiben
;Initialisierung
		push	de
		ld	c, 15		; OPENW: Er�ffnen Kassette schreiben
		call	5		; (sinnlosen !!!) Block 0 schreiben
		ld	d, ' '
		call	conso
		ld	bc, 0Bh		; 3 Byte Dateityp + 8 Byte Dateiname
		ld	hl, (M0077)
		inc	hl
		inc	hl
		ld	a, (hl)
		ld	(M0075), a	; Modus sichern (D3..D5)
		ld	de, CONBU	; Dateityp + Dateiname nach STDMA-Buffer kopieren
		ldir
		pop	de
		ld	hl, M006E	; Position im Buffer
		ld	(hl), 0Bh
;n�chstes Zeichen schreiben
wtape1:		ld	hl, CONBU
		ld	a, (M006E)	; Position im Buffer
		ld	c, a
		ld	b, 0
		add	hl, bc
		ld	(hl), d
		inc	a
		ld	(M006E), a
		bit	6, e		; Ende?
		jr	nz, wtape2	; Sprung wenn Endebit gesetzt
		ld	a, (M006E)
		cp	80h		; oder Buffer voll?
		jp	nz, rtape3	; sonst raus hier

wtape2:		ld	a, (M0075)
		cp	0D5h		; Modus LIST ?
		jr	nz, wtape5
;LIST: Parallele Ausgabe auf Console
		ld	hl, CONBU
		ld	a, (M006E)
		ld	b, a
wtape3:		ld	d, (hl)
		call	conso
		inc	hl
		djnz	wtape3
;
		ld	hl, 0
wtape4:		ld	b, 0
		ld	c, 1
		and	a
		sbc	hl, bc
		jr	nz, wtape4
; Block auf Kassette schreiben
wtape5:		ld	hl, CONBU
		ld	(DMA), hl	; DMA setzen
		ld	c, 21		; WRITS: Schreiben eines Blockes auf Kassette
		call	5
		xor	a
		ld	(M006E), a	; Position im Buffer zur�cksetzen
		ld	d, ' '
		call	conso
		bit	6, e		; Ende?
		jr	z, rtape2	; Sprung wenn Endebit gesetzt
		xor	a
		ld	(M005Ah), a	; ????
;Verify
		ld	de, aVerifyYN	; "\n\rVerify ((Y)/N)?:"
		call	prnst
		call	conso
		call	outlf
		call	outcr
		cp	'N'
		jr	z, rtape3	; Sprung, wenn kein Verify gew�nscht ist
		ld	de, aRewind	; "\nRewind <==\n\r"
		call	prnst
		call	outlf
		call	outcr
		ld	a, (BLNR)
		ld	b, a
		xor	a
		ld	(LBLNR), a
wtape6:		push	bc
		call	rtape4
		pop	bc
		djnz	wtape6		; bis alle Bl�cke gelesen
		jr	rtape3

;-----------------------------------------------------------------------------
; read from tape
;-----------------------------------------------------------------------------

rtape:		push	de
		bit	6, e		; Ende?
		jr	nz, rtape3	; dann abbrechen
		bit	3, e		; Init?
		jr	z, rtape1	; nein, Daten einlesen
; Init
		call	outlf
		ld	a, 1
		ld	(LBLNR), a
		call	rtape4
		call	thead
		pop	de
		ld	hl, CONBU+0Bh	; Offs. 3 Byte Dateityp + 8 Byte Dateiname
		ld	d, (hl)		; 1. Zeichen
		push	de
		ld	hl, M006E	; Position im Buffer
		ld	(hl), 0Ch	; mit 0Ch initialisieren (nach Dateityp+Dateiname)
		jr	rtape2
; Daten einlesen
rtape1:		ld	hl, CONBU
		ld	a, (M006E)	; Position im Buffer
		ld	c, a
		ld	b, 0
		add	hl, bc
		pop	de
		ld	d, (hl)		; n�chstes Zeichen holen
		push	de
		inc	a
		ld	(M006E), a	; Position im Buffer
		cp	80h		; Bufferende?
		jr	nz, rtape3	; nein, dann mit Zeichen zur�ck zu BASIC
		call	rtape4
		xor	a
		ld	(M006E), a
;
rtape2:		ld	c, 11		; CSTS: Abfrage Status CONST
		call	5
		cp	3		; <STOP>-Taste gedr�ckt?
		jr	z, rtape6	; ja -> Abbruch
;
rtape3:		pop	de
		res	7, e
		res	3, e
		ret
; Block einlesen
rtape4:		ld	hl, CONBU
		ld	(DMA), hl
		ld	c, 20		; READS: Lesen eines Blockes von Kassette
		call	5
		ret	nc
;Lesefehler
rtape5:		call	rcons1
		cp	0Dh		; <ENTER>-Taste gedr�ckt?
		jr	z, rtape4
		cp	3		; <STOP>-Taste gedr�ckt?
		jr	nz, rtape5
;
rtape6:		jp	IOERR
;

; Programmnamen anzeigen
thead:		ld	hl, CONBU
		ld	b, 0Bh		; 3 Byte Dateityp + 8 Byte Dateiname
thead1:		ld	d, (hl)
		call	conso		; anzeigen
		inc	hl
		djnz	thead1
;Programmnamen vergleichen
		ld	hl, (M0077)	; Vergleich mit zu lesendem Dateinamen

		ld	c, 0Ch		; vergleiche r�ckw�rts
		add	hl, bc
		ld	b, 0Bh		; 3 Byte Dateityp + 8 Byte Dateiname
		ld	de, CONBU+0Ah
thead2:		ld	a, (de)
		cp	(hl)
		dec	de
		jr	nz, thead4	; wenn ungleich
thead3:		dec	hl
		djnz	thead2
		ret
;
thead4:		sub	4		; Test auf gesetzte Copybit
		cp	(hl)		; wenn dann immer noch ungleich, so
		jr	nz, rtape6	; Datei nicht gefunden
		ld	a, 0FFh		; sonst DATFLG setzen
		ld	(DATFLG), a
		jr	thead3		; und weiter vergleichen

		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh
		;db	0FFh

	ELSEIF (ERWTYP == "LE192K") || (ERWTYP == "BASEA")

vertei:		bit	5, e
		jp	nz, 0
		push	hl
		push	bc
		ld	bc, vertei3
		push	bc
		ld	a, e
		and	1Eh
		xor	1Ah
		jr	nz, vertei2
		push	de
		ld	de, aCasJN	; "CAS: (J)/N "
		ld	c, 9		; PRNST
		call	5
		pop	de
		ret	c
		ld	c, 1		; CONSI
		call	5
		ret	c
		cp	3		; 'STOP'?
		scf
		ret	z
		cp	'N'
		ld	a, 'J'
		jr	nz, vertei1
		ld	a, 'N'
		set	2, e
vertei1:	push	de
		ld	e, a
		ld	c, 2		; CONSO
		call	5
		pop	de
		ret	c
vertei2:	push	hl
		ld	a, e
		and	7
		rla
		ld	c, a
		ld	b, 0
		ld	hl, vertab
		add	hl, bc
		pop	bc
		inc	bc
		inc	bc
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		jp	(hl)

vertei3:	ld	d, a
		pop	bc
		pop	hl
		jp	c, IOERR
		ret

aCasJN:		db "CAS: (J)/N ",0
vertab:		dw rcons
		dw conso
		dw rtape
		dw wtape
		dw rcons
		dw rcons
		dw rcons
		dw rcons
unk_E671:	db    0			; Eingabe Konsole := CONST
		db    0			; Ausgabe Konsole := CONST
		db    2			; Eingabe Magnetbandkassette :=	READER
		db    4			; Ausgabe Magnetbandkassette :=	PUNCH
		db    2			; Eingabe Drucker := READER
		db    6			; Ausgabe Drucker := LIST
		db    2			; Eingabe frei := READER
		db    4			; Ausgabe frei := PUNCH

rcons:		push	hl
		push	bc
		bit	3, e		; Intitialisierung?
		jr	z, rcons4
		bit	1, e		; Konsole/Drucker (0) oder Kassette (1)
		jr	z, rcons4
		ld	hl, 3		; 3 Zeichen Offset (D3D3D3 o.a.	Kennung)
		add	hl, bc
		ld	b, 8		; max. L�nge Dateiname
		push	de
		ld	de, 005Ch	; FCB
		ex	de, hl
; In FCB Leerzeichen zu	00-Bytes �ndern
rcons1:		ld	a, (de)
		cp	20h ; ' '
		jr	nz, rcons2
		xor	a		; A:=0
rcons2:		ld	(hl), a
		inc	de
		inc	hl
		djnz	rcons1
;
		pop	de
		bit	4, e		; E/A-Modus intern (1) oder ASCII (0)
		jr	z, rcons3
		ld	(hl), 'B'       ; Standard-Endung "BAS"
		inc	hl
		ld	(hl), 'A'
		inc	hl
		ld	(hl), 'S'
		jr	rcons4

rcons3:		ld	(hl), 'T'       ; im ASCII-Modus Endung "TXT"
		inc	hl
		ld	(hl), 'X'
		inc	hl
		ld	(hl), 'T'

rcons4:		ld	a, e
		and	10011011b
		xor	3		; Bit 0	und 1 togglen
		jr	nz, rcons6
		ld	a, (340h)
		cp	1
		jr	z, rcons6
		push	de
		ld	e, 1
		call	rcons
		pop	de
		ret	c
		ld	hl, 0FFFFh

rcons5:		ld	bc, 0064h
		sbc	hl, bc
		jr	nc, rcons5

; Auswahl logisches Ger�t
rcons6:		ld	a, e
		and	7
		ld	c, a
		ld	b, 0
		ld	hl, unk_E671
		add	hl, bc
		ld	b, (hl)		; B := logische	Ger�tenummer (intern)
		ld	c, d
		and	1		; Ein-Ausgabe-Bit
		inc	a
		bit	3, e		; Initialisierungsbit
		jr	z, rcons7
		add	a, 10h
		jr	rcons11

rcons7:		bit	7, e		; immediate-return-bit
		jr	z, rcons8
		xor	a		; A := 0
		jr	rcons11

rcons8:		bit	6, e		; Endebit
		jr	z, rcons11
		bit	0, e		; Eingabekanal/Ausgabekanal-Bit
		jr	z, rcons9
		bit	1, e		; Konsole/Drucker oder Magnetbandkassette
		jr	z, rcons9
		bit	5, e		; R�cksprung zum Steuerprogramm-Bit
		jr	z, rcons10
		res	5, e

rcons9:		add	a, 12h
		jr	rcons11

rcons10:	set	5, e
rcons11:	push	de
		ld	hl, rcons12
		push	hl
		ld	hl, (0F007h)	; Adresse Routine CONST	im Sprungverteiler (Konsolenstatus)
		inc	hl
		inc	hl
		inc	hl
		inc	hl
		jp	(hl)		; das sollte CONS2 sein	(F75Ah)

rcons12:	ld	a, c
		pop	de
		pop	bc
		pop	hl
		ret	c
		bit	3, e		; Initialisierungsbit
		jr	z, rcons14
		res	3, e
rcons13:	jp	rcons

rcons14:	bit	7, e		; immediate-return-bit
		jr	z, rcons15
		or	a
		ret	z
		res	7, e
		ret

rcons15:	bit	5, e		; R�cksprung zum Steuerprogramm-Bit
		jr	nz, rcons13
		ret

conso:		push	de
		ld	c, d
		call	0F00Ch		; CONSO: Ausgabe Zeichen zu CONST
		pop	de
		ret

rtape:		bit	3, e		; Initialisierungsbit
		jr	z, rtape5
		push	bc
		push	de
		call	0F593h		; REQU:	Ausgabe	Startmeldung, warten auf ENTER
	IF ERWTYP == "LE192K"
		ld	a, i
		ld	h, a
		ld	l, 7Ch ; '|'
		ld	(hl), 5
		inc	hl
		ld	(hl), 80h ; '�'
		ld	hl, 100h
		ld	(6Bh), hl
	ENDIF
		pop	de
		pop	hl
		ret	c
	IF ERWTYP == "BASEA"
		ld      a, 80h ; '�'
		ld      (67h), a
		xor     a
		ld      (6Bh), a
		inc     a
		ld      (68h), a
		ld      (6Ch), a
	ENDIF
		res	3, e
		ld	bc, 0B00h
rtape1:		call	rcons
		ret	c
		ld	d, a
		push	de
		ld	e, 1
		call	rcons
		pop	de
		ret	c
		ld	a, d
		cp	(hl)
		jr	z, rtape4
		dec	b
		bit	3, b
		jr	z, rtape2
		sub	4
		cp	(hl)
		jr	nz, rtape2
		set	7, c
		jr	rtape3

rtape2:		inc	c
rtape3:		inc	b
rtape4:		inc	hl
		djnz	rtape1
		ld	a, c
		and	7Fh ; ''
		scf
		ret	nz
		bit	7, c
		jr	z, rtape5
		dec	a
		ld	(DATFLG), a
rtape5:		jp	rcons

wtape:		bit	3, e
		jr	z, wtape2
		ld	l, c
		ld	h, b
		call	wtape4
		ret	c
		ld	b, 0Ah
wtape1:		call	wtape4
		ret	c
		djnz	wtape1
		jr	rtape5

wtape2:		bit	6, e
		jr	z, rtape5
		ld	a, (308h)
		ld	e, a
		ld	b, 80h ; '�'
wtape3:		call	rcons
		ret	c
		ld	d, 0
		djnz	wtape3
		set	6, e
		jr	rtape5

wtape4:		push	de
		ld	d, (hl)
		inc	hl
		call	rcons
		ld	a, e
		pop	de
		ld	e, a
		ret

;????
		ld	a, 32h ; '2'
		call	0DE6Bh
		call	LEN1
		jr	z, marke7
		ld	b, a
		ld	c, a
		inc	hl
		inc	hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ld	hl, 309h
marke5:		set	7, (hl)
		call	CI
		jr	nz, marke6
		call	CI
		ld	(de), a
		inc	de
		djnz	marke5
marke6:		ld	a, c
		sub	b
marke7:		jp	POS1

	ENDIF

		org	0E7E6H

window4:	ld	(3Dh), de	;E=P3ROL (1. ZU ROLLENDE SPALTE-1)
					;D=P4ROL (LETZTE ZU ROLLENDE SPALTE+1)
		ld	(3Bh), bc	;C=P1ROL (1. ZU ROLLENDE ZEILE-1)
					;B=P2ROL (LETZTE ZU ROLLENDE ZEILE+1)
		ld	d, c		;Cursor auf Fensteranfang
		inc	d
		inc	e
		ld	c, 18		; SETCU
		call	5
		ret

param:		call	ARGVL1	;ARGVL1
		push	af
		call	CPCOMM	;CPCOMM
		pop	af
		ret

;		db	(($+0ffh)/100h)*100h-$ dup (0FFh)	; mit FF auff�llen

		end
