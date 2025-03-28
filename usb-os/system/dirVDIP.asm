;-----------------------------------------------------

	cpu	Z80

;;	org	300h
;;	
;;	JP	usbkdo
;;	DB	"DIR     ",0
;;	DB	0		

;------------------------------------------------------------------------------

CHARP:		EQU	2BH		;ZEIGER AUF SPALTE
PARBU:		EQU	0040H		;HILFSZELLE (wird nur von ALDEV genutzt)
;;CONBU		equ	080h		; interner Zeichenkettenpuffer Kommandozeile
INTLN:		equ	0100h		; interner Zeichenkettenpuffer

memry		equ	INTLN+20h	; INTLN Puffer

; BDOS
CSTS:		equ	0F006h		;STATUS CONST
CONSI:		equ	0F009h		;EINGABE ZEICHEN VON CONST
OCRLF:		EQU	0F2FEH
;OUTA:		EQU	0F305H
;;OSPAC:		EQU	0F310H
PRNST		EQU	0F3E2H

GVAL    	EQU	0F1EAh

HLSV		EQU	01BEh		;erster Eintrag im BOS-Stack

;------------------------------------------------------------------------------
; DIR [suchstring]
;------------------------------------------------------------------------------

;PARBU	Bit 7 = 1 Suchmuster in INTLN+1
;PARBU	Bit 6 = 1 keine Ext. anzeigen
;PARBU	Bit 5 = 1 Ablegen in Speicher ab HL
;		je 13 Byte 1. Byte Typ (D ir/F ile), 12 Byte Name Format 8+3


dirkdo:		;Parameterauswertung
		xor	a			; A=0 ohne Parameter
		ld	(PARBU),a

		;; call	GVAL			; GVAL wurde in GOCPM schon aufgerufen (f. Kommandoname)
		ex	af,af'			; Cy'=1 kein weiterer Parameter in CONBU
		jr	c,dirkdo0		; wenn kein Parameter
		; Parameter Suchstr 
		call	GVAL
		xor	a
		cp	b			; L�nge = 0?
		jr	z, dirkdo0
;		
dirkdoz:	ld	hl,PARBU
		set	7,(hl)			;merken, dass Suchmuster �bergeben wurde
;
dirkdo0:	ld	a,(PARBU)		;Anzeigemodus
		bit	5,a			;Ablegen in Speicher?
		jr	z,dirkdo0a		;nein
		; sonst Ablage init
		ld	hl,(HLSV)
		ld	(HL),0

dirkdo0a:	call	vdip_init	; Synchronisation
		jp	c,exit
        	
		LD	A,SCS		; Short CMD-Modus
		CALL	PUT
		CALL	EXEC
		jp	c,exit		; Error
        	
		LD	A,IPH		; HEX- bzw. BIN-Modus
		CALL	PUT
		CALL	EXEC
		jp	c,exit		; Error
        	
		call	exec		; Flash-Disk vorhanden?
		jp	c,exit

; DIR-Kommando ausfuehren:

		ld	a,dir		; DIR
		call	put
		ld	a,cr		; ohne Parameter
		call	put
		call	get		; Enter holen
		jp	c,exit		; Fehler
	
rda:		ld	hl,memry
		ld	(hl),'F'	; default typ 'F' File
		inc	hl

		call	rd1		; Name holen
		jp	c, exit
		;

		call	setcolor
;Pseudo-DIR '.' oder '..'?		
		ld	hl,memry+1
		ld	a,(hl)
		cp	'.'		 
		jr	z,rda

; Dateiname liegt im Buffer und kann ausgewertet werden	
rd2:		
		;Namensvergleich
		ld	a,(PARBU)		;Anzeigemodus
		bit	7,a			;mit Suchstring?
		jr	z,rd3			;nein
		;ld	hl,memry+1
		ld	de, INTLN+1		;Suchmuster		
		call 	pmatch			;suchen
		jr 	c,rda			;nicht gleich, als nix anzeigen
		
