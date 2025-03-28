; File Name: eprommer_2_9_ccl.bin
; Range: 0100h - 0900h Loaded length: 0800h
; reassembliert mit IDAFREE
; aufbereitet für den AS Macro Assembler as1418
; Assemblieren mit: as -L eprommer.asm, p2bin -r $-$ eprommer.p
; orig: Rainer Brosig, August 86
; reass+Anpassung an Z9001: Volker Pohlers 21.02.2003, 25.06.2013

		CPU	Z80
;
;*************************************
;
;EPROM-HANDLER V.2.9 RAM FC
;Hardware nach Bd.227/228 mit Z 1013
;
;(c) by Rainer Brosig, August 86
;W.-Florin-Str. 2c, COSWIG, 8270
;
;*************************************
;

P1ROL		EQU	0003BH
CURSR		EQU	0002DH	; CURS aktuelle Cursorposition
SCREEN		EQU	0EC00H	; Screen-Start
CONIN		EQU	0F009H	; Eingabe 1 Zeichen (A) von CONST
;CONSO		EQU	0F00CH	; Ausgabe 1 Zeichen (C) zu CONST
OUTA:		EQU	0F305H	; Ausgabe 1 Zeichen (A) zu CONST

;Hardware Eprom-Programmiermodul des CC Leipzig (mit PIO)
PIO_DA		EQU	0FCH	; Daten Kanal A - Datenbus
PIO_STA		EQU	0FDH	; Steuerwort Kanal A
PIO_DB		EQU	0FEH	; Daten Kanal B
PIO_STB		EQU	0FFH	; Steuerwort Kanal B

; PB7	Fertigsignal
; PB6	Programmierimpuls
; PB5	CS/WE bzw. OE
; PB4	Zuschalten UPP
; PB3	Zuschalten UCE, U00
; PB2	Zähler rücksetzen
; PB1	-
; PB0	Zähler

		org	160h
;
;ARBEITSZELLEN
;

DATA:		DS	2
SOIL:		DS	2
;
AZYKZ:		DS	1		;AKTUELLER ZYKLENZAEHLER
KENNZ:		DS	1		; ProgrammKENNZ	(1..5)
FZ:		DS	1		;FEHLERZELLE
LESEZ:		DS	1		;GELESENES BYTE
eprom_size:	DS	2
eprom_von:	DS	2
eprom_bis:	DS	2
ramadr:		DS	2		; Ablagebereich	ROM-Inhalt im Speicher

;
;*****************************
		org	0300h

		JP	start
		db	"EPROMCCL", 0
		db	0
;
		db	"Rainer Brosig & Volker Pohlers"

start:
;
;INITIALISIERUNG
;
		ld	a, 0CFh		;PORT B BITMODE
		out	(PIO_STB), a
		ld	a, 80h		;BIT 0-6 AUSGABE BIT 7 EING.
		out	(PIO_STB), a
		ld	a, 20h		;EPROM-FASSUNG SPANNUNGSLOS
		out	(PIO_DB), a
		ld	a, 25h		;ZAEHLERRESET
		out	(PIO_DB), a
;
;TYPENABFRAGE
;
		call	cprst7
		db 	0Ch
		db	"  *** EPROM-Handler V.2.9 *** "
		db	8Dh

		ld	a,2
		ld	(P1ROL), A	; Fenster ab 3. Zeile

		call	cprst7
		db	0Ch
		db	0Dh
		db	"EPROM-Typ? :"
		db 	0A0h
		call	inphex		; Zahl einlesen	(Eprom-Typ)
		ld	a, l
		or	h
		jr	z, start	; Fehler bei 0
		push	hl
		ld	hl, (SOIL)	; SOIL, anfangsadresse der Eingabezeile
; 5 Zeichen (EpromTyp) auf den Bildschirm poken
		ld	de, SCREEN+0*40+0014h	; "V.2.9" wird überschrieben
		ld	bc, 5
		ldir
		pop	hl
		ld	a, l		; vom Eprom-Typ	werden nur die letzten beiden Stellen getestet
;
;LADEN PARAMETER
;
		cp	55h		; 555
		ld	hl, 400h	; EPROM-Groesse
		jr	nz, start2
		jr	start4
start2:					; 2708
		cp	8
		jr	nz, start3
		jr	start4
