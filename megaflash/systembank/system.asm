;------------------------------------------------------------------------------
; Z9001 MEGA-FLASH-Modul (2.5M-Modul)
; (c) V. Pohlers 2011
; letzte Änderung 14.10.2012/31.05.2013
; 02.03.2019 Missbrauch von AUR2 für ON_COLD
;------------------------------------------------------------------------------
; Systembank: Banksoftware
;------------------------------------------------------------------------------

	cpu	z80undoc

; Die Banksoftware nutzt die Eigenschaft des OS, eigene CCP zu schreiben
; (über '#       '). Es wird eine eigene Suchroutine CPROM und eine eigene
; Programmstartroutine GOCPM genutzt, die die Bänke mit durchsuchen.
; Gesucht wird immer zuerst in der aktuellen Bank von FF00..100h, dann in
; allen folgenden Bänken bis Bank FF von C000h..E700h.
; WBOOT und Return von normalen Programmen werden umgebogen, damit
; die Programme nach Ende wieder auf die Standardbank schalten.


VERSIONSDATUM	equ	DATE
;VERSIONSDATUM	equ	"08.01.2012"	; für feste Version oder anderen Text..

		section	system
		include	../includes.asm

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
LOCK    	EQU	0F2B8h
GETMS   	EQU	0F35Ch
;LOAD1   	EQU	0F526h
COEXT   	EQU	0F5B9h
ERPAR   	EQU	0F5E6h
ERDIS   	EQU	0F5EAh
WBOOT   	EQU	0F003h	;0F6AEh
;;CONS1		equ	0f758h
;
ERINP		EQU	0F5E2h
REA1		EQU	0F5A6h

;25.06.2013
DECO0		equ	0FD33h		; DECODIEREN DER TASTATURMATRIX

;02.03.2019 10:47:50
AUP2		equ	0EFDFh		; Eigentlich Adresse UP2-Treiber für PUNCH
AUR2		equ	0EFD7h		; Eigentlich Adresse UR2-Treiber für READER
					; hier f. Re-Init ON_COLD genutzt

; !!! Banknummern mit packedroms.asm syncronisieren !!!

	if megarom == "KOMBI"
b_basic		equ	2		;Basic-Bank für ft_BASIC-Programme, s.a. packedroms.asm
b_basicp	equ	4		;Basic-Bank für ft_BASIC-Programme mit neuem PRINT-AT, s.a. packedroms.asm
	else
b_basic		equ	1		;Basic-Bank für ft_BASIC-Programme, s.a. packedroms.asm
b_basicp	equ	2		;Basic-Bank für ft_BASIC-Programme mit neuem PRINT-AT, s.a. packedroms.asm
	endif

	if megarom == "MEGA8"
b_hibanks1	equ	5
b_hibanks2	equ	10
	endif

; Ports
hiram_on	equ	7		;HI-RAM C000-E7FF (64K-RAM-Karte)
hiram_off	equ	6		;HI-RAM C000-E7FF (64K-RAM-Karte)
shadow_on	equ	5		;RAM 4000-7FFF (64K-RAM-Karte)
shadow_off	equ	4
krt_grafik	equ	0B8h		;Port robotron- und KRT-Grafik


	if megarom == "KOMBI"
MZBWS:	EQU	0EC27H		;Merkzelle im BWS (Suchzelle)		(neu)
	endif

;------------------------------------------------------------------------------
; Systemsoftware
;------------------------------------------------------------------------------

		ORG	0C000H
;
PBEG:
		JP	CCP
		DB	"#       ", 0

; testweise, eigentlich nicht nötig, da über OS autom. ausgeführt
; nur falls es mehrere '# ' in der beim Einschalten aktuellen Bank geben sollte ...
		JP	CCP
		DB	"CCP     ", 0

; Anzeige der transienten Kommandos
		JP	MENU
		DB	"DIR     ", 0

		Db	0

;------------------------------------------------------------------------------

; Sprungverteiler für Erweiterungen
on_reset:	jp	0ffffh	; RET
on_cold:	jp	0ffffh	; RET
on_gocpm:	jp	0ffffh	; RET
sys_lastbank:	db	lastbank

;------------------------------------------------------------------------------
; CCP
;------------------------------------------------------------------------------

; Bank-Rückschaltcode, wenn Programm beendet wird
cd_stbk
		phase	bkswcode

FWBOOT: 	ld	hl,WBOOT		; OS-Routine
		push	hl			; Return-Adresse auf Stack
setbk0:		ld	a,systembank
		out	hiram_off, a		; Hi-RAM eines 64K-RAM-Moduls wieder ausschalten
setbk1:		out	bankport, a		; Systembank einschalten
		ret				; WBOOT starten
		dephase
cd_stbke

;------------------------------------------------------------------------------
; vergleicht 2 Strings ....
; de,hl .... die Strings im Speicher
; bc ....... die Lnge
; Rückgabe in BC .... C = 0 -> sie sind gleich

vergleichestrings:
		ld   a, (de)
		inc  de
		cpi				; a mit (hl) vergleichen
		jp   po,vergleicheStrings_ende
		jr   z, vergleichestrings	; falls gleich, dann Spung
vergleichestrings_ende:
		ret

;------------------------------------------------------------------------------
; Ausgabe Copyright-Meldung + Version
copyright:
	if megarom == "KOMBI"
		; cursor setzen
		ld  	de, 0301h
		ld  	c, 18		; SETCU, D Zeile (1-24) E Spalte (1-40)
		call 	5
		call	testkombi	; Ausgabe Kombi-Modul oder 64K-Modul
		ld	de, copyrightmsg3	; 1. Zeile
		ld	c,9
		call	5
	else
		; cursor setzen
		ld  	de, 0114h
		ld  	c, 18		; SETCU, D Zeile (1-24) E Spalte (1-40)
		call 	5
		ld	de, copyrightmsg1	; 1. Zeile
		ld	c,9
		call	5

		ld  	de, 0214h
		ld  	c, 18
		call 	5
		ld	de, copyrightmsg2	; 2. Zeile
		ld	c,9
		call	5

		; cursor auf Prompt setzen
		ld  	de, 0401h
		ld  	c, 18
		call 	5
	endif

		ret

	if megarom == "KOMBI"
