;-----------------------------------------------------------------------------
; CPM-BOOT-ROM Rossendorf Modul
; disassembliert Volker Pohlers 2004/2006, Teile von A. Schön.
;-----------------------------------------------------------------------------
;
; Der Boot-ROM steckt im einem speziellen ROM-Modul, daß über Reset oder einen 
; Speicherzugriff auf die Adresse 0FC00H aus- und durch einen Speicherzugriff 
; auf die Adresse 0F800H eingeschaltet werden kann.
;
; Der Modulspeicher liegt auf Adresse 0C000H ff.
; 
; Bei Start von CPM wird der gesamte Boot-ROM nach 0400H kopiert und dort
; weiter gestartet. 
; 
; Der Boot-Loader liest von einem an das Rossendorfer Floppy-Modul angeschlossenen
; Floppy-Laufwerk die ERSTE Datei ein.
; 
; Ist der Dateiname @CPMZ9.COM (Bem: Fehler im Programm, s.a. binit7), und 
; steht auf dem zweiten Programmbyte 11H, wird die Datei als gültiges CPM 
; erkannt und auf die Adresse geladen, die im dritten und vierten Programmbyte 
; angegeben ist (Normalerweise 8000H).
; 
; Das Programm wird schließlich auf der Adresse (Ladeadresse + 1600H) gestartet. 
; Das ist der Beginn des BIOS (Normalerweise also 9600H: JMP COLD. Hier muß im 
; BIOS ein Sprung auf eine Adresse im Ladebereich erfolgen, nicht im späteren 
; Arbeitsbereich des BIOS. Das Kopieren des BIOS in den Arbeitsbereich muß also 
; das BIOS selbst übernehmen).
;
; Programmparameter A-F 1/2 4/8; Default A 2 8
; Bootlaufwerk, 1- oder 2-seitig, 40 oder 80 Spuren
; 
;-----------------------------------------------------------------------------
; 191118 Bedeutung+Bezeichnung CFDC und DFDC waren vertauscht

		cpu	z80
		page	0


;BOOTVER 	EQU	'BFD4'		; BFD4.ROM Rossendorf Modul
BOOTVER 	EQU	'BOOTR'		; BOOTR.HEX Rossendorf Dump, vermutlich etwas aktueller als BFD4.ROM
;BOOTVER 	EQU	'URLADER'	; URLADER.COM U.Zander


	IF BOOTVER = 'URLADER'
FDCPORTS	EQU 'ROBOTRON'
	ELSE
FDCPORTS	EQU 'ROSSENDORF'
	ENDIF


		title	"CPM-BOOT-ROM Modul"
		

RAMCOD:		equ	0400h

		org 	RAMCOD		; wird aber in den RAM kopiert

start:		
start0:		jp	cCPM		; CPM-Kommando
					; Parameter A-F	1/2 4/8; Default A 2 8
		db	"BOOT    "

		db	0
		db	0

;-----------------------------------------------------------------------------
; Kommando CPM, Start des Loaders
; Parameter A-F	1/2 4/8; Default A 2 8
;-----------------------------------------------------------------------------

cCPM:		ld	(0FC00h), a	; ROM-Modul ausschalten
		; in	a, (7)		; R/W setzen im RAM-Modul
		out	(7), a		; RAM-Modul R/W

		ld	a, 2		; CPM-Kommando
		ld	(param12), a	; Defaultwert 2
		ld	a, 8
		ld	(param48), a	; Defaultwert 8
		ex	af, af'
					; es wurde vom OS schon GVAL aufgerufen ...
		jr	c, cCPM1	; Cy'=1, wenn alle Parameter abgearbeitet
		call	param		; Kommandozeilen-Parameter auswerten
		ex	af, af'
		jr	c, cCPM1	; Cy'=1, wenn alle Parameter abgearbeitet
		call	param		; Kommandozeilen-Parameter auswerten
		ex	af, af'
		jr	c, cCPM1	; Cy'=1, wenn alle Parameter abgearbeitet
		call	param		; Kommandozeilen-Parameter auswerten

