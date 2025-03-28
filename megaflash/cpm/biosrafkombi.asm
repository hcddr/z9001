;------------------------------------------------------------------------------
; RAM-Disk 406k / 58k f. Kombi-Modul / 64K-SRAM-Modul
; 21.04.2017 V. Pohlers
;------------------------------------------------------------------------------

	if codesec=commentsec

;------------------------------------------------------------------------------
; RAM-Disk 
;------------------------------------------------------------------------------

; Disketten-Treiber
; global genutzt currenttrack, currentsec, currentdrive	

; Code-Bereiche codesec
;	commentsec	Kommentare
;	equsec		Definitionen
;	biossec		z.b. im Shadow-RAM oder im ROM
;	ubiossec	im RAM, von CCP aus erreichbar
;	initsec		Initialisierung, Hardware-Erkennung etc.

; Der zusätzliche RAM steht leider nur in Bänken zur Verfügung. Bei einem 128K-
; SRAM stehen zwei, bei einem 512K-SRAM stehen acht Bänke zur Verfügung. 
; Ein 64K- SRAM-Modul wird leicht anders angesteuert als das Kombi-Modul. Es gibt
; genau 2 Bänke.
; 
; out 7	hi-ram an (sollte unter cp/a immer der fall sein!)
; 



klären: 
darf shadow-ram einfach zu- und weggeschaltet werden?
im minicpm: was ist mit hi-ram? Der müsste auch zugeschaltet werden.
Dann ist aber der BIOS-Code weg -> Umladeroutinen müssen in untere RAM-Page!

21.04.2017
todo: 64k sram kontrollieren. das funktioniert noch nicht ganz richtig.


	elseif codesec=biossec
;	SHARED  READ,WRITE
	
;------------------------------------------------------------------------------
; Adressen und Port-Definitionen
;------------------------------------------------------------------------------

;port 4
;port 5
;port 76h	ram bank

; 64KSRAM-Modul:
;76H	Einschalten des 1. 64K-RAM			Grundzustand
;77H	Einschalten des 2. 64K-RAM


rafkombi.codeadr	equ	0043h	; Freier Bereich
rafkombi.dma		equ	0080h

;------------------------------------------------------------------------------
; phys. Treiber
;------------------------------------------------------------------------------

;noch nicht bedacht:
;de liegt auch außerhalb des ziels
;deshalb geht das nur über 80h und weitertransport zum eigentlichen ziel :-(
;damit auch der stack etc. bleibt, darf ADRE nichts verändern

; Lesen von Diskette
rafkombi.READ:	
		;ist (currentdma) = rafkombi.dma?
		ld	hl,rafkombi.dma
		ld	de,(currentdma)
		or	a; Cy=0
		sbc	hl, de
		ld	a,h
		or	l
		jr	z, rafkombi.READ1

		;dma sichern
		ld	hl,rafkombi.dma
		ld	de,rafkombi.buf
		ld	bc, 0080h
		ldir
		CALL	rafkombi.READ1
		; ins ziel kopieren
		ld	hl, rafkombi.dma
		ld	de,(currentdma)
		ld	bc, 0080h
		ldir
		; dma rücksichern
		ld	hl,rafkombi.buf
		ld	de, rafkombi.dma
		ld	bc, 0080h
		ldir
		ret

rafkombi.READ1:	
		;(currentdma) = rafkombi.dma
		CALL	rafkombi.mvcoder
		call	rafkombi.READ0
		ret



; Schreiben auf Diskette
rafkombi.WRITE:	
		;ist (currentdma) = rafkombi.dma?
		ld	hl,rafkombi.dma
		ld	de,(currentdma)
		or	a; Cy=0
		sbc	hl, de
		ld	a,h
		or	l
		jr	z, rafkombi.WRITE1

		; dma sichern
		ld	hl, rafkombi.dma
		ld	de,rafkombi.buf	
		ld	bc, 0080h
		ldir
		; aus quelle kopieren
		ld	hl,(currentdma)
		ld	de, rafkombi.dma
		ld	bc, 0080h
		ldir
		CALL	rafkombi.WRITE1
		; dma rücksichern
		ld	hl,rafkombi.buf
		ld	de, rafkombi.dma
		ld	bc, 0080h
		ldir
		XOR	A
		ret

rafkombi.WRITE1:	
		;(currentdma) = rafkombi.dma
		CALL	rafkombi.mvcodew
		CALL	rafkombi.WRITE0
		XOR	A
		ret

rafkombi.mvcoder
		ld	hl, rafkombi.code
		ld	de, rafkombi.codeadr
		ld	bc, rafkombi.codeend-rafkombi.code
		ldir
		di
		ret

rafkombi.mvcodew
		ld	hl, rafkombi.codew
		ld	de, rafkombi.codeadr
		ld	bc, rafkombi.codeendw-rafkombi.codew
		ldir
		di
		ret

; wird nach 0043h kopiert. max bis 005Bh !!!
rafkombi.code
		phase 	rafkombi.codeadr
; Lesen
rafkombi.READ0:	CALL	rafkombi.ADRE
		out	(c),b
		out	(7),a		; hi on
		LD	BC,128
		LDIR
		xor	a		; A = 0
		out	(6), a		; hi off
		OUT	(4), A		; no shadow
		OUT	(76h), A	; ram bank 0
		ei
		RET
		dephase
rafkombi.codeend		


rafkombi.codew
		phase 	rafkombi.codeadr
; Schreiben
rafkombi.WRITE0:CALL	rafkombi.ADRE
		EX	DE,HL	
		out	(c),b
		out	(7),a		; hi on
		LD	BC,128
		LDIR
		xor	a		; A = 0
		out	(6), a		; hi off
		OUT	(4), A		; no shadow
		OUT	(76h), A	; ram bank 0
		ei
		RET
		dephase
rafkombi.codeendw		


;; bank 0 ist fürs OS, die darf nicht verwendet werden!!!
;; 		
;; zur DPB-Bildung siehe
;; http://hc-ddr.hucki.net/wiki/doku.php/cpm:write_a_bios:teil_2
;; variante 2
;; 
;; 2k spurgröße damit passt track in Register A => kleine Blockgröße :-)
;; = 2048/128 = 16 Records/track
;; 
;; track 	
;; 	00..20 bank1, no shadow (42k = 16k+16k+10k = 21 track)
;; 	21..28 bank1, shadow (16k = 8 track)
;; 
;; wenn 512k-kombi
;; 
;; 	29..40 bank2, no shadow (42k = 16k+16k+10k = 21 track)
;; 	41..49 bank2, shadow (16k = 8 track)
;; 	...
;; 	174..194 bank7, no shadow (42k = 16k+16k+10k = 21 track)
;; 	195..202 bank7, shadow (16k = 8 track)
;; 
;; 
;; also Adressrechnung:
;; 
;; bank := 1
;; while track>=29 { track -= 29; bank++ }  // 2x29=58k pro Bank insg.
;; if (track>=21) { track-=21; shadow } else {direkt} //2x21 = 42k Vordergrund-RAM
;; 

