;-----------------------------------------------------------------------------
; Mini-BIOS für den Z9001 ohne Floppy (zum Reinschnuppern)
; mit kleiner RAM-Disk
; basierend auf:
; Z9001-BIOS für CPA, 1989 Dr. Schwarzenberg,reass 2004 Volker Pohlers
;-----------------------------------------------------------------------------

		cpu	z80
	
;-----------------------------------------------------------------------------
; Historie:
;	 04.06.2004	Neuer CRT-Treiber aus aktuellstem BIOS
;	 06.06.2004	Korrektur RAM-Disk-Steuerung
;	 09.06.2004 	RAM-Disk mit 512 Byte großen Blöcken
;	06.03.2012	vp: anpassung an flash-rom-software
;-----------------------------------------------------------------------------
;

;;VERSIONSDATUM	equ	DATE
VERSIONSDATUM	equ	"14.7.2006"		; für 100% kompatibilität

	include "includes.asm"

;-----------------------------------------------------------------------------
; einbinden des Digital Teils ........

		org	0c000h        
prog_start:
		binclude "minicpm/ccp2_9000.rom"

;-----------------------------------------------------------------------------



firstram	equ $

CCP		equ	09000h		; base of ccp
BDOS       	equ	CCP+0806h	; base of bdos
UBIOS		equ	CCP+1600h	; base of bios
;RDSK:		equ	0A000h		; RAM-Disk
RDSK:		equ	0A800h		; RAM-Disk

;Ports
CTC0		equ	80h	; System CTC0
CTC1		equ	81h	; System CTC1
CTC3		equ	83h	; System CTC3

PIO1AD		equ	88h	; System PIO1AD
PIO1BD		equ	89h	; System PIO1BD	Anwenderport
PIO1BC		equ	8bh	; System PIO1BC Anwenderport



dbg	equ	0

;-----------------------------------------------------------------------------
; CCP+BDOS
;-----------------------------------------------------------------------------

;  org SBIOS - 1600H ; ;  db 1600h dup (?) ; Bereich CCP+BDOS

;-----------------------------------------------------------------------------
; BIOS
;-----------------------------------------------------------------------------

		PHASE 	UBIOS

		jp	cold		
		jp	wboot
		jp	_const		; const im upper bios
		jp	0F009h		; conin im z9001-os
		jp	_conout		; conout im upper bios
		jp	0F00Fh		; list im z9001-os
		jp	0F012h		; punch im z9001-os
		jp	0F015h		; reader im z9001-os
		jp	home
		jp	seldsk
		jp	settrk
		jp	setsec
		jp	setdma
		jp	read
		jp	write
		jp	0F02Dh		; listst im z9001-os
		jp	sectran

;-----------------------------------------------------------------------------
; ab hier ein bischen CODE
;-----------------------------------------------------------------------------

; einstellen einer Bank .... wichtig fÃ¼rdie Arbeit mit der Ramdisk
set_CPMBank	ld	a, (cpmbank)
set_Bank	out 	(0ffh),a
		ret

;-----------------------------------------------------------------------------
; wboot .... 2. Teil .... Coldboot Ã¤ndert hier etwas den Code 
; -> deshalb der Split + war zu faul, um mir etwas anderes einfallen zu lassen ...
; -> kÃ¶nnte man noch etwas tun
;-----------------------------------------------------------------------------


wboot2:		or	0
		ld	(hl), a
		ld	e, 1
		call	seldsk
		pop	bc
		ld	a, h
		or	l
		jp	z, wboot1

		jp	CCP	; CLEAR: CCP-Aufruf ohne Löschen des Befehlsbuffers		

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

READ:	CALL	calcadr
	JR	C, READ1
	LD	DE,(currentdma)
	JR	WRIT1
READ1:	call	set_cpmBank
	LD	A,1
	RET

WRITE:	CALL	calcadr
	JR	C,READ1
	EX	DE,HL
	LD	HL,(currentdma)
WRIT1:	LD	BC,80H
	LDIR
	call	set_cpmBank
	XOR	A
	RET

;-----------------------------------------------------------------------------
; es folgen Daten, die nicht in den ROM dÃ¼rfen .....

