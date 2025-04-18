;------------------------------------------------------------------------------
; Z9001 USB-Modul
; (c) V. Pohlers 2019-2025
;------------------------------------------------------------------------------
; Konfiguration SD-OS ROM-Modul C000
;------------------------------------------------------------------------------

	cpu	z80undoc

; Connector
p_connector	equ	2	; 0 - VDIP	--> Port �ndern in VDIP.asm
				; 1 - CH376	--> Port �ndern in ch376.asm
				; 2 - SD-Module
				
; optionale Bestandteile
; 0 - Bestandteil wird nicht eingebunden
; 1 - Bestandteil wird eingebunden (default)
p_crt	equ	1	; fast CLS + zus�tzl. Tasten
p_help	equ	1	; HELP-Kdo
p_zmon	equ	1	; Monitorzusatzkommandos
			; MENU, DUMP, FILL, TRANS, RUN, IN, OUT, MEM, EOR, LOAD, SAVE, FCB
p_sysinfo equ	0	; Systeminfo-Programm im ROM

;
p_load_nore	equ	1	; 1 - nur 1x LOAD-Versuch, kein "rewind" (default)
				; 0 - bekanntes OS-Verhalten (Fehlerausgabe, neuer Versuch)
				; 0 ist bei USB wenig sinnvoll
p_load	equ	1	; 1 - HELP-Kdo nutzt USBOS-Load-Routine (default)
			; 0 - HELP-Kdo nutzt eigene Load-Routine

;-------------------------------------------------------------------------------

	org	0c000h

	include	system/modul.asm

;-------------------------------------------------------------------------------
		END
