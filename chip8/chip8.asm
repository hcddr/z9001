;------------------------------------------------------------------------------
; CHIP8-Interpreter
; V.Pohlers, 2013 / 2021
;------------------------------------------------------------------------------

		cpu	z80

;-----------------------------------------------------------------------------
; AS-Funktionen
;-----------------------------------------------------------------------------

; obere 8 Bit: hi(CONBU)
hi              function x,(x>>8)&255

; untere 8 Bit: lo(CONBU)
lo              function x, x&255

; bws(zeile 0..23, spalte 0..39) analog print_at
;bws		function z,s,z*40+s+0EC00h
;bwsc		function z,s,z*40+s+0E800h

; bws(zeile 1..24, spalte 1..40) analog print_at
bws1		function z,s,(z-1)*40+(s-1)+0EC00h
bwsc1		function z,s,(z-1)*40+(s-1)+0E800h


;------------------------------------------------------------------------------
; Hauptprogramm f. Z9001
; v0.4 mit 4tel Grafik
;------------------------------------------------------------------------------

		org	300h

		jp	anf
		db	"CHIP8   ",0
		db	0

		
;------------------------------------------------------------------------------
; Hauptprogramm
;------------------------------------------------------------------------------

prgm		equ	4		; testpgm


anf:		call	smallwindw
		ld	hl,RAME
		ld	(PRGEND),hl

;
start:		call	initscr

; vorerst 4 Programme hart verdrahtet
start0:		ld	c,1
		call	5
		cp	'S'
		jp	z,save
		cp	'L'
		jp	z,load
		cp	'D'
		jp	z,dir
		cp	1Dh	; RUN
		jr	z, start2
		cp	1Ch	; LIST
		jr	z, start3

		cp	'0'
		jr	nz, .m1
		; RAM mit 0 füllen
		ld	hl,RAMB
		ld	(PRGEND),HL
		call	clrram
		jr	start

		; beispiele
.m1:		cp	'1'		; 1 - Programm 1	IBM_Logo
		ld	hl, prg1
		ld	bc, prg2-prg1
		jr	z,start1
		cp	'2'		; 2 - Programm 2	Breakout
		ld	hl, prg2
		ld	bc, prg3-prg2
		jr	z,start1
		cp	'3'		; 3 - Programm 3	panzer
		ld	hl, prg3
		ld	bc, prg4-prg3
		jr	z,start1
		cp	'4'		; 4 - Programm 4	pong2
		ld	hl, prg4
		ld	bc, prg4end-prg4
		jr	z,start1
		; 
		cp	3		; STOP - Ende 
		; sonst neue Eingabe
		jr	nz, start0
		; Ende
		call	fullwindw
;		ld	e,12		; CLS
;		ld	c,2
;		call	5
		RET


; Pogramm laden
start1		; ld	hl, prg
		ld	de, RAMB
		;ld	bc, 400h	; max.Länge in dieser Demo
		ldir
		ld	(PRGEND),DE
	
		call	clrram		; RAM leeren
; Interpreter starten		
start2:		ld	c,29	; DCU
		CALL 5


		ld	hl, RAMB
		call	chip8
; Ende
;		ld	a,0
;		ld	(25h),a
;
start2a:	ld	c,1
		call	5	; keypuffer leeren
		
		jp	start
		

; Editor
start3:		call	cmd_hexi
		push	af
		
		ld	bc, RAME-RAMB	; Größe RAM
		ld	hl, RAME
		ld	a, 0
start3a:	cpd
		jr	nz, start3b
		jp	pe, start3a
		
start3b:	inc	hl
		ld	(PRGEND), HL
		pop	af
		cp	1DH	; RUN?
		jr	z, start2
		
		jp	start

;------------------------------------------------------------------------------
; speicher leeren ab PRGEND bis RAME

clrram		ld	HL,RAME
		ld	DE,(PRGEND)
		or	a
		SBC	HL,DE
		ex	de,hl		; hl=(RAMEND)
		push	hl
		push	de
		pop	bc		; bc=Länge
		pop	de		; de=(RAMEND)
		inc	de
		ld	(hl),0
		ldir
		ret	

;------------------------------------------------------------------------------
; Test-Programme
;------------------------------------------------------------------------------


; 
prg1
		binclude IBM_Logo.ch8
		
		if 1=0		
;wandernde 8
prg2
		db	0a2h, 010h
		db	061h, 000h
		db	062h, 000h
		db	0d1h, 025h
		db	0d1h, 025h
		db	71h,01h
		db	72h,01h
		db	012h, 006h
		db	0f0h, 090h
		db	0f0h, 090h
		db	0f0h, 000h
		
		else

prg2
		binclude	Breakout.ch8

		endif

; panzer
prg3
		db	061h, 020h
		db	062h, 010h
		db	0a2h, 040h
		db	0d1h, 027h
		db	060h, 002h
		db	0e0h, 0a1h
		db	012h, 016h
		db	070h, 002h
		db	030h, 00ah
		db	012h, 00ah		
		db	012h, 008h
		db	0d1h, 027h
		db	040h, 002h
		db	072h, 0ffh
		db	040h, 004h
		db	071h, 0ffh
		db	040h, 006h
		db	071h, 001h
		db	040h, 008h
		db	072h, 001h
		db	040h, 002h
		db	0a2h, 040h
		db	040h, 004h
		db	0a2h, 053h
		db	040h, 006h
		db	0a2h, 04dh
		db	040h, 008h
		db	0a2h, 046h
		db	012h, 006h
		org 	prg3+40h
		db	010h
		db	054h
		db	07ch
		db	06ch
		db	07ch
		db	07ch
		db	044h
		db	07ch
		db	07ch
		db	06ch
		db	07ch
		db	054h
		db	010h
		db	00h
		db	0fch
		db	078h
		db	06eh
		db	078h
		db	0fch
		db	000h
		db	03fh
		db	01eh
		db	076h
		db	01eh
		db	03fh
		db	00h
		db	00h
		db	00h
		
