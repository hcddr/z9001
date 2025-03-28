;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M-Modul)
; (c) V. Pohlers 2011
; letzte Änderung 04.04.2012
;------------------------------------------------------------------------------
; Systembank: HELP-Kommando
;
; A C H T U N G : on-the-fly-Entpacken und gleich Anzeigen geht nicht wg. Rückbezug des
; Packalgorithmus auf vorhandene Textstücke. Deshalb wird in den Shadow-RAM entpackt.
;------------------------------------------------------------------------------

		section help


		cpu	z80undoc

standalone	equ	0		; 0 - internes Systemkommando, 1 - eigenständiges Programm
shadow_buf	equ	7800h		; Adr. zum Entpacken der Hilfetexte
					; wenn vorhanden, wird der Shadow-RAM genutzt
ram_buf		equ	3800h		; ansonsten wird diese RAM-Adr. genutzt

RED:    		EQU     0114H
GREEN:  		EQU     0214H
YELLOW:   		EQU     0314H
BLUE:   		EQU     0414H
MAGENTA:		EQU     0514H
CYAN:   		EQU     0614H
WHITE:  		EQU     0714H 

	if standalone

		include	"../includes.asm"

CSTS:		equ	0F006h		;STATUS CONST
CONSI:		equ	0F009h		;EINGABE ZEICHEN VON CONST
;CONSO:		equ	0F00Ch		;AUSGABE ZEICHEN ZU CONST
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H
GVAL    	EQU	0F1EAh
tmpcmd		equ	00110h		; temporärer Programmcode
currbank	equ	0042h		; aktuelle Bank
FCB: 		EQU	005Ch 		;Dateikontrollblock
;
GOCPM:		equ	0C173h
NMBUF		equ	FCB			; Zwischenspeicher für Name etc.


; Ports
shadow_on	equ	5		;RAM 4000-7FFF (64K-RAM-Karte)
shadow_off	equ	4


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


		org	1000h

		jp	help
		db	"HELP    ",0
		db	0

;COOUT Ausgabe ab (HL) (B) Zeichen, nur Buchstaben
;
COOUT:		LD	A,(HL)
		CP	A, ' '
		JR	NC, COUT1
		LD	A,'.'
COUT1:		CALL	OUTA			;Zeichen ausgeben
		INC	HL
		DJNZ	COOUT
		RET

;----------------------
; Bankumschaltung

; Code umlagern nach 110h (tmpcmd)
cp_cdnxbk	ld	hl,cd_nxbk
		ld	de,tmpcmd
		ld	bc,cd_nxbke-cd_nxbk
		ldir
		ret

; folgender Code wird nach 110h (tmpcmd) kopiert
; er darf deshalb nicht zu lang werden (BDOS-Stack beachten)

cd_nxbk
		phase	tmpcmd

; Bankumschaltung
l_nextbank:
		ld	a,(currbank)
		inc	a
		jr	l_setbank1
; Bank A aktivieren
l_setbank0:
		ld	a,systembank
l_setbank1:
		ld	(currbank),a
l_setbank2:	out	bankport, a
		ret
		dephase
cd_nxbke

;----------------------

	else
		public	HELP

	endif

;------------------------------------------------------------------------------
; HELP [pgm]		Anzeige einer Hilfe zum Programm
;			ohne Parameter: Liste aller Hilfetexte
;------------------------------------------------------------------------------

HELP:		
		;; call	GVAL			; GVAL wurde in GOCPM schon aufgerufen (f. Kommandoname)
		ex	af,af'			; Cy'=1 kein weiterer Parameter in CONBU
		jr	c,HELP1			; wenn kein Parameter
		call	GVAL
		xor	a
		cp	b			; Länge = 0?
		jr	z, HELP1

		; mit Parameter 
		call	showhlp			; Hilfe anzeigen
		jr	HELPEND

		; ohne Parameter
HELP1:		call	help0


HELPEND:	ld	e,2			;grün
		rst	rst_sbos
		db	3			;color
		
		;neue Zeile, wenn nötig
		ld	c,17			;GETCU
		call	5
		ld	a,e			;E Spalte des Cursors
		cp	1
		CALL	NZ, OCRLF
;		
		or	a
		ret


;------------------------------------------------------------------------------
; mit Parameter: Anzeigen der Hilfe
;------------------------------------------------------------------------------


showhlp:	
		; Programm suchen
		LD 	IYl, ft_HELP			;suchtyp für FA-Rahmen
		rst	rst_sbos
		db	4			;CPROM	TRANSIENTKOMMANDO SUCHEN
		jr	z, showhlp2
		; nicht gefunden
showhlp1:	rst	rst_sbos
		db	9
		db	"Keine Hilfe verfuegbar!",0Dh,8Ah
		ret
