;------------------------------------------------------------------------------
; Z9001
; (c) V. Pohlers 2012
; letzte Änderung 19.02.2012 19:16:56
; rem 29.03.2013 probehalber in prepdfcb: call chkwrt aktiviert
; rem 23.11.2017 bei openw optional auf Schreiben des Blocks verzichten
; 02.03.2019 Missbrauch von AUR2 für ON_COLD
; 23.12.2019 neue BOS-Funktion 19 DIRS
;------------------------------------------------------------------------------
; CP/M-Disketten unter OS
; DOS/CAOS
; Umbiegen des CALL5 auf Routinen zur Nutzung der Diskette (via BDOS)
;------------------------------------------------------------------------------

		cpu	z80

	section	call5

;BDOS functions
OPENF		EQU	15		;open file function
CLOSEF		EQU	16		;close file function
DELF		EQU	19		;delete file function
DREADF		EQU	20		;disk read function
DWRITF		EQU	21		;disk write function
MAKEF		EQU	22		;file make function
DMAF		EQU	26		;set dma address

;;BDOS		EQU	4006H		;primary bdos entry point
BUFF:		EQU	0080H		;default buffer

;-----------------------------------------------------------------------------
; neuer BOS-Call
;-----------------------------------------------------------------------------

BOS		equ	0F314h		; orig. Call 5
;;BOSE		equ	0f345h
;;BOSER		equ	0f5deh		;UNERLAUBTER SYSTEMRUF

;;SPSV:		EQU	000BH		;REGISTER FUER NUTZERSTACK
;;BCSV:		EQU	000DH		;REGISTER FUER BC
;;ASV:		EQU	000FH		;REGISTER FUER A
DMA		equ	001Bh
FCB		equ	005Ch
BLNR		equ	FCB+15
LBLNR		equ	FCB+16
;SBY		equ	FCB+23		;Schutzbyte (wird ignoriert)
;NFHD		equ	FCB+24		;'N' - bei open kein Block lesen/schreiben

MAPPI:		EQU	0F000H-64	;SYSTEMBYTE

AUR2		equ	0EFD7h		; Eigentlich Adresse UR2-Treiber für READER
					; hier f. Re-Init ON_COLD genutzt

singleprg	equ	0

	if singleprg

		public	initdos

		align	100h

		jp	initdos
		db	"DOS     ",0
		jp	exitdos
		db	"CAOS    ",0
		db	0
	
	else
		public	initdos, exitdos
		public	OPENR,OPENW,CLOSW,READS,WRITS,RRAND,DIRS

	endif
	
;-----------------------------------------------------------------------------
; CAOS
;-----------------------------------------------------------------------------


exitdos:	ld	hl, BOS
		ld	(6), hl

		ld	hl,0ffffh
		ld	(AUR2),hl

		ld	de,txt_caosinit
		ld	c,9
		call	5
		
		ret

txt_caosinit	db	"CASSETTE OS",0

;-----------------------------------------------------------------------------
; DOS
;-----------------------------------------------------------------------------

initdos:
		; jpvek für Call5-Haendler kopieren und ändern
		; 02.10.2018 zuerst an dieser Stelle, falls DOSX doppelt gestartet wird
		; durch Neuladen ist sonst der Sprungverteiler weg und der nachfolgende CALL 5
		; springt ins Leer
		ld	hl,0f045h
		ld	de,jpvek
		ld	bc,33*2
		ldir

		; Boot-Message
		ld	de,txt_dosinit
		ld	c,9
		call	5

		; init BDOS
		call	BiOS		;BOOT von BIOS

		; jpvek für Call5-Haendler kopieren und ändern
