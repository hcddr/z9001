;------------------------------------------------------------------------------
; Z9001 USB-Modul
; (c) V. Pohlers 2019, 2024 Umstruktierung des Codes
; letzte �nderung 26.01.2025
;------------------------------------------------------------------------------
; 05.11.2024 CH376-Einbindung Ronald Hecht
; 20.01.2025 SD-OS V. Pohlers
;------------------------------------------------------------------------------

	cpu	z80undoc

; Connector
;;p_connector	equ	2	; 0 - VDIP	--> Port �ndern in VDIP.asm
;;				; 1 - CH376	--> Port �ndern in ch376.asm
;;				; 2 - SD-Module
;;				
;;; optionale Bestandteile
;;; 0 - Bestandteil wird nicht eingebunden
;;; 1 - Bestandteil wird eingebunden (default)
;;p_crt	equ	1	; fast CLS + zus�tzl. Tasten
;;p_help	equ	1	; HELP-Kdo
;;p_zmon	equ	1	; Monitorzusatzkommandos
;;			; MENU, DUMP, FILL, TRANS, RUN, IN, OUT, MEM, EOR, LOAD, SAVE, FCB
;;p_sysinfo equ	0	; Systeminfo-Programm im ROM
;;
;;;
;;p_load_nore	equ	1	; 1 - nur 1x LOAD-Versuch, kein "rewind" (default)
;;				; 0 - bekanntes OS-Verhalten (Fehlerausgabe, neuer Versuch)
;;				; 0 ist bei USB wenig sinnvoll
;;p_load	equ	1	; 1 - HELP-Kdo nutzt USBOS-Load-Routine (default)
;;			; 0 - HELP-Kdo nutzt eigene Load-Routine


;	section	modul
;	public	load, load1, load4, prepfcb	; f�r menukdo.asm

; Die Software nutzt die Eigenschaft des OS, eigene CCP zu schreiben
; (�ber '#       '). Es wird eine eigene Suchroutine CPROM und eine eigene
; Programmstartroutine GOCPM genutzt, die USB mit durchsucht.


;------------------------------------------------------------------------------
; System
;------------------------------------------------------------------------------

CBOS:		EQU	05H		;zentraler BOS-Ruf
;
;CBOS-Rufe
;
;CONSI:		EQU	1		;CONST-Eingabe
;CONSO:		EQU	2		;CONST-Ausgabe
;LISTO:		EQU	5		;LIST-Ausgabe
;CSTS:		EQU	11		;CONST-Status

CSTS:		equ	0F006h		;STATUS CONST
CONSI:		equ	0F009h		;EINGABE ZEICHEN VON CONST
CONSO:		equ	0F00Ch		;AUSGABE ZEICHEN ZU CONST
LISTO:  	equ	0F00Fh

;
IOBYT:		equ	0004h

CONBU:		EQU	0080H		;CCP ZEICHENKETTENPUFFER
STDMA:		EQU	0080H		;STANDARDPUFFER FUER KASSETTE
INTLN:		equ	0100h		; interner Zeichenkettenpuffer
DMA:		EQU	001BH		;ZEIGER AUF KASSETTENPUFFER
PU:		EQU	002FH		;HILFSZELLE (TIME + Status CONST)
WORKA:		EQU	0033H		;HILFSZELLE (ASGN)
PARBU:		EQU	0040H		;HILFSZELLE (wird nur von ALDEV genutzt)

FCB: 		EQU	005Ch 		;Dateikontrollblock
START:		EQU	0071H		;STARTADRESSE

; BDOS
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H
;
DISPE   	EQU	0F0C0h
GVAL    	EQU	0F1EAh
CPROM		EQU	0F28Eh
LOCK    	EQU	0F2B8h
GETMS   	EQU	0F35Ch
;LOAD1   	EQU	0F526h
REA1		EQU	0F5A6h
COEXT   	EQU	0F5B9h
ERINP		EQU	0F5E2h
ERPAR   	EQU	0F5E6h
ERDIS   	EQU	0F5EAh
WBOOT   	EQU	0F003h	;0F6AEh
;;CONS1		equ	0f758h
;

