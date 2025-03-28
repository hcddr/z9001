;------------------------------------------------------------------------------
; 2K-BASIC-Erweiterung
; reass + Dok V. Pohlers 2003 ff.
;------------------------------------------------------------------------------
; File Name   :	m112.rom / bm608.rom
; Format      :	Binary File
; Base Address:	0000h Range: E000h - E800h Loaded length: 0800h
;------------------------------------------------------------------------------
;Versionen
;m112.rom / bm608.rom = Original
;p_printat	equ	0
;p_80z		equ	0
;p_farb16	equ	0
;p_wtape	equ	0


;bm608p V.Pohlers 13.12.2009 Anpassung f. CRT80
;p_printat	equ	1
;p_80z		equ	1
;p_farb16	equ	0
;p_wtape	equ	0
;p_disk		equ	0


; basic_16d.rom 16.02.2012
; = p_80z, p_disk, p_farb16

; basic_16dp.rom 16.02.2012 + Patch OS-Namen BASICP, WBASICP
; = p_printat, p_80z, p_disk, p_farb16

;20.05.2013 TODO eigentlich müsste bei p_printat auch das Window auf vollen Bildschirm gesetzt werden
; die jetzige Lösung sieht bei R+INFO aber wenig brauchbar aus (wg. Bildscrollen)

;23.11.2017 (FCB+24) := 'N', damit wird bei Disk/USB-kein Block 0 geschrieben/gelesen

;30.10.2018 p_zbs Dateiendung '.ZBS' analog CPM-Version statt '.SSS', '.TTT'

;26.12.2019 DIR+CD per CALL 5-Erweiterung
;------------------------------------------------------------------------------

;;; Patches
;;;V. Pohlers 13.12.2009
;;p_printat	equ	1	;PRINT AT über CALL 5 statt direktem Schreiben in den BWS
;;p_printatw	equ	0	;Window auf vollen Bildschrim setzen
;;
;;;V. Pohlers 14.12.2009
;;p_80z		equ	1	;Änderung WINDOW f. max. 80 Zeichen/Zeile f. CRT80
;;;V. Pohlers 13.02.2012
;;p_disk		equ	1	;Änderung CALL 5 Block 0, damit ein sinnvoller Block 0 geschrieben wird
;;				;(wichtig für Diskettenarbeit)
;;;V. Pohlers 30.10.2018				
;;p_zbs		equ	1	;Dateiendung '.ZBS' (analog CPM-Version) oder '.SSS', '.TTT'
;;				;(wichtig für Diskettenarbeit)
;;
;;;U.Zander
;;p_farb16	equ	1	;INK, PAPER f. 16 Farben zulassen
;;p_wtape		equ	0	;Patch auf BIOS-Routinen statt CALL 5, verhindert Block 0
;;				;nicht nutzbar bei p_disk=1



;;		cpu	z80

;Z9001-OS
DMA		equ	001BH 	;Zeiger auf Puffer für Kassetten-E/A
ATRIB		EQU	0027H	;aktuelles Farbattribut
M005A		equ	005Ah	;??? wird in wtape5 auf 0 gesetzt
BLNR		equ	006Bh	;Blocknummer
LBLNR		equ	006Ch	;gesuchte Blocknummer bei Lesen
M006E		equ	006Eh	;Position im Buffer
M0075		equ	0075h	;Modus beim Speichern/Lesen (D3..D5)
M0077		equ	0077h	;Merkzelle HL (für tape)
CONBU		equ	0080h	;Standardpuffer für Kassetten-E/A
INTLN: 		equ	0100h	;interner Zeichenkettenpuffer

port88		equ	088h	;Farbattribut
portB8		equ	0B8h	;Pixelgrafik

		if p_wtape
MF46F		equ	0F46Fh	;WRITE (Blockschreiben Sequentiell)
MF472		equ	0F472h	;WRIT1
MF593		equ	0F593h	;REQU (Startmeldung)
		endif