;;		ld	hl,0f045h
;;		ld	de,jpvek
;;		ld	bc,33*2
;;		ldir
		if ubios
		ld	hl,uOPENR
		else
		ld	hl,OPENR
		endif
		ld	(jpvek+13*2), hl
		if ubios
		ld	hl,uOPENW
		else
		ld	hl,OPENW
		endif
		ld	(jpvek+15*2), hl
		if ubios
		ld	hl,uCLOSW
		else
		ld	hl,CLOSW
		endif
		ld	(jpvek+16*2), hl
		if ubios
		ld	hl,uREADS
		else
		ld	hl,READS
		endif
		ld	(jpvek+20*2), hl
		if ubios
		ld	hl,uWRITS
		else
		ld	hl,WRITS
		endif
		ld	(jpvek+21*2), hl
		if ubios
		ld	hl,uRRAND
		else
		ld	hl,RRAND
		endif
		ld	(jpvek+33*2), hl
		;
		if ubios
		ld	hl,uDIRS
		else
		ld	hl,DIRS
		endif
		ld	(jpvek+19*2), hl
		;
		ld	hl,cload5
		ld	(jpvek+34*2), hl
		ld	hl,csave5
		ld	(jpvek+35*2), hl

		; neuer Call 5 -Haendler
		ld	hl, CBDOS
		ld	(6), hl

		ld	hl,uDOS
		ld	(AUR2),hl	;ON_COLD
		
		ret

txt_dosinit:
	if shadow
		db	"SHADOW "
	endif
		db	"DISK OS V.Pohlers ",DATE,0dh,0ah,0

;-----------------------------------------------------------------------------
; CALL 5-Routine
;-----------------------------------------------------------------------------

	if singleprg

CBDOS:		LD	(SPSV),SP	;SICHERN ANWENDERSTACK
		LD	SP,1C0H		;BOS - STACK
		SCF
		CCF
		PUSH	HL
		PUSH	DE
		PUSH	AF
		LD	(BCSV),BC
		LD	(ASV),A
		LD	HL,BOSE
		PUSH	HL		;RUECKKEHRADRESSE KELLERN
		LD	A,33
		CP	A, C
		JP	C, BOSER	;UNERLAUBTER SYSTEMRUF
		LD	B,0
		LD	HL,JPVEK	;ADRESSTABELLE DER SYSTEMRUFE
		ADD	HL,BC
		ADD	HL,BC
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		LD	C,E		;EINGANGSPARAMETER
		LD	B,D		;UEBERNEHMEN
		LD	A,(ASV)
		PUSH	HL		;SYSTEMRUFADRESSE KELLERN
		LD	L,3		;ANFANGSWERT FUER CURSORRUFE
		RET			;SPRUNG ZUR AUSFUEHRUNG

	endif

; die einzelnen Funktionen

;-----------------------------------------------------------------------------
; # OPENR C=13
;
; Funktion:
; 	- Ausgabe der Ausschrift 'start tape'
; 	- Lesen Block 0 einer Datei von Kassette
; 	- Vergleich gelesener Dateiname mit gesuchtem Dateinamen
; 	- bei Namensgleichheit übernehmen der gelesenen Dateiparameter in den FCB (siehe 2.3.4.)
; 	- Ausgabe eines Leerzeichens zum aktuellen CONST-Gerät
; 	- Kassettenpuffer ist die aktuelle DMA-Adresse (siehe Ruf 26)
; Eingang:
; 	- Name und Typ der gewünschten Datei im FCB
; 	- DMA (1BH) Adresse Kassettenpuffer für Block 0
; Return:
; 	- aktualisierte Dateiparameter im FCB (Anfangsadresse, Endadresse, Startadresse, Schutzbyte)
; 	- LBLNR (6CH) nächste zu lesende Blocknummer (1)
; 	- CY Fehlerstatus
;-----------------------------------------------------------------------------
OPENR:
		;DFCB füllen
		call	prepdfcb
		;File eröffnen
		ld	de,DFCB
		ld	c,OPENF
		call	BDOS
		inc	a
		jr	z,OPENRf
		;
		XOR	A
		LD	(DFCB+32),A	; clear next record field

		;Anz. Records holen
		ld	de,DFCB
		ld	c,35		; Compute file size
		call	BDOS
		ld	hl,(DFCB+33)
		dec	hl		; Kopflblock
		ld	(DRECCNT),hl

		;Block 0 lesen
		ld	de,(DMA)
		ld	c,DMAF
		call	BDOS
		ld	de,DFCB
		ld	c,DREADF
