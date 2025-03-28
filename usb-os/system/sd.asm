;-------------------------------------------------------------------------------	
; Kommunikation mit SD-Modul
;-------------------------------------------------------------------------------	

;PIO bit 3-0 A/E Daten Halbbyte = nibble
;PIO bit 7,6 E bit 5,4 A für Handshake
;HH =busy, LH= empf L nibble, HL sende L nibble ,LL empf/sende H nibble

;----------------
; User-PIO
PIO1BD		EQU	89H		; PIO1 B Daten Anwenderport
PIO1BS		EQU	8BH		; PIO1 B Kommando Anwenderport

;----------------

; SD-Modul-Arbeitsweise:
; nach Modul-Reset:
; send "SD-CARD-OS KC87 V..."
; main loop:	send "\nSD>", send 0x80
;		read special Kommando >= F0
;		oder read ASCII-Kommandozeile, Abschluss mit 0D
;		Abarbeitung Kommando
;
; Die Umschaltung zw. Senden/Empfangen muss auf beiden Seiten snychon erfolgen

;----------------

; PIO init
; SD-Modul meldet sich mit "\nSD>" 0x80
; das wird alles überlesen
; bei Rückkehr ist das Modul im Kommando-Empfangsmodus, der KC im Sende-Modus
; (ASCII-Kommando oder F0-Kommando)

sdinit:		ld	a, 00110000b	; Bit 4,5 OUT setzen
		out	(PIO1BD), a
		in	a, (PIO1BD)	; Modus-test
		and	11000000b
		cp	01000000b	; Ausgabe?
		jr	nz, sdinit1	; nein
		ld	a,0dh		; ja, sende erst <ENTER>
		call	outbyte		; (Umschalten auf Eingabe)

		; alles Überlesen bis 80h ("\nSD>" 0x80)
sdinit1:	call	mode_in
sdinit2:	call	getbyte		; alles Überlesen bis 80h
		cp	80h 		; 80H -> Umschalten auf Mode out
		jr	nz, sdinit2
		call	mode_out
		ret

;----------------

; PIO Umschalten auf Einlesen vom Modul
mode_in:	ld	a, 11001111b	; Modus3 Bit-E/A
		out	(PIO1BS), a
		out	(PIO1BS), a	; und Bitinitialisierung: Bit 4,5 OUT, sonst IN
		ret

; Einlesen vom Modul
; ret A - eingelesens Byte
getbyte:	;;di
		in	a, (PIO1BD)
		and	11000000b	; nur Bit 6,7
		cp	10000000b	; wait for 10xx....
		jr	nz, getbyte
		in	a, (PIO1BD)	; unteres Nibble holen
		and	00001111b
		ld	c, a
		ld	a, 00010000b	; out xx01....
		out	(PIO1BD), a
getbyte1:	in	a, (PIO1BD)
		and	11000000b
		jr	nz, getbyte1	; wait for 00xx....
		in	a, (PIO1BD)	; oberes Nibble	holen
		rla
		rla
		rla
		rla
		and	0F0h
		add	a, c
		ld	c, a		; Byte sichern
		xor	a		; A=00000000b
		out	(PIO1BD), a	; out 0000....
		ld	a, 00110000b
		out	(PIO1BD), a	; out 0011....
		;;ei
		ld	a, c
		ret

;--------------------------------

; PIO Umschalten auf Ausgabe zum Modul
mode_out:	ld	a, 11001111b	; Modus3 Bit-E/A
		out	(PIO1BS), a
		ld	a, 11000000b	; Bit 6,7 IN, sonst OUT
		out	(PIO1BS), a
		ret

; Ausgabe zum Modul
; in A -auszugebendes Byte
outbyte:	ld	c, a		; save a
		;;di	
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
		;;ei
		ret
