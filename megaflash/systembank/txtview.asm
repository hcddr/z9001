;------------------------------------------------------------------------------
; Z9001 MEGA-FLASH-Modul (2.5M-Modul)
; (c) V. Pohlers 2012
; letzte Änderung 30.03.2012 11:11
;------------------------------------------------------------------------------
; Systembank: Text-Anzeige
;------------------------------------------------------------------------------

		cpu	z80


BOS		equ	0F314h		; orig. Call 5
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H

COOUT		EQU	0F00Ch



COLSW:		EQU	17H		;PUFFER FARBSTEUERCODE

rst_sbos	equ	28h		;der RST für den Sprungverteiler
;;	0	;OUTHX	Ausgabe (A) hexa
;;	1	;OUTHL	Ausgabe (HL) hexa
;;	2	;WAIT	Unterbrechung Lauf
;;	3	;color	Vordergrundfarbe (E)
;;	4	;CPROM	Suchen Namen
;;	5	;FMOV	FA-Programm in Speicher kopieren
;;	6	;FRUN	FA-Programm starten
;;	7	;KDOPAR	Kommandoparameter aufbereiten
;;	8	;INHEX	Konvertierung ASCII-Hex ab (DE) --> (HL)
;;	9	;PRST7	Ausgabe String bis Bit7=1

ROT:    		EQU     0114H
GRUEN:  		EQU     0214H
GELB:   		EQU     0314H
BLAU:   		EQU     0414H
MAGENTA:		EQU     0514H
CYAN:   		EQU     0614H
WHITE:  		EQU     0714H 
BLACK:			EQU	0014h

		org	300h

; Anzeige Text von (aadr) bis max. (eadr)

		jp	new
		db	"PAGE    ",0
		db	0

;------------------------------------------------------------------------------

aadr:		dw first_aadr		; Anfangsadr. Text
;
;
curr:		dw first_aadr		; aktuelle Position
top:		dw first_aadr		; 1. Adr. der angezeigten Seite (top of page)

first_aadr	equ 800h


;------------------------------------------------------------------------------
; Neustart
;------------------------------------------------------------------------------
new:
		ld	hl,first_aadr
		ld	(aadr),hl

;------------------------------------------------------------------------------
		
new0:		ld	hl, (aadr)
		ld	(curr),	hl
		ld	(top),	hl
		
		call	cls
		ld	de, txt_init
		ld	c, 9
		call	5

;------------------------------------------------------------------------------
		
tast:		LD	C,1		; CONSI
		CALL	5

		cp	'N'
		jp	z, new
		cp	' '
		jp	z, fwrd
		cp	9
		jp	z, fwrd
		cp	8
		jp	z, back
		cp	3
		ret	z		; Programmende
		jr	tast

;------------------------------------------------------------------------------

txt_init	dw	ROT
		db "Textviewer V.Pohlers",0Dh,0ah,0ah
		dw	GRUEN
		db "N    =Neustart",0Dh,0ah
		db "SPACE=Vorwaerts",0Dh,0ah
		db "<-   =Rueckwaerts",0Dh,0ah
		db "^C   =Ende",0Dh,0ah,0ah
		dw	WHITE
		;;db	16h			; INV
		db	0
		
txt_ende
		dw	GRUEN
		db 	0dh,0ah,"--Ende--"
		db	0

;------------------------------------------------------------------------------
; Bildschirm löschen
; bei Standard-CRT-Treiber "fast cls"
;------------------------------------------------------------------------------

cls		ld	a, (0004)		; IOBYT
		and	3
		cp	1
		jr	z, fastcls

clsx:		ld	e, 0ch
		ld	c,2
		call	5
		ret

fastcls:	ld	hl, 0ec00h
		ld	de, 0ec01h
		ld	bc, 40*24-1
		ld	(hl), ' '
		ldir
		ld	de, 0101h
		ld	c,18			; SETCU
		call	5
		ret

;------------------------------------------------------------------------------
; Rueckwaerts
;------------------------------------------------------------------------------
back:
		ld	hl, (top)
		ld	de, 300h		; Textlänge beim Rückwärtsblättern
		sbc	hl, de
		;
		ld	de, (aadr)		; aadr unterschritten ??
		jr	c, back1
		push	hl
		scf
		sbc	hl, de
		pop	hl
		jr	nc, back2		; dann bis aadr zurück
back1:		ld	(curr),	de
		jr	fwrd
back2:		ld	a,(hl)
		cp	' '
		jr	nc, back3
		inc	hl
		jr 	back2
back3		ld	(curr),	hl		; sonst auf top-300h

;------------------------------------------------------------------------------
; Vorwaerts
;------------------------------------------------------------------------------
fwrd:		call	cls
		ld	hl, (curr)
		ld	(top), hl
;
fwrd1:		ld	a, (hl)
		cp	0Ch			; CLS -> 00
		jr	nz, fwrd2
		ld	a, 0
fwrd2:		

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

outch:		push	hl
		ld	c, a
		LD	A,(COLSW)
		push	AF
		call	COOUT
		pop	AF
		pop	hl

		; if (colsw) <> 0 then weiter (aktuelles Zeichen ist Farbwert)
    		OR	A
		jr	nz, outch1		;KEIN FARBCODE

		; Ende bei 00h oder 03h
		ld	a,(hl)
		cp	0
		jr	z,out_ende
		cp	3
		jr	z,out_ende