;ADRESSEN UND DATEN AUS BASIC KERN
;;GTOTOK		equ	88h
;;RSTTOK		equ	8Bh
;;GSBTOK		equ	8Ch
;;THNTOK		equ	0A9h
;;SGNTOK		EQU	0B6H
;;LODTOK		EQU	0D0H
;;ELSTOK		equ	0D4h

extgraf		equ	0A7D6H

		shared	snerr
		shared	fcerr

;;		include	basic_8k_kern.inc

; wesentliche Funktionen des Interpreterkernes:
;       ARGVL1          numerischen Parameter übernehmen
;       SNALY           String-Parameter übernehmen
;       LEN1            Länge und Adresse String-Parameter bestimmen
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
;
;-----------------------------------------------------------------------------

		IF	ROMTYP	== "ROM"
		db	0FFh
		db	0FFh
		db	0FFh
		ENDIF

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
		db	'R'+80h, "ENUM"
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
	ifdef dirkdo	
		db	'D'+80h,"IR"	; DIR vp 
DirTok		equ	0F3h
		db	'C'+80h,"D"	; CD vp 
CdTok		equ	0F4h
	endif
		db	80h

; Funktionen
adrtbe:		dw	inkey
		dw	joyst
		dw	string
		dw	instr

; Prozeduren
adrtab1:	dw	renum
		dw	delete
		dw	pause
		dw	beep
		dw	window
		dw	border
		dw	ink
		dw	paper
		dw	at

; Sprungveteiler Grafikerweiterung
adrtab2:	dw	extgraf		;PSET
		dw	extgraf+3	;LINE
		dw	extgraf+6	;CIRCLE
		dw	REM   		;!
		dw	extgraf+9	;PAINT
		dw	extgraf+12	;LABEL
		dw	extgraf+15	;SIZE
		dw	extgraf+18	;ZERO
		dw	extgraf+21	;HOME
		dw	REM   		;!
		dw	extgraf+24	;GCLS
		dw	extgraf+27	;SCALE
		dw	extgraf+30	;SCREEN
		dw	extgraf+33	;POINT
		dw	extgraf+36	;XPOS
		dw	REM   		;!
		dw	extgraf+39	;YPOS
;
	ifdef dirkdo	
		dw	DIR
		dw	CD
	endif
		
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
	ifdef dirkdo
		cp	DirTok-RETOK	;; DIR
		jr	nc, ERW11
	endif
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

;snerr		equ	0E144H
;fcerr		equ	0E14BH

snerr:		if p_80z
		ld	a, 0		;KRT-Grafik; 0 geht auch bei Robotron-Grafik
		else
		ld	a, 0E2h		;orig. Robotron-Grafik, RAND+hellblau auf grün+AUS
		endif
		out	(portB8), a	;Pixelgrafik abschalten
		jp	SNER

fcerr:		if p_80z
		ld	a, 0		;KRT-Grafik
		else
		ld	a, 0E2h
		endif
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
		sub	IKTOK-SGNTOK+IKTOK-SGNTOK
		jr	c, snerr
		cp	ISTOK-IKTOK+ISTOK-IKTOK+1
		jp	c, erw31
		call	erw12
		cp	32h
		jr	c, snerr
		cp	3Bh
		jr	nc, snerr
;


;-----------------------------------------------------------------------------
; BORDER i
; legt die Bildschirmrandfarbe fest.
; i =  1 schwarz ..  8 weiß
;-----------------------------------------------------------------------------

border:		ld	a, 1
		jr	paper0

;-----------------------------------------------------------------------------
; INK i
; legt die Vordergrundfarbe für alle nachfolgenden auszugebenden Zeichen fest.
; i =  1 schwarz ..  8 weiß
;-----------------------------------------------------------------------------

ink:		db	0F6h ; mit nachfolgendem Befehl: OR 0AFH

