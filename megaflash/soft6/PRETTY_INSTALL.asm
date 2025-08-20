; File Name   :	d:\hobby\z9001 prettyc\INSTALL.KCC
; Format      :	Binary file
; Base Address:	0000h Range: 0280h - 5280h Loaded length: 5000h


; I N S T A L L
; hängt an PRETTYC dran und wird gestartet

ROM:0300     aadr:
ROM:048C     init_rst:
ROM:319F     outhlsp
ROM:4E8C     ECBUF:	     dw	8000h		     
ROM:4E9E     RAMTP:	     dw	0BFFFh		     
ROM:4EA7     CONBUF:	     db	4		     
ROM:4F2D     pgrend
ROM:4F2E     sadr

rst8	prnstr-Routine


		org	pgrend+1

sadr:		call	init_rst	; RSTs initialisieren
loc_4F31:	rst	8
		db 0Ch,"***  Pretty C - Installierung   ***",0Dh,0Ah
		db 0Ah
		db "Version 1.1",0Dh,0Ah
		db 0Ah
		db 0Ah
		db "Lesen Sie Kap. 9 der Dokumentation",0Dh,0Ah
		db "zur Bedienung dieses Programms!",0Dh,0Ah
		db "Abbruch mit STOP.",0Dh,0Ah
		db 0Ah
		db "RAMTP [BFFF]: ",0
;
		call	GCONB		; Eingabe Zeichenkette
		jr	c, loc_4FD8	; Zahl in HL
		ld	hl, 0BFFFh	; default
loc_4FD8:	inc	l
		jp	nz, loc_521F	; nicht	xxFF
		dec	l
		call	outhlsp		; Ausgabe HL + Space
		ld	(RAMTP), hl
;		
		rst	8
		db 0Dh,0Ah
		db 0Ah
		db "EC: Standard-Textpuffer ab [8000]: ",0
		call	GCONB		; Eingabe Zeichenkette
		jr	c, loc_5013
		ld	hl, 8000h
loc_5013:	inc	l
		dec	l
		jp	nz, loc_521F
		call	outhlsp		; Ausgabe HL + Space
		ld	(ECBUF), hl
;
		rst	8
		db 0Dh,0Ah
		db 0Ah
		db "CC: Konstantenpuffer [400]: ",0
		call	GCONB		; Eingabe Zeichenkette
		jr	c, loc_5047
		ld	hl, 400h
loc_5047:	inc	l
		dec	l
		jp	nz, loc_521F
		call	outhlsp		; Ausgabe HL + Space
		ld	a, h
		ld	(CONBUF), a
;
		rst	8
		db 0Dh,0Ah
		db 0Ah
		db "EC: 24/20 Zeilen (Y=24,N=20): ",0
		call	CYESNO
		dw ec			; wert Y
		dw ec20			; wert n
		dw aadr+1		; eintrag auf adr
;
		rst	8
		db 0Dh,0Ah
		db 0Ah
		db "schnelle Tastenwiederholung? (Y/N): ",0
		call	CYESNO
		dw intp			; Tastaturinterrupt
		dw 0FCE4h		; Std. Tast.Int
		dw sub_323B+1		; eintrag auf Adr.
;
		rst	8
		db 0Dh,0Ah
		db 0Ah
		db "CC-Listing: jeweils 4 oder 2 Positionen",0Dh,0Ah
		db "einruecken (Y=4,N=2): ",0
		call	CYESNO
		dw 8787h		; 2x add a,a
		dw 0087h		; 1x add a,a + nop
		dw loc_2DB5		; patchadr.
;
loc_50FE:	rst	8
		db 0Dh,0Ah
		db 0Ah
		db 0Ah
		db "*** Installierung/Schreiben beendet.",0Dh,0Ah
		db 0Ah
		db "  Schalten Sie Ihr Bandgeraet ein und",0Dh,0Ah
		db "  starten Sie mit ENTER.",0Dh,0Ah
		db "  Abbruch: STOP.",0Ah
		db 0Ah,0
		ld	de, 5Ch		; FCB
		ld	hl, prettyfcb	; "PRETTYC"
		ld	bc, 24
		ldir
		ld	hl, sadr
		ld	a, h
		sub	3
		rl	l
		adc	a, a
		ld	b, a		; B=Anz.Bl”cke
		ld	c, 0Fh
		call	5
		ret	c
		ld	hl, aadr
		ld	(1Bh), hl
		ld	c, 15h
loc_51A1:	call	nc, 5
		ex	af, af'
		call	0F310h
		ex	af, af'
		djnz	loc_51A1
		ld	c, 10h
		call	nc, 5
		jp	nc, loc_50FE
		jp	err
;
prettyfcb:	db "PRETTYC",0
		db "COM"
		db  2Ah	; *
		db  2Ah	; *
		db  2Ah	; *
		db  2Ah	; *
		db  2Ah	; *
		db  2Ah	; *
		dw aadr
		dw pgrend
		dw 0FFFFh
		db    0


; Eingabe Zeichenkette
GCONB:		ld	de, 210h
		ld	c, 0Ah		; RCONB	  Eingabe einer	Zeichenkette von CONST
		ld	a, 5
		ld	(de), a
		call	5
		jp	c, err
		inc	de
		ld	a, (de)		; l„nge
		ld	l, a
		or	a
		ret	z		; nix eingegeben
		xor	a
		ld	h, a
		add	hl, de
		inc	hl
		ld	(hl), a		; eintragen 0 am ende
		jp	atoh

; Yes/No-Abfrage mit 2 Byte-Patches
CYESNO:		ld	c, 1		; CONSI
		call	5
		cp	3
		jp	z, err
		cp	0Dh
		jr	z, loc_5200
		cp	'Y'
		jr	z, loc_5200
		cp	'N'
		jr	nz, CYESNO
		scf
loc_5200:	inc	c		; CONSO
		ld	e, a
		ex	af, af'
		call	5
		ex	af, af'
		pop	hl		; Ret-Adr von Stack
		ld	b, 3		; 3 Parameter
loc_520A:	ld	e, (hl)
		inc	hl
		ld	d, (hl)
		inc	hl
		push	de
		djnz	loc_520A
		exx
		pop	bc		; param	1..3 nach bc ..	hl
		pop	de
		pop	hl
		jr	nc, loc_5218
		ex	de, hl
loc_5218:	ld	a, l
		ld	(bc), a
		inc	bc
		ld	a, h
		ld	(bc), a
		exx
		jp	(hl)
loc_521F:	rst	8
		db 0Dh,0Ah
		db "illegal value!",7,0
loc_5232:	jp	err

		end
