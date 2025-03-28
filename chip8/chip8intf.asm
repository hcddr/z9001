;------------------------------------------------------------------------------
; CHIP8-Interpreter
; V.Pohlers, 2013
;------------------------------------------------------------------------------
; Schnittstelle zum System, hier für Z9001
;------------------------------------------------------------------------------



;------------------------------------------------------------------------------
; BWS leeren
;------------------------------------------------------------------------------
c8_CLS		ld	hl,gbuf
		ld	de,gbuf+1
		ld	bc,64*32/8
		ld	(hl),0
		ldir	
		call	c8_drawbs
		ret	

;------------------------------------------------------------------------------
; BWS anzeigen
;------------------------------------------------------------------------------

c8_drawbs	push	hl
		ld	ix, gbuf
		ld	hl, 0ec00h+40+1
;		
		exx
		ld	de,pixtab	; vorbereiten
		exx
;
		ld	b,32/2
c8_drawbs3	push	bc
		
		ld	b,64/8	; /2 /4
c8_drawbs2	push	bc
		

		ld	b,4
		; Punkte (x,y),(x+1,y)     (84)
		;        (x,y+1),(x+1,y+1) (21) holen
		ld	d,(ix)		; Zeile
		ld	e,(ix+8)	; eine Zeile tiefer
c8_drawbs1	xor	a		; a = 0
		sla	d		; 2 Pixel aus erster Zeile
		rla
		sla	d
		rla
		sla	e		; 2 Pixel aus zweiter Zeile
		rla
		sla	e
		rla
		; hole Grafikzeichen aus Tabelle
		exx
		; ld	de,pixtab	; s.o.
		ld	h,0
		ld	l,a
		add	hl,de
		ld	a,(hl)
		exx
		; Zeichen ausgeben
		ld	(hl),a
		inc	hl
		djnz	c8_drawbs1	; 8 Pixel = 4 Zeichen ausgegeben
		;
		inc	ix		; weiter in GPUF
	
		pop	bc
		djnz	c8_drawbs2	; Zeile fertig ausgeben
		
		ld	de, 40-32	; Offset in BWS
		add	hl,de		; neue Zeile in BWS
		
		ld	de,8
		add	ix,de		; 2 neue Zeilen in GPUF
		
		pop	bc
		djnz	c8_drawbs3
;		
		pop	hl
		ret
		
; Tabelle Pixel-Grafik-Zeichen
;     FF  BC  BD  B6  BB  B4  B8  B0  BA  B9  B5  B1  B7  B3  B2  20
;                                                             
; 84  ##  ##  ##  ##  #.  #.  #.  #.  .#  .#  .#  .#  ..  ..  ..  ..
; 21  ##  #.  .#  ..  ##  #.  .#  ..  ##  #.  .#  ..  ##  #.  .#  ..

pixtab		db	20h
		db	0b2h
		db	0b3h
		db	0b7h
		db	0b1h
		db	0b5h
		db	0b9h
		db	0bah
		db	0b0h
		db	0b8h
		db	0b4h
		db	0bbh
		db	0b6h
		db	0bdh
		db	0bch
		db	0ffh
	
;------------------------------------------------------------------------------
; Abbruch bei Fehler
; in: HL-Adr. Fehlertext
;------------------------------------------------------------------------------
c8_Error	ex	de, hl
		ld	c,9
		call	5
		ret	

;------------------------------------------------------------------------------
; Warten auf Tastendruck, ret A=Chip8-Keycode, wenn Taste wieder losgelassen
;------------------------------------------------------------------------------

c8_waitkey	xor	a
		ld	(25h),a
		ld	c,1
		call	5
		call	c8_testkey0
		cp	0ffh
		jr	z,c8_waitkey
		ret	

;------------------------------------------------------------------------------
; Tastaturabfrage; kein warten auf Tastendruck, 
; ret A=Chip8-Keycode gedrückte Taste 
;     A=0ffh - keine Taste gedrückt; a=0feh - Abbruch des Interpreters		
;------------------------------------------------------------------------------

DECO0		equ	0fd33h

c8_testkey	
		;ld	c,11		; csts
		;call	5

		call	DECO0		; Tastatur-Polling
		ei
;		or	a
;		jr	nz,c8_testkey0
		ld	(25h),a

c8_testkey0	cp	48h		; außerhalb keytab ?
		jr	c, c8_testkey1	; nein
		ld	a,0ffh		; sonst 0ffh zurückgeben
		ret
c8_testkey1	ld	hl, keytab	; Kode umsetzen
		ld	d, 0
		ld	e,a
		add	hl, de
		ld	a,(hl)
		ret	

keytab		db	0ffh, 0ffh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh	; 00..07 Stop = Abbruch
		db	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; 08..0f
		db	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; 10..17
		db	0ffh, 0ffh, 0ffh, 0feh, 0ffh, 0ffh, 0ffh, 0ffh	; 18..1f ESC = Abbruch
		db	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; 20..27
		db	0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; 28..2f
		db	0, 1, 2, 3, 4, 5, 6, 7				; 30..37 0..7
		db	8, 9, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh, 0ffh	; 38..3f 8..9
		db	0ffh, 0ah, 0bh, 0ch, 0dh, 0eh, 0fh, 0ffh	; 40..47 @A..F


;------------------------------------------------------------------------------
; Ton
;------------------------------------------------------------------------------
DPIO1A:	equ	88H
CTC0:	EQU	80H

c8_sndon	
; s. INIVT
	 	LD	A,85H		;Steuerwort CTC: (EI, Zeitkonstante folgt)
	 	OUT	CTC0, A		;CTC0
	 	LD	A,40H		;VORTON 1
	 	OUT	CTC0, A		;CTC0 Zeitkonstante: 2,4576 Mhz / 16 / 40h = 2400 Hz
;
		IN	A, DPIO1A
		set	7,a
		OUT	DPIO1A, A
		ret
c8_sndoff	
		IN	A, DPIO1A
		res	7, a
		OUT	DPIO1A, A
		ld	a,3
    		OUT	CTC0, A		;CTC0

		ret