rafkombi.adre:
		ld	b,1			; bank
		ld	a,(currenttrack)	; max 202 :-)
rafkombi.adre1:	cp	29			; a-29 < 0 ? dh a < 29 ?
		jr	c, rafkombi.adre2
		sub	29
		inc	b
		jr	rafkombi.adre1
rafkombi.adre2:	cp	21	
		jr	c, rafkombi.adre4	
		sub	21
		;shadow
		out	(5),a
rafkombi.adre4:	;normal

		;b = bank
		;adr := (resttrack*16 + sektor)*128 + 4000h
		ld	h,0
		ld	l,a
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,HL
		ADD	HL,HL		; HL = Track * 10h (SPT)
		;
		LD	DE,(currentsector)
		DEC	DE		; wg. CP/A
		ADD	HL,DE		; HL := HL + Sector
		; das ganze mal 128 (Blockgröße im CPM)
		ADD	HL,HL	; *2
		ADD	HL,HL	; *4
		ADD	HL,HL	; *8
		ADD	HL,HL	; *16
		ADD	HL,HL	; *32
		ADD	HL,HL	; *64
		ADD	HL,HL	; *128 Bytes/Sektor => Offset in RAM-Disk
		ld	de,4000h
		ADD	HL,DE
		;
		;Bank b
		;;LD	DE,(currentdma)	; vorher setzen - gleich ist sie weg

		ld	a,(rafkombi.bankport)
		ld	c,a; 	76 bei kombi, 77 bei 65ksram
;;		out	(c),b
		;
		LD	DE,rafkombi.dma	; default gateway
;;		LD	BC,128
		RET
	

;------------------------------------------------------------------------------
; WBOOT
;------------------------------------------------------------------------------

rafkombi.WBOOT:	ret

;------------------------------------------------------------------------------

	elseif codesec=ubiossec
;	SHARED	DPH,DBP

;------------------------------------------------------------------------------
; RAM-Bereiche
;------------------------------------------------------------------------------

;Disk-Parameter-Header

rafkombi.bankport	db	76h
rafkombi.version	ds	1
rafkombi.bank0		ds	1
rafkombi.bank1		ds	1


rafkombi.dph:	dw	0		; XLT	translation table
		dw	0
		dw	0
		dw	0
		dw	dirbuf		; DIRBUF
		dw	rafkombi.dpb	; DPB
		dw	rafkombi.CSV	; CSV
		dw	rafkombi.ALV	; ALV

