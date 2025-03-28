;------------------------------------------------------------------------------
; bitbuster-extreme-Entpacker (LZ77 compression)
; orig. source: depack.gen (c) 2002-2003  Team Bomba, modified for Mega-Modul: A.S.
; Anpassung an Mega-Flash: V.Pohlers 2012, UZ-ROM-Modul 2015
;------------------------------------------------------------------------------


;--------------
; in	HL: source (binary)
;       DE: destination

depack:
		ld	a,128

		exx
		ld    de,1
		exx

depack_loop:
		call 	getbits			;get compression type bit
		jr	c,output_compressed	;if set, we got lz77 compression
	;
		ldi				;copy byte from compressed data to destination (literal byte)
		call 	hl_check_adress
		jr	depack_loop

;handle compressed data
output_compressed:
		ld	c,(hl)			;get lowest 7 bits of offset, plus offset extension bit
		inc	hl			;to next byte in compressed data
		call 	hl_check_adress
output_match:
		ld	b,0
		bit	7,c
		jr	z,output_match1		;no need to get extra bits if carry not set

		call 	getbits			;get offset bit 10 
		call 	rlbgetbits		;get offset bit 9
		call 	rlbgetbits		;get offset bit 8
		call 	rlbgetbits		;get offset bit 7

		jr	c,output_match1		;since extension mark already makes bit 7 set
		res	7,c			;only clear it if the bit should be cleared
output_match1:
		inc	bc


;return a gamma-encoded value
;length returned in HL

		exx				;to second register set!
		ld	h,d
		ld	l,e           		;initial length to 1
		ld	b,e			;bitcount to 1

;determine number of bits used to encode value

get_gamma_value_size:
		exx
		call 	getbits			;get more bits
		exx
		jr	nc,get_gamma_value_size_end;if bit not set, bitlength of remaining is known
		inc	b			;increase bitcount
		jr	get_gamma_value_size	;repeat...

get_gamma_value_bits:
		exx
		call 	getbits			;get next bit of value from bitstream
		exx

		adc	hl,hl			;insert new bit in HL
get_gamma_value_size_end:
		djnz	get_gamma_value_bits	;repeat if more bits to go

get_gamma_value_end:
		inc	hl			;length was stored as length-2 so correct this

; !!! hier kein 'call 	checkAdress'

		exx				;back to normal register set

		ret	c	;-> depack_loop verlassen
;HL' = length

		push	hl			;address compressed data on stack

		exx
		push	hl			;match length on stack
		exx

		ld	h,d
		ld	l,e			;destination address in HL...
		sbc	hl,bc			;calculate source address

		pop	bc			;match length from stack

;		ldir				;transfer data
; stattdessen neu vp 17.06.2015 
ldi_Loop	ldi				;transfer data
		call 	hl_check_adress
		jp pe,ldi_Loop  	; Loop until bc = zero

		

		pop	hl		;address compressed data back from stack
		jr	depack_loop

;-------------------
;UP
;getbits: macro to get a bit from the bitstream
;carry if bit is set, nocarry if bit is clear
;must be entered with second registerset switched in!

rlbgetbits
		rl 	b
getbits
		add	a,a		;shift out new bit
		ret	nz		;if remaining value isn't zere, we're done
		ld	a,(hl)		;get 8 bits from bitstream
		inc	hl
		call  	hl_check_adress
		rla			;(bit 0 will be set!!!!)
		ret

;----------------------
;UP Bankumschaltung bei Bankende
hl_check_adress:
		ex   	af,af'		;'

	if megarom == "KOMBI"
		ld	a,(currbank)
		rra				; bit 0 ins Cy-Flag
		ld	a,hi(bankende)		;Ende-ROM-Bereich?
		jr 	nc, hl_check_adress1
		ld	a,hi(bankende2)
hl_check_adress1:
	else
		ld   	a, hi(bankstart+blocksize)
	endif		
		cp   	h
		jr	nz, hl_check_adress_ret

		ld   	h, hi(bankstart)
	; Bank switchen
		call 	l_nextbank		; jr statt jp -> 1 Byte gespart
hl_check_adress_ret:
		ex   	af,af'		;'
		ret
	; ret	übernimmt l_nextbank mit
		
;------------------------------------------------------------------------------