cCPM1:		di
		ld	sp, RAMCOD	; Stackpointer setzen

		;KC Zähler anzapfen (nötig für FDC-Betrieb im nicht-DMA Modus)
		ld	a, 00110111b	; CTC3 programmieren
		out	(83h), a	; kein Interrupt, Vorteiler 256, positive Flanke, ohne Trigger,	Zeitkonstante folgt, Kanal Reset
		ld	a, 0F0h		; Zeitkonstante
		out	(83h), a

		ld	a, 0FBh		; Befehl EI        
		ld	(0EFF8h), a	
		ld	hl, 4DEDh	; Befehl RETI
		ld	(0EFF9h), hl	

		jp	inifd		; Initialisierung U8272

;-----------------------------------------------------------------------------
; Kommandozeilen-Parameter auswerten
;-----------------------------------------------------------------------------
param:		call	0F1EAh		; GVAL,	Parameter aus Eingabezeile holen
		jr	z, param2	; Parameter war	Zahl
		sub	'A'             ; Parameter ist Buchstabe A-F
		ret	c
		cp	5
		ret	nc
		ld	(ftdir+3), a	; wenn A-F (0..5)
		ret
param2:		ret	c		; Ret bei Fehler
		or	a
		ret	z		; Ret bei 0
		cp	3
		jr	nc, param3	; wenn Zahl  > 3
		ld	(param12), a	; Zahl 1..2
		ret
param3:		cp	4		; Test auf 4 oder 8
		jr	z, param4
		cp	8
		ret	nz		; sonst	zurück
param4:		ld	(param48), a	; 4 oder 8
	IF BOOTVER = 'URLADER'
		ret
	ENDIF

;-----------------------------------------------------------------------------
; physischer Disketten-Transfer
;-----------------------------------------------------------------------------

	include biosfdc.asm

	IF BOOTVER = 'BFD4'
                
;???????????????? unnütz und kann entfallen
		db	 21h ; !
		db	 31h ; 1
		db	 3Eh ; >
		db	 7Eh ; ~
		db	0B7h ; À
		db	0C2h ; -
		db	0E2h ; Ô
		db	 2Dh ; -
		db	 21h ; !
		db	0D5h ; i
		db	 40h ; @
		db	 23h ; #
		db	   1 ;
		db	   6 ;
		db	   0 ;
		db	 11h ;
		db	 5Dh ; ]
		db	 3Fh ; ?
		db	 7Eh ; ~
		db	 23h ; #
		db	0FEh ; ¦
		db	 20h ;
		db	0CAh ; -
		db	   4 ;
		db	 2Eh ; .
		db	0FEh ; ¦
		db	   9 ;
		db	0CAh ; -
		db	   4 ;
		db	 2Eh ; .
		db	0B7h ; À
		db	0CAh ; -
		db	   4 ;
		db	 2Eh ; .
		db	0FEh ; ¦
		db	 0Dh ;
		db	0CAh ; -
		db	   4 ;
		db	 2Eh ; .
		db	 12h ;
		db	   0 ;
		db	   0 ;

	ENDIF

;-----------------------------------------------------------------------------
; Initialisierung U8272
;-----------------------------------------------------------------------------

inifd:
	IF BOOTVER = 'URLADER'
		ld	a, 100000b
		out	(FDCZ),	a
		ld	a, 10011b
		out	(FDCZ),	a
	ENDIF
binit1:		ld	b, 0		;INITIALISIERUNG P8272
binit2:		djnz	binit2
		in	a, (CFDC)
		cp	80h
		jr	z, binit4
		in	a, (DFDC)
binit3:		jr	binit1

