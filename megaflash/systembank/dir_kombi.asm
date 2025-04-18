;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M-Modul)
; (c) V. Pohlers 2011 / 2018 f. Kombi-Modul
; letzte �nderung 27.07.2020
;------------------------------------------------------------------------------
; Systembank: DIR-Kommando
;------------------------------------------------------------------------------

;f. Kombimodul sol die Bank 0 nicht zwischengeschaltet werden
;damit die Bankanzeige nicht flackert
;dazu Umlagern der Such- und Anzeige-Codes nach 7400h (Shadow-RAM)
;und 2 getrennte Routinen
;Bereich bank0 alles (ggf nur os.rahmen bis c000)
;restl. B�nke Bereich C000-EFFF

;uz27.07.2020 Beim Befehl DIR bleibt nach einem STOP der Hintergrund-RAM aktiv. -> WAITu korrigiert

mnucode		equ 7400h

;------------------------------------------------------------------------------
; DIR [L|C] [muster]	Anzeigen aller Kommandos in allen folgenden B�nken
; 			L = ausf�hrliche Anzeige (Bank, Menu-Adr, SADR, u.a.)
;			C = ausf�hrliche Anzeige (Bank, Menu-Adr, Kommentar, u.a.)
;			Suchmuster mit '*' und '?'
;------------------------------------------------------------------------------

; PARBU:	Bit7 gesetzt: mit Suchmuster
;		= 1 Lange Anzeige; = 2 Kommentar anzeigen

MENU:		xor	a			; A=0 ohne Parameter
		ld	(PARBU),a

		;; call	GVAL			; GVAL wurde in GOCPM schon aufgerufen (f. Kommandoname)
		ex	af,af'			; Cy'=1 kein weiterer Parameter in CONBU
		jr	c,menu0			; wenn kein Parameter
; Parameter
		call	GVAL
		ld	a,b
		cp	1			; L�nge = 1
		jr	c,menu0			; bei L�nge 0
		jr	nz, menupar1
		ld	a,(INTLN+1)		; Zeichen
		cp	'C'
		jr	nz, menupar2
		; Parameter 'C'
		ld	a,2			; A=2 mit Parameter
		ld	(PARBU),a		; merken
		jr	menupar3
		; 
menupar2	cp	'L'
		jr	nz, menupar1
		; Parameter 'L'
		ld	a,1			; A=1 mit Parameter
		ld	(PARBU),a		; merken
		; 
menupar3	ex	af,af'			; weiterer Parameter?'
		jr	c, MENU0		; wenn kein Parameter
		call	GVAL
		xor	a
		cp	b			; L�nge = 0?
		jr	z, MENU0
		; Parameter Suchstr 

menupar1	ld	hl,PARBU
		set	7,(hl)			;merken, dass Suchmuster �bergeben wurde
		
MENU0:		
		; Code umlagern nach 120h (tmpcmd)
		call	cp_cdnxbk

		; Code umlagern 
		out 5,a
		ld	hl,mn_nxbk
		ld	de,mnucode
		ld	bc,mn_nxbke-mn_nxbk
		ldir

		; lastbank patchen
		ld	a,(nr_lastbank)
		ld	(CP422pd+1), a
		;
		out 4,a

; in aktueller Bank und im �brigen Speicher alles von ROM-Ende bis 100h
		ld	hl, 0FC00H		;ANFANGSADRESSE
MENU1:		push	hl
		LD	A,0C3H
		CP	A, (hl)			;JMP-Befehl?
		CALL	Z, MENANZ0
		pop	hl
		Dec	h			;IX=IX-100H
		jr	nz,MENU1

;und jetzt die B�nke von E700h-C000h
		out 5,a
		CALL	MENU00
		out 4,a
;
		call	c_gruen

;neue Zeile, wenn n�tig
		ld	c,17		;GETCU
		call	5
		ld	a,e		;E Spalte des Cursors
		cp	1
		CALL	NZ, OCRLF
;		
		or	a
		ret
		
;OS-Rahmen gefunden
MENANZ0:	push	hl
		pop	ix
MENU30
		;Namen kopieren nach 80h
		push	ix
		pop	hl
		ld	de, NMBUF
		ld	bc, 12			; 12 Byte Speicher f�r Jp+Name+0
		ldir
;
		out	5,a
		call	MENU2
		out	4,a
		
;;s.WAIT		RET	C			;bei Stop
;
		LD	A,(IX+12)
		CP	A, 0C3H			;folgt Name?
		ret	NZ			;nein
		LD	DE,12
		ADD	IX,DE			;Zaehler erhoehen
		JR	MENU30
