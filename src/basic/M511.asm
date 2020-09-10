;Version für das originale RAMBASIC und BASIC_84/BASIC_85/BASIC_85 mit M511
;reassembliert: Volker Pohlers, letzte Bearbeitung: 08.01.2008

		cpu	z80

;in basic_8k_kern definiert:
;ROMTYP
;BASTYP
; Kassette R0111 	"BASIC_84" + "RAM"
; BASIC_84 		"BASIC_84" + "ROM"
; BASIC_85 		"BASIC_85" + "ROM"
; BM600.ROM		"BASIC_86" + "ROM"

;Z9001-OS
DMA		equ	001BH 	;Zeiger auf Puffer für Kassetten-E/A
ATRIB		EQU	0027H	;aktuelles Farbattribut
BLNR		equ	006Bh	;Blocknummer
LBLNR		equ	006Ch	;gesuchte Blocknummer bei Lesen
M006E		equ	006Eh	;Position im Buffer
M0075		equ	0075h	;Vortonlänge
M0077		equ	0077h	;Merkzelle HL (für tape)
CONBU		equ	0080h	;Standardpuffer für Kassetten-E/A

OSPAC		equ	0F310h	;Leerzeichen ausgeben
PRNST		equ	0F3E2h
KARAM		equ	0FED6h
MAREK		equ	0FF59h



;ADRESSEN UND DATEN AUS BASIC KERN
;;GTOTOK		equ	88h
;;RSTTOK		equ	8Bh
;;GSBTOK		equ	8Ch
;;THNTOK		equ	0A9h
;;SGNTOK		EQU	0B6H
;;LODTOK		EQU	0D0H
;;ELSTOK		equ	0D4h

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

		jp	ERW1
sub_0_E006:	jp	ERW2
		jp	ERW3

		dw	MNTAB

		jp	VERTEI		; I/O-Verteiler

MNTAB:		db	'I'+80h, "NKEY$"
IKTOK		EQU	0D5H	;INKEY$
		db	'J'+80h, "OYST"
JOTOK		EQU	0D6H	;JOYST
		db	'S'+80h, "TRING$"
STROK		EQU	0D7H	;STRING$
		db	'I'+80h, "NSTR"
ISTOK		EQU	0D8H	;INSTR
		db	'R'+80h, "ENUMBER"
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
		db	80h

ADRTBE:		dw	INKEY
		dw	JOYST
		dw	STRING
		dw	INSTR

ADRTAB1:	dw	RENUM
		dw	DELETE
		dw	PAUSE
		dw	BEEP
		dw	WINDOW
		dw	BORDER
		dw	INK
		dw	PAPER
		dw	AT

;-----------------------------------------------------------------------------
; ERWEITERUNG 1
;*  E: <B>:TOKEN-LODTOK
;*     <HL> :  AUF TOKEN
;*  A:   <<SP>>: STARTADRESSE ROUTINE
;*     <HL>:  AUF TOKEN
;
;-----------------------------------------------------------------------------

ERW1:		ld	a, b
		sub	RETOK-LODTOK
		jr	c, ERR1
		cp	ATTOK-RETOK+1
		jr	nc, ERR1
		rlca
		ld	c, a
		ld	b, 0
		ex	de, hl
		ld	hl, ADRTAB1
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
		jr	nz, ERR1
		inc	a
		ld	(PRTFLG),a
		ld	a, (ATRIB)
		ld	(COLRET),a	;FARBE RETTEN
		ld	a, (hl)
		cp	INTOKE
		jr	z, INPRT
		call	TCHAR
		call	PAPER
		ld	a, (hl)
		cp	';'		;PAPER n ;
		jr	z, CLRG1
		jr	ERR1
;
INPRT:		call	TCHAR
		call	INK
		ld	a, (hl)
		cp	';'
		jr	z, CLRG1
		call	CPSTX
		db	','
		cp	PPTOK
		jr	nz, ERR1
		call	TCHAR		;INK n,PAPER n;
		call	PAPER
		call	CPSTX
		db	';'

CLREG:		call	PRINT2
		ld	a, (COLRET)
		ld	(ATRIB), a
		pop	bc
		ret

ERR1:		jp	SNER

CLRG1:		call	TCHAR
		jr	CLREG

;-----------------------------------------------------------------------------
; ERWEITERUNG 3
;* VERTEILER ZU ZUSAETZLICHEN STANDARTFUNKTIONEN
;* E: <HL> AUF SIGN. ZEICHEN NACH TOKEN
;*    <BC> =<<SP>>  (TOKEN-SGNTOK)*2
;* A: <HL> AUF SIGN. ZEICHEN NACH TOKEN
;-----------------------------------------------------------------------------