;-----------------------------------------------------------------------------
; PAPER i
; legt die Hintergrundfarbe für alle nachfolgenden auszugebenden Zeichen fest.
; i =  1 schwarz ..  8 weiß
;-----------------------------------------------------------------------------

paper:		xor	a

paper0:		push	af
		call	ARGVL1		;PARAMETER ERF.
		cp	1		;1..8?
		jr	c, window2
		if p_farb16
		cp	17
		else
		cp	9
		endif
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
		if p_farb16
		and	0Fh		;sonst INK
		else
		and	7		;sonst INK
		endif
paper2:		or	b
		ld	(ATRIB), a	;Farbattribut setzen
		ld	(ATRIB+1), a	;???
		ret
paper3:		if p_farb16
		and	0F0h
		else
		and	70h
		endif
		jr	paper2
;
paper4:		ld	a, c
		ifdef p_farb16p
		jp	paper16
		else
		out	(port88), a	;Farbe setzen
		ret
		endif

;-----------------------------------------------------------------------------
; WINDOW erste_zeile, letzte_zeile, erste_spalte, letzte_spalte
; WINDOW ist gleich WINDOW 0,23,0,39
;-----------------------------------------------------------------------------

WINDOW:		ld	c, 29		; DCU - Cursor löschen
		call	5
		call	TCHAR1		;Pointer auf nächstes signifikantes Zeichen
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
		if p_80z
		cp	82		;letzte_spalte+2 < 82 ? wg CRT80
		else
		cp	42		;letzte_spalte+2 < 42 ?
		endif
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
;;13.02.2012 window auf 40 Spalten-Treiber geht bei 51h leider in die Hose. Also Default lassen
;;		if p_80z
;;		ld	de, 5100h	;Spalten 1 - 80
;;		else
		ld	de, 2900h	;Spalten 1 - 28h=40
;;		endif
window1:	jp	window4
;
window2:	jp	fcerr

;-----------------------------------------------------------------------------
; RENUM [zlnralt1 [,zlnralt2 [,zlnrneu1 [,schrittweite]]]]
; Neunumerieren von Programmzeilen
; zlnralt1,2 - kennzeichnet niedrigste bzw. höchste alte Zeilennummer
; des neu zu numerierenden Programmabschnittes
; Standardwerte: zlnralt1: niedrigste vorhandene Zeilennummer
; zlnralt2 - höchste vorhandene Zeilennummer
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

;-----------------------------------------------------------------------------
; PAUSE [n]
; Die PAUSE-Anweisunmg unterbricht die Ausführung eines Programmes.
; Ist ein Parameter angegeben, dann für n Zehntelsekunden.
;-----------------------------------------------------------------------------

PAUSE:		call	TCHAR1		;PARAM.VORH.
		jr	nz, pause3	;PARAMETER VORH.
;
pause1:		call	CSTS		;OHNE PARAMETER
		jr	nz, pause1
		; Testen Tastaturstatus, gedrückte Taste in A
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

		jp	PRIST1
aBasic:		db	"BASIC   "
paus_val:	db	0
loc_0_E40C:	jp	SECST
aWbasic:	db	"WBASIC  "
		db	0
		db	0

;-----------------------------------------------------------------------------
; INKEY$
; Ermittlung einer Tastenbetätigung
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
; Zeichenkettenausdrucks j$ entsteht. i kann Werte zwischen 0 und 255 (einschließlich)
; annehmen. Der Zeichenkettenausdruck, der durch die Funktion STRING$ geliefert wird,
; darf höchstens 255 byte lang sein.
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
instr3:		xor	a		;nicht gefunden -> Rückgabewert 0
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
		ld	c, b		; Spielhebel 2 -> Rückgabewert in B
joyst1:		ld	a, c		; Spielhebel 1 -> Rückgabewert in C
joyst2:		jp	POS1		; Funktionswert zurückgeben

