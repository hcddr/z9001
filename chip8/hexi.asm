
		cpu	z80

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

;OS-Notizspeicheradressen
DMA:	EQU	01BH	;Zeiger auf Kassettenpuffer
FCB:	EQU	05CH	;Filecontrolblock
FNAME:	EQU	FCB	;Dateiname
FTYP:	EQU	FCB+8	;Dateityp
BLNR:	EQU	FCB+15	;Blocknummer		; wird hier als adr missbraucht !
LBLNR:	EQU	FCB+16	;gesuchte Blocknr.
AADR:	EQU	FCB+17	;Anfangsadresse
EADR:	EQU	FCB+19	;Endadresse
SADR:	EQU	FCB+21	;Startadresse
CONBU:	EQU	080h	;Eingabepuffer

ATRIB		equ	0027h		; aktuelles Farbattribut
P1ROL		equ	003Bh		; 1. rollende Zeile - 1
P2ROL		equ	003Ch		; letzte zu rollende Zeile + 1
P3ROL		equ	003Dh		; 1. zu rollende Spalte - 1
P4ROL		equ	003Eh		; letzte zu rollende Spalte + 1

; bws(zeile 1..24, spalte 1..40) analog print_at
bws1		function z,s,(z-1)*40+(s-1)+0EC00h
bwsc1		function z,s,(z-1)*40+(s-1)+0E800h

;
;OS-Routinen
CBOS:	EQU	05H	;zentraler BOS-Ruf
GVAL:	EQU	0F1EAH	;Parameter holen
OCRLF:	EQU	0F2FEH
OUTA:	EQU	0F305H
OSPAC:	EQU	0F310H
PRNST:	EQU	0F3E2H	;Stringausgabe
MOV:	EQU	0F588H
ERINP:	EQU	0F5E2H	;Eingabefehler
ERPAR:	EQU	0F5E6H	;Parameterfehler
;
;CBOS-Rufe
CONSI:	EQU	1	;CONST-Eingabe
CONSO:	EQU	2	;CONST-Ausgabe
GETST 	EQU	6	;Abfrage der Spielbebel

OPENR:	EQU	13	;OPEN READ
DCU 	EQU	29 ;Löschen Cursor
SCU 	EQU	30 ;Setzen Cursor

CR	equ	0dh
LF	equ	0ah

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

		org 	3C00h

		jp	cmd_hexi
		db 	"HEXI    ",0
		db    	0

caddr:		ds 	2		; aktuelle Adresse
cupos:		ds 	2		; aktuelle Bildschirmposition
ccol:		ds 	1		; aktuelle Spalte (0..39 (29) )
cline:		ds 	1		; aktuelle Zeile (0..20)
cuzei:		ds 	1		; Zeichen unter Cursor

;------------------------------------------------------------------------------
; Konvertierung Hex->ASCII
;------------------------------------------------------------------------------

; konvertiere A	hexadezimal nach (HL..HL+1)
conhx:		PUSH	AF
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	.m1
		POP	AF
.m1:		AND	A, 0FH

;		ADD	A, '0'
;		CP	A, 3AH
;		JR	C, .m2
;		ADD	A, 07H

; mit DAA-Trick, 2 Byte kürzer
		add	a, 90h
		daa			
		adc	a, 40h
		daa

.m2:		ld	(hl), a
		inc	hl
		RET

; konvertiere DE hexadezimal nach (HL..HL+4)
conde:		ld	a, d
		call	conhx		; konvertiere A	hexadezimal nach (HL..HL+1)
		ld	a, e
		call	conhx		; konvertiere A	hexadezimal nach (HL..HL+1)
		ld	(hl), ' '
		inc	hl
		ret

;------------------------------------------------------------------------------
; Konvertierung ASCII->HEX
;------------------------------------------------------------------------------

hex1:		sub	'0'
		cp	0Ah
		ccf
		ret	nc
		sub	7
		cp	0Ah
		ret	c
		cp	11h
		ccf
		ret

; (HL..HL+1) zu	Hex-byte konvertieren nach A
hexa:
		ld	a, (hl)
		inc	hl
		call	hex1
		ret	c
		rla
		rla
		rla
		rla
		ld	c, a
		ld	a, (hl)
		inc	hl
		call	hex1
		ret	c
		or	c
		ret