ERW3:		ld	a, c			;ZULAESSIG?
		sub	IKTOK-SGNTOK+IKTOK-SGNTOK
		jr	c, ERR1
		cp	ISTOK-IKTOK+ISTOK-IKTOK+1
		jp	nc, ERR1
		ex	de, hl
		ld	bc, ADRTBE		;NEIN
;
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

	IF	ROMTYP	== "RAM"
;-----------------------------------------------------------------------------
; Z9001-OS-Kommando-Rahmen
; Start von BASIC aus dem OS heraus
;-----------------------------------------------------------------------------

		org	nextpage($)

		jp	PRIST1
aBasic:		db	"BASIC   ",0
		jp	SECST
aWbasic:	db	"WBASIC  ",0
		db	0

	ENDIF

;-----------------------------------------------------------------------------
; RENUMBER [zlnralt1 [,zlnralt2 [,zlnrneu1 [,schrittweite]]]]
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

RENUM:		push	hl
		ld	hl, 10
		ld	(DISTAN), hl
		ld	hl, (PSTBEG)
		push	af
		push	hl
		inc	hl
		inc	hl
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		ld	(ANF), hl	;ANF=ERSTE ZEILE
		ld	(NANF), hl	;NANF=ANF
		ld	de, (SVARPT)	;DE=PROGR.ENDE
		dec	de
		dec	de
renum1:		pop	hl		;HL=ZEILENADR.
		push	hl		;IN STACK
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a		;HL=NAECHSTE ZADR.
		call	CPREG
		ex	(sp), hl	;HL=ZEILENADR.
					;STACK=NAECHSTE
		jr	nz, renum1
		pop	de
		inc	hl
		inc	hl
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		ld	(ENDE), hl	;END=LETZTE ZEILE
		ld	b, 4		;MAX 4 PARAMETER
		pop	af
		ld	hl, ANF
		ex	(sp), hl
renum2:		jr	z, renum5	;KEIN PARAM.MEHR
		call	DCHEX		;WERT IN DE
		push	af
		ld	a, d
		or	e
renum3:		jp	z, FCER		;PARAM.=0
		pop	af
		ex	(sp), hl
		ld	(hl), e
		inc	hl
		ld	(hl), d
		inc	hl		;PARAM.EINGETR.
		jr	z, renum5	;KEIN PARAM.MEHR
		push	af
		dec	b
		jr	z, renum4	;ALLE PARAM.
		pop	af
		ex	(sp), hl
		call	CPCOMM		;TEST AUF ","
		jr	renum2
renum4:		pop	af
		jp	nz, SNER	;KEIN ZEILENENDE
renum5:		ld	hl, (ENDE)
		ld	de, (ANF)
		call	CPREG		;END-ANF?
renum6:		jp	c, FCER
		ld	hl, (PSTBEG)
renum7:		call	ZPOIT1		;SUCHE ADR.VON ANF.
		jr	c, renum8	;ZEILE GEFUNDEN
		jr	z, renum3	;PROGR.ENDE
		jr	renum7

renum8:		pop	hl
		push	bc		;ADR.VON ANF.
		ld	de, (ENDE)	;END IN DE
		ld	hl, 0
		ld	(ENDE), hl	;ZEILENZAELER
renum9:		ld	h, b
		ld	l, c
		ld	c, (hl)
		inc	hl
		ld	b, (hl)
		ld	a, b
		or	c
		jr	z, renum3	;PROGR.ENDE
		inc	hl
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		call	CPREG
		ld	hl, (ENDE)
		inc	hl
		ld	(ENDE), hl
		jr	nz, renum9
		inc	hl
		inc	hl
		add	hl, hl
		inc	hl		;TABL=2*ZEILEN-ANZAHL+5
		ld	de, (SVARPT)	;PROGR.ENDE
		add	hl, de
		jr	c, renum6	;TAB.ZU LANG
		call	TMEMO1
		ld	(SVARPT), hl	;NEUES PROGR.ENDE
		xor	a
		dec	hl
		ld	(hl), a
		dec	hl
		ld	(hl), a
		dec	de
		dec	de
		ex	de, hl
		ld	(hl), e
		inc	hl
		ld	(hl), d
		inc	hl
		dec	a
		ld	(hl), a		;TAB.HAT ZEILENNUMMER 65535
		inc	hl
		ld	(hl), a
		inc	hl
		ex	de, hl		;DE=TABANF.ADR
		ld	hl, (NANF)	;HL=NANF
		ld	(ANF), hl	;NEUE ZEILENNR.
