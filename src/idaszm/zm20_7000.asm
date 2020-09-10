; ZM30 von Kassette R0112

	cpu	z80
	include	z9001.inc
	
	org 	7000h
	
ROM	equ	0	; 0 - RAM-Version
ZMKORR	equ	0	; 1 - korrigierte Version der R0112	

	include	zm20.inc
	
	end
