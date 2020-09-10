; File Name   :	h:\hobby\hobby0\z9001_comodore\comodore_com.bin
; Format      :	Binary file
; Base Address:	0000h Range: 0400h - 0B96h Loaded length: 0796h

		cpu	Z80

; PORTS
CTC0		 equ 80h			; System CTC0 Kassette,	Beeper
PIO1AS		 equ 8Ah			; PIO1 A Kommando
PIO2BS		 equ 93h			; Tastatur-PIO2	B Kommando

; Adr
ARB0		equ 0003h			; freier Bereich
DMA		 equ 001Bh			; Zeiger auf Puffer fr	Kassetten-E/A
ARB		 equ 006Ah			; Hilfszelle fr Kassettentreiber
BLNR		 equ 006Bh			; Blocknummer
BWS		 equ 0EC00h

; CALL5
CONSI		 equ 1				; Eingabe eines	Zeichens von CONST
CONSO		 equ 2				; Ausgabe eines	Zeichens zu CONST
PRNST		 equ 9				; Ausgabe Zeichenkette
SETCU		 equ 12h			; Setzen logische Cursoradresse

; OS-Prozeduren
LSTOP		equ	0FFD1h			; LSTOP Lesen eines Bits
WRIT1		equ	0F472h			; BLOCKSCHREIBEN SEQUENTIELL
INITA		equ	0FAE3h			; INITIALISIERUNG TASTATUR
INIC1		equ	0FB0Ah			; INITIALISIERUNG CTC etc.

; Chars
CLS		equ	0Ch

;------------------------------------------------------------------------------
; OS-Rahmen
;------------------------------------------------------------------------------

		org 	400h

		jp	start
aComodore:	db "COMODORE",0
		db    0
		db    0

;------------------------------------------------------------------------------
; Texte
;------------------------------------------------------------------------------

aHeimcomputerRo:db "HEIMCOMPUTER ROBOTRON Z9001",0
aSystemProgramm:db "SYSTEM-PROGRAMM",0
aLesenUndVerarb:db "LESEN UND VERARBEITEN",0
aVonCommodoreKa:db "VON COMMODORE-KASSETTEN",0
aHansKittelmann:db "HANS KITTELMANN",0Ah
		db 0Ah
		db 0Dh," 8019 DRESDEN",0Ah
		db 0Ah
		db 0Dh," HOLBEINSTR. 131",0

a2_0Vom30_10_84:db "2.0 VOM 30.10.84",0

aEnter:		db "         >ENTER<",0

aMenueAaaaa1Pro:db "MENUE",0Ah
		db 0Dh,"  ",0A0h,0A0h,0A0h,0A0h,0A0h,0Ah
		db 0Ah
		db 0Dh,"  1 = PROGRAMM EINLESEN",0Ah
		db 0Ah
		db 0Dh,"  2 = BASIC-PROGRAMM ERSTELLEN",0Ah
		db 0Ah
		db 0Dh,"  3 = BASIC-PROGRAMM LISTEN",0Ah
		db 0Ah
		db 0Dh,"  4 = BASIC-PROGRAMM AUF KASSETTE",0Ah
		db 0Ah
		db 0Dh,"  5 = ENDE DES PROGRAMMES",0

aCommodoreKasse:db " COMMODORE-KASSETTE EINLEGEN",0Ah
		db 0Ah
		db 0Dh," TONBAND-WIEDERGABE STARTEN",0Ah
		db 0Ah
		db 0Dh," BEI VORTON >ENTER< BETAETIGEN",0Ah
		db 0Ah
		db 0Dh,0

aAadrEadrName:	db "  AADR =",0Ah
		db 0Ah
		db 0Dh,"  EADR =",0Ah
		db 0Ah
		db 0Dh,"  NAME =",0Ah
		db 0Ah
		db 0Dh,0