fiotab:
		; Gerätetreiber	CONST/CON setzen
		dw	uTTYC		; TTY:
		dw	uCRTC		; CRT:
		dw	_BATC		; BAT:
		dw	0F8F1h		; RDR/UC1:=	CRT-Treiber Z9001
		; Gerätetreibertabelle READER/RDR setzen
		dw	0F8F1h		; TTY:=	CRT-Treiber Z9001
		dw	_dummyin	; RDR/PTR:
		dw	_dummyin	; UR1:
		dw	_dummyin	; UR2:
		; Gerätetreibertabelle PUNCH/PUN setzen
		dw	0F8F1h		; TTY:=	CRT-Treiber Z9001
		dw	upunch		; PUN/PTP:
		dw	upunch		; UP1:
		dw	0E397h		; UP2:
		; Gerätetreibertabelle LIST/LST setzen
		dw	18h
		dw	0F8F1h		; TTY:=	CRT-Treiber Z9001
		dw	uCRTL		; CRT:
		dw	uup		; LST/LPT:
		dw	uUL		; UL/UL1:


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

;Disk-Parameter-Header
DPBAS:		equ	$
dph0:		dw	0		; XLT	translation table
		dw	0
		dw	0
		dw	0
		dw	dirbuf		; DIRBUF
		dw	dpb0		; DPB
		dw	CSV0		; CSV
		dw	ALV0		; ALV

dph1:		dw	0		; XLT	translation table
		dw	0
		dw	0
		dw	0
		dw	dirbuf		; DIRBUF
		dw	dpb1		; DPB
		dw	CSV1		; es gibt keinen Check .....
		dw	ALV1		; ALV

disks		EVAL 	2

	if minicpm_disk2
dph2:		dw	0		; XLT	translation table
		dw	0
		dw	0
		dw	0
		dw	dirbuf		; DIRBUF
		dw	dpb1		; DPB
		dw	CSV2		; kein Check 
		dw	ALV2		; ALV

disks		EVAL	disks+1
	endif

ubiosend:	equ	$

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

byte_0_E34D:	db 	0FFh
off_0_E34E:	dw	loc_0_E350
loc_0_E350:	nop
loc_0_E351:	nop

cpmBank		db	?

currentdrive	db	?
currentdma:	dw	?		; aktuelle DMA-Adresse
currenttrack:	dw	?
currentsector:	dw	?

ALV0:		db	30h dup (?)	; (DSM+1)/8			; braucht er eh nicht 
CSV0:		; es gibt keinen Check ....

		dephase

		; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . 

		org 	0c000h+01600h+0100h
		phase 	ubios+0100h

; "intvectab" muss an einer xx00 Adresse stehen 

intvectab:	db 	12	dup(?)	; Interruptvektortabelle, 12 Byte
dirbuf:		db	128 dup (?)	; Bereich 128 Byte

ALV1:		db	32h dup (?)	; (DSM+1)/8
CSV1:					; es gibt keinen Check ....
ALV2:		db	32h dup (?)	; (DSM+1)/8
CSV2:					; es gibt keinen Check ....

lastram:	equ	$

;		SHARED  CCP,BDOS,UBIOS,RDSK,CTC0,CTC1,CTC3,PIO1AD,PIO1BD,PIO1BC


;-----------------------------------------------------------------------------

		dephase

prog_end:

;-----------------------------------------------------------------------------
; hier alles, was im ROM stehen kann ....
; hier alles, was im ROM stehen kann ....


calcAdr:	ld	a, (currentdrive)
		cp      0
		jp	z, RADR			; wir haben eine ramfloppy	
       	
		exx	
		ld	hl, cpmbank
		ld	b,(hl)			;b := cpmbank
		inc	b			;b := disk1b
	if minicpm_disk2
		cp	1
		jr	z, laufwerk_weiter	; wenn drive B:
		; sonst Drive C:
		push	af
		ld	a,(hl)
		add	a,81			; 80*10K = 800K Diskgröße + disk1b offset
		ld	b,a			; b := disk2b
		pop	af
laufwerk_weiter:
	endif
		exx
        	
		ld	b, 0
		ld	a, (currenttrack)
        	
		rra	; einmal nach recht's und modBit ins Carry ....
		jr	nc, weiter
        	
		ld	b, 40	; wird spÃter addiert ....

weiter:
		exx	
		add	a,b
		exx
