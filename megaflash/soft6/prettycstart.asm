; (patched) prettyc + clib + cmd + sieb + startmsg

	cpu	z80
	
	org	300h
	binclude	PRETTYC.ROM, 128	; umbenannte KCC-Datei
						; Header überlesen
						; Load-Patch + EOR = B5FF gesetzt
	
	org	08000h
	binclude	EC_SIEB.ROM, 128	; umbenannte KCC-Datei
						; Header überlesen
	

start:		ld      de, msg
                ld      c, 9
                call    5
                ;jp      0F089h
                or	a
                ret


msg:            db 0Dh,0Ah
                db 14h,6,"PrettyC + Libs 0300-BFFF geladen!",0Dh,0Ah
                db "Kommandos: EC GO CC C@ R@ CHS...",14h,2,0Dh,0Ah,0

	end start
	