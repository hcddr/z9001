;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M/3.5M-Modul)
; (c) KOMA Alexander Schön, 2005-2007
;------------------------------------------------------------------------------

		cpu z80
		org 0300h

hi      function x,(x>>8)&255 ; oberes Byte eines 16-Bit-Wortes
lo      function x,x&0000000011111111b;

	
		BINCLUDE "perseus.rom"

mein_start:		
;;		ld	a, 1			; Basicbank
;;		out	0ffh,a			; einschalten 

		; das Programm im Speicher umschreiben 
		; a) die Blockladeroutine
		ld	hl, 0330h		; hier der einsprung zur Blockladeroutine
		ld	(hl), 0cdh		; "CALL"		
		inc 	hl

		ld	(hl), lo(wait)
		inc	hl
		ld	(hl), hi(wait)

		ld	hl, 04a8h
		
		; und nun noch den Sprung am Ende ändern
		ld	(hl), lo (rechange)
		inc	hl

		ld	(hl), hi (rechange)

		call 	0411h

wait:		push	af
		push    bc

		ld	c, 050h
wait_y:		ld	b, 0ffh
wait_x:
		nop
		dec 	b 
		jr	nz, wait_x

		dec	c
		jr	nz, wait_y

		pop	bc
		pop	af
		
		ret

rechange:	; muss sein, damit das Programm richtig gespeichert werden kann.......
		push 	hl
		push	af

		; Blockladeroutine wieder umschreiben 
		ld	hl, 0330h
		ld	(hl), 0eh		; ld c,
		inc	hl

		ld	(hl), 014h		; ,14h
		inc	hl

		ld	(hl), 0cfh		; rst 8

		ld	hl, 04a8h
		ld	(hl), 050h
		inc	hl
		ld	(hl), 08h

		pop	af
		pop	hl

		jp 	0850h			; jetzt geht's endlich los 

		end