;25.06.2013
DECO0		equ	0FD33h		; DECODIEREN DER TASTATURMATRIX

;02.03.2019 10:47:50
AUP2		equ	0EFDFh		; Eigentlich Adresse UP2-Treiber f�r PUNCH
AUR2		equ	0EFD7h		; Eigentlich Adresse UR2-Treiber f�r READER
					; hier f. Re-Init ON_COLD genutzt

; Arbeitsspeicher
;0042--005B		;26 Byte frei f�r IDAS, DEBUGGER, usw.
;			;005A wird in BM608 BASIC.CSAVE auf 0 gesetzt!
;			;ZM, IDAS, EDAS nutzen diesen Bereich nicht 

;currbank+firstent wird hier nicht genutzt, bleibt aber wg. Kompatibilit�t zur MegaFlash-SW
;auf diesen Adressen

currbank	equ	0042h		; aktuelle Bank
firstent:	equ	currbank+1	; temp. Zelle f. Menu
DATA:		equ	firstent+1	; Konvertierungsbuffer
ARG1:		equ	DATA+2		; 1. Argument
ARG2:		equ	ARG1+2		; 2. Argument
ARG3:		equ	ARG2+2		; 3. Argument
ARG4:		equ	ARG3+2		; 4. Argument

; usb-os --> definiert in usbos.asm
;WRITFLG	equ	004eh		; aktuell im Schreib-Modus?
;initflg	equ	004fh
;fsize:		equ	0050h		; Blockgroesse (128 oder weniger)
;filesize:	equ	0051h		; Dateigroesse in Byte (DS 4!)
;
;filename:	equ	0160h		;
;		;ds	8+1+3+1		;Puffer f�r Filename (Name+Tennz+Typ+00)

; CRT-Treiber --> definiert in crtdrv.asm
;keybu1	equ	005Ah		;letztes eingegebenes Zeichen
;keybu2	equ	005Bh		;ersetztes Zeichen           


;------------------------------------------------------------------------------
; Systemsoftware
;------------------------------------------------------------------------------

; PHASE: MENU, INIT, CODE, RAM


;;	if p_connector = 2
;;		ORG	0B200H		; make -f makefile.windows  modul.com
;;	else
;;		ORG	0C000H
;;	endif			
;
PBEG:
		JP	CCP
		DB	"#       ", 0

		JP	CLS
		DB	"CLS     ", 0

		JP	CURSOR
		DB	"C       ", 0

		JP	VER
		DB	"VER     ", 0

		; DOS

		jp	initdos
		db	"DOS     ",0
		jp	exitdos
		db	"CAOS    ",0

	if p_connector=0
		jp	usbkdo
		db	"USB     ",0
	endif
	
		jp	dirkdo
		db	"DIR     ",0
		jp	cdkdo
		db	"CD      ",0
	if p_connector=1
		jp	erakdo
		db	"ERA     ",0
	endif
	if p_connector=2
		jp	sdxkdo
		db	"SDX     ",0
	endif

		
phase	eval	"MENU"

		if p_help
		include	helpkdo.asm
		endif

		if p_zmon
		include	zmonkdo.asm
		endif

		Db	0

;------------------------------------------------------------------------------
; CCP
;------------------------------------------------------------------------------

