;------------------------------------------------------------------------------
; RAF-2008
;------------------------------------------------------------------------------


	if codesec=commentsec

;------------------------------------------------------------------------------
; RAM-Disk  RAF 2008
; Akademie der Wissenschaften, rfe 4/1987, S. 268, Enrico Grämer als RAF2008 
; http://www.robotrontechnik.de/index.htm?/html/eigenbau/raf2008.htm
;------------------------------------------------------------------------------
                                                                                                                                                                               
; Raf_C = RAF-Control Port zum Laden der Track- & Sector-Adresse „HiAdr“ 
; via D-bus 0…7 und A-bus 8…14 (B-Reg).                                                                   ;
; Raf_D = RAF-Data-I/O Port zum Schreiben/Lesen von max. 128 zusammenhängenden 
; Bytes mit einem INIR-/OTIR-Befehl mit einem 7-bit Byte-Index „LoAdr“ auf dem 
; A-bus 8…14 (B-Reg)
; 
;                :-----  Vollständige 19 bit RAM-Adresse (1 RAF 512)  ------:
;     22 21 20 19:18 17 16 15   14 13 12 11 10  9  8  7: 6  5  4  3  2  1  0:
;                :                                     :                    :
;     15 14 13 12:11 10  9  8    7  6  5  4  3  2  1  0:                    :
;    +--+--+--+--+--+--+--+--+ +--+--+--+--+--+--+--+--+                    :
;    !       B-Register      ! !       r-Register      !                    :
;    +--+--+--+--+--+--+--+--+_+--+--+--+--+--+--+--+--+                    :
;      ! !!!!!  !    _________!_________              7: 6  5  4  3  2  1  0:
;      ! für    !    ! OUT(C),r-Befehl !            +--+--+--+--+--+--+--+--+ 
;      ! >512k  !    !__auf_Ctrl-Adr___!            !//:  B-Reg (INIR/OTIR) ! 
;      !        !                                   +--+--+--+--+--+--+--+--+ 
;      !        AOV                                   __________!__________
;      !        Adressüberlauf-Bit (RAF 512)          ! oberer Adr.bus in !
;      !              (Bit 10 bei RAF 128)            ! INIR-/OTIR-Befehl !
;      PROT                                           !______(7_bit)______!
;      Zugriffsschutz-Bit (1=geschützt) 
; 
; 
; Disketten-Treiber
; global genutzt currenttrack, currentsec, currentdrive	

; Code-Bereiche codesec
;	commentsec	Kommentare
;	equsec		Definitionen
;	biossec		z.b. im Shadow-RAM oder im ROM
;	ubiossec	im RAM, von CCP aus erreichbar
;	initsec		Initialisierung, Hardware-Erkennung etc.



	elseif codesec=biossec
;	SHARED  READ,WRITE
	
;------------------------------------------------------------------------------
; Adressen und Port-Definitionen
;------------------------------------------------------------------------------

lw		equ	'P'			; Laufwerksbuchstabe
rafport		equ	20h			; Port
anz_raf		equ	2			; max. Anzahl unterstützter RAF

;------------------------------------------------------------------------------
; phys. Treiber
;------------------------------------------------------------------------------

; READ	Lesen eines Sektors
p_rread:	call	raftrs			; Track und Sektorregister laden
		inir				; Daten-Input,  B war 7fh
		ini				; 128. Byte lesen
p_rread1:	inc	c			; c=ctrl-Port
		ld	b, 0FFh			; Zugriffsschutz-Bit 7 = 1
		out	(c), b			; Zugriffsschutz wieder setzen (I/O-Disable)
		ret

; WRITE	Schreiben eines Sektors
p_rwrite:	call	raftrs
		inc	b			; war 127 fuer READ, WRITE braucht 128 !
		otir				; 128 Byte ausgeben
		jr	p_rread1

; RAF-Addresse berechnen
; RAFTRS initialisiert die Track- und Sektor-Register zum Datenzugriff und
; setzt den Zugriffsschutz zurueck.
; Die Read- und Write-Routinen sind dann einfache Block-I/O-Uebertragungen,
; mit anschliessendem Setzen des Zugriffsschutzes.

