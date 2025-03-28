;------------------------------------------------------------------------------
; Z9001 MEGA-FLASH-Modul (2.5M-Modul)
; (c) V. Pohlers 2012
; letzte Änderung 14.07.2012
;------------------------------------------------------------------------------
; Systembank: Menüsoftware. Suchen der Programme in ROM (analog DIR)
; UPs für menu.asm
;------------------------------------------------------------------------------

; in: IY = Adr. DirBuffer

;extern 	DirCnt	DS 1			; Zähler für Anzahl
;		FAKategorie	DS 1


;------------------------------------------------------------------------------
; Auflisten aller Bank-Programme mit OS-Rahmen
;------------------------------------------------------------------------------

; in: IY = Adr. DirBuffer

;extern 	DirCnt		DS 1		; Zähler für Anzahl

MENU_OS:	
		SECTION	MENU_OS

		; Code umlagern nach 110h
		ld	hl,mn_nxbk
		ld	de,tmpcmd
		ld	bc,mn_nxbke-mn_nxbk
		ldir

		; lastbank patchen
		ld	a,systembank
		out	bankport, a    
		ld	a,(nr_lastbank)
		ld	(CP422p+1), a
		ld	a,(currbank)
		out	bankport, a    
		;

		xor	a
		ld	(DirCnt),a

;und jetzt die Bänke von E700h-C000h
;		ld	hl,currbank
;		dec	(hl)			; wird gleich wieder durch l_nextbank erhöht
		CALL	MENU00
		ld	(IY),0cch		; Ende kennzeichnen
		inc	IY
		ld	(IY),0cch		; Ende kennzeichnen (hier muss sonst immer xx00h-Adr. stehen)
		ret

;----------------------

; folgender Code wird nach 110h (tmpcmd) kopiert
; er darf deshalb nicht zu lang werden (BDOS-Stack beachten)

mn_nxbk
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


; die Bänke von C000h-E700h durchsuchen
MENU00		call	l_nextbank
		ld	hl,bankstart		;Ende ROM-Bereich C000-E7FF
		ld	a,0
MENU01:		push	hl
		LD	A,0C3H
		CP	A, (hl)			;JMP-Befehl?
		CALL	Z, MENANZ		;OS-Rahmen
		pop	hl
		
		inc	h			;HL=HL+100H

; 22.05.2015 UZ möchte, dass der RAM auch mit durchsucht wird, also kein abwechselndes Ende
;	if megarom == "KOMBI"
;		ld	a,(currbank)
;		rra				; bit 0 ins Cy-Flag
;		ld	a,hi(bankende)		;Ende-ROM-Bereich?
;		jr 	nc, CP422a
;		ld	a,hi(bankende2)
;CP422a:
;	else
		ld	a,hi(bankende)		;Ende-ROM-Bereich?
;	endif
		cp	h
		jr	nz,MENU01
		ld	a,(currbank)
cp422p:		cp	lastbank		; Bank FF überschritten?
		jr	nz,MENU00
;
		call	l_setbank0
		RET

;OS-Rahmen gefunden
MENANZ:		push	hl
		pop	ix
MENU3		push	ix
		pop	hl
;		
		;test 1. Zeichen ein Buchstabe oder Zeichen ?
		ld	a,(IX+3)
		cp	'A'-1
		ret	c
		cp	'z'
		ret	nc
;
		ld	a,(IX+11)
		cp	0
		ret	nz
;
		;Bank-Daten kopieren
		ld	a,(currbank)
		ld	(iy),a			; 1. Byte wird Bank
		inc	iy
		ld	(iy),l			; dann folgt Adr. in Bank
		inc	iy
		ld	(iy),h
		inc	iy
		;Namen kopieren
		inc	hl
		inc	hl
		inc	hl
		push	iy			; DirBuffer
		pop	de			; Speichern in DirBuffer
