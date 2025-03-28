; File Name   :	F:\dvd104\hobby\kingstener sd-card\SDX.KCC
; Format      :	Binary file
; Base Address:	0000h Range: 3F00h - 4000h Loaded length: 0100h

;Terminal KC87/Z9001 Übertragung via User-PIO-Port
;PIO bit 3-0 A/E Daten Halbbyte = nibble
;PIO bit 7,6 E bit 5,4 A für Handshake
;HH =busy, LH= empf L nibble, HL sende L nibble ,LL empf/sende H nibble
;2008 by Kingstener

;14.06.2008 vp relokatible Version, Start bei START
; erzeugen mit 2x assemblieren auf versch. Adressen
; Länge des zu verschiebenden Bereichs ist movlaenge = 00FBh Byte
; > genoffstab.pl sdx1.bin sdx2 00FB > offstab.inc
; > com2tap.pl sdx.bin 0 300 3FB (=START)
; > ren sdx.tap load87


; 04.10.2009 nichtverschiebbare Version f. Megamodul

	cpu	Z80


PIO1BD		EQU	89H		; PIO1 B Daten Anwenderport
PIO1BS		EQU	8BH		; PIO1 B Kommando Anwenderport

		org	0bc00h
		
beg		
		jp	sdx
		db	"SDX     ",0

mode_in:	ld	a, 11001111b	; Modus3 Bit-E/A
		out	(PIO1BS), a
		out	(PIO1BS), a	; und Bitinitialisierung: Bit 4,5 OUT, sonst IN
		ret


getbyte:	in	a, (PIO1BD)
		and	11000000b	; nur Bit 6,7
		cp	10000000b
		jr	nz, getbyte
		in	a, (PIO1BD)	; unteres Nibble holen
		and	00001111b
		ld	c, a
		ld	a, 00010000b
		out	(PIO1BD), a
getbyte1:	in	a, (PIO1BD)
		and	11000000b
		jr	nz, getbyte1
		in	a, (PIO1BD)	; oberes Nibble	holen
		rla
		rla
		rla
		rla
		and	0F0h
		add	a, c
		ld	c, a		; Byte sichern
		xor	a		; A=00000000b
		out	(PIO1BD), a
		ld	a, 00110000b
		out	(PIO1BD), a
		ld	a, c
		ret


mode_out:	ld	a, 11001111b	; Modus3 Bit-E/A
		out	(PIO1BS), a
		ld	a, 11000000b	; Bit 6,7 IN, sonst OUT
		out	(PIO1BS), a
		ret


outbyte:	ld	c, a
outbyte1:	in	a, (PIO1BD)
		and	11000000b
		cp	01000000b
		jr	nz, outbyte1
		ld	a, c
		and	0Fh
		or	00100000b
		out	(PIO1BD), a
outbyte2:	in	a, (PIO1BD)
		and	11000000b
		jr	nz, outbyte2
		ld	a, c
		rra
		rra
		rra
		rra
		and	0Fh
		out	(PIO1BD), a
outbyte3:	in	a, (PIO1BD)
		and	11000000b
		cp	11000000b
		jr	nz, outbyte3
		ld	a, 00110000b
		out	(PIO1BD), a
		ld	a, c
		ret

; 
sdx:		ld	a, 00110000b	; Bit 4,5 OUT setzen
		out	(PIO1BD), a
sdx1:		call	mode_in
sdx2:		call	getbyte
		cp	1Bh		; ESC -> Hilfsprogramme Lesen/Schreiben/Starten
		jr	z, ESC
		cp	80h 		; 80H -> Umschalten auf Mode out
		jr	z, sdx3
		cp	3		; STOP
		ret	z		; Ende

		ld	e, a		; sonst ECHO auf Bildschirm
		ld	c, 2		; CONSO
		call	5
		jr	sdx2
;
sdx3:		call	mode_out
		ld	c, 1		; CONSI
		call	5
		ld	e, a		; Eingegebenes Zeichen auf Bildschirm ausgeben
		ld	c, 2		; CONSO
		call	5
		call	outbyte		; und an Controller ausgeben
		cp	0Dh		; <ENTER>?
		jr	z, sdx1		; ja - Kommandoausführung, Ergebnis einlesen
		jr	sdx3		; sonst	weiter Terminalbetrieb


; Lesen in Speicher
esc_t:		call	getbyte		; Hole Anfangsadresse HL
		ld	l, a
		call	getbyte
		ld	h, a
		call	getbyte		; hole Anzahl DE
		ld	e, a
		call	getbyte
		ld	d, a
esc_t1:		call	getbyte		; Byte lesen
		ld	(hl), a		; in Speicher schreiben
		inc	hl
		dec	de
		ld	a, e
		or	d
		jr	nz, esc_t1	; bis alle Bytes abgearbeitet wurden
		jr	sdx2


; Schreiben auf SD-Card
esc_v:		call	getbyte		; Hole Anfangsadresse HL
		ld	l, a
		call	getbyte
		ld	h, a
		call	getbyte		; hole Anzahl DE
		ld	e, a
		call	getbyte
		ld	d, a
		call	mode_out
esc_v1:		ld	a, (hl)		; Byte holen
		call	outbyte		; auf SD-Card schreiben
		inc	hl
		dec	de
		ld	a, e
		or	d
		jr	nz, esc_v1	; bis alle Bytes abgearbeitet wurden
		jr	sdx1


; starten
esc_u:		call	getbyte		; Startadresse holen
		ld	l, a
		call	getbyte
		ld	h, a
		push	hl		; auf Stack legen
		ret			; und starten

;Hilfsprogrammverteiler
ESC:		call	getbyte
		cp	'T'
		jr	z, esc_t	; Programm in Speicher schreiben
		cp	'U'
		jr	z, esc_u	; Programm starten
		cp	'V'
		jr	z, esc_v	; Programm auf SD-Card schreiben
		
		jp	sdx

		end
