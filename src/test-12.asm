;------------------------------------------------------------------------------
; TEST-12.COM
; Prüfprogramme f. Z9001-Signaturanalyse
; Beschreibung s. Serviceanleitung Z9001, S. 40
; getestet wird der Speicherbereich 4000-7FFF
; funktioniert nur mit ASA-Programm (es erfolgen UP-Aufrufe in EPROM 2E11)
; reass. V.Pohlers 18.01.2011
;------------------------------------------------------------------------------

		cpu	Z80

		org 3000h
		jp	test12
		db "TEST-12 ",0
		jp	test13
		db "TEST-13 ",0
		db    0

;------------------------------------------------------------------------------
; TEST-12
;------------------------------------------------------------------------------

test12:		di
		ld	sp, 8800h
		ld	a, 01000011b
		out	(0F8h),	a
		call	83D2h			; ** UP aus 2E11
; BWS löschen
		ld	bc, 400h
		ld	hl, 0EC00h
test12a:	ld	(hl), ' '
		inc	hl
		dec	bc
		xor	a
		cp	c
		jr	nz, test12a
		cp	b
		jr	nz, test12a
; Anzeige Test-Nr (12) auf BWS
		call	8356h			; ** UP aus 2E11
		ld	hl, 0ED4Ah
		ld	(hl), '1'
		inc	hl
		ld	(hl), '2'
;
test12b:	call	83CEh			; ** UP aus 2E11
; RAM ab 4000h mit Bytefolge 55,F0,AA,0F füllen
		ld	hl, 4000h
		ld	bc, 4000h
test12c:	ld	(hl), 55h
		inc	hl
		dec	bc
		ld	(hl), 0F0h
		inc	hl
		dec	bc
		ld	(hl), 0AAh
		inc	hl
		dec	bc
		ld	(hl), 0Fh
		inc	hl
		dec	bc
		xor	a			; A=0
		cp	c
		jr	nz, test12c
		cp	b
		jr	nz, test12c
;		
		call	83D2h			; ** UP aus 2E11
		jp	test12b




;------------------------------------------------------------------------------
; TEST-13 
; der eigentliche Speichertest
;------------------------------------------------------------------------------

		org	3110h

test13:		di
		ld	sp, 8800h
		ld	a, 10000011b
		out	(0F8h),	a
		call	83D2h			; ** UP aus 2E11
; BWS löschen
		ld	bc, 400h
		ld	hl, 0EC00h
test13a:	ld	(hl), ' '
		inc	hl
		dec	bc
		xor	a			; A=0
		cp	c
		jr	nz, test13a
		cp	b
		jr	nz, test13a
; Anzeige Test-Nr (13) auf BWS
		call	8356h			; ** UP aus 2E11
		ld	hl, 0ED4Ah
		ld	(hl), '1'
		inc	hl
		ld	(hl), '3'
; RAM ab 4000h mit Bytefolge 55,F0,AA,0F füllen
		ld	hl, 4000h
		ld	bc, 4000h
test13b:	ld	(hl), 55h
		inc	hl
		dec	bc
		ld	(hl), 0F0h
		inc	hl
		dec	bc
		ld	(hl), 0AAh
		inc	hl
		dec	bc
		ld	(hl), 0Fh
		inc	hl
		dec	bc
		xor	a			; A=0
		cp	c
		jr	nz, test13b
		cp	b
		jr	nz, test13b
;		
test13d:	ld	a, 00001110b
		out	(0F9h),	a
; Speicher lesen		
		ld	hl, 4000h
		ld	bc, 4000h
test13e:	ld	a, (hl)
		inc	hl
		dec	bc
		xor	a			; A=0
		cp	c
		jr	nz, test13e
		cp	b
		jr	nz, test13e
;
		call	83D2h			; **  UP aus 2E11
		jp	test13d

		end