renum10:	pop	hl
		ld	c, (hl)
		inc	hl
		ld	b, (hl)
		inc	hl
		push	bc
		ld	bc, ANF
		ld	a, (hl)
		ld	(de), a
		ld	a, (bc)
		ld	(hl), a
		inc	hl
		inc	de
		inc	bc
		ld	a, (hl)
		ld	(de), a
		ld	a, (bc)
		ld	(hl), a		;NEUE ZEILENNR.IN PROGRAMM
					;ALTE ZEILENNR.IN TAB.
		inc	de
		ld	hl, (ANF)
		ld	bc, (DISTAN)
		add	hl, bc
		ld	(ANF), hl	;NEUE ZEILENNR.
		ld	hl, (ENDE)
		dec	hl
		ld	a, h
		or	l
		ld	(ENDE), hl
		jr	nz, renum10
		ld	(de), a
		pop	hl
		ld	hl, (PSTBEG)
		push	hl
renum11:	pop	hl
		ld	c, (hl)
		inc	hl
		ld	b, (hl)
		inc	hl
		push	bc
		ld	a, (hl)
		inc	hl
		and	(hl)
		inc	a
		jr	z, renum15
renum12:	inc	hl
renum13:	ld	a, (hl)
		or	a
		jr	z, renum11
		cp	GTOTOK
		jr	z, renum16
		cp	GSBTOK
		jr	z, renum16
		cp	RSTTOK
		jr	z, renum14
		cp	ELSTOK
		jr	z, renum14
		cp	THNTOK
		jr	nz, renum12
renum14:	call	DCHEX1
		ld	a, e
		or	d
		call	nz, RNU14	;VERGLEICH MIT TABELLE
		call	nz, RNU18	;ZAHL AENDERN
		jr	renum13
renum15:	dec	hl
		ld	(SVARPT), hl
		dec	hl
		ld	(hl), a
		dec	hl
		ld	(hl), a
		pop	hl
		pop	hl
		jp	LIN10
renum16:	call	DCHEX1
		ld	a, e
		or	d
		jr	z, renum13
		call	RNU14
		call	nz, RNU18
		ld	a, (hl)
		cp	','
		jr	nz, renum13	;ANWEISUNGSENDE
		jr	renum16
;
RNU14:		push	hl
		push	de
		ld	de, 65535
		call	ZPOIT		;TAB SUCHEN
		pop	de		;DE=ALTE NR.
		inc	bc
		inc	bc
		inc	bc
		inc	bc
		ld	h, b
		ld	l, c		;HL=TAB.ZEIGER
		ld	bc, (NANF)	;BC=NEUE NR.
RNU15:		ld	a, (hl)
		inc	hl
		push	hl
		or	(hl)
		jr	z, RNU17	;TAB.ENDE
		ld	a, (hl)
		dec	hl
		ld	l, (hl)
		ld	h, a
		call	CPREG
		jr	z, RNU16	;ZAHL GEFUNDEN
		ld	hl, (DISTAN)
		add	hl, bc
		ld	b, h
		ld	c, l
		pop	hl
		inc	hl
		jr	RNU15
RNU16:		ld	a, 0FFh
		or	a
RNU17:		pop	hl
		pop	hl
		ret
;
RNU18:		push	bc		;NEUE NR.
		ex	de, hl
		ld	hl, (SVARPT)
		sbc	hl, de
		push	hl		;PROGR.LAENGE
RNU19:		pop	bc
		ld	h, d
		ld	l, e
		dec	de
		ld	a, (de)
		cp	','
		jr	z, RNU20	;VORHER.ZAHL
		cp	03AH
		jr	nc, RNU20	;ZAHL STREICHEN

		push	bc
		push	de
		ldir
		pop	de
		jr	RNU19
RNU20:		ex	de, hl
		pop	de
		push	hl
		push	bc
		xor	a
		ld	b, 98h
		call	SGN1
		call	NUMKON
		pop	bc
		pop	de
		inc	hl
		inc	de
RNU22:		ld	a, (hl)
		or	a
		jr	z, RNU23
		push	bc
		push	hl
		ex	de, hl
		add	hl, bc
		ld	d, h
		ld	e, l
		dec	hl
		lddr
		pop	hl
		ldi
		pop	bc
		jr	RNU22
RNU23:		push	de
		ld	de, (PSTBEG)
		call	LIN11