STAB:		
	IF BOOTVER = 'BFD4'
		
		db  	8Fh 		; 7..4 Schrittratenzeit SRT = 9 ms 3..0 Kopfladezeit HUT = 15 ms
		db 	0FFh		; 7..1 Kopfladezeit 31 ms, 0: 1=nicht DMA Betrieb
	ELSEIF BOOTVER = 'BOOTR'
		db  	0EFh
		db 	0FFh
	ELSEIF BOOTVER = 'URLADER'
		db  	9Fh
		db  	3Fh
	ENDIF

binit4:		ld	hl, stab-1	;PARAMETER LADEN
		ld	bc, 303h	;SPECIFY-COMM 3BYTES
		call	wcom1		;SCHREIBEN COMM
;
		xor	a
		ld	(UNIT), a	; Laufwerk 0 als Standard setzen
		ld	(dFDCZ1), a

		IF BOOTVER = 'URLADER'
		jp	loc_8D0		; reingepatchter Code, s. Listingende
loc_70F:	equ	$		
		ELSE
		call	recal2		; Spur 0 einstellen (2 Versuche)
		ENDIF

		call	sds		; Prüfe	Laufwerk Status
		bit	4, a
		ld	a, 1
		jr	z, binit5
		ld	(dFDCZ1), a	; sonst teste Laufwerk 1
binit5:		ld	(UNIT), a
		call	recal2
		call	sds		; Prüfe	Laufwerk Status
		bit	4, a
		ld	a, (dFDCZ1)
		jr	z, binit6
		
	IF BOOTVER = 'URLADER'
		or	2
	ELSE
		inc	a
	ENDIF
		ld	(dFDCZ1), a
binit6:		
	IF BOOTVER = 'URLADER'
		out	(FDCZ), A	; Motor an
	ENDIF
		ei
		ld	hl, ftdir	; Bereitstellung der Parameter
		ld	de, ft.kom
		ld	bc, 0Bh
		ldir
		call	floppy		; ersten Sektor der Floppy laden
		or	a		; trat ein Fehler auf?
		jp	nz, error	; Fehlermeldung	anzeigen und zurück zum	OS
		;
		ld	de, dskbuf+1	; speichere hier Dateinamen der	ersten
					; geladenen Datei .... sollte @cpmz9 sein
		ld	b, 6		; Länge	des Dateinamens
		ld	hl, acpmz9	; "@CPMZ9"
binit7:		ld	a, (de)		; nächstes Zeichen des Dateinamens
		and	7Fh 		; strip high bit
		cp	(hl)		; und vergleichen
	IF BOOTVER = 'URLADER'
		inc	hl
		inc	de
	ELSE
		;inc hl	 fehlt hier, ist in robotron-variante drin
		;inc de  fehlt hier, so nur 6x Vergleich des 1. Zeichens!!!
	ENDIF
		ld	a, 'N'          ; Fehler "falsches System (Name!)"
		jp	nz, error	; Fehlermeldung	anzeigen und zurück zum	OS
		djnz	binit7

		ld	a, (dskbuf+15)	; Programmlänge als Blockanzahl (im CP/M-directory) 50h -> 10240 Byte
		ld	b, 0
		srl	a		; obere 4 Bits von A nach unten bringen, untere Bits nach B aufsammeln
		rr	b		
		srl	a		
		rr	b		
		srl	a		
		rr	b		
		rl	b		; obere vier bits von B nach unten bringen
		rl	b
		rl	b
		rl	b		
		ld	(blockanz), a	; Programmgröße in 2K-Blöcken
		or	a
		ld	a, 'L'          ; Fehler "falsche Laenge des Systems"
		jp	z, error	; Fehlermeldung	anzeigen und zurück zum	OS
		ld	a, b
		ld	(blockrest), a

;; "ldcpm0" landet auf dem Stack (Push) ... ein pop wird es aber nicht geben. Vielmehr holt
;; eines der folgenden "Ret" Opcode jenen Wert vom Stack und springt an diese
;; Speicheradresse in der Annahme, daß vorher von dort aus ein Call Befehl in jene
;; Subroutine ausgeführt wurde. Eventuell sollte so aufgrund der Kürze des Befehls
;; und der größeren Anzahl nötiger Call-Befehle Speicherplatz (vielleicht auch
;; Zeit) gespart werden.

