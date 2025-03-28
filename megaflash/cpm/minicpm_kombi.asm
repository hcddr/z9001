;-----------------------------------------------------------------------------
; Mini-CP/M für den Z9001 ohne Floppy (zum Reinschnuppern)
; mit kleiner RAM-Disk
; 02.08.2016 V.Pohlers
;
; basiert auf: Z9001-BIOS für CPA, 1989 Dr. Schwarzenberg,reass 2004 Volker Pohlers
; sowie Minibios AS 2007
;
; letzte Änderung 02.08.2016
; Fehler: Bei Nutzung von minicpm_disk2 überschneiden sich die RAM-Bereiche
; von UBIOS und RAM-Floppy!
;-----------------------------------------------------------------------------

		cpu	z80
		LISTING	NOSKIPPED

;-----------------------------------------------------------------------------
; Speicheraufteilung
; RAM:
; 	9000 CCP
; 	9806 BDOS
; 	A600 UBIOS		BIOS, RAM-Teil
; 	A800-BFFF RAM-Floppy
; ROM:
; 	C000 OS-Kommandorahmen
; 	CCP-Kopie,		wird von WBOOT an richtigen Platz kopiert
; 	UBIOS-Kopie, 		wird von INIT an richtigen Platz kopiert
; 	BIOS, ROM-Teil
; 	xxx  INIT, incl.
;-----------------------------------------------------------------------------

		include "../includes.asm"


CCP		equ	0A600h		; base of ccp
BDOS       	equ	CCP+0806h	; base of bdos
UBIOS		equ	CCP+1600h	; base of bios

;
VERSIONSDATUM	equ	DATE

rafkombi.drv	equ	'A'
rof.drv		equ	'C'
	if minicpm_disk2
rof.drv2	equ	'D'
	endif

;CPM-Version
cpa	equ	1; 1- CP/A-System Z9001
; 0 - orig cpm
; 1- CP/A-System Z9001
; 2- orig CP/A

	if cpa=1	; Z9001-OS-IO-Konzept
IOLOC	EQU	4		;i/o definition byte.
DISKA	EQU	3		;current drive name and user number.
	else		; standard CPM
IOLOC	EQU	3		;i/o definition byte.
DISKA	EQU	4		;current drive name and user number.
	endif


;sections codesec
commentsec	equ	0	;Kommentare
equsec		equ	1	;Definitionen
biossec		equ	2	;z.b. im Shadow-RAM oder im ROM
ubiossec	equ	3	;im RAM, von CCP aus erreichbar
initsec		equ	4	;Initialisierung, Hardware-Erkennung etc.


; EQU's
codesec 	EVAL	equsec
		include	biosinc_kombi.asm

x_align	function x, (($+x-1)/x)*x


;-----------------------------------------------------------------------------
; OS - RAHMEN
;-----------------------------------------------------------------------------

		org	0c000h

		jp	gominicpm
		db      "MINICPM ",0
		db	0

gominicpm:
	        ld      hl, ccp_code
	        ld      de, ccp
	        ld      bc, ubios_end-ccp_code
	        ldir

		ld	a,(currbank)
		ld	(cpmbank),a

	        jp 	COLD


;-----------------------------------------------------------------------------
; CCP+BDOS+UBIOS, wird in RAM-Speicher verschoben
;-----------------------------------------------------------------------------

ccp_code:
		PHASE	CCP

	if cpa=0    
		; orig CP/M von DRI
		LISTING	OFF
		section CCP
		include	ccp22.asm
		endsection
		section BDOS
		ds	x_align(100h)-$
		include	bdos22.asm  
		ds	x_align(100h)-$ 
		endsection
		LISTING	NOSKIPPED
	elseif cpa=23
		LISTING	OFF
TDRIVE	equ	DISKA
IOBYTE	EQU	IOLOC
		section CPM22
		include	CPM22ccp.asm
		include	CPM22bdos.asm
		endsection
		LISTING	NOSKIPPED
	elseif cpa=10
		binclude "ccp2_9000.rom"
	elseif cpa=1
		LISTING	OFF
		section CCP
		;public	dircol
		include	ccp_cpa_z9.asm
		endsection
		section BDOS
		include	bdos_cpa.asm
		endsection
		LISTING	NOSKIPPED
	elseif cpa=2
		LISTING	OFF
		section CCP
		public	dircol
		include	ccp_cpa.asm
		endsection
		section BDOS
		include	bdos_cpa.asm
		endsection
		LISTING	NOSKIPPED
	endif


