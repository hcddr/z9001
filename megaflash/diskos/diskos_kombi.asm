;------------------------------------------------------------------------------
; Z9001
; (c) V. Pohlers 2012
; letzte Änderung 28.03.2012 15:07
; rem 23.12.2019 neue BOS-Funktion 19 DIR
;------------------------------------------------------------------------------
; CP/M-Disketten unter OS
; mit/ohne Shadow RAM; mit/ohne Upper RAM
;------------------------------------------------------------------------------

; Organisation 
; Shadow-RAM: BDOS/BIOS/CCP-Routinen/Call5-Routinen/Init
; Normaler RAM: CCP-Routinen-Kdos/Call5-Routinen-OS-Rahmen+UBIOS


;------------------------------------------------------------------------------
		cpu	z80

; shadow = 1 mit Shadow f. Mega-Flash-Modul. 
; ubios = 0 ist bei shadow = 1 nicht sinnvoll
; ubios s.a. bios.asm, call5.asm
 
 
shadow		equ	1			; 0 = ohne Shadow 
ubios		equ	shadow			; 1 = Transport über UBIOS (uread, uwrite)

		
	if ubios		
ucode		equ	0bd00h			; Adresse Upper Code
	endif

;------------------------------------------------------------------------------
;Makros

shadow_on	macro
	if shadow
		out	(05h), a
	endif
		endm

shadow_off	macro
	if shadow
		out	(04h), a
	endif
		endm

;------------------------------------------------------------------------------

; im Shadow-RAM !!!!
		org	4000h

		jp	init			; Patch zum Start/Init

;------------------------------------------------------------------------------
; BDOS
;------------------------------------------------------------------------------

bdos		equ	$
		include bdos_cpa.asm

;------------------------------------------------------------------------------
; BIOS
;------------------------------------------------------------------------------

bios		equ	$
		include	bios4kombi.asm

;	bios access constants for bdos
;bios		equ	$+0E00h
BOOTF		equ	BIOS+3*0	;cold boot function
WBOOTF		equ	BIOS+3*1	;warm boot function
CONSTF		equ	BIOS+3*2	;console status function
CONINF		equ	BIOS+3*3	;console input function
CONOUTF		equ	BIOS+3*4	;console output function
LISTF		equ	BIOS+3*5	;list output function
PUNCHF		equ	BIOS+3*6	;punch output function
READERF		equ	BIOS+3*7	;reader input function
HOMEF		equ	BIOS+3*8	;disk home function
SELDSKF		equ	BIOS+3*9	;select disk function
SETTRKF		equ	BIOS+3*10	;set track function
SETSECF		equ	BIOS+3*11	;set sector function
SETDMAF		equ	BIOS+3*12	;set dma function
READF		equ	BIOS+3*13	;read disk function
WRITEF		equ	BIOS+3*14	;write disk function
LISTSTF		equ	BIOS+3*15	;list status function
SECTRAN		equ	BIOS+3*16	;sector translate

;------------------------------------------------------------------------------
; CCP
;------------------------------------------------------------------------------

		include	dos_ccp.asm
		
		include dump.asm
		
		include call5.asm

;------------------------------------------------------------------------------
; aber hier puffer-bereich für BIOS etc. möglich
; init usw. kann überschrieben werden
;------------------------------------------------------------------------------


;------------------------------------------------------------------------------
; init
;------------------------------------------------------------------------------

eor		equ	0036h
init:		
	if ubios
		; kopiere upper code block an sein Ziel
		ld	hl, ucodbeg
		ld	de, ucode
		ld	bc, ucodend-ucodbeg
		ldir
		
		ld	hl, ucode
		dec	hl
		dec	h
		ld	(eor),hl
		;;call	bios			; bios boot-function
		call	initdos			; enthält call bios
		jp	uinit_ret
;;		jp 	udos
	else
		;;call	bios			; bios boot-function
		call	initdos			; enthält call bios
;;		jp 	udos
		ret
	endif

;------------------------------------------------------------------------------
; upper code
;------------------------------------------------------------------------------

ucodbeg	equ	$

	if ubios
		phase	ucode
	
		jp	uDRIVE
		db	"DRIVE   ",0
		jp	uDIRECT
		db	"DDIR    ",0
		jp	uERASE
		db	"DDELETE ",0
		jp	uDDUMP
		db	"DDUMP   ",0
		jp	uDOS
		db	"DOS     ",0
		jp	uCAOS
		db	"CAOS    ",0
		db	0

uDRIVE:		shadow_on
		call	DRIVE
		shadow_off
		ret
uDIRECT:	shadow_on
		call	DIRECT
		shadow_off
		ret
uERASE:		shadow_on
		call	ERASE
		shadow_off
		ret
uDDUMP:		shadow_on
		call	DDUMP
		shadow_off
		ret
uDOS:		shadow_on
		call	initdos
		shadow_off
		ret
uCAOS:		shadow_on
		call	exitdos
		shadow_off
		ret

		
uinit_ret:	shadow_off
		ret

	else
		align 100h

		jp	DRIVE
		db	"DRIVE   ",0
		jp	DIRECT
		db	"DDIR    ",0
		jp	ERASE
		db	"DDELETE ",0
		jp	DDUMP
		db	"DDUMP   ",0
		jp	initdos
		db	"DOS     ",0
		jp	exitdos
		db	"CAOS    ",0
		db	0

	endif