;		out 	0ffh,a			; Bank einstellen .....
        	
		push	af
		
		ld 	a, (currentsector)
		add	a, b			; 40 oder 0
		dec 	a			; da sectorenzÃ¤hlung mit 0 beginnt .....
		ld	l,a
		ld 	h,0			; HL = CurrentSector ....
        	
		; mit 128 multiplizieren .....
		add 	hl,hl			; *2
		add 	hl,hl			; *4
		add 	hl,hl			; *8
		add 	hl,hl			; *16
		add 	hl,hl			; *32
		add 	hl,hl			; *64
		add 	hl,hl			; *128
        	
		ld 	bc, 0c000h		; BasisSpeicheradresse noch dazu und fertig.....
		add	hl, bc	
        	
		pop	af			
		jp	set_bank



;-----------------------------------------------------------------------------
; wboot .... 1. Teil
;-----------------------------------------------------------------------------

wboot:		
		di
		ld	sp, 80h

		; CCP kopieren ...
		; dazu erste CPM BAnk einstellen .....
		
		ld	a, (CPMBank)
		out 	0ffh, a

		; kopieren

		ld 	hl, 0c000h
		ld	de, ccp
		ld	bc, 01600h
		ldir

		ld	a, hi(intvectab)	;E7H
		ld	i, a
		im	2

		ld	a, 0C3h		; Befehlscode JP
		ld	(0), a		; 0000h: jp wboot
		ld	(38h), a	; 0038h: RST 38H, jp wboot
		ld	hl, ubios+3	; wboot	im upper Bios
		ld	(1), hl
		ld	(39h), hl
		ld	(5), a		; 0005h: jp bdos
wboot0:		ld	hl, BDOS
		ld	(6), hl

		ei

wboot1:		ld	hl, 3
		ld	c, (hl)
		push	bc
		ld	a, c
		and	0Fh
		ld	c, a
		xor	(hl)
		jp      wboot2



;-----------------------------------------------------------------------------
; PUN-Gerätetreiber für	PUNCH
;-----------------------------------------------------------------------------
upunch:		ld	a, c
		ld	de, upunch1+1
		call	hexa		; A nach hex konvertieren, Eintragen nach (DE),	2x inc DE
		ld	c, '('
		call	_conout		; _conout im upper Bios
upunch1:	ld	bc, 0
		push	bc
		call	_conout		; _conout im upper Bios
		pop	bc
		ld	c, b
		call	_conout		; _conout im upper Bios
		ld	c, ')'
		jp	_conout		; _conout im upper Bios
stopkey:	call	0FD33h		; Z9001-OS DECO0: Abfrage Tastaturmatrix
		ei
		sub	3		; STOP-Taste ?
		or	a
		ret	nz
		ld	(25h), a	; Tastaturbuffer
		scf
		ret

;-----------------------------------------------------------------------------
; TTY-Treiber für CONS
;-----------------------------------------------------------------------------
uttyc:		cp	1		;
uttyc1:		scf
		ccf
		jp	nz, 0F8F1h	; Z9001-OS CRT:	Steuerprogramm des CRT-Treibers
uttyc2:		call	0F8F1h		; Z9001-OS CRT:	Steuerprogramm des CRT-Treibers
		call	bell
		ld	hl, lstflag

		bit	0, (hl)
		jr	nz, uttyc10
		cp	1Ch		; LIST-Taste
		jr	nz, uttyc10
		ld	a, 1
		ld	(hl), a
		jr	uttyc

uttyc10:	bit	0, (hl)
		jr	z, uttyc4
		ld	(hl), 0
		cp	1Ch
		ret	z
		cp	'P'
		jr	nz, uttyc12
		ld	a, (15h)
		xor	1
		ld	(15h), a
uttyc11:	ld	a, 1
		jr	uttyc

uttyc12:	cp	'N'
		jr	nz, uttyc18
		push	de
		ld	hl, 0EC00h	; Adr. Bildwiederholspeicher
		in	a, (PIO1AD)
		bit	2, a
		ld	a, 14h
		jr	nz, uttyc13
		add	a, 4
uttyc13:	ld	d, a
uttyc14:	ld	e, 28h ; '('
uttyc15:	ld	c, (hl)
		push	de
		push	hl
		call	0F00Fh		; Z9001-OS: list
		pop	hl
		pop	de
		jr	c, uttyc17
		inc	hl
		dec	e
		jr	nz, uttyc15
		push	hl
		push	de
		ld	c, 0Dh
		call	0F00Fh		; Z9001-OS: list
		jr	c, uttyc16
		ld	c, 0Ah
		call	0F00Fh		; Z9001-OS: list
