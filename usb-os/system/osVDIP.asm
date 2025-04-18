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

WRITFLG		equ	004eh		; aktuell im Schreib-Modus?
initflg		equ	004fh
fsize:		equ	0050h		; Blockgroesse (128 oder weniger)
filesize:	equ	0051h		; Dateigroesse in Byte (DS 4!)

filename:	equ	0160h		;
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
  		DW	CLOSR 	;CLOSR		;CLOSE LESEN KASSETTE		<14>
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

		;Test auf VDIP-modul
;		in	a,(PIOB)	; an echter hardware kommt z.B. 79h zur�ck
		ld	c,PIOB
		in	l,(c)		; so funktioniert das besser ?
		ld	a,l
		cp	0ffh
		jr	z, novdip

		; VDIP init
		call	vdip_init0
		jp	c,BOSER		; Abbruch bei Fehler

		; neuer Call 5 -Haendler
		ld	hl, CBDOS
		ld	(6), hl

		call	chkwrt0		;28.02.2019 WRITFLG = 0

		xor	a
		ret

novdip:
		ld	de,txt_novdip
		ld	c,9
		call	5
		scf
		ret

;txt_dosinit:
;		db	"VDIP-USB OS V.Pohlers ",DATE,0dh,0ah,0
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
		call	vdip_binmode	; Bin-Mode aktivieren
		call	chkwrt		; letzte Datei noch schlie�en?
		call	prepfn		; neuen Filename aufbereiten

		;Dateigr��e ermitteln
;DIR�file 	01 20 file 0D 		List specified file and size
		call	getfs
		jr	c, OPENRf

		;File er�ffnen
		LD	A,OPR		; Open/read
		call	putfn		; Datei zum lesen oeffnen
		call	exec
		jr	c, OPENRf

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


; Dateigroesse abfragen (get file size)
	; DIR binary input mode DIR�file1.XXX0d -> FILE1.XXX�cccc
getfs:	ld	a,dir		; DIR <dateiname>
	call	putfn		; um Dateigroesse zu ermitteln
	ld	a,cr
	call	put		; Kommando ausfuehren

	call	get		; 1. Zeichen abholen
	ret	c		; Break oder TimeOut
	cp	cr
	jr	nz,getfserr7		; nicht CR
getfs1:	call	get		; naechste Zeichen (Dateiname) abholen
	ret	c		; Break oder TimeOut
	cp	cr		; CR vor Leerzeichen?
	jp	z,getfserr6		; dann Datei nicht vorhanden (CF-Error)
	cp	' '		; Trennzeichen?
	jr	nz,getfs1
	ld	hl,filesize	; Dateigroesse abholen
	ld	b,4		; 4 Byte
getfs2:	call	get
	ret	c		; Break oder TimeOut
	ld	(hl),a
	inc	hl
	djnz	getfs2
getfs3:	call	get
	ret	c
	cp	cr		; Zeilenende erkannt?
	jr	nz,getfs3
	call	get
	ret	c
	cp	'>'		; Prompt?
	jr	nz,getfserr7
	call	get
	ret	c
	cp	cr
	jr	nz,getfserr7
	ret
;
getfserr6	
getfserr7	scf
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
READS:		call	RRAND
		ret	c

		ld	HL,(DMA)
		LD	DE,80h
		ADD	HL,DE
		LD	(DMA),HL
		LD	HL,LBLNR
		INC	(HL)

    		CALL	OSPAC		;AUSGABE LEERZEICHEN

		or	a		;Cy=0
		ret

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

RRAND:		call	vdip_binmode	; Bin-Mode aktivieren

; Daten lesen, Sektor
	ld	hl,filesize	; Dateigroesse
	ld	a,(hl)
	inc	hl
	or	(hl)
	inc	hl
	or	(hl)
	inc	hl
	or	(hl)
	jp	z,rreadc		; 0 => fertig
;
	ld	b,128		; max. Puffergroesse
	ld	hl,filesize+3	; Dateigroesse
	ld	a,(hl)
	or	a
	jr	nz,rread1	; 4. Stelle > 0
	dec	hl
	or	(hl)
	jr	nz,rread1	; 3. Stelle > 0
	dec	hl
	or	(hl)
	jr	nz,rread1	; 2. Stelle > 0
	dec	hl
	ld	a,(hl)
	cp	b
	jr	nc,rread1	; 1. Stelle > 128
	ld	b,a		; der Rest
rread1:	LD	A,RDF		; rread from File
	CALL	put
	LD	A,' '
	CALL	put
	XOR	A
	CALL	put
	XOR	A
	CALL	put
	XOR	A
	CALL	put
	LD	A,B		; Anzahl
	ld	(fsize),a	; merken
	CALL	put
	LD	A,CR
	CALL	put
	ld	c,b		;vp: Anzahl merken
	ld	hl,(dma)	; Datenpuffer
rread2:	CALL	GET		; Daten lesen
	JR	C,rreadc		; Fehler -> Datei trotzdem schliessen
	LD	(HL),A
	INC	HL
	DJNZ	rread2
	ld	(fcb+25), hl	;vp LEADR merken
	call	ex1		; Prompt, cr testen
	JR	C,rreadc		; BRK/TimeOut
;
	ld	hl,filesize	; (restliche) Dateigroesse
	ld	a,(fsize)	; gelesene Blockgroesse
	ld	b,a
	ld	a,(hl)
	sub	b		; -128 (oder der Rest)
	ld	(hl),a
	inc	hl
	ld	a,(hl)
	sbc	a,0
	ld	(hl),a
	inc	hl
	ld	a,(hl)
	sbc	a,0
	ld	(hl),a
	inc	hl
	ld	a,(hl)
	sbc	a,0
	ld	(hl),a
