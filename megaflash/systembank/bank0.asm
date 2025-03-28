;------------------------------------------------------------------------------
; Z9001 MEGA-FLASH-Modul (2.5M-Modul)
; (c) V. Pohlers 2011
; letzte Änderung 14.03.2014 10:53
;------------------------------------------------------------------------------

		cpu	z80

		include	../includes.asm
	
		org	0c000h
	
;-------------------------------------------------------------------------------
; die System-Software
;-------------------------------------------------------------------------------

		binclude	"system.bin"
	

	if megarom == "KOMBI"
;-------------------------------------------------------------------------------
; RTC+DAT+neue Meldung
;-------------------------------------------------------------------------------

		org	0CF00h
		
		if	rom_uzander = 0
		binclude	"..\uz\clean.bin"	
		else
		binclude	"..\uz\clean_cf00.rom"	
		endif
	endif

	if 1=1
;------------------------------------------------------------------------------
;C000 ZM30 mit Verschieberahmen

		org	0d000h
                jp      loc_C00D
          	db	"ZM30    ",0
                db    0

loc_C00D:       ld      hl, 0d020h
                ld      de, 3000h
                ld      bc, 0DFFh
                ldir
                jp      3000h
;------------------------------------------------------------------------------
		org	0d020h

		if	rom_uzander = 0

		binclude	"..\vp\zm20a_3000.bin"
; Patch: Transientkommando-Rahmen
;		org	0d020h+0c00h+0fh
;orig		db 	"ZM      ",0
;		db 	"ZM3     ",0

		else
;19.10.2018 ulrichs variante. leider nicht systemkompatibel
		binclude	"..\uz\zm30_uz.rom"
		endif
	endif ; 1=1
	
;-------------------------------------------------------------------------------
; weitere Programme
;-------------------------------------------------------------------------------

includeprg	equ	true

;		align 100h
;		section	crc
;		include	"crc.asm"
;		endsection

		align 100h
		section	window
		include	"window.asm"
		endsection

		align 100h
		section	sdx
		include	"sdx.asm"
		endsection

;;		align 100h
;;		section	v24x
;;		include	"v24x.asm"
;;		endsection

		org	0E400h
		binclude	"rtcdat_uz.bin"

	if megarom == "KOMBI"
;------------------------------------------------------------------------------
; Patchen System-Programm
;     C025 : C3 FF FF            on_reset:	jp	0ffffh	; RET
;     C028 : C3 FF FF            on_cold:	jp	0ffffh	; RET
;     C02B : C3 FF FF            on_gocpm:	jp	0ffffh	; RET
;------------------------------------------------------------------------------

		org	syserw

syserw_uz	equ	0E460h		
		jp	syserw_uz	; reset
		jp	syserw_uz+3	; cold
		jp	syserw_uz+6	; gocpm
;------------------------------------------------------------------------------
	endif
	
	if megarom <> "KOMBI"
	org	0E400h
		binclude	"rtcdat_gide.bin"
	
	endif

;------------------------------------------------------------------------------

	message "======================================="
	message	"bank0.bin erstellt fuer: \{megarom}"
	message "======================================="


		end
