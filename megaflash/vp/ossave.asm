; File Name   :	C:\user\hobby\rechner\Z9001\dev\os-save\OS-SAVE-Tabelle.KCC
; Format      :	Binary file
; Base Address:	0000h Range: 0F89h - 1379h Loaded length: 03F0h

;------------------------------------------------------------------------------
; OS-SAVE
; rekompilierbare Version V.Pohlers 10.01.2012 
; ohne die OS-Erweiterung
; 19.02.2012 kleine Fehler behoben (Block-Counter bei Block 0; DMA Reset bei Verfiy)
;------------------------------------------------------------------------------

		cpu	z80

; Systemzellen

DMA		equ	001Bh		; Zeiger auf Puffer für Kassetten-E/A
KEYBU		equ	0025h		; Tastaturpuffer
EOR		equ	0036h		; Zeiger auf letzte für Anwender freie Adresse
PARBU		equ	0040h		; Hilfszelle zur Paramterpufferung
FCB		equ	005Ch		; Dateikontrollblock
FNAME		equ	005Ch		; Dateiname 8 Zeichen
FTYP		equ	0064h		; Dateityp 3 Zeichen
LBLNR		equ	006Ch		; gesuchte Blocknummer bei Lesen
AADR		equ	006Dh		; Dateianfangsadresse
EADR		equ	006Fh		; Dateiendeadresse
SADR		equ	0071h		; Startadresse, wenn Datei ein Maschinencodeprogramm ist
SBY		equ	0073h		; Schutzbyte. 0 nicht geschützt, 1 geschützt
CONBU		equ	0080h		; CCP-Eingabepuffer und Standardpuffer für Kassetten-E/A
INTLN		equ	0100h		; interner Zeichenkettenpuffer

GVAL		equ	0F1EAh
CPROM		equ	0F28Eh
ERINP		equ	0F5E2h
ERPAR		equ	0F5E6h
MOV		equ	0F588h
GETMS		equ	0F35Ch
REA1		equ	0F5A6h
FORMS		equ	0F836h
OSPAC		equ	0F310h
DECO0		equ	0FD33h


		org	0a000h

;------------------------------------------------------------------------------
; Kommandorahmen f. OS
;------------------------------------------------------------------------------

		jp	save
		db "OS-SAVE ",0
exkdo:		db    0

;------------------------------------------------------------------------------
; SAVE filename[.filetyp] aadr eadr [sadr]
;------------------------------------------------------------------------------


;-----------------------------
; Parameter bearbeiten
;-----------------------------

save:		ex	af, af'
		ld	hl, ERPAR
		push	hl
		ret	c
; Einlesen Name
		call	GVALH		; Parameter holen
		ret	z		; Fehler, wenn Parameter Zahl ist
		ex	af, af'
		ret	c		; Fehler, wenn kein Parameter folgt
		ld	a, (INTLN)	; Länges des Parameters
		or	a
		ret	z		; Fehler, wenn Parameter leer
		cp	9
		ret	nc		; Fehler, wenn Parameter länger als 8 Zeichen
		ld	de, FNAME	; sonst 8 Zeichen als Filename
		ld	a, 8
		call	MOV		; aus Zwischenpuffer kopieren
; Einlesen Dateityp
		ld	a, c		; C=Trennzeichen
		cp	'.'
		jr	z, sa1		; wenn Dateityp folgt
		ld	hl, 4F43h	; "COM"
		ld	(FTYP),	hl
		ld	a, 'M'
		ld	(FTYP+2), a	;sonst Standard-Typ "COM" eintragen
		or	a
		jr	sa2

sa1:		call	GVALH		; Parameter holen
		ret	z		; Fehler, wenn Parameter Zahl ist
		ex	af, af'
		ret	c		; Fehler, wenn kein Parameter folgt
		ld	a, 3
		cp	b		; B = Länge des Parameters
		ret	c		; wenn mehr als 3 Zeichen
		ld	de, FTYP	; sonst als Dateityp
		call	MOV		; aus Zwischenpuffer kopieren
; Einlesen Anfangsadresse
sa2:		call	GVALH		; Parameter holen
		ret	nz		; Fehler, wenn Parameter keine Hexzahl ist
		ret	c		; Fehler im Parameter
		ex	af, af'
		ret	c		; Fehler, wenn kein Parameter folgt
		ld	(AADR),	de
; Einlesen Endadresse
		call	GVALH		; Parameter holen
		ret	nz		; Fehler, wenn Parameter keine Hexzahl ist
		ret	c		; Fehler im Parameter
		ld	(EADR),	de
		ex	af, af'
		jr	nc, sa3		; wenn noch Parameter folgt
; Einlesen Startadresse
		ld	de, (AADR)	; sonst Startadresse = Anfangsadresse
		jr	sa4

sa3:		call	GVALH		; Parameter holen
		ret	nz		; Fehler, wenn Parameter keine Hexzahl ist
		ret	c		; Fehler im Parameter
		ex	af, af'
		ret	nc		; Fehler, wenn noch Parameter folgt