showhlp2:	; gefunden
		; wir gehen davon aus, dass es ein FA-Programm ist...
		ld	a, (NMBUF+fa_typ)	;Dateityp
		and	ft_typmask		;Typ maskieren
		cp	ft_HELP			;ist Text?
		ret	nz			;nein
		;

		out	(shadow_on),a		;Shadow-RAM ein

	; Header patchen
		ld	de, shadow_buf
	; wenn kein RAM, dann andere Adresse, z.B. 3800h
		ld	c,27			;GETM
		CALL	5
		OR	A
		jr	nz, showhlp3		;RAM vorhanden
		ld	DE, ram_buf
	;
showhlp3:	ld	(NMBUF+fa_aadr), de	; aadr
		push	de
		
		rst	rst_sbos
		db	5			;FMOV nach AAdr. im Speicher kopieren
		
		; Anzeigen
		pop	de			; ehem hl
		ld	c, 9
		call	5
		
		out	(shadow_off),a		;Shadow-RAM ein

		ret


;------------------------------------------------------------------------------
; kein Parameter: Auflisten aller HLP-Dateien
;------------------------------------------------------------------------------

HELP0:		
		ld	de, hlptxt
		ld	c, 9
		call	5

;Auflisten aller HLP-Dateien
		
		; Code umlagern nach 120h (tmpcmd)
		call	cp_cdnxbk

		; Code umlagern nach 130h (tmpcmd+offs)
		ld	hl,mn_nxbk
		ld	de,tmpcmd+cd_nxbke-cd_nxbk
		ld	bc,mn_nxbke-mn_nxbk
		ldir

;die Bänke von E700h-C000h durchsuchen
		CALL	HELP00
;
		ret

hlptxt:		dw	YELLOW
		db	"Anzeige einer kurzen Hilfe", 0dh,0ah
		DW	WHITE
		db	0dh,0ah
		db	"Aufruf:   HELP kommando", 0dh,0ah
		db	0dh,0ah
		db	"moegliche Kommandos: ", 0dh,0ah
		DW	GREEN
		db	0


;----------------------
; folgender Code wird nach 120h (tmpcmd) kopiert
; er darf deshalb nicht zu lang werden (BDOS-Stack beachten)

mn_nxbk

		phase	tmpcmd+cd_nxbke-cd_nxbk

; die Bänke von C000h-E700h durchsuchen
HELP00		call	l_nextbank
		ld	hl,bankstart		;Ende ROM-Bereich C000-E7FF
		ld	a,0
HELP01:		push	hl
		ld	a, 0FAH			;magic token
		cp	a, (hl)
		call	Z, MENANZF		;FA-Rahmen
		pop	hl
		
;;		jr	c, HELP0e		;bei STOP

		inc	h			;HL=HL+100H
	if megarom == "KOMBI"
		ld	a,(currbank)
		rra				; bit 0 ins Cy-Flag
		ld	a,hi(bankende)		;Ende-ROM-Bereich?
		jr 	nc, CP422a
		ld	a,hi(bankende2)
CP422a:
	else
		ld	a,hi(bankende)		;Ende-ROM-Bereich?
	endif
		cp	h
		jr	nz,HELP01
		ld	a,(currbank)
		cp	lastbank		; Bank FF überschritten?
		jr	nz,HELP00
;
HELP0e		call	l_setbank0
		RET

;
;FA-Rahmen gefunden
MENANZF:	inc	hl	
		cp	a, (hl)			;2x gefunden?
		ret	nz			;nein 
		
		dec	hl
		push	hl
		ld	de, NMBUF
		ld	bc, 20h
		ldir
		pop	hl			;HL-Adr. F-Rahmen

		ld	a,systembank
		out	bankport, a
MENANZF1:	call	HELP2F
		ld	a,(currbank)
		out	bankport, a
		RET

		dephase
mn_nxbke
;----------------------
;FA-Header
;Rahmen-Daten sind nach 80h kopiert
;;	0	2x0FAH, magic marker FlAsH
;;	2	FLASH-Dateityp
;;	3	Name (8 Zeichen)
;;	11	aadr, eadr, sadr
;;	17	länge
;;	19	FLASH-Kategorie
;;	20	Kommentar (12 Zeichen)


HELP2F:
		ld	a, (NMBUF+fa_typ)	;Dateityp
		and	ft_typmask		;Typ maskieren
		cp	ft_HELP			;ist Text?
		ret	nz			;sonst keine Anzeige

HELP2Fa:	
;;Kurzanzeige nur Name (A=0)
		ld	hl,NMBUF+fa_name
		
		ld	a,7fh		; abbruch, wenn kein ASCII-Zeichen
		cp	(hl)
		ret	c		; (hl) > 7f?
		
		LD	B,8
		CALL	COOUT			;Ausgabe Name
		CALL	OSPAC
		CALL	OSPAC
		rst	rst_sbos
		db	2			;WAIT
		RET
;

;------------------------------------------------------------------------------

		endsection
		
;		end