; Eintritt bei '#        '
CCP:		LD	SP,200H

	if PBEG <> 0C000h
		call	selfchk

		ld	hl,PBEG-101h
		ld	(0036H),hl	;OS-EOR vor Erw. setzen
	endif
		
		if p_crt==1
		; CRT-Treiber in Treibertabelle eintragen
		ld	hl,CRT
		ld	(0EFCBh),hl
		xor	a
		ld	(keybu1),a
		ld	(keybu2),a
		endif

		LD	DE,aEOS		;XOS-Prompt ausgeben
		LD	C,9
		CALL	5

		;init usb
		call initdos
		jp	c,0F089h	;GOCPM im System

		; on_cold-Treiber via AUR1 starten (USBX/DOSX)
		ld	hl,(AUP2)
		PUSH	HL
           	LD	HL,cold1
            	EX	(SP),HL		;RUECKKEHRADR. KELLERN
          	JP	(HL)
cold1:

		; on_cold-Treiber via AUR2 starten (USBX/DOSX)
		ld	hl,(aur2)
		PUSH	HL
           	LD	HL,cold2
            	EX	(SP),HL		;RUECKKEHRADR. KELLERN
          	JP	(HL)
cold2:


;

;------------------------------------------------------------------------------
; Eintritt bei RET

GOCPM:		LD	HL,GOCPM
		PUSH	HL			;RUECKKEHRADR. KELLERN
GOCPM1:		LD	HL,STDMA
		LD	(DMA),HL		;STANDARDKASSETTENPUFFER
		LD	A,'>'
		CALL	OUTA		;AUSGABE PROMPT

	if p_connector=0
		call	deinit		;VDIP: ggf. restl. vorhandene Daten abholen
	endif	
		;
		CALL	GETMS			;EINGABE KOMMANDOZEILE
		JP	C, DISPE		;STOP-TASTE ODER FEHLER
		CALL	COEXT			;VORVERARB. EINGABEZEILE
		RET	C			;ZEICHENKETTE LEER
		LD	HL,ERDIS
		PUSH	HL			;ADR. FEHLERROUTINE KELLERN
		CALL	GVAL			;1.PARAMETER HOLEN
		JP	Z, ERPAR		;KEIN NAME
;NAMEN IM SPEICHER SUCHEN
INDV:		PUSH	BC			;TRENNZEICHEN MERKEN
		CALL	CPROM			;NAMEN IM SPEICHER SUCHEN
	if PBEG <> 0C000h
		jr	nz, indv2		;wenn nicht gefunden
		; wenn gefunden, TEST auf ROM-BASIC
		; via HL=C0xx, DE=E4xx and (C000) = 18h 0Bh  dann wohl BASIC oder WBASIC
		ld	a,h
		cp	0C0h			; C0xx-Adr
		jr	nz,indv1		; kein BASIC, dann was anderes gefunden
		ld	a,(0c000h)
		cp	18h
		jr	nz,indv1		; kein BASIC, dann was anderes gefunden
		; BASIC im ROM gesucht und gefunden -> dann im RAM darunter weitersuchen
		ld	hl,0BF00h
		call	cprom+3
		jr	indv2
indv1:		xor	a			; restore, set Z-Flag (was anderes gefunden im ROM gesucht und gefunden)
indv2:
	endif
		POP	BC
		JR	Z, JMPHL		;NAMEN GEFUNDEN (HL)=STARTADR.
;Laden von USB/Kassette
INFIL:		ld	hl,0
		ld	(data),hl
		ld	ix,dfltEXT
		CALL	LOAD1			;DATEI LADEN
		RET	C			;FEHLER BEIM LADEN
		LD	HL,(START)		;(HL)=GELESENE STARTADRESSE
JMPHL:		JP	(HL)			;SPRUNG ZUR AUSFUEHRUNG

aEos:		db 0Bh,14h,1,"EOS",14h,2,0Ah
		db 0Dh,0

;------------------------------------------------------------------------------

	if PBEG <> 0C000h
	
selfchk		ld	HL,PBEG
		LD	BC,PEND-PBEG+1
		ld	DE,0
