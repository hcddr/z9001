;------------------------------------------------------------------------------
; Z9001
; (c) V. Pohlers 2016
; letzte �nderung 24.11.2016 13:15:41 RRAND + CLF + R�ckgabewerte
; rem 23.11.2017 bei openw optional auf Schreiben des Blocks verzichten
; rem 28.02.2019 bei prepfn2 statt or a nun cp 0; sonst Fehler bei EDAS
; rem 13.12.2019 bei rrand in LEADR (fcb+24) die letzte Adr+1 hinterlegen (f. HELP)
; rem 23.12.2019 neue BOS-Funktionen
; rem 11.04.2020 Anpassung an OS 1.1, bei BOS nun R�cksprung in OS-CALL5 bei originalen Funktionen
; rem 29.09.2020 xx00-Adressen-Tests erg�nzt

;------------------------------------------------------------------------------
; VDIP-USB unter OS
; DOS/CAOS
; Umbiegen des CALL5 auf Routinen zur Nutzung des USB-Sticks
;------------------------------------------------------------------------------

		cpu	z80

CONBU		EQU	0080H		;default buffer


;-----------------------------------------------------------------------------
; neuer BOS-Call
;-----------------------------------------------------------------------------

BOS		equ	0F314h		; orig. Call 5
BOSE		equ	0f345h
BOSER		equ	0f5deh		;UNERLAUBTER SYSTEMRUF
OSPAC:		EQU	0F310H

SPSV:		EQU	000BH		;REGISTER FUER NUTZERSTACK
BCSV:		EQU	000DH		;REGISTER FUER BC
ASV:		EQU	000FH		;REGISTER FUER A
DMA		equ	001Bh
FCB		equ	005Ch
BLNR		equ	FCB+15
LBLNR		equ	FCB+16
;SBY		equ	FCB+23		;Schutzbyte (wird ignoriert)
NFHD		equ	FCB+24		;'N' - bei open kein Block lesen/schreiben
LEADR		equ	FCB+25		;letzte gef�llte Adr+1

MAPPI:		EQU	0F000H-64	;SYSTEMBYTE


; RAM

initflg		equ	004fh
EBLNR:		equ	0050h		; Letzte blocknummer
filesize:	equ	0051h		; Dateigroesse in Byte (DS 4!)

PathName:	equ	0153H
filename:	equ	PathName+41
		;ds	8+1+3+1		;Puffer f�r Filename (Name+Tennz+Typ+00)



;		org	0c200h

;start		jp	initdos
;		db	"DOS     ",0
;		jp	exitdos
;		db	"CAOS    ",0
;		jp	usbkdo
;		db	"USB     ",0
;		jp	dirkdo
;		db	"DIR     ",0
;		jp	cdkdo
;		db	"CD      ",0
;		db	0

;-----------------------------------------------------------------------------
; Hinweis:  die lokalen Prozeduren d�rfen NICHT auf einer xx00Adresse liegen (wg cp 0)

JPVEK:		DW	0 	;INIT		;KALTSTART/RESET		<00>
  		DW	0 	;CONSI		;EINGABE VON CONST		<01>
  		DW	0 	;CONSO		;AUSGABE ZU CONST		<02>
  		DW	0 	;READI		;EINGABE VON READER		<03>
  		DW	0 	;PUNO		;AUSGABE ZU PUNCH		<04>
  		DW	0 	;LISTO		;AUSGABE ZU LIST		<05>
  		DW	0 	;GETST		;ABFRAGE SPIELHEBEL		<06>
  		DW	0 	;GETIO		;ABFRAGE I/O-BYTE		<07>
  		DW	0 	;SETIO		;SETZEN I/O-BYTE		<08>
  		DW	0 	;PRNST		;AUSGABE ZEICHENKETTE		<09>
  		DW	0 	;RCONB		;EINGABE ZEICHENKETTE		<10>
  		DW	0 	;CSTS		;STATUS CONST			<11>
  		DW	0 	;RETVN		;ABFRAGEVERSIONSNUMMER		<12>
  		DW	OPENR		;OPEN LESEN KASSETTE		<13>
  		DW	0	;CLOSR		;CLOSE LESEN KASSETTE		<14>
  		DW	OPENW		;OPEN SCHREIBEN KASSETTE	<15>
  		DW	CLOSW		;CLOSE SCHREIBEN KASSETTE	<16>
  		DW	0 	;GETCU		;ABFRAGE LOG. CURSORADR.	<17>
  		DW	0 	;SETCU		;SETZEN LOG. CURSORADR.		<18>
