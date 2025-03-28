	cpu	z80
	org	0bd00h

start:		ld      de, msg
                ld      c, 9
                call    5
                ;jp      0F089h
                or	a
                ret


msg:            db 0Dh,0Ah
                db 14h,6,"PrettyC + Libs 0300-BFFF geladen!",0Dh,0Ah
                db "Kommandos: EC GO CC C@ R@ CHS...",14h,2,0Dh,0Ah,0

	end
	