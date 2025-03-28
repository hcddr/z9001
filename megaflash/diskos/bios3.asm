;-----------------------------------------------------------------------------
; Z9001-BIOS für OS-CPM Version 0.1 für RAF2008
; (c) V. Pohlers 2012
; 20.02.2012 RAF-BIOS ist ok für fixe 2MB-RAF
;-----------------------------------------------------------------------------
; CP/M-Disketten unter OS
; BIOS (nur Disk-Funktionen nötig)
; einfaches BIOS für 1 Laufwerk
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
		jp	seldsk
		jp	settrk
		jp	setsec
		jp	setdma
		jp	read
		jp	write
		jp	0F02Dh		; listst im z9001-os
		jp	sectran

;-----------------------------------------------------------------------------
; boot
;-----------------------------------------------------------------------------

boot:
		ld	a, 0
		ld	(DISKo), a	; init. Laufwerk ist 'A'

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

;-----------------------------------------------------------------------------
; home
; auf Spur 0 zurueck (vor jedem Dir-Zugriff)
;-----------------------------------------------------------------------------

home:		ld	bc, 0

;-----------------------------------------------------------------------------
; settrk
; Einstellen Spur in Reg. BC
;-----------------------------------------------------------------------------

settrk:		ld	(dtrack), bc
		ret

;-----------------------------------------------------------------------------
; Einstellen Sektor in Reg. C
;-----------------------------------------------------------------------------

setsec:		ld	(dsectr), bc
		ret

;-----------------------------------------------------------------------------
; Einstellen DMA in Reg. BC
;-----------------------------------------------------------------------------
setdma:		ld	(ddma), bc
		ret

;-----------------------------------------------------------------------------
; Uebersetzung Sektornummer
; Translate-Tab-Adr. in DE, Eingangs-Sektornummer in BC,
;			    Ausgangs-Sektornummer in HL
; Es wird keine Translate-Tabelle benutzt, da die Sektor-
; nummernverwaltung verallgemeinert im nicht-Standard-DPB
; enthalten ist (auch fuer physische Sektorlaenge <>128)
;-----------------------------------------------------------------------------
sectran:	ld	h, b
		ld	l, c
		inc	hl		;Sektoren zaehlen in CP/A ab 1
		ret


;-----------------------------------------------------------------------------
; read/write
;-----------------------------------------------------------------------------

; READ	Lesen eines Sektors
read:		call	rafread
		if ubios
		call	uread
		endif
		ret

; WRITE	Schreiben eines Sektors
write:		if ubios			; 128 Byte ausgeben
		call	uwrite
		endif
		call	rafwrite
		ret



;-----------------------------------------------------------------------------
; HL auf DPH stellen
; i C: Laufw. (0=A:, 1=B: ...)
; i E: Bit 0 ist LOGIN-Bit von BDOS (=0, wenn LOGIN)
;-----------------------------------------------------------------------------

seldsk:		ld	hl, 0
		ld	a, c
		cp	0		; nur LW a: erlaubt
		ret	nz
;
		ld	(ddrive), a
		ld	hl, rafdph
		ret

; aktueller DPH
rafdph:		dw 	0
		dw 	0
		dw 	0
		dw 	0
		dw 	dirbuf		; Dir-Puffer
		dw 	rafdpb
		dw 	0
		dw 	alv0

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
; BIOS-RAM
;-----------------------------------------------------------------------------

ddrive:		db	0
dtrack:		dw	? 		;Seite
dsectr:		dw	? 		;Sektor

ALV0:		db	128 dup (?)
CSV0:		db	128 dup (?)

;; im UBIOS
;;ddma:		dw	?		; aktuelle DMA-Adresse
;;dirbuf:	db	128 dup (?)	; Bereich 128 Byte


biosend:	equ	$

		db	0		; damit bin-Code erzeugt wird

;-----------------------------------------------------------------------------

	endsection