; VDIP liefert "8.3"+00, bei Dir wird " DIR" angeh�ngt
; 0120   2E 20 44 49 52 00 00 00 00 00 00 00 00 00 00 00   . DIR...........
; 0120   2E 2E 20 44 49 52 00 00 00 00 00 00 00 00 00 00   .. DIR..........
; 0120   41 53 4D 38 37 2E 43 4F 4D 00 00 00 00 00 00 00   ASM87.COM.......
; ...
; 0120   00 53 54 2E 43 4F 4D 00 41 53 4D 00 00 00 00 00   .ST.COM.ASM.....
		
rd3:
		ld	a,(PARBU)		;Anzeigemodus
		bit	5,a			;Ablegen in Speicher?
		jr	nz,rdhl			;ja

; Anzeige: max 12 Zeichen: "8.3" oder "8 DIR"
;name
		ld	hl,memry+1
		ld	b,8
rd4:		call 	nxtch1
rd5:		call	outa
		djnz	rd4
		call	ospac

		ld	a,(PARBU)		;Anzeigemodus
		bit	6,a			;keine Extention anzeigen?
		jr	nz,rd7
;erw    	
		ld	b,3
		ld	a,(hl)
		cp	30h		;Punkt o. Leerzeichen?
		jr	nc, rd6
		inc	hl		;�bergehen
rd6:		call 	nxtch1	
		call	outa
		djnz	rd6
		call	ospac
;
rd7:		call	wait		; Pause?
		ret	c
;n�chsten Namen
		ld	a,(CHARP)
		cp	3*12		; max. 3 spaltige Anzeige
		call	nc,ocrlf	; neue Zeile
		jr	rda

;------------------------------------------------------------------------------

; Einlesen Dateiname nach HL
rd1:		ld	(hl),0		; Ende - 0 Byte f. Stringausgabe
		call	get		; Zeichen holen
		ret	c		; Fehler
		cp	'>'
		scf
		ret	z		; Prompt erkannt -> Anzeige
		cp	0dh		; neue Zeile
		;jr	z,rd2
		ret	z
		;CALL	OUTA		;AUSGABE
		ld	(hl),a		; Zeichen in Buffer ablegen
		inc	hl
		jr	rd1		; weiter

;------------------------------------------------------------------------------
; Ablegen in Speicher
rdhl:		ld	hl,memry
		ld	a,0
rdhl1:		inc	hl
		cp	(hl)		; Ende?
		jr	nz,rdhl1
; HL steht auf 00-Byte hinter Dateiname
		call chkdir		; Test auf " DIR"
		jr	nz,rdhl2
		ld	a,'D'
		ld	(memry),a	; typ 'D' Dir
rdhl2:		
; und nach (HLSV) kopieren
		ld	hl,memry
		ld	de,(HLSV)
rdhl3:		ld	a,(hl)
		ldi
		cp	0
		jr	nz, rdhl3
		ld	(HLSV),de
		ld	(de),a		; abschlie�endes 0-Byte schreiben
		jp	rda

;------------------------------------------------------------------------------
;
;n�chstes Zeichen aud Puffer holen, Trenner und Ende beachten
nxtch1:		ld	a,(hl)
		or	a		; Stringende?
		jr	z,nxtch2
		cp	'.'		; Dateityp-Trenner
		jr	z,nxtch2
		cp	' '		; DIR Trenner
		ret	z
		inc	hl		; sonst
		ret
nxtch2:		ld	a,' '
		ret	
;------------------------------------------------------------------------------
; Ende
exit:		ld	a,(PARBU)	;Anzeigemodus
		bit	5,a		;Ablegen in Speicher?
		call	z,ocrlf
		call	z,c_gruen
		call	deinit		; Treiber deaktivieren
		xor	a
		ret

;------------------------------------------------------------------------------
; Dateityp auswerten und Farbe setzen
; DIR	gelb
; COM	Gr�n
; ZBS	wei�
; HLP	??
; sonstige cyan

