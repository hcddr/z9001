;------------------------------------------------------------------------------
; Anpassung an Mega-Flash: V.Pohlers 2021
;------------------------------------------------------------------------------

; -----------------------------------------------------------------------------
; ZX7 decoder by Einar Saukas, Antonio Villena & Metalbrain
; "Standard" version (69 bytes only)
; -----------------------------------------------------------------------------
; Parameters:
;   HL: source address (compressed data)
;   DE: destination address (decompressing)
; -----------------------------------------------------------------------------
; RET HL = Endadr

depack:

dzx7_standard:
        ld      a, 80h
dzx7s_copy_byte_loop:
        ldi                             ; copy literal byte
        call 	hl_check_adress
dzx7s_main_loop:
        call    dzx7s_next_bit
        jr      nc, dzx7s_copy_byte_loop ; next bit indicates either literal or sequence

; determine number of bits used for length (Elias gamma coding)
        push    de
        ld      bc, 0
        ld      d, b
dzx7s_len_size_loop:
        inc     d
        call    dzx7s_next_bit
        jr      nc, dzx7s_len_size_loop

; determine length
dzx7s_len_value_loop:
        call    nc, dzx7s_next_bit
        rl      c
        rl      b
        jr      c, dzx7s_exit           ; check end marker
        dec     d
        jr      nz, dzx7s_len_value_loop
        inc     bc                      ; adjust length

; determine offset
        ld      e, (hl)                 ; load offset flag (1 bit) + offset value (7 bits)
        inc     hl
        call 	hl_check_adress
        db      0cbh, 033h              ; opcode for undocumented instruction "SLL E" aka "SLS E"
        jr      nc, dzx7s_offset_end    ; if offset flag is set, load 4 extra bits
        ld      d, 10h                  ; bit marker to load 4 bits
dzx7s_rld_next_bit:
        call    dzx7s_next_bit
        rl      d                       ; insert next bit into D
        jr      nc, dzx7s_rld_next_bit  ; repeat 4 times, until bit marker is out
        inc     d                       ; add 128 to DE
        srl	d			; retrieve fourth bit from D
dzx7s_offset_end:
        rr      e                       ; insert fourth bit into E

; copy previous sequence
        ex      (sp), hl                ; store source, restore destination
        push    hl                      ; store destination
        sbc     hl, de                  ; HL = destination - offset - 1
        pop     de                      ; DE = destination
        ldir

;;dzx7s_exit:
        pop     hl                      ; restore source address (compressed data)
        jr      nc, dzx7s_main_loop
        
dzx7s_next_bit:
        add     a, a                    ; check next bit
        ret     nz                      ; no more bits left?
        ld      a, (hl)                 ; load another group of 8 bits
        inc     hl
        call  	hl_check_adress
        rla
        ret

dzx7s_exit:	
	pop	de			 ; get last dest addr. + 1
	ret
	
; -----------------------------------------------------------------------------
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
		call 	l_nextbank
hl_check_adress_ret:
		ex   	af,af'		;'
		ret
		
;------------------------------------------------------------------------------