raftrs:		ld	hl, rafsztab-1
		ld	de, (currenttrack)
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
		;
		ld	a, (currentsec)		; a=(SECTOR)
		dec	a			; RAF zählt Sektoren 0..255;  BIOS 1..256
		ld	hl, (currentdma)	; hl=DMA-Adresse f. Block IO
;
raftrs2:	add	a, a			; SECTOR Shift left, D0 = 0, evtl set carry
		srl	b			; shift right, 0->D7 , D0->carry
		rra				; SECTOR shift right, carry->D7, D0->carry
		inc	c			; Setzen Control Port
		out	(c), a			; Zugriff auf Control Port, a=Sektornummer
		dec	c			; Setzen Daten Port
		ld	b, 127			; fuer 128 Bytes Lesen (INIR + 1 x INI,
						; bei OTIR B:=B+1 vor Schreiben notwendig)
		xor	a			; a = 00, Z = "No-Error"-Flag zu BIOS-RD/WR
		ret


;------------------------------------------------------------------------------
; WBOOT
;------------------------------------------------------------------------------

raf2008.WBOOT:	ret

;------------------------------------------------------------------------------

	elseif codesec=ubiossec
;	SHARED	DPH,DBP

;------------------------------------------------------------------------------
; RAM-Bereiche
;------------------------------------------------------------------------------

; aktueller DPH
rafdph:		dw 	0
		dw 	0
		dw 	0
		dw 	0
		dw 	dirbuf		; Dir-Puffer
		dw 	rafdpb
		dw 	0
		dw 	rafalv

; aktueller DPB
rafdpb:		dw 	80h			; SPT	Sektoren/Spur
rafdpb_bsh:	db 	4            		; BSH	= log2(blocksize/128)
		db 	0Fh          		; BLM	= 2^BSH-1
		db 	1            		; EXM
rafdpb_dsm:	dw 	0FFh         		; DSM	max. Blockanzahl-1
rafdpb_drm:	dw 	7Fh          		; DRM	max. Dir. Einträge-1
		db 	0C0h     			; AL0
		db 	0            		; AL1
		dw 	0            		; CKS	= (DRM+1)/4
		dw 	0            		; OFF	reservierte Spuren
; CP/A-Erw.
  		db	80h		;kein Disketten-DPB
; VP-Erw.
  		db	0		;phys. Nummer
  		dw	p_rread
  		dw	p_rwrite


rafalv:		ds  	128,0			; Allocation Bit Map

; Merkzellen für Vorhandensein von max. 4 RAM-Floppies
rafsztab:	db    	0			; Speicherkapazität RAF 0 in 16K-Einheiten
		db    	0			; Speicherkapazität RAF 1 in 16K-Einheiten
		db    	0			; Speicherkapazität RAF 2 in 16K-Einheiten
		db    	0			; Speicherkapazität RAF 3 in 16K-Einheiten


;------------------------------------------------------------------------------

	elseif codesec=initsec
;	SHARED	BOOT,BOOTMSG

;------------------------------------------------------------------------------
; BOOT
;------------------------------------------------------------------------------

BOOT:		call	raftst	
		RET	Z		; keine RAF vorhanden

		push	af			; Cy sichern
		push	de
		ld	de, aRafGesamtkapaz 	; "RAF-Gesamtkapazitaet $"
		ld	c, 9
		call	5
		pop	hl
		call	hldez			; HL dezimal ausgeben
		ld	de, aKBytes		; "K Bytes ($"
		ld	c, 9
		call	5
		ld	de, aRafIstNochWieB 	; "RAF ist noch wie	bei letzter Benutzung "...
		jp	nc, init10		; wenn nicht initialisiert
		ld	de, aRafIstUndefini 	; "RAF ist undefiniert, es folgt Loeschen "...
		ld	c, 9
		call	5
;RAF löschen
		ld	hl, rafdirbuf		; Dir-Puffer
		ld	(dbdma), hl
		ld	de, (rafdpb_drm)
		inc	de
		ld	hl, 0
eras1:		ld	(dtrack), hl
		xor	a