aStartTapeForWr:db 0Ah
		db 0Ah
		db " START TAPE FOR WRITE BASPRO",0Ah
		db 0Ah
		db 0Dh," UND >ENTER< BETAETIGEN",0Ah
		db 0Ah
		db 0Dh,0

aBlockLeseFehle:db "  BLOCK-LESE-FEHLER",0
aVorspannFehlt:	db "VORSPANN FEHLT",0
aFehlerInNeueAd:db "FEHLER IN NEUE ADRESSE",0

;------------------------------------------------------------------------------
; Start
;------------------------------------------------------------------------------

start:		
		; RST-Sprünge init.
		ld	hl, rst8_setcu
		ld	(9), hl
		ld	hl, rst10_conso
		ld	(11h), hl
		ld	hl, rst18_prnst
		ld	(19h), hl
		ld	a, 0C3h	; 'Ã'
		ld	(8), a
		ld	(10h), a
		ld	(18h), a

		; Titelbild zeichnen

		;"  HEIMCOMPUTER ROBOTRON Z9001          "
		;"                                       "
		;"  #################################### "
		;"  #SYSTEM-PROGRAMM           COMODORE# "
		;"  #################################### "
		;"                                       "
		;"  #################################### "
		;"  #                                  # "
		;"  #            LESEN UND VERARBEITEN # "
		;"  #                                  # "
		;"  #          VON COMMODORE-KASSETTEN # "
		;"  #                                  # "
		;"  #################################### "
		;"                                       "
		;"                                       "
		;"  HANS KITTELMANN                      "
		;"                                       "
		;"  8019 DRESDEN                         "
		;"                                       "
		;"  HOLBEINSTR. 131                      "
		;"                                       "
		;"                               >ENTER< "
		;"                                         

		ld	e, CLS
		rst	10h		; CONSO
		ld	de, 0202h
		rst	8		; SETCU
		ld	de, aHeimcomputerRo ; "HEIMCOMPUTER ROBOTRON Z9001"
		rst	18h		; PRNST
		; 1. Rahmen oben
		ld	de, 0402h
		rst	8		; SETCU
		ld	e, 0C1h	; 'Á'
		rst	10h		; CONSO
		ld	b, 22h
start1:		ld	e, 9Eh ; 'ž'
		rst	10h		; CONSO
		djnz	start1
		ld	e, 89h ; '‰'
		rst	10h		; CONSO
		; 1. Rahmen links
		ld	de, 0502h
		rst	8		; SETCU
		ld	e, 9Fh ; 'Ÿ'
		rst	10h		; CONSO
 		; 1. Rahmen rechts
		ld	de, 0525h
		rst	8		; SETCU
		ld	e, 0C0h	; 'À'
		rst	10h		; CONSO
		; 1. Rahmen unten
		ld	de, 0602h
		rst	8		; SETCU
		ld	e, 88h ; 'ˆ'
		rst	10h		; CONSO
		ld	b, 22h
start2:		ld	e, 0F8h	; 'ø'
		rst	10h		; CONSO
		djnz	start2
		ld	e, 0C8h	; 'È'
		rst	10h		; CONSO
		; Text in 1. Rahmen
		ld	de, 0503h
		rst	8		; SETCU
		ld	de, aSystemProgramm ; "SYSTEM-PROGRAMM"
		rst	18h		; PRNST
		;
		ld	de, 051Dh
		rst	8		; SETCU
		ld	de, aComodore	; "COMODORE"
		rst	18h		; PRNST
		; 2. Rahmen oben
		ld	de, 0802h
		rst	8		; SETCU
		ld	b, 24h
start3:		ld	e, 0FFh
		rst	10h		; CONSO
		djnz	start3
		; 2. Rahmen links + rechts
		ld	b, 5
		ld	de, 0802h
