;------------------------------------------------------------------------------
; Z9001
; (c) V. Pohlers 2016
; letzte Änderung 24.11.2016 13:15:41 RRAND + CLF + Rückgabewerte
; rem 23.11.2017 bei openw optional auf Schreiben des Blocks verzichten
; rem 28.02.2019 bei prepfn2 statt or a nun cp 0; sonst Fehler bei EDAS
; 02.03.2019 Missbrauch von AUR2 für ON_COLD
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
;NFHD		equ	FCB+24		;'N' - bei open kein Block lesen/schreiben

MAPPI:		EQU	0F000H-64	;SYSTEMBYTE

AUR2		equ	0EFD7h		; Eigentlich Adresse UR2-Treiber für READER
					; hier f. Re-Init ON_COLD genutzt


;		org	0b800h
		org	0b600h

start		jp	initdos
		db	"DOS     ",0
		jp	exitdos
		db	"CAOS    ",0
		jp	usbkdo
		db	"USB     ",0
		jp	dirkdo
		db	"DDIR    ",0
		jp	cdkdo
		db	"CD      ",0
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

		;Test auf VDIP-modul
;		in	a,(PIOB)	; an echter hardware kommt z.B. 79h zurück
		ld	c,PIOB
		in	a,(c)		; so funktioniert das besser
		cp	0ffh
		jr	z, novdip

		; VDIP init
		call	vdip_init0
		jp	c,BOSER		; Abbruch bei Fehler

initdos1
		; jpvek für Call5-Haendler kopieren und ändern
		ld	hl,0f045h
		ld	de,jpvek
		ld	bc,33*2
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
		db	"VDIP-USB OS V.Pohlers ",DATE,0dh,0ah,0
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
		call	vdip_binmode	; Bin-Mode aktivieren
		call	chkwrt		; letzte Datei noch schließen?
		call	prepfn		; neuen Filename aufbereiten

		;Dateigröße ermitteln
;DIR·file 	01 20 file 0D 		List specified file and size
		call	getfs
		jr	c, OPENRf

		;File eröffnen
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
		LDIR			; Parameter in FCB übernehmen
		xor	a		; kein Fehler
		ret
;
OPENRf		ld	a,13		; file not found error
		scf
		ret


; Dateigroesse abfragen (get file size)
	; DIR binary input mode DIR·file1.XXX0d -> FILE1.XXX·cccc
getfs:	ld	a,dir		; DIR <dateiname>
	call	putfn		; um Dateigroesse zu ermitteln
	ld	a,cr
	call	put		; Kommando ausfuehren

	call	get		; 1. Zeichen abholen
	ret	c		; Break oder TimeOut
	cp	cr
	jp	nz,getfserr7		; nicht CR
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
	jp	nz,getfserr7
	call	get
	ret	c
	cp	cr
	jp	nz,getfserr7
	ret
;
getfserr6	
getfserr7	scf
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
	ld	hl,(dma)	; Datenpuffer
rread2:	CALL	GET		; Daten lesen
	JR	C,rreadc		; Fehler -> Datei trotzdem schliessen
	LD	(HL),A
	INC	HL
	DJNZ	rread2
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
; bei Ende Datei schließen
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
	LD	A,CLF		; Close File (USB)
	CALL	putfn		; Datei schliessen
	call	exec
	LD	A,12		;Lesefehler
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
		call	vdip_binmode	; Bin-Mode aktivieren
		call	chkwrt		; letzte Datei noch schließen?
		call	prepfn		; neuen Filename aufbereiten
		
		;evtl vorhandene Datei auf USB löschen
		LD	A,DLF
		call	putfn
		LD	A,CR	; Kommandoabschluss
		CALL	PUT
openw1:		CALL	GET	; Ergebnis holen (Fehler ignorieren)
		CP	CR	; fertig?
		JR	NZ,openw1

		;Open Write
;OPW·file 	09 20 file 0D 		Open a file for writing or create a new file
		LD	A,OPW		; Open Write
		call	putfn
		call	EXEC		;Kdo ausführen
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
		ld	hl,(DMA)	; DMA erhöhen
		ld	bc,0080h
		add	hl,bc
		LD	(DMA),HL	;PUFFERADR. UM 128 ERHOEHEN
		LD	HL,BLNR
		LD	A,(HL)
		LD	(ASV),A		;BLOCKNUMMER ZURUECKGEBEN
		INC	(HL)		;BLOCKNUMMER ERHOEHEN
		ret

KARAM:		

;WRF·dworddata 	08 20 dword 0D data	Write the number of bytes specified in the 1st parameter to the currently open file
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
		ld	a,80h		;länge = 00000080
		call	put
		ld	a,CR		;0d
		call	put
		ld	HL,(DMA)
		ld	b,80h
karam1		ld	a,(HL)
		call	PUT		; 128 Byte
		inc	hl
		djnz	karam1
		call	ex1		;execute, aber ohne anschließendes CR
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
; vor neuen Dateien prüfen, ob letzte geschriebene Datei schon geschlossen wurde

chkwrt:		ld	a,(WRITFLG)
		or	a
		ret	z
		;ansonsten letzte Datei schließen
		LD	a,CLF		; Close File (USB)
		call	putfn
		call	exec
chkwrt0:	xor	a
		ld	(WRITFLG),a
		ret
WRITFLG		db	0		; aktuell im Schreib-Modus?

;-----------------------------------------------------------------------------

filename:	ds	8+1+3+1		;Puffer für Filename (Name+Tennz+Typ+00)
fsize:		db	0		; Blockgroesse (128 oder weniger)
filesize:	dw	0,0		; Dateigroesse in Byte

JPVEK:		ds	34*2

	
;-----------------------------------------------------------------------------

	include	diskos/usbinc.asm

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

initflg		db	0


;-----------------------------------------------------------------------------
	include	diskos/usbkdo.asm

;-----------------------------------------------------------------------------
;alt
;;dirkdo:		ld	hl, txt_dir
;;		ld	de, CONBU+1
;;		ld	bc, txt_dirend - txt_dir
;;		ldir
;;		jp	usbkdo
;;
;;txt_dir		db	3,"DIR",0
;;txt_dirend

;05.03.2019 neue Kommandos
;dirkdo:
;cdkdo:

	include	diskos/usbdir.asm

;-----------------------------------------------------------------------------
	end