; UZ-Modul-Variante herausfinden
; 64K-SRAM: OUT 76 n schaltet immer die 0. RAM-Ebene ein
; KOMBI: OUT 76 n schaltet die n-te RAM-Ebene ein
testkombi:	ld	hl,8000h
		ld	c,76h
		ld	de,0001h
		;
		ld	a,(hl)	; Vergleichswert aus Bank 0
		out	(c),e	; bank1
		ld	b,(hl)	; orig. Wert sichern
		cpl	a	; Vergleichswert negieren
		ld	(hl),a	; in Bank 1 schreiben (= Bank0, wenn sram-modul)
		out	(c),d	; bank0
		cp	(hl)	; Vergleichen (und Ergebnis merken)
		;
		out	(c),e	; bank1
		ld	(hl),b	; orig. Wert restaurieren
		out	(c),d	; bank0
        	
		ld	de, copyrightmsgS
		jr	z,testkombi1	;wenn gleich, dann sram-modul
		;sonst kombi-modul
		ld	de, copyrightmsg1	
testkombi1:	ld	c,9
		call	5
		ret
	endif

copyrightmsg1
	if megarom == "MEGA"
		db	15h,7,14h,0		;schwarz auf weiß
copyrightmsg1a	db	"** MEGA-FLASH-ROM **"
		db	0
	elseif megarom == "MEGA8"
		db	15h,7,14h,0		;schwarz auf weiß
copyrightmsg1a	db	"** MEGA-8KSEG-ROM **"
		db	0
	elseif megarom == "KOMBI"
		db	14h,07h
copyrightmsg1a	db	"KOMBI-MODUL   "
		db	0
copyrightmsgS	db	14h,07h
copyrightmsgSa	db	"64K-SRAM-MODUL"		; 14
		db	0
copyrightmsg3	db	"                         "	; 25 -- DL 25 statt 24
		db	14h,02h			;grün
		db	0dh,0ah,0ah
		db	0
;
	endif

copyrightmsg2
		db	"V.Pohlers "
		db	SUBSTR(VERSIONSDATUM+"      ",0,10)	; Datum als Version 'mm/dd/yyyy'
		db	15h,0
		db	14h,02h			;grün
		db	0

;------------------------------------------------------------------------------
;Ueberpruefen Monitorversion
chkOSVer:	LD	C,12		;RETVN Monitorversion
		CALL	5		;Version abfragen
		LD	A,1
		CP	A, B		;Version 1.x
		JR	NZ, chkOSVer1
		INC	A
		CP	A, C		;Version 1.2.
		RET	Z
		INC	A
		CP	A, C		;Version 1.3.
		RET	Z
chkOSVer1:	LD	A,7		;'BOS-ERROR'
		SCF
		RET

;------------------------------------------------------------------------------
; Eintritt bei '#        '
;

CCP:
		; ursprünglich wg OS1.1 (Z9001.84), sollte jetzt aber gehen
;		call	chkOSVer		; Ueberpruefen Monitorversion
;		jr	nc, CCP1
;		call	prst7
;		db	"unsupported. remove module",0dh,0ah+80h
;		jp	0F089h			; GOCPM im OS

CCP1:		LD	SP,200H

		ld	hl,cd_stbk
		ld	de,FWBOOT
		ld	bc,cd_stbke-cd_stbk
		ldir

		if 	rom_uzander==1
		ld	a,(0FC42h)		
		cp	0CBh			; Herzchen bei Ulrichs geändertem Monitor
		jr	z,CCP2
		endif

		LD	HL,FWBOOT		;ADR. WBOOT FUER CALL 0000
		LD	(1),HL

CCP2:

; dummerweise wird im OS in WBOOT CONST:=CRT gesetzt (IOST1)
; eine andere CONST-Treiber-Zuordnung wird einfach überschrieben :-(
; Ein init-CRT ist damit sinnlos.
; Eine KRT-Grafik muss explizit zurückgesetzt werden

; init CRT
;		ld	a,0FFh			;Initialisieren/Rücksetzen des Gerätes
;		call	CONS1			;log. Gerätetreiber CONST

; Zurückschalten in Textmodus bei KRT-Grafik/robotron-Grafik
		ld	a,0
		out	(krt_grafik),a

; Zurückschalten Standard-RAM
		out	(shadow_off),a		; shadow_off

; RESET-Test
; findet sich das +Robotronschriftzeichen auf dem Bildschirm ???

		ld   	hl, 0ec00h
		ld   	de, 0fc33h		;Text aus OS: "robotron  Z 9001"
		ld   	bc, 10h			;Länge

		call	vergleichestrings	;Zeichenkettenvergleich
		jr	nz, COLD		;nein, dann keine Copyright-Meldung

		; 24.04.2015 zusätzlich Cursorposition testen
		LD 	A,(002CH)		;Kursorzeile
		CP 	a,4			;Zeile 4
		jr	nz, COLD		;nein, dann keine Copyright-Meldung

		ld   	hl, 0ec13h		; 1. Zeile
		ld   	de, copyrightmsg1a	;eigene Meldung schon ausgegeben?
		ld   	bc, 14			;Länge

		call	vergleichestrings	;Zeichenkettenvergleich
		jr	z, COLD		;gleich -> dann gibt es nichts zu tun
		if megarom == "KOMBI"		
						; Test auf 2. Möglichkeit
		ld   	hl, 0ec13h		; 1. Zeile
		ld   	de, copyrightmsgSa	;eigene Meldung schon ausgegeben?
		ld   	bc, 14			;Länge

		call	vergleichestrings	;Zeichenkettenvergleich
		jr	z, COLD		;gleich -> dann gibt es nichts zu tun
		endif

		
		ld	hl,0ffffh		;02.03.2019 AUP2, aur2 rücksetzen
		ld	(AUP2),hl
		ld	(aur2),hl


	; Post-Reset-Init
		call	copyright		;nein -> dann anzeigen
	if megarom == "MEGA8"
		call	inithirom		; für MEGA8: Hi-ROMs kopieren
	endif
		call	on_reset


COLD:
		call	on_cold

	if 	rom_uzander==0		;Treiber werden vom orig ZM überschrieben, das geht
					;daher nicht bei Ulrichs seziellem Release

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
	endif	

;------------------------------------------------------------------------------
; Eintritt bei RET

GOCPM:		LD	SP,200H
;
		ld	a,systembank
		ld	(currbank),a
;
		call	SBOS_init
		LD	HL,GOCPM
		PUSH	HL			;RUECKKEHRADR. KELLERN

		if 	rom_uzander==1
		ld	a,(0FC42h)		
		cp	0CBh			; Herzchen bei Ulrichs geändertem Monitor
		jr	z,GOCPM1
		endif
		ld	hl,setbk0
		push	hl			;davor wieder auf systembank umschalten
GOCPM1:
		LD	HL,STDMA
		LD	(DMA),HL		;STANDARDKASSETTENPUFFER
;;		LD	A,'*'
;;		CALL	OUTA			;AUSGABE PROMPT
		LD	A,'>'
		CALL	OUTA			;AUSGABE PROMPT
;
		call	on_gocpm
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
		CALL	CPROM0			;NAMEN IM SPEICHER SUCHEN
		POP	BC
		JR	Z, JMPHL		;NAMEN GEFUNDEN (HL)=STARTADR.
;Laden von Kassette
INFIL:		ld	hl,0
		ld	(data),hl
		ld	ix,dfltEXT
		CALL	LOAD1			;DATEI LADEN
		RET	C			;FEHLER BEIM LADEN
		LD	HL,(START)		;(HL)=GELESENE STARTADRESSE
		JP	(HL)			;SPRUNG ZUR AUSFUEHRUNG


;------------------------------------------------------------------------------
;Ausführung des Programms
; in:	IYu = 00, wenn in aktueller Bank oder im übrigen Speicher gefunden
;		dann 	HL = Startadr
;	IYu = C3, wenn OS-Rahmen in Bank gefunden
;		dann 	HL = Startadr
;			(currbank) = bank
;	IYu = FA, wenn FA-Rahmen in Bank gefunden
;		dann 	FCB = FA-Header-Kopie
;			HL = Adr. Prg.
;			(currbank) = bank

JMPHL:		ld	a, IYu			;gefundender Programmtyp (aus CPROM)
;aktuell im Speicher
		cp	a,0			;aktuell im Speicher?
		jr	nz, JMPHL_OS
		JP	(HL)			;SPRUNG ZUR AUSFUEHRUNG
;OS-Programm in Bank
JMPHL_OS:	cp	a, 0c3h			;OS-Programm in Bank?
		jr	nz, JMPHL_FA

		PUSH	HL			;Startadr auf Stack
		ld	a,(currbank)
		jp	l_setbank2		;Bank setzen und Programm starten
;
;FA-Programm in Bank
JMPHL_FA:
		;Anzeige Daten
;;		push	hl
;;		call	MENUFF
;;		pop	hl

		;Umlagern und Starten
		call 	FMOV		;nach AAdr. im Speicher kopieren

		dec	de
		ld	(FCB+fa_eadr),de	;eadr merken
		
		jp	FRUN		;je nach Typ starten


;------------------------------------------------------------------------------
; CPROM: Suche Kommando im Speicher.
; RET: Z=1 wenn Transientprogramm gefunden wird
;	Z=0 wenn Programm nicht gefunden wird
;	IYu = 00, wenn in aktueller Bank oder im übrigen Speicher gefunden
;	IYu = C3, wenn OS-Rahmen in Bank gefunden
;		dann 	HL = Startadr
;			(currbank) = bank
;	IYu = FA, wenn FA-Rahmen in Bank gefunden
;		dann 	FCB = FA-Header-Kopie
;			HL = Adr. Prg.
;			(currbank) = bank
; gesucht wird in aktueller Bank oder im übrigen Speicher wie im OS (RAM abwärts)
; die Bänke werden dagegen speicheraufwärts durchsucht
;------------------------------------------------------------------------------

;Suchen in aktueller systembank alles von ROM-Ende bis 100h
CPROM0:		LD	IYl,0FFh		;suchtyp für FA-Rahmen
CPROM:		ld	a, IYl			;suchtyp
		cp	0ffh
		jr	nz, CP3			;keine OS-Suche bei Typsuche
;
		LD	HL,0FC00H		;ANFANGSADRESSE
		ld	IYu,00h
CP1:		PUSH	HL
CP2:		LD	A,0C3H
		CPI				;SPRUNGBEFEHL SUCHEN
		JR	NZ, CP22		;AUF NAECHSTER ADRESSSE SUCHEN
		INC	HL
		INC	HL
		PUSH	BC
		LD	BC,10BH
		CALL	LOCK			;VERGLEICH ZEICHENKETTE
		POP	BC
		JR	Z, CPE1			;GEFUNDEN
		XOR	A
		DEC	HL
		DEC	HL
		CP	A, (HL)
		JR	NZ, CP2			;WEITER MIT KOMMANDOTABELLE
CP22:		POP	HL
		DEC	H			;NAECHSTE 100H-GRENZE
		JR	NZ, CP1
		INC	H
;und jetzt die Bänke von C000h-E700h
		; Code umlagern nach 120h (tmpcmd)
CP3:		call	cp_cdnxbk

		; Code umlagern nach 130h (tmpcmd)
		ld	hl,cd_cprom4
		ld	de,tmpcmd+cd_nxbke-cd_nxbk
		ld	bc,cd_cprom4e-cd_cprom4
		ldir
		; lastbank patchen
		ld	a,(sys_lastbank)
		ld	(CP422p+1), a
		;
		call	CP4			; Suchen in den Bänken
		ret

;TRANS.-KOMMANDO GEFUNDEN
CPE1:		POP	BC			;HL vom Stack holen
		RET


;----------------------
; Bankumschaltung

; Code umlagern nach 110h (tmpcmd)
cp_cdnxbk	ld	hl,cd_nxbk
		ld	de,tmpcmd
		ld	bc,cd_nxbke-cd_nxbk
		ldir
		ret

; folgender Code wird nach 110h (tmpcmd) kopiert
; er darf deshalb nicht zu lang werden (BDOS-Stack beachten)

cd_nxbk
		phase	tmpcmd

; Bankumschaltung
l_nextbank:
		ld	a,(currbank)
		inc	a
	if (megarom == "KOMBI") && (useincport == 1)
		ld	(currbank),a
		out	bankportinc, a
		jr	l_setbank2u	
	else
		jr	l_setbank1
	endif
; Bank A aktivieren
l_setbank0:
		ld	a,systembank
l_setbank1:
		ld	(currbank),a
l_setbank2:	
		out	bankport, a
	if megarom == "KOMBI"
l_setbank2u:	
;		add	a, '0'		; Banknummer 0..9 entspricht der Anzeige
		neg	a		; original TU-ROM-Bank. Herunterzählen
		ld	(MZBWS),A
	endif
		ret
		dephase
cd_nxbke

;----------------------


;----------------------
;Suche in den Bänken
cd_cprom4
		phase	tmpcmd+cd_nxbke-cd_nxbk

CP4:		call	l_nextbank

	if megarom == "KOMBI"
	; kleine Warteschleife
		push	bc
		ld	bc, searchloopdelay		;03000h
l_setbank3:	dec	c
		jr	nz,l_setbank3
		djnz	l_setbank3
		pop	bc
	endif

		ld	hl,bankstart		;Anfang ROM-Bereich C000-DFFF
CP41:		PUSH	HL
		ld	a, 0FAH			;magic token FA-Rahmen?
		cp	a, (hl)
		jr	z,CPF1
CP42:		LD	A,0C3H			;oder OS-Rahmen?
		CPI				;SPRUNGBEFEHL SUCHEN
		JR	NZ, CP422		;AUF NAECHSTER ADRESSSE SUCHEN
;OS-Rahmen
		ld	a, IYl			;suchtyp
		cp	0ffh
		jr	nz, CP422		;keine OS-Suche bei Typsuche
;
		ld	IYu, 0C3H		;IYu = C3h
		INC	HL
		INC	HL
		PUSH	BC
		LD	BC,10BH			;C=Länge+2, 8 Byte Name + 1 Nullbyte
		CALL	LOCK			;VERGLEICH ZEICHENKETTE
		POP	BC
		JR	Z, CPE41		;GEFUNDEN
		XOR	A
		DEC	HL
		DEC	HL
		CP	A, (HL)
		JR	NZ, CP42		;WEITER MIT KOMMANDOTABELLE
CP422:		POP	HL
		INC	H			;NAECHSTE 100H-GRENZE

; 22.05.2015 UZ möchte, dass der RAM auch mit durchsucht wird, also kein abwechselndes Ende
;	if megarom == "KOMBI"
;		ld	a,(currbank)
;		rra				; bit 0 ins Cy-Flag
;		ld	a,hi(bankende)		;Ende-ROM-Bereich?
;		jr 	nc, CP422a
;		ld	a,hi(bankende2)
;CP422a:
;	else
		ld	a,hi(bankende)		;Ende-ROM-Bereich?
;	endif
		cp	h
		JR	NZ, CP41
		INC	H
		ld	a,(currbank)
CP422p:		cp	lastbank		; Bank FF überschritten? (wird gepatcht)
		jr	nz,CP4
;ende - alles durchsucht, aber nicht gefunden
		call	l_setbank0		; Systembank einschalten
		inc	h			; z-flag löschen
		ret				; NICHT GEFUNDEN

;TRANS.-KOMMANDO GEFUNDEN
CPE41:		POP	BC			;HL vom Stack holen
		jr	CPFE1

; FA-Rahmen
CPF1:		inc	hl
		cpi				;2x gefunden?
		jr	nz,CP422		;nein
		ld	IYu, a			;IYu = FAh
		;Test auf Dateityp
	;	ld	b,(hl)			;Dateityp
	;	res	7,b			;packed ausblenden
		ld	a,(hl)			;Dateityp
		and	ft_typmask		;Typ maskieren
		ld	b,a
		ld	a, IYl			;suchtyp
		cp	0ffh
		jr	z, CPF2
		cp	b			;Typ gleich?
		jr	nz,CP422		;nein
		jr	CPF2a
		;
CPF2		;29.06.2015 kleiner Hack, damit Hilfetexte nicht allgemein gefunden werden
		ld	a,ft_HELP	; Hilfedatei bei Syschtyp 0ffh?
		cp	b
		jr	z,CP422		; dann diese übergehen

CPF2a		inc	hl			;typ übergehen
		LD	BC,10AH			;C=Länge+2, Länge Namen=8
		CALL	LOCK			;VERGLEICH ZEICHENKETTE
		jr	nz,CP422		;nein
		;GEFUNDEN
		POP	HL			;KOMMANDO GEFUNDEN: HL=Adr. FA-Header
		ld	de,FCB			;FA-Header in FCB kopieren
		ld	bc,20h
		ldir				;HL=Adr. Prg.

CPFE1:		ld	a, systembank
		out	bankport, a
		RET				;Z=1 von CALL LOCK

		dephase
cd_cprom4e
;----------------------


;------------------------------------------------------------------------------
; FA-Programm in Speicher kopieren
;------------------------------------------------------------------------------

; in HL: Prog, currbank: Bank, FCB: FA-Header

;nach AAdr. im Speicher kopieren
FMOV:
;;		; Bankumschalt-Code umlagern nach 120h (tmpcmd)
;;		call	cp_cdnxbk
;;ist noch da von CPROM

		ld	a,(FCB+fa_kategorie)	;Dateikategorie
		and	fk_shadow		;Shadow-RAM zuschalten?
		jr	z, FMOVs		;nein

		out	(shadow_on),a		;Shadow-RAM ein

FMOVs:		ld	a,(FCB+fa_typ)		;Dateityp
		bit	7,a
		jr	nz, FMOVP		;wenn gepackt

;ungepackte Dateien

		push	hl
		; Code umlagern nach 130h (tmpcmd)
		ld	hl,cd_fmov
		ld	de,tmpcmd+cd_nxbke-cd_nxbk
		ld	bc,cd_fmove-cd_fmov
		ldir

		pop	hl			;ROM-Adr.
		ld	de,(FCB+fa_aadr)	;aadr (Ziel)
		ld	bc,(FCB+fa_length)	;Länge
		call	FMOV0			;Kopieren
		ret

;gepackte Dateien
FMOVP:		;;call	prst7
		;;db	"PACKE", 'D'+80h

		push	hl
		; Code umlagern nach 130h (tmpcmd)
		ld	hl,cd_fmovp
		ld	de,tmpcmd+cd_nxbke-cd_nxbk
		ld	bc,cd_fmovpe-cd_fmovp
		ldir

		pop	hl			;ROM-Adr.
		ld	de,(FCB+fa_aadr)	;aadr (Ziel)
		ex	af,af'			;af' retten f. GVAL
		push	af
		call	FMOVP0			;Kopieren
		pop	af
		ex	af,af'			;'
		ret

;----------------------
;ungepackte Dateien kopieren
cd_fmov
		phase	tmpcmd+cd_nxbke-cd_nxbk

FMOV0:		ld	a,(currbank)
		out	bankport, a

FMOV1:		ldi
		push	af
		call	hlcheck			; wurde E000 erreicht? dann Bankwechsel
		pop	af
		jp	pe, FMOV1

		ld	a, systembank
		out	bankport, a

		ret

hlcheck:
	if megarom == "KOMBI"
		ld	a,(currbank)
		rra				; bit 0 ins Cy-Flag
		ld	a,hi(bankende)		;Ende-ROM-Bereich?
		jr 	nc, hlchecka
		ld	a,hi(bankende2)
hlchecka:
	else
		ld	a,hi(bankende)		;Ende-ROM-Bereich?
	endif
		cp   	h
		ret	nz
		call	l_nextbank		; Bank switchen
		ld   	hl, bankstart
		ret

		dephase
cd_fmove
;----------------------

;----------------------
;gepackte Dateien kopieren
cd_fmovp
		phase	tmpcmd+cd_nxbke-cd_nxbk

FMOVP0:		ld	a,(currbank)
		out	bankport, a
		call	depack
		ld	a, systembank
		out	bankport, a
		ret

;Achtung: die Entpackroutine ist relativ lang (130h-1D8h) und überschreibt den BOS-Stack
;deshalb dürfen während des Entpackens keine BOS-Aufrufe erfolgen !!!
;evtl mit DI .. EI kapseln

;DX7-Unpacker: 12Bh-187h

		include	"unpack_dx7.asm"

		dephase
cd_fmovpe
;----------------------



;------------------------------------------------------------------------------
; FA-Programm starten
; je nach Typ starten
;------------------------------------------------------------------------------
FRUN:
;Zielbank
		ld	a,(currbank)		; Startbank merken
		ld	b,a

		ld	a,(FCB+2)		; Dateityp ft_xx
		and	ft_bankmask		; 01111000 Bit 6543 = Bank
		srl	a
		srl	a
		srl	a
		cp	15			; speziell systembank
		jr	z, FRUN0
		cp	0			; keine Bank festgelegt?
		jr	nz, FRUN1
	IF sysbankretrn == 0
		jr	FRUN1a			; UZ möchte Bankanzeige behalten
	ENDIF
FRUN0:		ld	a, systembank
FRUN1:		ld	(currbank),a
;Dateityp
FRUN1a:		ld	a,(FCB+2)		; Dateityp ft_xx
		and	ft_typmask		; FLASH-Dateityp 00000111b
		cp	ft_MC
		jr	z, FRUN_MC
		cp	ft_BASIC
		jr	z, FRUN_BAS
		ret
;
;MC-Programm
FRUN_MC:	ld	hl,(FCB+fa_sadr)	;sadr
		push	hl

		push	bc			; bank b merken, wird z.b. f chkrom genutzt
		call	FA_FCB			; FCB erstellen
		pop	bc

		ld	a,(currbank)
		jp	setbk1
		;;jp	(HL)
		
;02.03.2019 Die FA-Daten in einen FCB konvertieren 
;fa_eadr wird beim Laden passend gesetzt.
FA_FCB:		

;005C 	FCB: 	BER 36 		;Dateikontrollblock
;005C	FNAME: 	EQU FCB 	;Dateiname 8 Zeichen, ggf. mit 00 auffüllen
;0064	FTYP: 	EQU FCB+8 	;Dateityp 3 Zeichen, ggf. mit 00 auffüllen
;0069	PSUM: 	EQU FCB+13 	;Prüfsumme eines Datenblockes
;006A	ARB: 	EQU FCB+14 	;Hilfszelle für Kassettentreiber
;006B	BLNR: 	EQU FCB+15 	;Blocknummer
;006C	LBLNR: 	EQU FCB+16 	;gesuchte Blocknummer bei Lesen
;006D	AADR 	EQU FCB+17 	;Dateianfangsadresse
;006F	EADR 	EQU FCB+19 	;Dateiendeadresse
;0071	SADR 	EQU FCB+21 	;Startadresse, wenn Datei ein Maschinencodeprogramm ist
;0073	SBY: 	EQU FCB+23 	;Schutzbyte. 0 nicht geschützt, 1 System nach Laden der Datei vor WRITE geschützt
;
;
;	org	xx00h		; header
;	db	0FAh, 0FAh	; +0 Kennbytes
;	db	Dateityp	; +2 0-MC, 1-BASIC (s. ../includes.asm)
;	db	"NAME    "	; +3 genau 8 Zeichen
;	dw	aadr		; +11 Anfangsadresse im RAM
;	dw	eadr		; +13 Endadresse im RAM
;	dw	sadr		; +15 Startadresse im RAM (oder FFFFh - nichtstartend)
;	dw	länge		; +17 (Datei-)Länge des nachfolgenden Programms
;	db	Dateikategorie	; +19 Standard 0 (s. ../includes.asm)
;	db	"Kommentar   "	; +20 12 Zeichen, bel., z.B. Autor o.ä.

		ld	hl,fcb+11	;FA: aadr,eadr,sadr
		ld	de,fcb+17	;OS: aadr,eadr,sadr
		ld	bc,6
		ldir			;überlappung passt :-)
		ld	hl,fcb+3	;FA: name, mit leerzeichen aufgefüllt
		ld	de,fcb+0	;OS: name, mit 0-bytes aufgefüllt
		ld	b,8
