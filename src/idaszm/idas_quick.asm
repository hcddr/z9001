; File Name   :	h:\hobby\hobby0\z9001 kompaktor-kassette\idas_uz\idas_uz_erweiterung.rom
; Format      :	Binary file
; Base Address:	0000h Range: E500h - E800h Loaded length: 0300h
; Processor	  : z80	[]
; Target assembler: X-M-80 by Leo Sandy

		cpu	z80

; enum PORTS
CTC0:		 equ 80h			; System CTC0 Kassette,	Beeper
CTC1:		 equ 81h			; System CTC1 Anwenderport
CTC2:		 equ 82h			; System CTC2 Systemuhr
CTC3:		 equ 83h			; System CTC3 Systemuhr

; f. extra Hardware am User-Port
; Bit2: Ausgabe Signal
; Bit7: Einlesen Signal
PIO1BD		equ 89H				; User-Port Daten Kanal B
PIO1BS		equ 8BH				; User-Port Steuerung Kanal B


; enum RAM
DMA:		 equ 001Bh			; Zeiger auf Puffer für Kassetten-E/A
BLNR:		 equ 006Bh			; Blocknummer


		org 0E500h

;------------------------------------------------------------------------------
; OS-Rahmen
;------------------------------------------------------------------------------
		
		jp	QUICK
aQuick:		db "QUICK   ",0
		jp	NORMAL		; orig.	BDOS-Call
aNormal:	db "NORMAL  ",0
		jp	QLOAD
aQload:		db "QLOAD   ",0
		db    0

;------------------------------------------------------------------------------
; Kommando QUICK, NORMAL
; Quicksave aktivieren/deaktivieren
;------------------------------------------------------------------------------

QUICK:		ld	hl, CBDOS	; neuer	BOS-Call (CALL 5)
		xor	a
		ld	(5Ah), a
		jr	normal1
;
; Kommando NORMAL
; Quicksave deaktivieren
NORMAL:		ld	hl, 0F314h	; orig.	BDOS-Call
normal1:	ld	(6), hl
		ret

;------------------------------------------------------------------------------
; Kommando QLOAD [name[.typ]]
;------------------------------------------------------------------------------
;vgl. CLOAD-Kommando
QLOAD:
		call	0F1EAh
		ret	z
		ld	hl, 0F5E6h	; ERPAR
		push	hl
		ld	a, (100h)	; INTLN
		cp	9
		ret	nc
		ld	de, 5Ch
		ld	a, 8
		call	0F588h		; MOV
		ex	af, af'
		jr	nc, LOAD3
		ex	af, af'
		ld	hl, 4F43h	; Dateityp "COM" eintragen
		ld	(64h), hl	; FCB+8, TYP
		ld	a, 'M'
		ld	(66h), a
		jr	LOA33
LOAD3:		ld	a, c
		cp	'.'
		pop	hl
		jp	nz, 0F5E2h	; ERINP
		push	hl
		call	0F1EAh		; GVAL
		ret	z
		ld	a, 3
		cp	b
		ret	c
		ld	de, 64h		; FCB+8, TYP
		call	0F588h		; MOV
LOA33:		pop	hl
		ex	af, af'
		jp	nc, 0F5E2h	; ERINP
LOAD4:		call	OPENR
		jr	nc, LOAD5
		or	a
		scf
		ret	z
		call	0F5A3h		; REA
		ret	c
		jr	LOAD4
LOAD5:		ld	hl, (6Dh)
		ld	(DMA), hl
LOA55:		call	READS
		jr	nc, LOAD6
		call	0F5A3h		; REA
		ret	c
		xor	a
LOAD6:		or	a
		jr	z, LOA55
		jp	0F2FEh		; OCRLF


;------------------------------------------------------------------------------
; neuer	BOS-Call (CALL 5)
;------------------------------------------------------------------------------