sa4:		ld	(SADR),	de
;
		pop	hl		; Fehlerproc vom Stack nehmen

; Anfangsadresse < Endadresse?
		ld	hl, (EADR)
		ld	de, (AADR)
		or	a
		sbc	hl, de		; Anfangsadresse < Endadresse?
		jp	c, ERINP	; sonst Fehler error 2
;
;-----------------------------
; Ausgeben auf Band
;-----------------------------
;
		ld	hl, nokey	; Returnadresse auf Stack
		push	hl		; bei Fehler/Abbruch Tastaturpuffer löschen
;
		call	OPENW		; Open Write
		;vp
		ld	(puf1),	a	; Nummer des geschriebenen Blockes
		ret	c		; bei Fehler
		call	outblk		; Anzeige Block geschrieben
		jp	c, saa2		; Abbruch bei STOP-Taste
;
		ex	de, hl		; DE ist Anfangsadresse
		ld	(DMA), hl	; DMA := Anfangsadresse
;
sav2:		ld	hl, (DMA)	; aktuelle Position
		ld	de, 7Fh		;
		add	hl, de
		ld	de, (EADR)
		sbc	hl, de		; Pos+7Fh < EADR ? (Cy ist 0)
		jr	nc, sav1	; nein -> letzter Block
		call	WRITS		; sonst Block schreiben
		ld	(puf1),	a	; Nummer des geschriebenen Blockes
		ret	c		; wenn Fehler
		call	outblk		; Anzeige Block geschrieben
		jp	c, saa3		; Abbruch bei STOP-Taste
		jr	sav2		; nächsten Block lesen
;
sav1:		call	CLOSW		; Endeblock schreiben
		ret	c		; bei Fehler
		ld	hl, puf1	; Nummer des geschriebenen Blockes
		inc	(hl)		; für Endblock um 1 erhöhen
;
		ld	de, aVerifyYN	; "VERIFY ((Y)/N)?:"
		call	PRNST
		call	GETMS		; Eingabe String in Monitorpuffer
		jp	c, saa3		; Abbruch bei STOP-Taste
		ld	a, (CONBU+2)
		cp	'N'
		jp	z, saa4		; wenn kein Verify
;
;-----------------------------
; Verify
;-----------------------------
;
		ld	de, aRewind	; "REWIND <--"
		call	PRNST
		call	GETMS		; Eingabe String in Monitorpuffer
		jp	c, saa3		; Abbruch bei STOP-Taste
; ersten Block lesen
sav4:		;vp
		ld	hl, CONBU
		ld	(DMA), hl

		call	OPENR		; Open Read
		jr	c, sav4a	; bei Fehler
		call	stop
		jr	nc, sav5	; kein STOP? dann weiterlesen
		jr	saa3		; Abbruch bei STOP-Taste
; Fehler (z.B. file not found)
sav4a:		or	a		; Fehlercode = 0 ?
		jr	z, saa3		; Abbruch bei STOP-Taste
		call	REA1		; warten auf Bedienerhandlung
		jr	c, saa3		; Abbruch bei STOP-Taste
		jr	sav4

; die nächsten Blöcke lesen
sav8:		call	READS		; Block lesen
		jr	nc, sav7	; wenn kein Fehler
		call	REA1		; sonst warten auf Bedienerhandlung
		jr	c, saa6		; bei STOP-Taste
		jr	sav8
; Test auf Abbruch
sav7:		ld	l, a		; A sichern
		call	stop		; STOP?
		jr	c, saa6		; Abbruch bei STOP-Taste
		ld	a, l		; A restaurieren
;
sav5:		ld	hl, CONBU
		ld	(DMA), hl
		or	a		; EOF erreicht
		jr	z, sav8		; nein -> weiterlesen
; Verify Ende		
		ld	de, aSaveComplete 	; "SAVE COMPLETE"
saa7:		call	PRNST
		ld	a, 14h		; Farbe
		call	CONSO
		ld	a, 4		; blau
		call	CONSO
		ld	a, (puf1)
		call	outhx		; Ausgabe A hexadezimal
		ld	de, aRecordSWritten 	; "	RECORD(S) WRITTEN"
		call	PRNST
		ld	a, 14h		; Farbe
		call	CONSO
		ld	a, 4		; blau
		call	CONSO
		ld	a, (LBLNR)
		dec	a
		call	outhx		; Ausgabe A hexadezimal
		ld	de, aRecordSChecked 	; "	RECORD(S) CHECKED"
		jp	PRNST

; Abbruch mit STOP-Taste bei OPENW
saa2:		ld	de, aBreakByStopKey 	; "BREAK BY "STOP"-KEY!"
		call	PRNST
		ld	de, aNo			; "NO"
		call	PRNST

saa8:		ld	de, aRecordSWritten 	; "	RECORD(S) WRITTEN"
		call	PRNST
		ld	de, aNo			; "NO"
		call	PRNST
		ld	de, aRecordSChecked 	; "	RECORD(S) CHECKED"
		jp	PRNST