; 23.11.2017 Block 0 nicht lesen, wenn spezielles Flag gesetzt
		ld	a,(fcb+24)
		cp	'N'
;		CALL	NZ, BDOS
		jr	nz,openr1	; N-nicht lesen
		ld	hl,(DRECCNT)
		inc	hl		; dafür ein Block mehr merken
		ld	(DRECCNT),hl
		jr	openr2
openr1:		CALL	BDOS
openr2:		ld	hl,fcb+24
		ld	(hl),0		; special flag off

		ld	a,0
		ld	(BLNR),A
		inc	a
		ld	(LBLNR),A
		ld	hl,(DMA)
		LD	DE,17
		ADD	HL,DE
		LD	DE,FCB+17	; AADR, ...
		LD	BC,8
		LDIR			; Parameter in FCB übernehmen
		xor	a		; kein Fehler

OPENRe		ret
;
OPENRf		ld	a,13		; file not found error
		scf
		jr	OPENRe

;------------------------------------------------------------------------------
; READS C=20
; Funktion:
; 	- Lesen eines Blockes einer Datei von der Kassette
; 	- Ausgabe eines Leerzeichens zum aktuellen CONST-Gerät
; Eingang:
; 	- LBLNR (6CH) zu lesende Blocknummer
; 	- DMA (1BH) Adresse, auf welcher der Block abgelegt wird
; Return:
; 	- A Kennzeichen für letzten Block der Datei (EOF)
; 		kein EOF 0
; 		EOF 1
; 	- LBLNR LBLNR neu = LBLNR alt + 1
; 	- DMA DMA neu = DMA alt + 80H
; 	- CY Fehlerstatus
; 	- BLNR die wirklich gelesene Blocknummer (auch im Fehlerfall)
;-----------------------------------------------------------------------------
READS:		call	RRAND

		ld	HL,(DMA)
		LD	DE,80h
		ADD	HL,DE
		LD	(DMA),HL
		LD	HL,LBLNR
		INC	(HL)

		or	a		;Cy=0
		ret

;-----------------------------------------------------------------------------
; # C=33	RRAND
;
;Funktion:
;	- Lesen eines einzelnen Blockes einer Datei
;	- keine Veränderung von LBLNR und DMA (vgl. Systemruf 20)
;Eingang:
;	- LBLNR (6CH) zu lesende Blocknummer
;	- DMA (1BH) Adresse auf welcher der Block abgelegt wird
;Return:
;	- A Kennzeichen für letzten Block der Datei (EOF)
;		kein EOF 0
;		EOF 1
;	- CY Fehlerstatus
;	- BLNR (6BH) die wirklich gelesene Blocknummer (auch im Fehlerfall)
;Hinweis:
;	- wird der letzte Block erkannt, kehrt das Programm mit A=1 (EOF) zurück
;-----------------------------------------------------------------------------

RRAND:		ld	de,(DMA)
		ld	c,DMAF
		call	BDOS
		ld	de,DFCB
		ld	c,DREADF
		call	BDOS
		;
		ld	hl,(DMA)
		ld	de,128
		add	hl,de
		ld	(fcb+25), hl	;vp LEADR merken
		;
		push	af
		ld	a,(lblnr)
		ld	(blnr),a	; BLNR := LBLNR
		ld	b, a
		pop	af
		or	a		; Dateiende erreicht?
		jr	nz,RRAND2	; ja (A=1)
		
		ld	a,(DRECCNT)	; letzter Block der Datei?
		cp	b
		ld	a, 0
		jr	nz, RRAND1	; nein (A=0)
		
		; Dateiende
RRAND2		ld	a,0ffh
		ld	(BLNR),A
		ld	a,1		; Kennung Endeblock A=1
RRAND1		ld	(ASV),a
		or	a		;Cy=0
		ret