CBDOS:		ld	(0Bh), sp	
		ld	sp, 1C0h
		scf
		ccf			; Cy = 0
		push	hl
		push	de
		push	af
		ld	(0Dh), bc	; BCSV
		ld	(0Fh), a	; ASV
		ld	hl, 0F345h	; BOSE
		push	hl
		ld	a, c
		push	de
		pop	bc
		cp	2
		jr	z, CONSO
		cp	13
		jr	z, OPENR
		cp	14
		jr	z, CLOSR
		cp	15
		jr	z, OPENW	; REQU
		cp	16
		jr	z, CLOSW
		cp	20
		jr	z, READS
		cp	21
		jr	z, WRITS
		cp	33
		jp	z, RRAND
CBDOS1:		ld	bc, (0Dh)	; BCSV
		jp	0F32Bh		; Einsprung in orig. BDOS-Routine

;------------------------------------------------------------------------------
; Zeichenausgabe
;------------------------------------------------------------------------------

CONSO:		ld	a, (5Ah)
		or	a		; keine	Ausgabe (A<>0)?
		jr	z, CBDOS1	; nein: orig CONSO
		ld	b, 58h    	; ja: dann kurze Warteschleife
conso1:		djnz	conso1
		ret

;------------------------------------------------------------------------------
; Open Read
;------------------------------------------------------------------------------

OPENR:		call	0F593h		; REQU
		inc	a
		ret	c
		push	hl
		xor	a
		ld	(6Ch), a
		call	READS
		jp	0F405h		; Ende orig OPENR

;------------------------------------------------------------------------------
; Close Read
;------------------------------------------------------------------------------

CLOSR:		jp	0F42Dh		; orig. CLOSR

;------------------------------------------------------------------------------
; Read sequentiell
;------------------------------------------------------------------------------

READS:		call	RRAND
		ret	c
		ld	(DMA), hl
		ld	hl, 6Ch		; LBLNR
		inc	(hl)
		ret

;------------------------------------------------------------------------------
; Open Write
;------------------------------------------------------------------------------

OPENW:		call	0F593h		; REQU
		inc	a
		ret	c
		push	hl
		ld	a, 1		; keine	Ausgabe	bei CONSO
		ld	(5Ah), a
		ld	hl, 5Ch
		ld	(DMA), hl
		ld	a, 0
		ld	(73h), a
		ld	bc, 4000h	; langer Vorton
		xor	a
		ld	(BLNR), a	; BLNR
		ld	a, 2
		ld	(6Ch), a	; LBLNR
		call	WRIT1		; Blockschreiben
		jp	0F465h		; Ende orig. OPENW

;------------------------------------------------------------------------------
; Close Write
;------------------------------------------------------------------------------

CLOSW:		ld	a, 0FFh
		ld	(BLNR), a
		ld	c, 80h
closw1:		call	CONSO		; hier als kurze Warteschleife
		dec	c
		jr	nz, closw1
		xor	a
		ld	(5Ah), a	; Ausgabe bei CONSO wieder erlauben

;------------------------------------------------------------------------------
; Blockschreiben
;------------------------------------------------------------------------------

WRITS:		ld	bc, 10h		; Kurzer Vorton
WRIT1:		ld	de, (DMA)
		ld	a, (0EFC0h)	; MAPPI
		or	a
		jr	z, WRIT2	; kein Schreibschutz
WERR:		ld	a, 9
WERR1:		scf
		push	af
		xor	a
		ld	(5Ah), a	; Ausgabe bei CONSO wieder erlauben
		pop	af
		ret
WRIT2:		ld	hl, (36h)
		push	de
		ld	de, 7Fh
		sbc	hl, de
		pop	de
		call	0FCBCh		; COMPW
		ld	a, 10
		jr	c, WERR1
		ex	de, hl
		call	0F23Bh		; CHRAM
		jr	nc, WERR
		call	QINIT		; Interruptroutinen setzen
		call	KARAM		; Schreiben eines Blocks
		call	QEXIT		; Interruptroutinen rücksetzen
		jp	0F49Ah		; Ende des orig. WRITE

;------------------------------------------------------------------------------
; Read Random Block
;------------------------------------------------------------------------------

