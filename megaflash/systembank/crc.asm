;------------------------------------------------------------------------------
; CRC-Berechnung;  f. Mega-Flash-SW
; Beispiel für Nutzung Sprungverteiler
; V.Pohlers 08.10.2012
;------------------------------------------------------------------------------


		cpu	Z80

; Sprungverteiler aus Mega-Flash-SW
rst_sbos	equ	28h		;der RST für den Sprungverteiler

;0 OUTHX	Ausgabe (A) hexa
;1 OUTHL	Ausgabe (HL) hexa
;7 KDOPAR	Kommandoparameter aufbereiten
;8 INHEX	Konvertierung ASCII-Hex ab (DE) --> (HL)
;9 PRST7	Ausgabe String bis Bit7=1

;------------------------------------------------------------------------------
; Hauptprogramm
; CRC aadr [eadr]  	berechne CRC16 von aadr bis eadr (einschließlich)
;			fehlt eadr, wird ein Bereich von 2K genommen
;			die Berechnung ist dieselbe wie beim Eprommer EPROM2A
;------------------------------------------------------------------------------

		ifndef includeprg
		org	300h
		endif

		; OS-Rahmen
		jp	CRC_KDO
		db 	"CRC    ",0
		db    	0

		; Hauptprogramm
CRC_KDO:	rst	rst_sbos	; Kommandozeilen-Parameter holen
		db	7		; KDOPAR HL=ARGV1=aadr, DE=ARGV2=eadr

		ld	bc, 800h

		ex	de,hl		; hl=eadr, de=aadr
		ld	a,h
		or	l
		jr	z, CRC_KDO1	; ARG2=0? dann Länge 2KByte

		;ARG2=0<>0: Länge berechnen als eadr-aadr+1
		or	a		; Cy=0
		sbc	hl,de
		inc	hl		; +1
		ld	b,h		; bc = länge
		ld	c,l

CRC_KDO1:	; CRC-Berechnung   de=aadr, bc=länge

		; Anzeige "CRC (aadr-eadr) = crc"
		rst	rst_sbos
		db	9		; PRST7
		db	"CRC ",'('+80h

		; aadr
		ex	de,hl
		rst	rst_sbos	; Anzeige de=aadr
		db	1 		; OUTHL
		ex	de,hl

		rst	rst_sbos
		db	9		; PRST7
		db	'-'+80h

		; CRC-Berechnung
		call	crc		; de=aadr, bc=länge
					; ret: hl=crc
		; eadr
		ex	de,hl
		dec	hl
		rst	rst_sbos	; Anzeige de=eadr
		db	1 		; OUTHL
		ex	de,hl

		rst	rst_sbos
		db	9		; PRST7
		db	") =",' '+80h

		; crc
		rst	rst_sbos	; Anzeige CRC
		db	1 		; OUTHL, hl=crc

		rst	rst_sbos
		db	9		; PRST7
		db	0dh,0ah+80h

		; zurück ins OS
		xor	a
		ret


;------------------------------------------------------------------------------
; CRC berechnen
; Routine aus EPROMA2
; in DE = Startadr., BC = Länge, out HL=CRC
; CRC-CCITT (CRC-16) x16 + x12 + x5 + 1 
;------------------------------------------------------------------------------

crc:		ld	hl, 0FFFFh
crc1:		ld	a, (de)
		xor	h
		ld	h, a
		rrca
		rrca
		rrca
		rrca
		and	0Fh
		xor	h
		ld	h, a
		rrca
		rrca
		rrca
		push	af
		and	1Fh
		xor	l
		ld	l, a
		pop	af
		push	af
		rrca
		and	0F0h
		xor	l
		ld	l, a
		pop	af
		and	0E0h
		xor	h
		ld	h, l
		ld	l, a
		inc	de
		dec	bc
		ld	a, b
		or	c
		jr	nz, crc1
		ret

;		end
