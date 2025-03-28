; File Name   :	F:\dvd104\hobby\kingstener sd-card\SDX.KCC
; Format      :	Binary file
; Base Address:	0000h Range: 3F00h - 4000h Loaded length: 0100h

;Terminal KC87/Z9001 Übertragung via V24-Modul
;2008 by Kingstener orig. SD 
;18.07.2013 VP für V24-Modul + RTS/CTS-Protokoll
;26.07.2013  zeichen senden mit handshake ist i.o. !

	cpu	Z80

errchk	equ	1	; 0 - keine Fehlerprüfung

		ifndef includeprg
		org	0b000h
		endif
		
;------------------------------------------------------------------------------
beg		
		jp	sdx
		db	"V24X    ",0
		db	0
;------------------------------------------------------------------------------

sdx:
		call	init
; Eingabe von ext.
sdx1:		call	getbyte
		cp	1Bh		; <ESC> -> Hilfsprogramme Lesen/Schreiben/Starten
		jr	z, ESC
		cp	80h 		; 80H -> Umschalten auf Mode out
		jr	z, sdx3
		cp	3		; <STOP>
		
;		JP	Z,INITA		;TASTATUR INITIALISIERN
;					; und Ende
		ret	z		; Ende

		ld	e, a		; sonst ECHO auf Bildschirm
		ld	c, 2		; CONSO
		call	5
		
;		rst 28h			; Testweise Anzeige als Hexzahl
;		db	0		; outhx
		
		jr	sdx1
; Ausgabe zu ext.
sdx3:		ld	c, 1		; CONSI Zeichen von Tastatur holen
		call	5
		ld	e, a		; Eingegebenes Zeichen auf Bildschirm ausgeben
		ld	c, 2		; CONSO
		call	5
		call	outbyte		; und an Controller ausgeben
		cp	0Dh		; <ENTER>?
		jr	z, sdx1		; ja - Kommandoausführung, Ergebnis einlesen
		jr	sdx3		; sonst	weiter Terminalbetrieb

;Hilfsprogrammverteiler
ESC:		call	getbyte
		cp	'T'
		jr	z, esc_t	; Programm in Speicher schreiben
		cp	'U'
		jr	z, esc_u	; Programm starten
		cp	'V'
		jr	z, esc_v	; Programm auf SD-Card schreiben
		;
		jr	sdx1

; Bytes lesen von V24 in Speicher
; ESC T aadr anz byte ... byte
esc_t:		call	getbyte		; Hole Anfangsadresse HL
		ld	l, a
		call	getbyte
		ld	h, a
		call	getbyte		; hole Anzahl DE
		ld	e, a
		call	getbyte
		ld	d, a
esc_t1:		call	getbyte		; Byte lesen
		ld	(hl), a		; in Speicher schreiben
		inc	hl
		dec	de
		ld	a, e
		or	d
		jr	nz, esc_t1	; bis alle Bytes abgearbeitet wurden
		jr	sdx1

; Bytes schreiben von Speicher zu V24
; ESC V aadr anz
esc_v:		call	getbyte		; Hole Anfangsadresse HL
		ld	l, a
		call	getbyte
		ld	h, a
		call	getbyte		; hole Anzahl DE
		ld	e, a
		call	getbyte
		ld	d, a
esc_v1:		ld	a, (hl)		; Byte holen
		call	outbyte		; auf SD-Card schreiben
		inc	hl
		dec	de
		ld	a, e
		or	d
		jr	nz, esc_v1	; bis alle Bytes abgearbeitet wurden
		jr	sdx1

; starten
; ESC U sadr
esc_u:		call	getbyte		; Startadresse holen
		ld	l, a
		call	getbyte
		ld	h, a
		push	hl		; auf Stack legen
		ret			; und starten


;------------------------------------------------------------------------------
; der phys. Treiber
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; V24-Interface 
;------------------------------------------------------------------------------

SIODA:	EQU	0B0H	;Datenadr SIO Kanal A
SIOKD:	EQU	SIODA+2	;Kdoadr   - " -
CTC:	EQU	0A8H	;Adr CTC Kanal 0
;
;
;Baudrate: BDRAT in Bd
;    BDRAT=9600,19200,38400 bei x1 clock mode
;    BDRAT=1200,4800,9600 (oder kleiner) bei x16 clock mode
;
;Zeitkonstante fuer CTC: ZKCTC=9600/BDRAT
;
;------------------------------------
;
; Paritaetsbit: PABI
;    ohne     Paritaet: PABI=0
;    ungerade Paritaet: PABI=1
;    gerade   Paritaet: PABI=3
;
;------------------------------------
;
; Stopbit: STPBI
;    1   Stopbit: STPBI=4
;    1.5 Stopbit: STPBI=8
;    2   Stopbit: STPBI=0CH
;