; Abbruch mit STOP-Taste
saa3:		ld	de, aBreakByStopKey 	; "BREAK BY "STOP"-KEY!"
		call	PRNST
;
;-----------------------------
; Abschluss
;-----------------------------
;
saa4:		ld	a, 14h		; Farbe
		call	CONSO
		ld	a, 4		; blau
		call	CONSO
		ld	a, (puf1)
		call	outhx		; Ausgabe A hexadezimal
		jr	saa8

saa6:		ld	de, aBreakByStopKey ; "BREAK BY "STOP"-KEY!"
		jr	saa7

;-----------------------------

aSaveComplete:	db 0Ah,0Dh
		db 14h,1
		db "SAVE COMPLETE"
		db 0Ah,0Dh,0Ah,0
aRecordSWritten:db 14h,2," RECORD(S) WRITTEN"
		db 0Ah,0Dh,0
aRecordSChecked:db 14h,2," RECORD(S) CHECKED"
		db 0Ah,0Dh,0Ah,0
aVerifyYN:	db 0Ah,0Dh
		db "VERIFY ((Y)/N)?:",0
aRewind:	db 0Ah,0Dh
		db "REWIND "
		db 14h,1
		db "<--"
		db 14h,2
		db ' ',0
aBreakByStopKey:db 0Ah,0Dh
		db 14h,1,"BREAK BY ",14h,4,"\"STOP\"",14h,1,"-KEY!",14h,2
		db 0Ah, 0Dh,0Dh,0Ah,0
aNo:		db 14h,4,"NO",14h,2,0

;------------------------------------------------------------------------------
; Parametereingabe Hexzahl
;------------------------------------------------------------------------------

GVALH:		call	GVAL		; Parameter holen
		ret	nz		; Parameter war keine Zahl
		push	hl		; Adresse des nächsten Zeichens in CONBU
		push	bc		; Länge des Parameters + Trennzeichen
		ld	de, INTLN
		call	hex3
		pop	bc
		pop	hl
		jr	c, gvalerr	; wenn Fehler
		cp	a		; Flags setzen
		ret
; Eingabefehler
gvalerr:	cp	a		; Z=0
		jp	ERINP		; error 2
;
hex3:		ld	a, (de)
		or	a
		scf			; Cy=1 Fehler
		ret	z		; wenn kein Parameter
		ld	a, 4
		call	FORMS		; Formatieren String auf Länge A
		ret	c		; wenn Fehler
;
		ld	hl, puf2
		ld	b, 2
hex2:		call	hex4		; Test auf Hex-Ziffer
		ret	c		; wenn Fehler
		ld	(hl), a
		call	hex4		; Test auf Hex-Ziffer
		ret	c		; wenn Fehler
		rld
		dec	hl
		djnz	hex2
		ld	de, (puf1)
		ret
;
; Test auf Hex-Ziffer
hex4:		ld	a, (de)		; Zeichen holen
		inc	de
		cp	30h 	; '0'
		ret	c		; Cy=1, wenn Zeichen < '0'
		cp	3Ah 	; '9'+1
		ccf
		ret	nc		; Cy=0, wenn Zeichen Ziffer 0..9
		and	0DFh		; Wandlung in Großbuchstaben
		sub	7		; 'F'->3Fh
		cp	40h 	; '@'
		ccf
		ret			; Cy=1, wenn kein Buchstabe A..F

;------------------------------------------------------------------------------
; Ausgabe A hexadezimal
;------------------------------------------------------------------------------

outhx:		push	af
		and	0F0h
		rlca
		rlca
		rlca
		rlca
		call	outhx1
		pop	af
		and	0Fh
outhx1:		add	a, 30h 	; '0'
		cp	3Ah 	; '9'+1
		jr	c, outhx2
		add	a, 7	; A..F
outhx2:		jr	CONSO

;------------------------------------------------------------------------------
; Systemaufrufe
;------------------------------------------------------------------------------

OPENW:		ld	c, 15
		jr	call5

WRITS:		ld	c, 21
		jr	call5

CLOSW:		ld	c, 16
		jr	call5

PRNST:		ld	c, 9
		jr	call5

OPENR:		ld	c, 13
		jr	call5

READS:		ld	c, 20
		jr	call5

CONSO:		ld	c, 2
		ld	e, a

call5:		jp	5

;------------------------------------------------------------------------------
; sonstige Unterprogramme
;------------------------------------------------------------------------------

; Anzeige Block geschrieben: Cursor wandert durch Ausgbe von Leerzerichen
outblk:		call	OSPAC		; Leerzeichen ausgeben
; Tastaturabfrage
stop:		call	DECO0		; Tastaturabfrage
		ei
		or	a		; Taste gedrückt?
		ret	z		; nein
		cp	3		; <STOP> ?
		scf
		ret	z		; Cy=1, wenn Stop-Taste
		ccf			; sonst Cy=0
		ret

puf1:		db 	0
puf2:		db    	0

; Keypuffer löschen
nokey:		;;xor	a
		ld	a, 0		;vp Cy erhalten
		ld	(KEYBU), a
		ret

		end
