;-----------------------------------------------------
;
;	UTools Version 1.5 (von M. Leubner)
;
; Hilfsprogramme zur Arbeit mit USB-Sticks unter CP/M
;
;	USB-Direktkommando ausfuehren
;
; Umsetzung auf Z9001-OS: V:Pohlers 20.04.2016 
;-----------------------------------------------------

	cpu	Z80

	section usbkdo
	public	   usbkdo

;	org	300h
;	
;	JP	usbkdo		; eigentlicher Programstart
;	DB	"USB     ",0	; ENV von Z-System
;	DB	0		

;-----------------------------------------------------

;	include	USBINC.Z80	; allgemeine Unterprogramme

CONBU		equ	080h		; interner Zeichenkettenpuffer Kommandozeile
memry		equ	100h		; INTLN Puffer

;-----------------------------------------------------

usbkdo:	ld	HL,CONBU+1
;	ld	a,(CONBU+1)	; Länge Eingabezeile
	ld	b,(HL)		; Merken
;	ld	hl,CONBU+2	; Beginn Eingabezeile (Kommando wurde durch Leerzeichen ersetzt)
	INC 	HL
start0	ld	a,(hl)		; Leerzeichen am Anfang uebergehen
	cp	' '
	jr 	nz,start1
	dec	b
	inc	hl
	jr	start0
start1	

trail3:	push	hl
	push	bc
	ld	a,b		; Länge Parameter
	or	a
	jr	nz, trail3a		;
	ld	(initflg),a	; ohne Parameter -> init
trail3a:	
	call	vdip_init	; Synchronisation
	pop	bc
	pop	hl
	jp	c,uexit

; Extended CMD-Modus aktivieren:

	LD	A,ECS		; Extended CMD-Modus
	CALL	put
	LD	A,CR		; Kommandoabschluss
	CALL	put
ecs1:	CALL	GET		; Ergebnis holen
	jr	c,uexit		; BRK oder TimeOut!
	CP	'>'
	JR	NZ,ecs1		; warten bis Prompt kommt
	CALL	GET
	jr	c,uexit		; BRK oder TimeOut
	CP	CR
	jr	nz,uexit		; kein CR nach Prompt!

; Ausgabe Kommando:

	inc	b		; bei Laenge=0 nur cr!
	jr	ausg2
ausg1:	ld	a,(hl)		; Kommandozeilenrest
	inc	hl
	call	put		; zum VDIP1 senden
ausg2:	djnz	ausg1
ausg4:	ld	a,cr
	call	put		; Kommando abschliessen

; Rueckgabe abholen:

eing0:	ld	hl,memry	; Ablagepuffer
eing1:	call	get		; Daten holen
	jr	c,uexit		; BRK oder TimeOut
	cp	cr		; Zeilenende?
	jr	z,eing2		; ja, testen ob fertig
	ld	(hl),a		; im Speicher merken
	inc	hl
	call	crtx		; und anzeigen
	jr	eing1
	;
eing2:	call	crtx		; cr anzeigen
;
	ld	de,errtab	; Fertigmeldungen testen
	dec	hl		; zurueck zu letztem Zeichen
eing3:	push	hl
eing4:	ld	a,(de)
	dec	de
	or	a
	jr	z,uexit1		; Zeichenkette gefunden -> fertig!
	cp	cr
	jr	z,uexit1		;		- " -
	cp	(hl)
	dec	hl
	jr	z,eing4		; Zeichen stimmt
	pop	hl
eing5:	ld	a,(de)		; in den Vergleichsketten
	dec	de
	or	a		; Trennzeichen zu naechster Meldung suchen
	jr	z,eing3		; und testen
	cp	cr		; erste Meldung erreicht?
	jr	z,eing0		; keine hinterlegte Meldung, also weiter
	jr	eing5

uexit1:	pop	hl
uexit:	call	deinit		; Treiber deaktivieren
	;rst	0
	xor	a
	ret

; Liste der moeglichen Fertigmeldungen:

	db	cr
	db	"Bad Command",0		; Fehlermeldungen
	db	"Command Failed",0
	db	"Disk Full",0
	db	"Invalid",0
	db	"Read Only",0
	db	"File Open",0
	db	"Dir Not Empty",0
	db	"Filename Invalid",0
	db	"No Disk",0		; Prompt - ohne USB-Stick
	db	"D:\\>"			; Prompt - wenn OK
ERRTAB	equ	$-1

;-----------------------------------------------------

;	include	USBINC.Z80	; allgemeine Unterprogramme

;-----------------------------------------------------

;	end

;
;	USB gibt Kommandos direkt zum Vinculum aus.',cr,lf
;	Beispiele:',cr,lf
;	  USB                 - Pruefen ob Laufwerk vorhanden ist',cr,lf
;	  USB FWV             - Anzeige der Vinculum-Firmware-Version',cr,lf
;	  USB IDD             - Anzeige der Laufwerksinformationen',cr,lf
;	  USB DIR             - Anzeige des unsortierten Verzeichnisses',cr,lf
;	  USB CD /            - Geht zum Hauptverzeichnis',cr,lf
;	  USB CD <dirname>    - Wechsel in Unterverzeichnis',cr,lf
;	  USB CD ..           - Verzeichnisebene zurueck',cr,lf
;	  USB MKD <dirname>   - Unterverzeichnis anlegen',cr,lf
;	  USB DLD <dirname>   - leeres Unterverzeichnis loeschen',cr,lf
;	  USB DLF <filename>  - Datei loeschen',cr,lf
;	  USB RD <filename>   - (Text-)Datei anzeigen',cr,lf
;	  USB REN <alt> <neu> - Datei umbenennen',cr,lf
;	

	endsection
	