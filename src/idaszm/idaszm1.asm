; IDAS-Modul VP
; 	ZM mit Meldung "Z9001 MONITOR V2.0 (ROM) 1985" und mit EPROM (idaszm2)
; 	ZM hat Register C und E vertauscht wie in ZM30 der Kassette R0112


	cpu	z80

	include	z9001.inc

	org	0D800h
	
	section zm
ROM	equ	1	; 0 - RAM-Version, 1=IDASZM (Centr), 2=IDASZM2 (mit EPROM)
ZMKORR	equ	0	; 1 - korrigierte Version der R0112	

	include	zm20.inc
	endsection

; QUICK-TURBO

	;org 0E500h
	align 100h
	binclude	idas_quick.bin

	end