;  		DW	0 	;BOSER		;NICHT GENUTZT
 		DW 	DIRS 		;LIST FILES 			<19>
  		DW	READS		;BLOCKLESEN SEQUENTIELL		<20>
  		DW	WRITS		;BLOCKSCHREIBEN SEQUENTIELL	<21>
  		DW	0 	;SETTI		;STELLEN UHRZEIT		<22>
  		DW	0 	;GETTI		;ABFRAGE UHRZEIT		<23>
  		DW	0 	;PRITI		;AUSGABE UHRZEIT		<24>
  		DW	0 	;INITA		;INITIALISIERUNG TASTATUR	<25>
  		DW	0 	;SETDM		;SETZEN ADR. KASSETTENPUFF.	<26>
  		DW	0 	;GETM		;LOG. SPEICHERTEST		<27>
  		DW	0 	;SETM		;SETZEN SPEICHERKONFIG.		<28>
  		DW	0 	;DCU		;LOESCHEN CURSOR		<29>
  		DW	0 	;SCU		;ANZEIGE CURSOR			<30>
  		DW	0 	;COEXT		;VORVERARBEITEN ZEICHENKET.	<31>
;  		DW	0 	;BOSER		;NICHT GENUTZT
 		DW 	CHDIR 		;LIST/CHANGE SUBDIRECTORY 	<32>
  		DW	RRAND		;BLOCKLESEN			<33>
; -> implementiert in ubos2.asm
; (aufgeteilt wg. Speicherbelegung)
		if p_zmon=1
		DW	CLOAD5		;LADEN				<34>
		DW	CSAVE5		;SPEICHERN			<35>
		DW	KDOPAR		;Parameter aufbereiten		<36>
		DW	OUTHX		;Ausgabe (E) hexa		<37>
		DW	OUTDE		;Ausgabe (DE) hexa		<38>
		endif
JPVEKE:

;-----------------------------------------------------------------------------
; Tests
; die lokalen Prozeduren d�rfen NICHT auf einer xx00Adresse liegen

test00		macro	lbl		
		if lbl # 100h = 0 
			error "lbl liegt auf xx00-Adresse \{lbl}"
		endif
		endm	
		
		if mompass>1

		test00 OPENR 
		test00 OPENW 
		test00 CLOSW 
		test00 DIRS 
		test00 READS 
		test00 WRITS 
		test00 CHDIR 
		test00 RRAND 
		if p_zmon=1
		test00 CLOAD5
		test00 CSAVE5
		test00 KDOPAR
		test00 OUTHX 
		test00 OUTDE 
		endif
		endif
;-----------------------------------------------------------------------------
; CAOS
;-----------------------------------------------------------------------------

exitdos:	ld	hl, BOS
		ld	(6), hl

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
;		ld	de,txt_dosinit
;		ld	c,9
;		call	5

		; CH376 init
		call	usb__reset
		call	usb__ready
		jp	nz, no_ch376
		;; Test auf g�ltigen Pfad
		call	usb__open_path
		jr	z, init_path_ok
		;; Wenn ung�ltig, mit root initialisieren
		call	usb__root
init_path_ok:	
		; neuer Call 5 -Haendler
		ld	hl, CBDOS
		ld	(6), hl
	
		xor	a
		ret

no_ch376:
		ld	de,txt_no_ch376
		ld	c,9
		call	5
		scf
		ret