eras2:		push	de
		inc	a
		ld	(dsectr), a
		ld	de, aGspur		; "ƒSpur $"
		ld	c, 9
		call	5
		ld	hl, (dtrack)
		call	hldez			; HL dezimal ausgeben
		ld	de, aSektor		; ", Sektor \x16$"
		ld	c, 9
		call	5
		ld	hl, (dsectr)
		ld	h, 0
		call	hldez			; HL dezimal ausgeben
		call	p_rread
		pop	de
		ld	a, d
		or	e
		jr	z, eras4
		ld	hl, rafdirbuf		; Dir-Puffer
		ld	a, 4			; 4 Entries in einem Sektor
		ld	bc, 20h			; Anzahl der Bytes, die zu überspringen sind
eras3:		ld	(hl), 0E5h 		; "User"-Nummer = E5  = Gelöschter Eintrag
		add	hl, bc			; Rest des Dir.-Eintrages überspringen
		dec	de
		dec	a
		jr	nz, eras3
eras4:		push	de
		call	p_rwrite
		ld	de, aCR			; "\r$"
		ld	c, 9
		call	5
		pop	de
		ld	a, d
		or	e
		jr	z, init9		; Ende
		ld	a, (dsectr)
		ld	hl, rafdpb
		cp	(hl)			; letzter Sektor erreicht?
		jr	nz, eras2		; nein
		ld	hl, (dtrack)
		inc	hl
		jr	eras1

; Directory-Eintrag 'RAFvalid.SYS' für initialisierte RAM-Floppy
init9:		call	rafrdsc0
		ld	de, rafdirbuf		; Dir-Puffer
		ld	hl, rafdirinit
		ld	bc, 20h
		ldir
		call	p_rwrite
;
		ld	de, aV			; "‚\r\n$"
init10:		ld	c, 9
		call	5

		ld	de, aRafAlsLaufwerk 	; "RAF als Laufwerk	O: installiert\r\n$"
		ld	c, 9
		call	5
		
		ret


aRafAlsLaufwerk:db 'RAF als Laufwerk ',lw,': installiert',0Dh,0Ah,'$'
aRafGesamtkapaz:db 'RAF-Gesamtkapazitaet $'
aKBytes:	db 'K Bytes ($'
aSpurenZu128Sek:db ' Spuren zu 128 Sektoren)',0Dh,0Ah,'$'
aLaufwerkOIstSc:db 'Laufwerk ',lw,': ist schon installiert!',7,0Dh,0Ah,'$'
aRafIstNochWieB:db 'RAF ist noch wie bei letzter Benutzung geladen!',0Dh,0Ah,'$'
aRafIstUndefini:db 'RAF ist undefiniert, es folgt Loeschen Directory',0Dh,0Ah,'$'
aGspur:		db 83h,'Spur $'
aSektor:	db ', Sektor ',16h,'$'
aCR:		db 0Dh,'$'
aV:		db 82h,0Dh,0Ah,'$'

;------------------------------------------------------------------------------
; HL dezimal ausgeben
;------------------------------------------------------------------------------

hldez:		push	hl
		ld	c, 0
		ld	de, -10000
		call	hldez1
		ld	de, -1000
		call	hldez1
		ld	de, -100
		call	hldez1
		ld	de, -10
		call	hldez1
		ld	a, l
		or	30h 			; '0'
		pop	hl
		jr	hldez2
hldez1:		call	hldez3
		ret	z
hldez2:		push	bc
		push	hl
		ld	e, a
		ld	c, 2
		call	5
		pop	hl
		pop	bc
		ret
;
hldez3:		ld	a, 2Fh			; "0'-1
hldez4:		inc	a
		add	hl, de
		jr	c, hldez4
		sbc	hl, de
		inc	c
		cp	'0'
		ret	nz
		dec	c
		ret

;------------------------------------------------------------------------------
; Testen auf RAM-Floppies
; Ermitteln der Einzel- und Gesamtkapazität
; Test, ob initialisiert
; ret: z=1 keine RAF
;      cy=1 RAF nicht init
;------------------------------------------------------------------------------

raftst:		ld	hl, rafsztab		; Tabelle der Speicherkapazitäten
		ld	de, 0			; de = Gesamtkapazität aller RAFs
		ld	bc, anz_raf*100h+rafport; C=RAF-Port, B=anz_raf
raftst1:	push	bc
		push	hl
		ld	b, 0
		; Test auf Speicher