RNU26:		inc	hl
		ld	a, (hl)
		inc	hl
		or	(hl)
		jr	nz, RNU26
		ex	de, hl
		ld	(hl), e
		inc	hl
		ld	(hl), d
		inc	de
		inc	de
		ld	(SVARPT), de
		pop	hl
		ld	d, h
		ld	e, l
RNU25:		ld	a, (hl)
		or	a
		inc	hl
		jr	nz, RNU25
		pop	bc
		ex	(sp), hl
		push	bc
		ex	de, hl
		ret


;-----------------------------------------------------------------------------
; INK i
; legt die Vordergrundfarbe für alle nachfolgenden auszugebenden Zeichen fest.
; i =  1 schwarz ..  8 weiß
;-----------------------------------------------------------------------------

INK:		call	border1		;Argument holen (1-8)
		sla	a		;in obere Tetrade verschieben
		sla	a
		sla	a
		sla	a
		ld	b, a
		ld	a, (ATRIB)
		and	7
		jr	paper1		;Farbattribut setzen


;-----------------------------------------------------------------------------
; PAPER i
; legt die Hintergrundfarbe für alle nachfolgenden auszugebenden Zeichen fest.
; i =  1 schwarz ..  8 weiß
;-----------------------------------------------------------------------------

PAPER:		call	border1		;Argument holen (1-8)
		ld	b, a
		ld	a, (ATRIB)
		and	70h
paper1:		or	b
		ld	(ATRIB), a	;Farbattribut setzen
		ld	(28h), a	;???
		ret


;-----------------------------------------------------------------------------
; BORDER i
; legt die Bildschirmrandfarbe fest.
; i =  1 schwarz ..  8 weiß
;-----------------------------------------------------------------------------

BORDER:		call	border1		;Argument holen (1-8)
		sla	a		;auf Bit 5-3 verschieben
		sla	a
		sla	a
		out	(88h), a	;Farbe setzen
		ret
;
border1:	call	ARGVL1		;PARAMETER ERF.
		cp	1
		jr	c, window2
		cp	9
		jr	nc, window2
		dec	a
		ret


;-----------------------------------------------------------------------------
; WINDOW erste_zeile, letzte_zeile, erste_spalte, letzte_spalte
; WINDOW ist gleich WINDOW 0,23,0,39
;-----------------------------------------------------------------------------

WINDOW:		ld	c, 29		; DCU - Cursor löschen
		call	5
		call	TCHAR1		;Pointer auf nächstes signifikantes Zeichen
		jr	z, window3	;wenn keine Parameter
		call	ARGVL1		;Argument holen
		push	af
		call	CPCOMM		;Test auf Komma
		call	ARGVL1		;Argument holen
		push	af
		call	CPCOMM		;Test auf Komma
		call	ARGVL1		;Argument holen
		push	af
		call	CPCOMM		;Test auf Komma
		call	ARGVL1		;Argument holen
		inc	a
		inc	a
		ld	d, a		;d=letzte_spalte+2
		cp	42		;letzte_spalte+2 < 42 ?
		jr	nc, window2	;nein, d.h. letzte_spalte >= 40
		pop	af
		ld	e, a		;e=erste_spalte
		cp	42		;erste_spalte < 42 ?
		jr	nc, window2	;nein, d.h. erste_spalte >= 42
		pop	af
		inc	a
		inc	a
		ld	b, a		;b=letzte_zeile+2
		cp	26		;letzte_zeile+2 < 26?
		jr	nc, window2	;nein, d.h. letzte_zeile >= 24
		pop	af
		ld	c, a		;c=erste_zeile
		cp	26		;erste_zeile < 26 ?
		jr	nc, window2	;nein, d.h. erste_zeile >= 26
		inc	a
		cp	b		;erste_zeile+1 < letzte_zeile+2 ?
		jr	nc, window2	;nein, d.h. erste_zeile > letzte_zeile
		ld	a, e
		inc	a
		cp	d		;erste_spalte+1 < letzte_spalte+2 ?
		jr	nc, window2	;nein, d.h. erste_spalte > letzte_spalte
;
window1:	ld	(3Dh), de	;E=P3ROL (1. ZU ROLLENDE SPALTE-1)
					;D=P4ROL (LETZTE ZU ROLLENDE SPALTE+1)
		ld	(3Bh), bc	;C=P1ROL (1. ZU ROLLENDE ZEILE-1)
					;B=P2ROL (LETZTE ZU ROLLENDE ZEILE+1)
		ld	d, c		;Cursor auf Fensteranfang
		inc	d
		inc	e
		ld	c, 18		; SETCU
		call	5
		ret
