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
dirkdoz:	ld	hl,PARBU
		set	7,(hl)			;merken, dass Suchmuster �bergeben wurde
;
dirkdo0:	ld	a,(PARBU)		;Anzeigemodus
		bit	5,a			;Ablegen in Speicher?
		jr	z,dirkdo0a		;nein
		; sonst Ablage init
		ld	hl,(HLSV)
		ld	(HL),0

dirkdo0a:
	ld	hl, memry
		ld	(hl),'F'	; default typ 'F' File
		inc	hl
	call	usb__dir_start
	jp	nz, exit
	jr	rd2
rda:	ld	hl, memry + 1
	call	usb__dir_continue
	jp	nz, exit
rd2:	ld	hl, memry + 12
				; Dateiname liegt im Buffer und kann ausgewertet werden	
		ld	(hl),0		; Ende - 0 Byte f. Stringausgabe
		call	setcolor
;Pseudo-DIR '.' oder '..'?		
		ld	hl,memry + 1
		ld	a,(hl)
		cp	'.'		 
		jr	z,rda
;Namensvergleich
		ld	a,(PARBU)		;Anzeigemodus
		bit	7,a			;mit Suchstring?
		jr	z,rd3			;nein
		;ld	hl,memry+1
		ld	de, INTLN+1		;Suchmuster		
		call 	pmatch			;suchen
		jr 	c,rda			;nicht gleich, als nix anzeigen
; Anzeige: max 12 Zeichen: "8.3" oder "8 DIR"
;name
rd3:		ld	a,(PARBU)		;Anzeigemodus
		bit	5,a			;Ablegen in Speicher?
		jr	nz,rdhl			;ja

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
		ld	hl, memry + 9 
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
exit:		call	c_gruen
		call	ocrlf
		xor	a
		ret

;------------------------------------------------------------------------------
; Dateityp auswerten und Farbe setzen
; DIR	gelb
; COM	Gr�n
; ZBS	wei�
; HLP	??
; sonstige cyan

setcolor:	;HL steht hinter Dateiname, also 4 Zeichen zur�ck
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
	ld	de, CONBU+2	;Pfadnamen direkt aus Konsolenbuffer holen
	call	SPACE		;Leerzeichen �bergehen
	push	de
	ld	b, 0		;L�nge des Pfadnamens ermitteln und in B speichern
cdkdo0:	ld	a, (de)
	cp	' '		;Ende bei Leerzeichen
	jr	z, cdkdo1
	cp	0		;Ende bei NULL
	jr	z, cdkdo1
	inc	b		;L�nge und String Pointer erh�hen
	inc	de
	jr	cdkdo0		;Weitersuchen bis Ende
cdkdo1:
	pop	de		;Anfangsadresse des Pfadnamens wiederherstellen
	ld	c, 32		;BOS Systemruf CHDIR
	ld	a, b		;Wenn L�nge gleich Null, dann List directories
	call	5		;BOS
	xor	a		;Fehlerbehandlung durch BOS
	ret

; -----------------------------------------------------------------------------