raftst2:	push	bc			
		xor	a
		call	raftrs2
		ld	a, 5Ah
		in	l, (c)			; orig. Wert sichern
		out	(c), a			; B = RAF-Adr. Bit 21..14
		dec	b
		cpl
		in	h, (c)			; orig. Wert sichern
		out	(c), a			; CPL
		inc	b
		in	a, (c)
		cp	5Ah
		out	(c), l			; orig. Wert restaurieren
		jr	nz, raftst3
		dec	b
		in	a, (c)
		cp	0A5h			; == cpl 5A
		out	(c), h			; orig. Wert restaurieren
		jr	nz, raftst3
		pop	bc
		inc	b			; nächste 16k-Einheit
		jr	nz, raftst2		; max bis B=FFh
		push	bc
		;
raftst3:	pop	bc
		ld	a, b			; a = b = Speicherkapazität in 16k-Einheiten
		ld	b, 0FFh			; Schreibschutz ein
		inc	c
		out	(c), b
		;
		pop	hl
		ld	(hl), a
		add	a, e
		ld	e, a
		ld	a, 0
		adc	a, d
		ld	d, a			; de = Gesamtkapazität aller RAFs in 32K
		pop	bc
		inc	hl			; nächste Merkzelle für Kapazität
		inc	c
		inc	c			; nächste RAF testen
		djnz	raftst1			; bis anz_raf RAFs getestet
		;
		ld	a, d
		or	e
		ret	z			; wenn Gesamtkapazität = 0, d.h. keine RAF

		push	de
		push	af
		ex	de, hl			; Gesamtkapazität in 16k-Einheiten
		add	hl, hl			; * 2
		add	hl, hl			; * 4
		add	hl, hl			; * 8
		add	hl, hl			; * 16
		ex	de, hl			; de = de * 16 = Gesamtkapazität in KByte
		push	de
		;
		ld	hl, dbplist
		ld	bc, 0Fh			; Länge pro Eintrag in dbplist
raftst4:	ld	a, (hl)
		inc	hl
		sub	e
		ld	a, (hl)
		inc	hl
		sbc	a, d			; Kapazität >= de?
		jr	nc, raftst5		; ja: gefundener Eintrag ist groß genug
		add	hl, bc
		jr	raftst4
		;
raftst5:	push	de
		ld	de, rafdpb
		ldir				; gefundenen Eintrag nach rafdpb kopieren
		;Anpassen des DPB
		pop	hl
;;		ld	(word_547), hl		; Gesamt-Kapazität in KB
		ld	a, (rafdpb_bsh)
		sub	3
		jr	z, raftst7
		ld	b, a
raftst6:	srl	h
		rr	l
		djnz	raftst6
raftst7:	dec	hl
		ld	(rafdpb_dsm), hl	; DSM anpassen
		;Test, ob RAF initialisiert
		call	rafrdsc0		; ersten Sektor lesen
		ld	hl, rafdirbuf		; Dir-Puffer
		ld	de, rafdirinit		; Vergleich auf "RAFvalid.SYS"
		ld	b, 20h
raftst8:	ld	a, (de)
		cp	(hl)
		jr	nz, raftst9
		inc	de
		inc	hl
		djnz	raftst8
		jr	raftst10
raftst9:	pop	de
		pop	af
		scf				; nicht init.
		push	af
		push	de
raftst10:	pop	de
		pop	af
		pop	hl
		ret

; ersten Sektor lesen
rafrdsc0:	ld	hl, dirbuf		; Dir-Puffer
		ld	(currentdma), hl
		ld	hl, 0
		ld	(currenttrack), hl
		inc	hl
		ld	(currentsec), hl
		jp	p_rread

;------------------------------------------------------------------------------
; Directory-Eintrag für initialisierte RAM-Floppy
;------------------------------------------------------------------------------

rafdirinit:	db  	20h
		db  	'R'
		db  	'A'
		db  	'F'
		db  	'v'
		db  	'a'
		db  	'l'
		db  	'i'
		db  	'd'
		db  	'S' + 80h
		db  	'Y' + 80h
		db  	'S'
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
		db    	0
;

;;word_547:	dw 	0

;------------------------------------------------------------------------------
; dbp-Liste, im Vergleich zu normalen DPB steht hier am Anfang noch die Größe
;------------------------------------------------------------------------------


