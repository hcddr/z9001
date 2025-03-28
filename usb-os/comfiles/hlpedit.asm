; Z9001
; Volker Pohlers 2020
; full screen color editor mit 22 zeilen
; laden, speichern (PRNST-Format)
; vorrangig gedacht für HLP-Dateien

; möglich color xx -> farb, cursor rechts färbt zeichen um. ende einfärben, wenn anderer steuercode
; ist aber nicht ganz sinnvoll.
; Version f. USB-System
; 11.08.2020  Umstellung CSAVE/CLOAD auf CALL 5
; 11.08.2020  bei Laden Attribut-Wandlung

	cpu	z80

ATRIB:	EQU	0027H		;aktuelles Farbattribut
CHARP:	EQU	002BH		;ZEIGER AUF SPALTE
LINEP:	EQU	002CH		;ZEIGER AUF ZEILE
CURS:	EQU	002DH		;PHYS. CURSORADRESSE
BUFFA:	EQU	0034H		;PUFFER FARBCODE		Zeichen unter Cursor
P1ROL:	EQU	003BH		;1. ZU ROLLENDE ZEILE-1
P2ROL:	EQU	003CH		;LETZTE ZU ROLLENDE ZEILE+1
P3ROL:	EQU	003DH		;1. ZU ROLLENDE SPALTE-1
P4ROL:	EQU	003EH		;LETZTE ZU ROLLENDE SPALTE+1
BUFF:	EQU	003FH		;PUFFER FUER ZEICHEN		unter Cursor
FCB: 	EQU	005Ch 		;Dateikontrollblock
DMA	equ	001Bh

;OCRLF:  EQU	0F2FEH
;OUTA:	EQU	0F305H
;OSPAC:  EQU	0F310H
;PRNST:  EQU	0F3E2H		;AUSGABE ZEICHENKETTE ab DE
CONSI:  EQU	0F009H		;EINGABE ZEICHEN VON CONST
GCURS 	EQU	0F030H		;Abfrage logische und physische Cursoradresse

CURSL:	EQU	8		;CURSOR LINKS
CURSR:	EQU	9		;CURSOR RECHTS
CURSD:	EQU	0AH		;CURSOR RUNTER (LF)
CURSU:	EQU	0BH		;CURSOR HOCH
CLEAR:	EQU	0CH		;BILDSCHIRM LOESCHEN
CARIG:	EQU	0DH		;CURSOR AN ZEILENANFANG (CR)
SPACE:	EQU	20H		;LEERZEICHEN

;-------------------------------------------------------

	org	300h

	jp	start
	db	"HLPEDIT ",0
	db	0

;-------------------------------------------------------

start:	call 	init
	ld	a,(atrib)
	push	af
	
	call 	loop

;ende
	;setze farbattribut
	pop	af
	ld	(atrib),a

	ld	a,25		;letzte zu rollende Zeile + 1
	ld	(p2rol),a
	call	cls
	jp	0

;-------------------------------------------------------

cls	ld	a,CLEAR		; cls
	jp	outa

init:	call	cls
	ld	a,23		;letzte zu rollende Zeile + 1
	ld	(p2rol),a

	ld	hl,0ec00h + 22*40
	ld	b,40
	ld	a,0a0h		; waagerechter Strich
init1:	ld	(hl),a
	inc	hl
	djnz	init1
	ld	de,footln
	ld	bc,footlne-footln
	ex	de,hl
	ldir

	ret

footln	db	"ESC+ Laden Speichern Ende Color  VP2020"
footlne	equ	$

;-------------------------------------------------------
; Editierschleife

loop	call	CONSI
	cp	01Bh		; ESC?
	jr	z,loope
	cp	CURSR		; Spezialbehandlung, Farbe übernehmen
	jr	z,loopr
loop1:	call	OUTA
	jr	loop

loopr	call	OUTA
	ld	a,(colmod)
	;or	a
	cp	' '
	jr	z,loop
	; sonst färben
	call	GCURS
	sbc	hl,de		; Farbspeicher-Pos
	dec	hl		; Zeichen zurück
	ld	a,(ATRIB)
	ld	(hl),a		; Farbe setzen
	jr	loop

;-------------------------------------------------------

; ESC
loope	call	CONSI
	cp	'E'
	ret	z		; loop beenden
	cp	'L'
	jp	z,load
	cp	'S'
	jp	z,save
	cp	'C'
	jp	z,swcmod
	jr	loop1		; sonst Zeichen ausgeben
;


;-------------------------------------------------------
; Einfärbemodus toggeln
swcmod	ld	a, (colmod)
	xor	0FFh
	ld	(colmod), a
	jr	loop



;-------------------------------------------------------
buffer	equ	3800h
fext	db	"HLP"

;-------------------------------------------------------
; speichern
SAVE:	call	recode
	call	cls
	LD	(fcb+17),HL	; AADR
	LD	(fcb+19),DE	; EADR
	ld	a,'N'
	ld	(fcb+24),a 	;ohne kopfblock laden
	ld	a,82h		; Filename abfragen
	ld	ix,fext		; Filetyp HLP
	ld	c,35		; CSAVE
	call	5
	jr	load1		; wieder anzeigen