window2:	jp	SNER		;Ausgabe SN-ERROR
		ld	c, 29		; DCU
		call	5
window3:	ld	bc, 1900h	;Zeilen 1 - 18h=24
		ld	de, 2900h	;Spalten 1 - 28h=40
		jr	window1


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
	IF	BASTYP	<> "BASIC_84"
		ld	a, d
		or	e
		ret	z		;wenn = 0
	ENDIF
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
pause9:		call	CI		;Tastatureingabe
pause10:	pop	de
		pop	bc
		pop	af
pause11:	pop	hl
		ret

paus_val:	db	0

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

;		db	0FFh
;		db	0FFh
;		db	0FFh
;		db	0FFh
;		db	0FFh
;		db	0FFh
;		db	0FFh

	IF	ROMTYP	== "ROM"
;-----------------------------------------------------------------------------
; Z9001-OS-Kommando-Rahmen
; Start von BASIC aus dem OS heraus
;-----------------------------------------------------------------------------

		org	nextpage($)

		jp	PRIST1
aBasic:		db	"BASIC   ",0
		jp	SECST
aWbasic:	db	"WBASIC  ",0
		db	0

	ENDIF

;-----------------------------------------------------------------------------
; INSTR (x$,y$)
; Diese Anweisung liefert die Position des ersten Auftretens des
; Zeichenkettenausdruckes x$ im Zeichenkettenausdruck y$.
; Ist x$ nicht in y$ enthalten, so den Wert 0.
; Der Funktionswert ist ein numerischer Wert zwischen 0 und 255.
;-----------------------------------------------------------------------------

INSTR:		call	SNALY6		;PARAMETER1
		call	CPCOMM		;Test auf Komma
		push	hl
		call	LEN1		;STRING LAENGE
		jr	z, instr7	;Fehler: X$ ist Leerstring
;
		ld	b, a		;B=Länge X$
		inc	hl
		inc	hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)		;DE=Adresse X$
		pop	hl
;
		push	de
		push	bc
		call	SNALY		;PARAMETER 2
		call	CPBRGT		;Test auf rechte Klammer
		pop	bc
		pop	de
;
		push	hl
;
		push	de
		push	bc
		call	LEN1		;STRING LAENGE
	IF	BASTYP	== "BASIC_84"
		jr	z, instr7	;Fehler: Y$ ist Leerstring
	ELSE
		jr	z, instr4	;Fehler: Y$ ist Leerstring
	ENDIF
		inc	hl
		inc	hl
		ld	c, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, c		;HL=Adresse Y$
		pop	bc
		ld	c, a		;C=Länge Y$
		pop	de
;
		push	hl
instr1:		push	bc
		push	de
		ld	a, (de)
instr2:		cp	(hl)		;erstes Zeichen gleich?
		jr	z, instr8
		inc	hl
		dec	c
		jr	nz, instr2
;
instr3:		xor	a		;nicht gefunden -> Rückgabewert 0
		pop	hl
instr4:		pop	hl
		pop	hl
instr5:		ld	de, SNLY16
		push	de
instr6:		jp	POS1
;
instr7:		jp	FCER		;FC ERROR
;
instr8:		inc	hl
		push	hl
		dec	hl
instr9:		inc	hl
		dec	c
		jr	z, instr10	;wenn am Ende von Y$ angekommen
		inc	de
		dec	b
		jr	z, instr11	;wenn am Ende von X$ angekommen
		ld	a, (de)
		cp	(hl)		;Vergleich nächstes Zeichen
		jr	z, instr9	;wenn gleich
;
		pop	hl
		pop	de
		ld	a, c
		pop	bc
		ld	c, a
		jr	instr1		;sonst weitersuchen
;
instr10:	inc	de		;Ende von Y$ erreicht
		dec	b		;auch Ende von X$ erreicht?
		pop	hl
		jr	nz, instr3	;nicht gefunden -> Rückgabewert 0
		jr	instr12		;wenn gefunden
;X$ in Y$ gefunden
instr11:	pop	hl
instr12:
	IF	ROMTYP	== "ROM"
		dec	c
	ENDIF
		pop	de
		pop	de
		pop	de
		and	a
		sbc	hl, de
		ld	a, l		; Rückgabewert
		jr	instr5