;txt_dosinit:
;		db	"VDIP-USB OS V.Pohlers ",DATE,0dh,0ah,0
txt_no_ch376:
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
		LD	A,(JPVEKE-JPVEK)/2	;Anz. Systemrufe 
		CP	A, C
		JP	C, BOSER	;UNERLAUBTER SYSTEMRUF
		LD	B,0
		LD	HL,JPVEK	;ADRESSTABELLE DER SYSTEMRUFE
		ADD	HL,BC
		ADD	HL,BC
		LD	A,(HL)
		
		or	a		; keine eigene Routine
		jp	z, 0f333h	; weiter im BOS des OS
		
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
; 	- bei Namensgleichheit �bernehmen der gelesenen Dateiparameter in den FCB (siehe 2.3.4.)
; 	- Ausgabe eines Leerzeichens zum aktuellen CONST-Ger�t
; 	- Kassettenpuffer ist die aktuelle DMA-Adresse (siehe Ruf 26)
; Eingang:
; 	- Name und Typ der gew�nschten Datei im FCB
; 	- DMA (1BH) Adresse Kassettenpuffer f�r Block 0
; Return:
; 	- aktualisierte Dateiparameter im FCB (Anfangsadresse, Endadresse, Startadresse, Schutzbyte)
; 	- LBLNR (6CH) n�chste zu lesende Blocknummer (1)
; 	- CY Fehlerstatus
;-----------------------------------------------------------------------------
OPENR:
	call	usb__close_file	; letzte Datei noch schlie�en?
	call	prepfn
	ld	hl, filename
	call	usb__open_read
	jr	nz, OPENRf

	call	usb__get_file_size	; Dateigr��e nach DEHL und Nummer des letzten Blocks berechnen
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
	cp	'N'		; Letzen block um eins erh�hen
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
		LDIR			; Parameter in FCB �bernehmen
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
; 	- Ausgabe eines Leerzeichens zum aktuellen CONST-Ger�t
; Eingang:
; 	- LBLNR (6CH) zu lesende Blocknummer
; 	- DMA (1BH) Adresse, auf welcher der Block abgelegt wird
; Return:
; 	- A Kennzeichen f�r letzten Block der Datei (EOF)
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
;	- keine Ver�nderung von LBLNR und DMA (vgl. Systemruf 20)
;Eingang:
;	- LBLNR (6CH) zu lesende Blocknummer
;	- DMA (1BH) Adresse auf welcher der Block abgelegt wird
;Return:
;	- A Kennzeichen f�r letzten Block der Datei (EOF)
;		kein EOF 0
;		EOF 1
;	- CY Fehlerstatus
;	- BLNR (6BH) die wirklich gelesene Blocknummer (auch im Fehlerfall)
;Hinweis:
;	- wird der letzte Block erkannt, kehrt das Programm mit A=1 (EOF) zur�ck
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
; 	- BLNR Blocknummer des n�chsten Blocks (1)
; 	- CY Fehlerstatus
;
;-----------------------------------------------------------------------------
OPENW:
	call	usb__close_file	; letzte Datei noch schlie�en?
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

	include CH376.asm

; neue BDOS-Funktionen

; 		DW 	DIRS 		;LIST FILES 			<19>
; 		DW 	CHDIR 		;LIST/CHANGE SUBDIRECTORY 	<32>
;;		DW	CLOAD		;LADEN				<34>
;;		DW	CSAVE		;SPEICHERN			<35>

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
		;Suchstring nach INTLN kopieren, L�ngenbyte eintragen	
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
;	- A <> 0 change directory, b=l�nge, de=dir
; Return:
;-----------------------------------------------------------------------------

CHDIR:
	or	a		;List directories?
	jr	z, chdir0
	ld	a, (BCSV+1)	;L�nge des Pfadnamens in b
	or	a		;Wenn L�nge Null, dann List directories
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
	call	usb__open_read	;Versuche Directory zu �ffnen
	cp	CH376_ERR_OPEN_DIR ;Directory vorhanden?
	jr	nz, chdir_error	   ;Nein, Fehler.
	ld	a, (BCSV+1)	   ;L�nge nach A, Directory noch in HL
	call	dos__set_path	;Pfad setzen
	jr	nz, chdir_fatal	;Fehler beim Pfad setzen. Vermutlich zu gro�.
	call	usb__open_path	;Pfad �ffnen, um die Existenz zu pr�fen
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

	if p_zmon

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
	jp	cload


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
	jp	csave

;-----------------------------------------------------------------------------
; # KDOPAR C=36
;
; Funktion:
; 	- bis zu 4 Hex-Zahlen-Parameter aufbereiten
; Eingang:
; 	- bis zu 4 Parameter (Hex-Zahlen) im Eingabepuffer CONBU abgelegt
;       - Vornull nicht n�tig, es gelten die letzten 4 Stellen eines Parameters
; 	- oder ':', dann gelten die letzten Parameter erneut
; Return:
;	ARG1:	in 0046H 
;	ARG2:	in 0048H 
;	ARG3:	in 004AH 
;	ARG4:	in 004CH 
;-----------------------------------------------------------------------------

;-----------------------------------------------------------------------------
; # OUTDE C=38
;
; Funktion:
; 	- Ausgabe (DE) hexa
; Eingang:
; 	- DE
;-----------------------------------------------------------------------------

;
OUTDE:		LD	A,D
		CALL	OUTHX

;-----------------------------------------------------------------------------
; # OUTHX C=37
;
; Funktion:
; 	- Ausgabe (E) hexa
; Eingang:
; 	- E
;-----------------------------------------------------------------------------

OUTE:		LD	A,E
		jp	OUTHX

	endif
		
;-----------------------------------------------------------------------------
;	end