start3:					; 2716
		cp	16h
		add	hl, hl
		jr	z, start4
		cp	32h		; 2732
		add	hl, hl
		jr	z, start4
		cp	64h		; 2764
		add	hl, hl
		jr	z, start4
		cp	28h		; 27128
		add	hl, hl
		jr	z, start4
		cp	56h		; 27256
		add	hl, hl
		jr	z, start4
		jp	start
start4:					; Groesse des Eproms merken
		ld	(eprom_size), hl
;
;
MODE:		call	UDDOF
		call	INITE
		call	cprst7
		db	0Ch
		db	0Dh
		db	"     Fassung spannungslos!"
		db	0Dh
		db	0Dh
		db	0Dh
		db	"Mode:"
		db	0Dh
		db	"====="
		db	0Dh
		db	0Dh
		db	0Dh
		db	"     Lesen.........1"
		db	0Dh
		db	0Dh
		db	"     Programmieren.2"
		db	0Dh
		db	0Dh
		db	"     Vergleichen...3"
		db	0Dh
		db	0Dh
		db	"     Loeschtest....4"
		db	0Dh
		db	0Dh
		db	"     Wiederholen...5"
		db	0Dh
		db	0Dh
		db	"     Fortsetzen....6"
		db	0Dh
		db	0Dh
		db	0Dh
		db	"Funktionswahl nach Kennziffer:"
		db	0A0h

MRET:		CALL	CCONIN
		cp	3		; STOP-Taste gedrueckt?
		jr	z, BREAK
		cp	'N'             ; N gedrueckt?
		jr	z, BREAK
		jr	MAUSW
;
BREAK:		push	af
		ld	a,0
		ld	(P1ROL), A	; Fenster ab 1. Zeile

		pop	af
		cp	'N'
		jp	z, start	; Bei N	Neustart
;extra für Megamodul
		xor	a		; f. Megamodul 13.03.2010
		out	(0ffh),a	; Bank 0

		jp	0F000h		; Bei STOP zur?ck zum Betriebssystem
;
;KENNZAHL-AUSWERTUNG
;
MAUSW:					; Fehler wenn <	1
		cp	'1'
		jr	c, MRET
		cp	'5'
		jp	nc, MREK	; UP-Aufruf bei	Zahl 1..5