;-------------------------------------------------------
; Laden
LOAD:	call	cls

	ld	a,'N'
	ld	(fcb+24),a 	;ohne kopfblock laden
	LD	HL,buffer
	ld	a,82h		;Abfrage "Filename:"
	ld	ix,fext		; Filetyp HLP
	ld	c,34		; CLOAD
	call	5
	jr	c,load1		; bei Ladefehler

	;0-Byte anfügen (Sicherheit, wenn Text am PC geändert)
	
	;todo: wenn (dma)-128 <= LEADR < (dma), dann 
	ld	hl,(fcb+25)	;LEADR, bei USB
	ld	(hl),0
	;
	;ld	hl,(dma)	;sonst
	;ld	(hl),0

	; Anzeigen
load1:	call	cls
;;	ld	de, buffer
;;	call	PRNST

	; Anzeigen mit Attributwandlung
	ld	hl, buffer
outtext:
	ld 	a,(hl)
	cp	0
	jr	z, ende
	cp	'<'		; attrib?
	call	z,check
	call	outa
	inc	hl
	jr	outtext
ende:
	jp	loop


;-------------------------------------------------------
; Umkodieren des Bildschirminhalts in Zeichenkette

recode	ld	a,0ffh
	ld	(lacol),a	; init
	ld	DE, 0EC00h	; BWS
	ld	ix, 0E800h	; Farbspeicher
	ld	hl, buffer	; ziel
;;	call	recol		; init Vordergrund-Farbe
	ld	c,22		; Anzahl Zeilen
recod2:	ld	b,40		; Zeichen/Zeile
recod1:	call	recol		; ggf. Vordergrund-Farbe
	ld	a,(de)		; Zeichen
	ld	(hl),a		; übernehmen
	inc	de
	inc	ix
	inc	hl
	djnz	recod1
; zeile packen
	cp	SPACE		; ist ein Leerzeichen am Zeilenende?
	jr	nz, recod4	; nein, also kein CR+LF!
recod3:	dec	hl		; rückwärts
	ld	a,(hl)
	cp	SPACE		; solange Leerzeichen
	jr	z,recod3
	inc	hl
	ld	a,CARIG		; dann CR+LF schreiben
	ld	(hl),a
	inc	hl
	ld	a,CURSD
	ld	(hl),a
	inc	hl
recod4:	dec	c
	jr	nz,recod2
; Zeilenenden am Textende löschen
recod6:	dec	hl		; rückwärts
	ld	a,(hl)
	cp	CURSD		; LF
	jr	nz,recod5
	dec	hl
	ld	a,(hl)
	cp	CARIG		; CR suchen
	jr	nz,recod5
	jr	recod6
	;
recod5	inc	hl		; letztes CR + LF
	inc	hl		; wieder nehmen
	;
	inc	hl		; und eins weiter für
	ld	a,0		; Abschluss-Byte
	ld	(hl),a
	;
	ld	de,buffer
	ex	de,hl
	ret			; hl=aadr, de=eadr

; Vordergrundfarbe
recol	push	bc
	ld	a,(de)
	cp	SPACE		; Leerzeichen
	jr	z,recol1	; ohne Farbe übernehmen
	; letzte Vordergrundfarbe
	ld	a,(lacol)
	ld	b,a
	; ermittle Vordergrundfarbe
	ld	a,(ix)
	rrca
	rrca
	rrca
	rrca
	and	7		; Vordergrund-Farbe
	; vergleich
	cp	b
	jr	z,recol1
	; schreibe Farbbyte
	ld	c,14h		; COLOR
	ld	(hl),c
	inc	hl
	ld	(hl),a
	inc	hl
	ld	(lacol),a	; letzte Farbe merken
recol1	pop	bc
	ret


;-------------------------------------------------------
;umwandeln Steuercodes
;Attribut-Suche
check:	ld	de, attrib
check0:	push	hl
check1:	inc	hl
	ld	c,(hl)
	ld	a,(de)
	cp	20h
	jr	c,check3	; ende erreicht
	cp	a,c
	jr	nz,check2	; nicht gleich
	inc	de
	jr	check1

;nicht gleich, nächstes Attribut testen
check2:	inc	de
	ld	a,(de)
	cp	20h		; Attributende?
	jr	nc,check2	
	cp	0		; Listenende?
	jr	z,check4
	inc	de
	pop	hl
	jr	check0
;gleich, gefunden
check3:	ld	e,a
	ld	a,(hl)
	cp	'>'		; attrib?
	jr	nz,check4
	ld	a,14h		; Farbe folgt
	call	outa
	ld	a,e		; Farbe
	pop	de		; HL von Stack nehmen
	ret
;nichts gefunden		
check4:	pop	hl
	ld	a,(hl)
	ret	


attrib:
	db "RED",01
	db "GREEN",02
	db "YELLOW",03
	db "BLUE",04
	db "MAGENTA",05
	db "CYAN",06
	db "WHITE",07
	db 0


;
;-------------------------------------------------------
;
	include	hlpedit_crt40.asm

;-------------------------------------------------------
;colmod	db	0		
colmod equ	0ef98h+31	; Merkzelle Einfärbemodus
lacol	ds	1		; Merkzelle letzte Farbe

	end