;-----------------------------------------------------------------------------
;STRING$ (i,j$)
; Die Funktion liefert eine Zeichenkette, die durch i-fache Wiederholung des
; Zeichenkettenausdrucks j$ entsteht. i kann Werte zwischen 0 und 255 (einschließlich)
; annehmen. Der Zeichenkettenausdruck, der durch die Funktion STRING$ geliefert wird,
; darf höchstens 255 byte lang sein.
;-----------------------------------------------------------------------------

STRING:		call	CPSTX		;'('?
		DB	'('
		CALL	ARGVL1		;PARAMETER 1
		PUSH	AF		;WERT RETTEN
		call	CPCOMM		;KOMMA?
		call	SNALY		;PARAMETER 2 (STRING)
		call	CPBRGT		;')'?
		pop	af
		push	hl		;ZEILENZEIGER
		push	af
		call	LEN1		;LAENGE UND ADRESSE PARAM.2
		inc	hl		;IN A UND HL
		inc	hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		pop	bc		;PARAM.1 (WIEDERHOLFAKTOR)
		push	bc
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
		push	bc
		call	STROP		;PLATZ IN STRINGPOOL RESERVIEREN
					;ADR.NEUER STRING IN DE
		pop	bc		;LAENGE NEUER STRING IN BC
		pop	bc		;ADR.ALTER STRING HOLEN
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

;-----------------------------------------------------------------------------
; BEEP [...] (beliebige Parameter)
;-----------------------------------------------------------------------------

BEEP:		call	TCHAR1		;PARAMETER VORH.?
		jr	nz, beep1
		ld	c, 2		; CONSO
		ld	e, 7		; BEEP
		call	5
		ret	nc
beep1:		call	TCHAR		;nachfolgende Parameter übergehen
		ret	z
		jr	beep1

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
		call	ARGVL1		;Parameter1: Zeile
		push	af
		call	CPCOMM		;KOMMA?
		call	ARGVL1		;Parameter2: Spalte
		push	af
		call	CPBRGT		;')'?
;
		call	CPSTX		;'('?
		dec	sp
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
at1:		jp	SNER		;SN ERROR
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
		ex	(sp), hl	;(SP)=Position im FarbBWS
;
		push	de
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
		jr	z, joyst2	; A=0, so Fehler
		cp	3		; A<3 ?
		jr	nc, joyst2	; wenn nein, d.h. A>=3, so Fehler
		ld	c, 6		; GETST Joystick-Abfrage
		call	5
		jr	c, joyst2	; bei Fehler
		cp	1		; Spielhebel 1?
		jr	z, joyst1
		ld	c, b		; Spielhebel 2 -> Rückgabewert in B
joyst1:		ld	a, c		; Spielhebel 1 -> Rückgabewert in C
		jp	POS1		; Funktionswert zurückgeben
;
joyst2:		jp	SNER		; SN ERROR

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

;		db	0FFh
;		db	0FFh
;		db	0FFh
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

;		org	0e600h
		org	nextpage($)

VERTEI:		bit	5, e		; BYE ?
		jp	nz, 0		; dann Systemneustart
		ld	(M0077), hl
		push	hl		; HL sichern
		ld	hl, vertei1	; Rückehradresse kellern
		push	hl
		ld	a, e
		and	7
		sla	a
		add	a, lo(vertab)
		ld	l, a
		ld	a, 0
		adc	a, hi(vertab)
		ld	h, a
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a
		jp	(hl)		; Start der IO-Routine
vertei1:	pop	hl		; HL restaurieren
		ret			; und zurück zum BASIC

aVerifyYN:	db	"\r\n"
		db	"VERIFY (Y/N)? ",0
aRewind:	db	" REWIND! ",0


vertab:		dw	rcons		;Kanal#0: Console
		dw	conso
		dw	rtape		;Kanal#1: Tape
		dw	wtape
		dw	IOERR		;Kanal#2: Drucker
		dw	IOERR
		dw	IOERR		;Kanal#3: frei
		dw	IOERR

;-----------------------------------------------------------------------------
; read console
;-----------------------------------------------------------------------------

rcons:		bit	7, e		; nur Status-Abfrage?
		jr	z, rcons1
		call	rconb		; sonst Zeichenkette einlesen
		or	a
		jr	z, rcons2	; wenn nix eingegeben wurde
		res	7, e
		jr	rcons2
rcons1:		call	consi
rcons2:		ld	d, a
		ret

;-----------------------------------------------------------------------------
; console output
;-----------------------------------------------------------------------------

conso:		push	de
		push	bc
		ld	e, d		; auzugebendes Zeichen
		ld	c, 2		; CONSO
		call	5
		pop	bc
		pop	de
		res	7, e
		ret