; (HL..HL+3) als 4stellige Hexzahl nach	DE konvertieren
hexde:		call	hexa		; (HL..HL+1) zu	Hex-byte konvertieren nach A
		ret	c
		ld	d, a
		call	hexa		; (HL..HL+1) zu	Hex-byte konvertieren nach A
		ret	c
		ld	e, a

; Test auf Leerzeichen
testsp:		ld	a, ' '
		cp	(hl)
		inc	hl
		ret	z
		scf
		ret

;------------------------------------------------------------------------------
; Eingabe
;------------------------------------------------------------------------------

edit:		ld	hl, (cupos)
		call	hexde		; (HL..HL+3) als 4stellige Hexzahl nach	DE konvertieren
		ret	c
		ld	(caddr), de
		ld	b, 8		; max 8	Byte
		ld	de, CONBU	; Buffer

; Eingabe hex
edit2:		call	hexa
		ret	c

;		
edit3:		ld	(de), a
		inc	de
		call	testsp		; Test auf Leerzeichen
		ret	c
		djnz	edit2
		ld	hl, CONBU	; Buffer
		ld	de, (caddr)
		ld	c, 8
		ldir
		ret

;------------------------------------------------------------------------------
; Anzeigen einer Zeile
;------------------------------------------------------------------------------

line:		ld	de, (caddr)
		ld	hl, (cupos)
		push	de
		call	conde		; konvertiere DE hexadezimal nach (HL..HL+4)
		ld	ix, 0		; Prüfsumme
		ld	b, 8		; 8 Byte pro Zeile
		pop	de
		push	de
line1:		ld	a, (de)
		push	de
		ld	e, a
		ld	d, 0
		add	ix, de		; Prüfsumme berechnen
		pop	de
		call	conhx		; konvertiere A	hexadezimal nach (HL..HL+1)
		inc	de
		ld	(hl), ' '
		inc	hl
		djnz	line1
		pop	de
;
		ld	(hl), ' '
		ret


;------------------------------------------------------------------------------
; Anzeige aktualisieren
;------------------------------------------------------------------------------

disp:		ld	de, (ccol)	; aktuelle Position in Zeile
		ld	d, 0
		ld	hl, (cupos)
		add	hl, de
		ld	a, (hl)
		ld	(cuzei), a	; Zeichen unter Cursor
;
disp1:		ld	a, 0F8h		; Cursor-Symbol
		cp	(hl)
		jr	nz, disp2
		ld	a, (cuzei)	; Zeichen unter Cursor
disp2:		ld	(hl), a
		ld	bc, 100h
disp3:		push	bc

; Taste gedrückt?
		ld	c, 11		; CSTS
		call	5
		pop	bc
		jr	c, disp4	; bei Fehler
		or	a
		jr	nz, disp5	; wenn Taste gedrückt
; nein
disp4:		xor	a
		dec	bc
		or	b
		or	c
		jr	nz, disp3
		jr	disp1
; Taste gedrückt
disp5:		push	bc
		ld	c, 1		; CONSI
		call	5
		pop	bc
		jr	c, disp4	; bei Fehler
		ld	b, a
		ld	a, (cuzei)	; Zeichen unter Cursor
		ld	(hl), a
		ld	a, b
;Cursor left
		cp	8		; Cursor left
		jr	nz, disp7
		ld	a, (ccol)	; aktuelle Position in Zeile
		cp	5		; linker Rand erreicht?
		jr	z, disp1
		dec	a
		dec	hl
disp6:		ld	(ccol),	a	; aktuelle Position in Zeile
		jr	disp		; Anzeige aktualisieren
;Cursor right
disp7:		cp	9		; Cursor right
		jr	nz, disp9
disp8:		ld	a, (ccol)	; aktuelle Position in Zeile
		cp	29		; rechter Rand erreicht?
		jr	nc, disp1
		inc	a
		inc	hl
		jr	disp6
;
disp9:		cp	' '
		ret	c
		ld	(hl), a		;sonst Zeichen übernehmen
		jr	disp8

;------------------------------------------------------------------------------
; Hauptprogramm
;------------------------------------------------------------------------------

cmd_hexi:	call	smallwindw	; Bildschirm löschen
		;call	cls	
		ld	c,DCU
		call	5

		ld	hl,RAMB
		ld	(caddr),hl
		ld	hl, bws1(2,2)
		ld	(cupos), hl
		ld	a,5
		ld	(ccol),a
		ld	a,0
		ld	(cline),a