;-----------------------------------------------------------------------------
;PRINT AT (Zeile,Spalte);Ausdruck ,Ausdruck ...
;Die angegebenen Ausdrücke werden auf dem Bildschirm an der durch Zeile und Spalte
;festgelegten Position hintereinander angezeigt.
;Die Parameter Zeile (0 bis 23) und Spalte (0 bis 39) sind ganzzahlige Ausdrücke.
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
	
		if p_printat = 0

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
		ld	e, 40		;Länge Bildschirmzeile
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
		pop	bc		;????
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

		else	; p_printat = 1  neu über BDOS-CALL 5, VP091231

		ld	b, a		;B=Zeile
		ld	a, b
		cp	24		;Zeile<24?
		jr	nc, at1		;Nein -> SN ERROR
		ld	a, c
		if p_80z
		cp	80		;Spalte<80?
		else
		cp	40		;Spalte<40?
		endif
		jr	c, at2		;ja
at1:		jp	fcerr		;SN ERROR
;Cursor merken
at2:		push	bc		;Position
		ld	c,17		;GETCU
		call	5
		ld	(M0077), de	;aktuelle Cursoradresse sichern
		
		ld	a,(ATRIB)	;aktuelles Attribut sichern
		ld	(M0077+2),a
		
;;		;vp20.05.2013
		if p_printatw
		call	at_win
		endif
		
;Cursor setzen
		pop	de
		inc	d
		inc	e
		ld	c,18		;SETCU
		call	5		
;
at5:		cp	IKTOK		;0D5h
		jr	c, at6
		ld	a, (EXTFLG)
		and	a
		jr	z, at6
		call	sub_0_E006	;erw2
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

		;BC=TextAdresse; e=Textlänge	
		ld	h,b
		ld	l,c
		ld	d,e
;
at8:		ld	a,(hl)		;Zeichen
		ld	e,a		
		ld	c,2		;CONSO
		call	5
		inc	hl
		dec	d
		jr	nz, at8

		pop	hl

at9:		call	TCHAR1
		jr	nz, at10

		if p_printatw
		;vp20.05.2013
		ld	bc,(M0077+3)	; Window restaurieren
		ld	(3BH),bc
		ld	bc,(M0077+5)
		ld	(3DH),bc
		endif
		
		ld	de,(M0077)
		ld	c,18		;SETCU
		call	5
		ld	a,(M0077+2)	;aktuelles Attribut
		ld	(ATRIB),a
		
		pop	bc		;????
		ret

at10:		call	CPCOMM		;KOMMA?
		jr	at5

		endif	; p_printat

;-----------------------------------------------------------------------------
; DELETE zeilennummer1 [,zeilennummer2]
; Streichen von Programmzeilen
; zeilennummer1,2 - kennzeichnet niedrigste bzw. höchste zu streichende BASIC-Zeile
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
		cp	(hl)		; dann muß im Speicher ein JP stehen
		ld	a, b
		pop	hl		; ok? dann ausführen
		ret	z
		jp	snerr		; sonst Fehler

;		db	0FFh

;-----------------------------------------------------------------------------
; IO-Schnittstelle
; Das zu übertragende Zeichen steht entweder in den Registern A
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
;     5            1    - Rücksprung zum Steuerprogramm
;     6                   Endebit
;     7                   immediate-return-bit
;
;-----------------------------------------------------------------------------

		org	nextpage($)


VERTEI:		bit	5, e		; BYE ?
		jp	nz, 0		; dann Systemneustart
		ld	(M0077), hl
		push	hl		; HL sichern
		push	bc
		ld	hl, vertei1	; Rückehradresse kellern
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
		ret			; und zurück zum BASIC

		if p_wtape
aVerifyYN:	db	0Ah
		db	0Dh
		db	"VERIFY (Y/(N))?:"
		db	0
aRewind:	db	0Ah
		db	"REWIND <=="
		db	0Ah
		db	0Dh
		db	0
		elseif p_disk
		; kein Verify
		else
aVerifyYN:	db	0Ah
		db	0Dh
		db	"Verify ((Y)/N)?:"
		db	0