;-----------------------------------------------------------------------------
; # OPENW C=15
;
; Funktion:
; 	- Ausgabe der Ausschrift 'start tape'
; 	- Ausgabe von Block 0 auf Kassette
; Eingang:
; 	- Name Typ und Dateiparameter im FCB (von Nutzer zu initialisieren) (siehe 2.3.4.)
; Return:
; 	- A Nummer des geschriebenen Blocks (0)
; 	- BLNR Blocknummer des nächsten Blocks (1)
; 	- CY Fehlerstatus
;
;-----------------------------------------------------------------------------
OPENW:
		;DFCB füllen
		call	prepdfcb
		;File eröffnen
		ld	de,DFCB
		ld	c,DELF
		call	BDOS
		ld	de,DFCB
		ld	c,MAKEF
		call	BDOS
		inc	a		; A = FF ist Fehler
		ld	a,13		; Fehler 13
		scf
		ret	z		; wenn nicht anlegbar
		;
		XOR	A
		LD	(DFCB+32),A	; clear next record field
		
		;Block 0 Schreiben
		LD	HL,(DMA)
		PUSH	HL
		LD	HL,FCB
		LD	(DMA),HL	;SCHREIBEN DES FCB
		LD	A,0
		LD	(FCB+23),A	;KEIN SCHUTZ
		XOR	A
		LD	(BLNR),A	;BLOCKNUMMER 0
		LD	A,2
		LD	(LBLNR),A
		ld	(WRITFLG),a	;Status merken
; 23.11.2017 Block 0 nicht schreiben, wenn spezielles Flag gesetzt
		ld	hl,fcb+24
		ld	a,(hl)
		ld	(hl),0		; special flag off
		cp	'N'
		CALL	NZ,WRITS		;SCHREIBEN BLOCK
		POP	HL
		LD	(DMA),HL	;PUFFERADR. AUF AUSGANGSWERT
		RET

; DFCB aufbereiten
prepdfcb:	call	chkwrt		; wurde letzte zu schreibende Datei mit closw beendet?

		; FCB mit 0 füllen
		ld	hl,dfcb
		ld	(HL),0
		ld	de,dfcb+1
		ld	bc,35
		ldir
		;current disk
		ld	a,0
		ld	(DFCB+0),a	;current disk = 0
		;Name + Typ übertragen
		ld	b,11		;8+3
		ld	hl,FCB
		ld	de,DFCB+1
prepdfcb2:	ld	a,(HL)
		and	7Fh		;strip high-bit
		cp	0		;00 wird Leerzeichen
		jr	nz, prepdfcb1
		ld	a, ' '
prepdfcb1:	ld	(de),a
		inc	hl
		inc	de
		djnz	prepdfcb2
		;COM-->KCC
		ld	hl,DFCB+9
		ld	a, (HL)
		cp	'C'
		ret	nz
		inc	hl
		ld	a, (HL)
		cp	'O'
		ret	nz
		inc	hl
		ld	a, (HL)
		cp	'M'
		ret	nz
		ld	(HL),'C'
		dec	hl
		ld	(HL),'C'
		dec	hl
		ld	(HL),'K'
		ret

;-----------------------------------------------------------------------------
; WRITS C=21
;
; Funktion:
; 	- Schreiben eines Blockes einer Datei auf Kassette
; Eingang:
; 	- BLNR (6BH) Nummer des zu schreibenden Blockes
; 	- DMA (1BH) Speicheradresse, ab der zu schreiben ist
; Return:
; 	- A Nummer des geschriebenen Blockes
; 	- BLNR BLNR neu = BLNR alt + 1
; 	- DMA DMA neu = DMA alt + 80H
;-----------------------------------------------------------------------------

;
;BLOCKSCHREIBEN SEQUENTIELL
;
WRITS:		LD	DE,(DMA)	;PUFFERADRESSE
		LD	A,(MAPPI)
		OR	A
		JR	Z, WRIT2	;KEIN SCHUTZ VOR SCHREIBEN
