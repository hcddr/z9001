;------------------------------------------------------------------------------
; ROM-FloppyDisk f. Mini-CPM
;------------------------------------------------------------------------------


	if codesec=commentsec

; Disketten-Treiber
; global genutzt currenttrack, currentsec, currentdrive	

; Code-Bereiche codesec
;	commentsec	Kommentare
;	equsec		Definitionen
;	biossec		z.b. im Shadow-RAM oder im ROM
;	ubiossec	im RAM, von CCP aus erreichbar
;	initsec		Initialisierung, Hardware-Erkennung etc.

	elseif codesec=biossec
	
;------------------------------------------------------------------------------
; Adressen und Port-Definitionen
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; phys. Treiber
;------------------------------------------------------------------------------

	if megarom == "KOMBI"

rof.calcAdr:	
	; Berechnung Adr.
		ld	a,(rofbank)		;a := rofbank
		ld	b,a			;b := 1. Bank der ROM-Disk
	;1 Track=1K, wir starten mit 
		ld	a, (currenttrack)
rof.calc3:	bit	0,b
		ld	c,10
		jr	z,rof.calc1		; wenn gerade 10K-Bank
		ld	c,6		; sonst 6K
rof.calc1:	sub	a,c
		jr	c, rof.calc2 
		inc	b		;Bank erhöhen
		jr	rof.calc3 
rof.calc2:	add	a,c		; wieder korrigieren
		;
		;HL := SPT*track
		inc	a		; 0->1
		ld	hl,-8		; und wieder korrigieren
		ld	de,8
rof.calc4:	add	hl,de
		dec	a
		jr	nz,rof.calc4
		;HL := HL + SEC
		ld	de,(currentsector)
		dec	de
		add	hl,de
		;*128
		; mit 128 multiplizieren .....
		add 	hl,hl			; *2
		add 	hl,hl			; *4
		add 	hl,hl			; *8
		add 	hl,hl			; *16
		add 	hl,hl			; *32
		add 	hl,hl			; *64
		add 	hl,hl			; *128
		ld 	de, 0c000h		; BasisSpeicheradresse noch dazu und fertig.....
		add	hl, de	
		ld	a,b			; Bank
		or	a
		jp	set_bank
	else
;Megaflash
rof.calcAdr:	ld	a, (currentdrive)
		exx	
		ld	hl, rofbank
		ld	b,(hl)			;b := rofbank
	if minicpm_disk2
		cp	1
		jr	z, rof.laufwerk_weiter	; wenn drive B:
		; sonst Drive C:
		push	af
		ld	a,(hl)
		add	a,81			; 80*10K = 800K Diskgröße + disk1b offset
		ld	b,a			; b := disk2b
		pop	af
rof.laufwerk_weiter:
	endif
		exx
		ld	b, 0
		ld	a, (currenttrack)
		rra	; einmal nach recht's und modBit ins Carry ....
		jr	nc, rof.weiter
		ld	b, 40			; Sektoren pro Track
rof.weiter:	exx	
		add	a,b
		exx
		push	af
		ld 	a, (currentsector)
		add	a, b			; 40 oder 0
		dec 	a			; da sectorenzählung mit 0 beginnt .....
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
	endif



;------------------------------------------------------------------------------
; WBOOT
;------------------------------------------------------------------------------

rof.WBOOT:	ret

;------------------------------------------------------------------------------

	elseif codesec=ubiossec
;	SHARED	DPH,DBP
;	SHARED  READ,WRITE

;---14.03.2017 searchrf in RAM wg. Port-Umschaltung
rof.BOOT:	
		call	searchrf
		ld	(rofbank),a
		call	set_cpmBank
		ret

; ROM_Floppy im Megamodul suchen
; ret: cy=1 nicht gefunden
;      cy=0 gefunden
;      a = bank-nr

searchrf:	ld	b,255
searchrf1:	ld	a, b
		cpl
		out	(bankport), a	; 0..255

;The CP/M 2.2 directory has only one type of entry: 
;UU F1 F2 F3 F4 F5 F6 F7 F8 T1 T2 T3 EX S1 S2 RC   .FILENAMETYP....
;AL AL AL AL AL AL AL AL AL AL AL AL AL AL AL AL   ................

		
		ld	c,4		; Anz. von zu testenden DIR-Einträgen
		ld	de, 20h		; Länge DIR-Eintrag
		ld	ix, 0c000h	; erste Adresse
		
searchrf3:	ld	a,(ix+0)	; UU
		cp	0		; wir nutzen nur User 0
		jr	nz, searchrf2
		
		ld	a,(ix+1h)	; erste Buchstabe Dateiname
		cp	20h
		jr	c, searchrf2

		ld	a,(ix+0dh)	; S1 reserved 00
		cp	0
		jr	nz, searchrf2

	; sowas haben wir -> ASM. Evtl Test auf < 80 o.ä.	
	;	ld	a,(ix+0eh)	; S2 - Extent counter, high byte
	;	cp	0		; sollte bei unseren Disks auch 00 sein
	;	jr	nz, searchrf2	
		
		ld	a,(ix+0fh)	; RC - Number of records
		cp	0
		jr	z, searchrf2

		ld	a,(ix+10h)	; AL - mindestens der erste Block ist belegt
		cp	0
		jr	z, searchrf2

		add	ix, de
		dec	c
		jr	nz, searchrf3
		
		; sonst haben wir wohl den richtigen Block gefunden..
		ld	a,b
		cpl
		or	a		; Cy=0
		ret
	