;
	ld	a,(lblnr)
	ld	(blnr),a	; BLNR := LBLNR
;;	ret

;161123
	ld	hl,filesize	; Dateigroesse = 0?
	ld	a,(hl)
	inc	hl
	or	(hl)
	inc	hl
	or	(hl)
	inc	hl
	or	(hl)
	jr	nz, rreadend
; bei Ende Datei schlie�en
	LD	A,CLF		; Close File (USB)
	CALL	putfn		; Datei schliessen
	call	exec
;
	ld	a,0ffh
	ld	(BLNR),A
	ld	a,1
	LD	(ASV),A	
	or	a
	ret
rreadend:
	xor	a
	LD	(ASV),A	
	ret	
	

rreadc:	; bei Fehler und Dateiende
	call	CLOSR1
	LD	A,12		;Lesefehler
	scf
	ret

;-----------------------------------------------------------------------------
; # CLOSR
;04.02.2025
CLOSR:		call	vdip_binmode	; Bin-Mode aktivieren
		call	chkwrt		; letzte Datei noch schlie�en?
CLOSR1:		LD	A,CLF		; Close File (USB)
		CALL	putfn		; Datei schliessen
		call	exec
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
		call	vdip_binmode	; Bin-Mode aktivieren
		call	chkwrt		; letzte Datei noch schlie�en?
		call	prepfn		; neuen Filename aufbereiten
		
		;evtl vorhandene Datei auf USB l�schen
		LD	A,DLF
		call	putfn
		LD	A,CR	; Kommandoabschluss
		CALL	PUT
openw1:		CALL	GET	; Ergebnis holen (Fehler ignorieren)
		CP	CR	; fertig?
		JR	NZ,openw1

		;Open Write
;OPW�file 	09 20 file 0D 		Open a file for writing or create a new file
		LD	A,OPW		; Open Write
		call	putfn
		call	EXEC		;Kdo ausf�hren
		ld	a,13	; file not found error
		ret	c

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
		CALL	NZ, WRITS		;SCHREIBEN BLOCK
		POP	HL
		LD	(DMA),HL	;PUFFERADR. AUF AUSGANGSWERT
		RET

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

; Kommando A gefolgt leerzeichen und filename senden 
putfn:		CALL	PUT
		LD	A,' '
		CALL	PUT
		LD	HL,filename
putfn1:		ld	a,(hl)
		or	a
		ret	z		; ende erreicht
		inc	hl
		CALL	PUT
		jr	putfn1	

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
		call	vdip_binmode	; Bin-Mode aktivieren

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
		ld	hl,(DMA)	; DMA erh�hen
		ld	bc,0080h
		add	hl,bc
		LD	(DMA),HL	;PUFFERADR. UM 128 ERHOEHEN
		LD	HL,BLNR
		LD	A,(HL)
		LD	(ASV),A		;BLOCKNUMMER ZURUECKGEBEN
		INC	(HL)		;BLOCKNUMMER ERHOEHEN
		ret

KARAM:		

;WRF�dword data 	08 20 dword 0D data	Write the number of bytes specified in the 1st parameter to the currently open file
		;
		ld	a,WRF		; Write
		call	PUT
		ld	a,' '		;00
		call	put
		xor	a		;dword
		call	put
		xor	a
		call	put
		xor	a
		call	put
		ld	a,80h		;l�nge = 00000080
		call	put
		ld	a,CR		;0d
		call	put
		ld	HL,(DMA)
		ld	b,80h
karam1		ld	a,(HL)
		call	PUT		; 128 Byte
		inc	hl
		djnz	karam1
		call	ex1		;execute, aber ohne anschlie�endes CR
		ld	a,11
		ret

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

		LD	a,CLF		; Close File (USB)
		call	putfn
		call	exec
;
		call	chkwrt0
		pop	af
		ret

;-----------------------------------------------------------------------------
; vor neuen Dateien pr�fen, ob letzte geschriebene Datei schon geschlossen wurde

chkwrt:		ld	a,(WRITFLG)
		or	a
		ret	z
		;ansonsten letzte Datei schlie�en
		LD	a,CLF		; Close File (USB)
		call	putfn
		call	exec
chkwrt0:	xor	a
		ld	(WRITFLG),a
		ret
;


;-----------------------------------------------------------------------------

	include	VDIP.asm

; VDIP init
		
vdip_init:	ld	a,(initflg)
		or	a
vdip_init1:	call	z,synchr		; Synchronisation
		ret	c			; im Feherfall
		ld	a,42			; sonst erfolgreiche Init merken
		ld	(initflg),a
		ret
vdip_init0:	xor	a		; Z=0
		ld	(initflg),a
		jr	vdip_init1



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

CHDIR:		or	a
		jp	z,cdkdo0	; alle Verzeichnisse anzeigen

; 	- CONBU+4 (1BH) Directory-Name, mit 00-Byte abschlie�en
		ld	a,(BCSV+1)	;REGISTER FUER BC, B := l�nge
		ld	c,a
		ld	b,0		;BC=L�nge
		add	a,3
		ld	(conbu+1),a
;		
		ld	hl,conbu+4
		ld	(hl),' '
		inc	hl
		ex	de,hl
		ldir
		ex	de,hl
		ld	(hl),c		;C=0
		jp	cdkdob1		; Verzeichniswechsel

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
