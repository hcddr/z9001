		cpu	z80
		org	3C00h

		jp	cmd_hexi
		db 	"H       ",0
		db    	0

caddr:		dw 	RAMB		; aktuelle Adresse
cupos:		dw 	0EC52h		; aktuelle Bildschirmposition
ccol:		db 	0		; aktuelle Spalte (0..xx)
cline:		db 	0		; aktuelle Zeile (0..xx)

;------------------------------------------------------------------------------
; 
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
		ADD	A, '0'
		CP	A, 3AH
		JR	C, .m2
		ADD	A, 07H
.m2:		ld	(hl), a
		inc	hl
		RET

; konvertiere DE hexadezimal nach (HL..HL+4)
conde:
		ld	a, d
		call	conhx
		ld	a, e
		call	conhx
		ld	(hl), ' '
		inc	hl
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

; Anzeigen einer Zeile
		
line:		push	de
		push	hl
		ld	hl,10000h - RAMB + 200h
		add	hl,de
		ex	hl,de
		pop	hl
		call	conde
		pop	de
;
		ld	b, 8		; 8 Byte pro Zeile
.m1:		ld	a, (de)
		call	conhx
		inc	de
		ld	(hl), ' '
		inc	hl
		djnz	.m1
		ret

; Anzeigen 16 Zeilen

line16:		ld	b,16
.m1:		push	bc
		call	line
		ld	bc,11
		add	hl,bc
		pop	bc
		djnz	.m1
		ret
		
;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

; window	2..17 zeile, 2..33 spalte

cmd_hexi
		ld	de, (caddr)
		ld	hl, (cupos)
		call	line16
		;
		
edit1		ld	c,1
		call	5
		cp	1Bh	; ESC
		jp	z, editend
		cp	8
		jp	z, culeft
		cp	9
		jp	z, curight
		cp	0ah
		jp	z, cudown
		cp	0bh
		jp	z, cuup
		;0..9,a..F
		jr	edit1

; Ende		
editend:	xor	a
		ret

; cudown
cudown		;prüfen ob erste adr < RAME-80H
		;nach oben scrollen
		jp	edit1


		
;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------
		
RAMB		equ	2000h		; Arbeitsspeicher für CHIP8, 0E00h Bytes
RAME		equ	RAMB+0E00h-1
		