selfchk1:	ld	a,e
		add	a,(hl)
		ld	e,a
		ld	a,d
		adc	a,0
		ld	d,a
		inc	hl
		djnz	selfchk1
		
		ld	hl,(psum)
		ld	a,h
		or	l
		jr	z,selfchk2 ; wenn 0, dann Pr�fsumme merken
		
		or	a
		sbc	hl,de
		ld	a,h
		or	l
		ret	z	; pr�fsumme gleich
		
		; sonst Abbruch, zur�ck ins OS
		ld	a,0
		ld	(PBEG),a
		jp	0F000h
				
selfchk2	ld	(psum),de
		ret		

	endif
	
;------------------------------------------------------------------------------
;* 	C L O A D   -   KOMMANDO                                   *
; muss leider aus OS kopiert werden, da im OS keine Nutzung der SBOS-Systemrufe :(
;------------------------------------------------------------------------------
;

dfltEXT:	db	"COM"

LOAD:	CALL	GVAL		;NAECHSTEN PARAMETER HOLEN
	RET	Z		;KEIN GUELTIGER NAME
;

;DATEI LADEN OHNE START
LOAD1:	call	prepfcb
	ret	c
LOAD4:
	;CALL	OPENR
	ld	c,13		;OPENR
	call	5
	JR	NC, LOAD5	;KEIN FEHLER
	OR	A
	SCF
	RET	Z		;STOP GEGEBEN
	if p_load_nore==1	;keine Ladewiederholung
	ld	a,0FFh		;<STOP> simulieren
	scf			;immer Ausstieg, keine Wiederholung
	ret
	else		;orig
	CALL	REA1		;AUSG. FEHLERMELD. WARTEN REAKT.
	RET	C		;STOP GEGEBEN
	JR	LOAD4		;WIEDERHOLUNG
	endif
LOAD5:	ld	hl,(data)	;neue aadr?
	ld	a,h
	or	l
	jr	nz,LOAD51
	LD	HL,(FCB+17)	;DATEIANFANGSADRESSE
LOAD51:	LD	(DMA),HL	;NACH ADR. KASSETTENPUFFER
LOA55:	;CALL	READ		;LESEN BLOCK
	ld	c,20		; READ
	call	5
	JR	NC, LOAD6	;KEIN FEHLER
	CALL	REA1		;AUSG. FEHLERMELD. WARTEN REAKT.
	RET	C		;STOP GEGEBEN
	XOR	A
LOAD6:	OR	A
	JR	Z, LOA55	;WEITER BIS DATEIENDE LESEN
	JP	OCRLF
;
MOV:	LD	HL,INTLN+1	;ZWISCHENPUFFER
MOV1:	LD	B,A
MOV2:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	MOV2
	RET

prepfcb:
	LD	HL,ERPAR
	PUSH	HL
	LD	A,(INTLN)	;PARAMETERLAENGE
	CP	A, 9
	RET	NC		;NAME ZU LANG
	LD	DE,FCB
	LD	A,8
	CALL	MOV		;NAME IN FCB EINTRAGEN
	EX	AF, AF'
	JR	NC, LOAD3	;DATEITYP FOLGT
	EX	AF, AF'
;	LD	HL,4F43H	;STANDARDEINTRAGUNG
;	LD	(FCB+8),HL	;
;	LD	A,'M'		;COM VORNEHMEN
;	LD	(FCB+10),A	;
;	JR	LOA33
	;STANDARDEINTRAGUNG
	push	ix
	pop	hl
	ld	a,3
	JR	LOA31
LOAD3:	LD	A,C
	CP	A, '.'
	POP	HL
	JP	NZ, ERINP	;FALSCHES TRENNZEICHEN
	PUSH	HL
	CALL	GVAL		;PARAMETER HOLEN
	RET	Z		;KEIN GUELTIGER TYP
	LD	A,3
	CP	A, B		;TYP IST ZU LANG
	RET	C
	LD	DE,FCB+8	;TYP IN FCB EINTRAGEN
;	CALL	MOV
	LD	HL,INTLN+1	;ZWISCHENPUFFER
loa31:	CALL	MOV1
LOA33:	POP	HL
	EX	AF, AF'		;'
	JP	NC, ERINP	;ZU VIELE PARAMETER
	ccf
	ret

;-------------------------------------------------------------------------------
;CLS
;-------------------------------------------------------------------------------
;
CLS:		ld	a,0ch
		call	OUTA
		or	a
		ret

;-------------------------------------------------------------------------------
;CURSOR on/off
;-------------------------------------------------------------------------------
;
CURSOR:		ld	hl,0efc8h
		ld 	a,(hl)
		XOR	a, 00100000B		; "Farb-RAM existiert" togglen (E800-EBFF)
		ld 	(hl),a
		ret

;-------------------------------------------------------------------------------
;VER
;-------------------------------------------------------------------------------

VER:		ld	de, vertxt
		ld	c,9
		call	5
		ret

vertxt:	if p_connector=2
		db	"SD-OS und Tools"
	else
		db	"USB-OS und Tools"
	endif	
		db	13,10
		db	"(c) V.Pohlers, Neustadt i.H., "
		db	DATE
		db	13,10
	if p_connector=1
		db	"CH376 Ronald Hecht, Bruce Abbott"
		db	13,10
	endif
		db 0

		align 8h	; etwas platz lassen wg. Datum
;		endsection


phase	eval	"CODE"

;-------------------------------------------------------------------------------
;Einbindung USB
;CALL5 Ext.    
;DOS, CAOS, USB, DIR, CD
;-------------------------------------------------------------------------------

		section	usb
	if p_connector=0
		public	deinit
	endif		
		public	initdos,exitdos
;		public	usbkdo
		public	dirkdo,cdkdo

	if p_connector=0
		include	osVDIP.asm
	elseif p_connector=1
		include	os376.asm
	elseif p_connector=2
		public sdxkdo
		include	osSD.asm
	endif

;dirkdo:
;cdkdo:
	if p_connector=0
		include	dirVDIP.asm
	elseif p_connector=1
		include	dir376.asm
	elseif p_connector=2
		include	dirSD.asm
	endif
		
;usbkdo:
	if p_connector=0
		include	USBkdoVDIP.asm
	elseif p_connector=1
		include	USBkdo376.asm
	elseif p_connector=2
		include	sdxkdo.asm
	endif

		endsection

;-------------------------------------------------------------------------------
;Einbindung CRT-TReiber-Erweiterung
;-------------------------------------------------------------------------------

		if p_crt=1
		section crtdrv
		public	   crt,keybu1,keybu2
		include crtdrv.asm
		endsection
		endif

;-------------------------------------------------------------------------------
;Einbindung Monitorzusatzkommandos
;MENU, DUMP, FILL, TRANS, RUN, IN, OUT, MEM, EOR, LOAD, SAVE, FCB
;-------------------------------------------------------------------------------

		if p_zmon=1
;		section eoskdo
;		public	cload,csave,KDOPAR,OUTHX
		include	zmonkdo.asm

; Kommandos vom Z1013
		include	syskdo.asm
;		endsection

		else

;f. ERA und CD		
;fuehrende Leerzeichen ueberlesen
SPACE:		LD	A,(DE)
		CP	A, ' '
		RET	NZ
		INC	DE
		JR	SPACE

		endif


;-------------------------------------------------------------------------------
;weiteres
;HELP
;-------------------------------------------------------------------------------

		;;align	100h

		if p_help=1
		section hlpkdo
		public help
		include	helpkdo.asm
		endsection
		endif


;-------------------------------------------------------------------------------
; SYSINFO dazupacken

	if p_sysinfo=1
	if $ > 0D000h
		error "Modul �berschneidet sich mit SYSINFO!"
	endif

		org	0D000h

		section sysinfo

		binclude	sysinfo_loader.bin
		endsection
	endif		
;-------------------------------------------------------------------------------

PEND		equ	$

	if PBEG <> 0C000h
psum		dw	0
	endif

;;		END