;-----------------------------------------------------------------------------
; write tape
;-----------------------------------------------------------------------------

;BASIC-Kopf:
; 3 Byte Dateityp (D3, D4, D5 bzw. D7, D8, D9)
; 8 Byte Dateiname, wenn kürzer, dann muß mind. 1 Leerzeichen folgen
; 2 Byte Adresse1
; 2 Byte Adresse2

wtape:		push	hl
		push	bc
		push	de
		bit	3, e		; init?
		jr	z, wtape2	; nein, also Byte in Buffer schreiben
;Initialisierung
		ld	hl, (M0077)
		ld	bc, 0Bh		; 3 Byte Dateityp + 8 Byte Dateiname
		inc	hl
		inc	hl
		ld	a, 0D5h		; CLIST
		cp	(hl)		; ist 3. Byte = CLIST-Kennung?
		push	de
		ld	de, 0A0h	; Länge Vorton
		jr	nz, wtape1
		ld	de, 400h	; Bei CLIST mehr Zeit zwischen den Blöcken lassen
wtape1:		ld	(M0075), de	; Länge Vorton merken
		ld	de, CONBU	; Dateityp + Dateiname nach STDMA-Buffer kopieren
		ldir
		pop	de
		ld	hl, BLNR	; 1. Block hat Nummer 0
		ld	(hl), 0
		ld	hl, M006E	; Position im Buffer
		ld	(hl), 0Ch	; mit 0Ch initialisieren (nach Dateityp+Dateiname)
		ld	hl, CONBU+0Bh	; Offs. 3 Byte Dateityp + 8 Byte Dateiname
		ld	(hl), d		; 1. auszugebendes Zeichen
		jp	wtape9
; nächstes Zeichen in Buffer schreiben
wtape2:		ld	hl, CONBU
		ld	a, (M006E)	; Position im Buffer
		ld	c, a
		ld	b, 0
		add	hl, bc
		inc	a
		ld	(M006E), a
		ld	(hl), d		; Zeichen in Buffer schreiben
		bit	6, e		; Ende?
		jr	nz, wtape3	; Sprung wenn Endebit gesetzt
		cp	80h		; oder Buffer voll?
		jr	nz, wtape9	; sonst raus hier
; Block auf Kassette schreiben
wtape3:		ld	hl, CONBU
		ld	(DMA), hl	; DMA setzen
		push	de
		ld	a, (BLNR)
		or	a		; 1. Block?
		ld	bc, 1770h	; dann langer Vorton
		jr	z, wtape4
		ld	bc, (M0075)	; sonst gewählte Vortonlänge
wtape4:		inc	a
		ld	(BLNR), a	; Blocknummer erhöhen
		call	KARAM		; Block schreiben
		ld	hl, M006E	; Position im Buffer
		ld	(hl), 0		; zurücksetzen für nächsten Block
		call	inita		; Tastatur init.
		call	OSPAC		; Leerzeichen ausgeben
		pop	de
		bit	6, e		; Ende?
		jp	z, rtape4
; Verify
		ld	de, aVerifyYN	; "\r\nVERIFY (Y/N)? "
		call	PRNST
		call	consi
		cp	'Y'
		jr	nz, wtape9	; Sprung, wenn kein Verify gewünscht ist
		ld	de, aRewind	; " REWIND! "
		call	PRNST
		call	consi
		ld	d, '*'
		call	conso
		ld	a, (BLNR)
		ld	b, a		; Anzahl der zu verifizierenden Blöcke
wtape5:		push	bc
;
wtape6:		call	MAREK		; Block lesen
		call	inita
		jr	nc, wtape7	; weiter wenn alles ok
		call	consi		; bei Lesefehlern warten auf Tastendruck
		cp	0Dh		; <ENTER>?
		jr	z, wtape6	; dann Block erneut lesen
		cp	3		; <STOP>?
		jr	z, rtape6	; dann Abbruch -> IOERR
wtape7:		call	rconb
		cp	3		; <STOP>?
		jr	z, rtape6	; dann Abbruch -> IOERR
		pop	bc
		call	OSPAC
		djnz	wtape5		; bis alle Blöcke gelesen
wtape8:		pop	af
wtape9:		pop	de
		pop	bc
		pop	hl
		res	7, e
		res	3, e
		ld	d, a
		ret

;-----------------------------------------------------------------------------
; read from tape
;-----------------------------------------------------------------------------