FA_FCB2:	ld	a,(hl)		;Leerzeichen zu 0-Bytes
		cp	' '
		jr 	nz,FA_FCB1
		xor	a		; A := 0
FA_FCB1:  	ld	(de),a
		inc	hl
		inc	de
		djnz	FA_FCB2
		;COM eintragen
		ld	hl,"OC"
		ld	(fcb+8),hl
		ld	a,'M'
		ld	(fcb+10),a
		ret
;
;BASIC-Programm
FRUN_BAS:
		; Code umlagern nach 130h (tmpcmd)
		push	de
		ld	hl,cd_frunb
		ld	de,tmpcmd+cd_nxbke-cd_nxbk
		ld	bc,cd_frunbe-cd_frunb
		ldir
		pop	de

		ld	b, b_basic		; basicbank einschalten
		; evtl. Basic mit neuem Print-at zuschalten
		ld	a,(IOBYT)
		and	11b			; CONST-Treiber
		cp	1			; CRT?
		jr	z,FRUN_BAS00
		ld	b, b_basicp		; nein-anderer Treiber, also Grafik-Basic nehmen

	IF sysbankretrn == 0

FRUN_BAS00:	jp	FRUN_BAS1

	ELSE
		; evtl. Bank manuell wechseln (wenn im FA-Header festgelegt)