;
		
;----------------------
; folgender Code wird nach mnucode in Shadow-RAM kopiert

mn_nxbk

		phase	mnucode

; die B�nke von C000h-E700h durchsuchen
MENU00		call	l_nextbank
		ld	hl,bankstart		;Ende ROM-Bereich C000-DFFF
		ld	a,0
MENU01:		push	hl
		ld	a, 0FAH			;magic token
		cp	a, (hl)
		jr	nz,MENU03
		call	MENANZF			;FA-Rahmen
		jr	MENU02
;	
MENU03:		LD	A,0C3H
		CP	A, (hl)			;JMP-Befehl?
		CALL	Z, MENANZ		;OS-Rahmen
MENU02		pop	hl
		
;;		jr	c, MENU0e		;bei STOP

		inc	h			;HL=HL+100H
		ld	a,hi(bankende)		;Ende-ROM-Bereich?
		cp	h
		jr	nz,MENU01
		ld	a,(currbank)
cp422pd		cp	lastbank		; Bank FF �berschritten?
		jr	nz,MENU00
;
MENU0e		call	l_setbank0
		RET

NMBUF		equ	FCB			; Zwischenspeicher f�r Name etc.

;OS-Rahmen gefunden
MENANZ:		push	hl
		pop	ix
MENU3
		;Namen kopieren nach 80h
		push	ix
		pop	hl
		ld	de, NMBUF
		ld	bc, 12			; 12 Byte Speicher f�r Jp+Name+0
		ldir
;
;;		ld	a,systembank
;;		out	bankport, a
		call	MENU2
;;		ld	a,(currbank)
;;		out	bankport, a
;;s.WAIT		RET	C			;bei Stop
;
		LD	A,(IX+12)
		CP	A, 0C3H			;folgt Name?
		ret	NZ			;nein
		LD	DE,12
		ADD	IX,DE			;Zaehler erhoehen
		JR	MENU3
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

;;		ld	a,systembank
;;		out	bankport, a
		call	MENU2F
;;		ld	a,(currbank)
;;		out	bankport, a
		RET

;----------------------

;OS-Rahmen auswerten
;Rahmen-Daten sind nach 80h kopiert
MENU2:		ld	hl,NMBUF+11
		XOR	A
		CP	A, (HL)			;Stringende=0?
		ret	NZ			;kein Name
		ld	hl,NMBUF+3
;test 1. Zeichen ein Buchstabe?
		ld	a,(HL)
		cp	'#'			; Ausnahme f�r EOS-Programme
		jr	z, MENU3a
		cp	'A'-1
		ret	c
		cp	'z'
		ret	nc
;Anzeigemodus ausw�hlen
MENU3a:		ld	a,(PARBU)		;Anzeigemodus
		bit	7,a			;mit Suchstring?
		jr	z,MENU2a		;nein
;Namensvergleich
		push	hl
		ld	hl, NMBUF+3		;Dateiname
		ld	de, INTLN+1		;Suchmuster		
		call 	pmatch			;suchen
		pop	hl
		ret 	c			;nicht gleich, als nix anzeigen
		
MENU2a:		ld	hl,NMBUF+3
		ld	a,(PARBU)		;Anzeigemodus
		and	7fh
		jr	nz,MENUF
;
;;Kurzanzeige nur Name (A=0)
;
		call	c_gruenu
		LD	B,8
		CALL	COOUTu			;Ausgabe Name
		CALL	OSPAC
		CALL	OSPAC
		jr	MENU4
;		
;;Langanzeige Bank, Name, Rahmen-Adr, Startadr. (A=1)
;
MENUF:		call	c_gelbu
		ld	a,(currbank)
		call	OUTHXu
		call	c_gruenu
		CALL	OSPAC
		LD	B,8
		CALL	COOUTu			;Ausgabe Name
		CALL	OSPAC
		CALL	OSPAC
		call	c_gelbu
		CALL	MEADR			;Ausgabe Adressen
		call	c_gruenu
		CALL	OCRLF
;;
MENU4		CALL	WAITu
		RET
;Ausgabe Adressen
MEADR:		PUSH	IX			;orig. Adr.
		POP	HL
		CALL	OUTHLu			;Ausg. 1. Adr.
		CALL	OSPAC
		ld	HL,NMBUF+1
		LD	A,(HL)
		inc	HL
		LD	H,(HL)
		LD	L,A
		CALL	OUTHLu			;Ausg. 2. Adr.
		RET