start4:		push	bc
		inc	d
		push	de
		rst	8		; SETCU
		ld	e, 0FFh
		rst	10h		; CONSO
		ld	e, 25h 
		rst	8		; SETCU
		ld	e, 0FFh
		rst	10h		; CONSO
		pop	de
		pop	bc
		djnz	start4
		; 2. Rahmen unten
		ld	de, 0E02h
		rst	8		; SETCU
		ld	b, 24h 
start5:		ld	e, 0FFh
		rst	10h		; CONSO
		djnz	start5
		; Text in 2. Rahmen
		ld	de, 0A0Fh
		rst	8		; SETCU
		ld	de, aLesenUndVerarb ; "LESEN UND VERARBEITEN"
		rst	18h		; PRNST
		ld	de, 0C0Dh
		rst	8		; SETCU
		ld	de, aVonCommodoreKa ; "VON COMMODORE-KASSETTEN"
		rst	18h		; PRNST
		; Copyright
		ld	de, 1102h
		rst	8		; SETCU
		ld	de, aHansKittelmann ; "HANS KITTELMANN\n\n\r 8019 DRESDEN\n\n\r	HOLB"...
		rst	18h		; PRNST
		;
		call	enter		; Anzeige >ENTER<
start6:		call	os_consi	; Eingabe ein Zeichen von CONST
		cp	0Dh
		jr	nz, start6
		jr	menu

;------------------------------------------------------------------------------
; RST-Rufe f. Zeichenein- und ausgabe nutzen (Code wird kürzer)
;------------------------------------------------------------------------------

; RST8: Setzen logische Cursoradresse
rst8_setcu:	ld	c, SETCU	; Setzen logische Cursoradresse
		jr	callos

; RST10: Ausgabe eines	Zeichens zu CONST
rst10_conso:	ld	c, CONSO	; Ausgabe eines	Zeichens zu CONST
		jr	callos

; RST18: Ausgabe einer	Zeichenkette zu	CONST
rst18_prnst:	ld	c, PRNST	; Ausgabe einer	Zeichenkette zu	CONST
		jr	callos

; Eingabe ein Zeichen von CONST
os_consi:	ld	c, CONSI	; Eingabe eines	Zeichens von CONST
		jr	callos

; Anzeige >ENTER<
enter:		ld	de, 1716h
		rst	8		; SETCU
		ld	de, aEnter	; "	    >ENTER<"
		rst	18h		; PRNST
		ld	c, 1Dh

; Systemruf
callos:		call	5
		ret

;------------------------------------------------------------------------------
; Hauptmenu anzeigen
;------------------------------------------------------------------------------

menu:		ld	e, CLS
		rst	10h		; CONSO
		ld	de, 0203h
		rst	8		; SETCU
		ld	de, aMenueAaaaa1Pro ; "MENUE\n\r       \n\n\r  1 = PROGRAMM EINLESE"...
		rst	18h		; PRNST
		ld	c, 1Dh
		call	5
menu1:		call	os_consi	; Eingabe ein Zeichen von CONST
		cp	'1'
		jp	z, read		; Programm einlesen
		cp	'2'
		jp	z, conv		; Basic-Programm erstellen
		cp	'3'
		jp	z, list		; Basic-Programm listen
		cp	'4'
		jp	z, save		; Basic-Programm auf Kassette
		cp	'5'
		jr	nz, menu1
		ld	c, 0		; Rücksprung ins OS
		call	5


;------------------------------------------------------------------------------
; CTC und PIO init
;------------------------------------------------------------------------------

ioinit:		di
		call	INIC1		; System-Initialisierung
		;
		out	(PIO2BS), a	; Tastatur-PIO2	B Kommando
		out	(PIO1AS), a	; PIO1 A Kommando
		ld	a, 5
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 0B0h	; '°'
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 0Fh
		out	(PIO1AS), a	; PIO1 A Kommando
		ld	a, 0Ah
		out	(PIO1AS), a	; PIO1 A Kommando
		ld	a, 0E7h	; 'ç'
		out	(PIO1AS), a	; PIO1 A Kommando
		ei
		ret