;------------------------------------------------------------------------------
; Upper BIOS: Routinen zum Umladen bei read/write
; da hier auch der Adressbereich des Shadow-RAMs genutzt werden könnte,
; wird im Shadow-BIOS immer auf biosbuf statt (ddma) geschrieben/gelesen
;------------------------------------------------------------------------------

ddma:		dw	?		; aktuelle DMA-Adresse
dirbuf:		ds	128 		; Bereich 128 Byte

	if ubios

biosbuf		ds	128		; DMA Buffer f. BIOS

; Lesen von Disk
uread		ld	hl, biosbuf
		ld	de, (ddma)
		ld	bc, 128
		shadow_off
		ldir
		shadow_on
		ret

; Schreiben auf Disk
uwrite		ld	hl, (ddma)
		ld	de, biosbuf
		ld	bc, 128
		shadow_off
		ldir
		shadow_on
		ret
	
	endif	

;-----------------------------------------------------------------------------
; CALL 5-Routine
;-----------------------------------------------------------------------------
SPSV:		EQU	000BH		;REGISTER FUER NUTZERSTACK
BCSV:		EQU	000DH		;REGISTER FUER BC
ASV:		EQU	000FH		;REGISTER FUER A
;BOSE		equ	0f345h
BOSER		equ	0f5deh		;UNERLAUBTER SYSTEMRUF
ERDIS		equ	0f5eah

CBDOS:		LD	(SPSV),SP	;SICHERN ANWENDERSTACK
		LD	SP,1C0H		;BOS - STACK
		SCF
		CCF
		PUSH	HL
		PUSH	DE
		PUSH	AF
		LD	(BCSV),BC
		LD	(ASV),A
		LD	HL,CBOSE
		PUSH	HL		;RUECKKEHRADRESSE KELLERN
		LD	A,33+2
		CP	A, C
		JP	C, BOSER	;UNERLAUBTER SYSTEMRUF
		LD	B,0
		LD	HL,JPVEK	;ADRESSTABELLE DER SYSTEMRUFE
		ADD	HL,BC
		ADD	HL,BC
		LD	A,(HL)
		INC	HL
		LD	H,(HL)
		LD	L,A
		LD	C,E		;EINGANGSPARAMETER
		LD	B,D		;UEBERNEHMEN
		LD	A,(ASV)
		PUSH	HL		;SYSTEMRUFADRESSE KELLERN
		LD	L,3		;ANFANGSWERT FUER CURSORRUFE
		RET			;SPRUNG ZUR AUSFUEHRUNG

;AUSGANG AUS BOS
CBOSE:		JR	NC, BOSE1	;KEIN FEHLER
		CALL	ERDIS		;AUSGABE FEHLERMELDUNG
;		shadow_off
		POP	AF
		SCF			;SETZEN FEHLERSTATUS
		PUSH	AF
BOSE1:		POP	AF
		POP	DE
		POP	HL
		LD	A,(ASV)
		LD	BC,(BCSV)
		LD	SP,(SPSV)
		RET


;------------------------------------------------------------------------------

	if ubios
	
uOPENR:		shadow_on
		call	OPENR
		shadow_off
		ret
uOPENW:		shadow_on
		call	OPENW
		shadow_off
		ret
uCLOSW:		shadow_on
		call	CLOSW
		shadow_off
		ret
uREADS:		shadow_on
		call	READS
		shadow_off
		ret
uWRITS:		shadow_on
		call	WRITS
		shadow_off
		ret
uRRAND:		shadow_on
		call	RRAND
		shadow_off
		ret
;
uDIRS:		shadow_on
		call	DIRS
		shadow_off
		ret

	endif
;-----------------------------------------------------------------------------
; # CLOAD C=34
;
; Funktion:
; 	- Schreiben eines Blockes einer Datei auf Kassette
; Eingang:
;   A=0 => Dateiname+Typ ist bereits im FCB eingetragen
;   A=1 => Dateiname "Name[.Typ]" muss in CONBU abgelegt sein
;   A=2 => zuerst Abfrage "Filename:"
;   HL = 0 => orig. aadr wird genommen
;   HL <> 0 => aadr
;ret: Cy=1 Fehler
;-----------------------------------------------------------------------------

cload5:
	;AUSGANG AUS BOS
	POP	HL	; BOSE
	POP	AF
	POP	DE
	POP	HL
	LD	BC,(BCSV)
	LD	SP,(SPSV)
	rst	28h
	db	14	; CLOAD
	ret

;-----------------------------------------------------------------------------
; # CSAVE C=35
;
; Funktion:
; 	- Schreiben eines Blockes einer Datei auf Kassette
; Eingang:
;   A=0 => Dateiname+Typ ist bereits im FCB eingetragen
;   A=1 => Dateiname "Name[.Typ]" muss in CONBU abgelegt sein
;   A=2 => zuerst Abfrage "Filename:"
;ret: Cy=1 Fehler
;-----------------------------------------------------------------------------

csave5:
	;AUSGANG AUS BOS
	POP	HL	; BOSE
	POP	AF
	POP	DE
	POP	HL
	LD	BC,(BCSV)
	LD	SP,(SPSV)
	rst	28h
	db	15	; CSAVE
	ret

	
;-----------------------------------------------------------------------------
JPVEK:		ds	(33+2)*2

		
	if ubios
		dephase
	endif

ucodend		equ	$

		end
