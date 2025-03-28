;-----------------------------------------------------
;
;	UTools Version 1.5 (von M. Leubner)
;
; Hilfsprogramme zur Arbeit mit USB-Sticks unter CP/M
;
;	gemeinsam genutzte Unterprogramme
;
; USBINC.Z80 (Include)	    18.01.2008 - 03.12.2014
;-----------------------------------------------------

;Einstellungen fuer nicht-KC-Systeme (Angaben entsprechen Z1013):

BRKT	EQU	0	; Tastaturabfrage bei GET (Abbruch mit Break/ESC) ?
			; 0 = keine Tastaturabfrage
			; 1 = kann bei aufwaendigen BIOS-Routinen Uebertragung
			; sehr stark bremsen!

; Portadressen definieren:
PIOA	EQU	0DCh	; Daten A (Datenport, bidirektional)
PIOB	EQU	0DDh	; Daten B (Steuersignale, Bitbetrieb)
PIOAS	EQU	0DEh	; Steuer A
PIOBS	EQU	0DFh	; Steuer B
FREQ	EQU	2	; CPU-Taktfrequenz in MHz


; CP/M-Vereinbarungen:

CR	EQU	0DH
lf	EQU	0AH
esc	EQU	27h

; Vinculum-Kommandos:

DIR	EQU	01H	; List file(s)
DLF	EQU	07H	; Delete File
WRF	EQU	08H	; Write to File
OPW	EQU	09H	; Open/write
CLF	EQU	0AH	; Close
RDF	EQU	0BH	; Read from File
OPR	EQU	0EH	; Open/read
SCS	EQU	10H	; Short CMD
ECS	EQU	11H	; Extend. CMD
DIRT	EQU	2FH	; List File Date&Time
IPH	EQU	91H	; Binaer-Modus einstellen

; ---------------------------------------------------------

; Synchronisieren mit Vinculum:
;
; PA:	CY=1	Break, TimeOut oder Error
; VR:	AF,HL,BC

synchr:
; PIO Port B initialisieren:
	ld	a,0CFH		; Bitbetrieb
	out	(piobs),a
	ld	a,00110011b	; I/O festlegen
	out	(piobs),a
	ld	a,07H		; DI, Maske folgt nicht
	out	(piobs),a
;	ld	a,0FFH		; kein Bit aktiv
;	out	(piobs),a
	ld	a,0C4H		; #PROG=1, #RESET=1, RD&WR inaktiv
	out	(piob),a

; PIO Port A initialisieren:
	ld	a,8FH		; bidirektional
	out	(pioas),a
	ld	a,07H		; kein INT
	out	(pioas),a
	in	a,(pioa)	; Dummy-Eingabe

; dreistufiges Synchronisieren:

sync:	LD	A,FREQ		; CPU-Taktfrequenz in MHz
	LD	B,A
	LD	hl,0		; Startwert fuer Multiplikation
	ld	de,600		; Faktor fuer Zeitschleife bei CP/M-Version
T3:	add	hl,de		; aufsummieren
	djnz	T3
	ld	d,h
	ld	e,l		; DE = Zaehlerwert fuer Zeitschleife
syn0:	call	condin		; Tastatureingabe vorhanden?
	jr	z,syn1		; nein
	cp	3		; Break?
	jp	z,0
	cp	esc		; ESC?
	jp	z,0

syn1:	in	a,(PIOB)	; Status abfragen
	rrca
	jr	c,syn2		; keine Daten vorhanden
	call	get		; vorhandene Daten abholen
;;ggf
	call	crtx		; und anzeigen, wenn konfiguriert
	jr	sync
	;
syn2:	rrca	
	jr	c,sync		; noch nicht bereit, Daten zu schreiben
	djnz	$		; kurze Zeit warten
	dec	de
	ld	a,d		; Zaehler abwarten
	or	e
	jr	nz,syn0		; nochmals nachschauen...
	in	a,(PIOB)	; Status abfragen
	and	3		; nur Bit 0 und 1 auswerten
	cp	1		; alle Daten abgeholt und bereit zum schreiben?
	jr	nz,sync		; nein !

	ld	a,cr
	call	put		; <cr> muss irgendwie <cr> zurueckgeben
syn3:	call	get
	ret	c		; BRK oder TimeOut
	cp	cr
	jr	nz,syn3

	ld	a,'E'		; E <cr> muss E <cr> zurueckgeben
	call	put
	ld	a,cr
	call	put
syn4:	call	get		; Daten holen
	ret	c		; BRK oder TimeOut
	cp	'E'
	jr	nz,syn4
	call	get
	ret	c		; BRK oder TimeOut
	cp	cr
	jr	nz,syn4

	ld	a,'e'		; e <cr> muss e <cr> zurueckgeben
	call	put
	ld	a,cr
	call	put