FRUN_BAS00:	ld	a,(currbank)
		cp	systembank
		jr	z,FRUN_BAS0
		ld	b, a			; zu nutzende Basic-Bank patchen

FRUN_BAS0:	ld	a, b_basic		; basicbank einschalten
		jp	FRUN_BAS1

	ENDIF
;----------------------
;Kopieren
cd_frunb

	phase	tmpcmd+cd_nxbke-cd_nxbk

FRUN_BAS1: 	ld	a, b			; basicbank einschalten
		out	bankport,a

; Basic-Kaltstart (c) 09.10.2011 vp
; Programm ab (SVARPT)-2 laden (Std. 0401h)
; am Ende SVARPT := auf erstes Byte hinter Programm setzen

	; DE = Adr. hinter Programm
	ld	(03D7h), de	; SVARPT setzen

; Kaltstart

	LD	HL,0C0BDh	; RAMST
     	LD	DE,00300h	; WSP
     	LD	BC,67h
     	LDIR
     	EX	DE,HL
     	LD	SP,HL
     	xor 	A
     	LD	(03ABh),A	; EOINPB
     	LD	(0400h),A	; PRAM-1
     	;Reserviere Arbeitsrambereich
     	LD	HL, (0036h)	; EOR	oberes RAM-Ende
     	LD	DE,-256
     	LD	(03B0h),HL	; MEMSIZ
     	ADD	HL,DE
     	LD	(0356h),HL	; STDPTR
     	LD	A, 0AFH
     	LD	(03FCh),A	; EXTFLG

