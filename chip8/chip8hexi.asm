;------------------------------------------------------------------------------
; HEX-Editor
; start mit cmd_hexi
; ret A=Zeichen von Tastatur (Strg-C, RUN, ESC)
;------------------------------------------------------------------------------

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
		sub	a,hi(RAMB)-2	; Korrektur zur Anzeige (Offs)
		
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
		ld	a,hi(RAMB)-2	; Korrektur Offset
		add	a,d
		ld	d,a
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
line0:		push	de
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


; Anzeigen 16 Zeilen

line16:		ld	de, (caddr)
		ld	hl, (cupos)
		ld	b,16
.m1:		push	bc
		call	line0
		ld	bc, 11
		add	hl,bc
		push	hl
		ld	hl, 8
		add	hl,de
		ex	de,hl
		pop	hl
		pop	bc
		djnz	.m1
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
		
		call	line16

; main loop
hexi1:		call	line		; Anzeigen einer Zeile
hexi2:		call	disp		; Anzeige aktualisieren
		cp	3		; stop
		ret	z		; Ende
		cp	1Bh		; ESC
		ret	z		; Ende
		cp	1Dh		; RUN
		ret	z		; Ende
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
