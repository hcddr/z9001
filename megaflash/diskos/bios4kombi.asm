;-----------------------------------------------------------------------------
; Z9001-BIOS für OS-CPM Version 0.2 für Kombimodul-RAF + Floppy
; (c) V. Pohlers 2012
; 20.02.2012 RAF-BIOS ist ok für fixe 2MB-RAF
; 28.09.2018 f. Kombimodul Nutzung der vorhandenen Kombi-RAF
; 191118 Bedeutung+Bezeichnung CFDC und DFDC waren vertauscht
; 200316 aktuelles Laufwerk beibehalten (bei BOOT via Ctrl-C)
;-----------------------------------------------------------------------------
; CP/M-Disketten unter OS
; BIOS (nur Disk-Funktionen nötig)
; einfaches BIOS für 3 Laufwerke 2xFloppy+RAF
;------------------------------------------------------------------------------


		cpu	z80undoc


	section bios

;werden extern festgelegt:
;;BDOS       	equ	04006h		; base of bdos
;;DISKA		equ	BDOS+00DE8h	; Boot-LW f. BDOS Func. 13 INIT 
;;DISKo
;;ubios		equ	1		; 1 = Transport über UBIOS (ureasd, uwrite)

;-----------------------------------------------------------------------------
; RAF2008

rafport		equ	20h		; Port
rafdrv		equ	'M'

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

		; Disk-Treiber init
		
boot0:		; kopiere testkombi in saveram
		ld	hl,rafkombi.testkombi
		ld	de,80h
		ld	bc,rafkombi.raftst-rafkombi.testkombi
		ldir
		
		call	80h			; testkombi
		call	rafkombi.boot + 3 	; der Rest
		
		; Floppy-LW init.
		call	binit		

		ld	de, boot_txt
		ld	c, 9
		call	bdos

		ld 	a,(rafkombi.version)
		ld	de,boot_txt7
		cp	7
		jr	z, boot1
		ld	de,boot_txt2
		cp	2
		jr	z, boot1
		ld	de,boot_txt1
		
boot1		ld	a,(DISKo)
		add	a,'A'
		ld	(boot_txtd),a	;curent drive
		
		ld	c, 9
		call	bdos
		ld	de, boot_txte
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
		db	"  ",rafdrv,": RAF ",'$'
	
boot_txt1	db	"SRAM-Modul 58k$"
boot_txt2	db	"Kombi-Modul 58k$"
boot_txt7	db	"Kombi-Modul 406k$"
		
boot_txte	db	0dh, 0ah
		db	"current drive: "
boot_txtd:	db	'?'	
		db	0dh, 0ah
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
		call	rafkombi.READ
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
		call	rafkombi.WRITE
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
		LD	HL, rafkombi.dph	; ja: RAF
		ld	(ddrive), a
		RET	


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
; RAFKOMBI-Treiber
;-----------------------------------------------------------------------------

		include	biosrafkombi.asm

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