; Zeilenanfangsadressen korrigieren

	CALL	0C64Fh		; NEW2
	INC	HL
	EX	DE,HL
	call	0C493h		; LIN11

; und starten

     	call	0C669h		; INITR	; SP setzen
	jp	0C854H		; RUNMOD

	dephase

cd_frunbe
;----------------------

	if megarom == "MEGA8"

;------------------------------------------------------------------------------
; Mega-8 HI-ROM init
;------------------------------------------------------------------------------

; MEGA8 hat jeweils 8K ROM C000-DFFF und jeweils 2K RAM E000-E7FF pro Bank
; In den Bänken sind die originalen 10K-Bänke aufgeteilt auf jeweils
; 4 Bänke a 8 K, die 5. Bank enthält die jeweils oberen 2K dieser 4 Bänke

; Bei der Initialisierung werden die oberen 2K in die RAM-Bereiche der 
; Bänke kopiert

inithirom:
		; Code umlagern nach 130h (tmpcmd)
		ld	hl,cd_hirom
		ld	de,tmpcmd+cd_nxbke-cd_nxbk
		ld	bc,cd_hirome-cd_hirom
		ldir
		;
		call	hirom
		;
		ret

;----------------------
;Kopieren
cd_hirom

	phase	tmpcmd+cd_nxbke-cd_nxbk
hirom		ld	a,b_hibanks1		; Bank Nr. 5 enthält die oberen 2K
		call	hirom0			; von Bank 1..4
		ld	a,b_hibanks2		; Bank Nr. 10 enthält die oberen 2K
		call	hirom0			; von Bank 6..9
		ld	a,systembank		
		jp	setbk1			; und zurück zum System
;

hirom0		call	setbk1			; Bank setzen
		ld	hl,0C000h		; 4x 2K zwischenpuffern
		ld	de,2000h
		ld	bc,2000h
		ldir