setcolor:	ld	a,(PARBU)	;Anzeigemodus
		bit	5,a		;Ablegen in Speicher?
		ret	nz		;ja, dann keine Farbe

		;HL steht hinter Dateiname, also 4 Zeichen zur�ck
		dec	hl
		ld	a,(hl)
		dec	hl
		cp	'M'
		jr	z,sc_com
		cp	'S'
		jr	z,sc_zbs
		cp	'R'
		jr	z,sc_DIR
		;
sc0:		jp	c_cyan		; sonstige cyan

sc_com:		ld	a,'O'
		cp	(hl)
		jr	nz,sc0
		dec	hl
		ld	a,'C'
		jr	nz,sc0
		jp	c_gruen

sc_zbs:		ld	a,'B'
		cp	(hl)
		jr	nz,sc0
		dec	hl
		ld	a,'Z'
		jr	nz,sc0
		jp	c_white

sc_dir:		ld	a,'I'
		cp	(hl)
		jr	nz,sc0
		dec	hl
		ld	a,'R'
		jr	nz,sc0
		jp	c_gelb

;------------------------------------------------------------------------------
; Stringsuche mit einfachen Wildcards '*' und '?'
; vp120209
; hl = Text, der untersucht wird, nullterminiert
; de = Suchmuster mit '?' und '*', nullterminiert

; 30.04.2015 das war doch tats�chlich nicht 100% korrekt: 
; bei FA-Rahmen muss der Text nicht nullterminiert sein, sondern ist max. 8 Zeichen lang!

pmatch:		ld	b,12	
pmatch0:	ld	a,(hl)			; Test auf Stringende
		or	a			; a=0?
		scf
		ret	z			; Cy=1 nicht gefunden
		push	hl
		push	de
		push	bc
		call 	match			; 
		pop	bc
		pop	de
		pop	hl
		ret	nc			; Cy=0 gefunden
		inc	hl
		dec	b			; max 8 Stellen
		ret	z
		jr	pmatch0

;------------------------------------------------------------------------------
; Stringvergleich mit einfachen Wildcards '*' und '?'
; vp120209
; hl = Text, der untersucht wird, nullterminiert
; de = Suchmuster mit '?' und '*', nullterminiert
; ret: Cy=0 match
; Cy=1 kein match

match:		ld	a, (de)			; Suchmuster Ende?
		or	a			; =0?
		ret	z			; dann fertig mit Cy=0
;		
		ld	b, a			; Suchmuster Zeichen merken
		cp	'*'
		jr	nz, match2
; wildcard '*'		
; �berlesen der Zeichen im Text
		inc	de
		ld	a, (de)			; Suchmuster Zeichen hinter '*'
		or	a
		ret	z			; dann fertig mit Cy=0
		ld	c, a
		
match1		ld	a, (hl)			; Text Ende?
		or	a			; =0?
		scf
		ret	z			; dann fertig mit Cy=1

		cp	c			; Vergleich mit Text
		inc	hl
		jr	nz, match1
		jr	match4			; n�chste Zeichen

; Wildcard '?' oder direktes Zeichen
match2		ld	a, (hl)			; Text Ende?
		or	a			; =0?
		scf
		ret	z			; dann fertig mit Cy=1

		cp	b			; Vergleich mit Text
		jr	z, match3
		ld	a,'?'			; oder Wildcard '?'
		cp	b
		jr	z, match3

		scf
		ret				; kein match, Cy=1

match3		inc	hl			; n�chste Position im Text
match4		inc	de
		jr	match			; Vergleiche n�chste Zeichen

; -----------------------------------------------------------------------------
;
;WAIT Unterbrechung Programm, wenn <PAUSE> gedrueckt,
;     weiter mit beliebiger Taste
;
WAIT:		CALL	CSTS			;Abfrage Status
		OR	A
		RET	Z			;keine Taste gedrueckt
		CALL	CONSI			;Eingabe
		CP	A, 03H			;<STOP>?
		;;JP	Z, GOCPM
		jr	z,wait0
