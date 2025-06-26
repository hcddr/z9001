;------------------------------------------------------------------------------
; Z9001
; (c) V. Pohlers 2025
; vgl. usbos.asm (standalone: osVDIP.asm)

;------------------------------------------------------------------------------
; CH376-USB unter OS
; DOS/CAOS
; Umbiegen des CALL5 auf Routinen zur Nutzung des USB-Sticks
;------------------------------------------------------------------------------

		cpu	z80

CONBU		EQU	0080H		;default buffer

rst_sbos	macro
		;rst	28h		;der RST für den Sprungverteiler
		CALL 0C02Fh
		endm


;-----------------------------------------------------------------------------
; neuer BOS-Call
;-----------------------------------------------------------------------------

BOS		equ	0F314h		; orig. Call 5
BOSE		equ	0f345h
BOSER		equ	0f5deh		;UNERLAUBTER SYSTEMRUF
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H

SPSV:		EQU	000BH		;REGISTER FUER NUTZERSTACK
BCSV:		EQU	000DH		;REGISTER FUER BC
ASV:		EQU	000FH		;REGISTER FUER A
DMA		equ	001Bh
FCB		equ	005Ch
BLNR		equ	FCB+15
LBLNR		equ	FCB+16
;SBY		equ	FCB+23		;Schutzbyte (wird ignoriert)
;NFHD		equ	FCB+24		;'N' - bei open kein Block lesen/schreiben
LEADR		equ	FCB+25		;letzte gefüllte Adr+1

MAPPI:		EQU	0F000H-64	;SYSTEMBYTE

AUR2		equ	0EFD7h		; Eigentlich Adresse UR2-Treiber für READER
					; hier f. Re-Init ON_COLD genutzt


;		org	0b800h
		org	0b600h

start		jp	initdos
		db	"DOS     ",0
		jp	exitdos
		db	"CAOS    ",0
		jp	dirkdo
		db	"DDIR    ",0
		jp	cdkdo
		db	"CD      ",0
		jp	erakdo
		db	"ERA     ",0
		db	0
	
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

txt_caosinit	db	"CASSETTE OS",0dh,0ah,0

;-----------------------------------------------------------------------------
; DOS
;-----------------------------------------------------------------------------

initdos:	ld	hl, BOS
		ld	(6), hl

		; Boot-Message
		ld	de,txt_dosinit
		ld	c,9
		call	5

		; CH376 init
		call	usb__reset
		call	usb__ready
		jp	nz, novdip
		;; Test auf gültigen Pfad
		call	usb__open_path
		jr	z, init_path_ok
		;; Wenn ungültig, mit root initialisieren
		call	usb__root
init_path_ok:

initdos1
		; jpvek für Call5-Haendler kopieren und ändern
		ld	hl,0f045h
		ld	de,jpvek
		ld	bc,35*2
		ldir
		ld	hl,OPENR
		ld	(jpvek+13*2), hl
		ld	hl,OPENW
		ld	(jpvek+15*2), hl
		ld	hl,CLOSW
		ld	(jpvek+16*2), hl
		ld	hl,READS
		ld	(jpvek+20*2), hl
		ld	hl,WRITS
		ld	(jpvek+21*2), hl
		ld	hl,RRAND
		ld	(jpvek+33*2), hl
		;
		ld	hl,DIRS
		ld	(jpvek+19*2), hl
		ld	hl,CHDIR
		ld	(jpvek+32*2), hl
		;	
		ld	hl,cload5
		ld	(jpvek+34*2), hl
		ld	hl,csave5
		ld	(jpvek+35*2), hl

		; neuer Call 5 -Haendler
		ld	hl, CBDOS
		ld	(6), hl

eor		equ	0036h		; EOR	oberes RAM-Ende
		ld	hl,start-101h	; OS löscht bei Reset 100h ab EOR!
		LD	(eor), HL

		ld	hl,initdos
		ld	(AUR2),hl	;ON_COLD
		
		xor	a
		ret

novdip:		ld	hl,0ffffh
		ld	(AUR2),hl	;ON_COLD
		
		ld	de,txt_novdip
		ld	c,9
		call	5
		xor	a
		ret

txt_dosinit:
		db	"CH376-USB OS V.Pohlers ",DATE,0dh,0ah,0
txt_novdip:
		db	"Kein USB-Modul!",0dh,0ah,0

;-----------------------------------------------------------------------------
; CALL 5-Routine
;-----------------------------------------------------------------------------

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
		LD	A,35		; 
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
	call	usb__close_file	; letzte Datei noch schließen?
	call	prepfn
	ld	hl, filename
	call	usb__open_read
	jr	nz, OPENRf

	call	usb__get_file_size	; Dateigröße nach DEHL und Nummer des letzten Blocks berechnen
	sla	l		; DEHL = DEHL * 2
	rl	h
	rl	e
	rl	d
	ld	a, l		; aufrunden(HL / 256) - 1
	or	a		; 
	jr	nz, nrblocks
	dec	h
