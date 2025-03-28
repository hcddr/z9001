	cpu	z80
;
; Druckertreiber fuer Z9001. "Gedruckt" wird in eine Datei
; V.Pohlers, 2020

; mit Vorsicht zu genieﬂen - es darf kein File-I/O erfolgen, also
; kein LOAD aber auch kein DIR, CD u.a. !!!
; es fehlt ein flush.

;
IOBYT:	EQU	0004H	
LISW:	EQU	0015H	
DMA:	EQU	001BH	
KEYBU:	EQU	0025H	
EOR:	EQU	0036H	
FCB:	EQU	005CH
INTLN:	EQU	0100H	
ATTYL:	EQU	0EFE1H	
TXLST:	EQU	0EFEFH	
GOCPM:	EQU	0F089H	
GVAL:	EQU	0F1EAH	
ERPAR:	EQU	0F5E6H	
DECO0:	EQU	0FD33H	
;
OUTA:	EQU	0F305H
CONS1:	EQU	0F758H		; Interner log. Zeichenausgabe
OC:	EQU	0F97DH		; phys. Bildschirmtreiber

ESC	equ	27
;

	ORG	0B800H	
;
PBEG:	
	JP	INIT	
INTX0:	DB	"FILEPRN "	
	DW	0	

INIT:	
;;	call	dia1		; Parameter verarbeiten
;
;;	LD	HL,PBEG-100H	
;;	LD	(EOR),HL	; EOR darf nicht bei Cassette ge‰ndert werden, sonst FFehler out of memory

; internes ASGN
	LD	DE,INTX0	;Text
	LD	(TXLST),DE	;Zeichenkette fuer LIST eintragen
	LD	HL,TTYL		;TTY-Treiber
	LD	(ATTYL),HL	
	LD	HL,IOBYT	;LIST:=ATTYP
	RES	7,(HL)	
	RES	6,(HL)	
	XOR	A	
	LD	(LISW),A	;kein Copy
;
	CALL	INUP1		;Drucker init.
;
;f. ASGN
	LD 	H,6 		;log. Ger‰tenummer (LIST)
	LD 	L,0 		;phy. Ger‰tenummer (TTY)
	LD 	BC,TTYL 	;Adresse der Zeichenausgabe
	LD 	DE,INTX0
	OR 	A 		;kein Fehler
	RET

;init
INUP1:	ld	hl, prnbuf
	ld	(bufptr), hl

	; fcb name+typ
	ld	hl, myfcb
	ld	de,fcb
	ld	bc,11
	ldir
	ld	hl,4000h
	ld	(fcb+17),hl
	ld	hl,0ffffh
	ld	(fcb+19),hl	; eadr
	ld	(fcb+21),hl	; sadr
	xor	a
	ld	(fcb+23),a	; sby
	ld	c, 15
	call	5		; openw
	RET		
;

;
;***
;
;Druckertreiber
; in A - Kommando
;    C - Zeichen
;
TTYL:	INC	A		;A=0FFH Drucker init. ?
	Jp	Z, INUP1	;Initialisieren und RET
	DEC	A		;A=0?
	JR	NZ, LOA		;sonst
;
; A=0 Status
cLOD1:	LD	A,0FFH	
	OR	A		;Cy=0
	ret
;
; A=2 Zeichenausgabe
LOA:	;call 	OC		; Ausgabe auf Bildschirm
	ld	hl,(bufptr)
	ld	(hl), c
	inc	hl
	ld	(bufptr),hl
	ld	de,prnbuf+128
	or	a
	sbc	hl,de
	jr	c,loa2		; wenn Hl < DE

loend:	ld	hl, prnbuf
	ld	(bufptr),hl

	if 1=1

;;	ld	hl, prnbuf
	ld	(DMA),hl	; DMA setzen
	ld	c,21		; WRITS
	call	5

	ld	c,16		; CLOSW
	call	c,5		; im Fehlerfall File schlieﬂen
	ret

	else
		
; blockausgabe Puffer
	ld	b,128
loa1:	ld	c,(hl)
	push	hl
	push	bc
	call	oc
	pop	bc
	pop	hl
	inc	hl
	djnz	loa1

	endif

;ende, kein fehler
loa2:	or	a
	RET		
;

myfcb:	db	"FILEPRN",0
	db	"PRN"

;RAM-Bereiche
bufptr:	ds 2
prnbuf:	ds 128

	END		
