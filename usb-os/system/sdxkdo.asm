;Terminal KC87/Z9001 Übertragung via User-PIO-Port
;PIO bit 3-0 A/E Daten Halbbyte = nibble
;PIO bit 7,6 E bit 5,4 A für Handshake
;HH =busy, LH= empf L nibble, HL sende L nibble ,LL empf/sende H nibble
;2008 by Kingstener
;
; 20.01.2025 vpohlers sdx0-Einschub zur autom. Modus-Umschaltung


	cpu	Z80


;PIO1BD		EQU	89H		; PIO1 B Daten Anwenderport
;PIO1BS		EQU	8BH		; PIO1 B Kommando Anwenderport

;		org 	3F00h
;		org 	0BF00h
;		org 	0BC00h
		
;		jp	sdx
;		db	"SDX      ",0

;-------------------------------------------------------------------------------	
; 
sdxkdo:		ld	a, 00110000b	; Bit 4,5 OUT setzen
		out	(PIO1BD), a	
;vp:		
sdx0:		;;call 	mode_in		; init
		in	a, (PIO1BD)	; Modus-test
		and	11000000b
		cp	01000000b	; ausgabe?
		jr	nz, sdx1
		ld	a,0dh		; sende <ENTER>
		call	outbyte		; (Umschalten auf Eingabe)
;			
sdx1:		call	mode_in
; Zeichen von AVR einlesen und auswerten
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

; Zeichen von Tastatur an AVR ausgeben bis <Enter>
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

;-------------------------------------------------------------------------------	

;Hilfsprogrammverteiler
ESC:		call	getbyte
		cp	'T'
		jr	z, esc_t	; Programm in Speicher schreiben
		cp	'U'
		jr	z, esc_u	; Programm starten
		cp	'V'
		jr	z, esc_v	; Programm auf SD-Card schreiben
		ret

;-------------------------------------------------------------------------------	

; 1B 54 Lesen in Speicher
; ESC, 'T', adr, anz
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

; 1B 55 starten
; ESC, 'U', adr
esc_u:		call	getbyte		; Startadresse holen
		ld	l, a
		call	getbyte
		ld	h, a
		push	hl		; auf Stack legen
		ret			; und starten

; 1B 56 Schreiben auf SD-Card
; ESC, 'V', adr, anz
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
		jp	sdx1		; zurück; umschalten auf mode_in

;-------------------------------------------------------------------------------	