RRAND:		ld	hl, (36h)
		ld	de, 7Fh
		sbc	hl, de
		ld	de, (DMA)
		call	0FCBCh		; COMPW
		ld	a, 0Ah
		ret	c
		ex	de, hl
		call	0F23Bh		; CHRAM
		ld	a, 9
		jr	nc, WERR1
		push	af
RR2:		pop	af
		call	QINIT		; Interruptroutinen setzen
		call	MAREK		; Lesen	eines Blocks
		call	QEXIT		; Interruptroutinen rücksetzen
		call	0FAE3h		; INITA
		push	af
		push	hl
		ld	hl, 6Ch		; LBLNR
		ld	a, (BLNR)
		cp	(hl)
		pop	hl
		jr	c, RR2
		jp	0F506h		; Ende orig. RRAND

;------------------------------------------------------------------------------
; Interruptroutinen setzen+rücksetzen
;------------------------------------------------------------------------------

QINIT:		push	hl
		ld	hl, IKACT	; Interruptroutine zum Schreiben
		ld	(200h),	hl
		ld	hl, IKEP	; Interruptroutine zum Lesen
		jr	QEXIT1

; Interruptroutinen rücksetzen
QEXIT:
		push	hl
		ld	hl, 0FF43h	; orig. IKACT
		ld	(200h),	hl
		ld	hl, 0FFBDh	; orig. IKEP
QEXIT1:		ld	(20Ah),	hl
		pop	hl
		ret

;------------------------------------------------------------------------------
; Block schreiben
;------------------------------------------------------------------------------

; Initialisierung CTC
INIC1:		ld	a, 27h 		; Zeitgeber kein Interrupt
		out	(CTC2), a
		ld	a, 96h
		out	(CTC2), a
		ld	a, 3
		ret
		
; Schreiben eines Blocks
KARAM:		di
		exx
		ld	c, 0		; Prüfsumme
		ld	b, 80h		; Anz. Byte/Block
		ld	hl, (DMA)	; Ladeadresse
		exx
		call	INIC1		; ret: A=3
		out	(93h), a
		out	(CTC3), a
		out	(CTC0), a
		call	INIVT		; Vorton init.
KARA1:		call	AUSV		; Vorton ausgeben
		cpi			; dec BC
		jp	pe, KARA1
		ld	a, 16		; 1-Bit schreiben
		call	DYNST		; warten, bis Halbperiode ausgegeben
		ld	a, 16
		call	DYNST		; warten, bis Halbperiode ausgegeben
		ld	a, (BLNR)
		call	KAUBT		; Schreiben Blocknummer
		exx
KARA2:		ld	a, (hl)
		call	KAUBT		; Schreiben eines Bytes
		ld	a, d
		add	a, c
		ld	c, a
		inc	hl
		djnz	KARA2
		call	KAUBT		; Schreiben Prüfsumme
		call	KAUBT		; Schreiben Prüfsumme (warum 2x ???)
		di
		or	a
		ld	a, 3
		out	(CTC0), a
		ei
		ret

; Vorton init.
INIVT:		; Userport
		ld	a, 7
		out	PIO1BS, a	; SPIO1B
		ld	a, 0CFh
		out	PIO1BS, a
		ld	a, 0FBh		; 1111_1011; Bit2 = Ausgabe
		out	PIO1BS, a
		ld	a, 7
		out	PIO1BS, a
		ld	a, 4
		out	PIO1BD, a	; Bit2 := 1
		;
		ld	a, 85h
		out	(CTC0), a
		ld	a, 20		; Vorton 1
		out	(CTC0), a
		ei
		ret

;------------------------------------------------------------------------------
; Schreiben eines Bytes
;------------------------------------------------------------------------------

KAUBT:		ld	e, 8		; 8 Bit
		ld	d, a
kaubt1:		rrc	d
		jr	nc, kaubt4
; 1-Bit
		ld	a, 16
kaubt2:		or	a
		jr	nz, kaubt2
		ld	a, 16
kaubt3:		or	a
		jr	nz, kaubt3
		dec	e		; nächstes bit
		jr	nz, kaubt1
		ret