;30.04.2015 wg. Bug in möglichen Namen und damit die immer 8 Zeichen lang sind, wird jetzt manuell kopiert :-(
;;		ld	bc, 9			; 11 Byte Speicher für Name+0
;;		ldir
		ld	b,8
m00:		ld	a,(hl)
		or	a		; A=0?
		jr	nz,m01
		ld	a,' '	
m01:		ld	(de),a
		inc	hl
		inc	de
		djnz	m00
		ldi			; Abschluss-0-Byte kopieren
;
		push	de
		pop	iy			; DirBuffer erhöhen
;
		ld	hl,DirCnt
		inc	(hl)			; DirCnt erhöhen	
		;
		LD	A,(IX+12)
		CP	A, 0C3H			;folgt Name?
		ret	NZ			;nein
		LD	DE,12
		ADD	IX,DE			;Zaehler erhoehen
		JR	MENU3
;
		dephase
mn_nxbke
;----------------------

		ENDSECTION

;------------------------------------------------------------------------------
; Auflisten aller Bank-Programme mit FA-Rahmen
;------------------------------------------------------------------------------

; in: IY = Adr. DirBuffer

;extern 	DirCnt	DS 1			; Zähler für Anzahl
;		FAKategorie	DS 1

MENU_FA:	
		SECTION	MENU_FA

		; Code umlagern nach 110h
		ld	hl,mn_nxbk
		ld	de,tmpcmd
		ld	bc,mn_nxbke-mn_nxbk
		ldir

		; lastbank patchen
		ld	a,systembank
		out	bankport, a    
		ld	a,(nr_lastbank)
		ld	(CP422ap+1), a
		ld	a,(currbank)
		out	bankport, a    
		;

		xor	a
		ld	(DirCnt),a

;und jetzt die Bänke von E700h-C000h
		CALL	MENU00
		ld	(IY),0cch		; Ende kennzeichnen
		inc	IY
		ld	(IY),0cch		; Ende kennzeichnen (hier muss sonst immer xx00h-Adr. stehen)
		ret

;----------------------

; folgender Code wird nach 110h (tmpcmd) kopiert
; er darf deshalb nicht zu lang werden (BDOS-Stack beachten)

mn_nxbk
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


; die Bänke von C000h-E700h durchsuchen
MENU00		call	l_nextbank
		ld	hl,bankstart		;Ende ROM-Bereich C000-E7FF
		ld	a,0
MENU01:		push	hl
		LD	A,0FAH			;magic token
		CP	A, (hl)			;JMP-Befehl?
		CALL	Z, MENANZ		;OS-Rahmen
		pop	hl
		
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
		jr	nz,MENU01
		ld	a,(currbank)
CP422ap:	cp	lastbank		; Bank FF überschritten?
		jr	nz,MENU00
;
		call	l_setbank0
		RET

;FA-Rahmen gefunden
MENANZ:		inc	hl	
		cp	a, (hl)			;2x gefunden?
		ret	nz			;nein 
		dec	hl

;test auf Dateikategorie fa_kategorie, beachte hidden-bit, ignoriere shadow-bit
;und variante user-fk_typ (übergeben als ffh = sonstige 8..31)

		push	hl
		pop	ix
		ld	a, (ix+fa_kategorie)	;Kategorie
		ld	b,a			;merken
		and	fk_hidden		;unsichtbar?
		ret	nz			;dann keine Anzeige

		ld	a,b
		and	00011111b		;flags ausblenden
		ld	b,a
		; 
		cp	fk_cpm+1		; user-Kategorie?
		jr	c, MENANZ0		; wenn fa_kategorie <= fk_cpm
		ld	b,0ffh			; wenn user-Kategorie
MENANZ0:	ld	a,(FAKategorie)		; Vergleich mit Übergabewert
		cp	b
		ret	nz			; ungleiche Kategorie
		;Bank-Daten kopieren
		ld	a,(currbank)
		ld	(iy),a			; 1. Byte wird Bank
		inc	iy
		ld	(iy),l			; dann folgt Adr. in Bank
		inc	iy
		ld	(iy),h
		inc	iy
		;Namen kopieren
		inc	hl
		inc	hl
		inc	hl
		push	iy			; DirBuffer
		pop	de			; Speichern in DirBuffer
		ld	bc, 8			; 8 Byte Speicher für Name
		ldir
;
		xor	a
		ld	(de),a			; Stringende 0
		inc	de
;
		push	de
		pop	iy			; DirBuffer erhöhen
;
		ld	hl,DirCnt
		inc	(hl)			; DirCnt erhöhen	
		;
		RET
;
		dephase
mn_nxbke
;----------------------
		ENDSECTION



;------------------------------------------------------------------------------
; Anzeige der Datei-Infos
;------------------------------------------------------------------------------
; in hl: Zeiger auf Header in Dir-Array

show_info:

		;;ld	ix, flash_struct	;;n.nötig
		ld	a,(ix+max_daten+1)
		cp	0ffh			; OS-Programm?
		jp	z, show_info_os

; FA-Auswertung
;----------------------
;FA-Header
;;	0	2x0FAH, magic marker FlAsH	
;;	2	FLASH-Dateityp                  
;;	3	Name (8 Zeichen)                
;;	11	aadr, eadr, sadr                
;;	17	länge                           
;;	19	FLASH-Dateikategorien           
;;	20	Kommentar (12 Zeichen)          
                                                
; Wechseln zur Bank                             
		ld	a,(hl)			; bank
		out	bankport, a
		inc	hl
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a			; hl=Adr.FA-Rahmen im ROM
; Daten anzeigen
;      MC _ 8E60-A7FF,FFFF_ robotron Gra 

		ld	a,192			; " |" (rechter Rand)
		ld	(screen+23*40+6), a 
		ld	(screen+23*40+22), a 
		
		; Dateityp
		push	hl
		ld	de, fa_typ
		add	hl,de
		ld	a,(hl)			; FLASH-Dateityp
		and	ft_typmask		; FLASH-Dateityp
		ld	hl,typtab
		ld	d,0
		ld	e,a
		add	a,e
		add	a,e
		ld	e,a			; E=3xA
		add	hl,de			; Pos in Typtab errechnet
		ld	de, screen+23*40+3
		ld	bc,3
		CALL	print_textl		;Ausgabe Typ
		pop	hl		
		
		; aadr-eadr,sadr
		push	hl
		ld	de,fa_aadr		
		add	hl,de
		ld	de,screen+23*40+8
		call	show_hlx		; Anzeige AADR
		ld	a,'-'
		ld	(de),a
		inc	de
		call	show_hlx		; Anzeige EADR
		ld	a,','
		ld	(de),a
		inc	de
		call	show_hlx		; Anzeige SADR
		pop	hl

		; Kommentar
		ld	de, fa_comment
		add	hl,de
		ld	de, screen+23*40+24
		ld	bc,12			; max 12 Zeichen
		call	print_textl

		; zurückschalten
		ld	a,systembank
		out	bankport, a
		ret

typtab:		db	"MC "	; 0 ft_MC
		db	"BAS"	; 1 ft_BASIC
		db	"HLP"	; 2 ft_HELP
		db	"FT3"	; 3 ft_typ3
		db	"FT4"	; 4 ft_typ4
		db	"FT5"	; 5 ft_typ5
		db	"FT6"	; 6 ft_typ6
		db	"FT7"	; 7 ft_typ7

; Ausgabe (HL) Hexadezimal
; in HL: Adr; DE: Adr. BWS
; out HL+2, DE+4
show_hlx:	ld	a,(hl)
		push	af
		inc	hl
		ld	a,(hl)
		call	show_ax
		pop	af
		call	show_ax
		inc	hl
		ret		
;
;OUTHX Ausgabe (A) hexa
;
show_ax:	PUSH	AF
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	show_ax1
		POP	AF
show_ax1:	AND	A, 0FH
		ADD	A, 30H
		CP	A, 3AH
		JR	C, show_ax2
		ADD	A, 07H
show_ax2:	ld	(DE),a
		inc	DE
		RET

;------------------------------------------------------------------------------

show_info_os

		ld	a,(hl)			; bank
		ld	de, screen+23*40+21
		call	show_ax
		inc	hl

		ld	a,192			; " |" (rechter Rand)
		ld	(de), a 
		inc	de
		inc	de
		call	show_hlx
		
		ld	de, screen+23*40+3
		ld	hl, bank_text
		call	print_text
		
		ret

bank_text	db 	"OS-Programm",192," Bank ",0


;------------------------------------------------------------------------------
; Print_text ..... der String wird mit einer 0 beendet
; hl = von
; de = wohin
; bc = max. Länge

print_textl:	ld 	a,(hl)
		or 	a,a
		jr 	z, print_textl_exit
		ldi
		jp	pe, print_textl
print_textl_exit:
		inc hl
		ret

;------------------------------------------------------------------------------
