;-----------------------------------------------------------------------------
; Z9001-BIOS für OS-CPM Version 0.2 für RAF2008 + Floppy
; (c) V. Pohlers 2012
; 20.02.2012 RAF-BIOS ist ok für fixe 2MB-RAF
; 191118 Bedeutung+Bezeichnung CFDC und DFDC waren vertauscht
; 200316 aktuelles Laufwerk beibehalten (bei BOOT via Ctrl-C)
;-----------------------------------------------------------------------------
; CP/M-Disketten unter OS
; BIOS (nur Disk-Funktionen nötig)
; einfaches BIOS für 3 Laufwerke 2xFloppy+RAF2008
;------------------------------------------------------------------------------


		cpu	z80


	section bios

;werden extern festgelegt:
;;BDOS       	equ	04006h		; base of bdos
;;DISKA		equ	BDOS+00DE8h	; Boot-LW f. BDOS Func. 13 INIT 
;;DISKo
;;ubios		equ	1		; 1 = Transport über UBIOS (ureasd, uwrite)

;-----------------------------------------------------------------------------
; RAF2008

rafport		equ	20h		; Port
rafdrv		equ	'P'

;-----------------------------------------------------------------------------
; BIOS-Eintrittspunkt
;-----------------------------------------------------------------------------

;;		org	04E00h

		jp	boot		; boot im Loadbereich 8000h ff.
		jp	wboot
		jp	0F006h		; const im upper bios
		jp	0F009h		; conin im z9001-os
		jp	0F00Ch		; Ausgabe Zeichen zu CONST
		jp	0F00Fh		; list im z9001-os
		jp	0F012h		; punch im z9001-os
		jp	0F015h		; reader im z9001-os
		jp	home
		jp	b_seldsk
		jp	settrk
		jp	setsec
		jp	setdma
		jp	b_read
		jp	b_write
		jp	0F02Dh		; listst im z9001-os
		jp	sectran

;-----------------------------------------------------------------------------
; boot
;-----------------------------------------------------------------------------

boot:
		ld	hl, DISKO
		ld	a, (hl)
		cp	0FFh
		jr	nz,boot0
		
		ld	a, rafdrv-'A'
		ld	(DISKo), a	; init. Laufwerk ist 'M'

boot0:		call	binit		; LW init.

		ld	a,(DISKo)
		add	a,'A'
		ld	(boot_txt2),a	;curent drive

		ld	de, boot_txt
		ld	c, 9
		call	bdos


;-----------------------------------------------------------------------------
; wboot
;-----------------------------------------------------------------------------

wboot:		ld	c, 13		; init	Laufwerk + DMA
		call	bdos		; 
		ld	a,(DISKo)	; initial disk aus BDOS 0004
		ld	e,a
		ld	c, 14		; select
		call	bdos		; 
		ret


boot_txt	db	"  A:, B: Floppy", 0dh, 0ah
		db	"  ",rafdrv,":     RAF2008", 0dh, 0ah
		db	"current drive: "
boot_txt2:	db	'?', 0dh, 0ah
		db	'$'

;;;-----------------------------------------------------------------------------
;;; home
;;; auf Spur 0 zurueck (vor jedem Dir-Zugriff)
;;;-----------------------------------------------------------------------------
;;
;;home:		ld	bc, 0
;;
;;;-----------------------------------------------------------------------------
;;; settrk
;;; Einstellen Spur in Reg. BC
;;;-----------------------------------------------------------------------------
;;
;;settrk:		ld	(dtrack), bc
;;		ret
;;
;;;-----------------------------------------------------------------------------
;;; Einstellen Sektor in Reg. C
;;;-----------------------------------------------------------------------------
;;
;;setsec:		ld	(dsectr), bc
;;		ret
;;
;;;-----------------------------------------------------------------------------
;;; Einstellen DMA in Reg. BC
;;;-----------------------------------------------------------------------------
;;setdma:		ld	(ddma), bc
;;		ret
;;
;;;-----------------------------------------------------------------------------
;;; Uebersetzung Sektornummer
;;; Translate-Tab-Adr. in DE, Eingangs-Sektornummer in BC,
;;;			    Ausgangs-Sektornummer in HL
;;; Es wird keine Translate-Tabelle benutzt, da die Sektor-
;;; nummernverwaltung verallgemeinert im nicht-Standard-DPB
;;; enthalten ist (auch fuer physische Sektorlaenge <>128)
;;;-----------------------------------------------------------------------------
;;sectran:	ld	h, b
;;		ld	l, c
;;		inc	hl		;Sektoren zaehlen in CP/A ab 1
;;		ret
;;

