;------------------------------------------------------------------------------
; RAM-Disk f. Mini-CPM
;------------------------------------------------------------------------------


	if codesec=commentsec

;------------------------------------------------------------------------------
; kleine RAM-Disk 6K
; RAM-Disk: 8 SPT x 128 HSEC x 6 TRK
;
; Blockl‰nge ist 512 Byte. Das ist in CP/M nicht deklariert, funktioniert aber
; und spart RAM-Speicher. 256 Byte oder gar 128 Byte funktionieren leider nicht.
;------------------------------------------------------------------------------


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

rafmini.RDSK:		equ	0A800h		; RAM-Disk
rafmini.RDSKEND:	equ	0BFFFh

;------------------------------------------------------------------------------
; phys. Treiber
;------------------------------------------------------------------------------

rafmini.READ:	CALL	rafmini.RADR
		RET	C
		LD	DE, (currentdma)
		Jr	rafmini.WRIT1
        	
rafmini.WRITE:		CALL	rafmini.RADR
		RET	C
		EX	DE, HL
		LD	HL, (currentdma)
rafmini.WRIT1:	LD	BC, 128
		LDIR
		XOR	A
		RET

;Berechnung Adresse
rafmini.RADR:	LD	HL, (currenttrack)	; HL = aktuelle Spur oder Track
		LD	BC, (currentsector)	; C = aktueller Sector
		ADD	HL, HL
		ADD	HL, HL
		ADD	HL, HL			; *8 Sectors/Track
		; HL = Sectors/Track * Track = Basis-Sektor currenttrack
		; addiere den aktuellen Sector hinzu ... BC , b vorher auf 0 runter gez‰hlt
		ADD	HL,BC	; B=0; HL = Basis-Sektor currenttrack + currentsector
		; das ganze mal 128 (Blockgrˆﬂe im CPM)
		ADD	HL,HL	; *2
		ADD	HL,HL	; *4
		ADD	HL,HL	; *8
		ADD	HL,HL	; *16
		ADD	HL,HL	; *32
		ADD	HL,HL	; *64
		ADD	HL,HL	; *128 Bytes/Sektor => Offset in RAM-Disk
;       	
		LD	BC, rafmini.RDSK-128	; Sektorenz‰hlung beginnt mit 1 (CP/A), deshalb Korrektur
		ADD	HL, BC	; Basis-Adr. RAM-Disk addieren
		LD	A, hi(rafmini.RDSKEND)
		CP	H	; Cy=1: H>0BFH, also RAM-Disk overflow
		RET


;------------------------------------------------------------------------------
; WBOOT
;------------------------------------------------------------------------------

rafmini.WBOOT:	ret

;------------------------------------------------------------------------------

	elseif codesec=ubiossec
;	SHARED	DPH,DBP

;------------------------------------------------------------------------------
; RAM-Bereiche
;------------------------------------------------------------------------------

;Disk-Parameter-Header

rafmini.dph:	dw	0		; XLT	translation table
		dw	0
		dw	0
		dw	0
		dw	dirbuf		; DIRBUF
		dw	rafmini.dpb	; DPB
		dw	rafmini.CSV	; CSV
		dw	rafmini.ALV	; ALV

; RAM-Disk A: 8 SPT x 128 HSEC x 6 TRK
rafmini.dpb:	Dw	8		; SPT	8 Sektoren/Spur
		DB	2		; BSH	= log2(blocksize/128)
;					;  => blocksize = (2^x)*128 =  512
		DB	3		; BLM	= 2^BSH-1
		DB	0		; EXM
		Dw	12-1		; DSM	max. x Blˆcke
					;  => also x* blocksize = 6K disc !!!
		Dw	8-1		; DRM	max x Dir. Eintr‰ge
		DB	080H		; AL0	also x Block (DRM*32/blocksize)
		DB	0		; AL1	f¸r DIR reservieren
		Dw	0		; kein Check ....
		Dw	0		; OFF	0 reservierte Spuren
; CP/A-Erw.
  		db	80h		;kein Disketten-DPB
; VP-Erw.
  		db	0		;phys. Nummer
  		dw	rafmini.read
  		dw	rafmini.write

rafmini.ALV:	db	2 dup (?)	; (DSM+1)/8
rafmini.CSV:	equ	0		; es gibt keinen Check ....

;------------------------------------------------------------------------------

	elseif codesec=initsec
;	SHARED	BOOT,BOOTMSG

;------------------------------------------------------------------------------
; BOOT
;------------------------------------------------------------------------------

rafmini.BOOT:	call	rafmini.rfdel
		ret
        	
rafmini.RFDEL:	LD      HL, rafmini.MT4		; RAMDISK LOESCHEN
        	CALL	PRNST
rafmini.RF1:    CALL	CONIN
		and	5FH		; klein -> groﬂ
		CP     'Y'
		JR	Z, rafmini.RF2
		CP     'N'
		RET	Z        
		JR	NZ, rafmini.RF1
;RAM-Disk formatieren
rafmini.RF2:    	LD	HL, rafmini.RDSK
		LD      DE, rafmini.RDSK+1
        	LD	BC, rafmini.RDSKEND-rafmini.RDSK
        	LD 	A, 0E5H
		LD	(HL), A     
		LDIR
		RET
        	
rafmini.MT4:	DB	0DH, 0AH, 0AH, "RAM-Disk formatieren (Y/N)?", '$'

rafmini.BOOTMSG	macro
		outradix	16
		db	rafmini.drv,": RAM-Disk \{rafmini.RDSK}-\{rafmini.RDSKEND}", 0Dh, 0Ah
		outradix	10
	endm

;------------------------------------------------------------------------------

	endif
	
	