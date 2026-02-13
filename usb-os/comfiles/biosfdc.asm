;Source: BIOSDSKT.MAC (CPA) + Kramer

;************************************************
; physischer Disketten-Transfer
;************************************************

;
; FDC-Ports:
; ----------


; 01.12.2013 Die Bezeichner CFDC und DFDC waren vertauscht

	IF FDCPORTS = 'ROBOTRON'

CFDC         	equ	98h  	; FDC Steueregister
DFDC         	equ	99h  	; FDC Datenregister
FDCZ        	equ	0A0h 	; FDC Zusatzregister
				; 5 4 3 2 1 0
				; x x 0 0 x x
				; | |     | |
				; | |     | Motor Laufwerk 0 ein/aus
				; | |     Motor Laufwerk 1 ein/aus
				; | Terminal Count aktivieren/deakt.
				; FDC Reset

CPMSYSTEM 	equ 'ROBOTRON'

	ELSE

CFDC         	equ	10h  	; FDC Steueregister
DFDC         	equ	11h  	; FDC Datenregister
FDCZ        	equ	12h 	; TC = high

CPMSYSTEM 	equ 'ROSSENDORF'

	ENDIF

;
; Aufruf:
; -------
; Bereitstellung der Parameter auf den Bytes:

;       ft.kom:	db	0	; bit0 - =1 ohne Fehlerwiederholung
;				     1 - lesen ft.len von beliebigem Sektor
;				     2 - schreiben (wenn auch bit0: mit verify)
;				     3 - 0-FM; 1-MFM   (5"FM nur bei PC1715)
;				     4 - 0-8"; 1-5"
;				     5 - 0- 40-Spur-Laufwerk; 1- 80-Spur-LW
;				     7 - =0 Vorderseite, =1 Rueckseite
;	ft.adr: dw	0	; Transferadresse
;	ft.lwn: db	0	; 0..3 phys. Laufwerksnummer
;	ft.trk: db	0	; 0..  track
;	ft.sid: db	0	; 0..ff side (side=0 auf Rueckseite moeglich!)
;	ft.sec: db	0	; 0..  sector (beliebig bei SektId lesen)
;	ft.len: db	0	; 0..3 Sektorlaenge (auch 0..3 bei SektId les.)
;	ft.anz: db	0	; 0.. Anzahl der zu uebertragenden Sektoren
;				;      =0: nur Positionieren
;				;      (<>0 bei SektId lesen)
;       ft.stp: db	0	;      Anzahl der Stepimpulse von Spur zu Spur
;	ft.sti: db	0	;      Schrittzeit von Spur zu Spur
;				;      in 0,1ms Einheiten
;
;	call	floppy
;       ...			; in A steht Ergebniskode
;				; alle Register (auch IX) undef.
;
; Ergebniskode (in Reg. A):
;	00h kein Fehler (Z-Flag nicht von floppy gesetzt)
;	'C' CRC-Fehler
;	'D' LW nicht existent
;	'R' Geraet nicht bereit, aber existent
;	'S' Sektor nicht gefunden
;	'T' Spurnummer zu gross
;	'U' keine Marke gefunden
;	'W' Diskette schreibgeschuetzt

; Paramfeld wird an folgenden Stellen veraendert:
;  Komm. "Lesen Sekt,Id.":	ft.trk .. ft.len gestellt
;  Komm. "Schreiben mit Verify":ft.kom, bit 0 geloescht

floppy:		ld	a, 15+1
		ld	(crerc), a		; Fehlerzaehler fuer CRC-Fehlerwiederholungen
		ld	a, 4+1			; Fehlerzaehler fuer Spurfindewiederholungen
		ld	(sperc), a

	IF CPMSYSTEM = 'ROBOTRON'

		ld	a, (ft.lwn)
		ld	c, a
		or	a
		ld	a, 1
		jr	z, drv0
		rlca
; Laufwerksnummer pruefen
drv0:		ld	hl, dFDCZ1
		and	(hl)
		jr	nz, drv0a
		ld	a, 'D'
		jp	fehret
drv0a:		out	(FDCZ),	a		; Motor an
		ld	(dFDCZ2), a

	ELSE

; Laufwerksnummer pruefen
		ld	hl, dFDCZ1
		ld	a, (ft.lwn)		; LW
		ld	c, a			; merken LW fuer Motor-an-Test
		cp	(hl)
		jr	c, drv0a			; ->ja
		ld	a, 'D'			; LW nicht existent
		jp	fehret			; -> Fehler
drv0a:		equ	$
	ENDIF

		ld	a, (ft.kom)
		and	80h
		rlca
		rlca
		rlca
		or	c
		ld	(UNIT), a
		ld	a, (ft.anz)
		ld	hl, ft.trk
		or	(hl)
		jr	nz, floppy3
		call	recal2
		jp	fehret

floppy3:	call	seek
		or	a
		jr	z, floppy5
		jp	fehret

floppy4:	ld	hl, sperc
		dec	(hl)
		ld	a, 'T'			; Fehler "Spurnr. zu groß"
		jp	z, fehret
		call	recal2
		or	a
		jp	nz, fehret
		jr	floppy3

floppy5:	ld	hl, ft.trk
		ld	de, TRCK
		ld	bc, 4
		ldir
		inc	(hl)
		dec	(hl)
		jp	z, noerr
		ex	de, hl
		ld	a, 0FFh
		ld	(hl), a
		inc	hl
		ld	a, 0Ah
		ld	(hl), a
		ld	a, (ft.len)
		or	a
		ld	a, 0FFh
		jr	nz, floppy6
		ld	a, 80h
floppy6:	ld	(DTL), a
		ld	a, (ft.kom)
		bit	1, a
		jr	nz, floppy10
		bit	2, a
		jr	nz, floppy7
		call	r8272
		jr	floppy8
floppy7:	call	sds
		bit	6, a
		ld	a, 'W'			; Fehler "write protect"
		jp	nz, fehret
		call	w8272
floppy8:	or	a
		jr	z, floppy9
		cp	'T'			; Fehler "Spurnr. zu groß"
		jr	z, floppy4
		cp	'C'			; Fehler: CRC-Zeichen falsch
		jr	nz, fehret
		ld	hl, ft.kom
		bit	0, (hl)
		jr	nz, fehret
		ld	hl, crerc
		dec	(hl)
		jr	z, fehret
		jr	floppy5
floppy9:	ld	hl, ft.kom
		bit	6, (hl)
		jr	z, noerr
		bit	2, (hl)
		jr	z, noerr
		res	2, (hl)
		jr	floppy5
floppy10:	call	readID
		ld	hl, reslt+4
		ld	de, ft.trk+1
		ld	bc, 3
		ldir
		or	a
		jr	nz, fehret
		ld	hl, ft.trk
		ld	a, (reslt+3)
		cp	(hl)
		jr	z, floppy11
		inc	(hl)
		dec	(hl)
		jp	z, floppy4
floppy11:	ld	(hl), a

; kein Fehler aufgetreten
noerr:		xor	a

; Fertigmelden, Ergebnis in A
fehret:
	IF CPMSYSTEM = 'ROBOTRON'
		push	af
		xor	a		; Motoren aus
		out	(FDCZ),	a
		pop	af
	ENDIF
		ret

; Spur 0 einstellen ( 2 Versuche)
recal2:		call	recal
		ret	z

; Spur 0 einstellen
recal:		ld	bc, 207h	; com. Spur 0 einstellen
		call	wcom		; com. in FDC schreiben

; prüfe Interruptstatus
sense:		ld	bc, 108h
		call	wcom		; com. in FDC schreiben
		call	rbyte		; 1 Byte lesen
		ld	b, a		; Resultatbyte (sto) in A enthält Fehlercode
		and	0C0h
		cp	80h
		call	nz, rbyte	;PCN lesen
		bit	5, b		; Seek Ende?
		jr	z, sense	; solange noch kein Seek Ende
		ld	a, 00011000b
		and	b
		ret	z
		ld	a, 'F'		; Fehler "Fehler bei Ausführung des SEEK-Kommandos"
		bit	4, b
		ret	nz
		ld	a, 'R'		; Fehler "Gerät nicht bereit"
		ret

; prüfe Laufwerkstatus
sds:		ld	bc, 204h
		call	wcom		; com. in FDC schreiben
		jp	rbyte		; Status Reg. lesen

; Spur einstellen
seek:		call	rdy		; Laufwerk bereit?
		ret	nz
		ld	a, (ft.stp)
		ld	b, a
		ld	a, (ft.trk)
		dec	b
		jr	z, seek1
		add	a, a
seek1:		ld	(TRCK), a
seek2:		ld	bc, 30Fh	; com. Spur einstellen
		call	wcom		; com. in FDC schreiben
		jp	sense		; prüfe Interruptstatus

; Laufwerk bereit?
rdy:		push	de
		ld	de, (rdwait)
rdy0:		push	bc
		call	sds		; prüfe Laufwerkstatus
		pop	bc
		bit	5, a		; rdy-Bit in Statusreg. 3
		jr	nz, rdy1	; falls alles i.O., raus hier
		dec	e
		jr	nz, rdy0
		dec	d
		jr	nz, rdy0
		ld	a, 'R'		; Fehler "Gerät nicht bereit"
		jr	rdy2
rdy1:		ld	a, 0
rdy2:		pop	de
		or	a
		ret

; Kommando in FDC schreiben
wcom:		ld	hl, CTAB
wcom1:		call	delay		; Verzögerung f. Statusflag 8272
		in	a, (CFDC)
		and	0C0h
		cp	80h		; RQM, DIO=OUT
		jr	nz, wcom1
		ld	a, c
		out	(DFDC), a
		inc	hl
		ld	c, (hl)
		djnz	wcom1
		ret

;Verzögerung f. Statusflag 8272
delay:		push	bc
		ld	b, 1
		djnz	$
		pop	bc
		ret

;1 Byte lesen
rbyte:		call	delay		; Verzögerung f. Statusflag 8272
		call	irdy		; Bereit für Dateneingabe?
		in	a, (DFDC)
		ret

; Lese 7 Resultbytes
rrslt:		ld	b, 6
		call	rbyte		; 1 Byte lesen
		ld	hl, reslt
		ld	(hl), a
		and	0C0h		; Fehler?
		ld	c, a
resl1:		call	rbyte		; 1 Byte lesen
		inc	hl
		ld	(hl), a
		djnz	resl1
		ld	a, c		; Fehlermeldung Status Reg. 0
		or	a
		ret

; Bereit für Dateneigabe?
irdy:		in	a, (CFDC)
		rlca
		jr	nc, irdy	; noch nicht bereit
		ret

; Sektor schreiben
w8272:		ld	de, 0A3EDh	; Code OUTI
		ld	c, 5
		jr	rwit

; Sektor lesen
r8272:		ld	de, 0A2EDh	; Code INI
		ld	c, 6
rwit:		ld	(rwmode), de
		call	set_mfm_bit
		ld	(CTAB), a	; Befehlstabelle für Leseoperation, MFM lesen
		call	rdy		; Laufwerk bereit?
		ret	nz
		ld	hl, 128		; Blockgröße
		ld	a, (ft.len)	; Sektorlaenge
		or	a
		ld	b, a
		jr	z, rwit2
rwit1:		add	hl, hl		; max. speicherplatz ermitteln
		djnz	rwit1
;
rwit2:		ld	a, (ft.anz)
		ld	b, a
		ld	de, 0
		ex	de, hl		; hl=0
rwit3:		add	hl, de
		djnz	rwit3
		ld	a, l
		or	a
		exx
		ld	b, a
		exx
		jr	z, rwit4
		inc	h
rwit4:		ld	b, h
		exx
		ld	c, DFDC
		ld	hl, (ft.adr)
		exx
		ld	d, 20h
		ld	hl, rwret
		push	hl
		ld	c, CFDC
		push	bc
		ld	b, 9		; Anzahl der Bytes
		ld	a, (CTAB)	; Anfangsadr. der CTAB
		ld	c, a		; in c kopieren ... für wcom
		di
		call	wcom		; com. in FDC schreiben
		pop	bc
rwit5:		in	a, (c)
		jp	p, rwit5
		and	d
		ret	z
		exx
rwmode:		ini			; oder outi je nach read/write
		exx
		jr	nz, rwit5
		djnz	rwit5
;TC senden
	IF CPMSYSTEM = 'ROBOTRON'
		ld	a, (dFDCZ2)
		or	10h		; TC senden
		out	(FDCZ),	a
		xor	10h		; TC wieder auf low
		out	(FDCZ),	a
	ELSE
		out	(FDCZ),	a	; bei ROSSENDORF: TC senden
	ENDIF
		pop	hl
rwret:		ei

ErrorEval:	call	rrslt		; Lese 7 Result Bytes
		ret	z
		cp	0C0h
		ld	a, 'R'		; Fehler "Gerät nicht bereit"
		ret	z
		ld	a, c
		cp	80h
		ld	a, 'B'		; Fehler "fehlerhafte Befehlsausgabe (interner Fehler)"
		ret	z
		ld	a, (reslt+1)
		ld	c, a
		srl	c
		ld	a, 'U'		; Fehler "keine Marke gefunden"
		ret	c
		srl	c
		ld	a, 'W'		; Fehler "Diskette schreibgeschützt"
		ret	c
		srl	c
		ld	a, 'S'		; Fehler "Sektor nicht gefunden"
		ret	c
		srl	c
		srl	c
		ld	a, 'C'		; Fehler "CRC-Fehler"
		ret	c
		srl	c
		ret	c
		ld	a, 'S'		; Fehler "Sektor nicht gefunden"
		ret

; Read Ident.
readID:		call	rdy		; Laufwerk bereit?
		ret	nz
		ld	bc, 20Ah	; com Read Ident
		call	set_mfm_bit
		ld	c, a
		call	wcom		; com. in FDC schreiben
		jp	ErrorEval

;
set_mfm_bit:	ld	a, (ft.kom)
		and	8
		rlca
		rlca
		rlca
		or	c
		ret

ft.kom:		db	0
ft.adr:		dw	0
ft.lwn:		db	0
ft.trk:		db	0
ft.sid:		db	0
ft.sec:		db	0
ft.len:		db	0
ft.anz:		db	0
ft.stp:		db	0
ft.sti:		db	0

crerc:		db	0
sperc:		db	0

dFDCZ1:		db	0	; Merkzelle FDC Zusatzregister
	IF CPMSYSTEM = 'ROBOTRON'
dFDCZ2:		db	0	; Merkzelle FDC Zusatzregister
	ENDIF
CTAB:		db	46h	; Befehlscode für MFM lesen
UNIT:		db	0	; Kopf/Laufwerksbyte
TRCK:		db	0	; Spurnummer (Zylinder)
HED:		db	0 	; Kopfnummer (0,1)
HSTSEC:		db	1 	; Sektornummer
N:		db	3 	; relative Sektorlänge 2^N; 3 => 1024 Byte
EOT:		db	0FFh 	; Nummer des letzten Sektors
GPL:		db	10h 	; Anzahl der Lückenbytes in GAP3
DTL:		db	0FFh	; Datenlänge (bei N>0 = 0FFh)

rdwait:		dw	5000	; timeout-wert für rdy

; Resulttab. f. FDC
reslt:		db	   0 ; ST0
		db	   0 ; ST1
		db	   0 ; ST2
		db	   0 ; Cyl.
		db	   0 ; Head
		db	   0 ; Record
		db	   0 ; N