BDRAT:	EQU	9600	;9600 Bd
PABI:	EQU	2	;ohne Paritaet
STPBI:	EQU	4	;1 Stopbit


; orig: V24-Treiber von Robotron
; RTS nach AMSTRAD CPC interface serie RS232, Philippe LEBEL
; http://www.cpcwiki.eu/index.php/Z80-SIO_dual_ports_RS232_interface_for_CPC_(French)

init:		;SIO init
		ld	hl, PROGT
		ld	b, 3
		ld	c, CTC
		otir
		ld	b, 9
		ld	c, SIOKD
		otir
		and	a
		ret

; Systemtakt 2.457.600 Hz = 256*9600
; Vorteiler CTC 16 * Vorteiler SIO 16 => max Rate hier 9600

;die Variante mit x1 clock mode produziert leider regelmäßig aller paar Sekunden
;Fehler am KC, deshalb nur max. 9600 Baud 

PROGT:		;CTC
		DB 3			; reset
		DB 00010111b		; Zeitgeber, DI, Vorteiler 16
		DB 9600/BDRAT		; Zeitkonstante 
;		DB (9600*16)/BDRAT	; Zeitkonstante 
		;SIO
		DB 18h			; WR0, Channel Reset
		DB 4, 40h+PABI+STPBI	; WR4, x16 clock mode, 8 Bit Sync, Stopbit, Paritaetsbit
;		DB 4, 00h+PABI+STPBI	; WR4, x1 clock mode, 8 Bit Sync, Stopbit, Paritaetsbit
		db 1, 0			; WR1, Kein Interrupt
		db 3, 0C1h		; WR3, 8 rec bits, rec enable, rts off
		db 5, 68h		; WR5, Sender 8 TX Bits, TX enable, RTS inactive

; Einlesen Byte von ext. V24
; out A: Zeichen, B - Fehlercode
getbyte:	in	a, (SIOKD)	; SIO RR0
		bit	0,a		; check bit 0 for ready
		jr	nz, getbyte2	; es ist noch was in der Warteschlange
	
		;RTS 
		ld 	a,5 		;WR5
		out (SIOKD),A
		ld 	a,06Ah 		;TX 8bit, BREAK off, TX on, RTS active
		out (SIOKD),A
		
		di

		;warte bis frei
getbyte1:	in	a, (SIOKD)	; SIO RR0
		bit	0,a		; check bit 0 for ready
		jr	z, getbyte1	; not ready continue to poll
		;
getbyte2:	di
		;RTS  
		ld 	a,5 		;WR5
		out (SIOKD),A
		ld 	a,068h 		;TX 8bit, BREAK off, TX on, RTS inactive
		out (SIOKD),A
		;
		in	a, (SIODA)
		ei
	if errchk	
		ld	c, a
		;check for receive errors
		ld	a, 01h
		out	(SIOKD),a	; set WR0 point to RR1
		in	a, (SIOKD)	; get RR1 error register
		ld	b, a		; store error
		and	70h		; mask off all but D6,D5,D4
		ld	a, c
		ret	z
		;if errors reset before return
		ld	a, 30h		; set error reset command
		out	(SIOKD),a	; WR0 error reset command
		;TODO: Ausgabe Fehlermeldung o.a.
		push	hl
		push	de
		push	bc
		ld	a, b
		call	0f5efh		;errdis
		pop	bc
		pop	de
		pop	hl
		ld	a, c
	endif	
		ret

; ----------

; Ausgabe Byte zu ext. V24
; in A: Zeichen
; out A: Zeichen (unverändert)
outbyte:	ld	c, a
outbyte1:	in	a, (SIOKD)	; SIO RR0
;		bit	2,a		; test bit 2
;		jr	z, outbyte1	; b2=1 if empty, 0 if not empty
; mit Hardware-Flow-Control
		and	24h		; Bit 5 (CTS) und Bit 2 (TX Buffer Empty)
		cp	24h
		jr	nz, outbyte1	; solange nicht bereit
		;tx buffer is now empty
		ld	a, c		; Zeichen aus C nehmen
		OUT	(SIODA), a
		ret
;

;------------------------------------------------------------------------------

;		end