;------------------------------------------------------------------------------
; Comodore Block einlesen
;------------------------------------------------------------------------------

rblock:		ld	b, 0
rblock1:	xor	a
		ld	(ARB), a
rblock2:	ld	a, (ARB)
		or	a
		jr	z, rblock2
		cp	91h 
		jr	c, rblock	; Comodore Block einlesen
		cp	9Bh 
		jr	nc, rblock	; Comodore Block einlesen
		djnz	rblock1
rblock3:	ld	b, 2
rblock4:	xor	a
		ld	(ARB), a
rblock5:	ld	a, (ARB)
		or	a
		jr	z, rblock5
		cp	84h 
		jr	nc, rblock3
		djnz	rblock4
		call	LSTOP		; Lesen eines Bits
		cp	20h 
		ccf
		ret	c
		ld	b, 8
		ld	e, 0
rblock6:	push	bc
		call	LSTOP		; Lesen eines Bits
		cp	20h 
		jr	nc, rblock8
		call	LSTOP		; Lesen eines Bits
		cp	20h 
		ret	c
;
rblock7:	ccf
		rr	e
		pop	bc
		djnz	rblock6
		inc	hl
		ld	(hl), e
		exx
		dec	bc
		ld	a, b
		or	c
		exx
		ret	z
		jr	rblock3
;
rblock8:	call	LSTOP		; Lesen eines Bits
		cp	20h 
		jr	c, rblock7
		pop	bc
		ccf
		ret


;------------------------------------------------------------------------------
; Dezimalwandung
;------------------------------------------------------------------------------

; Dezimalwandung HL

dezhl:		push	hl
		ld	a, l
		call	deza
		push	hl
		pop	de
		pop	hl
		ld	a, h
		call	deza
		ret

; Dezimalwandung A

deza:		ld	b, a
		and	0F0h 
		rrca
		rrca
		rrca
		rrca
		cp	0Ah
		jp	p, deza1
		or	30h ; '0'
		jr	deza2
deza1:		add	a, 37h ; '7'
deza2:		ld	l, a
		ld	a, b
		and	0Fh
		cp	0Ah
		jp	p, deza3
		or	30h ; '0'
		jr	deza4
deza3:		add	a, 37h ; '7'
deza4:		ld	h, a
		ret


;------------------------------------------------------------------------------
; Vorspann einlesen
;------------------------------------------------------------------------------

sub_80B:	ld	b, 9
		ld	hl, COBAS+1
		ld	a, 89h 		;
loc_812:	cp	(hl)
		jr	nz, loc_81A
		inc	hl
		dec	a
		djnz	loc_812
		ret
;
loc_81A:	scf
		ret

; ungenutzt
a0Fehlt:	db "0 FEHLT",0
aKeinBit00:	db "KEIN BIT 00",0
aKeinBit11:	db "KEIN BIT 11",0

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

; Programm einlesen

read:		ld	hl, COBAS	; Programm einlesen
		ld	e, CLS
		rst	10h		; CONSO
		ld	de, aCommodoreKasse ; "	COMMODORE-KASSETTE EINLEGEN\n\n\r TONBAND"...
		rst	18h		; PRNST