;
		CP	A, 013H			;<PAUSE>?
		jp	z, CONSI		; 1 Byte sparen
		xor	a			;nein
		RET
;Ende
wait0:		;call	deinit
;		ld	hl,(200h-2)		;GOCPM
;		jp (hl)
;;

		call	deinit
		ld	a,0ffh
		scf
		ret

;;Farben
;c_rot		ld	e,1
;		jr	color
c_gruen		ld	e,2
		jr	color
c_gelb		ld	e,3
		jr	color
;c_blau		ld	e,4
;		jr	color
;c_magenta	ld	e,5
;		jr	color
c_cyan		ld	e,6
		jr	color
c_white		ld	e,7
;
color		ld	a,14h
		call	outa
		ld	a,e
		;call	outa
		;ret
		jp	outa	; 1 Byte sparen

;------------------------------------------------------------------------------
; CD [verzeichnis]
;------------------------------------------------------------------------------


cdkdo:
		;; call	GVAL			; GVAL wurde in GOCPM schon aufgerufen (f. Kommandoname)
		ex	af,af'			; Cy'=1 kein weiterer Parameter in CONBU
		jr	c,cdkdo0		; wenn kein Parameter
; mit Parameter: Wechsel ins Verzeichnis
cdkdob1:		ld	HL, "DC"	; 'CD' restaurieren wurde von GVAL gel�scht
		ld	(CONBU+2), HL
		jp	usbkdo		; Wir nutzen einfach "USB CD xxx"

;ohne Parameter: Anzeige m�glicher Verzeichnisse
cdkdo0:		call	vdip_init	; Synchronisation
		jp	c,exit
        	
		LD	A,SCS		; Short CMD-Modus
		CALL	PUT
		CALL	EXEC
		jp	c,exit		; Error
        	
		LD	A,IPH		; HEX- bzw. BIN-Modus
		CALL	PUT
		CALL	EXEC
		jp	c,exit		; Error
        	
		call	exec		; Flash-Disk vorhanden?
		jp	c,exit

; DIR-Kommando ausfuehren:

		ld	a,dir		; DIR
		call	put
		ld	a,cr		; ohne Parameter
		call	put
		call	get		; Enter holen
		jp	c,exit		; Fehler
	
cda:		ld	hl,memry
cd1:		call	get		; Zeichen holen
		jp	c,exit		; Fehler
		cp	'>'
		jp	z,exit		; Prompt erkannt -> Anzeige
		cp	0dh		; neue Zeile
		jr	z,cd2
		;CALL	OUTA		;AUSGABE
		ld	(hl),a		; Zeichen in Buffer ablegen
		inc	hl
		jr	cd1		; weiter
; Dateiname liegt im Buffer und kann ausgewertet werden	
cd2:		call chkdir
		jr	nz,cda
; DIR gefunden, anzeigen
		ld	de,memry
		;ld	c,9
		;call 	5		; call 5 geht hier nicht wg. CHDIR
		call	PRNST
		call	OSPAC
;n�chsten Namen
		ld	a,(CHARP)
		cp	3*12		; max. 3 spaltige Anzeige
		call	nc, ocrlf	; neue Zeile
		jr	cda

; Test auf " DIR"
; ret: NZ kein DIR
chkdir:
		dec	hl
		ld	a,(hl)
		cp	'R'
		ret	nz
		dec	hl
		ld	a,(hl)
		cp	'I'
		ret	nz
		dec	hl
		ld	a,(hl)
		cp	'D'
		ret	nz
		dec	hl
		ld	a,(hl)
		cp	' '		;Trennzeichen DIR?
		ret	nz
		xor	a		;A=0; Z=1
		ld	(hl),a		;Stringende einf�gen
		ret
		
; -----------------------------------------------------------------------------

;	end