; pong2
prg4
		binclude	pong2.ch8		


prg4end


;------------------------------------------------------------------------------
; SAVE/LOAD
;------------------------------------------------------------------------------

fext	db	"CH8"	

save:	call	dir0

	ld	hl,RAMB
	LD	(fcb+17),HL	; AADR
	ld	HL,(PRGEND)
	LD	(fcb+19),HL	; EADR
	ld	a,'N'
	ld	(fcb+24),a	; kein Block 0 lesen/schreiben, nur Datei öffnen	
	
	ld	a,82h		; Filename abfragen
	ld	ix,fext		; Filetyp BIN
	ld	c, 35		; CSAVE
	call	5
	jr	enter

;------------------------------------------------------------------------------

load:	call	dir0
	
	ld	a,'N'
	ld	(fcb+24),a	; kein Block 0 lesen/schreiben, nur Datei öffnen	
	LD	HL,RAMB		; neue Zieladr.
	ld	a,82h		; Abfrage "Filename:"
	ld	ix,fext		; Filetyp BIN
	ld	c,34		; CLOAD
	call	5
	jr	c, enter
	
	ld	hl,(fcb+25)	; LEADR
	ld	(PRGEND), hl

	call	clrram		; RAM bis RAME leeren

	call	initscr		; schnelles cls
	jp	start2
	
	
;------------------------------------------------------------------------------

enter:	ld	de,entertxt
	ld	c,9
	call	5
	ld	c,1
	call	5
	jp	start

entertxt db 0dh,0ah,"<ENTER>",0

;------------------------------------------------------------------------------

dirz:	db	"?CH8",0	; entspricht *.CH8
;
dir:	call	dir0
	jr	enter

dir0:	call	cls
	ld	hl,P4ROL	; letzte zu rollende Spalte + 1
	ld	a,(hl)
	push	af
	ld	a,3*9+2
	ld	(hl),a
	ld	a,0C0h		; mit Suchmuster, keine Ext. anzeigen
	ld	de,dirz		; Suchmuster
	ld	c,19		; DIRS
	call	5		
	pop	af
	ld	(P4ROL),a
	ret

;------------------------------------------------------------------------------
; UPs
;------------------------------------------------------------------------------


;kleines Eingabefenster at 2,2 .. 17,33 (zeile, spalte)

smallwindw:	ld	hl, (17+1)*100h+(2-1)
		ld	(P1ROL), hl
		ld	hl, (33+1)*100h+(2-1)
		ld	(P3ROL), hl

;		ld	hl, bws1(2,2)	; Cursor auf Fenster setzen
;		ld	(CURS), hl
;
;		ld	hl, bwsc1(2,2)	; Farbattribut übernehmen
;		ld	a,(hl)
;		ld	(ATRIB),a

		ld	a,20h		; grün auf schwarz
		ld	(ATRIB),a

		ld	a, 0Ch		; CLS
		call	outa
		ret

; volles Fenster
fullwindw:	ld	hl, 1900h	; 1-24 (25,0)
		ld	(P1ROL), hl
		ld	hl, 2900h	; 1-40 (41,0)
		ld	(P3ROL), hl

		ld	a,20h		; grün auf schwarz
		ld	(ATRIB),a

cls:		ld	a, 0Ch
		call	outa
		ret


; Hauptfenster zeichnen
initscr		

	; Hintergrundbild/Oberfläche zeichnen
	ld	hl,mainpic
	call	decomp
	ret
	
;------------------------------------------------------------------------------
; Hintergrundbild 
;------------------------------------------------------------------------------

mainpic
	binclude PICTURE8.COM.pic

;------------------------------------------------------------------------------
; decompact-routine f. Hintergrundbild
; in HL - Adr. gepacktes Bild
;------------------------------------------------------------------------------

decomp:		ld	de, 0E800h	; ziel
decomp1:	ld	a, (hl)
		cp	1		; 1 - Ende
		ret	z
		or	a		; 0 - RLE
		jr	z, decomp3
		ld	(de), a		; sonst zeichen übernehmen
		inc	de
decomp2:	inc	hl
		jr	decomp1
decomp3:	inc	hl
		ld	a, (hl)		; zeichen
		inc	hl
		ld	b, (hl)		; anzahl
decomp4:	ld	(de), a
		inc	de
		djnz	decomp4
		jr	decomp2

;------------------------------------------------------------------------------
; Std.-Lib.
;------------------------------------------------------------------------------

	include	z9001.asm

;------------------------------------------------------------------------------
; Hexeditor
;------------------------------------------------------------------------------

	include	chip8hexi.asm

;------------------------------------------------------------------------------
; Interpreter
;------------------------------------------------------------------------------


;		align 100h

; Schnittstelle zum System
		include	chip8intf.asm

;		align 100h

; Systemunabhängiger Interpreter
		include	chip8intp.asm


PRGEND		ds	2		; Programmende


RAMB		equ	2000h		; Arbeitsspeicher für CHIP8, 0E00h Bytes
RAME		equ	RAMB+0E00h-1
;--------------------------------------------------------------


	END