;
		call	ccoout		; Mode ausgeben
		ld	(KENNZ), a
		call	cprst7
		db	0Dh
		db	0Dh
		db	"gesamten Speicherbereich "
		db	0Dh
		db	0Dh
		db	"des EPROM ? (N/ENT)"
		db	0A0h
		CALL	CCONIN
		cp	3		; Stop-Taste gedrueckt?
		jp	z, MODE
		cp	0Dh		; ENTER-Taste gedrueckt
		jr	nz, MBER
		ld	a, 0Ch		; CLS ausgeben (Bildschirm l"schen)
		call	ccoout
		ld	hl, (eprom_size)
		dec	hl
		ld	(eprom_bis), hl
		ld	hl, 0
		ld	(eprom_von), hl
		jp	MKENZ
;
MBER:		call	cprst7
		db	0Ch
		db	0Dh
		db	0Dh
		db	0Dh
		db	"rel. EPROM-Adressbereich (HEX)"
		db	0Dh
		db	0Dh
		db	0Dh
		db	0Dh
		db	"  von:"
		db	0A0h
		call	inphex
		ld	bc, (eprom_size)
		push	hl
		or	a
		sbc	hl, bc		;KONTROLLE BEREICHSGROESSE
		pop	hl
		jp	nc, MBER
		ld	(eprom_von), hl
		call	cprst7
		db	0Dh
		db	"  bis:"
		db	0A0h
		call	inphex
		ld	bc, (eprom_von)
		push	hl
		or	a
		sbc	hl, bc		;KONTROLLE BEREICH
		pop	hl
		jp	c, MBER
		push	hl
		ld	bc, (eprom_size)
		sbc	hl, bc
		jp	nc, MBER
		pop	hl
		ld	(eprom_bis), hl

;
;*******************************
;FUNKTIONSAUFSPALTUNG F1-F4
;
MKENZ:		ld	a, (KENNZ)
		cp	'1'
		jp	z, MLES		; 1-Lesen
		cp	'2'
		jp	z, MPRO		; 2-Programmieren
		cp	'3'
		jp	z, MVERG	; 3-Vergleichen

;
;*****************************
;4-LOESCHTEST
;
LTEST:		call	LTMA		;LOESCHTEST MIT ANZEIGE
		ld	a, (FZ)
		or	a
		jr	z, EPRG1
		call	ZVEIN
		call	UDDON
		call	LADEN
LTFE1:		in	a, (PIO_DA)
		cp	0FFh
		jr	z, LTFE2
		push	af
		call	cprst7
		db	0Dh
		db	"no blank:"
		db	0A0h
		ld	h, b
		ld	l, c
		call	COUTHL
		LD	A, ' '
		CALL	ccoout
		CALL	ccoout
		pop	af
		call	COUTHX
		CALL	CCONIN
                cp      3		; STOP gedrueckt?
		jp	z, MODE
LTFE2:		call	ZYEND
		jr	z, EPRG1
		inc	bc
		call	AZINC
LTFE3:		dec	a		;EINSCHW.-ZEIT
		jr	nz, LTFE3
		jr	LTFE1

EPRG1:		call	UDDOF
		call	cprst7
		db	0Dh
		db	0Dh
		db	0Dh
		db	"OK"
		db	0Dh
		db	0A0h
		CALL	CCONIN
		jp	MODE
;
;*****************************
;EINLESE-PROGRAMM EPROM IN RAM
;Mode 1: Lesen
;
MLES:		call	cprst7
		db	0Dh
		db	0Dh
		db	0Dh
		db	"nach"
		db	0A0h
		call	ANZ5
MLES1:	call	ZVEIN
		call	UDDON
		call	LADEN
MLES2:	in	a, (PIO_DA)
		ld	(hl), a
		call	AZINC
		call	ZYEND
		inc	hl
		inc	bc
		jr	nz, MLES2
		call	CRC		; CRC-Berechnung
		jp	MODE		;ENDE SCHLEIFE LESEZYKLUS
;
;*****************************
;PROGRAMMIER-PROGRAMM
; + LOESCHTEST
;
MPRO:		call	LTMA
		ld	a, (FZ)
		or	a
		jr	z, up_prog
		call	ANZ4
		CALL	CCONIN
		cp	'J'
		jp	nz, MODE
;
;*****************************
;  ABFRAGE RAM-ADRESSE
; + TEST AUF BESCHREIBFAEHIGKEIT
;Mode 2: Programmieren
;
up_prog:	call	cprst7
		db	0Dh
		db	0Dh
		db	0Dh
		db	20h
		db	"von"
		db	0A0h
		call	ANZ5
MTAB2:	call	ZVEIN
		call	UDDON
		call	LADEN
up_prog2:	call	VTEST
		call	AZINC
		call	ZYEND
		jr	z, PROGR
		inc	hl
		inc	bc
		jp	up_prog2
;
VTEST:		push	bc
		in	a, (PIO_DA)
		ld	(LESEZ), a
		ld	b, a
		ld	a, (hl)
		xor	b
		ld	b, a
		ld	a, (hl)
		and	b
		pop	bc
		ret	z
;
;FEHLERROUTINE
;
		call	cprst7
		db	0Ch
		db	0Dh
		db	0Dh
		db	"Unvertraeglichkeit!  R       E"
		db	0Dh
		db	0Dh
		db	"EPROM-Zelle:"
		db	0A0h
		push	hl
		ld	h, b
		ld	l, c
		call	COUTHL
                pop     hl
                push    hl
                call	cprst7
		db	"  "
		db	0A0h
		ld	a, (hl)
		call	COUTHX
		call	cprst7
		db	" <-#->"
		db	0A0h
		ld	a, (LESEZ)
		call	COUTHX
		call	cprst7
		db	0Dh
		db	0Dh
		db	8Dh
		CALL	CCONIN
		cp	3	; STOP gedrueckt?
		pop	hl
		ret	nz
		jp	MODE
;
;
;*****************************
;PROGRAMMIERUNG
;
PROGR:		call	cprst7
		db	0Ch
		db	0Dh
		db	0Dh
		db	0Dh
		db	"       Programmierung!"
		db	0Dh
		db	"      ================"
		db	0Dh
		db	0Dh
		db	0Dh
		db	"   "
		db	0A0h
		ld	a, 8Ch
		call	ccoout
		call	cprst7
		db	" - Programmierzyklus"
		db	0Dh
		db	0Dh
		db	"   "
		db	0A0h
		ld	a, 0CFh
		call	ccoout
		call	cprst7
		db	" - Sicherheitszyklus"
		db	0Dh
		db	0Dh
		db	8Dh

		xor	a
		ld	(AZYKZ), a	;LOESCHEN AKTUELLEN ZYKLENZAEHLER

VPZ:					;VOLLER PROGRAMMIERZYKLUS
		xor	a
		ld	(FZ), a
		ld	a, 8Ch
		call	ccoout
		call	PZYKL		;PR.-ZYKL.OHNE LESEN
		call	VGZ		;KONTROLLESEZYKLUS
		ld	a, (FZ)
		or	a
		jr	z, SIZYK	;FEHLERFREI-->SICHERHEITSZYKLEN
		push	hl
		ld	hl, AZYKZ
		inc	(hl)
		ld	a, (hl)
		cp	100		; max 100 Zyklen
		pop	hl
		jr	nz, VPZ
		jp	MVERG1
;
;SICHERHEITSZYKLEN
;
SIZYK:		ld	a, (AZYKZ)
		cp	3
		jr	nc, up_prog7
		ld	a, 3
up_prog7:	sla	a		;ANZ.SICHERH.-ZYKL.=PRZ.*2
		sla	a		;*2
		ld	b, a
up_prog8:	push	bc
		ld	a, 0CFh
		call	ccoout
		call	PZYKL
		pop	bc
		djnz	up_prog8
		call	VGZ
		ld	a, (FZ)
		or	a
		jp	nz, MVERG1
		call	CRC
		jp	MODE
;
;*****************************
;UP-TIME 60ms (bei 2MHz Taktfrequenz)
;
TIME_:		push	de
		ld	de, 2500h	;z1013: 2000h
TIME_1:		dec	e
		jr	nz, TIME_1
		dec	d
		jr	nz, TIME_1
		pop	de
		ret
;
;***************************
;UP-VERGLEICHSLESEZYKLUS
;
VGZ:		call	INITE		;EINGABE
		ld	a, 0Ch		;Upp OF + Udd ON
		out	(PIO_DB), a
		call	TIME_
		call	ZVEIN
		in	a, (PIO_DB)
		set	5, a		;/CS=LOW
		out	(PIO_DB), a
		call	LADEN
		xor	a
		ld	(FZ), a		;LOESCHEN FEHLERZELLE
VGZ1:		call	VTEST
		in	a, (PIO_DA)
		cp	(hl)
		jr	z, VGZ2
		ld	a, 0FFh
		ld	(FZ), a
VGZ2:		call	AZINC
		call	ZYEND
		ret	z
		inc	bc
		inc	hl
		jr	VGZ1
;
;***************************
;UP-PROGR.-ZYKL.OHNE KONTROLLE
;
PZYKL:		call	UPPON
		call	LADEN
PZYK1:		call	PROS
		call	AZINC
		call	ZYEND
		ret	z
		inc	bc
		inc	hl
		jr	PZYK1
;
;***************************
;UP-LADEN
;
LADEN:		ld	hl, (ramadr)
		ld	bc, (eprom_von)
		ld	de, (eprom_bis)
		ret
;
;***************************
;UP-KONTROLLE ZYKLUSENDE
;
ZYEND:		push	hl
		ld	h, 8
TIME1:		dec	h
		jr	nz, TIME1
		ld	h, b
		ld	l, c
		or	a
		sbc	hl, de
		pop	hl
		ret
;
;*****************************
; ZAEHLERVOREINSTELLEN
; + UPP ZUSCHALTEN
;
UPPON:		call	ZVEIN
		ld	a, 1Ch
		out	(PIO_DB), a	;UPP ZUSCHALTEN
		call	TIME_
		ret
;
;*****************************
; UP-PROGRAMMIERSCHRITT
; HL=AKTUELLE RAM-ADR.
; Zellenprogrammierung
;
PROS:		ld	a, (hl)
		cp	0FFh
		jr	z, ZYKEN
		call	INITA		;AUSGABEINITIALISIERUNG
		ld	a, 1Ch
		out	(PIO_DB), a	;CS-SCHREIBEN BEI UDD+UP
		ld	a, (hl)
		out	(PIO_DA), a	;AUSGABE DATENBYTE
		ld	a, 5Ch
		out	(PIO_DB), a	;PROGAMMIERIMPULS AUSLOESEN
		ld	a, 20h
ZS1:		dec	a
		jr	nz, ZS1
;
MIE:		push	hl
		push	bc
		push	de
		LD	C,11		; CSTS
		CALL	5
		pop	de
		pop	bc
		pop	hl
		cp	3		; STOP-Taste gedrueckt?
		jr	nz, MRUEK
		call	UDDOF
		call	INITE		;EINGABEINIT.
		jp	MODE

MRUEK:		in	a, (PIO_DB)	;ABFRAGE ENDE PROGRAMMIERZEIT
		bit	7, a
		jr	nz, MIE
ZYKEN:		ret
;
;*****************************
; UP LESEN EPROMZELLE
; INHALT IM AKKU+LESEZELLE
;
LEEZ:		call	INITE
		in	a, (PIO_DB)
		set	5, a		;EPROM AUF LESEN
		out	(PIO_DB), a
		in	a, (PIO_DA)
		ld	(LESEZ), a
		ret
;
;*****************************
;VERGLEICHEN EPROM MIT RAM
;
MVERG:
		call	cprst7
		db	0Dh
		db	0Dh
		db	0Dh
		db	" Vergleich mit"
		db	0Dh
		db	0Dh
		db	0A0h
		call	ANZ5
MVERG1:		in	a, (PIO_DB)
		res	4, a
		set	3, a
		out	(PIO_DB), a
		call	LEEZ
		call	TIME_
		call	ZVEIN
		call	LADEN
		xor	a
		ld	(FZ), a
MVERG2:		in	a, (PIO_DA)
		ld	(LESEZ), a
		cp	(hl)
		call	nz, E3
		call	AZINC
		call	ZYEND
		jr	z, MVERG3
		inc	hl
		inc	bc
		jr	MVERG2
;
MVERG3:		call	UDDOF
		call	cprst7
		db	0Dh
		db	0Dh
		db	0Dh
		db	" OK"
		db	0A0h
		CALL	CCONIN
		jp	MODE
;
;*****************************
;REKURSIVE FUNKTIONEN
;Modus 5..6
;
MREK:		cp	'7'
		jp	nc, MRET	; Mode > 6 ist nicht erlaubt
		cp	'6'             ; Fortsetzen
		jr	nz, MWIED
; Modus 6 - Fortsetzen
		or	a		;ERZEUGEN DES FOLGEPARAMETERS
		ld	hl, (eprom_bis)
		ld	bc, (eprom_von)
		sbc	hl, bc		;HL=GROESSE DES ZUVOR
		ld	bc, (ramadr)	;BEARBEITETEN SPEICHERBEREICHS-1
		inc	hl
		add	hl, bc		;HL=NEUE RAM-ADRESSE
		ld	(ramadr), hl	;NEUE <-> ALTE RAMADR.
; Modus 5 - Wiederholen
MWIED:		ld	a, (KENNZ)
		cp	'1'
		jp	z, MLES1
		cp	'2'
		jp	z, MTAB2
		cp	'3'
		jp	z, MVERG1
		cp	'4'
		jp	z, LTEST
		jp	MODE
;
;*****************************
;UP-FEHLERROUTINE 3
;
E3:		ld	a, (FZ)
		or	a
		jr	nz, ME31
		call	cprst7
		db	0Ch
		db	0Dh
		db	0Dh
		db	"     ungleiche Zellen:"
		db	0Dh
		db	0Dh
		db	0Dh
		db	"   EPROM            RAM"
		db	0Dh
		db	0Dh
		db	" Adr.  Inh.      Adr.  Inh."
		db	0Dh
		db	0Dh
		db	0A0h
ME31:		push	hl
		push	bc
		pop	hl
		call	COUTHL
		call	cprst7
		db	"  "
		db	0A0h
		ld	a, (LESEZ)
		call	COUTHX
		call	cprst7
		db	"      "
		db	0A0h
		pop	hl
		call	COUTHL
		call	cprst7
		db	"  "
		db	0A0h
		ld	a, (hl)
		call	COUTHX
		call	cprst7
		db	0Dh
		db	0A0h
		ld	a, 0FFh
		ld	(FZ), a
		CALL	CCONIN
		cp	3		; STOP-Taste gedrueckt?
		jp	z, MODE
		ret
;
;*****************************
;AUSSCHRIFTEN
;
pr_bereich:	call	cprst7
		db	0Ch
		db	0Dh
		db	0Dh
		db	0Dh
		db	" EPROM auf gewaehltem Bereich"
		db	0Dh
		db	0Dh
		db	0A0h
		ret
;*****************************
pr_geloescht:	call	cprst7
		db	"geloescht !"
		db	0Dh
		db	0Dh
		db	0A0h
		ret
;*****************************
pr_nicht_gel:	call	cprst7
		db	"nicht geloescht !"
		db	0Dh
		db	0Dh
		db	0A0h
		ret
;*****************************
ANZ4:		call	cprst7
		db	"trotzdem weiter ? (J/N) "
		db	0A0h	; ÿ
		ret
;*****************************
ANZ5:		call	cprst7
		db	"RAM-Adresse (HEX) ? :"
		db	0A0h	; ÿ
		call	inphex
		ld	(ramadr), hl
		ret
;
;*****************************
;UP-EINSCHALTEN Udd
;
UDDON:		push	af
		in	a, (PIO_DB)
		set	3, a
		out	(PIO_DB), a
		call	TIME_
		pop	af
		ret
;
;*****************************
;UP-AUSSCHALTEN EPROM SPANNUNGEN
;+ ZAEHLERRESET
;
UDDOF:		in	a, (PIO_DB)
		and	0E7h
		out	(PIO_DB), a
		call	TIME_
		res	2, a
		out	(PIO_DB), a
		ld	a, 20h
		out	(PIO_DB), a
		ret
;
;*****************************
;UP-LOESCHTEST
;RUECKERKEHR MIT (FZ)=0
;WENN ALLE ZELLEN DES
;BEREICHS=FFH
;
TESTL:		call	INITE
		xor	a		;A=0
		ld	(FZ), a
		call	ZVEIN
		call	UDDON
		call	LADEN
LTZ1:		in	a, (PIO_DA)
		cp	0FFh
		jr	z, LTZ2
		ld	a, 0FFh
		ld	(FZ), a
LTZ2:		call	AZINC
		call	ZYEND
		ret	z
		inc	bc
		jr	LTZ1
;
;*****************************
;UP-EINGABE IN HL
;
inphex:		ld	hl, (CURSR)
		ld	(SOIL), hl
inhex1:		CALL	CCONIN
		cp	3		; STOP-Taste gedrueckt?
		jp	z, MODE
		call	ccoout
		cp	0Dh		; ENTER-Taste gedrueckt?
		jr	nz, inhex1
		ld	de, (SOIL)
		CALL	CINHEX
		ret
;
;*****************************
;UP-ZAEHLERVOREINSTELLUNG
;
ZVEIN:		in	a, (PIO_DB)
		res	2, a
		out	(PIO_DB), a
		set	2, a
		out	(PIO_DB), a	;ZAEHLERRESET
		or	a
		ld	bc, (eprom_von)
MZVES:		ld	hl, 0
		adc	hl, bc
		jr	z, ENDEV	;ENDE VOREINST.
		call	AZINC		;ADRESSZ.INC
		dec	bc		;SCHLEIFENZ.DEC
		jr	MZVES
ENDEV:		ret
;
;*****************************
;UP-WEITERZAHLEN EPROM-ADRESSZAEHLER
;
AZINC:		in	a, (PIO_DB)
		set	0, a		;LH-FLANKE BIT 0 (Tv-EINGANG D193)
		out	(PIO_DB), a
		res	0, a		;HL-FLANKE
		out	(PIO_DB), a
		ret
;
;*****************************
;UP-LOESCHTEST MIT AUSSCHRIFTEN
;
LTMA:		call	pr_bereich	;CLS+AUSSCHRIFT "EPROM...."
		call	TESTL
		ld	a, (FZ)
		or	a
		jp	z, loc_088B
		call	pr_nicht_gel	;AUSSCHRIFT "NICHT GELOESCHT"
		jr	loc_088E
loc_088B:	call	pr_geloescht	;AUSSCHRIFT "GELOESCHT"
loc_088E:	call	UDDOF
		ret
;
;*****************************
;DATENPORT-INITIALISIERUNG
;*****************************
;
INITA:		ld	a, 0CFh
		out	(PIO_STA), a
		xor	a
		jr	INITM
;
INITE:		ld	a, 0CFh
		out	(PIO_STA), a
		ld	a, 0FFh
INITM:		out	(PIO_STA), a
		ret
;
;CRC-Berechnung
;vgl. FA
;
;*******************************
;UP-BERECHNUNG CRC-REST
;
CRC:		call	UDDOF
		or	a
		ld	hl, (eprom_bis)
		ld	bc, (eprom_von)
		sbc	hl, bc
		ld	b, h
		ld	c, l
		inc	bc
		ld	hl, (ramadr)
		ld	de, 0FFFFh
;
CRC1:		ld	a, (hl)
		xor	d
		ld	d, a
		rrca
		rrca
		rrca
		rrca
		and	0Fh
		xor	d
		ld	d, a
		rrca
		rrca
		rrca
		push	af
		and	1Fh
		xor	e
		ld	e, a
		pop	af
		push	af
		rrca
		and	0F0h
		xor	e
		ld	e, a
		pop	af
		and	0E0h
		xor	d
		ld	d, e
		ld	e, a
		inc	hl
		dec	bc
		ld	a, b
		or	c
		jr	nz, CRC1
;		
		ld	h, d
		ld	l, e
		call	cprst7
		db	0Dh
		db	0Dh
		db	"CRC-CHECK:"
		db	0A0h
		call	COUTHL
		call	cprst7
		db	0Dh
		db	0Dh
		db	"OK"
		db	0Dh
		db	8Dh
		CALL	CCONIN
		ret


;-------------------------------------------------
; Anpassung der Z1013-Routinen an Z9001
;-------------------------------------------------

;
; Ausgabe bis Bit7 gesetzt
;
cprst7:		EX	(SP),HL		;Adresse hinter CALL
PRS1:		LD	A,(HL)
		INC	HL
		PUSH	AF
		AND	07FH
		CALL	ccoout
		POP	AF
		BIT	7,A		;Bit7 gesetzt?
		JR	Z,PRS1		;nein
		EX	(SP),HL		;neue Returnadresse
		RET
;
;Ausgabe A
;
ccoout:		PUSH	AF
		CALL	OUTA
		pop	AF
		CP	0DH
		RET	NZ
		PUSH	AF
		LD	A,0AH
		CALL	OUTA
		POP	AF
		ret
;
;Eingabe A
;
cconin:		PUSH	BC
		push	de
		push	hl
		CALL	CONIN
		POP	hl
		POP	de
		POP	BC
		ret


;
;letzen vier Zeichen im Buffer ab DE als Hexzahl konvertieren
;und in DATA ablegen
;
KONVX:		LD	A,(DE)		;fuehrende Leerzeichen ueberlesen
		CP	' '
		JR	NZ,KON0
		INC	DE
		JR	KONVX
;
KON0:		XOR	A
		LD	HL,DATA
		LD	(HL),A		;DATA=0
		INC	HL
		LD	(HL),A
KON1:		LD	A,(DE)
		DEC	HL
		SUB	30H		;Zeichen<"0"?
		RET	M
		CP	0AH		;Zeichen<="9"?
		JR	C,KON2
		SUB	7
		CP	0AH		;Zeichen<"A"?
		RET	M
		CP	10H		;Zeichen>"F"?
		RET	P
KON2:		INC	DE		;Hexziffer eintragen
		RLD
		INC	HL
		RLD
		JR	KON1		;naechste Ziffer
;
;Konvertierung ASCII-Hex ab (DE) --> (HL)
;
CINHEX:		PUSH	BC
		CALL	KONVX		;Konvertierung
		LD	B,H		;BC=HL=DATA+1
		LD	C,L
		LD	L,(HL)		;unteres Byte
		INC	BC
		LD	A,(BC)
		LD	H,A		;oberes Byte
		OR 	L		;Z-Flag setzen
		POP	BC
		RET
;
;Ausgabe (A) hexadezimal
;
COUTHX:		PUSH	AF
		RRA
		RRA
		RRA
		RRA
		CALL	OUX1		;obere Tetrade ausgeben
		POP	AF		;und die untere
OUX1:		PUSH	AF
		AND	0FH
		ADD	A,30H		;Konvertierung --> ASCII
		CP	':'		;Ziffer "A" ... "F"?
		JR	C,OUX2		;nein
		ADD	A,7		;sonst Korrektur
OUX2:		CALL	ccoout		;und Ausgabe
		POP	AF
		RET
;
;Ausgabe HL hexadezimal
;
COUTHL:		PUSH	AF
		LD	A,H
		CALL	COUTHX
		LD	A,L
		CALL	COUTHX
		POP	AF
		RET

		end	start