WERR:		LD	A,9		;SCHREIBSCHUTZ
WERR1:		SCF			;FEHLERAUSGANG
		RET
WRIT2:		
;;		LD	HL,(EOR)	;LOGISCHES RAM - ENDE
;;		PUSH	DE
;;		LD	DE,7FH
;;		SBC	HL,DE
;;		POP	DE
;;		CALL	COMPW		;ADRESSVERGLEICH
;;		LD	A,10
;;		JR	C, WERR1	;BLOCK LIEGT HINTER RAM - ENDE
;;		EX	DE,HL
;;		CALL	CHRAM		;LOGISCHER SPEICHERTEST
;;		JR	NC, WERR	;BEREICH IST GESCHUETZT/ROM
		CALL	KARAM		;AUSGABE BLOCK
		RET	C
		ld	hl,(DMA)	; DMA erhöhen
		ld	bc,0080h
		add	hl,bc
		LD	(DMA),HL	;PUFFERADR. UM 128 ERHOEHEN
		LD	HL,BLNR
		LD	A,(HL)
		LD	(ASV),A		;BLOCKNUMMER ZURUECKGEBEN
		INC	(HL)		;BLOCKNUMMER ERHOEHEN
		ret

KARAM:		ld	de,(DMA)
		ld	c,DMAF
		call	BDOS
		ld	de,DFCB
		ld	c,DWRITF
		call	BDOS
		or	a
		ret	z
		scf
		ld	a,10		; fehler eom
		ret			; bei Fehler ist A<>0
		;

;-----------------------------------------------------------------------------
; # CLOSW C=16
;
; Funktion:
; 	- Ausgabe des letzten Blockes einer Datei auf Kassette
; Return:
; 	- A Nummer des geschriebenen Blockes (FF)
; 	- BLNR die Merkzelle der Blocknummer hat den Wert 0
; 	- CY Fehlerstatus
;-----------------------------------------------------------------------------
CLOSW:
		ld	a, 0ffh
		ld	(BLNR),a
		call	WRITS		; Letzten Block schreiben
		push	af
		ld	de,DFCB
		ld	c,CLOSEF
		call	BDOS		; File schließen
		call	chkwrt0
		pop	af
		ret

;-----------------------------------------------------------------------------
; vor neuen Dateien prüfen, ob letzte geschriebene Datei schon geschlossen wurde

chkwrt:		ld	a,(WRITFLG)
		or	a
		ret	z
		;ansonsten letzte Datei schließen
		ld	de,DFCB
		ld	c,CLOSEF
		call	BDOS		; File schließen
chkwrt0:	xor	a
		ld	(WRITFLG),a
		ret
;
WRITFLG		db	0		; aktuell im Schreib-Modus?

;-----------------------------------------------------------------------------
; # DIRS C=19
;
; Funktion:
; 	- LIST FILES
; Eingang:
;	- A Bit 7 = 1 Suchmuster in INTLN+1
;	- A Bit 6 = 1 keine Ext. anzeigen	(nicht implementiert)
;	- DE = String, mit 00-Byte
; Return:
;	-
;-----------------------------------------------------------------------------

DIRS:		LD	HL,BUFF+2
		;
		bit	7,A		; Suchmuster?
		jr	nz,dirs0	; ja
		;nein, alles anzeigen
		ld	(HL),0		; letztes Zeichen
		jp	DIRECT		; Directory anzeigen

		;ja, mit suchstring
DIRS0:		ld	(hl),'*'
		inc	hl
		ld	(hl),'.'
		inc	hl
dirs2:		ld	a,(de)
		cp	'?'
		jr	z,dirs1
		ld	(hl),a
		inc	hl
dirs1:		inc	de
		or	a
		jp	z,DIRECT
		jr	dirs2

;-----------------------------------------------------------------------------

DFCB:		ds	36		; FCB für CBDOS-Operationen
DRECCNT:	ds	2		; Anzahl der Records bei READ

	if singleprg
JPVEK:		ds	(33+2)*2
	endif
	
;-----------------------------------------------------------------------------

	endsection