rtape:		push	hl
		push	bc
		push	de
		bit	6, e		; Ende?
		jr	nz, wtape9	; dann abbrechen
		bit	3, e		; Init?
		jr	z, rtape7	; nein, Daten einlesen
; Init
		ld	hl, CONBU
		ld	(DMA), hl	; DMA auf STDMA setzen
		xor	a
		ld	(M006E), a	; Position im Buffer = 0
		ld	hl, LBLNR	; 1. zu lesende Blocknummer = 1
		ld	(hl), 1
rtape1:		ld	c, 33		; RRAND, Lesen eines Blockes von Kassette
		call	5
		jr	nc, rtape3	; wenn kein Fehler
rtape2:		call	consi
		cp	3		; <STOP>?
		jr	nz, rtape1	; nein, dann erneuter Leseversuch
		jr	rtape6
rtape3:		ld	a, (BLNR)
		dec	a
		jr	nz, rtape2	; erneuter Leseversuch, wenn nicht Block Nr. 1
; 1. Block gelesen
		call	OSPAC		; Leerzeichen ausgeben
		call	thead
		ld	hl, M006E	; Position im Buffer
		ld	(hl), 0Ch	; mit 0Ch initialisieren (nach Dateityp+Dateiname)
		ld	hl, CONBU+0Bh	; Offs. 3 Byte Dateityp + 8 Byte Dateiname
		ld	a, (hl)		; 1. Zeichen
rtape4:		push	af
rtape5:		call	rconb
		cp	3		; <STOP>?
		jr	nz, wtape8	; zurück zu BASIC
rtape6:		jr	rtapef		; IOERR
; Daten einlesen
rtape7:		ld	hl, CONBU
		ld	a, (M006E)	; Position im Buffer
		ld	c, a
		ld	b, 0
		add	hl, bc
		ld	a, (hl)		; nächstes Zeichen holen
		push	af
		ld	a, c
		inc	a
		ld	(M006E), a	; Position im Buffer
		cp	80h		; Bufferende?
		jr	nz, wtape8	; nein, dann mit Zeichen zurück zu BASIC
		ld	a, (LBLNR)	; ja, dann Blocknummer erhöhen
		inc	a
		ld	(LBLNR), a
rtape8:		ld	c, 33		; RRAND, Lesen eines Blockes von Kassette
		call	5		; nächsten Block lesen
		jr	nc, rtape10	; wenn ohne Lesefehler
rtape9:		call	consi
		cp	3		; <STOP>?
		jr	nz, rtape8	; nein, dann erneuter Leseversuch
		jr	rtapef		; sonst IOERR
rtape10:	ld	hl, LBLNR	; Vergleich gelesene und zu lesende Block Nr.
		ld	a, (BLNR)
		cp	(hl)
		jr	c, rtape8
		jr	nz, rtape9	; erneuter Leseversuch, wenn nicht Block Nr.
		call	OSPAC
		ld	hl, M006E	; Position im Buffer
		ld	(hl), 0		; zurücksetzen für Block
		jr	rtape5		; und Block abarbeiten


; Programmnamen anzeigen
thead:		ld	hl, CONBU
		ld	b, 0Bh		; 3 Byte Dateityp + 8 Byte Dateiname
thead1:		ld	d, (hl)
		call	conso		; anzeigen
		inc	hl
		djnz	thead1
;Programmnamen vergleichen
		ld	hl, (M0077)	; Vergleich mit zu lesendem Dateinamen
		ld	bc, 0Ch		; vergleiche rückwärts
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
		jr	nz, rtapef	; Datei nicht gefunden
		ld	a, 0FFh		; sonst DATFLG setzen
		ld	(DATFLG), a
		jr	thead3		; und weiter vergleichen
;
rtapef:		jp	IOERR

;-----------------------------------------------------------------------------
;Initialisierung Tastatur
;-----------------------------------------------------------------------------

inita:		push	af
		ld	c, 25		; INITA, Initialisierung der Tastatur und der Systemuhr
		call	5
		pop	af
		ret

;-----------------------------------------------------------------------------
; read console buffer
;-----------------------------------------------------------------------------

rconb:		push	bc
		ld	c, 11		; RCONB, Eingabe Zeichenkette von CONST
		jr	cbios

;-----------------------------------------------------------------------------
; console input
;-----------------------------------------------------------------------------

consi:		push	bc
		ld	c, 1		; CONSI
;
cbios:		call	5
		pop	bc
		ret

;		db	0FFh
;		db	0FFh

		db	(($+0ffh)/100h)*100h-$ dup (0FFh)	; mit FF auffüllen

		end