;----------------------
;FA-Header
;Rahmen-Daten sind nach 80h kopiert
;;	0	2x0FAH, magic marker FlAsH
;;	2	FLASH-Dateityp
;;	3	Name (8 Zeichen)
;;	11	aadr, eadr, sadr
;;	17	l�nge
;;	19	FLASH-Klasse
;;	20	Kommentar (12 Zeichen)


MENU2F:
		ld	a, (NMBUF+fa_kategorie)	;Kategorie
		and	fk_hidden		;unsichtbar?
		ret	nz			;dann keine Anzeige
		

;Anzeigemodus ausw�hlen
		ld	a,(PARBU)		;Anzeigemodus
		bit	7,a			;mit Suchstring?
		jr	z,MENU2Fa		;nein
;Namensvergleich
		push	hl
		ld	hl, NMBUF+fa_name	;Dateiname 
		ld	de, INTLN+1		;Suchmuster		
		call 	pmatch			;suchen
		pop	hl
		ret 	c			;nicht gleich, als nix anzeigen
;
MENU2Fa:	ld	a,(PARBU)		;Anzeigemodus ausw�hlen
		and	7fh
		jr	nz,MENUFF
;;Kurzanzeige nur Name (A=0)
;;		call	c_cyan
		
		; farbe anhand Typ
		ld	a,(NMBUF+fa_typ)
		add	a, 6			; cyan
		;sub	a, 6			; cyan
		;neg
		and	7
		ld	e, a
		call	coloru		
		
		ld	hl,NMBUF+fa_name
		LD	B,8
		CALL	COOUTu			;Ausgabe Name
		CALL	OSPAC
		CALL	OSPAC
		jr	MENU4f
;;Langanzeige BANK POS TYP NAME VON BIS START KATEGORIE (A=1)
MENUFF:		call	c_gelbu
		ld	a,(currbank)
		call	OUTHXu			; Bank
		CALL	OSPAC
		CALL	OUTHLu			; Bankadr.
		CALL	OSPAC

MENUFF2:	call	c_rotu
		ld	a,(NMBUF+fa_typ)
		and	ft_typmask		; FLASH-Dateityp
;Typ als Zahl anzeigen
;		add	a,'0'			;Typ
;		CALL	OUTA

;Typ als String anzeigen
		ld	hl,typtab
		ld	d,0
		ld	e,a
		add	a,e
		add	a,e
		ld	e,a			; E=3xA
		add	hl,de			; Pos in Typtab errechnet
		ld	b,3
		ld	a,(NMBUF+ft_typmask)
		rla				;bit 8 -> Cy
		call	c, c_cyanu		;packed bleibt rot
		CALL	COOUTu			;Ausgabe Typ
		CALL	OSPAC
;Name
		call	c_gruenu			;packed bleibt rot
		LD	B,8
		ld	hl,NMBUF+fa_name
		CALL	COOUTu			;Ausgabe Name
		CALL	OSPAC
		call	c_gelbu

		ld	a, (PARBU)
		and	7fh
		cp	2
		jr	z,MENUFC
		
;Adressen
		ld	hl,(NMBUF+fa_aadr)
		CALL	OUTHLu			;aadr
		CALL	OSPAC
		ld	hl,(NMBUF+fa_eadr)
		CALL	OUTHLu			;eadr
		CALL	OSPAC
		ld	hl,(NMBUF+fa_sadr)
		CALL	OUTHLu			;sadr
		CALL	OSPAC
;Kategorie
		call	c_rotu
		ld	a,(NMBUF+fa_kategorie)
		and	3fh
		add	a,'0'			;Kategorie
		CALL	OUTA			;als Zahl anzeigen
		CALL	OCRLF
;
		call	c_gruenu
;
MENU4f		CALL	WAITu
		RET

;
typtab:		db	"MC "	; 0 ft_MC
		db	"BAS"	; 1 ft_BASIC
		db	"HLP"	; 2 ft_HELP
		db	"FT3"	; 3 ft_typ3
		db	"FT4"	; 4 ft_typ4
		db	"FT5"	; 5 ft_typ5
		db	"FT6"	; 6 ft_typ6
		db	"FT7"	; 7 ft_typ7


; Anzeige mit Kommentar 10.02.2012
MENUFC:	

;Kategorie
		call	c_rotu
		ld	a,(NMBUF+fa_kategorie)
		and	3fh
		add	a,'0'			;Kategorie
		CALL	OUTA			;als Zahl anzeigen
		CALL	OSPAC
;
		ld	hl,NMBUF+fa_comment
		LD	B,12
		CALL	COOUTu			;Ausgabe Kommentar
		CALL	OCRLF
		call	c_gruenu
		jr	MENU4f