aRewind:	db	0Ah
		db	"Rewind <=="
		db	0Ah
		db	0Dh
		db	0
		endif

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
; 8 Byte Dateiname, wenn kürzer, dann muß mind. 1 Leerzeichen folgen
; 2 Byte Adresse1
; 2 Byte Adresse2

	if p_disk
prepfcb:	ld	hl, (M0077)
		inc	hl
		inc	hl
		;
	ifdef p_zbs
		push	hl		; Adr. 3xTyp+Name
		ld	de,0064h	;FCB/FTYP
		ex 	de,hl
		ld	(hl),'Z'
		inc	de
		inc	hl
		ld	(hl),'B'
		inc	de
		inc	hl
		ld	(hl),'S'
		inc	de
		inc	hl
		ex	de,hl		
	else
		push	hl		; Adr. 3xTyp+Name
		ld	a,(hl)
		and	7fh		;strip high bit
		ld	de,0064h	;FCB/FTYP
		ex 	de,hl
		ld	(hl),a		;copy type (3x)
		inc	de
		inc	hl
		ld	(hl),a
		inc	de
		inc	hl
		ld	(hl),a
		inc	de
		inc	hl
		ex	de,hl		
	endif		
		ld	de,005Ch	;FCB/FNAME
		ld	bc,8		; Name kopieren
		ldir
		pop	hl
		;23.11.2017
		ld	a,'N'		; "special flag" := 'N'
		ld	(005Ch+24),a	; bei USB/Disk-kein Block 0
		ret
	endif	

wtape:		push	de
		bit	3, e		; init?
		jr	z, wtape1	; nein, also Byte in Buffer schreiben
;Initialisierung
		push	de

		if p_disk
		call	prepfcb
		ld	c, 15		; OPENW: Eröffnen Kassette schreiben
		call	5		; (sinnvollen) Block 0 schreiben
		ld	d, ' '
		call	conso
		;
		ld	bc, 0Bh		; 3 Byte Dateityp + 8 Byte Dateiname

		elseif p_wtape
		call	MF593		;REQU (Startmeldung)
		ld	a,1
		ld	(BLNR), a	;Blocknr.
		nop
		nop
		ld	bc, 0Bh		; 3 Byte Dateityp + 8 Byte Dateiname
		ld	hl, (M0077)
		inc	hl
		inc	hl

		else ; normal
		ld	c, 15		; OPENW: Eröffnen Kassette schreiben
		call	5		; (sinnlosen !!!) Block 0 schreiben
		ld	d, ' '
		call	conso
		ld	bc, 0Bh		; 3 Byte Dateityp + 8 Byte Dateiname
		ld	hl, (M0077)
		inc	hl
		inc	hl

		endif		
		ld	a, (hl)
		ld	(M0075), a	; Modus sichern (D3..D5)
		ld	de, CONBU	; Dateityp + Dateiname nach STDMA-Buffer kopieren
		ldir
		pop	de
		ld	hl, M006E	; Position im Buffer
		ld	(hl), 0Bh
;nächstes Zeichen schreiben
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
		if p_wtape
		push	de
		call	wtape10		; Patch
		pop	de
		else
		if p_disk
		bit	6, e		; Ende?
		ld	c, 16		; CLOSW
		jr	nz, wtape5e	; Sprung wenn Endebit gesetzt
		ld	c, 21		; WRITS: Schreiben eines Blockes auf Kassette
wtape5e		call	5
		else
		ld	c, 21		; WRITS: Schreiben eines Blockes auf Kassette
		call	5
		endif
		endif
		xor	a
		ld	(M006E), a	; Position im Buffer zurücksetzen
		ld	d, ' '
		call	conso
		bit	6, e		; Ende?
		jr	z, rtape2	; Sprung wenn Endebit gesetzt
	if ~~ p_disk		; wir brauchen Platz - Verify entfällt
		xor	a
		ld	(M005A), a	; ????