uttyc16:	pop	de
		pop	hl
		jr	c, uttyc17
		dec	d
		jr	nz, uttyc14
uttyc17:	pop	de
		jr	uttyc11
uttyc18:	equ	$

		ld	hl, lsttab	; Tabelle Extrazeichen (LIST+char)
		ld	bc, 7
		cpir			; suche	Sondertaste
		jr	nz, uttyc4
		ld	bc, 6
		add	hl, bc
		ld	a, (hl)		; Sonderzeichen	holen

uttyc4:		ld	hl, uttyc6
		push	hl
		cp	'A'
		jr	c, uttyc5
		cp	'['
		jr	nc, uttyc5
		or	20h
		ret
uttyc5:		cp	'a'
		ret	c
		cp	'{'
		ret	nc
		sub	20h
		ret
uttyc6:		or	a
		ret
		
		
lstflag:	db	0

lsttab:		db	'8'		; Tabelle Extrazeichen (LIST+char)
		db	'9'
		db	','
		db	'.'
		db	'I'
		db	'?'
		db	'='
;
		db	'['
		db	']'
		db	'{'
		db	'}'
		db	'|'
		db	5Ch
		db	'~'

;-----------------------------------------------------------------------------
; CRT-Treiber für CONS
;-----------------------------------------------------------------------------
ucrtc:		cp	1		;
		jp	nz, uttyc1
		call	0F8F1h		; Z9001-OS CRT:	Steuerprogramm des CRT-Treibers
bell:		di
		push	af
		push	bc
		ld	b, 0
		ld	c, 14h
		ld	a, 111b		; interrupt aus, zeitgeber mode, Vorteiler 16, negative	Flange,
					; Start	sofort,	Konstante folgt, Kanal Reset
		out	(CTC0), a	; CTC0
		ld	a, 96h		; Zeitkonstante
		out	(CTC0), a
		in	a, (PIO1AD)
		set	7, a
		out	(PIO1AD), a	; Lautsprecher an
bell1:		djnz	bell1
		dec	c
		jr	nz, bell1
		res	7, a
		out	(PIO1AD), a	; Lautsprecher aus
		ld	a, 11b
		out	(CTC0), a	; CTC0 Reset
		pop	bc
		pop	af
		ei
		ret

;-----------------------------------------------------------------------------
; UP2 Gerätreiber für PUNCH
;-----------------------------------------------------------------------------
uup:		push	af
		ld	a, 0Ch
		jr	ucrtl1

;-----------------------------------------------------------------------------
; CRT-Gerätetreiber für	LIST
;-----------------------------------------------------------------------------
ucrtl:		push	af
		ld	a, 7Eh
		
ucrtl1:		ld	(ucrtl4+1), a
		ld	a, 11001111b
		out	(PIO1BC), a	; PIO1B	init Bitmode
		ld	a, 10000000b
		out	(PIO1BC), a	; Bit7 Eingabe,	Bit6-Bit0 Ausgabe
		pop	af
		inc	a
		ret	z
		dec	a
		jr	nz, ucrtl2
		in	a, (PIO1BD)	; PIO1B	lesen
		or	7Fh
		cpl
		ret		
ucrtl2:		call	stopkey
		jr	nc, ucrtl3	; Sprung, wenn STOP-Taste nicht	gedrückt
		ld	(15h), a	; LISW,	Schalter für Hardcopy
		ret
ucrtl3:		in	a, (PIO1BD)	; PIO1B	lesen
		add	a, a
		jr	c, ucrtl2
		ld	a, c
		cp	7Fh
		jr	nz, ucrtl4
		ld	a, 1Bh
ucrtl4:		ld	e, 7Eh
		ld	b, 9
		di
		or	a
		rla
ucrtl5:		out	(PIO1BD), a	; PIO1B	schreiben
		call	ucrtl6		; kurze	Pause, Zeitwert	in E
		rra
		djnz	ucrtl5
		or	1
		out	(PIO1BD), a	; PIO1B	schreiben
		ei
; kurze	Pause, Zeitwert	in E
ucrtl6:		push	de
ucrtl7:		dec	e
		jr	nz, ucrtl7
		pop	de
		ret