searchrf2:	djnz	searchrf1
		scf
		ret


;------------------------------------------------------------------------------
; RAM-Bereiche
;------------------------------------------------------------------------------

rof.READ:	CALL	rof.calcadr
		JR	C, rof.ERR
		LD	DE, (currentdma)
		LD	BC, 128
		LDIR
		call	set_cpmBank
		XOR	A
		RET
	
; Schreiben auf ROM-Floppy ist nicht sinnvoll
rof.WRITE:			
rof.ERR:	call	set_cpmBank
		LD	A,1		; Fehler
		RET

;Kombi
;disk capacity:      64K
;tracks:            48    0 system
;sectors/track:      8    8 last
;sectors/system:     0    4 dir
;dir entries:       16    0K
;sectors/group:      4  255K  5FH groups
;kbytes/extent:     16K                  

;Megaflash
; disk capacity:    800K
; tracks:           160    0 system
; sectors/track:     40   40 last
; sectors/system:     0   48 dir
; dir entries:      192    6K
; sectors/group:     16    2K 18FH groups
; kbytes/extent:     16K


;Disk-Parameter-Header

rof.dph:	dw	0		; XLT	translation table
		dw	0
		dw	0
		dw	0
		dw	dirbuf		; DIRBUF
		dw	rof.dpb		; DPB
		dw	rof.CSV		; CSV
		dw	rof.ALV		; ALV
		
	if minicpm_disk2
rof.dph2:	dw	0		; XLT	translation table
		dw	0
		dw	0
		dw	0
		dw	dirbuf		; DIRBUF
		dw	rof.dpb		; DPB
		dw	rof.CSV2	; CSV
		dw	rof.ALV2	; ALV
	endif

	if megarom == "KOMBI" 
; ROM Floppy 128K = (8*128) * 128
; 1K Blöcke => 128 Blöcke => 8 bit-Blocknummern 
rof.DPB:    	DW      8		; SPT = 8 Sektoren pro Track-Spur
        	DB      3		; BSH => log2(blockSize/128) => blockSize 1024
		DB 	7		; BLM => = 2^BSH-1
		DB	0		; EXM => 0
;        	DW      63          	; DSM => DISK SIZE/blockSize-1 => 64K
        	DW      127          	; DSM => DISK SIZE/blockSize-1 => 128K
        	DW      31              ; DIRECTORY MAX-1 <= 1 Block * 1024/32
        	DB      10000000B	; 1 Dir Block
        	DB      0
        	DW      0		; kein Check .....
        	DW      0
; CP/A-Erw.
  		db	80h		;kein Disketten-DPB
; VP-Erw.
  		db	0		;phys. Nummer
  		dw	rof.read
  		dw	rof.write

;megarom == "MEGA"
  	elseif lastbank < 0ffh
; ROM Floppy 128K = (8*128) * 128
; 1K Blöcke => 128 Blöcke => 8 bit-Blocknummern 
rof.DPB:    	DW      40		; SPT = 8 Sektoren pro Track-Spur
        	DB      3		; BSH => log2(blockSize/128) => blockSize 1024
		DB 	7		; BLM => = 2^BSH-1
		DB	0		; EXM => 0
;        	DW      63          	; DSM => DISK SIZE/blockSize-1 => 64K
        	DW      127          	; DSM => DISK SIZE/blockSize-1 => 128K
        	DW      31              ; DIRECTORY MAX-1 <= 1 Block * 1024/32
        	DB      10000000B	; 1 Dir Block
        	DB      0
        	DW      0		; kein Check .....
        	DW      0
; CP/A-Erw.
  		db	80h		;kein Disketten-DPB
; VP-Erw.
  		db	0		;phys. Nummer
  		dw	rof.read
  		dw	rof.write
	else
; ROM Floppy im 800k KC87 Format.... (40*128) * 160
; 2K Blöcke => 400 Blöcke => 16 bit-Blocknummern 
rof.DPB:   		DW      40	; SPT = 40 Sektoren pro Track-Spur
        	DB      4		; BSH => log2(blockSize/128) = 2048
		DB 	15		; BLM => 01111b
		DB	0		; EXM => 0
        	DW      399             ; DSM => DISK SIZE-1
        	DW      191             ; DIRECTORY MAX-1
        	DB      11100000B	; 3 Dir Bloecke
        	DB      0
        	DW      0		; kein Check .....
        	DW      0
; CP/A-Erw.
  		db	80h		;kein Disketten-DPB
; VP-Erw.
  		db	0		;phys. Nummer
  		dw	rof.read
  		dw	rof.write
	endif

rof.ALV:	db	32h dup (?)	; (DSM+1)/8
rof.CSV:	equ	0		; es gibt keinen Check ....
	if minicpm_disk2
rof.ALV2:	db	32h dup (?)	; (DSM+1)/8
rof.CSV2:	equ	0		; es gibt keinen Check ....
	endif


rofbank		db	0

;------------------------------------------------------------------------------

	elseif codesec=initsec
;	SHARED	BOOT,BOOTMSG

;------------------------------------------------------------------------------
; BOOT
;------------------------------------------------------------------------------

rof.BOOTMSG	macro
		db      rof.drv,": ROMFLOPPY (Anwendungen)",0dh,0ah
	if minicpm_disk2
                db      rof.drv2,": ROMFLOPPY (Basic, Spiele)", 0dh, 0ah
        endif
        endm



;------------------------------------------------------------------------------

	endif
	