read1:		call	os_consi	; Eingabe ein Zeichen von CONST
		cp	0Dh
		jr	nz, read1
		call	ioinit
		exx
		ld	bc, 89h		; 
		exx
		call	rblock		; Comodore Block einlesen
		ld	de, aBlockLeseFehle ; "	 BLOCK-LESE-FEHLER"
		jr	c, read2
		call	sub_80B		; Vorspann einlesen
		ld	de, aVorspannFehlt ; "VORSPANN FEHLT"
		jr	c, read2
		call	INITA		; INITIALISIERUNG TASTATUR
		ld	de, aAadrEadrName ; "  AADR =\n\n\r  EADR =\n\n\r  NAME	=\n\n\r"
		rst	18h		; PRNST
		ld	hl, (COBAS+11)	; aadr
		call	dezhl
		ld	(BWS+0F9h), hl
		ld	(BWS+0FBh), de
		ld	hl, (COBAS+13)	; eadr
		call	dezhl
		ld	(BWS+0149h), hl
		ld	(BWS+014Bh), de
		ld	hl, COBAS+15	; name
		ld	de, BWS+0199h
		ld	bc, 1Fh
		ldir
		ld	hl, (COBAS+13)
		ld	de, (COBAS+11)
		or	a
		sbc	hl, de
		ld	de, 9
		add	hl, de
		push	hl
		exx
		pop	bc
		exx
		ld	hl, COBAS
		call	ioinit
		call	rblock		; Comodore Block einlesen
		ld	de, aBlockLeseFehle ; "	 BLOCK-LESE-FEHLER"
		jr	c, read2
		call	sub_80B		; Vorspann einlesen
		ld	de, aVorspannFehlt ; "VORSPANN FEHLT"
		jr	c, read2
		call	INITA		; INITIALISIERUNG TASTATUR
		jp	menu

; bei Fehler
read2:		call	INITA		; INITIALISIERUNG TASTATUR
		push	de
		ld	e, CLS
		rst	10h		; CONSO
		ld	de, 0202h
		rst	8		; SETCU
		pop	de
		rst	18h		; PRNST
		call	enter		; Anzeige >ENTER<
read3:		call	os_consi	; Eingabe ein Zeichen von CONST
		cp	0Dh
		jp	z, menu
		cp	3
		jr	nz, read3
		ld	c, 0
		call	5

;------------------------------------------------------------------------------
; HL hexadezimal in (IX).. ablegen
;------------------------------------------------------------------------------

; Konvertierung	HL hex->dez

todez:		push	de
		ld	b, 10h
		ld	de, 0
		ld	c, e
todez1:		add	hl, hl
		ld	a, e
		adc	a, e
		daa
		ld	e, a
		ld	a, d
		adc	a, d
		daa
		ld	d, a
		ld	a, c
		adc	a, c
		ld	c, a
		djnz	todez1
		ld	a, c
		call	outa		; Ausgabe A hexadezimal	  ASCII	2 Stellen
		ld	a, d
		call	outa		; Ausgabe A hexadezimal	  ASCII	2 Stellen
		ld	a, e
		call	outa		; Ausgabe A hexadezimal	  ASCII	2 Stellen
		pop	de
		ret

; A hexadezimal in (IX).. ablegen
outa:	push	af
		rrca
		rrca
		rrca
		rrca
		call	hexa		; Konvertierung	low Nibble A in	Hex Ascii
		pop	af

; Konvertierung	low Nibble A in	Hex Ascii
hexa:	and	0Fh
		add	a, 90h 
		daa			; DAA-Trick
		adc	a, 40h 
		daa
		ld	(ix+0),	a
		inc	ix
		ret

;------------------------------------------------------------------------------
; Token	ersetzen
;------------------------------------------------------------------------------

reptok:		push	hl
		ld	hl, tokenlst	
		sub	7Fh 		; Tokenoffset
		; Suche Token in Liste
		; d.h. suche n-tes Auftreten von CBh
		ld	b, a
reptok1:	ld	a, (hl)
		inc	hl
		cp	0CBh 		; 
		jr	nz, reptok1
		djnz	reptok1
		; Übertrage Basic-Befehl nach (IX)
reptok2:	ld	a, (hl)
		ld	(ix+0),	a
		inc	ix
		inc	hl
		ld	a, (hl)
		cp	0CBh 		; Ende erreicht?
		jr	nz, reptok2
		pop	hl
		ret

; Liste der Commodore-Basic-Befehle, Reihenfolge wie COMMDORE-Token 80H (END) ...CBH (GO)
; 73 Token, vgl. http://www.c64-wiki.com/index.php/BASIC_token

