		cpu	z80

		org 	0300h

start0:		jp	start
		db	"RES     ", 0
		db	0


;12.11.2025 >>>>>>>>>> I/O Reset, Call-5-Reset
IOBYT:		equ	0004h		;IO-Byte
IOST:		equ	0F6E0h		;INITIALISIERUNG STANDARD-E/A
IOST1:		equ	0F712h		;TEILINITIALISIERUNG TREIBER
BOS:		equ	0F314h		;
CRT:		equ	0F8F1h
ACRT1:		equ	0EFCBh
GOCPM:		equ	0F089h
WBOOT:		equ	0F6AEh

start:
		DI
		LD	SP,200H		;CCP- UND ANWENDERSTACK
		LD	A,0C3H		;JMP - CODE
		LD	(0),A		;FUER CALL 0000 UND
		LD	(5),A		;CALL 0005 SPEICHERN
		LD	HL,WBOOT	;ADR. WBOOT FUER CALL 0000
		LD	(1),HL
		LD	HL,BOS		;ADR. BOS FUER CALL 0005
		LD	(6),HL
		LD	A,(IOBYT)
		AND	A, 0FCH		;ZUWEISEN CONST:=CRT
		OR	1		;
		CALL	IOST1		;TEILINITIALISIERUNG TREIBER
		;
		ld	(0FC00h), a	; Schalt-ROM-Modul ausschalten
		out	(7), a		; R/W setzen im 64K-RAM-Modul
		ei

		;ret
		jp	gocpm

		end
