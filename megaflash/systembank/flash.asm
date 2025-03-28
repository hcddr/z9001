;------------------------------------------------------------------------------
; Z9001 MEGA-FLASH-Modul (2.5M-Modul)
; (c) V. Pohlers 2012
; letzte Änderung
;------------------------------------------------------------------------------
; Systembank: Flash-Programmierung
;------------------------------------------------------------------------------

	cpu	z80

AM29	equ	1
AT29	equ	2

;;	; Hersteller; typ, rule, id, sa_size, twc
;;	"WINBOND", "W29C020", AT29, 0DA45h, 256*1024, 128, 10
;;	"WINBOND", "W29C040", AT29, 0DA46h, 512*1024, 256, 10
;;

		org	1000h
		
		jp	start1
		db	"FLASH1  ",0
		jp	start2
		db	"FLASH2  ",0
		jp	test
		db	"FWRITE  ",0
		db	0


; modified: a, hl
chip_put_byte	macro byte, adr
		ld	a,adr>>11		;bank = A18..A11
		out	(0ffh),a
		ld	hl,adr&7ffh		;addr = A10..A0 + chip-base
		add	hl,de
		ld	a,byte
		ld	(hl), a
		endm

; in c: 3. Byte
; modified: a, hl
chip_seq	chip_put_byte 0AAh, 05555h 
		chip_put_byte 055h, 02AAAh 
		chip_put_byte C, 05555h
		ret

; reset
; in: DE = chip_base, z.B. 0c000h
; modified: a, bc, hl
chip_reset:	call	delay
;;		chip_put_byte 0AAh, 05555h 
;;		chip_put_byte 055h, 02AAAh 
;;		chip_put_byte 0F0h, 05555h
		ld	c, 0F0h
		call	chip_seq
		call	delay
		ret

; get_id
; in: DE = chip_base, z.B. 0c000h
; modified: a, bc, hl
get_id:		call	chip_reset
;;		chip_put_byte 0AAh, 05555h 
;;		chip_put_byte 055h, 02AAAh 
;;		chip_put_byte 090h, 05555h
		ld	c, 090h
		call	chip_seq
		call	delay
		ld	a, 0			; Adr 0
		out	(0ffh), a
		ld	hl, 0			; id (Byte 00000 und 00001)
		add	hl,de
		ld	a,(hl)
		inc	hl
		ld	l,(hl)
		ld	h,a			; HL := id
		push	hl
		call	chip_reset
		pop	hl
		ret

; erase full chip
; in: DE = chip_base, z.B. 0c000h
erase:		call	chip_reset
;		chip_put_byte 0AAh, 05555h 
;		chip_put_byte 055h, 02AAAh 
;		chip_put_byte 080h, 05555h 
		ld	c, 080h
		call	chip_seq
;		chip_put_byte 0AAh, 05555h 
;		chip_put_byte 055h, 02AAAh 
;		chip_put_byte 010h, 05555h 
		ld	c, 010h
		call	chip_seq
		call	delay
		ret

; write block
; in: HL = von, DE = zieladr, bank
write:		di
		push	de
		push	hl
		call	calc_base
;		chip_put_byte 0AAh, 05555h 
;		chip_put_byte 055h, 02AAAh 
;		chip_put_byte 0A0h, 05555h 
		ld	c, 0A0h
		call	chip_seq
		ld	a,(bank)
		out	(0ffh),a
		pop	hl
		pop	de
		ld	bc, 128			; sa_size
		ldir				; schreiben
		ei	
		call	delay
		ret

; delay	twc
; modified: b, c
delay:		ld	c, twc			; 10 ms
delay2:		ld	b, 200			; 1 ms
delay1:		djnz	delay1			; 13 Takte, 1 Takt ~ 0,4µs, also ~ 5 µs
		dec	c
		jr	nz, delay2
		ret

; in: de = adr; out de := basis_adr. (c000, c800, .., e800)
calc_base:	ld	e,0
		ld	a,d
		and	0f8h
		ld	d,a			; de = base
		ret

;------------------------------------------------------------------------------
; FLASH
;------------------------------------------------------------------------------

start1		
		ld	de,0c000h		;base chip a
		call	get_id
		call	PRST7
		db	"CHIP A ID", '='+80h
		call	outhl	
		call	ocrlf

		ld	de,0c800h		;base chip b
		call	get_id
		call	PRST7
		db	"CHIP B ID", '='+80h
		call	outhl	
		call	ocrlf

		ld	de,0d000h		;base chip c
		call	get_id
		call	PRST7
		db	"CHIP C ID", '='+80h
		call	outhl	
		call	ocrlf

		ld	de,0d800h		;base chip d
		call	get_id
		call	PRST7
		db	"CHIP D ID", '='+80h
		call	outhl	
		call	ocrlf

		ld	de,0e000h		;base chip e
		call	get_id
		call	PRST7
		db	"CHIP E ID", '='+80h
		call	outhl	
		call	ocrlf
		ret


; Version 2
start2		ld	de,0c000h		;base chip a
		ld	b,5
start2a		
		push	de
		push	bc
				
		call	get_id
		call	PRST7
		db	"CHIP", ' '+80h
		ld	a, 'F'
		pop	bc
		sub	b
		push	bc
		call	outa			; Chip-Buchstabe A..E	
		call	PRST7
		db	" ID", '='+80h
		call	outhl	
		call	ocrlf

		pop	bc
		pop	de
		ld	hl,800h
		add	hl,de
		ex	de,hl
		djnz	start2a
		
		ld	a,0
;		out	(0ffh),a
		ret
	
;-------------------------------------------------------------------------------
; FWRITE schreiben
;-------------------------------------------------------------------------------

test		ld	hl, 1000h
		ld	de, 0e200h
		ld	a, 42h
		ld	(bank), a
		call	write
		ret

twc:		equ	10
bank:		ds	1

;-------------------------------------------------------------------------------
; Unterprogramme
;-------------------------------------------------------------------------------
;
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H
;

;Ausgabe String bis Bit7=1
;
PRST7:		EX	(SP),HL			;Adresse hinter CALL
PRS1:		LD	A,(HL)
		INC	HL
		PUSH	AF
		and	7FH
		CALL	OUTA
		POP	AF
		BIT	7,A			;Bit7 gesetzt?
		JR	Z, PRS1			;nein
		EX	(SP),HL			;neue Returnadresse
		RET

;OUTHL Ausgabe (HL) hexa
;
OUTHL:		LD	A,H
		CALL	OUTHX
		LD	A,L
;
;OUTHX Ausgabe (A) hexa
;
OUTHX:		PUSH	AF
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	OUTH1
		POP	AF
OUTH1:		AND	A, 0FH
		ADD	A, 30H
		CP	A, 3AH
		JR	C, OUTH2
		ADD	A, 07H
OUTH2:		CALL	OUTA
		RET

		end
