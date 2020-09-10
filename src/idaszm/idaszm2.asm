; IDAS-Modul VP
; 	ZM mit Meldung "Z9001 MONITOR V2.0 (ROM) 1985" und mit EPROM (idaszm2)
; 	ZM hat Register C und E vertauscht wie in ZM30 der Kassette R0112


	cpu	z80

	include	z9001.inc

	org	0D800h
	
	section zm
ROM	equ	2	; 0 - RAM-Version, 1=IDASZM (Centr), 2=IDASZM2 (mit EPROM)
ZMKORR	equ	1	; 1 - korrigierte Version der R0112	

	include	zm20.inc
	endsection

; EPROM
; die Version des IDAS-Moduls weicht etwas von der RAM-Version ab, da hier 
; Code in den ZM-Bereich (Copyright-Meldung) geschrieben wird.
; Der Code an sich stimmt aber überein.

	;org	0e4A8h
ROM	equ	1	
	include	eprom.inc

	end