;------------------------------------------------------------------------------
; Stringsuche mit einfachen Wildcards '*' und '?'
; vp120209
; hl = Text, der untersucht wird, nullterminiert
; de = Suchmuster mit '?' und '*', nullterminiert

; 30.04.2015 das war doch tats�chlich nicht 100% korrekt: 
; bei FA-Rahmen muss der Text nicht nullterminiert sein, sondern ist max. 8 Zeichen lang!

pmatch:		ld	b,8	
pmatch0:	ld	a,(hl)			; Test auf Stringende
		or	a			; a=0?
		scf
		ret	z			; Cy=1 nicht gefunden
		push	hl
		push	de
		push	bc
		call 	match			; 
		pop	bc
		pop	de
		pop	hl
		ret	nc			; Cy=0 gefunden
		inc	hl
		dec	b			; max 8 Stellen
		ret	z
		jr	pmatch0


;------------------------------------------------------------------------------
; Stringvergleich mit einfachen Wildcards '*' und '?'
; vp120209
; hl = Text, der untersucht wird, nullterminiert
; de = Suchmuster mit '?' und '*', nullterminiert
; ret: Cy=0 match
; Cy=1 kein match

match:		ld	a, (de)			; Suchmuster Ende?
		or	a			; =0?
		ret	z			; dann fertig mit Cy=0
;		
		ld	b, a			; Suchmuster Zeichen merken
		cp	'*'
		jr	nz, match2
; wildcard '*'		
; �berlesen der Zeichen im Text
		inc	de
		ld	a, (de)			; Suchmuster Zeichen hinter '*'
		or	a
		ret	z			; dann fertig mit Cy=0
		ld	c, a
		
match1		ld	a, (hl)			; Text Ende?
		or	a			; =0?
		scf
		ret	z			; dann fertig mit Cy=1

		cp	c			; Vergleich mit Text
		inc	hl
		jr	nz, match1
		jr	match4			; n�chste Zeichen

; Wildcard '?' oder direktes Zeichen
match2		ld	a, (hl)			; Text Ende?
		or	a			; =0?
		scf
		ret	z			; dann fertig mit Cy=1

		cp	b			; Vergleich mit Text
		jr	z, match3
		ld	a,'?'			; oder Wildcard '?'
		cp	b
		jr	z, match3

		scf
		ret				; kein match, Cy=1

match3		inc	hl			; n�chste Position im Text
match4		inc	de
		jr	match			; Vergleiche n�chste Zeichen

;------------------------------------------------------------------------------
; weitere lokale Kopien
		
;OUTHL Ausgabe (HL) hexa
;
OUTHLu:		LD	A,H
		CALL	OUTHXu
		LD	A,L
;
;OUTHX Ausgabe (A) hexa
;
OUTHXu:		PUSH	AF
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	OUTH1u
		POP	AF
OUTH1u:		AND	A, 0FH
		ADD	A, 30H
		CP	A, 3AH
		JR	C, OUTH2u
		ADD	A, 07H
OUTH2u:		CALL	OUTA
		RET
;
;COOUT Ausgabe ab (HL) (B) Zeichen, nur Buchstaben
;
COOUTu:		LD	A,(HL)
		CP	A, ' '
		JR	NC, COUT1u		; A>=' '
		LD	A,'.'
COUT1u:		CALL	OUTA			;Zeichen ausgeben
		INC	HL
		DJNZ	COOUTu
		RET
;
;WAIT Unterbrechung Programm, wenn <PAUSE> gedrueckt,
;     weiter mit beliebiger Taste
;
WAITu:		CALL	CSTS			;Abfrage Status
		OR	A
		RET	Z			;keine Taste gedrueckt
		CALL	CONSI			;Eingabe
		CP	A, 03H			;<STOP>?
		jr	nz,waitu1
		ld	a,systembank
		out	bankport, a		;bank 0 einschalten
		out 4,a				;wg. uz27.07.2020 
		JP	GOCPM			;zur�ck zum System
;
waitu1:		CP	A, 013H			;<PAUSE>?
		RET	NZ			;nein
		CALL	CONSI			;Eingabe
		RET
;;

;;Farben
c_rotu		ld	e,1
		jr	coloru
c_gruenu		ld	e,2
		jr	coloru
c_gelbu		ld	e,3
		jr	coloru
c_blauu		ld	e,4
		jr	coloru
c_magentau	ld	e,5
		jr	coloru
c_cyanu		ld	e,6
		jr	coloru
c_whiteu		ld	e,7
;
coloru		ld	a,14h
		call	outa
		ld	a,e
		call	outa
		ret
;------------------------------------------------------------------------------

		dephase
mn_nxbke