dbplist:
; 64 x 1K (DSM x BLS = Kapazizät)
		dw  0040h	; Größe in KByte
		dw  80h		; SPT	Sektoren/Spur
		db    3		; BSH	= log2(blocksize/128)
		db    7		; BLM	= 2^BSH-1
		db    0		; EXM
		dw  3Fh		; DSM	max. Blockanzahl-1
		dw  1Fh		; DRM	max. Dir. Einträge-1
		db  80h		; AL0
		db    0		; AL1
		dw    0		; CKS	= (DRM+1)/4
		dw    0		; OFF	reservierte Spuren
; 128 x 1K
		dw  0080h	; Größe in KByte
		dw  80h		; SPT	Sektoren/Spur
		db    3		; BSH	= log2(blocksize/128)
		db    7		; BLM	= 2^BSH-1
		db    0		; EXM
		dw  7Fh		; DSM	max. Blockanzahl-1
		dw  3Fh		; DRM	max. Dir. Einträge-1
		db 0C0h		; AL0
		db    0		; AL1
		dw    0		; CKS	= (DRM+1)/4
		dw    0		; OFF	reservierte Spuren
; 128 x 2K
		dw  0100h	; Größe in KByte
		dw  80h		; SPT	Sektoren/Spur
		db    4		; BSH	= log2(blocksize/128)
		db  0Fh		; BLM	= 2^BSH-1
		db    1		; EXM
		dw  7Fh		; DSM	max. Blockanzahl-1
		dw  7Fh		; DRM	max. Dir. Einträge-1
		db 0C0h		; AL0
		db    0		; AL1
		dw    0		; CKS	= (DRM+1)/4
		dw    0		; OFF	reservierte Spuren
; 256 x 2K
		dw  0200h	; Größe in KByte
		dw  80h		; SPT	Sektoren/Spur
		db    4		; BSH	= log2(blocksize/128)
		db  0Fh		; BLM	= 2^BSH-1
		db    1		; EXM
		dw 0FFh		; DSM	max. Blockanzahl-1
		dw  7Fh		; DRM	max. Dir. Einträge-1
		db 0C0h		; AL0
		db    0		; AL1
		dw    0		; CKS	= (DRM+1)/4
		dw    0		; OFF	reservierte Spuren
; 512 x 2K
		dw  0400h	; Größe in KByte
		dw  80h		; SPT	Sektoren/Spur
		db    4		; BSH	= log2(blocksize/128)
		db  0Fh		; BLM	= 2^BSH-1
		db    0		; EXM
		dw 01FFh	; DSM	max. Blockanzahl-1    h
		dw 0FFh		; DRM	max. Dir. Einträge-1
		db 0F0h		; AL0
		db    0		; AL1
		dw    0		; CKS	= (DRM+1)/4
		dw    0		; OFF	reservierte Spuren
; 1024 x 4K
		dw  1000h	; Größe in KByte
		dw  80h		; SPT	Sektoren/Spur
		db    5		; BSH	= log2(blocksize/128)
		db  1Fh		; BLM	= 2^BSH-1
		db    1		; EXM
		dw 03FFh	; DSM	max. Blockanzahl-1    h
		dw 01FFh	; DRM	max. Dir. Einträge-1  h
		db 0F0h		; AL0
		db    0		; AL1
		dw    0		; CKS	= (DRM+1)/4
		dw    0		; OFF	reservierte Spuren
; 1024 x 8K
		dw  2000h	; Größe in KByte
		dw  80h		; SPT	Sektoren/Spur
		db    6		; BSH	= log2(blocksize/128)
		db  3Fh		; BLM	= 2^BSH-1
		db    3		; EXM
		dw 03FFh	; DSM	max. Blockanzahl-1    h
		dw 01FFh	; DRM	max. Dir. Einträge-1  h
		db  80h		; AL0
		db    0		; AL1
		dw    0		; CKS	= (DRM+1)/4
		dw    0		; OFF	reservierte Spuren



raf2008.BOOTMSG	macro
		db	raf2008.drv,": RAF-2008 RAM-Floppy", 0Dh, 0Ah
	endm

;------------------------------------------------------------------------------

	endif
	
	