;-----------------------------------------------------------------------------
; UBIOS
;-----------------------------------------------------------------------------

		;PHASE 	UBIOS
	if $ <> UBIOS
		error "CCP + BDOS Fehler"
	endif

		jp	cold
		jp	wboot
		JP	CONST		;console status
		JP	CONIN		;console character in
		JP	CONOUT		;console character out
		JP	LIST		;list character out
		JP	PUNCH		;punch character out
		JP	READER		;reader character out
		jp	home
		jp	seldsk
		jp	settrk
		jp	setsec
		jp	setdma
		jp	read
		jp	write
		JP	LISTST		;return list status
		jp	sectran

;-----------------------------------------------------------------------------
; CODE, der im RAM stehen muss
;-----------------------------------------------------------------------------

; einstellen einer Bank .... wichtig für die Arbeit mit der Ramdisk
set_CPMBank	ld	a, (cpmbank)
set_Bank	out 	(bankport),a
		ret

read:		jp	0		; wird gepatcht

write:		jp	0		; wird gepatcht

codesec 	EVAL	ubiossec
		include	biosinc_kombi.asm


ubios_end0:			; RAM-Ende

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; folgendes wird definiert, muss aber nicht mit kopiert oder freigehalten werden
; deswegen überlappend programmiert (org bei ubios_end)
cpmBank		db	?

currentdrive	db	?
currentdma:	dw	?		; aktuelle DMA-Adresse
currenttrack:	dw	?
currentsector:	dw	?

bootdrive	db	?



; "intvectab" muss an einer xx00 Adresse stehen
; deshalb hier dazwischen gedrängt.
		ds	x_align(100h)-$
intvectab:	ds 	12	; Interruptvektortabelle, 12 Byte
;

dirbuf:		ds	128 	; Bereich 128 Byte

ubios_end1:			; RAM-Ende, muss kleiner Beginn RAM-Disk sein!

;-----------------------------------------------------------------------------

		dephase

		org	ubios_end0+ccp_code-ccp


ubios_end:			; RAM-Ende

;-----------------------------------------------------------------------------
; hier alles, was im ROM stehen kann ....

codesec 	EVAL	biossec
		include	biosinc_kombi.asm

;-----------------------------------------------------------------------------
; Disk-Routinen
;-----------------------------------------------------------------------------

;select disk
seldsk:		LD	A,C
		LD	(currentdrive),A
		LD	HL, rafkombi.dph
		CP	rafkombi.drv-'A'
		jr	Z,seldsk1
		LD	HL, rof.DPH
		CP	rof.drv-'A'
		jr	Z,seldsk1
	if minicpm_disk2
		LD	HL, rof.DPH2
		CP	rof.drv2-'A'
		jr	Z,seldsk1
	endif
		; im Fehlerfall
		LD	HL,0000H	;error return code
		RET

; DPB suchen (f. SWAP-Kommando)
seldsk1:	push	hl
		ld	DE, 10 		;Offs. zu DPB
		ADD	HL,DE
		LD	A,(HL)
		inc	hl
		ld	H,(hl)
		ld	L,a		;HL = DBP
		;Read- und Write-Prozeduren patchen
		ld	de,15+2		;Offs. Read-Proc im DPB
		ADD	HL,DE
		LD	E,(HL)
		inc	hl
		ld	D,(hl)
		ld	(read+1),DE	;read-Proc
		inc	hl
		LD	E,(HL)
		inc	hl
		ld	D,(hl)
		ld	(write+1),DE	;write-Proc
		pop	hl		;DPH zurückgeben
		ret

;Sector Transformation
sectran:	LD	H,B
		LD	L,C
		INC	HL		; CP/A-Translation
		RET

;Sector einstellen
setsec:		LD	(currentsector),BC
		RET

HOME:		LD	BC,0	;Spur 0
settrk:		LD	(currenttrack),BC
		RET

setdma:		LD	(currentdma),BC	;DMA setzen
		RET


;-----------------------------------------------------------------------------
; wboot
;-----------------------------------------------------------------------------

wboot:		di
		ld	sp, 80h
		; CCP kopieren ...
		; dazu CPM Bank einstellen
		ld	a, (CPMBank)
		out 	bankport, a
		; kopieren
		ld 	hl, ccp_code
		ld	de, ccp
		ld	bc, 01600h
		ldir
;
wboot3:		ld	a, hi(intvectab)	;E7H
		ld	i, a
		im	2