tokenlst:	db 0CBh,"END",0CBh,"FOR",0CBh,"NEXT",0CBh,"DATA",0CBh,"INPUT#"
		db 0CBh,"INPUT",0CBh,"DIM",0CBh,"READ",0CBh,"LET",0CBh,"GOTO"
		db 0CBh,"RUN",0CBh,"IF",0CBh,"RESTORE",0CBh,"GOSUB",0CBh,"RETURN"
		db 0CBh,"REM",0CBh,"STOP",0CBh,"ON",0CBh,"WAIT",0CBh,"LOAD"
		db 0CBh,"SAVE",0CBh,"VERIFY",0CBh,"DEF",0CBh,"POKE",0CBh,"PRINT#"
		db 0CBh,"PRINT",0CBh,"CONT",0CBh,"LIST",0CBh,"CLR",0CBh,"CMD"
		db 0CBh,"SYS",0CBh,"OPEN",0CBh,"CLOSE",0CBh,"GET",0CBh,"NEW"
		db 0CBh,"TAB(",0CBh,"TO",0CBh,"FN",0CBh,"SPC(",0CBh,"THEN",0CBh,"NOT"
		db 0CBh,"STEP",0CBh,"+",0CBh,"-",0CBh,"*",0CBh,"/",0CBh,"^"
		db 0CBh,"AND",0CBh,"OR",0CBh,">",0CBh,"=",0CBh,"<",0CBh,"SGN"
		db 0CBh,"INT",0CBh,"ABS",0CBh,"USR",0CBh,"FRE",0CBh,"POS",0CBh,"SQR"
		db 0CBh,"RND",0CBh,"LOG",0CBh,"EXP",0CBh,"COS",0CBh,"SIN",0CBh,"TAN"
		db 0CBh,"ATN",0CBh,"PEEK",0CBh,"LEN",0CBh,"STR$",0CBh,"VAL"
		db 0CBh,"ASC",0CBh,"CHR$",0CBh,"LEFT$",0CBh,"RIGHT$",0CBh,"MID$"
		db 0CBh,"???",0CBh


;------------------------------------------------------------------------------
;Basic-Programm erstellen
;------------------------------------------------------------------------------


conv:		ld	ix, KCBAS	; Zielspeicher f. Basic-Programm 
		ld	hl, COBAS+1	; Quelle Comodore-Programm
		ld	a, 89h 		;
		ld	b, 9
conv1:		cp	(hl)
		ld	de, aVorspannFehlt ; "VORSPANN FEHLT"
		jp	nz, read2
		dec	a
		inc	hl
		djnz	conv1
		dec	hl
		; KC-Basic-Kopf aufbauen
		ld	b, 3		; 3x D5
conv2:		ld	(ix+0),	0D5h 	; Kennung Basic-Programm (ASCII)
		inc	ix
		djnz	conv2
		ld	(ix+0),	42h 	; 'B'
		ld	(ix+1),	41h 	; 'A'
		ld	(ix+2),	53h 	; 'S'
		ld	(ix+3),	50h 	; 'P'
		ld	(ix+4),	52h 	; 'R'
		ld	(ix+5),	4Fh 	; 'O'
		ld	(ix+6),	20h 	; ' '
		ld	(ix+7),	20h 	; ' '
		ld	(ix+8),	0Dh	; neue Zeile vorbereiten
		ld	(ix+9),	0Ah
		ld	b, 0Ah
conv3:		inc	ix
		djnz	conv3
conv4:
		; Adresse der BASIC-Zeile prüfen
		inc	hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ld	a, d		; Ende (0000) erreicht ?
		or	e
		jr	z, conve	; Endekennzeichen (03)
		; Zeilennummer 
		inc	hl
		ld	c, (hl)
		inc	hl
		ld	b, (hl)
		push	hl
		push	bc
		pop	hl
		call	todez		; Konvertierung	HL hex->dez
		pop	hl
		; 
		xor	a
		ld	(ARB0), a