;-----------------------------------------------------------------------------
; UL Gerätetreiber für LIST
;-----------------------------------------------------------------------------
uul:		inc	a
		ret	z
		dec	a
		cpl
		ret	z
		ld	a, 11001111b
		out	(PIO1BC), a
		xor	a
		out	(PIO1BC), a
		ld	a, 1010111b
		out	(CTC1), a
		out	(CTC1), a
		ld	a, c
		or	80h
		cp	0FFh
		jr	nz, uul1
		ld	a, 9Bh
uul1:		out	(PIO1BD), a
		push	ix
		pop	ix
		and	7Fh
		out	(PIO1BD), a
		or	80h
		out	(PIO1BD), a
uul2:		call	stopkey
		ret	c
		in	a, (CTC1)
		cp	57h
		jr	z, uul2
		xor	a
		ret

;-----------------------------------------------------------------------------
; console status
;-----------------------------------------------------------------------------
_const:		call	0F006h		; Z9001-OS: Abfrage Status CONST
		or	a
		ret	z
		ld	a, 0FFh
		ret

;-----------------------------------------------------------------------------
; BAT-Gerätereiber für CRT
;-----------------------------------------------------------------------------
_BATC:		or	a
		jp	nz, 0F7B4h	; Z9001-OS: BAT, Steuerprogramm für Batch-Mode von CONST
		ld	hl, (0F016h)	; Z9001-OS: Adresse des UP READER (Eingabe Zeichen von Reader)
		inc	hl
		inc	hl
		jp	(hl)

;-----------------------------------------------------------------------------
; Dummy-Gerätetreiber, gibt stets Dateiende (^Z) zurück
;-----------------------------------------------------------------------------
_dummyin:				; ^Z; Eingabeende
		ld	a, 1Ah
		ret




;-----------------------------------------------------------------------------
; console character out
;-----------------------------------------------------------------------------
_conout:	ld	a, (byte_0_E34D)
		cp	0FFh
		jr	z, _conout3
		ld	hl, (off_0_E34E)
		res	7, c
		inc	c
		ld	(hl), c
		dec	hl
		ld	(off_0_E34E), hl
		ld	hl, byte_0_E34D
		dec	(hl)
		jr	nz, _conout2
		dec	(hl)
		ld	hl, _conout1
		push	hl
		ld	hl, (0F069h)	; Z9001-OS: Adr. Setzen log. Cursor
		push	hl
		ld	l, 3
		ld	de, (loc_0_E350)
		ret
_conout1:	ld	hl, loc_0_E351
		ld	(off_0_E34E), hl
_conout2:	or	a
		ret
_conout3:	ld	a, (25h)	; KEYBU	(Tastaturbuffer)
		cp	13h		; PAUSE-Taste?
		jr	nz, _conout4
		push	bc
		call	0F009h		; Z9001-OS: Eingabe Zeichen von CONST, PAUSE-Taste holen
		call	0F009h		; Z9001-OS: Eingabe Zeichen von CONST, Warten auf Tastendruck
		pop	bc
_conout4:	ld	a, 1Bh
		cp	c
		jp	nz, 0F00Ch	; Z9001-OS: Ausgabe Zeichen zu CONST
		ld	a, 2
		ld	(byte_0_E34D), a
		jr	_conout1

;-----------------------------------------------------------------------------
; (HL) nach hex	konvertieren, Eintragen	nach (DE), 2x inc DE
;-----------------------------------------------------------------------------
hexm:		ld	a, (hl)
hexa:		call	hexa1		; A nach hex konvertieren, Eintragen nach (DE),	2x inc DE
hexa1:		rrca
		rrca
		rrca
		rrca
		push	af
		and	0Fh
		sub	0Ah
		jr	c, hexa2
		add	a, 7
hexa2:		add	a, 3Ah
		ld	(de), a
		inc	de
		pop	af
		ret

;-----------------------------------------------------------------------------
; cold boot
; Einsprung durch Init nach Bootloader, Initialisierung von cold und ubios
;-----------------------------------------------------------------------------

cold:		di

		ld	sp, 80h
		
		xor	a
		ld	(3), a		; Standard-Laufwerk A
		ld	(wboot2+1), a

		ld	hl, 0FCB0h	; Z9001-OS: Tabelle der Interruptadressen
		ld	bc, 0Ch
		ld	de, intvectab	; nach E700 kopieren
		ldir

