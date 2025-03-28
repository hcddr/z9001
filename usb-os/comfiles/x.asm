; sd-os rootloader, auf SD-Karte als "load87" ablegen (KCC-Format)
; V. Pohlers 01/2025
; lädt und startet das eigentliche System

		cpu	z80

; BDOS
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H

fcb		equ	005ch
conbu		equ	0080h
dma		equ	001Bh

dbg		equ	1		; 1 mit Ausgabe


;-------------------------------------------------------------------------------	

		org	300h

		jp	start
		db	"X       ",0
		db	0

;-------------------------------------------------------------------------------	

start:		call	sdinit	
		; openr
		ld	a, 0f1h		; open read
		call	outbyte
		ld	b,12		; Filename.Typ, 12 Zeichen senden
		ld	hl, filename	; zu ladende Datei
		; ohne RAM-Modul nur Miniversion laden
		ld	a,(37h)
		cp	3Fh		; hi(3FFF), nur 16K RAM?
		jr	nz, l1		; nein
		ld	hl, filename38	; ja, dann andere Datei
		;

l1:		if	dbg=1
		push	hl
		pop	de
		ld	c,9
		call	5
		endif

l2:		ld	a,(hl)		; send filename
		call	outbyte
		inc	hl
		djnz	l2
;				
		call	mode_in
		call	getbyte		; read_result_byte
		cp	0feh		; Fehler?
		jp	z, t4_err
;
		call	ocrlf
		
		; read headerblock
		ld	hl,conbu
		call	readblk
		ld	hl,(conbu+21)	; sadr
		ld	(fcb+21),hl	; merken

		; read all blocks
		ld	hl,(conbu+17)	; aadr
		if dbg=1
		call	outhl
		call	ocrlf
		endif
l3:		call	readblk0
		or	a
		jr	nz,l3		; weiterlesen, wenn voller Block

		; close file
		call	sdinit	
		ld	a, 0f0h		; close file
		call	outbyte

		; File eingelesen, jetzt starten
		call	ocrlf
		ld	hl,(fcb+21)	; sadr
		if dbg=1
;		call	outhl
		endif
		jp	(hl)
; alternativ Ende
;		xor	a
;		ret			; ret. zum OS

; Daten konnte nicht geöffnet werden --> Abbruch
t4_err		ld	a,13		; BOS-error: file not found
		scf
		ret

;-------------------------------------------------------------------------------	
; in hl: adr
; ret a=anz bytes

readblk0:	call	ospac
readblk:	call	sdinit
		ld	a, 0f2h		; open read
		call	outbyte
		call	mode_in
		call	getbyte		; read_result_byte anz daten
readblk1:	or	a
		ret	z		; 0 Bytes
		push	af		; merken f. ende
		; read b bytes
		ld	b,a
readblk2:	call	getbyte
		ld	(hl),a
		inc	hl
		djnz	readblk2
		;
		pop	af
		ret

;-------------------------------------------------------------------------------	

	include ../system/SD.asm

;-------------------------------------------------------------------------------	

filename	db	"SDOS.COM",0		; zu ladende Datei bei 48K RAM
filename38	db	"SDOS38.COM",0		; zu ladende Datei bei 16K RAM

;------------------------------------------------------------------------------
; LIB
;------------------------------------------------------------------------------

		if dbg=1

;OUTHL Ausgabe (HL) hexa
;
OUTHL:		LD	A,H
		CALL	OUTHX
		LD	A,L
;
;OUTHX Ausgabe (A) hexa
;
OUTHX:		PUSH	AF
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	OUTH1
		POP	AF
OUTH1:		AND	A, 0FH
		ADD	A, 30H
		CP	A, 3AH
		JR	C, OUTH2
		ADD	A, 07H
OUTH2:		CALL	OUTA
		RET


OUTHXA:		PUSH	AF
		call	outhx
		pop	af
		ret

;Ausgabe String bis 00

PRST0:		EX	(SP),HL
XOUt4:		LD	A,(HL)
		INC	HL
		OR	A
		jr	Z,XOUT2
		CALL	OUTA
		JR	XOUt4
XOUT2:		EX	(SP),HL
		RET

	endif

;------------------------------------------------------------------------------

		end