;Verify
		ld	de, aVerifyYN	; "\n\rVerify ((Y)/N)?:"
		call	prnst
		call	conso
		call	outlf
		call	outcr
		if p_wtape
		cp	'Y'
		jr	nz, rtape3	; Sprung, wenn kein Verify gewünscht ist
		else
		cp	'N'
		jr	z, rtape3	; Sprung, wenn kein Verify gewünscht ist
		endif
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
		djnz	wtape6		; bis alle Blöcke gelesen
	endif
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
	if p_disk
		ld	a,(0007h)	;jp BDOS
		cp	0F0h		;orig, d.h. im System-ROM?
		jr	nc, rtape0	;dann Block 1 lesen
		
		call	prepfcb		;sonst
		ld	hl, CONBU
		ld	(DMA), hl	; DMA setzen
		ld	c,13		;OPENR
		call	5
		jp	c, rtape6
	endif
rtape0:		ld	a, 1
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
		ld	d, (hl)		; nächstes Zeichen holen
		push	de
		inc	a
		ld	(M006E), a	; Position im Buffer
		cp	80h		; Bufferende?
		jr	nz, rtape3	; nein, dann mit Zeichen zurück zu BASIC
		call	rtape4
		xor	a
		ld	(M006E), a
;
rtape2:		ld	c, 11		; CSTS: Abfrage Status CONST
		call	5
		cp	3		; <STOP>-Taste gedrückt?
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
		cp	0Dh		; <ENTER>-Taste gedrückt?
		jr	z, rtape4
		cp	3		; <STOP>-Taste gedrückt?
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

		ld	c, 0Ch		; vergleiche rückwärts
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

;----------------------------------------------------
; Patches U.Z.
		ifdef p_farb16p
;Patch zu paper4
paper16:        bit     6, a
                jr      z, paper16a
                set     1, a
                res     6, a
                jr      paper16b
paper16a:       res     1, a
paper16b:       out     (port88), a
                ret
		endif

		if p_wtape
wtape10:	ld      a, (BLNR)	;Blocknr.
		dec     a		;-1
		jp      nz, MF46F	;WRITE (Blockschreiben Sequentiell)
		ld      bc, 1770h	;wenn 1. Block, dann langer Vorton
		jp      MF472		;WRIT1
		endif

;----------------------------------------------------

		;vp20.05.2013
		if p_printatw

at_win		ld	bc,(3BH)	; Window sichern
		ld	(M0077+3),bc
		ld	bc,(3DH)
		ld	(M0077+5),bc
		
		ld	bc, 1900h	; volles Fenster
		ld	(3Bh), bc
		if p_80z
		ld	bc, 5100h
		else
		ld	bc, 2900h
		endif
		ld	(3Dh), bc

;		ld	de,101h
;		ld	c, 18		; SETCU
;		call	5
		ret
		
		endif

	ifdef dirkdo
;-----------------------------------------------------------------------------
; DIR	
;-----------------------------------------------------------------------------
dir:		ld	a,0c0h		;mit Suchmuster, keine Ext. anzeigen
		ld	de,dirzbsc
		ld	c,19		;DIRS
		jp	5		
dirzbsc:	db	"ZBS",0
;-----------------------------------------------------------------------------
; CD ["VERZEICHNIS"]
;-----------------------------------------------------------------------------
cd:		jr	z, cd1		;KEIN PARAMETER VORH.
					;a:=0, list directories
		;mit param
		call	SNALY		;PARAMETER (STRING)
		push	hl
		call	ASC1		;LAENGE UND ADRESSE PARAM
					;IN C UND DE; A <> 0
		ld	b,c		;Länge in b übergeben					
		pop	hl					
cd1:		ld	c,32		;CHDIR
		jp	5	

	endif

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
		
;----------------------------------------------------

;		org	EXTBEG+07E6H

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

		db	(($+0ffh)/100h)*100h-$ dup (0FFh)	; mit FF auffüllen

;;		end