syn5:	call	get		; Daten abholen
	ret	c		; BRK oder TimeOut
	cp	'e'
	jr	nz,syn5
	call	get
	ret	c		; BRK oder TimeOut
	cp	cr
	jr	nz,syn5
	ret

; Eingabe von VDIP1 abholen (mit Break und TimeOut):
; PA:	A	Datenbyte
;	CY=1	TimeOut oder Break
; VR:	AF

GET:	push	bc
	ld	bc,0		; Zeitkonstante
get4:
	IF BRKT
	call	condin		; Tastatureingabe vorhanden?
	jr	z,get1		; nein
	cp	3		; Break?
	jr	z,get5
	cp	esc		; ESC?
	jr	z,get5
get1:
	ENDIF
	in	a,(PIOB)	; Status abfragen
	rrca			; Daten vorhanden?
	jr	nc,get3		; ja, abholen
	inc	bc
	ld	a,b
	or	c		; TimeOut?
	jr	nz,get4
get2:	call	eprint
	db	"TimeOut Error",0
	IF BRKT
	jr	get6
	;
get5:	call	eprint
	db	"Break",0
get6:
	ENDIF
	pop	bc
	scf			; Fehler
	ret
	;
get3:	LD	A,0C0H		; RD# aktiv
	OUT	(PIOB),A
	IN	A,(PIOA)	; Daten holen
	LD	C,A
	LD	A,0C4H		; RD# inaktiv
	OUT	(PIOB),A
	LD	A,C
	pop	bc
	or	a		; CY=0 (OK)
	ret

; Ausgabe zu VDIP1 senden:
; PE:	A	Datenbyte
; VR:	-

PUT:	OUT	(PIOA),A	; Daten
	push	af
put1:	IN	A,(PIOB)	; Status abfragen
	RRCA
	RRCA
	JR	C,put1		; nicht bereit, warten!
	LD	A,0CCH
	OUT	(PIOB),A	; WR aktiv
	LD	A,0C4H
	OUT	(PIOB),A	; WR inaktiv
	pop	af
	RET


; Vinculum-Kommando ausfuehren:
;
;PA:	CY=1	Fehler (VDIP1-Fehler oder BRK oder TimeOut)
;VR:	AF

EXECA:	call	put
;
EXEC:	LD	A,CR	; Kommandoabschluss
	CALL	PUT
ex1:	CALL	GET	; Ergebnis holen
	RET	C	; BRK oder TimeOut!
	CP	'>'
	JR	NZ,ERR
	CALL	GET
	RET	C
	CP	CR	; OK, fertig?
	RET	Z
ERR:	CALL	CRTX	; Errorcode anzeigen
	CALL	GET
	JR	C,EX3
	CP	CR	; Ende?
	JR	NZ,ERR
ex3:	CALL	eprint
	db	"-Error",0
	SCF		; Fehler!
	RET

; spezielle CRT-Routine:
;
; PE:	A	Zeichencode
; VR:	-

CRTX:	push	af
	and	7fh		; Bit 7 abschneiden
	cp	20h
	jr	nc,crt1		; darstellbares Zeichen!
	cp	cr
	jr	nz,crt2		; nur CR zulaessig
	call	OUTA
	ld	a,lf		; mit LF ergaenzen
crt1:	call	OUTA
crt2:	pop	af
	ret

;
; Treiberumleitung deaktivieren (vor EXIT):
; V1.4: vorher noch alle anliegenden Daten abholen
;
deinit:	in	a,(PIOB)	; Status abfragen
	rrca
	jr	c,deini2	; keine Daten vorhanden
	call	get		; vorhandene Daten abholen
	jr	deinit
deini2:	djnz	$		; kurze Zeit warten
	in	a,(PIOB)	; Status-Kontrolle
	and	3		; nur Bit 0 und 1 auswerten
	cp	1		; alle Daten abgeholt und bereit zum schreiben?
	jr	nz,deinit	; nein !
	ret

;------------
; Anpassung Z9001

condin		ld	a,(25h)		; keybu
		or	a
		ret

eprint		EX	(SP),HL			;Adresse hinter CALL
		push	af
PRS1:		LD	A,(HL)
		INC	HL
		or	A
		JR	Z, PRS2		;nein
		CALL	CRTX
		jr	PRS1
PRS2:		pop	af
		EX	(SP),HL			;neue Returnadresse
		RET

OUTA:		EQU	0F305H

;-------------

; Short+BIN-Mode
; ret	Cy=error
vdip_binmode:
	LD	A,SCS		; Short CMD-Modus
	CALL	EXECA
	ret	c

	LD	A,IPH		; HEX- bzw. BIN-Modus
	CALL	EXECA
	ret			; Error