;
		ld	a, 0C3h		; Befehlscode JP
		ld	(0), a		; 0000h: jp wboot
		ld	hl, ubios+3	; wboot	im upper Bios
		ld	(1), hl
		ld	(5), a		; 0005h: jp bdos
		ld	hl, BDOS
		ld	(6), hl
;
		ei

		ld	a,(DISKA)	; DRIVE-Byte !! Im Std.-CP/M ist das 0004h !!
		and	0fh
		ld	c,a

		;verify that is a legal drive
		call	seldsk
		ld	a,h
		or	l
		jr	nz,wboot4
		;else bootdrive
		ld	a,(bootdrive)
		ld	(DISKA),a
		ld	c,a
;
wboot4:		jp	CCP	; CLEAR: CCP-Aufruf ohne Löschen des Befehlsbuffers




;-----------------------------------------------------------------------------
; cold boot
; Einsprung durch Init nach Bootloader, Initialisierung von cold und ubios
;-----------------------------------------------------------------------------

cold:		di
		ld	sp, 80h

		xor	a		; A := 0
		ld	(DISKA), a	; Standard-Laufwerk A
		ld	(bootdrive), a

		; Zeichentreiber init
		call	chrdrv.init
	
		; Meldung
		ld	hl, bootmsg	; Anzeige Boot-Meldung
		call	prnst		; Stringausgabe

		; Disk-Treiber init
		call	rafkombi.boot
		call	rof.boot


		; Start-Kommando patchen
		ld	hl, startkdo	; Start-Kommando
		ld	de, CCP+0007h	; CCP-Befehlsbuffer
		ld	bc, startkdoend-startkdo	; Byte + 1 Längenbyte
		ldir

		;jp	wboot		; WBOOT	im ShadowBios
		jp	wboot3		; WBOOT	im ShadowBios, mit Ausführung des startkdo :-))


startkdo:	db  	startkdoend-$-1	; Länge	des Befehls(buffers)
		db 	rof.drv,":",0	; Umschalten auf ROM-Disk
		;db	"CLOCK",0
		;db 	"STAT DEV:",0
		;db 	"DIR",0
startkdoend:	equ	$

;
codesec 	EVAL	initsec
		include	biosinc_kombi.asm

;-----------------------------------------------------------------------------
prnst
;print message until M(BC) = '$'
		LD	A,(HL)
		CP	'$'
		RET	Z		;stop on $
		INC	HL
		PUSH	HL
		LD	C,A		;char to C
		CALL	CONOUT
		POP	HL
		JR	prnst


; -----------------------------------------------------------------------------------------------

ROT:    		EQU     0114H
GRUEN:  		EQU     0214H
GELB:   		EQU     0314H
BLAU:   		EQU     0414H
MAGENTA:		EQU     0514H
CYAN:   		EQU     0614H
WHITE:  		EQU     0714H

bootmsg:        db      0Ch
	if cpa=0
                dw	gruen
                db      "CP/M 2.2", 0Dh, 0Ah
	else
		dw	rot
                db      "Mini-CP/A Z9001, Version ",VERSIONSDATUM, 0Dh, 0Ah
                dw	gruen
                db      16h, "Schwarzenberg 1989,Pohlers 2016", 16h
                db	0Dh, 0Ah
		outradix	16
                db      "TPA 100H - \{BDOS-1}H"
		outradix	10
                db	" \{(BDOS-256)/1024} KB" , 0Dh, 0Ah
                dw	gelb
	endif
		db	0dh,0ah
                db	"Laufwerke:", 0Dh, 0Ah
                dw	gruen
		rafkombi.bootmsg
		rof.bootmsg

		chrdrv.bootmsg
                db      '$'


biosend		equ	$

	;if MOMPASS > 1
	outradix	16
	message	       "====================="
	message	       "cpm:		\{ccp}H"
	message	       "bdos:		\{bdos}H"
	message	       "ubios:		\{ubios}H - \{ubios_end0}H - \{ubios_end1}H"
	message	       "codeend:	\{biosend}H"
	message	       "====================="
	;endif


;------------------------------------------------------------------
; PATCHES

	if cpa=0
		;patch f. 40 Spalten
		;org	CCP+04B1h		; DIRECT3+94B1-9498
		org	0c4d3h
		db	1			; AND	03H -> AND	01H
						; 2 spalten bei DIR
	endif


	; Konsole
	if cpa = 2
		;patch CCP DIR 2 Spalten
		org dircol - ccp + ccp_code
		db	1
	endif

		end
	