; main loop
hexi1:		call	line		; Anzeigen einer Zeile
hexi2:		call	disp		; Anzeige aktualisieren
		cp	3		; stop
		jr	z,hexend
		cp	1Bh		; ESC
		jr	z,hexend
		cp	1Dh		; RUN
		jr	z,hexend

;		
		push	af		; in A steht der Tastencode
		sub	0Ah
		and	0FEh
		cp	0Ah		; color + shift-color überspringen 
		jr	z, hexi15	
		call	edit

hexi15:		call	line		; Anzeigen einer Zeile
		pop	af

;Cursor up
		cp	0Bh		; Cursor UP
		jr	nz, hexi19
		ld	hl, (caddr)
		
		;cp RAMB
		ld	de,RAMB
		CALL	0FCBCH		; COMPW		;ADRESSVERGLEICH
		jr	z, hexi1
				
		ld	de, 8
		sbc	hl, de
		ld	(caddr), hl
		ld	a, (cline)	; aktuelle Zeile (0..20)
		or	a
		jr	nz, hexi17
		
		CALL	0FA50h	; ROLD		;ROLLEN ABWAERTS

;		ld	hl, bws1(24,1)	; scrollen
;		ld	de, bws1(25,1)
;		ld	bc, 840		; 21*40
;		lddr
		jr	hexi1

hexi17:		dec	a
		ld	(cline), a	; aktuelle Zeile (0..20)
		ld	hl, (cupos)
		ld	de, 40
		sbc	hl, de
hexi18:		ld	(cupos), hl
		jr	hexi1


; Ende
hexend:		call	fullwindw		; Bildschirm löschen
		or	a
		ret

;Cursor down
hexi19:		cp	10
		jr	nz, hexi22
hexi20:		ld	hl, (caddr)

		;cp RAME
		ld	de,RAME-7
		CALL	0FCBCH		; COMPW		;ADRESSVERGLEICH
		jr	z, hexi1

		ld	de, 8
		add	hl, de
		ld	(caddr), hl
		ld	a, (cline)	; aktuelle Zeile (0..20)
		cp	15		; darzustellende Zeilen
		jr	c, hexi21
;		ld	de, bws1(2,1)	; scrollen
;		ld	hl, bws1(3,1)
;		ld	bc, 840		; 21*40
;		ldir
		CALL	0FA4Fh	; ROLU		;ROLLEN AUFWAERTS
		
		jp	hexi1

hexi21:		inc	a
		ld	(cline), a	; aktuelle Zeile (0..20)
		ld	hl, (cupos)
		ld	de, 40
		add	hl, de
		jr	hexi18

; ENTER
hexi22:		cp	0Dh		; ENTER
		jp	nz, hexi1
		ld	a, 5
		ld	(ccol),	a	; aktuelle Position in Zeile
		jr	hexi20


;------------------------------------------------------------------------------
; UPs
;------------------------------------------------------------------------------


;kleines Eingabefenster at 2,2 .. 17,33 (zeile, spalte)

smallwindw:	ld	hl, (17+1)*100h+(2-1)
		ld	(P1ROL), hl
		ld	hl, (33+1)*100h+(2-1)
		ld	(P3ROL), hl

;		ld	hl, bws1(2,2)	; Cursor auf Fenster setzen
;		ld	(CURS), hl
;
;		ld	hl, bwsc1(2,2)	; Farbattribut übernehmen
;		ld	a,(hl)
;		ld	(ATRIB),a

;		ld	a,20h		; grün auf schwarz
		ld	a,71h		; weiß auf schwarz
		ld	(ATRIB),a

		ld	a, 0Ch		; CLS
		call	outa
		ret

; volles Fenster
fullwindw:	ld	hl, 1900h	; 1-24 (25,0)
		ld	(P1ROL), hl
		ld	hl, 2900h	; 1-40 (41,0)
		ld	(P3ROL), hl

		ld	a,20h		; grün auf schwarz
		ld	(ATRIB),a

cls:		ld	a, 0Ch
		call	outa
		ret
		
;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------
		
RAMB		equ	2000h		; Arbeitsspeicher für CHIP8, 0E00h Bytes
RAME		equ	RAMB+100h-1
		
		end