nrblocks:
	ld	a,(fcb+24)	; Wenn block 0 nicht lesen,
	cp	'N'		; Letzen block um eins erhöhen
	jr	nz, noextrablock
	inc	h
noextrablock:	
	ld	a, h
	ld	(EBLNR), a	; Letzte blocknummer
;		;Block 0 lesen
		ld	a,0
		ld	(LBLNR),A

; 23.11.2017 Block 0 nicht lesen, wenn spezielles Flag gesetzt
		ld	a,(fcb+24)
		cp	'N'
		CALL	NZ, RRAND		;BLOCK LESEN
		ld	hl,fcb+24
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
		ret
;
OPENRf		ld	a,13		; file not found error
		scf
		ret

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
READS:		CALL	RRAND
		RET	C

		LD	(DMA),HL
		LD	HL,LBLNR
		INC	(HL)

		PUSH	AF
    		CALL	OSPAC		;AUSGABE LEERZEICHEN
		POP	AF

		RET

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

RRAND:
	ld	hl, (dma)
	ld	de, 128
	call	usb__read_bytes
	ld	(LEADR), hl	; letzte beschriebene Adresse + 1 speichern
	jr	nz, rreadc	; Lesefehler
	ld	a, d
	or	e
	jr	z, rreadc	; Fehler, wenn nichts gelesen (DE == 0) 
	ld	a, (EBLNR)	; Letzter Block erreicht?
	ld	b, a
	ld	a, (LBLNR)
	cp	b
	jr	z, rrandeof	; Ja
	ld	(BLNR), a	; Nein, weiterlesen
	xor	a
	ld	(ASV), a
	ret


rrandeof: ;; Letzten Block gelesen
	call	usb__close_file
	ld	a, 0FFh
	ld	(BLNR), a
	ld	a, 1
	ld	(ASV), a
	or	a
	ret

rreadc:	;; bei Fehler und unerwartetem Dateiende
	call	usb__close_file
	ld	a, 12		; Lesefehler
	scf
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
	call	usb__close_file	; letzte Datei noch schließen?
	call	prepfn		; neuen Filename aufbereiten
	ld	hl, filename
	call	usb__open_write
	jr	nz, openwerr

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
; 23.11.2017 Block 0 nicht schreiben, wenn spezielles Flag gesetzt
		ld	hl,fcb+24
		ld	a,(hl)
		ld	(hl),0		; special flag off
		cp	'N'
		CALL	NZ, WRITS		;SCHREIBEN BLOCK
		POP	HL
		LD	(DMA),HL	;PUFFERADR. AUF AUSGANGSWERT
		RET

openwerr:
	scf
	ld	a, 13	; file not found error
	ret

;Filename aufbereiten
prepfn		;Filename 8 Zeichen
		ld	hl,FCB		;quelle
		ld	de,filename	;ziel
		ld	b,8
prepfn2		ld	a,(hl)
		;or	A		;00?
		cp	0
		jr	z, prepfn1
		cp	' '		;Leerzeichen
		jr	z, prepfn1
		ld	(de),a
		inc	de
prepfn1		inc	hl
		djnz	prepfn2
		;Trennz.
		ld	a,'.'
		ld	(de),A		
		inc	de
		;Typ
		ldi			;wenn hier 0 kommt, ist das nicht schlimm
		ldi
		ldi
		;Ende-0
		xor	a
		ld	(de),A		
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

;den Test auf EOR mach ich nicht, wir wollen ja auch ROMs leicht speichern...
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
		LD	(DMA),HL	;PUFFERADR. UM 128 ERHOEHEN
		LD	HL,BLNR
		LD	A,(HL)
		LD	(ASV),A		;BLOCKNUMMER ZURUECKGEBEN
		INC	(HL)		;BLOCKNUMMER ERHOEHEN
		RET

KARAM:		
	ld	hl, (DMA)
	ld	de, 128
	call	usb__write_bytes
	jr	nz, KARAM_ERR
	xor	a
	ret
KARAM_ERR:
	CALL	usb__close_file
	LD	A, 11
	SCF
	RET

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
CLOSW:		ld	a, 0ffh
		ld	(BLNR),a
		call	WRITS		; Letzten Block schreiben
		push	af

		call	usb__close_file

		pop	af
		ret



;-----------------------------------------------------------------------------
; # DIRS C=19
;
; Funktion:
; 	- LIST FILES
; Eingang:
;	- A Bit 7 = 1 Suchmuster in DE, sonst alles anzeigen
;	- A Bit 6 = 1 Dateityp nicht anzeigen
;	- DE = String, mit 00-Byte
; Return:
;	-
;-----------------------------------------------------------------------------
DIRS:		ld	(PARBU), A
		bit	7,A		; Suchmuster?
		jp	z,dirkdo0	; nein, alles anzeigen
		;Suchstring nach INTLN kopieren, Längenbyte eintragen	
		;INTLN String im OS-Format, z.B. db 3,"ZBS",0
		ld	b,0
		ld	hl,intln+1
dirs2:		ld	a,(de)
		ld	(hl),a
		or	a
		jr	z,dirs1
		inc	hl
		inc	de
		inc	b
		jr	dirs2	