conv5:		inc	hl
		ld	a, (hl)		; nächstes Zeichen
		or	a
		jr	z, conv10	; Zeilenende
		cp	' '
		jr	nc, conv6	; Steuercodes durch 5F '_' ersetzen
		ld	a, 5Fh ; '_'
conv6:		cp	22h ; '"'	; Stringanfang?
		jr	nz, conv7	; nein
		ld	(ix+0),	a
		inc	ix
		ld	a, (ARB0)	; Stringflag setzen
		cpl
		ld	(ARB0), a
		jr	conv5		; string komplett übernehmen
		;		
conv7:		cp	7Fh 		; Token?
		jr	c, conv8	; nein
		cp	0E2h 		; max. mögliches Token
		jr	nc, conv8	; überschritten	
		ld	b, a
		ld	a, (ARB0)
		or	a		; in String?
		ld	a, b
		jr	nz, conv8	; dann übergehen
		call	reptok		; Token	ersetzen
		jr	conv5		; und weiter mit nächstes Zeichen
		;
conv8:		cp	7Fh 		; Token?
		jr	c, conv9	; nein
		ld	a, 5Fh 		; durch 5F '_' ersetzen
conv9:		ld	(ix+0),	a
		inc	ix
		jr	conv5		; und weiter mit nächstes Zeichen
		; Zeilenende
conv10:		push	hl
		inc	hl
		sbc	hl, de
		ld	de, 4000h	
		sbc	hl, de		; max. Größe überschritten?
		pop	hl
		ld	de, aFehlerInNeueAd ; "FEHLER IN NEUE ADRESSE"
		jp	nz, read2
		; neue Zeile vorbereiten
		ld	a, 0Dh
		ld	(ix+0),	a
		inc	ix
		ld	a, 0Ah
		ld	(ix+0),	a
		inc	ix
		jr	conv4
		; Endekennzeichen schreiben
conve:		ld	a, 3		; Endekennzeichen (03)
		ld	(ix+0),	a
		jp	menu

;------------------------------------------------------------------------------
; Basic-Programm listen
;------------------------------------------------------------------------------

list:		ld	hl, KCBAS+11	; Basic-Programm listen
		ld	e, CLS
		rst	10h		; CONSO
		ld	a, 3
list1:		ld	e, (hl)
		cp	e		; Ende (03) erreicht?
		jp	z, menu		; dann Rücksprung ins Menü
		rst	10h		; sonst	Zeichen	ausgeben (CONSO)
		inc	hl		; 
		jr	list1

;------------------------------------------------------------------------------
; Basic-Programm auf Kassette
;------------------------------------------------------------------------------

save:		ld	hl, KCBAS	; Basic-Programm auf Kassette
		ld	(DMA), hl
		ld	a, 1
		ld	(BLNR), a
		ld	e, CLS
		rst	10h		; CONSO
		ld	de, aStartTapeForWr ; "\n\n START TAPE FOR WRITE BASPRO\n\n\r UND >"...
		rst	18h		; PRNST
save1:		call	os_consi	; Eingabe ein Zeichen von CONST
		cp	0Dh
		jr	nz, save1
		ld	bc, 1770h	; langer Vorton
save2:		call	WRIT1		; Blockschreiben sequentiell
		ld	e, ' '
		rst	10h		; CONSO
		push	ix
		pop	hl
		ld	de, (DMA)
		or	a
		sbc	hl, de
		jp	c, menu
		ld	bc, 800h	; mittellanger Vorton
		jr	save2

;------------------------------------------------------------------------------
; Speicher für BASIC-Programme
;------------------------------------------------------------------------------

COBAS		equ	47F7h			; Commodore-Basic-Programm
KCBAS		equ	COBAS+4000h		; konvertiertes KC-Basic

		end