;-----------------------------------------------------------------------------
; read/write
;-----------------------------------------------------------------------------

; READ	Lesen eines Sektors
b_read:		ld	a,(ddrive)
		cp	rafdrv-'A'		; RAF ?
		jr	nz, b_read1
		call	rafread
		jr	b_read2
b_read1		call	read		; Floppy
b_read2:	if ubios
		call	uread
		endif
		ret

; WRITE	Schreiben eines Sektors
b_write:	if ubios			; 128 Byte ausgeben
		push	bc			; c sichern
		call	uwrite
		pop	bc
		endif
		ld	a,(ddrive)
		cp	rafdrv-'A'		; RAF ?
		jr	nz, b_write1
		call	rafwrite
		jr	b_write2
b_write1	call	write		; Floppy
b_write2	ret

;-----------------------------------------------------------------------------
; HL auf DPH stellen
; i C: Laufw. (0=A:, 1=B: ...)
; i E: Bit 0 ist LOGIN-Bit von BDOS (=0, wenn LOGIN)
;-----------------------------------------------------------------------------

b_seldsk:	ld	a, c
		CP	rafdrv-'A'		; Laufwerk M ?
		jp	nz,seldsk	; nein: Suche über Floppy-Laufwerk
		LD	HL, rafdph	; ja: RAF2008
		ld	(ddrive), a
		RET	

;-----------------------------------------------------------------------------
; RAF2008-Treiber
;-----------------------------------------------------------------------------

; aktueller DPH
rafdph:		dw 	0
		dw 	0
		dw 	0
		dw 	0
		dw 	dirbuf		; Dir-Puffer
		dw 	rafdpb
		dw 	0
		dw 	alvM

; aktueller DPB
; 2048 K / 512 x 4K BLS
rafdpb:		dw 	80h		; SPT	Sektoren/Spur
rafdpb_bsh:	db 	5            	; BSH	= log2(blocksize/128)
		db 	1Fh          	; BLM	= 2^BSH-1
		db 	1            	; EXM
rafdpb_dsm:	dw 	01FFh         	; DSM	max. Blockanzahl-1
rafdpb_drm:	dw 	01FFh          	; DRM	max. Dir. Einträge-1
		db 	0F0h   		; AL0
		db 	0            	; AL1
		dw 	0            	; CKS	= (DRM+1)/4
		dw 	0            	; OFF	reservierte Spuren

; Merkzellen für Vorhandensein von max. 4 RAM-Floppies
rafsztab:	db    	80			; Speicherkapazität RAF 0 in 16K-Einheiten
		db    	0			; Speicherkapazität RAF 1 in 16K-Einheiten
		db    	0			; Speicherkapazität RAF 2 in 16K-Einheiten
		db    	0			; Speicherkapazität RAF 3 in 16K-Einheiten

;-----------------------------------------------------------------------------
; Lesen Sektor
;-----------------------------------------------------------------------------
; Schreiben Sektor
; Register C (vom BDOS gestellt):
;	=0, wenn normales write
;	=1, wenn directory-write (sofort ausgeben)
;	=2, wenn Beginn eines neuen Datenblocks (kein preread)
;-----------------------------------------------------------------------------

; READ	Lesen eines Sektors
rafread:	call	raftrs		; Track und Sektorregister laden
		inir			; Daten-Input,  B war 7fh
		ini			; 128. Byte lesen
p_rread1:	inc	c		; c=ctrl-Port
		ld	b, 0FFh		; Zugriffsschutz-Bit 7 = 1
		out	(c), b		; Zugriffsschutz wieder setzen (I/O-Disable)
		ret

; WRITE	Schreiben eines Sektors
rafwrite:	call	raftrs
		inc	b		; war 127 fuer READ, WRITE braucht 128 !
		otir			; 128 Byte ausgeben
		jr	p_rread1

; RAF-Addresse berechnen
; RAFTRS initialisiert die Track- und Sektor-Register zum Datenzugriff und 
; setzt den Zugriffsschutz zurueck.
; Die Read- und Write-Routinen sind dann einfache Block-I/O-Uebertragungen,
; mit anschliessendem Setzen des Zugriffsschutzes.