; Bestimmen von Anfangssektor und Track (Default 2-8)
		ld	hl, ldcpm0
		push	hl
;
		ld	hl, param48	; 4 oder 8
		ld	a, (param12)	; 1 oder 2
		add	a, (hl)
		ld	h, 0
		cp	5
		ld	b, 3
		ret	z		; 1/4 -> B = 3, H = 0
		cp	9
		ld	b, 5
		ret	z		; 1/8 -> B = 5, H = 0
		cp	6
		ret	z		; 2/4 -> B = 5, H = 0
		ld	b, 2
		ld	h, 1		; 2/8 -> B = 2, H = 1
		ret
;
ldcpm0:		ld	a, b
		ld	(ft.sec), a
		ld	l, 0
		ld	(ft.trk), hl
		ld	hl, ft.kom
		ld	a, (ft.sid)
		rrca
		res	7, (hl)
		or	(hl)
		ld	(hl), a
		call	floppy		; Block lesen
		or	a
		jp	nz, error	; Fehlermeldung	anzeigen und zurück zum	OS

; Test auf korrektes @cpmz9
; als 1. Byte muß 11h stehen, dann folgt die Ladeadresse
; (also ursprünglich di und ld de, 8000h)
		ld	a, (dskbuf+1)
		cp	11h
		ld	a, '?'          ; Fehler "kein CPMZ9-System"
		jp	nz, error	; Fehlermeldung	anzeigen und zurück zum	OS
		ld	hl, (dskbuf+2)	; Parameter des Befehls LD DE, xxxx, also die Ladeadresse

		ld	(loadadr), hl
		ex	de, hl

; Auf "dskbuf" wird das CPM Betriebssystem geladen. Mit dabei noch der komplette
; Loader (128 Bytes). Ab "dskbuf+80h" gibt es dann den eigentlichen Programmcode.

		ld	hl, dskbuf+80h
		ld	bc, 380h	; Ein Sektor ist 400h (1024) Bytes groß. Header weg bleiben 380h Bytes.
		ldir			; Kopieren der ersten Bytes des CPMs nach loadadr
		ex	de, hl
		ld	(ft.adr), hl
		ld	hl, blockanz
		dec	(hl)
		ld	a, 'L'
		jp	z, error	; Fehlermeldung	anzeigen und zurück zum	OS
		ld	hl, ft.sec
		inc	(hl)

; Da das CPM noch nicht zur Verfügung steht, müssen die genutzten Sektoren und Tracks auf 
; manuelle Weise ermittelt und ausgelesen werden.

ldcpm1:		ld	hl, ft.sec
		ld	a, 5
		cp	(hl)
		jr	nc, ldcpm3
		ld	(hl), 1
		dec	hl
		ld	a, (param12)	; 1 oder 2
		dec	a
		jr	z, ldcpm2
		xor	(hl)
		ld	(hl), a
		jr	nz, ldcpm3
ldcpm2:		dec	hl
		inc	(hl)
ldcpm3:		ld	a, 6
		ld	hl, ft.sec
		sub	(hl)
		ld	hl, blockanz
		cp	(hl)
		jr	c, ldcpm4
		ld	a, (hl)
ldcpm4:		ld	(ft.anz), a
		ld	hl, ft.kom
		ld	a, (ft.sid)
		rrca
		res	7, (hl)
		or	(hl)
		ld	(hl), a
		call	floppy		; nächsten Sektor lesen
		or	a
		jp	nz, error	; Fehlermeldung	anzeigen und zurück zum	OS
		ld	hl, ft.anz
		ld	b, (hl)
		ld	hl, (ft.adr)
