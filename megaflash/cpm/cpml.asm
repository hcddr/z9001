;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M-Modul)
; (c) V. Pohlers 2011
; letzte Änderung 10.03.2012
;------------------------------------------------------------------------------
; Loader für diverse CP/M-Versionen
; als Besonderheit wird nach dem Laden der MEGA-ROM weggeschaltet
;------------------------------------------------------------------------------

		cpu	z80undoc

rst_sbos	equ	28h		;der RST für den Sprungverteiler

;;	0	;OUTHX	Ausgabe (A) hexa
;;	1	;OUTHL	Ausgabe (HL) hexa
;;	2	;WAIT	Unterbrechung Lauf
;;	3	;color	Vordergrundfarbe (E)
;;	4	;CPROM	Suchen Namen
;;	5	;FMOV	FA-Programm in Speicher kopieren
;;	6	;FRUN	FA-Programm starten
;;	7	;KDOPAR	Kommandoparameter aufbereiten
;;	8	;INHEX	Konvertierung ASCII-Hex ab (DE) --> (HL)
;;	9	;PRST7	Ausgabe String bis Bit7=1


CR:     EQU     0DH  
LF:     EQU     0AH  
ROT:    EQU     0114H
GRUEN:  EQU     0214H
GELB:   EQU     0314H
BLAU:   EQU     0414H
MAGENTA:EQU     0514H
CYAN:   EQU     0614H
WHITE:  EQU     0714H


conbu		equ	0080h
GVAL    	EQU	0F1EAh

		org	300h

		ld	de, startmsg
		ld	c,9
		call	5

start1:		ld	c,1		; consi
		call	5
		cp	03h		; STOP	-> Abbruch/Ende
		ret	z
		cp	'1'             ; Pgm. 1
		LD	HL,cpm1
		jr	z, start2
		cp	'2'             ; Pgm. 2
		LD	HL,cpm2
		jr	z, start2
		cp	'3'             ; Pgm. 3
		LD	HL,cpm3
		jr	z, start2
		;
		jr	start1

start2:		ld	(auswahl),a
		ld	e,a		; auswahl anzeigen
		ld	c,2		; conso
		call	5
		
		ld	de, loadmsg
		ld	c,9
		call	5
		
		; HL=Adr. Programmname
		; INTLN mit Programmnamen füllen (Länge, pgm-name, 0)
		ld	de,CONBU+2
		ld	bc,9
		ldir
		CALL	GVAL		;PARAMETER HOLEN
		; Programm suchen
		LD IYl,0FFh		;suchtyp für FA-Rahmen
		rst	rst_sbos
		db	4		;CPROM	TRANSIENTKOMMANDO SUCHEN
		jr	z, cmpl
		; nicht gefunden
		rst	rst_sbos
		db	9
		db	"not found!",0Dh,8Ah
		ret
cmpl:		; gefunden
		; wir setzen voraus, dass es ein FA-Programm ist...
		rst	rst_sbos
		db	5		;FMOV nach AAdr. im Speicher kopieren

;;		rst	rst_sbos
;;		db	6		;FRUN je nach Typ starten

		ld	a,(auswahl)
		cp	'3'
		jr	z, cpm48k


		; speziell CP/M
		ld	(0FC00h), a	; ROM-Modul ausschalten
		in	a, (7)		; R/W setzen im RAM-Modul
		ld	a, 0		; Boot-Laufwerk

		jp	8000h+1600h	; starten des BIOS

cpm48k:		ld	a, 0		; Boot-Laufwerk
		jp	4000h+1600h	; starten des BIOS

;------------------------------------------------------------------------------

startmsg
	        dw GELB
	        db CR, LF
	        db "CP/M-Loader", cr, lf
	        DB "-----------", CR, LF    
	        db CR, LF
	        dw gruen
	        db "1 - CP/M orig. robotron", CR, LF
	        db "2 - CP/M orig. ZFK Rossendorf", CR, LF
	        db "3 - CP/M 48K robotron", CR, LF
	        db CR, LF
	        dw white
	        db "Auswahl: "
	        db 0

loadmsg:	dw gruen
		db CR, LF
		db CR, LF, "lade...",0

; die zu ladenden Programme dürfen diesen Loader nicht überschreiben !!

cpm1		db	"CPM-R",0
cpm2		db	"CPM-ZFK",0
cpm3		db	"CPM-48K",0

auswahl		ds	1

		end