outch1:		inc	hl			; sonst nächste Zeichenadr.
		;
		ld	c, 17
		call	5			; GETCU
		ld	a, D			; Zeile
		cp	24
		jp	z, tast			; letzte Zeile
		cp	23
		jr	nz, fwrd1
		ld	a, E
		cp	1
		jr	nz, fwrd1
		;
		ld	(curr),	hl
		jr	fwrd1

; Textende erreicht -> wieder auf Anfang setzen
out_ende:	ld	de, txt_ende
		ld	c,9
		call	5

		LD	C,1		; CONSI
		CALL	5
		
		jp	new0


;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------


		end

; test:
		org	first_aadr

		db	"Kanal A ist auf BIT Ein-/Ausgabe initialisiert, Kanal B auf",0dh,0ah
		db	"Ausgabe. Auf Kanal B wird 0 ausgegeben, d.h., alle Leitungen",0dh,0ah
		db	"sind 'LOW'. Ist keine Taste gedrückt, so sind alle Leitungen",0dh,0ah
		db	"von Kanal A auf Grund der Ziehwiderstände 'HIGH'. Wird eine",0dh,0ah
		db	"Taste gedrückt, so ist eine Leitung von A mit einer Leitung",0dh,0ah
		db	"von B verbunden, und es wird ein Interrupt ausgelöst, da eine",0dh,0ah
		db	"Leitung von A LOW-Pegel führt. Jetzt werden die Kanäle uminitialisiert,",0dh,0ah
		db	"die von A gelesene Information wird auf A wieder",0dh,0ah
		db	"ausgegeben und auf Kanal B führt jetzt nur die der gedrückten",0dh,0ah
		db	"Taste entsprechende Leitung LOW-Pegel.",0dh,0ah
		db	"",0dh,0ah
		db	"",0dh,0ah
		db	"EA-Adressen Z9001",0dh,0ah
		db	"",0dh,0ah
		db	"Adresse Verwendung Details",0dh,0ah
		db	"00-7Fh frei",0dh,0ah
		db	"80-87 CTC",0dh,0ah
		db	"88-8F PIO1",0dh,0ah
		db	"90-97 PIO2 (Tastatur)",0dh,0ah
		db	"98-A7 Musikmodul für KC87 als frei deklariert",0dh,0ah
		db	"A8-B7 Druckermodule CTC A8-AB, SIO B0-B4",0dh,0ah
		db	"B8-C7 frei",0dh,0ah
		db	"C8-CF E/A-Modul C8-CB oder CC-CF (umschaltbar)",0dh,0ah
		db	"D0-D7 Programmiermodul",0dh,0ah
		db	"D8-DF frei",0dh,0ah
		db	"E0-EF Spracheingabemodul",0dh,0ah
		db	"F0-F7 frei",0dh,0ah
		db	"F8-FF ADU-Modul FC, FD, F8-FB",0dh,0ah
		db	"--",0dh,0ah
		db	"04-07 CPM-RAM-Modul",0dh,0ah
		db	"10-12 CPM-Floppy-Modul Rossendorf-Version",0dh,0ah
		db	"98-A7 CPM-Floppy-Modul Robotron-Version",0dh,0ah
		db	"B8-BA Grafikzusatz",0dh,0ah
		db	"",0dh,0ah
		db	"BASIC Farbspeicher binär Farbe",0dh,0ah
		db	"1 0 000 schwarz",0dh,0ah
		db	"2 1 001 rot",0dh,0ah
		db	"3 2 010 grün",0dh,0ah
		db	"4 3 011 gelb",0dh,0ah
		db	"5 4 100 blau",0dh,0ah
		db	"6 5 101 purpur (violett)",0dh,0ah
		db	"7 6 110 cyan (hellblau)",0dh,0ah
		db	"8 7 111 weiss",0dh,0ah
		db	"",0dh,0ah
		dw	BLACK
		db	"System-OS",0dh,0ah
		dw	GELB
		db	"",0dh,0ah
		db	"chr(6) - Blinken ein/aus, chr(22) - Invers ein/aus",0dh,0ah
		db	"",0dh,0ah
		db	"Alle nach CHR$(6) ausgegebenen Zeichen erscheinen blinkend auf dem Bildschirm",0dh,0ah
		db	"(für sie wird das Blinkbit im Farbspeicher gesetzt). Nach nochmaliger Ausgabe",0dh,0ah
		db	"von CHR$(6) werden alle danach ausgegebenen Zeichen wieder normal dargestellt.",0dh,0ah
		db	"Analoges gilt für CHR$(22), die Zeichen werden dann invers (mit vertauschten",0dh,0ah
		db	"Vorder- und Hintergrundfarben) ausgegeben.",0dh,0ah
		db	"",0dh,0ah
		db	"Port 136 (s. S. 131)",0dh,0ah
		db	"",0dh,0ah
		db	"Über die PIO 1, Kanal A, Adresse 136=88h, sind der Farbcode für den",0dh,0ah
		db	"Bildschirmrand, der 20/24-Zeilen-Modus und die Ansteuerung von Grafikmodus und",0dh,0ah
		db	"Summerton (BEEP) codiert.",0dh,0ah
		db	"		",0dh,0ah
		db	03h

		end