raftrs:		ld	hl, rafsztab-1	; Tabelle 
		ld	de, (dtrack)
		ld	c, rafport-2
		ld	a, e
raftrs1:	inc	c
		inc	c
		inc	hl
		sub	(hl)
		jr	nc, raftrs1
		dec	d
		jr	z, raftrs1
		add	a, (hl)
		ld	b, a
		ld	a, (dsectr)	; a=(SECTOR)
		dec	a		; RAF zählt Sektoren 0..255;  BIOS 1..256
		if ubios
		ld	hl, biosbuf	; hl=DMA-Adresse f. Block IO
		else
		ld	hl, (ddma)	; hl=DMA-Adresse f. Block IO
		endif
;
raftrs2:	add	a, a		; SECTOR Shift left, D0 = 0, evtl set carry
		srl	b		; shift right, 0->D7 , D0->carry
		rra			; SECTOR shift right, carry->D7, D0->carry
		inc	c		; Setzen Control Port
		out	(c), a		; Zugriff auf Control Port, a=Sektornummer
		dec	c		; Setzen Daten Port
		ld	b, 127		; fuer 128 Bytes Lesen (INIR + 1 x INI, 
					; bei OTIR B:=B+1 vor Schreiben notwendig)
		xor	a		; a = 00, Z = "No-Error"-Flag zu BIOS-RD/WR
		ret


;-----------------------------------------------------------------------------
; Floppy-Treiber
;-----------------------------------------------------------------------------
		
BIOSVER 	equ 'CPMZ9OK'
FDCPORTS 	equ 'ROBOTRON'		
		
		include	biosdsk.asm
		include	biosfdc.asm

; Initialisierung FDC
binit:		ld	a, 20h		; 0010 0000 FDC	Reset
		out	(FDCZ),	a
		ld	a, 13h		; 0001 0011 Terminal Count aktivieren, Motor LW	1+2 an
		out	(FDCZ),	a
;
binit1:		ld	b, 0		;INITIALISIERUNG P8272
binit2:		djnz	binit2
		in	a, (CFDC)
		cp	80h
		jr	z, binit4
		in	a, (DFDC)
binit3:		jr	binit1
;
stab:
		db  	11101111b	;XXXX=Schrittratenzeit SRT,XXXX= Kopfladezeit HUT
		db  	00111111b	;XXXXXXX=Kopfladezeit HLT,X=no dma ND
;
binit4:		ld	hl, stab-1	;PARAMETER LADEN
		ld	bc, 303h	;SPECIFY-COMM 3BYTES
		call	wcom1		;SCHREIBEN COMM
		xor	a
		ld	(UNIT), a
		ld	(dFDCZ1), a
		call	recal2
		call	sds
		bit	4, a
		ld	a, 1
		jr	z, binit5
		ld	(dFDCZ1), a
binit5:		ld	(UNIT), a
		call	recal2
		call	sds
		bit	4, a
		ld	a, (dFDCZ1)
		jr	z, binit6
		or	2
		ld	(dFDCZ1), a
binit6:		out	(FDCZ), a	; ZusatzRegister FDC schreiben
		ret

;-----------------------------------------------------------------------------
; BIOS-RAM
;-----------------------------------------------------------------------------

;;ddrive:		db	0
;;dtrack:		dw	? 		;Seite
;;dsectr:		dw	? 		;Sektor

ALVM:		db	128 dup (?)
;CSVM:		db	128 dup (?)

;; im UBIOS
;;ddma:		dw	?		; aktuelle DMA-Adresse
;;dirbuf:	db	128 dup (?)	; Bereich 128 Byte

ALV0:		db	50 dup (?)	;0E52Dh			= DSM/8+1 = 399/8+1 = 50
CSV0:		db	64 dup (?)	;0E55Fh			= ? eigentlich CKS (also 48)
ALV1:		db	50 dup (?)	;0E59Fh
CSV1:		db	64 dup (?)	;0E5D1h


biosend:	equ	$

		db	0		; damit bin-Code erzeugt wird

;-----------------------------------------------------------------------------

fdcbuffer:	ds	1024		; Buffer für FDC-IO-Operation (1K)


	endsection