;
; 0-Bit		
kaubt4:		ld	a, 12
kaubt5:		or	a
		jr	nz, kaubt5
		ld	a, 12
kaubt6:		or	a
		jr	nz, kaubt6
		dec	e		; nächstes bit
		jr	nz, kaubt1
		ret
;
; Vorton	
AUSV:		ld	a, 20
		call	DYNST
		ld	a, 20
; warten, bis Halbperiode ausgegeben
DYNST:		or	a
		jr	nz, DYNST
		ret

;------------------------------------------------------------------------------
; Interruptroutine zum Schreiben
; wird ausgelöst, wenn alte Zeitkonstante heruntergezählt wurde
; in: A = neue Zeitkonstante
; ret: A := 0
;------------------------------------------------------------------------------

IKACT:		ex	af, af'         
		ld	a, 3
		out	(CTC0), a
		ld	a, 85h
		out	(CTC0), a
		ex	af, af'
		out	(CTC0), a	; neue Zeitkonstante
		; Userport
		in	a, PIO1BD	; Bit2 togglen
		xor	4
		out	PIO1BD, a
		xor	a
		ei
		reti

;------------------------------------------------------------------------------
; Lesen	eines Blocks
;------------------------------------------------------------------------------

MAREK:		di
		call	INIC1
		out	(93h), a	; Tastatur
		out	(CTC3), a
		out	(CTC0), a
		out	PIO1BS, a
		ld	a, 5
		out	(CTC0), a	; CTC0 zum Zeitmessen
		ld	a, 0A1h		; Startwert
		out	(CTC0), a
		; Userport
		ld	a, 0Ah		; Interruptvektor -> 20AH
		out	PIO1BS, a
		ld	a, 0CFh		; Mode 3
		out	PIO1BS, a
		ld	a, 10h		; Bit4 = Eingabe
		out	PIO1BS, a
		ld	a, 0B7h		; EI; High, Maske folgt
		out	PIO1BS, a
		ld	a, 0EFh		; Maske: Bit7 kein Interrupt
		out	PIO1BS, a
		;
		ld	hl, (DMA)
		ei
; Trennzeichen lesen
marek1:		ld	bc, 600h
marek2:		xor	a
marek3:		or	a
		jr	z, marek3
		cp	77h		; Trennzeichen gelesen?
		jr	nc, marek1
		djnz	marek2
; noch eins
marek4:		xor	a
marek5:		or	a
		jr	z, marek5
		cp	77h		; Trennzeichen gelesen?
		jr	c, marek4
;
		call	IBYTE		; Blocknummer lesen
		ld	b, 80h
		ld	(BLNR), a
MA4:		call	IBYTE		; Lesen	eines Bytes
		ld	(hl), a
		add	a, c
		ld	c, a
		inc	hl
		djnz	MA4
		call	IBYTE		; Prüfsumme lesen
		di
		cp	c
		ld	a, 3
		out	PIO1BS, a
		out	(CTC0), a
		ret	z
		scf
		ret

;------------------------------------------------------------------------------
; Interruptroutine zum Lesen
; ausgelöst von User-Port-PIO! Bit7 = 1
; ret: A := 0A1h-gezählte Zeit
;------------------------------------------------------------------------------

IKEP:		in	a, (CTC0)	
		ex	af, af'
		ld	a, 7
		out	(CTC0), a
		ld	a, 0A1h	  	; neue Zeitmessung
		out	(CTC0), a
		ex	af, af'
		ei
		reti

;------------------------------------------------------------------------------
; Lesen	eines Bytes
; ret: A=Byte
;------------------------------------------------------------------------------

IBYTE:		ld	de, 800h	; D=8 Bit; E=0
ibyte1:		xor	a
ibyte2:		or	a		; Warten auf Flanke
		jr	z, ibyte2
		cp	7Fh
		rr	e		; Cy=gelesenes Bit
		dec	d		; nächstes Bit
		jr	nz, ibyte1
		ld	a, e
		ret

;------------------------------------------------------------------------------

		end