;		ld	c, 10010100b	; I/O-Byte: LIST=UL:,PUNCH=UP1:,READER=UR1:,CONST=TTY:
		ld	c, 10010111b	; I/O-Byte: LIST=UL:,PUNCH=UP1:,READER=UR1:,CONST=TTY:
		call	0F03Ch		; Z9001-OS: Setzen I/O-Byte

		ld	a, hi(intvectab); Interrupttabelle
		ld	i, a		; Interruptregister setzen
		im	2

		; Gerätetreibertabellen füllen
		di
		ld	hl,fiotab
		ld	de,0EFC9h	; Tabelle der Gerätetreiberadressen
		ld	bc,4*4*2
		ldir
		ei
		
		xor	a
		ld	(lstflag), a
		
cold7:		ld	a, 0
		ld	hl, loc_0_E350
		ld	(off_0_E34E), hl
		ld	hl, 0
		ld	(loc_0_E350), hl
		ld	a, 0FFh
		ld	(byte_0_E34D), a

		ld	hl, bootmsg	; Anzeige Boot-Meldung
		call	prnst		; Stringausgabe
		call	rfdel

		ld	hl, startkdo	; Start-Kommando
		ld	de, CCP+0007h	; CCP-Befehlsbuffer
		ld	bc, startkdoend-startkdo	; Byte + 1 Längenbyte
		ldir

		jp	wboot		; WBOOT	im ShadowBios

startkdo:	db  	startkdoend-$-1	; Länge	des Befehls(buffers)
		db 	"b:",0
		;db	"CLOCK",0
		;db 	"STAT DEV:",0
		;db 	"DIR",0
startkdoend:	equ	$


;-----------------------------------------------------------------------------
prnst:		ex	de, hl
		ld	hl, (0F057h)	; Adr. PRNST-Funktion des Z1013-OS
		jp	(hl)

;-----------------------------------------------------------------------------
; RAM-Disk-Treiber
;-----------------------------------------------------------------------------

seldsk:	LD	HL,0	;Laufwerk waehlen
	PUSH	BC
	LD	A,C
	CP	disks		; wenn > dann ist das Carry Bit gesetzt .....
	JR	nc,FEHL		;wenn nicht RAM-Disk

	LD	L,C
	LD	H,0
	ADD	HL,HL		; *2
	ADD	HL,HL		; *4
	ADD	HL,HL		; *8
	ADD	HL,HL		; *16
	LD	DE,DPBAS
	ADD	HL,DE
	LD	(currentdrive),A
	POP	BC

	RET

FEHL:	LD	HL,0
	POP	BC
	RET


;Sector Transformation
sectran:LD	H,B
	LD	L,C
	INC	HL
	RET

setsec:	LD	HL,currentsector	;Sector einstellen
	LD	(HL),C
	RET

HOME:	LD	BC,0	;Spur 0

settrk:	LD	HL,currenttrack	;Spur anwaehlen
	LD	(HL),C
	RET

setdma:	LD	(currentdma),BC	;DMA setzen
	RET

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 


RADR:	LD	A,(currenttrack)
	LD	D,0
	LD	E,A			; DE = aktuelle Spur oder Track
	LD	A,(currentsector)
	LD	C,A			; C = aktueller Sector ....
	LD	HL,0			
	LD	B, 26	; Sectors/Track	; Anzahl der Sectoren pro Track ....

; berechnen der Ausgangsspur im RAM ...... 26 * Ã¼bergebener Track ....
; 					  (26 = Sectoren/Track)

RADR1:	ADD	HL,DE
	DJNZ	RADR1	; HL = Sectors/Track * Track = Basis-Sektor currenttrack

; addiere den aktuellen Sector hinzu ... BC , b vorher auf 0 runter gezÃ¤hlt

	ADD	HL,BC	; B=0; HL = Basis-Sektor currenttrack + currentsector

; das ganze mal 128 .... 128 = BlockgrÃ¶ÃŸe im CPM .....

	ADD	HL,HL	; *2
	ADD	HL,HL	; *4
	ADD	HL,HL	; *8
	ADD	HL,HL	; *16
	ADD	HL,HL	; *32
	ADD	HL,HL	; *64
	ADD	HL,HL	; *128 Bytes/Sektor => Offset in RAM-Disk

	LD	BC,RDSK-128	; Sektorenzählung beginnt mit 1, deshalb Korrektur