; RAM-Disk 406k
; BLS = 2048 (2K)
rafkombi.dpb:	Dw	16		; SPT	16 Sektoren/Spur
		DB	4		; BSH	= log2(blocksize/128)
		DB	15		; BLM	= 2^BSH-1
		DB	1		; EXM	8 Bit-Blocknummern
		Dw	406/2-1		; DSM	max. x Blöcke
rafkombi.rafdpb_drm:	Dw	127		; DRM	max x Dir. Einträge
		DB	0C0H		; AL0	also x Block (DRM*32/blocksize)
		DB	0		; AL1	für DIR reservieren
		Dw	0		; kein Check ....
		Dw	0		; OFF	0 reservierte Spuren
; CP/A-Erw.
  		db	80h		;kein Disketten-DPB
; VP-Erw.
  		db	0		;phys. Nummer
  		dw	rafkombi.read
  		dw	rafkombi.write

rafkombi.ALV:	db	26 dup (?)	; (DSM+1)/8
rafkombi.CSV:	equ	0		; es gibt keinen Check ....

rafkombi.buf:	db	128 dup (?)


;------------------------------------------------------------------------------

	elseif codesec=initsec
;	SHARED	BOOT,BOOTMSG

;------------------------------------------------------------------------------
; BOOT
;------------------------------------------------------------------------------

rafkombi.BOOT:	call	rafkombi.testkombi
;	1 sram-Modul
;	2 kombi-Modul 128k
;	7 kombi-Modul 512k
		ld	(rafkombi.version),a
		cp	7	;alles voreingestellt, nichts weiter zu tun
		jr	z, rafkombi.boot1
		cp	1
		jr	nz, rafkombi.boot2
		; bankport auf 77 setzen
		ld	a,77h
		ld	(rafkombi.bankport),a
rafkombi.boot2:		;kleine Ram-Disk nach dpb + offs kopieren
		ld	hl,rafkombi.dpb58
		ld	de,rafkombi.dpb+5
		ld	bc,5
		ldir
rafkombi.boot1:		;raf init
		call	rafkombi.init8
		ret

rafkombi.BOOTMSG	macro
		outradix	16
		db	rafkombi.drv,": RAM-Disk", 0Dh, 0Ah
		outradix	10
	endm

; Werte bei kleiner RAM-Disk (58k)
rafkombi.dpb58:		Dw	58/2-1		; DSM	max. x Blöcke
		Dw	63		; DRM	max x Dir. Einträge
		DB	080H		; AL0	also x Block (DRM*32/blocksize)


;;-----------------------------------------------------------------------------
; UZ-Modul-Variante herausfinden
; 64K-SRAM: OUT 76 n schaltet immer die 0. RAM-Ebene ein
; KOMBI: OUT 76 n schaltet die n-te RAM-Ebene ein
; ret a =
;	0 kein Modul
;	1 sram-Modul
;	2 kombi-Modul 128k
;	7 kombi-Modul 512k

;-----------------------------------------------------------------------------

rafkombi.testkombi:	
		di
		ld	hl,8000h
		ld	c,76h
		ld	de,0001h
		out	(c),d	; bank0
		;
		ld	a,(hl)	; Vergleichswert aus Bank 0
		ld	(rafkombi.bank0),a
		
		out	(c),e	; bank1
		ld	b,(hl)	; orig. Wert sichern
		inc	a
		ld	(hl),a	; in Bank 1 schreiben (= Bank0, wenn sram-modul)

		out	(c),d	; zurück zu bank0
		cp	(hl)	; Vergleichen (und Ergebnis merken)
		;
		jr	z,rafkombi.testsram

; Kombi-Modul
		out	(c),e	; bank1
		ld	a,b
		ld	(hl),a	; orig. Wert zurückschreiben
		ld	(rafkombi.bank1),a
		; gibt es Bank 7?  Vergleich mit Bank 1
		ld	de,0107h
		out	(c),e	; bank7
		ld	b,(hl)	; orig. Wert sichern
		inc	a
		ld	(hl),a	; in Bank 7 schreiben

		out	(c),d	; zurück zu bank1
		cp	(hl)	; Vergleichen (und Ergebnis merken)
		ex	af,af'	; wenn gleich, dann nur 1 Bank
		;
		out	(c),e	; bank7
		ld	(hl),b	; orig. Wert sichern
		out	(c),d	; bank1
		ld	a,(rafkombi.bank1)
		ld	(hl),a	; orig. Wert sichern
		;
		ld	d,0		
		out	(c),d	; bank0
		ld	a,(rafkombi.bank0)
		ld	(hl),a	; orig. Wert restaurieren
        	;
		ei
        	ex	af,af'
        	ld	a,7	; A=7 512k Kombi
		ret	nz 
		ld	a,2	; A=2 128K Kombi
		ret	