ldcpm5:		ld	de, 400h	; Länge ein Sektor
		add	hl, de
		djnz	ldcpm5
		ld	(ft.adr), hl
		ld	a, (ft.sec)
		ld	hl, ft.anz
		ld	de, ft.sec
		add	a, (hl)
		ex	de, hl
		ld	(hl), a
		ld	a, (blockanz)
		ex	de, hl
		sub	(hl)
		ld	(blockanz), a
		jr	c, ldcpm6
		jr	nz, ldcpm1
ldcpm6:		ld	a, (blockrest)
		or	a
		jr	z, ldcpm8
		bit	7, a
		jr	nz, ldcpm7
		set	7, a
		ld	(blockrest), a
		ld	a, 1
		ld	(blockanz), a
		ld	hl, (ft.adr)
		ld	(blockadr), hl
		ld	hl, dskbuf
		ld	(ft.adr), hl
		jp	ldcpm1
; letzten Sektor kopieren
ldcpm7:		and	7Fh
		ld	c, 0
		rra
		rr	c
		ld	b, a
		ld	hl, dskbuf
		ld	de, (blockadr)
		ldir

ldcpm8:		ld	bc, 1600h	; Offset CCP+BDOS
		ld	hl, (loadadr)	; zu Ladeadr. addieren
		add	hl, bc
		ld	a, (ftdir+3)	; Boot-Laufwerk holen
		jp	(hl)		; und starten des BIOS

		; -- FINI --

;-----------------------------------------------------------------------------
; Fehlermeldung	anzeigen und zurück zum	OS
;-----------------------------------------------------------------------------
error:		push	af
		ld	de, aBootError	; "Boot-Error: "
		ld	c, 9
		call	5		; PRNST	Ausgabe	Zeichenkette
		pop	af
		ld	c, 2
		ld	e, a
		call	5		; CONSO	Ausgabe	Zeichen	E

	IF BOOTVER = 'URLADER'
		in	a, (6)		; RAM-Modul Write Only
		ld	(0F800h), a	; Modul einschalten
	ENDIF
		jp	0		; Systemwarmstart

;-----------------------------------------------------------------------------

	IF BOOTVER = 'URLADER'
	ELSE
;?????????????????
		pop	af
		ld	sp, 0
		jp	0EFF8h		; hier steht EI/RETI (Interruptroutine der CTC)
	ENDIF;

; in loc_0_772 werden die 10 Byte nach ft.kom kopiert
ftdir:		db	39h 		; kommando
		dw	dskbuf 		; Transferadresse
		db	0		; phys. Laufwerksnummer
		db	0 		; track
		db	0 		; side
		db	1 		; Sektorlaenge
		db	3 		; Anzahl der zu uebertragenden Sektoren
		db	1 		; Anzahl der Stepimpulse von Spur zu Spur
		db	1 		; Schrittzeit von Spur zu Spur

		db	 'Z' 		; ???????

aBootError:	db	"Boot-Error: ", 0

acpmz9:		db	"@CPMZ9"

loadadr:	dw	0		; Ziel-Ladeadr. des CPM (also i.allg. 8000h)

blockanz:	db	0		; Größe des CPMs in 2K-Blöcken
blockrest:	db	0		; Anzahl der restl. 128-Byte Blöcke
blockadr:	dw	0		; aktuelle Blockladeadresse

	IF BOOTVER = 'URLADER'
param12:	db	0		; 1 oder 2
param48:	db	0		; 4 oder 8
	ELSE
param12:	db	2		; 1 oder 2
param48:	db	8		; 4 oder 8
	ENDIF


dskbuf:		equ $		; Sektor-Buffer für Floppy, 1K Bereich ! (2K?)

	IF BOOTVER = 'URLADER'
		db	14 dup (0FFh)
loc_8D0:	ld	a, 10h
		ld	(TRCK),	a
		call	seek2
		ld	a, 1
		ld	(UNIT),	a
		call	seek2
		xor	a
		ld	(UNIT),	a
		ld	(TRCK),	a
		call	recal2
		jp	loc_70F
	ENDIF

		end