; die oberen 2K in einer Extra-Bank
; alles um ein Byte verschoben, damit die OS-RAHMEN nicht gefunden werden

		ld	hl,2001h		; Zwischenpuffer + 1
		ld	b,4			; 4 Teile
		sub	a,b			; A war 5 (oder 10), nun 1 (bzw. 6)
hirom1		push	bc
		call	setbk1			; Bank A setzen
		ld	de,0E000h		; 2K kopieren
		ld	bc,800h
		ldir
		pop	bc
		inc	a			; nächste Bank
		djnz	hirom1
		ret

	dephase

cd_hirome
;----------------------
	endif

;------------------------------------------------------------------------------







;------------------------------------------------------------------------------
;* 	C L O A D   -   KOMMANDO                                   *
; muss leider aus OS kopiert werden, da im OS keine Nutzung der SBOS-Systemrufe :(
;------------------------------------------------------------------------------
;
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
	CALL	REA1		;AUSG. FEHLERMELD. WARTEN REAKT.
	RET	C		;STOP GEGEBEN
	JR	LOAD4		;WIEDERHOLUNG
LOAD5:	ld	hl,(data)	;neue aadr?
	ld	a,h
	or	l
	jr	nz,LOAD51
	LD	HL,(FCB+17)	;DATEIANFANGSADRESSE
LOAD51:	LD	(DMA),HL	;NACH ADR. KASSETTENPUFFER
LOA55:
	;CALL	READ		;LESEN BLOCK
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
	LD	HL,INTLN+1	;ZWISCHENPUFFER
loa31:	CALL	MOV1
LOA33:	POP	HL
	EX	AF, AF'		;'
	JP	NC, ERINP	;ZU VIELE PARAMETER
	ccf
	ret

;------------------------------------------------------------------------------
; Unterprogramme
;------------------------------------------------------------------------------

;OUTHL Ausgabe (HL) hexa
;
OUTHL:		LD	A,H
		CALL	OUTHX
		LD	A,L
;
;OUTHX Ausgabe (A) hexa
;
OUTHX:		PUSH	AF
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	OUTH1
		POP	AF
OUTH1:		AND	A, 0FH
		ADD	A, 30H
		CP	A, 3AH
		JR	C, OUTH2
		ADD	A, 07H
OUTH2:		CALL	OUTA
		RET
;
;COOUT Ausgabe ab (HL) (B) Zeichen, nur Buchstaben
;
COOUT:		LD	A,(HL)
		CP	A, ' '
		JR	NC, COUT1		; A>=' '
		LD	A,'.'
COUT1:		CALL	OUTA			;Zeichen ausgeben
		INC	HL
		DJNZ	COOUT
		RET
;
;WAIT Unterbrechung Programm, wenn <PAUSE> gedrueckt,
;     weiter mit beliebiger Taste
;
WAIT:		CALL	CSTS			;Abfrage Status
		OR	A
		RET	Z			;keine Taste gedrueckt
		CALL	CONSI			;Eingabe
		CP	A, 03H			;<STOP>?
		JP	Z, GOCPM
;
		CP	A, 013H			;<PAUSE>?
		RET	NZ			;nein
		CALL	CONSI			;Eingabe
		RET
;;

;;Farben
c_rot		ld	e,1
		jr	color
c_gruen		ld	e,2
		jr	color
c_gelb		ld	e,3
		jr	color
c_blau		ld	e,4
		jr	color
c_magenta	ld	e,5
		jr	color
c_cyan		ld	e,6
		jr	color
c_white		ld	e,7
;
color		ld	a,14h
		call	outa
		ld	a,e
		call	outa
		ret

;------------------------------------------------------------------------------
;25.06.2013
;------------------------------------------------------------------------------

; Test,	ob <STOP> gedrückt -> Cy=1
stopkey:	call	DECO0		; DECODIEREN DER TASTATURMATRIX
		ei
		or	a
		ret	z
		cp	3		; <STOP> ?
		scf
		ret	z
		ccf
		ret

;CLOAD
;in:
;   A=0 => Dateiname+Typ ist bereits im FCB eingetragen
;   A=1 => Dateiname "Name[.Typ]" muss in CONBU abgelegt sein
;   A=2 => zuerst Abfrage "Filename:"
;   A=3 => Dateiname "Name[.Typ]" muss in CONBU abgelegt sein, ohne initiales GVAL
;   A+80h -> in IX Zeiger auf Default-Dateityp, sonst COM
;   HL = 0 => orig. aadr wird genommen
;   HL <> 0 => aadr
;ret: Cy=1 Fehler
cload:		bit 	7,a
		jr 	nz,cload0
		ld 	ix,dfltext
cload0:		res 	7,a
		ld	(data),hl	; HL merken
		or	a
		jp	z, LOAD4	; A=0 -> Dateiname+Typ ist bereits im FCB eingetragen
		dec	a
		jr	z, cload1	; A=1 => Dateiname+Typ steht in CONBU
		dec	a
		jr	z, cload2	; A=2 => Filename abfragen
		jp	LOAD1		; A=3 => Dateiname+Typ steht in CONBU;  ohne GVAL

cload2:		call	getfname	; A=2 => Filename abfragen
		ret	c
cload1		jp	LOAD

;Filename abfragen, Eingabe als "Name[.Typ]"
getfname:	ld	de, aFilename	; Kassetten-I/O: Filename abfragen+laden/speichern
		ld	c,9
		call	5
		call	GETMS		; EINGABE ZEICHENKETTE IN MONITORPUFFER
		ret	c
		call	COEXT		; VORVERARBEITEN EINER ZEICHENKETTE
		ret
aFilename:	db "Filename: ",0
dfltEXT:	db	"COM"

;CSAVE
;
csave: 		bit 	7,a
		jr 	nz,csave0
		ld 	ix,dfltext
csave0:		res 	7,a
 		or	a
		jp	z, csave1	; A=0 -> Dateiname+Typ ist bereits im FCB eingetragen
		dec	a
		jr	z, csave4	; A=1 => Dateiname+Typ steht in CONBU
;
		call	getfname	; A=2 => Filename abfragen
		ret	c
;
csave4:		CALL	GVAL		;NAECHSTEN PARAMETER HOLEN
		RET	Z		;KEIN GUELTIGER NAME
		call	prepfcb
		ret	c
;
csave1		ld	hl, (fcb+19)	; EADR
		ld	de, (fcb+17)	; AADR
		or	a
		sbc	hl, de
		ret	c		; aadr > eadr
		ld	c, 15		;OPENW: Eroeffnen Kassette schreiben
		call	5
		ret	c
		call	ospac		; Ausgabe Leerzeichen
		call	stopkey		; Test auf <STOP>
		ret	c		; wenn STOP
		ex	de, hl
		ld	(DMA), hl
csave3:		ld	hl, (DMA)
		ld	de, 7Fh
		add	hl, de
		ld	de, (fcb+19)	; EADR
		sbc	hl, de
		jr	nc, csave2
		ld	c, 21		; WRITS: Schreiben eines Blockes auf Kassette
		call	5
		ret	c
		call	ospac		; Ausgabe Leerzeichen
		call	stopkey		; Test auf <STOP>
		ret	c		; wenn STOP
		jr	csave3
csave2:		ld	c, 16		; CLOSW: Abschlie¯en Kassette schreiben
		call	5
		ret	c
		JP	OCRLF
;

;------------------------------------------------------------------------------
;   ***SUPERVISOR***
;------------------------------------------------------------------------------

SBOS_init:
	LD	A,0C3H		;Sprungverteiler eintragen
	LD	(rst_sbos),A	;RST-Ruf
	LD	HL,SBOS
	LD	(rst_sbos+1),HL
	ret

;externe Nutzungsmoeglichkeit von Routinen
;
SBOS:	EX	(SP),HL
	PUSH	AF
	LD	A,(HL)		;Byte nach RST
	ex	af,af'		;merken
	INC	HL		;Rueckkehradr.
	POP	AF
	EX	(SP),HL		;kellern
	PUSH	HL
	PUSH	BC
	PUSH	AF
	LD	HL,SBTAB	;Sprungtabelle
	ex	af,af'		;Byte nach RST
	SLA	A		;x2
	LD	C,A
	LD	B,0
	ADD	HL,BC		;HL=Tab.adr.
	LD	A,(HL)
	INC	HL
	LD	H,(HL)
	LD	L,A		;HL=Adr. Routine
	POP	AF
	POP	BC
	EX	(SP),HL		;Ansprung
	RET			;Routine
;
;
;Sprungtabelle fuer Supervisor
SBTAB:	DW	OUTHX		;0 Ausgabe (A) hexa
	DW	OUTHL		;1 Ausgabe (HL) hexa
	DW	WAIT		;2 Unterbrechung Lauf
	DW	color		;3 Vordergrundfarbe (E)
	DW	CPROM		;4 Suchen Namen
	DW	FMOV		;5 FA-Programm in Speicher kopieren
	DW	FRUN		;6 FA-Programm starten
	DW	KDOPAR		;7 Kommandoparameter aufbereiten
	DW	INHEX		;8 Konvertierung ASCII-Hex ab (DE) --> (HL)
	DW	PRST7		;9 Ausgabe String bis Bit7=1
	DW	GOCPM		;10 Warmstart
	DW	JMPHL		;11 Program starten (nach CPROM)
	DW	cp_cdnxbk	;12 Bankumschalt-Code umlagern nach tmpcmd
	DW	stopkey		;13 Test, ob <STOP> gedrückt -> Cy=1
	dw	cload		;14 Datei laden. in: (fcb), hl, a
	dw	csave		;15 Datei speichern. in: (fcb), a
	dw	COOUT		;16 Ausgabe ab (HL) (B) Zeichen, nur Buchstaben

;-------------------------------------------------------------------------------
; der DIR-Befehl
;-------------------------------------------------------------------------------
		
	if megarom == "KOMBI"
		include	"dir_kombi.asm"
	else
		include	"dirkdo.asm"
	endif

		message	"=============================> Min-System-Ende \{$}"

;-------------------------------------------------------------------------------
; OS-Rahmen für zusätzliche Kommandos
;-------------------------------------------------------------------------------

		align 100h

		JP	HELP
		DB	"HELP    ", 0

; vom Z1013 (noch ohne Bankparameter)

		JP	D_KDO
		DB	"DUMP    ", 0

		JP	K_KDO
		DB	"FILL    ", 0

		JP	T_KDO
		DB	"TRANS   ", 0

		JP	J_KDO
		DB	"RUN     ", 0

		JP	I_KDO
		DB	"IN      ", 0

		JP	O_KDO
		DB	"OUT     ", 0

		JP	MEM
		DB	"MEM     ", 0

; weitere Kommandos

		JP	EOR
		DB	"EOR     ", 0

		JP	CLS
		DB	"CLS     ", 0

		JP	CURSOR
		DB	"C       ", 0

		JP	KDO_LOAD
		DB	"LOAD    ", 0

		JP	KDO_SAVE
		DB	"SAVE    ", 0

		jp	KDO_FCB
		db	"FCB     ", 0

		JP	VER
		DB	"VER     ", 0
		
		Db	0

;-------------------------------------------------------------------------------
; HELP
;-------------------------------------------------------------------------------

		include	"help.asm"

;-------------------------------------------------------------------------------
; Systemkommandos
;-------------------------------------------------------------------------------
		include	"syskdo.asm"


;-------------------------------------------------------------------------------

VER:		ld	de, version
		ld	c,9
		call	5
		ret

; ROM-Eintrag

version:	db	"(c) V.Pohlers, Neustadt i.H., "
		db	DATE
		db	13,10,0

		endsection

;-------------------------------------------------------------------------------


		END