;
rafkombi.testsram:	
		out	(77h),a	; bank1
		ld	b,(hl)	; orig. Wert sichern
		CPL		; Vergleichswert negieren
		ld	(hl),a	; in Bank 1 schreiben (= Bank0, wenn sram-modul)
		out	(c),d	; bank0
		cp	(hl)	; Vergleichen (und Ergebnis merken)
		ex	af,af'
		;
		out	(77h),a	; bank1
		ld	(hl),b	; orig. Wert restaurieren
		out	(c),d	; bank0
		ld	a,(rafkombi.bank0)
		ld	(hl),a	; orig. Wert restaurieren
        	;
        	ei
        	ex	af,af'
		ld	a,1	; A=1 SRAM-modul
		ret	nz 
		ld	a,0	; A=0 kein Modul
		ret	


;------------------------------------------------------------------------------

;Test, ob RAF initialisiert
;ret Z=0 nicht init.
		
rafkombi.raftst:		call	rafkombi.rafrdsc0		; ersten Sektor lesen
		ld	hl, dirbuf		; Dir-Puffer
		ld	de, rafkombi.rafdirinit		; Vergleich auf "RAFvalid.SYS"
		ld	b, 20h
rafkombi.raftst8:	ld	a, (de)
		cp	(hl)
		ret	nz
		inc	de
		inc	hl
		djnz	rafkombi.raftst8
		ret

; ersten Sektor lesen
rafkombi.rafrdsc0:	ld	hl, dirbuf		; Dir-Puffer
		ld	(currentdma), hl
		ld	hl, 0
		ld	(currenttrack), hl
		inc	hl				; CP/A 1.Sektor = 1
		ld	(currentsector), hl
		jp	rafkombi.read


; ----------------------------

rafkombi.init8:		call	rafkombi.raftst
		ret	z
; sonst löschen
		ld	de, rafkombi.aRafIstUndefini
		ld	c, 9
		call	5
;RAF löschen
		ld	hl, dirbuf		; Dir-Puffer
		ld	(currentdma), hl
		ld	de, (rafkombi.rafdpb_drm)
		inc	de
		ld	hl, 0
rafkombi.eras1:		ld	(currenttrack), hl
		xor	a			; bei CP/A Sektor ab 1
		;ld	a,-1			; normal: Sektor zählt ab 0
rafkombi.eras2:		push	de
		inc	a
		ld	(currentsector), a
		call	rafkombi.read
		pop	de
		ld	a, d
		or	e
		jr	z, rafkombi.eras4
		ld	hl, dirbuf		; Dir-Puffer
		ld	a, 4			; 4 Entries in einem Sektor
		ld	bc, 20h			; Anzahl der Bytes, die zu überspringen sind
rafkombi.eras3:		ld	(hl), 0E5h 		; "User"-Nummer = E5  = Gelöschter Eintrag
		add	hl, bc			; Rest des Dir.-Eintrages überspringen
		dec	de
		dec	a
		jr	nz, rafkombi.eras3
rafkombi.eras4:		push	de
		call	rafkombi.write
		pop	de
		ld	a, d
		or	e
		jr	z, rafkombi.init9		; Ende
		ld	a, (currentsector)
		ld	hl, rafkombi.dpb
		cp	(hl)			; letzter Sektor erreicht?
		jr	nz, rafkombi.eras2		; nein
		ld	hl, (currenttrack)
		inc	hl
		jr	rafkombi.eras1

; Directory-Eintrag 'RAFvalid.SYS' für initialisierte RAM-Floppy
rafkombi.init9:		call	rafkombi.rafrdsc0
		ld	de, dirbuf		; Dir-Puffer
		ld	hl, rafkombi.rafdirinit
		ld	bc, 20h
		ldir
		call	rafkombi.write
;
		ret

rafkombi.aRafIstUndefini:db "RAF wird initialisiert",0Dh,0Ah,0


;------------------------------------------------------------------------------
; Directory-Eintrag für initialisierte RAM-Floppy
;------------------------------------------------------------------------------

rafkombi.rafdirinit:	db  	20h		; user 32 - wird nie angezeigt!
		db  	'R'
		db  	'A'
		db  	'F'
		db  	'v'
		db  	'a'
		db  	'l'
		db  	'i'
		db  	'd'
		db  	'S' + 80h	; FILE R/O
		db  	'Y' + 80h	; Systemfile
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
word_547:	dw 	0		; Kapazitaet


;------------------------------------------------------------------------------

	endif
	
	