dirs1:		ld	hl,intln
		ld	(hl),b		
		
		jp	dirkdoz		; sonst Suchmuster auswerten

;-----------------------------------------------------------------------------
; # CHDIR C=32
;
; Funktion:
; 	- LIST/CHANGE SUBDIRECTORY
; Eingang:
; 	- A = 0 List directories, 
;	- A <> 0 change directory, b=länge, de=dir
; Return:
;-----------------------------------------------------------------------------

CHDIR:
	or	a		;List directories?
	jr	z, chdir0
	ld	a, (BCSV+1)	;Länge des Pfadnamens in b
	or	a		;Wenn Länge Null, dann List directories
	jr	z, chdir0
	cp	9		;Zu lang?
	jr	nc, chdir_error
	ld	c, a		;Pfadnamen nach filename kopieren,
	ld	b, 0		;um ihn mit NULL zu terminieren
	ld	hl, filename
	ex	de, hl
	ldir
	xor	a		;Mit NULL terminieren
	ld	(de), a
	ld	hl, filename
	call	usb__open_read	;Versuche Directory zu öffnen
	cp	CH376_ERR_OPEN_DIR ;Directory vorhanden?
	jr	nz, chdir_error	   ;Nein, Fehler.
	ld	a, (BCSV+1)	   ;Länge nach A, Directory noch in HL
	call	dos__set_path	;Pfad setzen
	jr	nz, chdir_fatal	;Fehler beim Pfad setzen. Vermutlich zu groß.
	call	usb__open_path	;Pfad öffnen, um die Existenz zu prüfen
	ret	z		;Pfad gefunden

chdir_fatal:			;Fataler Fehlerfall, Leider ist der Pfad
	call	usb__root	;dann hier kapputt. Durch '/' ersetzen.
chdir_error:
	scf			;Fehlerflag setzen
	ld	a, 13		;File not found error
	ret

chdir0:				;List directories
	ld	hl, dir_pattern
	ld	de, intln
	ld	bc, 13
	ldir
	jp	dirkdoz
dir_pattern:
	db	11, "????????DIR", 0

;-----------------------------------------------------------------------------
; # CLOAD C=34
;
; Funktion:
; 	- Schreiben einer Datei auf Kassette
; Eingang:
;   A=0 => Dateiname+Typ ist bereits im FCB eingetragen
;   A=1 => Dateiname "Name[.Typ]" muss in CONBU abgelegt sein (als OS-Parameter)
;   A=2 => zuerst Abfrage "Filename:"
;   A+80h -> in IX Zeiger auf Default-Dateityp (3 Char), sonst COM
;   HL = 0 => orig. aadr wird genommen
;   HL <> 0 => aadr
;ret: Cy=1 Fehler
;-----------------------------------------------------------------------------

;SPSV:	EQU	0BH		;REGISTER FUER NUTZERSTACK
;BCSV:	EQU	0DH		;REGISTER FUER BC
;ASV:	EQU	0FH		;REGISTER FUER A
;
cload5:
	;AUSGANG AUS BOS
	POP	HL	; BOSE
	POP	AF
	POP	DE
	POP	HL
	LD	BC,(BCSV)
	LD	SP,(SPSV)
	rst_sbos
	db	14	; CLOAD
	ret

;-----------------------------------------------------------------------------
; # CSAVE  C=35
;
; Funktion:
; 	- Schreiben einer Datei auf Kassette
; Eingang:
;   FCB ist vorbereitet (AADR, EADR, SADR, ...)
;   A=0 => Dateiname+Typ ist bereits im FCB eingetragen
;   A=1 => Dateiname "Name[.Typ]" muss in CONBU abgelegt sein (als OS-Parameter)
;   A=2 => zuerst Abfrage "Filename:"
;   A+80h -> in IX Zeiger auf Default-Dateityp (3 Char), sonst COM
;ret: Cy=1 Fehler
;-----------------------------------------------------------------------------

csave5:
	;AUSGANG AUS BOS
	POP	HL	; BOSE
	POP	AF
	POP	DE
	POP	HL
	LD	BC,(BCSV)
	LD	SP,(SPSV)
	rst_sbos
	db	15	; CSAVE
	ret

;-----------------------------------------------------------------------------
; phys. Treiber

	include	CH376.asm

;-----------------------------------------------------------------------------
; Kommandos

;f. ERA und CD: fuehrende Leerzeichen ueberlesen
SPACE:		LD	A,(DE)
		CP	A, ' '
		RET	NZ
		INC	DE
		JR	SPACE


	include	USBkdo376.asm
	include	dir376.asm

;-----------------------------------------------------------------------------
; RAM:

JPVEK:		ds	34*2

initflg		db	0		; equ	004fh
EBLNR:		db	0		; equ	0050h		; Letzte blocknummer
filesize:	dw	0,0		; Dateigroesse in Byte (DS 4!)

PathName:	ds	41
filename:	ds	8+1+3+1		;Puffer für Filename (Name+Tennz+Typ+00)

;-----------------------------------------------------------------------------


	end