; RAM Floppy Basis Adresse dazu ......

	ADD	HL,BC	; Basis-Adr. RAM-Disk addieren
	
	LD	A, 0BFH
	CP	H	; Cy=1: H>0BFH, also RAM-Disk overflow
	RET

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 

RFDEL:	LD      HL, MT4		; RAMDISK LOESCHEN
        CALL	PRNST
RF1:    CALL	0F009h		; conin im z9001-OS
	and	5FH		; klein -> groß
	CP     'Y'
	JR	Z, RF2
	CP     'N'
	RET	Z        
	JR	NZ, RF1
RF2:    LD	HL,RDSK
	LD      DE,RDSK+1
        LD	BC,0BFFFH-RDSK
        LD 	A,0E5H
	LD	(HL),A     
	LDIR
	RET

;-----------------------------------------------------------------------------
;testweise: 256-Byte-Blöcke
dpb0:		Dw	26		; SPT	26 Sektoren/Spur
		DB	2		; BSH	= log2(blocksize/128)
;					;  => blocksize = (2^x)*128 =  512
		DB	3		; BLM	= 2^BSH-1
		DB	0		; EXM
		Dw	12-1		; DSM	max. x Blöcke
					;  => also x* blocksize = 4K disc !!!
		Dw	8-1		; DRM	max x Dir. Einträge
		DB	080H		; AL0	also x Block (DRM*32/blocksize)
		DB	0		; AL1	für DIR reservieren
		Dw	0		; kein Check ....
		Dw	0		; OFF	0 reservierte Spuren

	; 26*

; ROM Floppy im 800k KC87 Format....

DPB1:   DW      40		; SPT = 40 Sektoren pro Track-Spur
        DB      4		; BSH => log2(blockSize/128) = 2048
	DB 	15		; BLM => 01111b
	DB	0		; EXM => 
        DW      399;            ; DSM => DISK SIZE-1
        DW      191             ;DIREKTORY MAX-1
        DB      11100000B
        DB      0
        DW      0		; kein Check .....
        DW      0


; -----------------------------------------------------------------------------------------------

ROT:    		EQU     0114H
GRUEN:  		EQU     0214H
GELB:   		EQU     0314H
BLAU:   		EQU     0414H
MAGENTA:		EQU     0514H
CYAN:   		EQU     0614H
WHITE:  		EQU     0714H 

MT4:	DB	0DH
	DB	0AH
	DB	0AH
	DB	"RAM-Disk formatieren (Y/N)?"
	DB	0

                ;             1234567890123456789012345678901234567890
bootmsg:        db      0Ch
		dw	rot
                db      "Mini-CP/A Z9001, Version ",VERSIONSDATUM, 0Dh, 0Ah
                dw	gruen
                db      16h, "Schwarzenberg 1989,Pohlers 2004, KOMA 05", 16h
                db      "TPA 100H - \{BDOS-1}H", 0Dh, 0Ah,0dh,0ah
                dw	gelb
                db	"Laufwerke:", 0Dh, 0Ah
                dw	gruen
                db      "A: RAM-Disk \{RDSK}-BFFFH", 0Dh, 0Ah
                db      "B: ROMFLOPPY (Anwendungen)",0dh,0ah
	if minicpm_disk2
                db      "C: ROMFLOPPY (Basic, Spiele)", 0dh, 0ah
        endif
                db      0dh,0ah
                dw	gelb
                db      "I/O-Devices:", 0Dh, 0Ah
                dw	gruen
                db      "LST: = CRT: V24-User-Port 1200 Bd", 0Dh, 0Ah
                db      "LST: = LPT: V24-User-Port 9600 Bd", 0Dh, 0Ah
                db      "LST: = UL1: Centronics User-Port", 0Dh, 0Ah
                db      "CON: = TTY: Beep + Gross<=>Klein", 0Dh, 0Ah
                db      "CON: = CRT: nur  Tastatur-Beep", 0Dh, 0Ah
                db      "CON: = UC1: ohne Beep"
                db      0


		org 0e700h


		jp	gominicpm
		db      "MINICPM ",0		
		db	0

gominicpm:
        ld      hl, 0c000h
        ld      de, ccp
        ld      bc, prog_end-prog_start
        ldir

	ld	a,(currbank)
	ld	(cpmbank),a

        jp 	ccp+01600h

		end
