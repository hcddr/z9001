		page	0

;------------------------------------------------------------------------------
; 20.05.2004 volker pohlers; letzte Änderung 12.05.2013
; basierend auf der PDF-Datei von U. Zander habe ich das Listing korrigiert
; und an den Arnold-Assembler angepasst. Das erzeugte Binärfile entspricht
; zu 100% dem BIOS des Z9001.
; Lediglich die Meldungstexte wurden an die Schreibweise des BIOS des Z9001
; angepasst (orig. Zeilen 2225-2252).
;
; vp 2007: Einbindung aller bekannten Versionen des OS
; vp 2007: Einbinden der ROMBANK-Erweiterung von U.Zander
; vp 2007: erweiterte Dokumentation im Listing
; vp 19.10.2009: OS 1.1 ergänzt
; vp 21.01.2011: neu strukturiert, einzelne Patches sind optional wählbar
;	neu eorpatch, krtgrafik
; vp 24.01.2011  neuer Patch von U.Zander f. SHLOC
; vp 12.05.2013  Kommentare f. Kassettenroutinen erweitert
; vp 15.08.2018 Umbau auf aktuelle Version von rb (kc873sys.zip, kc873_sys_links_CEEF.bin vom 23.4.2014)
;------------------------------------------------------------------------------

; OS-Version 1.1, 1.2 oder 1.3
osver		equ	12	;11,12,13

; Systemversion, setzt sich aus Einzelpatches zusammen
sysver		equ	"rb"	;os,rb21,rb,vp

		if sysver == "os"
;Standard-OS, keine Patches
tastneu		equ	0	; geänderte Tastaturabfrage Version RB21
shlocFlg	equ	0	; Nutzung von Adr. 26h (SHLOC) statt PIO 88h f. CAPS LOCK Flag
;; nur wenn tastneu = 1, können die nachfolgenden Patches genutzt werden
farb16		equ	0	; 16-Farben-Unterstützung
rombank		equ	0	; ROM-Bank durchsuchen
rommenu		equ	0	; Option f. ROM-Bank: autom. Aufruf von "H"
eorpatch	equ	0	; Geänderte Speicherinitialisierung wg. abschaltbarer Module
krtgrafik	equ	0	; bei interner Zeichenausgabe KRT abschalten
;geänderte Begrüßung 16 Zeichen, wenn leer, dann orig. "robotron  Z 9001"
;resmsg		equ	"robotron  Z 9001"

		elseif sysver == "rb21"
; Version U. Zander RB21
tastneu		equ	1	; geänderte Tastaturabfrage Version RB21
shlocFlg	equ	0	; Nutzung von Adr. 26h (SHLOC) statt PIO 88h f. CAPS LOCK Flag
farb16		equ	1	; 16-Farben-Unterstützung
rombank		equ	1	; ROM-Bank durchsuchen
rommenu		equ	1	; Option f. ROM-Bank: autom. Aufruf von "H"
eorpatch	equ	0	; Geänderte Speicherinitialisierung wg. abschaltbarer Module
krtgrafik	equ	0	; bei interner Zeichenausgabe KRT abschalten
resmsg		equ	" Z-80 COMPUTER Ë"	; U. Zander f. RB21

		elseif sysver == "rb"
; Version U. Zander farb16neu 24.01.2011
; Änderung gegenüber tastneu: Nutzung von Adr. 26h (SHLOC) statt PIO 88h f. CAPS LOCK Flag
; Anpassung 15.08.2018 an kc873_sys_links_CEEF.bin 23.4.2014
tastneu		equ	1	; geänderte Tastaturabfrage Version RB21
shlocFlg	equ	1	; Nutzung von Adr. 26h (SHLOC) statt PIO 88h f. CAPS LOCK Flag
farb16		equ	1	; 16-Farben-Unterstützung
rombank		equ	1	; ROM-Bank durchsuchen
rommenu		equ	0	; Option f. ROM-Bank: autom. Aufruf von "H"
eorpatch	equ	1	; Geänderte Speicherinitialisierung wg. abschaltbarer Module
krtgrafik	equ	0	; bei interner Zeichenausgabe KRT abschalten
resmsg		equ	"robotron Z9001 Ë"	; farb16

		elseif sysver == "vp"
; Version VP
tastneu		equ	1	; geänderte Tastaturabfrage Version RB21
shlocFlg	equ	1	; Nutzung von Adr. 26h (SHLOC) statt PIO 88h f. CAPS LOCK Flag
farb16		equ	1	; 16-Farben-Unterstützung
rombank		equ	0	; ROM-Bank durchsuchen
rommenu		equ	0	; Option f. ROM-Bank: autom. Aufruf von "H"
eorpatch	equ	1	; Geänderte Speicherinitialisierung wg. abschaltbarer Module
krtgrafik	equ	1	; bei interner Zeichenausgabe KRT abschalten
resmsg		equ	"Z9001 kompakt   "	; VP
		endif

	;PN	MONITOR 16.08.85
;
;MONITOR FUER SERIENGERAET 1985
;V 01.02.
;
;	TITL	' R0BOTRON  Z  9001  -  MONITOR '
;
	cpu	z80
	ORG	0F000H
;
;*******************************************************************
;*                                                                 *
;*	MONITOR - D E F I N I T I O N E N                          *
;*                                                                 *
;*******************************************************************
;
IOBYT:	EQU	4		;I/O-BYTE
SPSV:	EQU	0BH		;REGISTER FUER NUTZERSTACK
BCSV:	EQU	0DH		;REGISTER FUER BC
ASV:	EQU	0FH		;REGISTER FUER A
JOYR:	EQU	13H		;SPIELHEBEL 1
JOYL:	EQU	14H		;SPIELHEBEL 2
LISW:	EQU	15H		;SCHALTER FUER DRUCKERAUSGABE
BSW:	EQU	16H		;SCHALTER KONTROLLTON
COLSW:	EQU	17H		;PUFFER FARBSTEUERCODE
DMA:	EQU	1BH		;ZEIGER AUF KASSETTENPUFFER
STUND:	EQU	1DH		;PUFFER STUNDEN
MIN:	EQU	1EH		;PUFFER MINUTEN
SEK:	EQU	1FH		;PUFFER SEKUNDEN
COUNT:	EQU	23H		;ZAEHLER CTC2 - INTERRUPTS
LAKEY:	EQU	24H		;LETZTES GUELTIGES ZEICHEN
KEYBU:	EQU	25H		;TASTATURPUFFER
SHLOC:	EQU	26H		;SCHALTER SHIFT LOCK
ATRIB:	EQU	27H		;AKTUELLES FARBATRIBUT
CHARP:	EQU	2BH		;ZEIGER AUF SPALTE
LINEP:	EQU	2CH		;ZEIGER AUF ZEILE
CURS:	EQU	2DH		;PHYS. CURSORADRESSE
PU:	EQU	2FH		;HILFSZELLE			(TIME + Status CONST)
WORKA:	EQU	33H		;HILFSZELLE			(ASGN)
BUFFA:	EQU	34H		;PUFFER FARBCODE		Zeichen unter Cursor
BU:	EQU	35H		;HILFSZELLE			(RCONB)
EOR:	EQU	36H		;ZEIGER AUF LOG. RAM - ENDE
P1ROL:	EQU	3BH		;1. ZU ROLLENDE ZEILE-1
P2ROL:	EQU	3CH		;LETZTE ZU ROLLENDE ZEILE+1
P3ROL:	EQU	3DH		;1. ZU ROLLENDE SPALTE-1
P4ROL:	EQU	3EH		;LETZTE ZU ROLLENDE SPALTE+1
BUFF:	EQU	3FH		;PUFFER FUER ZEICHEN		unter Cursor
PARBU:	EQU	40H		;HILFSZELLE			(ASGN)
FCB:	EQU	5CH		;FILE-CONTROL-BLOCK
PSUM:	EQU	69H		;PRUEFSUMME
ARB:	EQU	6AH		;ARBEITSZELLE
BLNR:	EQU	6BH		;BLOCKNUMMER
LBLNR:	EQU	6CH		;ZU LESENDE BLOCKNUMMER
AADR:	EQU	6DH		;ANFANGSADRESSE
EADR:	EQU	6FH		;ENDADRESSE
START:	EQU	71H		;STARTADRESSE
CONBU:	EQU	80H		;CCP ZEICHENKETTENPUFFER
STDMA:	EQU	80H		;STANDARDPUFFER FUER KASSETTE
INTLN:	EQU	100H		;INTERNER ZWISCHENPUFFER
SCTOP:	EQU	0EC00H		;ADR. ZEICHENSPEICHER
MAPPI:	EQU	0F000H-64	;SYSTEMBYTE
MAPAR:	EQU	MAPPI+1		;64 BIT KONFIG.-REGISTER
ATTY:	EQU	MAPAR+8		;ADR. TREIBERADRESSVEKTOR
ACRT1:	EQU	ATTY+2		;VEKT.-ADR. CRT-TREIBER CONST
ABAT:	EQU	ACRT1+2		;VEKT.-ADR. BAT-TREIBER CONST
ACRT2:	EQU	ACRT1+24	;VEKT.-ADR. CRT-TREIBER LIST
TXCON:	EQU	ATTY+32		;ZEICHENKETTENADRESSVEKTOR
				;VEKT.-ADR. STRING FUER CONST
TXRDR:	EQU	TXCON+2		;VEKT.-ADR. STRING FUER READER
TXPUN:	EQU	TXCON+4		;VEKT.-ADR. STRING FUER PUNCH
TXLPT:	EQU	TXCON+6		;VEKT.-ADR. STRING FUER LIST
LINEL:	EQU	40		;LAENGE PHYSISCHE BILDSCHIRMZEILE
ONEKB:	EQU	400H		;KONSTANTE 1 KBYTE
STIOB:	EQU	1		;STANDARD I/O-BYTE
TYPIE:	EQU	2		;TYP EINGABEFEHLER
ZYPRE:	EQU	3		;TYP BEREICHSFEHLER
CURSL:	EQU	8		;CURSOR LINKS
CURSR:	EQU	9		;CURSOR RECHTS
CURSD:	EQU	0AH		;CURSOR RUNTER (LF)
CURSU:	EQU	0BH		;CURSOR HOCH
CLEAR:	EQU	0CH		;BILDSCHIRM LOESCHEN
CARIG:	EQU	0DH		;CURSOR AN ZEILENANFANG (CR)
SPACE:	EQU	20H		;LEERZEICHEN
FIRST:	EQU	SPACE		;1. DRUCKBARES ZEICHEN
;
; System-PIO ist PIO1
DPIO1A:	equ	88H		;Daten Kanal A		Video
DPIO1B:	equ	89H		;Daten Kanal B		User-E/A
SPIO1A:	equ	8aH		;Steuerung Kanal A
SPIO1B:	equ	8bH		;Steuerung Kanal B

; Tastatur-PIO ist PIO2
DPIOA:	EQU	90H		;TASTATUR-PIO A DATEN
DPIOB:	EQU	91H		;TASTATUR-PIO B DATEN
SPIOA:	EQU	92H		;TASTATUR-PIO A KOMMANDO
SPIOB:	EQU	93H		;TASTATUR-PIO B KOMMANDO
CTC0:	EQU	80H
CTC2:	EQU	82H
CTC3:	EQU	83H
;
;	EJEC
;
;*******************************************************************
;*                                                                 *
;* 	OPERATING SYSTEM  -  S P R U N G TA B E L L E              *
;*                                                                 *
;*******************************************************************
;
RESET:	JP	INIT		;KALTSTART
	JP	WBOOT		;WARMSTART
CSTS:	JP	CONST		;STATUS CONST
CONSI:	JP	CONIN		;EINGABE ZEICHEN VON CONST
CONSO:	JP	COOUT		;AUSGABE ZEICHEN ZU CONST
LISTO:	JP	LIST		;AUSGABE ZEICHEN ZU LIST
PUNO:	JP	PUNCH		;AUSGABE ZEICHEN ZU PUNCH
READI:	JP	READR		;EINGABE ZEICHEN VON READER
GETST:	JP	GSTIK		;ABFRAGE SPIELHEBEL
	JP	BOSER		;NICHT GENUTZT
SETTI:	JP	STIME		;STELLEN UHRZEIT
GETTI:	JP	GTIME		;ABFRAGE UHRZEIT
SETDM:	JP	SDMA		;SETZEN ADR. KASSETTENPUFFER
READS:	JP	READ		;BLOCKLESEN SEQUENTIELL
WRITS:	JP	WRITE		;BLOCKSCHREIBEN SEQUENTIELL
	JP	LLIST		;STATUS LIST
	JP	GCURS		;ABFRAGE PHYS. CURSORADRESSE
	JP	SCURS		;SETZEN PHYS. CURSORADRESSE
	JP	BOSER		;NICHT GENUTZT
GETIO:	JP	GIOBY		;ABFRAGE I/O-BYTE
SETIO:	JP	SIOBY		;SETZEN I/O-BYTE
GETM:	JP	GMEM		;LOGISCHER SPEICHERTEST
SETM:	JP	SMEM		;SETZEN SPEICHERKONFIGURATION
;
;	EJEC
;
;*******************************************************************
;*                                                                 *
;* 	BASIC OPERATING SYSTEM  -  A D R E S S T A B E L L E       *
;*                                                                 *
;*******************************************************************
;
JPVEK:	DW	INIT		;KALTSTART/RESET		<00>
	DW	CONSI		;EINGABE VON CONST		<01>
	DW	CONSO		;AUSGABE ZU CONST		<02>
	DW	READI		;EINGABE VON READER		<03>
	DW	PUNO		;AUSGABE ZU PUNCH		<04>
	DW	LISTO		;AUSGABE ZU LIST		<05>
	DW	GETST		;ABFRAGE SPIELHEBEL		<06>
	DW	GETIO		;ABFRAGE I/O-BYTE		<07>
	DW	SETIO		;SETZEN I/O-BYTE		<08>
	DW	PRNST		;AUSGABE ZEICHENKETTE		<09>
	DW	RCONB		;EINGABE ZEICHENKETTE		<10>
	DW	CSTS		;STATUS CONST			<11>
	DW	RETVN		;ABFRAGEVERSIONSNUMMER		<12>
	DW	OPENR		;OPEN LESEN KASSETTE		<13>
	DW	CLOSR		;CLOSE LESEN KASSETTE		<14>
	DW	OPENW		;OPEN SCHREIBEN KASSETTE	<15>
	DW	CLOSW		;CLOSE SCHREIBEN KASSETTE	<16>
	DW	GETCU		;ABFRAGE LOG. CURSORADR.	<17>
	DW	SETCU		;SETZEN LOG. CURSORADR.		<18>
	DW	BOSER		;NICHT GENUTZT
	DW	READS		;BLOCKLESEN SEQUENTIELL		<20>
	DW	WRITS		;BLOCKSCHREIBEN SEQUENTIELL	<21>
	DW	SETTI		;STELLEN UHRZEIT		<22>
	DW	GETTI		;ABFRAGE UHRZEIT		<23>
	DW	PRITI		;AUSGABE UHRZEIT		<24>
	DW	INITA		;INITIALISIERUNG TASTATUR	<25>
	DW	SETDM		;SETZEN ADR. KASSETTENPUFF.	<26>
	DW	GETM		;LOG. SPEICHERTEST		<27>
	DW	SETM		;SETZEN SPEICHERKONFIG.		<28>
	DW	DCU		;LOESCHEN CURSOR		<29>
	DW	SCU		;ANZEIGE CURSOR			<30>
	DW	COEXT		;VORVERARBEITEN ZEICHENKET.	<31>
	DW	BOSER		;NICHT GENUTZT
	DW	RRAND		;BLOCKLESEN			<33>
;
;	EJEC
;
;*******************************************************************
;*                                                                 *
;* 	C O N S O L  -  C O M M A N D  -  P R O G R A M            *
;*                                                                 *
;*******************************************************************
;
GOCPM:	LD	HL,GOCPM
	PUSH	HL		;RUECKKEHRADR. KELLERN
	LD	HL,STDMA
	LD	(DMA),HL	;STANDARDKASSETTENPUFFER
	LD	A,'>'
	CALL	OUTA		;AUSGABE PROMPT
	CALL	GETMS		;EINGABE KOMMANDOZEILE
	JR	C, DISPE	;STOP-TASTE ODER FEHLER
	CALL	COEXT		;VORVERARB. EINGABEZEILE
	RET	C		;ZEICHENKETTE LEER
	LD	HL,ERDIS
	PUSH	HL		;ADR. FEHLERROUTINE KELLERN
	CALL	GVAL		;1.PARAMETER HOLEN
	JP	Z, ERPAR	;KEIN NAME
;*******************************************************************
;* 	BEHANDLUNG TRANSIENTKOMMANDOS                              *
;*******************************************************************
;
;NAMEN IM SPEICHER SUCHEN
INDV:	PUSH	BC		;TRENNZEICHEN MERKEN
	CALL	CPROM		;NAMEN IM SPEICHER SUCHEN
	POP	BC
	JR	Z, JMPHL	;NAMEN GEFUNDEN (HL)=STARTADR.
;*******************************************************************
;* 	PROGRAMM LADEN UND STARTEN                                 *
;*******************************************************************
INFIL:	CALL	LOAD1		;DATEI LADEN
	RET	C		;FEHLER BEIM LADEN
	LD	HL,(START)	;(HL)=GELESENE STARTADRESSE
JMPHL:	JP	(HL)		;SPRUNG ZUR AUSFUEHRUNG
;*******************************************************************
;* 	A S G N   -   KOMMANDO                                     *
;*******************************************************************
; Funktion: Zuweisung log. Gerät - phys. Gerät
; 	    Anzeige der aktuellen Zuweisung
; a) Eingang
; 	- ASGN
; 	gerufen von:  GOCPM über JMP (HL)
; 	Parameter  : CY 0 weitere Parameter im Konsolpuffer
; 		        1 keine weiteren Parameter
; b) gerufene Programme
; c) Ausgang
; 	- ALDEV
; 	- DISPA
;
ASGN:	EX	AF, AF'
	JR	NC, ALDEV	;WEITERE PARAMETER FOLGEN
;
;ANZEIGE DER AKTUELLEN ZUWEISUNGEN
;
; Funktion:  Anzeige der aktuellen Gerätezuweisung
; a) Eingang
; 	- DISPA
; 	gerufen von: ASGN, ALDEV
; 	Parameter  : SADV Stringadreßvektor zur Adressierung der zum log. Gerät
; 			definierten Ausgebestrings
; 		     LOGDV Tabelle der logischen Geräte
; 	- DISPE
; 	gerufen von: GOCPM Zeichen-E/A-Fehler in der Kommandoeingabe
; b) gerufene Programme
; 	- OCRLF Ausgabe CRLF
; 	- PRNST Ausgabe String
; 	- OUTA Ausgabe Zeichen
; c) Ausgang
; 	- WBOOT Fehler nach Gerätezuweisung bei Zeichenausgabe
; d) Return
; 	Parameter: -
;
DISPA:	CALL	OCRLF
DISPE:	JP	C, WBOOT	;FEHLER NACH ZUWEISUNG
	LD	B,4		;ANZAHL DER LOG. GERAETE
	LD	HL,TXCON	;ADRESSTABELLE ZEICHENKETTEN
	LD	DE,PHYDV+2	;NAMENSTABELLE DER GERAETE
DA2:	CALL	PRNST
	LD	A,':'
	CALL	OUTA
	PUSH	DE
	LD	E,(HL)		;
	INC	HL		;
	LD	D,(HL)		;(DE)=ADRESSE DER ZUGEHOERIGEN
	INC	HL		;ZEICHENKETTE
	PUSH	HL
	CALL	PRNST		;AUSGABE ZEICHENKETTE
	POP	HL
	POP	DE
	INC	DE
	INC	DE
	INC	DE		;NAECHSTER GERAETENAME
	CALL	OCRLF
	DJNZ	DA2
	RET
;
;
;ZUWEISUNG LOGISCHES GERAET - PHYSISCHES GERAET
;
; a) Eingang
;	- ALDEV
; 	gerufen von: ASGN
; 	Parameter : CONBU Konsolpuffer mit weiteren Eingabeparametern
; b) gerufene Programme
; 	- GVAL Parameter übernehmen
; 	- LOCK  log. Gerätenamen suchen
; 	- CDEL Zeichentest
; 	- LOPDV  Suchen phys. Gerätenamen
; 	- INDV Einlesen Treiberprogramm
; 	- EXIO  Prüfen der Zuweisung
; c) Ausgang
; 	- ERPAR Parameterfehler
; 	- ERINP Eingabefehler
; 	- DISPA
;
ALDEV:	CALL	GVAL		;NAECHSTEN PARAMETER HOLEN
	JR	Z, ALDE1	;KEIN NAME
	EX	AF, AF'
	JP	C, ERPAR	;NAECHSTER PARAMETER FEHLT
	PUSH	BC		;TRENNZEICHEN MERKEN
	LD	BC,409H		;(B)=ANZAHL LOG. GERAETE
				;(C)=LAENGE TABELLENNAME
	LD	HL,PHYDV+2
	CALL	LOCK		;NAME SUCHEN
	LD	E,B
	POP	BC
	JR	NZ, ALD00	;NAME NICHT GEFUNDEN
	LD	A,4
	SUB	E
	ADD	A, A
	LD	(WORKA),A	;ZWISCHENERGEBNIS MERKEN
	LD	(PARBU),HL	;ADR. ZEICHENKETTE MERKEN
	LD	A,C
	CP	A, ':'
	JR	NZ, ALDE0
	CALL	CDEL
	CP	A, '='
ALDE0:	JP	NZ, ERINP	;FALSCHE TRENNZEICHEN
	CALL	GVAL		;LETZTEN PARAMETER HOLEN
ALDE1:	JR	Z, ALDER	;KEIN NAME
	PUSH	BC		;TRENNZEICHEN MERKEN
	CALL	LOLDV		;PHYS. GERAETENAMEN SUCHEN
	POP	BC
	JR	Z, ALD0		;NAMEN GEFUNDEN
	CALL	INDV		;TREIBER VON KASSETTE HOLEN
	RET	C		;FEHLER BEIM LADEN

ALD:
	IF	osver == 11
	ex      af, af'
	ELSE
	NOP
	ENDIF

	PUSH	HL
	PUSH	DE
	LD	A,H		;(H)=LOG. GERAETENUMMER (0,2,4,6,)
	ADD	A, H
	ADD	A, L		;(L)=PHYS. GERAETENUMMER
	ADD	A, A
	LD	D,0
	LD	E,A
	LD	HL,ATTY		;TABELLE DER TREIBERADRESSEN
	ADD	HL,DE
	LD	(HL),C		;
	INC	HL		;ADRESSE IN TABELLE BRINGEN
	LD	(HL),B		;
	POP	DE
	POP	HL
ALD0:	LD	A,(IOBYT)	;I/O-BYTE MERKEN
	EX	AF, AF'
	JR	NC, ALDER	;ZU VIELE PARAMETER
	LD	A,(WORKA)	;ZWISCHENERGEBNIS ZURUECK
	LD	B,A
	LD	C,L
	CP	A, H		;
	JR	Z, ALD1		;
	SUB	L		;
	INC	A		;
	CP	A, 6		;TEST AUF ZULAESSIGE GERAETE
	JR	Z, ALD1		;
	DEC	A		;
	CP	A, B		;
ALD00:	JR	NZ, ALDER	;FALSCHES GERAET
ALD1:	PUSH	DE
	LD	E,B		;(E)=INTERNE NUMMER LOG. GERAET
				;(C)=NUMMER PHYS.GERAET
	LD	HL,IOBYT
	LD	B,9
	INC	A
ALD6:	RR	(HL)		;
	DEC	A		;
	JR	NZ, ALD66	;
	SRL	C		;I/O-BYTE MODIFIZIEREN
	RR	(HL)		;
	SRL	C		;
	DEC	B		;
ALD66:	DJNZ	ALD6
	LD	B,E
	CALL	EXIO		;ZUWEISUNG PRUEFEN
	POP	DE
	JR	NC, ALD7	;ZUWEISUNGSFEHLER
	EX	AF, AF'
	LD	(IOBYT),A	;I/O-BYTE RESTAURIEREN
	LD	A,4
	SCF
	RET
ALDER:	JP	ERPAR
ALD7:	LD	HL,(PARBU)	;ZEICHENKETTENADR. ZURUECK
	LD	(HL),E		;
	INC	HL		;ADRESSE EINTRAGEN IN TABELLE
	LD	(HL),D		;
	JP	DISPA		;ZUWEISUNG ANZEIGEN
;
;*******************************************************************
;* 	T I M E  -  KOMMANDO                                       *
;*******************************************************************
;
TIME_:	EX	AF, AF'
	JR	C, ZAU		;KEIN WEITERER PARAMETER
	LD	B,3		;ANZAHL PARAMETER
	LD	A,23		;BEREICHSGRENZE STUNDEN
T0:	LD	(PU),A
	PUSH	BC
	CALL	GVAL		;NAECHSTEN PARAMETER HOLEN
	POP	BC
	JR	NZ, ALDER	;KEINE ZAHL
	RET	C		;NICHT KONVERTIERBAR
	LD	E,A
	LD	A,(PU)
	CP	A, E		;VERGLEICH MIT BEREICH
	LD	A,3
	RET	C		;WERT ZU GROSS
T1:	LD	C,L
	LD	L,H
	LD	H,E
	EX	AF, AF'
	JR	C, T3		;KEIN WEITERER PARAMETER
	LD	A,59		;GRENZE FUER MINUTEN; SEKUNDEN
	DJNZ	T0
	JP	ERINP		;ZU VIELE PARAMETER
T2:	LD	(MIN),HL
	LD	A,C
	LD	(STUND),A
	OR	A
	RET
;FEHLENDE PARAMETER MIT 00 BELEGEN
T3:	LD	E,0
	EX	AF, AF'
	DJNZ	T1
	JR	T2		;EINTRAGEN
;
;AUSGABE DER AKTUELLEN UHRZEIT
;
ZAU:	LD	DE,INTLN+1	;ZWISCHENPUFFER
	CALL	PRITI		;ZEICHENKETTE ERZEUGEN
	CALL	PRNST		;ZEICHENKETTE AUSGEBEN
	JP	OCRLF
;
;ZEICHENTEST IN EINGABEZEILE
;
; Funktion: Übernahme des nächsten Zeichens aus dem Konsolpuffer
; 	    Löschen des Zeichens mit Leerzeichen
; 	    Test des Zeichens auf Trennzeichen (20H,’,’.’:’,0)
; a) Eingang
; 	- CDEL
; 	gerufen von: GVAL, ALDER
; 	Parameter  : CONBU Konsolpuffer
; 	- CDEL2
; 	gerufen von: GVAL Test eines Zeichens auf Trennzeichen 0
; 	Parameter  : A zu testendes Zeichen
; 		     Z 1
; b)  gerufene Programme
; 	- CDELI Zeichentest
; c) Ausgang
; 	-
; d)  Return
; 	Parameter: A, C getestetes Zeichen
; 	Z 0   kein Trennzeichen, 1  Trennzeichen
; 	CY 1   Trennzeichen, 0 (Kennzeichen für Stringende)
; 	CONBU getestetes Zeichen gelöscht mit Leerzeichen
;
CDEL:	LD	HL,CONBU+1
CDEL1:	INC	HL
	LD	A,(HL)
	CP	A, ' '
	JR	Z, CDEL1	;1. ZEICHEN<>20H SUCHEN
	CALL	CDELI		;TRENNZEICHENTEST
CDEL2:	LD	C,A
	RET	NZ		;ZEICHEN
	CP	A, 1
	RET	C		;ENDE ZEICHENKETTE
	CP	A, A
	RET			;TRENNZEICHEN
;
;TEST AUF TRENNZEICHEN UND LOESCHEN GESTESTETES ZEICHEN
CDELI:	LD	A,(HL)
	OR	A
	RET	Z		;ENDE ZEICHENKETTE
	PUSH	HL
	PUSH	BC
	LD	HL,DTAB		;TABELLE DER TRENNZEICHEN
	LD	BC,5
	CPIR
	POP	BC
	POP	HL
	LD	(HL),' '	;LOESCHEN ZEICHEN IN PUFFER
	INC	HL
	RET
;
;PARAMETER AUS EINGABEZEILE HOLEN
;
; Funktion: Löschen internen Puffer (INTLN).
; 	    Übernahme Parameter aus CONBU nach INTLN
; 	    Test auf Parameterart
; 	    Konvertieren Parameter, wenn dieser ein Wert ist
; a) Eingang
; 	- GVAL
; 	gerufen von: WBOOT, GOCPM, ALDEV, STIME, LOAD
; 	Parameter  : CONBU Konsolpuffer
; b) gerufene Programme
; 	- CDEL Übernahme Zeichen aus CONBU und Test
; 	- CDEL1 Test Zeichen
; 	- CDEL2 Test Zeichen
; 	- CONV konvertieren Parameter
; c) Ausgang
; 	- ERINP  Eingabefehler im Parameter
; d) Return
; 	Parameter: Z  1 Parameter war Dezimalzahl
; 		      0 Parameter war keine Zahl
; 		   CY  0 kein Fehler
; 		       1 Fehler im Parameter
; 		   A  Konvertierte Dezimalzahl, wenn Z = 1 und CY = 0
; 		   C  den Parameter begrenzendes Trennzeichen
; 		   B  Länge des Parameters
; 		   HL  Adresse des nächsten Zeichens in CONBU
; 		   CY’ 0 weitere Parameter in CONBU (ist in Doku falsch!)
; 		       1 keine weiteren Parameter (ist in Doku falsch!)
; 		   A’ den Parameter begrenzendes Trennzeichen
; 		   INTLN  Länge des Parameters
; 		   INTLN+1. . . übernommener Parameter
; 		   CONBU übernommener Parameter und Trennzeichen gelöscht mit
; 			 Leerzeichen
;
GVAL:	LD	DE,INTLN+82
	XOR	A
	LD	B,81
MOP0:	LD	(DE),A		;
	DEC	DE		;LOESCHEN ZWISCHENPUFFER
	DJNZ	MOP0		;
	PUSH	HL
	CALL	CDEL		;TEST AUF TRENNZEICHEN
	JR	C, MOP3		;ENDE DER ZEICHENKETTE
	JR	Z, MOP3		;TRENNZEICHEN GEFUNDEN
MOP1:	LD	(DE),A
	INC	B		;ALLE ZEICHEN BIS
	INC	DE		;ZUM NAECHSTEN TRENNZEICHEN
	CALL	CDELI		;UEBERNEHMEN
	JR	NZ, MOP1	;
	CALL	CDEL2
MOP3:	LD	A,B
	LD	(INTLN),A	;PARAMETERLAENGE MERKEN
	LD	A,C
	POP	HL		;TRENNZEICHEN MERKEN
	EX	AF, AF'
	LD	A,(INTLN+1)
	CP	A, '0'
	JR	C, GV3
	CP	A, '9'+1
	JR	NC, GV3
	PUSH	HL
	PUSH	BC
	LD	DE,INTLN
	CALL	VIEXT		;KONVERTIEREN PARAMETER
	POP	BC
	POP	HL
	JR	C, GV2		;NICHT KONVERTIERBAR
	CP	A, A
	RET			;IN ORDNUNG
GV2:	CP	A, A
	JP	ERINP		;NICHT KONVERTIERBAR
GV3:	CP	A, 40H
	JR	C, GV2
	SCF
	RET			;PARAMETER KEINE DEZIMALZAHL
;
;AENDERN LOGISCHE SPEICHERKONFIGURATION
;
MOD:	PUSH	HL		;(HL)=SPEICHERADRESSE
	PUSH	BC		;(C)=STATUS (1 RAM, 0 ROM)
	CALL	CHR0
	PUSH	AF
	SRL	C
	JR	CR1
;
;LOGISCHER SPEICHERTEST
;
CHRAM:	PUSH	HL		;(HL)=SPEICHERADRESSE
	PUSH	BC
	CALL	CHR0
	PUSH	AF
CR1:	CALL	CHR5
	POP	AF
	POP	BC
	POP	HL
	PUSH	AF
	OR	A
	SBC	HL,DE		;HL=HL-400H
	POP	AF		;(A)=STATUS (1 RAM, 0 ROM)
	RET
;
CHR0:	LD	DE,400H
	XOR	A
CHR1:	SBC	HL,DE
	INC	A
	JR	NC, CHR1
	LD	HL,MAPAR	;ADR. 64 BIT REGISTER FUER
				;SPEICHERSTATUS
CHR2:	SUB	8
	INC	HL
	JR	NC, CHR2
CHR3:	ADD	A, 8
	DEC	HL
	JR	Z, CHR3
CR33:	LD	B,9
CHR4:	RL	(HL)
	DEC	A
	RET	Z
CHR5:	DJNZ	CHR4
	RET
;
;ZEICHENKETTENVERGLEICH
;
; Funktion: Stringvergleich
; a) Eingang
; 	- CHEC
; 	gerufen von: LOCK, OPENR
; 	Parameter  : HL Adresse String 1
; 		     DE Adresse String 2
; 		     B Anzahl zu vergleichender Zeichen
; b)  gerufene Programme
; 	-
; c)  Ausgang
; 	-
; d)  Return
; 	Parameter: Z 1 String 1 = String 2
; 	DE unverändert
; 	HL Wort vor String 2
;
CHEC:	PUSH	HL		;ADR. 1. ZEICHENKETTE
	PUSH	DE		;ADR. 2. ZEICHENKETTE
	EX	DE,HL
CHC0:	LD	A,(DE)
	CP	A, 20H
	JR	Z, CH0
	CP	A, 40H
	JR	C, CHC01
CH0:	AND	A, 0DFH		;NUR GROSSBUCHSTABEN
CHC01:	CP	A, (HL)
	INC	DE
	INC	HL
	JR	NZ, CHC1
	DJNZ	CHC0		;(B)=ANZAHL ZEICHEN
	POP	DE
	POP	DE		;ADR. 1. ZEICHENKETTE
	LD	L,E
	LD	H,D
	DEC	HL
	LD	A,(HL)
	DEC	HL
	LD	L,(HL)
	LD	H,A		;(HL)=WORT VOR 1. ZEICHENKETTE
	RET
CHC1:	POP	DE
	POP	HL
	RET
;
;SUCHEN TRANSIENTKOMMANDO IM SPEICHER
;
; Funktion: Suchen Kommando im Speicher
; Kommando muß auf  integraler 100H-Grenze beginnen
; Aufbau:JP KOMM
; 	DB 'KNAME   ' ;8 Zeichen mit Space aufgefüllt
; 	DA 00 ;Ende Kommandofeld
; oder 	JP KOMM1
; 	DB 'K1NAME  '
; 	DB 0 ;Ende Kommando 1
; 	JP KOMM2
; 	DB 'K2NAME  '
; 	DB 0 ;Ende Kommando 2
; 	...
; 	JP KOMMN
; 	DB 'KNNAME  '
; 	DA 0 ;Ende Kommandofeld
; a) Eingang
; 	- CPROM
; 	gerufen von: WBOOT, GOCPM
; 	Parameter  : INTLN INTLN+1 enthält Kommando in der Länge 8 Bytes
; b) gerufene Programme
; 	- LOCK Suchen String
; c) Ausgang
; d) Return
; 	Parameter: Z 0 Kommando nicht gefunden
; 		     1 Kommando gefunden
; 		HL Adresse der Kommandoroutine
; 		DE Adresse des Kommandos im Speicher
;
CPROM:	LD	HL,0FC00H	;ANFANGSADRESSE
CP1:	PUSH	HL
CP2:	LD	A,0C3H
	CPI			;SPRUNGBEFEHL SUCHEN
	JR	NZ, CP22	;AUF NAECHSTER ADRESSSE SUCHEN
	INC	HL
	INC	HL
	PUSH	BC
	LD	BC,10BH
	CALL	LOCK		;VERGLEICH ZEICHENKETTE
	POP	BC
	JR	Z, CPE1		;GEFUNDEN
	XOR	A
	DEC	HL
	DEC	HL
	CP	A, (HL)		;00h statt C3h (Listendende)?
	JR	NZ, CP2		;WEITER MIT KOMMANDOTABELLE
CP22:	POP	HL
CP3:	DEC	H		;NAECHSTE 100H-GRENZE
	if rombank
	JP	ROMBK		;Sprung zur ROM-Bank
	else
	JR	NZ, CP1
	INC	H
	endif
	RET			;NICHT GEFUNDEN
CPE1:	POP	BC		;TRANS.-KOMMANDO GEFUNDEN
	RET
;VERGLEICH EINGABE MIT TREIBERNAMEN  BAT  UND  CRT
LOLDV:	LD	BC,0206H
	LD	HL,LOGDV+2	;NAMENSTABELLE
;VERGLEICH
LOCK:	LD	DE,INTLN+1
LOCK1:	PUSH	BC
	LD	B,C
	DEC	B
	DEC	B
	CALL	CHEC
	POP	BC
	RET	Z		;GEFUNDEN
	LD	A,C
LOCK2:	INC	HL
	DEC	A
	JR	NZ, LOCK2
	DJNZ	LOCK1
	OR	1
	RET
;
;PRUEFEN TREIBERADRESSE ENTSPRECHEND I/O-BYTE
;
; Funktion: Lesen einer ausgewählten Treiberadresse
; 	    Prüfen der gültigen Zuweisung
; a) Eingang
; 	- EXIO
; 	gerufen von: ALDEV, CONST
; 	Parameter  : B interne Nummer des log. Gerätes (0, 2, 4, 6)
; 			0 : CONST
; 			6 : LIST
; 		     IOBYT
; 		     Treiberadreßvektor
; b) gerufene Programme
; 	- COMPW Vergleichen DE und HL
; c) Ausgang
; 	-
; d) Return
; 	Parameter: CY 1 keine Treiberadresse gefunden (FFFFH)
; 		      0 Adresse gefunden
; 	           HL Treiberadresse
;
EXIO:	PUSH	AF
	LD	D,0
	LD	E,B		;INTERNE LOG. GERAETENUMMER
	LD	A,B		;(0, 2, 4, 6)
	OR	A
	LD	A,(IOBYT)
	JR	Z, SH1
SH:	SRL	A
	DJNZ	SH
SH1:	SLA	E
	AND	A, 3
	ADD	A, E
	LD	E,A
	LD	HL,ATTY		;TABELLE DER TREIBERADRESSEN
	POP	AF
	ADD	HL,DE		;ADRESSE DER BENOETIGTEN
	ADD	HL,DE		;TREIBERADR. BERECHNEN
	PUSH	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	HL,-1
	EX	DE,HL
	CALL	COMPW		;TREIBERADR. = FFFFH
				;JA --> GERAET NICHT ZUGEWIESEN
	POP	DE
	CCF
	RET			;(HL)=ADR. DER TREIBERROUTINE
;
MOVE:	PUSH	HL
	PUSH	DE
	PUSH	BC
	LDIR
	JR	OUTS2
;
OCRLF:	LD	A,0DH
	CALL	OUTA
	LD	A,0AH
;
OUTA:	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	C,A
	CALL	COOUT
OUTS2:	POP	BC
	POP	DE
	POP	HL
	RET
;
OSPAC:	LD	A,20H
	JR	OUTA
;
;	EJEC
;
;*******************************************************************
;*                                                                 *
;* 	B A S I C  -  O P E R A T I N G  -  S Y S T E M            *
;*                                                                 *
;*******************************************************************
;
BOS:	LD	(SPSV),SP	;SICHERN ANWENDERSTACK
	LD	SP,1C0H		;BOS - STACK
	SCF
	CCF
	PUSH	HL
	PUSH	DE
	PUSH	AF
	LD	(BCSV),BC
	LD	(ASV),A
	LD	HL,BOSE
	PUSH	HL		;RUECKKEHRADRESSE KELLERN
	LD	A,33
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
;
;AUSGANG AUS BOS
BOSE:	JR	NC, BOSE1	;KEIN FEHLER
	CALL	ERDIS		;AUSGABE FEHLERMELDUNG
	POP	AF
	SCF			;SETZEN FEHLERSTATUS
	PUSH	AF
BOSE1:	POP	AF
	POP	DE
	POP	HL
	LD	A,(ASV)
	LD	BC,(BCSV)
	LD	SP,(SPSV)
	RET
;
;EINGABE ZEICHENKETTE IN MONITORPUFFER
;
; Funktion:    Eingabe String in Monitorpuffer (80H)
; a) Eingang
; 	- GETMS
; 	gerufen von: GOCPM, REQU
; 	Parameter  : -
; b) gerufene Programme
; 	- CONIN Eingabe Zeichen
; 	- OUTA Ausgabe Zeichen in A
; c) Ausgang
; 	- RCONB
; 	Parameter: DE Adresse Consolepuffer (80H)
;
GETMS:	LD	DE,CONBU
	LD	A,80		;LAENGE INITIALISIEREN
	LD	(DE),A
	LD	A,(ASV)
;
;EINGABE ZEICHENKETTE
;
RCONB:	LD	L,E
	LD	H,D
	INC	HL
	LD	C,L
	LD	B,H
	INC	BC
	LD	(HL),0		;LAENGE ZEICHENKETTE = 0
	LD	(BU),A
GETS1:	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	CONIN		;EINGABE EIN ZEICHEN
	POP	BC
	POP	DE
	POP	HL
	RET	C		;FEHLER BEI ZEICHENEINGABE
	PUSH	HL
	LD	HL,COLSW	;ZELLE FUER FARBSTEUERZEICHEN
	INC	(HL)
	DEC	(HL)		; HL <> 0 ?
	POP	HL
	JR	NZ, GETS0	;dann UEBERNEHMEN FARBCODE
	CP	A, 03		;STOP - TASTE
	JR	NZ, GETS2
	XOR	A
	SCF
	RET
GETS2:	CP	A, 1FH		;DEL - TASTE
	JR	Z, GETS5	;LOESCHEN LETZTES ZEICHEN
	CP	A, 2		;CLLN - TASTE
	JR	NZ, GETS4
GETS3:	CALL	GETBS
	JR	NZ, GETS3	;LOESCHEN GESAMTE ZEILE
	JR	GETS1
GETS4:	CP	A, 0DH		;ENTER - TASTE
	JR	Z, GETSE	;ENDE
	CP	A, 0BH		;CURSOR HOCH
	JR	Z, GETS1	;IGNORIEREN
	CP	A, 0AH		;CURSOR RUNTER
	JR	Z, GETS1	;IGNORIEREN
	CP	A, 8		;CURSOR LINKS
	JR	NZ, GETS0
GETS5:	CALL	GETBS		;LETZTES ZEICHEN LOESCHEN
	JR	GETS1
GETS0:	CP	A, 10H		;CTRL/P
	JR	Z, GETS8	;NUR AUSFUEHREN
	INC	(HL)		;ZEICHEN IN
	LD	(BC),A		;ZEICHENKETTE
	INC	BC		;UEBERNEHMEN
GETS8:	CALL	OUTA		;AUSGABE DES ZEICHENS
	RET	C		;FEHLER BEI AUSGABE
	LD	A,(DE)
	CP	A, (HL)		;PUFFER VOLL?
	JR	NZ, GETS1
GETSE:	LD	A,(BU)
	LD	(ASV),A
	JP	OCRLF
;
;BEHANDLUNG EIN ZEICHEN LOESCHEN
GETBS:	INC	(HL)
GBS1:	DEC	(HL)
	RET	Z		;ALLES GELOESCHT
	DEC	BC
	LD	A,(BC)
	CP	A, 9		;CURSOR RECHTS

	JR	Z, GBS2
	CP	A, 20H
	JR	C, GBS1		;STEUERZEICHEN GEFUNDEN
	LD	A,8
	CALL	OUTA
	CALL	OSPAC
GBS2:	LD	A,8
	CALL	OUTA
	DEC	(HL)
	RET
;
;AUSGABE ZEICHENKETTE
PRNST:	LD	A,(DE)
	OR	A		;ZEICHENKETTENENDE ?
	JR	NZ, PRN1
	LD	A,(COLSW)
	OR	A		;WAR 0-BYTE EIN FARBCODE ?
	RET	Z		;KEIN FARBCODE
	XOR	A
PRN1:	CALL	OUTA
	RET	C		;FEHLER BEI AUSGABE
	INC	DE
	JR	PRNST		;NAECHSTES ZEICHEN
;
;ABFRAGE VERSIONSNUMMER
;
RETVN:	IF osver == 11
	LD	HL,101H
	ELSEIF osver == 12
	LD	HL,102H
	ELSEIF osver == 13
	LD	HL,103H
	ENDIF
	JR	CLR1
;
;OPEN FUER KASSETTE LESEN
;
OPENR:	CALL	REQU		;AUSGABE STARTMELDUNG
	INC	A
	RET	C		;STOP GEGEBEN
	PUSH	HL
	XOR	A		;BLOCKNUMMER 0 LESEN
	LD	(LBLNR),A
	CALL	READ		;BLOCKLESEN
	POP	HL
	LD	(DMA),HL	;PUFFERADR. ZURUECKSETZEN
	RET	C		;LESEFEHLER
	PUSH	HL
	LD	DE,17		;OFFS. AADR (= AADR-FCB)
	ADD	HL,DE
	LD	DE,AADR

	IF	osver == 11
	LD	BC,6
	ELSE
	LD	BC,8
	ENDIF

	LDIR			;DATEIPARAMETER UEBERNEHMEN
	POP	DE
	LD	HL,FCB
	LD	B,11
	CALL	CHEC		;NAMENSVERGLEICH
	LD	A,13
	SCF
	RET	NZ		;FALSCHE DATEI GELESEN

	IF	osver == 11
	LD	a,(fcb+11)
	ELSE
	LD	A,(FCB+23)	;SCHUTZBYTE
	ENDIF

	OR	A
	RET	Z		;KEIN SCHUTZ
	LD	(MAPPI),A	;SYSTEMSCHUTZ EIN
	RET
;
;CLOSE FUER KASSETTE LESEN
;
CLOSR:	LD	HL,AADR		;ADRESSE DER DATEIPARAMETER
CLR1:	LD	(BCSV),HL	;UEBERGEBEN
	RET
;
;BLOCKLESEN SEQUENTIELL
;
READ:	CALL	RRAND		;BLOCK LESEN
	RET	C		;LESEFEHLER
	LD	(DMA),HL	;PUFFERADR. UM 128 ERHOEHEN
	LD	HL,LBLNR
	INC	(HL)		;ZU LESENDE BLOCKNUMMER ERHOEHEN
	PUSH	AF
	CALL	OSPAC		;AUSGABE LEERZEICHEN
	POP	AF
	RET
;
;OPEN FUER KASSETTE SCHREIBEN
;
OPENW:	CALL	REQU		;AUSGABE STARTMELDUNG
	INC	A
	RET	C		;STOP GEGEBEN
	PUSH	HL
	LD	HL,FCB
	LD	(DMA),HL	;SCHREIBEN DES FCB
	LD	A,0

	IF	osver == 11
	LD	(fcb+11),a
	ELSE
	LD	(FCB+23),A	;KEIN SCHUTZ
	ENDIF

	LD	BC,1770H	;LANGER VORTON
	XOR	A
	LD	(BLNR),A	;BLOCKNUMMER 0
	LD	A,2
	LD	(LBLNR),A
	CALL	WRIT1		;SCHREIBEN BLOCK
	POP	HL
	LD	(DMA),HL	;PUFFERADR. AUF AUSGANGSWERT
	RET
;
;CLOSE FUER KASSETTE SCHREIBEN
;
CLOSW:	LD	A,0FFH
	LD	(BLNR),A	;BLOCKNUMMER FFH
;
;BLOCKSCHREIBEN SEQUENTIELL
;
WRITE:	LD	BC,0A0H		;KURZER VORTON
WRIT1:	LD	DE,(DMA)	;PUFFERADRESSE
	LD	A,(MAPPI)
	OR	A
	JR	Z, WRIT2	;KEIN SCHUTZ VOR SCHREIBEN
WERR:	LD	A,9		;SCHREIBSCHUTZ
WERR1:	SCF			;FEHLERAUSGANG
	RET
WRIT2:	LD	HL,(EOR)	;LOGISCHES RAM - ENDE
	PUSH	DE
	LD	DE,7FH
	SBC	HL,DE
	POP	DE
	CALL	COMPW		;ADRESSVERGLEICH
	LD	A,10
	JR	C, WERR1	;BLOCK LIEGT HINTER RAM - ENDE
	EX	DE,HL
	CALL	CHRAM		;LOGISCHER SPEICHERTEST
	JR	NC, WERR	;BEREICH IST GESCHUETZT/ROM
	CALL	KARAM		;AUSGABE BLOCK
	LD	(DMA),HL	;PUFFERADR. UM 128 ERHOEHEN
	LD	HL,BLNR
	LD	A,(HL)
	LD	(ASV),A		;BLOCKNUMMER ZURUECKGEBEN
	INC	(HL)		;BLOCKNUMMER ERHOEHEN
	JP	INITA		;TASTATUR INITIALISIERN
;
;AUSGABE DER AKTUELLEN UHRZEIT
;
PRITI:	PUSH	DE
	LD	BC,STUND	;ADRESSE DER UHRZEIT
	LD	D,3
	LD	HL,INTLN+1	;ZWISCHENPUFFER
	PUSH	HL
	DEC	HL
PRTI1:	LD	(HL),':'
	INC	HL
	LD	A,(BC)
	PUSH	BC
	OR	A
	JR	Z, PRTI3
	LD	B,A		;
	XOR	A		;INTERNE ZAHL
PRTI2:	ADD	A, 1		;IN BCD - ZAHL UMWANDELN
	DAA			;
	DJNZ	PRTI2		;
PRTI3:	LD	(HL),A
	LD	A,33H		;
	RRD			;IN DRUCKBARE ZEICHEN
	INC	HL		;UMWANDELN
	LD	(HL),A  	;
	INC	HL
	LD	(HL),0		;ENDE ZEICHENKETTE
	POP	BC
	INC	BC
	DEC	D
	JR	NZ, PRTI1
	POP	HL
	POP	DE
	LD	C,8
	JP	MOVE		;KETTE ZUR ANGEGEBENEN ADR.
;
;BLOCKLESEN
;
RRAND:	LD	HL,(EOR)	;LOGISCHES RAM - ENDE
	LD	DE,7FH
	SBC	HL,DE
	LD	DE,(DMA)	;PUFFERADRESSE
	CALL	COMPW		;ADRESSVERGLEICH
	LD	A,10
	RET	C		;BLOCK UEBERSCHREIBT RAM - ENDE
	EX	DE,HL
	CALL	CHRAM		;LOGISCHER SPEICHERTEST
	LD	A,9
	JR	NC, ERAND	;BEREICH GESCHUETZT/ROM
RR1:	PUSH	AF
RR2:	POP	AF
	CALL	MAREK		;EINGABE BLOCK
	CALL	INITA		;TASTATUR INITIALISIEREN
	PUSH	AF
	PUSH	HL
	LD	HL,LBLNR	;ZU LESENDE BLOCKNUMMER
	LD	A,(BLNR)	;GELESENE BLOCKNUMMER
	CP	A, (HL)
	POP	HL
	JR	C, RR2		;BLOCKNUMMER NOCH NICHT ERREICHT
	JR	Z, RROK		;GEFUNDEN
	CP	A, 0FFH
	JR	Z, RROK		;ENDEBLOCK GELESEN
	POP	AF
	LD	A,11		;BLOCKNUMMER ZU GROSS
ERAND:	SCF
	RET
RROK:	POP	AF
	LD	A,12
	RET	C		;LESEFEHLER
	LD	A,(BLNR)	;RUECKGABE EOF - KENNZEICHEN
	INC	A
	LD	A,0
	JR	NZ, RROK1
	INC	A
RROK1:	LD	(ASV),A		;1 WENN ENDEBLOCK, SONST 0
	RET
;
;
;
;
;*******************************************************************
;* 	C L O A D   -   KOMMANDO                                   *
;*******************************************************************
;
;
; Funktion:    Laden eines Programms
; a) Eingang
; 	- LOAD
; 	gerufen von: INFIL, CLOAD
; 	Parameter  : CONBU mit gesuchtem Namen
; b)  gerufene Programme
; 	- GVAL Parameterübernahme
; 	- MOV verschieben Speicherbereich
; 	- OPENR Eröffnen für Lesen
; 	- READ Lesen eines Blockes
; 	- REA Abfrage Bedienerhandlung bei Fehler
; c) Ausgang
; 	- ERPAR Parameterfehler
; 	- ERINP Eingabefehler
; 	- OCRLF Ausgabe CR/LF nach Einlesen
; 	Parameter: CY 0 keine Fehler
; 		      1 Fehler, Code in A
; 		   Programm ab Anfangsadresse im Speicher
; 		   DMA nach Programm
;
LOAD:	CALL	GVAL		;NAECHSTEN PARAMETER HOLEN
	RET	Z		;KEIN GUELTIGER NAME
;
;DATEI LADEN OHNE START
LOAD1:	LD	HL,ERPAR
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
	LD	HL,4F43H	;STANDARDEINTRAGUNG
	LD	(FCB+8),HL	;
	LD	A,'M'		;COM VORNEHMEN
	LD	(FCB+10),A	;
	JR	LOA33
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
	CALL	MOV
LOA33:	POP	HL
	EX	AF, AF'
	JP	NC, ERINP	;ZU VIELE PARAMETER
LOAD4:	CALL	OPENR
	JR	NC, LOAD5	;KEIN FEHLER
	OR	A
	SCF
	RET	Z		;STOP GEGEBEN
	CALL	REA		;AUSG. FEHLERMELD. WARTEN REAKT.
	RET	C		;STOP GEGEBEN
	JR	LOAD4		;WIEDERHOLUNG
LOAD5:	LD	HL,(AADR)	;DATEIANFANGSADRESSE
	LD	(DMA),HL	;NACH ADR. KASSETTENPUFFER
LOA55:	CALL	READ		;LESEN BLOCK
	JR	NC, LOAD6	;KEIN FEHLER
	CALL	REA		;AUSG. FEHLERMELD. WARTEN REAKT.
	RET	C		;STOP GEGEBEN
	XOR	A
LOAD6:	OR	A
	JR	Z, LOA55	;WEITER BIS DATEIENDE LESEN
	JP	OCRLF
;
MOV:	LD	HL,INTLN+1	;ZWISCHENPUFFER
	LD	B,A
MOV2:	LD	A,(HL)
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	MOV2
	RET
;
;AUSGABE STARTMELDUNG, WARTEN AUF ENTER
;
; Funktion: Ausgabe String 'start tape' , warten auf ENTER
; a) Eingang
; 	- REQU
; 	gerufen von: OPENR, OPENW
; 	- REQU0
; 	gerufen von: REA
; b) gerufene Programme
; 	- PRNST Ausgabe String
; 	- GETMS Eingabe String
; c) Ausgang
; 	-
; d) Return
; 	Parameter: A FFH wenn STOP
; 	             0 sonst
;
REQU:	LD	DE,TXTRC	;TEXTADRESSE STARTMELDUNG
	CALL	PRNST		;AUSGABE TEXT
REQU0:	CALL	GETMS		;EINGABE ZEICHENKETTE
	LD	HL,(DMA)
	RET	NC		;KEIN STOP
	LD	A,0FFH
	RET
;
;AUSGABE FEHLERMELDUNG, WARTEN AUF BEDIENERREAKTION
;
; Funktion: Ausgabe Fehlermeldung,  warten auf Bedienerhandlung
; a) Eingang
; 	- REA
; 	gerufen von: LOAD
; 	Parameter: A Fehlercode
; b) gerufene Programme
; 	- REQUO  warten auf Bedienerhandlung
; 	- MOD  verändern Speicherkonfiguration (bei Fehler 9)
; c) Ausgang
; 	-
; d) Return
; 	Parameter: CY 0 kein STOP
; 	              1 STOP, Fehlercode in A
;
REA:	CALL	ERDIS		;AUSGABE FEHLERMELDUNG
REA1:	CALL	REQU0		;EINGABE ZEICHENKETTE
	RET	C		;STOP GEGEBEN
	LD	A,(ASV)
	CP	9		;FEHLER DURCH GESCHUETZT. BEREICH
	SCF
	CCF
	RET	NZ		;NEIN
	LD	C,1
	CALL	MOD		;SCHUTZ AUFHEBEN, DA NICHT STOP
	OR	A
	RET
;
;VORVERARBEITEN EINER ZEICHENKETTE
;
COEXT:	INC	DE
	LD	A,(DE)		;LAENGE ZEICHENKETTE
	OR	A
	JR	Z, COMP3	;ZEICHENKETTE LEER
	LD	L,E
	LD	H,D
	PUSH	HL
	INC	HL
	INC	DE
	LD	B,A
	LD	C,0
	EX	DE,HL
	LD	A,1FH
COMP1:	CP	A, (HL)
	JR	NC, COMP2	;STEUERZEICHEN UEBERGEHEN
	LDI			;ZEICHEN UEBERNEHMEN
	INC	BC
	INC	BC
	DEC	HL
COMP2:	INC	HL		;NAECHSTES ZEICHEN
	DJNZ	COMP1
	POP	HL
	LD	(HL),C		;NEUE LAENGE EINTRAGEN
	EX	DE,HL
	LD	A,C
	OR	A
	LD	(HL),0		;0-BYTE AN KETTE ANHAENGEN
	RET	NZ
COMP3:	SCF			;NEUE ZEICHENKETTE IST LEER
	RET
;
;
BOSER:	LD	A,7
	SCF
	RET
ERINP:	LD	A,TYPIE
	SCF
	RET
ERPAR:	LD	A,1
	SCF
	RET
;
;AUSGEBEN FEHLERMELDUNG
;
; Funktion: Ausgabe Fehlermeldung
; a) Eingang
; 	- ERDIS
; 	gerufen von: BOSE, REA, GOCPM
; 	Parameter  : A Fehlercode
; 		     CY 1 (bei 0 RET)
; b) gerufene Programme
; 	- PRNST Ausgabe String
; 	- OUTA Ausgabe Zeichen in A
; 	- OCRCF Ausgabe CR/LF34
; c) Ausgang
; 	-
; d) Return
; 	Parameter: CY 1
; 		   A Fehlercode
;
ERDIS:	RET	NC		;KEIN FEHLER
	CP	A,0FFH
	SCF
	RET	Z		;KEINE MELDUNG, NUR INTERN
	LD	(ASV),A		;FEHLERNUMMER ZURUECKGEBEN
	OR	A
	SCF
	RET	Z		;KEINE MELDUNG, NUR WARNUNG
	PUSH	AF

	IF	osver <> 11
	XOR	A
	LD	(LISW),A	;DRUCKER AUS
	ENDIF

	CALL	OCRLF
	POP	AF
	LD	DE,TXTE
	SUB	5
	JR	NC, ERD1
	PUSH	AF		;A = 1...4
	CALL	PRNST
	POP	AF
	ADD	A, 35H
	CALL	OUTA
	JR	ERD6
ERD1:	SUB	2
	RET	C		;A = 5 U. 6
	PUSH	AF		;A = 7...13
	LD	DE,TXTBE
	CALL	PRNST
	LD	A,':'
	CALL	OUTA
	CALL	OSPAC
	POP	AF
	JR	NZ, ERD2
	LD	B,8		;A = 7
	JR	ERD21
ERD2:	DEC	A
	JR	NZ, ERD3
ERD21:	LD	HL,PHYDV-7	;A = 8
	LD	DE,9
	SRL	B
	INC	B
ERD22:	ADD	HL,DE
	DJNZ	ERD22
	EX	DE,HL
	JR	ERD5
ERD3:	LD	DE,TXTMP
	DEC	A
	JR	Z, ERD5		;A = 9
	LD	DE,TXTEO
	DEC	A
	JR	Z, ERD5		;A = 10
	LD	DE,TXTNB
	DEC	A
	JR	Z, ERD5		;A = 11
	LD	DE,TXTPT
	DEC	A
	JR	Z, ERD5		;A = 12
	LD	DE,TXTNF
	DEC	A
	JR	Z, ERD5		;A = 13
	DEC	DE
ERD5:	CALL	PRNST		;AUSGABE MELDUNG
ERD6:	CALL	OCRLF
STERR:	XOR	A
ENDER:	SCF
	RET
;
;*******************************************************************
;*                                                                 *
;*	O P E R A T I N G  -  S Y S T E M                          *
;*                                                                 *
;*******************************************************************
;
;INITIALISIERUNG DES COMPUTERS
;
INIT:	DI
	LD	SP,200H		;CCP- UND ANWENDERSTACK

	IF eorpatch

	;s.http://www.sax.de/~zander/z9001/tip/tipc.html
	LD 	BC,100H 	;100 Bytes
	LD 	H,C
	LD 	L,C 		;HL=0000
	LD 	(HL),0FFH 	;Adresse 0000 mit FF beschreiben
	LD 	D,H
	LD 	E,L 		;DE=0000
	INC 	DE 		;DE=0001
	LDIR 			;001 bis 100 mit FF füllen

	else

	LD	C,0
	LD	HL,(EOR)	;LOGISCHES RAM - ENDE
	LD	E,L
	LD	D,H
	INC	DE
	LD	B,1
	LDIR			;LOESCHEN 100H BYTES AB
				;LOG. RAM - ENDE
	ENDIF

	LD	A,2
	LD	I,A
	INC	A
	OUT	SPIO1A, A
	LD	A,0CFH
	OUT	SPIO1A, A	;PIO 1  PORT A  IN BYTEAUSGABE
	XOR	A
	OUT	SPIO1A, A
	OUT	DPIO1A, A
;PHYSISCHER SPEICHERTEST, SETZEN SPEICHERKONFIGURATION
MEMTE:	LD	HL,0FC00H
	LD	B,64		;64  1k BYTES BEREICHE
MEMT0:	LD	A,(HL)
	CPL
	LD	(HL),A
	LD	D,(HL)
	CP	A, D
	CPL
	LD	(HL),A
	LD	C,1
	JR	Z, MEMT1	;RAM GEFUNDEN
	DEC	C
	DEC	HL
	LD	(EOR),HL	;VORLAEUFIGES LOG. RAM - ENDE
	INC	HL
MEMT1:	CALL	MOD		;MERKEN KONFIG. IM 64 BIT - REGISTER
	DJNZ	MEMT0

	if osver == 11
	ld      a, 0C3h
	ld      (5), a
	ENDIF

	LD	HL,BOS		;ADR. BOS FUER CALL 0005
	LD	(6),HL
	CALL	IOST		;INITIALISIEREN STANDARD-E/A
	LD	DE,MSG
	if rommenu
	CALL	MENUE		;Menüanzeige (nur Version 2)
	else
	CALL	PRNST
	endif
;
;WARMSTART, TEILINITIALISIERUNG
;
WBOOT:	DI
	LD	SP,200H
	LD	A,0C3H		;JMP - CODE
	LD	(0),A		;FUER CALL 0000 UND

	IF	osver <> 11
	LD	(5),A		;CALL 0005 SPEICHERN
	ENDIF

	LD	HL,WBOOT	;ADR. WBOOT FUER CALL 0000
	LD	(1),HL
	LD	A,(IOBYT)
	AND	A, 0FCH		;ZUWEISEN CONST:=CRT
	OR	1		;
	CALL	IOST1		;TEILINITIALISIERUNG TREIBER
	LD	DE,TXTWB
	CALL	PRNST
	LD	HL,0023H	;'#'
	LD	(CONBU+2),HL	;PSEUDOEINGABE #
	CALL	GVAL		;PARAMETER HOLEN
	CALL	CPROM		;TRANSIENTKOMMANDO SUCHEN
	JP	NZ, GOCPM	;NICHT GEFUNDEN
	JP	(HL)		;SPRUNG ZUR SYSTEMERWEITERUNG
;
;INITIALISIERUNG STANDARD-E/A
IOST:	LD	HL,ATTY		;TABELLE TREIBERADRESSEN
	LD	DE,ATTY+1
	LD	BC,31
	LD	(HL),-1
	LDIR			;ALLE AUF FFFFH LOESCHEN
	LD	DE,200H
	LD	HL,INTV
	LD	C,12
	LDIR			;INTERRUPTADRESSEN LADEN
	if sysver = "os"
	LD	HL,LOGDV	; original
	elseif 			; bei UZ
	LD	HL,LOGDV+1
	endif
	LD	(TXRDR),HL	;ZEICHENKETTENADRESSEN
	LD	(TXPUN),HL	;FUER TREIBER
	LD	(TXLPT),HL	;INITIALISIEREN
	LD	HL,BAT		;
	LD	(ABAT),HL	;
	XOR	A
	LD	(ATRIB),A	;FARBE LOESCHEN
	LD	(MAPPI),A	;SYSTEMSCHUTZ LOESCHEN
	LD	A,STIOB		;STANDARD-I/O-BYTE
;
;TEILINITIALISIERUNG
IOST1:	LD	(IOBYT),A
	LD	HL,LOGDV+2
	LD	(TXCON),HL	;ADRESSE VON 'CRT' EINTRAGEN
	LD	HL,CRT
	LD	(ACRT1),HL	;TREIBERADRESSE VON CRT LADEN
	LD	(ACRT2),HL	;(FUER CONST UND LIST)
	IM	2
	LD	DE,0FFFFH
IOST2:	DEC	DE
	LD	A,E
	OR	D
	JR	NZ, IOST2	;ENTPRELLEN RESETTASTE
	LD	(LISW),A	;DRUCKER AUS
	DEC	A
	JP	(HL)		;INITIALISIERUNG VON CRT
;
;ABFRAGE LOGISCHE CURSORADRESSE
;
GCURS:	LD	L,7
	JR	DCU
;
;SETZEN physische CURSORADRESSE
;
SCURS:	LD	L,5		; L := 8 (Fkt. Setzen phys.. Cursoradresse)
	LD	E,C		;PARAMETER UEBERNEHMEN
	LD	D,B		;
;
;SETZEN logische CURSORADRESSE
; in: L=3, Anfangswert fuer Cursorrufe (BOS)
;
SETCU:	INC	L		; L := 6 (Fkt. Setzen log. Cursoradresse)
;
;ABFRAGE PHYSISCHE CURSORADRESSE
;
GETCU:	INC	L		; L := 5 (Fkt. Abfrage phys. und log. Cursoradresse)
;
;ANZEIGEN CURSOR
;
SCU:	INC	L		; L := 4 (Fkt. Cursor anzeigen)
;
;LOESCHEN CURSOR
; in: L=3, Anfangswert fuer Cursorrufe (BOS) (Fkt. Cursor löschen)
;
DCU:	LD	A,L		;A=Fkt. des CONST-Treibers
	CALL	CONS1		;AUSFUEHREN DURCH CONST
	RET	C		;FEHLER
	CP	A, 3
	RET	Z		; bei bei Fkt. 3 (Cursor löschen)
	LD	C,L		;
	LD	B,H		;
	CP	A, 6		;
	RET	NC		; Fkt. >= 6
	LD	(BCSV),HL	;RUECKGABE PARAMETER
	CP	A, 4		;
	RET	Z		; bei Fkt. 4 (Cursor anzeigen)
	; bei Fkt. 5 (Abfrage phys. und log. Cursoradresse)
	LD	(1BCH),DE	; Pos. von DE im BOS-Stack (SP = 1C0H)
	RET
;
; CONST, CONIN, CONOUT, LIST, LLIST, READER,PUNCH (CONST1, LIST1, RDR1)
; Funktion:   Verzweigen zu log. Geräten
; a) Eingang
; 	gerufen  von: Systemruf, Cursorruf
; 	Parameter: bei OUT Zeichen in C
; b) gerufene Programme
; 	- EXIO Test Gerätezuweisung, Startadresse der Gerätetreiber holen
; c) Ausgang
; 	-
; d) Return
; 	Parameter: CY 0 kein Fehler
; 		      1 Fehler, Code in A
; 		   B interne log. Gerätenummer
; 		   A bei IN Zeichen
;
;
;ABFRAGE STATUS CONST
;
CONST:	LD	A,0
CONS1:	LD	B,0		;INTERNE LOG. GERAETENR. CONST
CONS2:	PUSH	BC
	PUSH	DE
	CALL	EXIO		;VERFUEGBARKEIT TREIBER PRUEFEN
	POP	DE
	JR	NC, CONS3	;IN ORDNUNG
	POP	BC
CON22:	LD	A,8		;NICHT ZUGEWIESEN
	RET
CONS3:	PUSH	HL
	LD	HL,CONS4
	EX	(SP),HL		;RUECKKEHRADR. KELLERN
	LD	(PU),A
	JP	(HL)		;SPRUNG ZUR TREIBERROUTINE
;
CONS4:	POP	BC
	LD	C,A
	JR	C, CON22	;FEHLER
	LD	A,(PU)
	CP	A, 2		;WAR RUF EINE EINGABE?
	RET	NC		;NEIN
	LD	A,C
	LD	(ASV),A		;STATUS ODER ZEICHEN ZURUECK
	OR	A
	RET
;
;EINGABE VON CONST
;
CONIN:	LD	A,1
	JR	CONS1
;
;AUSGABE ZU CONST
;
COOUT:	LD	A,C
	CP	A, 10H		;CTRL/P
	JR	NZ, COOU1
	LD	A,(LISW)
	XOR	1		;DRUCKER EIN/AUS
	LD	(LISW),A

	if osver == 11
	ret
COOU1:  ld      a, (LISW)
        or      a
        push    bc
        call    nz, LIST
        pop     hl
        ld      c, l
        ret     c
        ld      a, 2
        jr      CONS1
	ELSE
COOU1:	LD	A,2
	PUSH	BC
	CALL	CONS1		;AUSGABE ZU CONST
	POP	HL
	LD	C,L
	RET	C		;FEHLER
	LD	A,(LISW)
	OR	A
	RET	Z		;KEINE AUSGABE ZU LIST
	ENDIF

;
;AUSGABE ZU LIST
;
LIST:	LD	A,2
LIST1:	LD	B,6		;INTERNE LOG. GERAETENR. LIST
	JR	CONS2
;
;ABFRAGE STATUS LIST
;
LLIST:	LD	A,0
	JR	LIST1
;
;EINGABE VON READER
;
READR:	LD	A,1
RDR1:	LD	B,2		;INTERNE LOG. GERAETENR. READER
	JR	CONS2
;
;AUSGABE ZU PUNCH
;
PUNCH:	LD	A,2
	LD	B,4		;INTERNE LOG. GERAETENR. PUNCH
	JR	CONS2
;
;STEUERPROGRAMM FUER BATCH-MODE VON CONST
;
BAT:	CP	A, 1		;EINGABE GEFORDERT
	JR	Z, READR
	CP	A, 0FFH		;INITIALISIERUNG GEFORDERT
	JR	NZ, LIST1	;AUSGABE


	if osver == 11
	CALL	0FFEEh		; ?????
	ELSE
	CALL	RDR1		;INIT. READER
	ENDIF

	RET	C		;FEHLER
	LD	A,0FFH
	JR	LIST1		;INIT. LIST
;
;ABFRAGE SPIELHEBEL
;
GSTIK:	CALL	GPIOD		;TASTATUR-PIO DIREKT LESEN
	LD	BC,(JOYR)
	LD	(BCSV),BC	;RUECKGABE PARAMETER
	JP	INPIO		;INIT. TASTATUR-PIO
;
;ABFRAGE I/O-BYTE
;
GIOBY:	LD	A,(IOBYT)
	LD	(ASV),A		;RUECKGABE PARAMETER
	LD	C,A
;
;SETZEN I/O-BYTE
;
SIOBY:	LD	A,C
	LD	(IOBYT),A
	OR	A
	RET
;
;SETZEN KASSETTENPUFFER
;
SDMA:	LD	(DMA),BC
	OR	A
	RET
;
;LOGISCHER SPEICHERTEST
;
GMEM:	LD	L,C
	LD	H,B
	CALL	CHRAM		;TEST DER ADRESSE IN HL
	LD	A,1
	JR	C, GM1		;RAM GEFUNDEN
	DEC	A		;GESCHUETZT/ROM
GM1:	LD	(ASV),A		;RUECKGABE PARAMETER
	OR	A
	RET
;
;SETZEN SPEICHERKONFIGURATION
;
SMEM:	LD	L,C
	LD	H,B
	LD	C,A
	CALL	MOD		;STATUS FUER ADR. IN HL AENDERN
	OR	A
	RET
;
;ABFRAGE AKTUELLE UHRZEIT
;
GTIME:	LD	A,(STUND)
	LD	(ASV),A		;RUECKGABE PARAMETER
	LD	HL,(MIN)
	LD	C,H
	LD	B,L
	LD	(BCSV),BC	;
;
;STELLEN DER UHR
;
STIME:	LD	(STUND),A
	LD	L,B
	LD	H,C
	LD	(MIN),HL
	OR	A
	RET
;
;2-STELLIGE DEZIMALZAHL IN INTERNE DARSTELLUNG KONVERTIEREN
;
; Funktion:    Umwandlung Parameterstring (Dezimalzahl) in interne Darstellung (ein Byte)
; a) Eingang
; 	- VIEXT
; 	gerufen von: GEVAL
; 	Parameter  : DE Stringadresse
; b) gerufene Programme
; 	- FORMS formatieren Eingabe-String
; c) Ausgang
;	-
; d) Return
; 	Parameter: DE Adresse nach String
; 		   A Wert
;
VIEXT:	LD	A,(DE)
	OR	A
	SCF
	RET	Z		;ZEICHENKETTE LEER
	LD	A,2		;NEUE LAENGE DER ZEICHENKETTE
	CALL	FORMS		;AUF NEUE LAENGE BRINGEN
	RET	C		;ZU VIELE DEZIMALSTELLEN
	LD	BC,2		;(C)=ANZAHL DER STELLEN
ADEC1:	LD	A,(DE)
	INC	DE
	SUB	30H
	RET	C		;FEHLER
	CP	A, 10
	CCF
	RET	C		;FEHLER
	ADD	A, B
	DEC	C
	RET	Z
	ADD	A, A
	LD	B,A
	ADD	A, A
	ADD	A, A
	ADD	A, B
	LD	B,A		;(B)=ZAHL
	JR	ADEC1
;
;ZEICHENKETTE AUF BESTIMMTE LAENGE FORMATIEREN
;
; Funktion:    Formatieren String  auf n Bytes für Konvertierung in interne Zahl
; Ausblenden bzw. Einfügen von Vornullen
; a) Eingang
; 	- FORMS
; 	gerufen von:  VIEXT37
; 	Parameter: DE Stringadresse
; 	           A neue gewünschte Länge
; b) gerufene Programme
; 	- MOVE verschieben Speicherbereich
; c) Ausgang
; 	-
; d) Return
; 	Parameter: DE Adresse 1. Zeichen neuer String
; 		   CY 0 kein Fehler
; 		      1 zu viele signifikante Stellen (keine Vornullen)
;
FORMS:	LD	L,E		;(DE)=ADR. DER KETTENLAENGE
	LD	H,D
	INC	DE
	CP	A, (HL)
	RET	Z		;LAENGE ERREICHT
	LD	B,0
	LD	C,(HL)
	JR	C, DHAZ		;ALT > NEU
	LD	(HL),A		;NEUE LAENGE
	SUB	C
FORM1:	ADD	HL,BC		;
	LD	E,L		;
	LD	D,H		;
	INC	DE		;
	PUSH	BC		;
	LDDR			;VORNULLEN EINFUEGEN
	POP	BC		;
	EX	DE,HL		;
	LD	(HL),'0'	;
	EX	DE,HL		;
	INC	BC		;
	DEC	A		;
	JR	NZ, FORM1	;
	RET
;
DHAZ:	PUSH	AF
	INC	HL
	INC	HL
	LD	A,(DE)
	CP	A, '0'
	JR	NZ, DHAZE	;KEINE VORNULL
	DEC	C
	CALL	MOVE		;LOESCHEN VORNULL
	DEC	DE
	LD	A,C
	LD	(DE),A		;NEUE LAENGE
	POP	AF
	JR	FORMS
;
DHAZE:	POP	AF		;ZU VIELE SIGNIFIKANTE STELLEN
	SCF
	RET
;
;*******************************************************************
;*	CRT - TREIBER	TEIL 1: BILDSCHIRM                         *
;*******************************************************************
;
;FARBCODEBERECHNUNG
COL:	SUB	14H		;(A)=FARBSTEUERCODE
	JR	C, RAND		;RANDFARBE AENDERN
	JR	Z, INK		;VORDERGRUNDFARBE AENDERN

PAPER:
	IF farb16
	LD	B,0F0H		;Unterstützung für 16 Farben
	ELSE
	LD	B,0F8H		;HINTERGRUNDFARBE AENDERN
	ENDIF

	LD	A,E		;ALTER FARBCODE
P1:	AND	A, B
	OR	C		;(C)=ALTER FARBCODE
	RET			;(A)=RSULTIERENDER FARBCODE
;

INK:
	IF farb16
	CALL	INK16		;Unterstützung für 16 Farben
	else
	LD	A,E
	LD	B,8FH
	ENDIF

I0:	SLA	C
I1:	SLA	C
	SLA	C
	SLA	C
	JR	P1
;
RAND:	IN	A, DPIO1A	;SYSTEMPORT PIO 1
	IF farb16
	CALL	BORD
	AND	B
	OR 	C
	else
	LD	B,0C7H
	CALL	I1
	ENDIF
R1:	OUT	DPIO1A, A
	POP	AF		;RUECKKEHRADR. VERNICHTEN
	JR	MCOL2
;
;ZEICHENAUSGABE
;
; Funktion: Behandlung alle Sonderzeichen (Farbe, Bell, Blinken, Invers)
; a) Eingang
; 	- OCHAR
; 	gerufen von: CRT
; 	Parameter  : C Zeichen
; b) gerufene Programme
; 	- COL Farbbehandlung
; 	- BELL1 Tonausgabe vorbereiten/beenden
; 	- INIVT Initialisieren Ton
; 	- AUS1 Ausgabe Ton
; 	- OC Ausgabe ASCII-Zeichen
; 	- MIAT Farbcode invertieren
;
OCHAR:	LD	A,(ATRIB)	;AKTUELLER FARBCODE
	LD	E,A
	LD	A,(HL)		;(HL)=ADR. VON COLSW
	OR	A
	JR	Z, OCH1		;ZEICHEN IST KEIN FARBCODE
MCOL:	CALL	COL		;NEUEN FARBCODE BERECHNEN
MCOL1:	LD	(ATRIB),A	;NEUER AKTUELLER FARBCODE
MCOL2:	XOR	A
	LD	(HL),A		;FARBSCHALTERLOESCHEN
	RET
;

OCH1:
	if farb16
	JP	CTRLAD		;AUSZUGEBENDES ZEICHEN
MF8A1:
	else
	LD	A,C		;AUSZUGEBENDES ZEICHEN
	SUB	5
	ENDIF

	JR	Z, SCOL		;STEUERCODE RANDFARBE GEFUNDEN (05 (F) CTRL/E)
	DEC	A
	JR	NZ, OCH3
;06 (F) CTRL/F Blinken EIN/AUS
BLINK:	LD	A,E		;BLINKBIT EIN/AUS
	XOR	80H		;BLINKBIT AENDERN
	JR	MCOL1
OCH3:	DEC	A
	JR	NZ, OCH4
;07 CTRL/G Ausgabe eines Summertones
BELL:	DI			;AUSGABE TASTATURTON
	CALL	BELL1		;SUMMER EIN/AUS
	CALL	INIVT		;INIT. TONAUSGABE
	LD	BC,30H		;ANZAHL TOENE
BELL0:	CALL	AUS1		;AUSGABE
	CPI			;
	JP	PE,BELL0	;
	LD	A,3
	OUT	CTC0, A		;CTC 0  HALT
BELL1:	IN	A, DPIO1A
	XOR	80H
	OUT	DPIO1A, A
	RET
;
OCH4:	SUB	0AH
	JR	NZ, OCH44
;11 CTRL/Q Kontrollton EIN/AUS
	DEC	HL		;(HL)=ADR. SCHALT. KONTROLLTON
	LD	A,(HL)		;
	XOR	1		;UMSCHALTEN
	LD	(HL),A		;
	RET
;
OCH44:	SUB	3
	JR	Z, SCOL		;FARBSTEUERCODE VORDERGRUND
	DEC	A
	JR	NZ, OCH5	;KEIN FARBSTEUERCODE HINTERGRUND
; 14 (F) COLOR CTRL/T nächstes Zeichen ist Code für Vordergrundfarbe
; 15 (F) SHIFT+COLOR o. CTRL/U nächstes Zeichen ist Code für Hintergrundfarbe
SCOL:	LD	A,C		; C = 14h oder 15h
	LD	(HL),A		;FARBSTEUERCODE IN COLSW MERKEN
OCH5:	DEC	A
	JR	Z, INVER	;FARBEN INVERTIEREN (bei A=15 und A=16)
; sonst normale Zeichenausgabe
	CALL	OC		;AUSGABE DES ZEICHENS
	LD	A,(BSW)
	OR	A
	RET	Z		;KEIN KONTROLLTON
	JR	BELL		;KONTROLLTON AUSGEBEN
; 16 (F) CTRL/V Inversdarstellung aller folgenden Zeichen
INVER:	LD	A,E
	CALL	MIAT		;FARBE INVERTIEREN
	JR	MCOL1
;
;STEUERPROGRAMM DES CRT - TREIBERS
;
; Funktion:  Bildschirmtreiber, Tastaturtreiber, Steuerprogramm
; a) Eingang
; 	- CRT
; 	gerufen von: CONST1 (über JMP (HL))
; 	Parameter  : A Art des Rufes
; 			FF Init.
; 			0 Status Tastatur
; 			1 Eingabe
; 			2 Ausgabe
; 		     (C Zeichen bei Ausgabe)
; 			3 Cursor löschen
; 			4 Cursor setzen
; 			5  Abfrage log. Cursoradr.
; 			6  Setzen log. Cursoradr.
; 		     (DE Adresse; Zeile/Spalte)
; 			7  Abfrage phys. Cursoradr.
; 			8 Setzen phys. Cursoradr.
; 		     (DE Adresse)
; b) gerufene Programme
; 	- OC Ausgabe ASCII-Zeichen
; c)  Ausgang
; 	- INITA Tastaturinitialisierung
; 	- OCHAR Ausgabe Zeichen
; 	- OC Ausgabe ASCII-Zeichen (für Cursoroperationen)
; d) Return
; 	Parameter: A Zeichen bei IN
; 		DE, HL Adressen bei Cursorabfrage
; 		DE log.
; 		HL phys.
; ;
CRT:	LD	HL,COLSW	;HL FUER FARBBEHANDLUNG STELLEN
	INC	A
	JR	NZ, CRT1
ICRT:	DI			;INITIALISIERUNG CRT
	LD	HL,1900H	;(24 Zeilen)
	LD	(P1ROL),HL	;STANDARDFENSTER
	LD	H,29H		;EINSTELLEN (40 Spalten) L = 0
	LD	(P3ROL),HL	;
	LD	H,0		; L = 0
	LD	(COUNT),HL	;
	LD	(KEYBU),HL	;ARBEITSZELLEN LOESCHEN
	LD	(JOYR),HL	;
	LD	(BSW),HL	;
	IN	A, DPIO1A
	AND	A, 38H		;GRAFIKANZEIGE UND
	OUT	DPIO1A, A	;TASTATURSUMMER AUS
	JP	INITA		;INIT. TASTATUR
;
CRT1:	DEC	A
	JR	NZ, CRT2

; 00	Abfrage Status
;	Return:
;		A Status
;		0 kein Zeichen bei Eingabegerät, nicht bereit bei Ausgabegerät
;		sonst Zeichen liegt an bei Eingabegerät,
;		(im installierten CRT-Treiber wird der Zeichencode übergeben)
STAT:	LD	A,(KEYBU)	;STATUS ABFRAGEN
	RET
;
CRT2:	DEC	A
	JR	NZ, CRT3
CI:	LD	A,(KEYBU)	;TASTATUREINGABE
	OR	A
	JR	Z, CI		;WARTEN AUF ZEICHEN, 01 Eingabe Zeichen
	PUSH	AF
	XOR	A
	LD	(KEYBU),A	;TASTATURPUFFER LOESCHEN
	LD	(JOYR),A	;SPIELHEBELPUFFER
	LD	(JOYL),A	;LOESCHEN
	LD	A,(HL)		;(HL)=ADR. FARBSCHALTER
	OR	A
	JR	Z, CI2		;ZEICHEN IST KEIN FARBCODE
	POP	AF

	if farb16
	CP	A, 49H
	JR	NC, CI		;KEIN GUELTIGER FARBCODE
	JP	FARB16C		;WANDELN IN INTERNEN FARBCODE
MF941:	OR	A		;KEIN GUELTIGER FARBCODE
	else
	CP	A, 39H
	JR	NC, CI		;KEIN GUELTIGER FARBCODE
	SUB	31H		;WANDELN IN INTERNEN FARBCODE
	JR	C, CI		;KEIN GUELTIGER FARBCODE
	ENDIF

	PUSH	AF
CI2:	POP	AF
	RET
;
CRT3:	DEC	A
	JP	Z, OCHAR	;02 ZEICHEN AUSGEBEN
	LD	C,0		;ZUFAELLIGES ZEICHEN LOESCHEN
	DEC	A
	JP	Z, DELC		;03 CURSOR LOESCHEN
	DEC	A
	JP	Z, SETC		;04 CURSOR ANZEIGEN
	DEC	A
	JR	NZ, CRT4

; 05	Abfrage logische und physische Cursoradresse
;	Return:
;		HL physische Cursoradresse
;		DE logische Cursoradresse
GLCU:	CALL	OC		;ABFRAGE LOG. CURSORADRESSE
				;HL MIT PHYS. ADR. LADEN
	LD	DE,(CHARP)	;LOG. ADRESSE
	RET
;
CRT4:	DEC	A
	JR	Z, SLCU		;06 LOG. CURSORADRESSE SETZEN
	DEC	A
	JR	Z, OC		;07 ABFRAGE PHYS. CURSORADRESSE
				;HL MIT PHYS. ADR. LADEN
	DEC	A		;08 Setzen Cursor auf physische Adresse
	RET	NZ		;KEIN GUELTIGER RUF

; 08	Setzen Cursor auf physische Adresse
;	Eingang:
;		DE physische Cursoradresse
SPCU:	LD	HL,0EC00H	;CURSOR AUF PHYS. ADR. SETZEN
	EX	DE,HL
	SBC	HL,DE
	RET	C		;ADR. NICHT IM ZEICHENSPEICHER
	LD	DE,40		;UMRECHNEN PHYS. --> LOG. ADR.
SP1:	SBC	HL,DE
	INC	A
	JR	NC, SP1
	ADD	HL,DE
	INC	L
	LD	H,A
	EX	DE,HL

;06	Setzen Cursor auf logische Adresse
;	Eingang:
;		DE logische Cursoradresse
SLCU:	LD	(CHARP),DE	;CURSOR AUF LOG. ADR. SETZEN

; 07	Abfrage physische Cursoradresse
;	Return:
;		HL physische Cursoradresse

;
;*******************************************************************
;*	PHYSISCHER BILDSCHIRMTREIBER                               *
;*******************************************************************
;
; Funktion:  phys. Bildschirmtreiber
; a) Eingang
; 	- OC
; 	gerufen von: CRT, OCHAR
; 	Parameter  : C  ASCII-Zeichen
; b) gerufene Programme
; 	- DELC Cursor löschen
; 	- ROLU Rollen hoch
; 	- ROLD Rollen runter
; 	- MIAT Farbcode investieren
; c) Ausgang
; 	-
; d) Return
; 	Parameter: HL phys. Cursoradresse
;
OC:	if krtgrafik
	jp	ocx
	else
	LD	HL,SETC		;ADR. FUER ABSCHLIESSENDES
	endif
oc0:	PUSH	HL		;CURSOR ANZEIGEN KELLERN
	CALL	DELC		;CURSOR LOESCHEN
	; HL = (CURS), DE= (CURS)-ONEKB (=Adr. im Farbspeicher)
	LD	A,C		;AUSZUGEBENDES ZEICHEN
	SUB	8		;CURSOR LINKS
	RET	C		;FEHLER
	JR	Z, DECCP	;DEC ZEICHENZEIGER
	DEC	A		;CURSOR RECHTS
	JR	Z, INCCP	;INC ZEICHENZEIGER
	DEC	A		;CURSOR RUNTER (LF)
	JR	Z, INCLP	;INC ZEILENZEIGER
	DEC	A		;CURSOR HOCH
	JR	Z, DECLP	;DEC ZEILENZEIGER
	DEC	A
	JR	Z, HOME		;LOESCHEN BILDSCHIRM
	DEC	A
	JR	Z, CR		;CURSOR AUF ZEILENANFANG (CR)
	CP	A, FIRST-0DH
	RET	C		;KEIN DRUCKBARES ZEICHEN
;Zeichenausgabe
; HL = (CURS), DE= (CURS)-ONEKB (=Adr. im Farbspeicher)
DIS:	LD	(HL),C		;ZEICHEN IN ZEICHENSPEICHER
	LD	A,(ATRIB)	;AKTUELLER FARBCODE
	LD	(DE),A		;FARBCODE IN FARBSPEICHER
	JR	INCCP		;INC ZEICHENZEIGER
;Sonderzeichen
HOME:	LD	A,(P1ROL)
	INC	A
	LD	(LINEP),A	;CURSOR AUF 1. ZEILE
	LD	B,A
	LD	A,(P2ROL)
	SUB	B		;AKTUELLE ZEILENZAHL
	LD	B,A
HOME1:	PUSH	BC
	CALL	ROLU		;ROLLEN AUFWAERTS
	POP	BC
	DJNZ	HOME1		;BIS FENSTER LEER
CR:	LD	A,(P3ROL)
	LD	(CHARP),A	;CURSOR AUF 1. SPALTE-1
;INC ZEICHENZEIGER
INCCP:	LD	HL,CHARP
	LD	DE,P4ROL
	INC	(HL)		;CURSOR AUF NAECHSTE SPALTE
	LD	A,(DE)
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	NZ
	DEC	DE
	LD	A,(DE)
	INC	A
	LD	(HL),A		;CURSOR AUF 1. SPALTE
;INC ZEILENZEIGER
INCLP:	LD	HL,LINEP
	INC	(HL)		;CURSOR AUF NAECHSTE ZEILE
	LD	A,(P2ROL)
	DEC	A
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	NC
	LD	(HL),A		;CURSOR AUF LETZTE ZEILE
	JR	ROLU		;ROLLEN AUFWAERTS
;DEC ZEICHENZEIGER
DECCP:	LD	HL,CHARP
	LD	DE,P3ROL
	DEC	(HL)		;CURSOR AUF VORHERGEHENDE SPALTE
	LD	A,(DE)
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	NZ
	INC	DE
	LD	A,(DE)
	DEC	A
	LD	(HL),A		;CURSOR AUF LETZTE SPALTE
;DEC ZEILENZEIGER
DECLP:	LD	HL,LINEP
	DEC	(HL)
	LD	A,(P1ROL)
	CP	A, (HL)		;CURSOR AUS DEM FENSTER?
	RET	C
	INC	A
	LD	(HL),A		;CURSOR AUF 1. ZEILE
	JR	ROLD		;ROLLEN ABWAERTS
;CURSOR WIEDER ANZEIGEN
; 04	Cursor anzeigen
;	Return:
;		HL physische Cursoradresse
SETC:	LD	A,(CHARP)
	LD	C,A
	LD	A,(LINEP)
	LD	B,A
	LD	HL,SCTOP-LINEL 	;ZEICHENSPEICHERADR.-ZEILENLAENGE
	LD	DE,LINEL	;ZEILENLAENGE
SETC1:	ADD	HL,DE		;
	DJNZ	SETC1		;
	LD	B,C		;BERECHNEN CURSORADR.
	DEC	HL		;
SETC2:	INC	HL		;
	DJNZ	SETC2		;
	LD	(CURS),HL	;MERKEN CURSORADRESSE
	LD	A,(MAPAR+7)	;KONFGURATIONSBYTE FUER FARBE
	BIT	5,A		;FARBVARIANTE?
	JR	NZ, SETC5	;FARBE
	LD	A,(HL)		;KEINE FARBE->MERKEN ZEICHEN
	LD	(BUFF),A	;
	LD	(HL),0FFH	;SETZEN CURSOR
SETC5:	LD	DE,ONEKB
	PUSH	HL
	SBC	HL,DE		;ZUGEHOERIGE FARBCODEADRESSE
	LD	A,(HL)		;
	LD	(BUFFA),A	;MERKEN FARBCODE
	LD	A,(ATRIB)
	XOR	80H		;BLINKEN FUER CURSOR INVERTIEREN
	LD	B,A
	XOR	(HL)
	AND	A, 0F0H
	LD	A,B

	if farb16
	NOP			;FARBE BLEIBT
	NOP
	NOP
	else
	CALL	Z, MIAT		;CURSORFARBE INVERTIEREN
	ENDIF

	LD	(HL),A		;CURSORFARBE SETZEN
	POP	HL
	RET
;
;LOESCHEN CURSOR
; 03	Cursor löschen
DELC:	LD	HL,(CURS)
	LD	A,(MAPAR+7)	;KONFIGURATIONSBYTE FUER FARBE
	BIT	5,A		;FARBVARIANTE?
	JR	NZ, DELC1	;FARBE
	LD	A,(BUFF)	;KEINE FARBE
	LD	(HL),A		;ZEICHEN ZURUECK
DELC1:	LD	DE,ONEKB
	PUSH	HL
	OR	A
	SBC	HL,DE		;ZUGEHOERIGE FARBCODEADRESSE
	LD	A,(BUFFA)
	LD	(HL),A		;ALTEN FARBCODE ZURUECK
	EX	DE,HL
	POP	HL
	RET
;
;BILDSCHIRM ROLLEN (FENSTER)
;
; Funktion: Bildschirm rollen, letzte Zeile löschen38
; a) Eingang
; 	- ROLU, ROLD
; 	gerufen von:  OC
; 	- ROLL
; 	gerufen von: ROLU, ROLD
; 	Parameter  : A <>0 runter
; 		       =0 hoch
; b) gerufene Programme
; 	- MOVE Speicher verschieben
;
ROLU:	DB	3EH		;LD A,
;
ROLD:	XOR	A
;
ROL:	PUSH	AF
	LD	HL,SCTOP-LINEL	;ZEICHENSPEICHERADR.-ZEILENLAENGE
	LD	DE,LINEL	;ZEILENLAENGE
	LD	A,(P1ROL)
	INC	A
	LD	C,A
	LD	A,(P2ROL)
	DEC	A
	LD	B,A
	POP	AF
	PUSH	BC
	OR	A		;ROLLEN ABWAERTS?
	JR	Z, ROL1
	LD	B,C
ROL1:	ADD	HL,DE
	DJNZ	ROL1		;1. ZU ROLLENDE ZEILE
	POP	BC
	PUSH	AF
	LD	A,B
	SUB	C
	JR	Z, ENDRO	;EINE ZEILE, NUR LOESCHEN
	LD	B,A
ROL2:	POP	AF
	PUSH	HL
	OR	A		;ROLLEN ABWAERTS?
	JR	Z, ROL3
	ADD	HL,DE
	JR	ROL4
ROL3:	SBC	HL,DE
ROL4:	POP	DE
	PUSH	AF
	PUSH	HL
	PUSH	BC
;
;EINE ZEILE IN ROLLRICHTUNG UMSPEICHERN
MOVEL:	LD	A,(P3ROL)
	INC	A
	LD	B,A
	DEC	HL
	DEC	DE
MOVL1:	INC	HL
	INC	DE
	DJNZ	MOVL1		;1. SPALTE SUCHEN
	LD	C,A
	LD	A,(P4ROL)
	SUB	C
	LD	C,A		;ZEICHENANZAHL
	CALL	MOVE		;UMSPEICHERN
	PUSH	BC
	LD	BC,ONEKB
	EX	DE,HL
	SBC	HL,BC		;ADR. IM FARBSPEICHER
	EX	DE,HL
	SBC	HL,BC
	POP	BC
	LDIR
	POP	BC
	POP	HL
	LD	DE,LINEL
	DJNZ	ROL2
ENDRO:	POP	AF
;
;ZEILE LOESCHEN
DELLI:	LD	A,(P3ROL)
	INC	A
	LD	C,A
	LD	B,A
DELL1:	INC	HL
	DJNZ	DELL1		;1. SPALTE SUCHEN
	LD	E,L
	LD	D,H
	DEC	HL
	LD	A,(P4ROL)
	SUB	C
	LD	C,A		;ANZAHL ZEICHEN
	DEC	C
	LD	(HL),SPACE
	PUSH	BC
	PUSH	AF
	CALL	NZ, MOVE	;LOESCHEN
	LD	DE,ONEKB
	SBC	HL,DE		;ADR. IM FARBSPEICHER
	LD	A,(ATRIB)	;AKTUELLER FARBCODE
	RES	7,A		;KEIN BLINKEN
	LD	(HL),A
	POP	AF
	POP	BC
	RET	Z
	LD	E,L
	LD	D,H
	INC	DE
	LDIR			;LOESCHEN FARBSPEICHER
DELEN:	RET
;
;FARBCODE INVERTIEREN
MIAT:
	if farb16
	JP	MIATN
	NOP
MFADA:
	else
	LD	C,0
	SLA	A
	ENDIF

	RR	C		;MERKEN BLINKBIT
	RLCA
	RLCA
	RLCA
	AND	A, 7FH
	OR	C		;BLINKBIT ZURUECK
	RET
;
;*******************************************************************
;* 	CRT-TREIBER  TEIL 2: TASTATUR                              *
;*******************************************************************
;
;INITIALISIERUNG TASTATUR
;
INITA:	DI
	PUSH	AF
	CALL	INICT		;CTC INITIALISIEREN
	POP	AF
;
;INITIALISIERUNG TASTATUR-PIO  DATEN A  AUF 0
INPIO:	PUSH	AF
	CALL	INITT		;INIT. PIO DATEN A AUF FFH
	LD	A,83H		;INTERRUPT
	OUT	SPIOB, A	;Interrupt ein
	XOR	A		;A=0
	OUT	DPIOA, A	;SPIOA alle Leitungen auf 0
;bei Tastendruck wird jetzt ein LOW-Pegel von PIOA auf PIOB durchgeleitet
;dieser löst einen Interrupt aus --> INTP
	POP	AF
	EI
	RET
;
;INITIALISIERUNG CTC
INICT:	LD	A,3		;Steuerwort CTC: Reset
	OUT	CTC0, A
	OUT	CTC2, A
	OUT	8AH, A		;Steuerung PIO1 Kanal A, Interrupt aus
	XOR	A
	OUT	CTC0, A		;INTERRUPT-VEKTOR = 00h
	LD	A,0C7H		;ZAEHLERINTERRUPT (Steuerwort CTC3: EI, Reset, Zeitkonstante folgt)
	OUT	CTC3, A
	LD	A,40H		;Zeitkonstante 64, zusammen mit CTC2 ergibt das einen Takt von 1 sek = 1 Hz
	OUT	CTC3, A
INIC1:	LD	A,27H		;ZEITGEBER KEIN INTERRUPT (Steuerwort CTC2: Vorteiler 256, Reset, Zeitkonstante folgt)
	OUT	CTC2, A
	LD	A,96H		;Zeitkonstante: 2,4576 Mhz / 256 / 96h = 64 Hz
	OUT	CTC2, A
	LD	A,3
	RET
;
;INITIALISIERUNG TASTATUR-PIO DATEN A AUF FFH
INITT:	LD	A,0CFH		;BIT E/A
	OUT	SPIOA, A
	XOR	A		;ALLES AUSGAENGE
	OUT	SPIOA, A
	LD	A,8		;Interruptvektor
	OUT	SPIOB, A
	LD	A,0CFH		;BIT E/A
	OUT	SPIOB, A
	LD	A,0FFH		;ALLES EINGAENGE
	OUT	SPIOB, A
	LD	A,17H		;Interruptsteuerwort, OR, LOW-aktiv, Maske folgt
	OUT	SPIOB, A
	XOR	A		;A=0, Interrupt-Maske
	OUT	SPIOB, A	;alle Eingänge mit Interrupt
	DEC	A		;A=FF
	OUT	DPIOA, A	;mit FF init.
	RET

	IF tastneu = 0

;
;UMC0DIERUNGSTABELLE FUER SONDERTASTEN+SHIFT
;S64..S78
TAB1:	DB	18H		; tab right
	DB	1EH		; CONT
	DB	1FH		; DEL
	DB	5DH		; ]
	DB	0
	DB	8		; cu left
	DB	9		; cu right
	DB	0AH		; cu down
	DB	0BH		; cu up
	DB	2		; CL LN
	DB	0DH		; ENTER
	DB	3		; STOP
	DB	20H		; space
;
;UMCODIERUNGSTASTEN FUER SONDERTASTEN
;S64..S78
TAB2:	DB	19H		; tab left
	DB	13H		; PAUSE
	DB	1AH		; INS
	DB	5EH		; ^
	DB	0
	DB	8		; cu left
	DB	9		; cu right
	DB	0AH		; cu down
	DB	0BH		; cu up
	DB	1BH		; ESC
	DB	0DH		; ENTER
	DB	3		; STOP
	DB	20H		; space
	DB	0
	DB	14H		; COLOR
	DB	0
	DB	7EH		;INTERNER CODE GRAFIC-TASTE
	DB	1CH		; LIST
	DB	1DH		; RUN
	DB	7DH		;INTERNER CODE SHLOC-TSTE
;
;UMCODIERUNGSTABELLE FUER GRAFIKSYMBOLE
TABG:	DB	0ABH		;CTRL/A

	if osver == 11
	DB	8Ch		; CTRL B
	ELSE
	DB	8DH
	ENDIF

	DB	82H		; CTRL C
	DB	85H		; CTRL D
	DB	86H		; CTRL E
	DB	84H		; CTRL F
	DB	0CFH		; CTRL G
	DB	0C3H		; CTRL H
	DB	96H		; CTRL I
	DB	90H		; CTRL J
	DB	9BH		; CTRL K
	DB	9CH		; CTRL L
	DB	0AFH		; CTRL M
	DB	0C4H		; CTRL N
	DB	95H		; CTRL O
	DB	92H		; CTRL P
	DB	0AEH		; CTRL Q
	DB	87H		; CTRL R
	DB	0ACH		; CTRL S
	DB	8CH		; CTRL T
	DB	91H		; CTRL U
	DB	83H		; CTRL V
	DB	0ADH		; CTRL W
	DB	80H		; CTRL X
	DB	81H		; CTRL Y
	DB	0C2H		; CTRL Z
	DB	0
	DB	0
	DB	0
	DB	93H		;CTRL/^
	DB	0
	DB	0
	DB	0ECH		; SHIFT 1
	DB	0EDH		; SHIFT 2
	DB	0EEH		; SHIFT 3
	DB	0EFH		; SHIFT 4
	DB	0F0H		; SHIFT 5
	DB	0CAH		; SHIFT 6
	DB	0CCH		; SHIFT 7
	DB	0D0H		; SHIFT 8
	DB	0D1H		; SHIFT 9
	DB	0DAH		; SHIFT :
	DB	0DEH		; SHIFT ;
	DB	0FCH		; ','
	DB	0DFH		; SHIFT =
	DB	0FDH		; '.'
	DB	0DBH		; '?'
	DB	0B3H		;'0'
	DB	0A0H		; '1'
	DB	0A1H		; '2'
	DB	9EH		; '3'
	DB	9FH		; '4'
	DB	0C0H		; '5'
	DB	0C7H		; '6'
	DB	0B4H		; '7'
	DB	0B0H		; '8'
	DB	0B1H		; '9'
	DB	8FH		; ':'
	DB	0FEH		; ';'
	DB	0DCH		; SHIFT ','
	DB	0FFH		; '='
	DB	0DDH		; SHIFT '.'
	DB	0BEH		; '?'
	DB	0B2H		;'@'
	DB	0A3H		; 'A'
	DB	0F9H		; 'B'
	DB	0AAH		; 'C'
	DB	0A5H		; 'D'
	DB	0A9H		; 'E'
	DB	88H		; 'F'
	DB	0C8H		; 'G'
	DB	0C6H		; 'H'
	DB	0BCH		; 'I'
	DB	0B6H		; 'J'
	DB	0BBH		; 'K'
	DB	0BAH		; 'L'

	IF osver = 11
	DB	0FBH
	ELSEIF osver = 12
	DB	0B7H		; 'M'
	ELSEIF osver = 13
	DB	0FBH
	ENDIF

	DB	0FAH		; 'N'
	DB	0BDH		; 'O'
	DB	0B8H		; 'P'
	DB	0A8H		; 'Q'
	DB	0C1H		; 'R'
	DB	0A6H		; 'S'
	DB	89H		; 'T'
	DB	0B5H		; 'U'
	DB	0F8H		; 'V'
	DB	0A4H		; 'W'
	DB	0A2H		; 'X'
	DB	0A7H		; 'Y'
	DB	0C5H		; 'Z'
	DB	98H		; CONTR :
	DB	0
	DB	0D7H		; SHIFT ^
	DB	0B9H		; ^
	DB	0D2H		; SHIFT 0
	DB	0D3H		; SHIFT @
	DB	0F2H		; SHIFT A
	DB	0E0H		; SHIFT B
	DB	0E2H		; SHIFT C
	DB	0F4H		; SHIFT D
	DB	0E8H		; SHIFT E
	DB	0F5H		; SHIFT F
	DB	0F6H		; SHIFT G
	DB	8AH		; SHIFT H
	DB	0D4H		; SHIFT I
	DB	8BH		; SHIFT J
	DB	0D8H		; SHIFT K
	DB	0D9H		; SHIFT L
	DB	0CDH		; SHIFT M
	DB	0CEH		; SHIFT N
	DB	0D5H		; SHIFT O
	DB	0D6H		; SHIFT P
	DB	0EAH		; SHIFT Q
	DB	0E7H		; SHIFT R
	DB	0F3H		; SHIFT S
	DB	0E6H		; SHIFT T
	DB	0C9H		; SHIFT U
	DB	0E1H		; SHIFT V
	DB	0E9H		; SHIFT W
	DB	0E3H		; SHIFT X
	DB	0E4H		; SHIFT Y
	DB	0CBH		; SHIFT Z
	DB	94H		; CONTR <
	DB	9DH		; CONTR ,
	DB	97H		; CONTR =
	DB	9AH		; CONTR .
	DB	99H		; CONTR ?

	ELSE	; tastneu = 1

;Neue Tastaturtabelle:
;
;TABELLE FUER ALLE TASTEN
;
TAB1:
;Spalte 0
	DB  '0'
	DB  '8'
	DB  '@'
	DB  'H'
	DB  'P'
	DB  'X'
	DB  08H  ; <-
	DB  00H  ; SHIFT
;Spalte 1
	DB  '1'
	DB  '9'
	DB  'A'
	DB  'I'
	DB  'Q'
	DB  'Y'
	DB  09H  ; ->
	DB  14H  ; COLOR
; Spalte 2
	DB  '2'
	DB  ':'
	DB  'B'
	DB  'J'
	DB  'R'
	DB  'Z'
	DB  0AH  ; cursor down
	DB  00H  ; CONTROL
; Spalte 3
	DB  '3'
	DB  ';'
	DB  'C'
	DB  'K'
	DB  'S'
	DB  19H  ; |<-
	DB  0BH  ; cursor up
	DB  11H  ; GRAFIK
; Spalte 4
	DB  '4'
	DB  ','
	DB  'D'
	DB  'L'
	DB  'T'
	DB  13H  ; PAUSE
	DB  1BH  ; ESC
	DB  1CH  ; LIST
; Spalte 5
	DB  '5'
	DB  '='
	DB  'E'
	DB  'M'
	DB  'U'
	DB  1AH  ; INS
	DB  0DH  ; ENTER
	DB  1DH  ; RUN
; Spalte 6
	DB  '6'
	DB  '.'
	DB  'F'
	DB  'N'
	DB  'V'
	DB  '^'
	DB  03H  ; STOP
	DB  10H  ; SHIFT LOCK
; Spalte 7
	DB  '7'
	DB  '?'
	DB  'G'
	DB  'O'
	DB  'W'
	DB  '[' ; (S68)
	DB  ' '	; SPACE
	DB  ']' ; (S88)
;
;TABELLE DER SONDERTASTEN (24)
;
TAB2:	DB  '1'
	DB  '2'
	DB  '3'
	DB  '4'
	DB  '5'
	DB  '6'
	DB  '7'
	DB  '8'
	DB  '9'
	DB  '0'
	DB  ':'
	DB  ';'
	DB  ','
	DB  '='
	DB  '.'
	DB  '?'
	DB  19H  ; |<-
	DB  13H  ; PAUSE
	DB  1AH  ; INS
	DB  1BH  ; ESC
	DB  20H  ; SPACE
  	DB  1CH  ; LIST
	DB  1DH  ; RUN
	DB  14H  ; INK
;
;TABELLE DER SONDERTASTEN + SHIFT
;
	DB  3		; 15.08.2018
	DB  '!'
	DB  '"'	 ; "
	DB  '#'
	DB  '$'
	DB  '%'
	DB  '&'
	DB  27H  ; ’
	DB  '('
	DB  ')'
	DB  '_'
	DB  '*'
	DB  '+'
	DB  '<'
	DB  '-'
	DB  '>'
	DB  2FH  ; /
	DB  18H  ; ->|
	DB  1EH  ; CONT
	DB  1FH  ; DEL
	DB  02H  ; CLLN
	DB  20H  ; SPACE
	DB  7CH  ; |
;;	DB  7FH  ;
        DB  5CH  ; 15.08.2018
	DB  15H  ; PAPER
	DB  3		; 15.08.2018
	DB  0FFH
;	DB  0FFH

	if rommenu
;Menü, nur in der Version 2.1 implementiert, sonst alles 0FFH:
MENUE:	CALL	PRNST
	LD	A,(IOBYT)
	AND	0FCH
	OR	01H
	CALL 	IOST1
	LD	HL,0048H 	; "H"
	LD	(CONBU+2),HL	; PSEUDOEINGABE "H"
	CALL	GVAL
	CALL	CPROM		; SUCHEN KOMMANDO IM SPEICHER
	RET	NZ  		; NICHT GEFUNDEN
	JP	(HL)  		; SPRUNG ZUM PROGRAMM "H"
	endif

;------------------------------------------------------------------------------
; Patches V Pohlers
;------------------------------------------------------------------------------

; Anpassung Zeichenausgabe: Jedesmal die orig. Grafik wieder einschalten
	if krtgrafik
ocx:	ld	a,0
	out	0b8h,a		;KRT-Grafik aus
	LD	HL,SETC		;orig. Code
	jp	oc0
	endif

	org	0FBD3h
;------------------------------------------------------------------------------
	ENDIF

;
;TABELLE DER LOGISCHEN GERAETE
PHYDV:	DW	TXCON
	DB	"CONST "
	DB	0
	DW	TXCON+2
	DB	"READER"
	DB	0
	DW	TXCON+4
	DB	"PUNCH "
	DB	0
	DW	TXCON+6
	DB	"LIST  "
	DB	0
;
;WBOOT - MELDUNG
TXTWB:	DB	0AH
	DB	0DH
	DB	"OS"
	DB	0AH
	DB	0DH
	DB	0
;
;TABELLE DER RESIDENTEN KOMMANDOS
;
	ORG	RESET+0C00H
;
RESCO:	JP	ASGN
	DB	"ASGN    "
	DB	0
	JP	TIME_
	DB	"TIME    "
	DB	0
	JP	LOAD
	DB	"CLOAD   "
	DB	0
;
;TABELLE DER PHYSISCHEN GERAETE IM MONITOR
LOGDV:	DW	0001		;LOG. GERAET CONST, PHYS. CRT
	DB	"CRT"
	DB	0
	DW	0002		;LOG. GERAET CONST, PHYS. BAT
	DB	"BAT"
	DB	0
;
;RESET - MELDUNG
MSG:	DB	14H	; Color
	DB	1
	DB	0CH
	IFNDEF  resmsg
	DB	"robotron  Z 9001"
	ELSE
	DB	resmsg
	ENDIF
	DB	0AH
	DB	0DH
	DB	14H	; Color
	DB	2
	DB	0
;
TXTRC:	DB	0AH
	if osver == 11
	DB	0DH
	ENDIF
	DB	"start tape"
	DB	0AH
	DB	0DH
	DB	0
;
;FEHLERMELDUNGEN
TXTBE:
	IF	osver <> 11
	DB	07		;CTRL/G
	ENDIF

	DB	"BOS-"
TXTE:	DB	"error"
	DB	07
	DB	0
TXTMP:	DB	"memory protected"
	DB	0
TXTEO:	DB	"end of memory"
	DB	0
TXTNB:	DB	"record not found"
	DB	0
TXTPT:	DB	"bad record"
	DB	0
TXTNF:	DB	"file not found"
;
;TABELLE DER TRENNZEICHEN
DTAB:	DB	0
	DB	" ,.:"
;
;INTERRUPTADRESSEN
INTV:	DW	IKACT		;KASSETTE SCHREIBEN	CTC0
	DW	0		;			CTC1
	DW	ICTC		;VORTEILER UHR		CTC2
	DW	INUHR		;SEKUNDENTAKT UHR	CTC3
	DW	INTP		;TASTATUR		PIOB
	DW	IKEP		;KASSETTE LESEN		PIO1AS
;
COMPW:	PUSH	HL
	OR	A
	SBC	HL,DE
	POP	HL
	RET
;
;UHRINTERRUPTROUTINE
;
INUHR:	EI
	PUSH	HL
	PUSH	BC
	PUSH	AF
	LD	HL,SEK+1
	LD	B,2
	LD	A,60
INUH1:	DEC	HL
	INC	(HL)
	CP	A, (HL)
	JR	NZ, INUH3
	LD	(HL),0
	DJNZ	INUH1
	LD	A,24
	DEC	HL
	INC	(HL)
	CP	A, (HL)
	JR	NZ, INUH3
	LD	(HL),0
INUH3:	POP	AF
	POP	BC
	POP	HL
	RETI
;
;TASTATURINTERRUPTROUTINE
;wird durch PIOB aktiv, wenn ein Eingang auf LOW geht
;weiter geht es mit einem Interrupt durch CTC2 --> ICTC
;
INTP:	PUSH	AF
	LD	A,10
	LD	(COUNT),A	;INTERRUPTZAEHLER LADEN
	LD	A,7FH		;FUER ENTPRELLEN
	LD	(LAKEY),A	;LETZES ZEICHEN LOESCHEN
	LD	A,0A5H		;CTC 2  INTERRUPT ERLAUBEN
	OUT	CTC2, A		;EI, Zeitgeber, Vorteiler 256, Zeitkonstantenstart, Zeitkonstante folgt
	LD	A,96H		;Zeitkonstante: 2,4576 Mhz / 256 / 96h = 64 Hz
	OUT	CTC2, A
	POP	AF
	EI
	RETI
;
;INTERRUPTROUTINE ZUM TASTATUR ENTPRELLEN/REPEAT - FUNKTION
;wird durch CTC2 aktiv
;
ICTC:	EI
	PUSH	AF
	PUSH	HL
	LD	HL,COUNT
	DEC	(HL)
	JR	Z, ICTC2	;TASTATUR ABFRAGEN
	LD	A,7
	AND	A, (HL)
	JR	NZ, ENDI	;NOCH NICHT WIEDER ABFRAGEN
	INC	HL		;(HL)=ADR. LAKEY
	CALL	DECO		;TASTATUR ABFRAGEN WENN LAKEY <>0
	JR	Z, ENDI		;KEIN GUELTIGER TASTENCODE
	CP	A, (HL)		;VERGLEICH MIT LETZTEM CODE
	JR	Z, ENDI
	DEC	HL
	LD	(HL),40		;NACH 1. ZEICHEN LANGE PAUSE
	JR	ICTC3
ICTC2:	LD	(HL),6		;SCHNELLES REPEAT
	CALL	DECO0		;TASTATUR ABFRAGEN
	JR	Z, ENDI		;KEIN GUELTIGER CODE
ICTC3:	INC	HL
	LD	(HL),A
	LD	A,(KEYBU)
	CP	A, 3		;STOP
	JR	Z, ENDI		;NICHT UEBERSCHREIBEN
	LD	A,(HL)
	LD	(KEYBU),A	;ZEICHEN IN TASTATURPUFFER
ENDI:	POP	HL
	POP	AF
	EI
	RETI

; TASTATURMATRIX
;
; PIO2A, Port 90H
;
;   A0    A1    A2    A3    A4    A5    A6    A7
;   |     |     |     |     |     |     |     |
;  TI0   TI1   TI2   TI3   TI4   TI5   TI6   TI7
;   |     |     |     |     |     |     |     |
; +-----+-----+-----+-----+-----+-----+-----+-----+      PIO2B, Port 91H
; | S11 | S12 | S13 | S14 | S15 | S16 | S17 | S18 |--TO0-B0
; |   0 |   1 |   2 |   3 |   4 |   5 |   6 |   7 |
; +-----+-----+-----+-----+-----+-----+-----+-----+
; | S21 | S22 | S23 | S24 | S25 | S26 | S27 | S28 |--TO1-B1
; |   8 |   9 |   : |   ; |   , |   = |   . |   ? |
; +-----+-----+-----+-----+-----+-----+-----+-----+
; | S31 | S32 | S33 | S34 | S35 | S36 | S37 | S38 |--TO2-B2
; |   @ |   A |   B |   C |   D |   E |   F |   G |
; +-----+-----+-----+-----+-----+-----+-----+-----+
; | S41 | S42 | S43 | S44 | S45 | S46 | S47 | S48 |--TO3-B3
; |   H |   I |   J |   K |   L |   M |   N |   O |
; +-----+-----+-----+-----+-----+-----+-----+-----+
; | S51 | S52 | S53 | S54 | S55 | S56 | S57 | S58 |--TO4-B4
; |   P |   Q |   R |   S |   T |   U |   V |   W |
; +-----+-----+-----+-----+-----+-----+-----+-----+
; | S61 | S62 | S63 | S64 | S65 | S66 | S67 |(S68)|--TO5-B5
; |   X |   Y |   Z | tab |pause| ins |   ^ |     |
; +-----+-----+-----+-----+-----+-----+-----+-----+
; | S71 | S72 | S73 | S74 | S75 | S76 | S77 | S78 |--TO6-B6
; |left |right| down|  up | esc |enter|stop |space|
; +-----+-----+-----+-----+-----+-----+-----+-----+
; | S81 | S82 | S83 | S84 | S85 | S86 | S87 |(S88)|--TO7-B7
; |shift|color|contr|graph|list | run |shlck|     |
; +-----+-----+-----+-----+-----+-----+-----+-----+
;

	IF tastneu = 0

;
;DECODIEREN DER TASTATURMATRIX
DECO:	LD	A,(HL)		;(HL)=ADR. LAKEY
	OR	A
	RET	Z
;
; Funktion: dekodieren Tastaturmatrix
; a) Eingang
; 	- DECOO
; 	gerufen von: ICTC
; b) gerufene Programme
; 	- GPIOD Abfrage Tastatur PIO
; c) Ausgang
; 	-
; d) Return
; 	Parameter: A Zeichen
; 		   Z 1 Fehler
; 		     0 gültig
;
DECO0:	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	HL,ERDEC
	PUSH	HL		;ADR. FUER ENDEBEHANDLUNG
	CALL	GPIOD		;LESEN TASTATUR-PIO
DEC2:	LD	A,D
	OR	A
	RET	Z		;KEIN KONTAKT IN MATRIXZEILE
	LD	A,E
	OR	A
	RET	Z		;KEIN KONTAKT IN MATRIXSPALTE
	LD	A,(SHLOC)
	OR	A
	JR	Z, DEC22	;KEIN SHIFT LOCK
	SET	0,E
	SET	7,D		;BIT WIE BEI SHIFT STELLEN
	RES	7,L
DEC22:	PUSH	HL
	PUSH	DE
;ZEILE DECODIEREN
	LD	E,D
	LD	C,8
	CALL	M0
	LD	H,A
	CALL	M2
	LD	L,A
	POP	DE
	POP	BC
	RET	NZ
;SPALTE DECODIEREN
	PUSH	BC
	LD	C,1
	XOR	A
	CALL	M01
	PUSH	AF
	ADD	A, H
	LD	H,A
	POP	AF
	ADD	A, L
	CP	A, A
	CALL	M2
	LD	L,A
	POP	BC
	RET	NZ
;
	IN	A, DPIO1A	;BIT FUER GRAFIK HOLEN (LED)
	LD	E,A
	LD	A,L
	CP	A, 72
	JR	Z, EINET	;EINZELTASTE
	CP	A, 65
	JR	Z, SHT0
	CP	A, 70
	JR	NZ, SHT1
	LD	A,7DH+44	;INTERNER CODE SHIFT LOCK + 44
;
SHT0:	SUB	44
	LD	L,A
	LD	A,H
	CP	A, 56
	RET	NZ
	LD	A,L
	JP	ER1
SHT1:	CP	A, 64
	JR	Z, ZWEIT	;ZWEI TASTEN
	RET	NC
	SUB	57
	RET	C
	ADD	A, H
	BIT	7,B
	JR	Z, CONTT	;CONTROLTASTE
	LD	BC,90H		;B=0, C=DPIO1A
	LD	H,00000101B
	OUT	(C), H
	INC	C
	IN	H, (C)
	DEC	C
	OUT	(C), B
	BIT	7,H
	RET	Z
	INC	A
SHT2:	CP	A, 12
	JR	C, UCO20
	JR	Z, UCO30
	CP	A, 14
	JR	C, UCO20
	JR	Z, UCO30
	CP	A, 15
	JR	Z, UCO20
	SUB	43
	JR	C, UCO93
	CP	A, 13
	RET	NC
	LD	HL,TAB1		;SONDERTASTEN + SHIFT
	JR	UCOTA
;
CONTT:	DEC	A		;TASTE + CONTROL
CONT2:	SUB	10
	RET	C
	SUB	6
	RET	Z
	JR	NC, CONT3
	CP	A, 0FAH
	JR	NZ, COT22
	SUB	1FH
COT22:	BIT	6,E		;GRAFIK-MODE?
	RET	Z
	SUB	80H
	JR	ENDE
CONT3:	CP	A, 27
	JR	C, ENDE
	CP	A, 30
	RET	NZ
CONT4:	JR	ENDE
;
EINET:	LD	A,H		;EINZELTASTE
	CP	A, 12
	JR	C, UCO30
	JR	Z, UCO20
	CP	A, 14
	JR	C, UCO30
	JR	Z, UCO20
	SUB	43
	JR	C, UCO73
	LD	HL,TAB2		;SONDERTASTEN
	JR	UCOTA
;
ZWEIT:	LD	A,B		;ZWEI TASTEN BETAETIGT
	XOR	C
	CP	A, D
	RET	NZ
	LD	A,3
	AND	A, H
	LD	A,H
	JR	NZ, CONT2
	OR	A
	JR	NZ, SHT2
	LD	A,'_'
	JR	ENDE
;BERECHNEN CODES ALPHA-NUM.-ZEICHEN
UCO93:	ADD	A, 20H
UCO73:	ADD	A, 2BH
UCO30:	ADD	A, 10H
UCO20:	ADD	A, 20H
ENDE:	BIT	6,E		;GRAFIK-MODE?
	JR	Z, ER1
	LD	HL,TABG-1	;GRAFIK-CODES
UCOTA:	LD	B,0
	LD	C,A		;TABELLENOFFSET
	ADD	HL,BC
	LD	A,(HL)
	CP	A, '^'
	JR	Z, ENDE
	CP	A, 5DH
	JR	Z, ENDE
	OR	A
	POP	HL
	JR	NZ, ER2		;GUELTIGER CODE
	LD	A,7FH
	LD	(LAKEY),A	;LOESCHEN
	LD	A,10
	JR	ERDC2
ER1:	POP	HL
ER2:	CP	A, 7EH		;INTERNER CODE GRAFIK
	JR	NZ, ER22
	LD	A,E
	XOR	40H		;GRAFIK-LED EIN/AUS
	OUT	DPIO1A, A
ER21:	XOR	A
	LD	(LAKEY),A	;WAR NUR INTERNE CODIERUNG
	LD	A,40		;LANGE REPEATPAUSE
	JR	ERDC2
ER22:	CP	A, 7DH		;INTERNER CODE SHIFT LOCK
	JR	NZ, ER3
	LD	A,(SHLOC)
	XOR	1		;SHIFT LOCK EIN/AUS
	LD	(SHLOC),A
	JR	ER21
ER3:	POP	BC
	POP	DE
	POP	HL
	CP	A, 5DH
	JR	Z, ER4
	CP	A, 60H
	JR	NZ, ER5
	SUB	21H
ER4:	INC	A
ER5:	OR	A
	RET
;DEKODIERUNGSFEHLER
ERDEC:	LD	A,83H		;PIO UND CTC NEU INIT.
	OUT	SPIOB, A
	XOR	A
	OUT	DPIOA, A
	LD	A,25H
	OUT	CTC2, A
	LD	A,96H
	OUT	CTC2, A
	XOR	A
	LD	(LAKEY),A
ERDC2:	LD	(COUNT),A
	XOR	A
	JR	ER3
;
M0:	LD	A,-9
M01:	LD	B,8
M1:	ADD	A, C
	SRL	E
	RET	C
M2:	DJNZ	M1
	RET	NZ
	ADD	A, C
	CP	A, A
	RET

	ELSE	; tastneu = 1

;
;DECODIEREN DER TASTATURMATRIX
DECO:	LD	A, (HL)		;(HL)=ADR. LAKEY
	OR	A
	RET	Z
DECO0:	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	HL, ERDEC	;DECODIERFEHLER_NEU
	PUSH	HL		;ADR. FUER ENDEBEHANDLUNG
	CALL	GPIOD		;LESEN TASTATUR-PIO
DEC2:	LD	A, D		;D=Zeile
	OR	A
	RET	Z		;KEIN KONTAKT IN MATRIXZEILE
	LD	A, E		;E=Spalte
	OR	A
	RET	Z		;KEIN KONTAKT IN MATRIXSPALTE
	LD	A, H		;H=Control-Taste
	AND	80H
	LD	H, 0C0H
	LD	B, 0FBH
	CALL	MFDE0
	JR	Z, DEC3
	LD	A, L
	AND	80H
	LD	H, 20H
	LD	B, 0FEH
	CALL	MFDE0
	JR	Z, DEC3
	if shlocFlg
	ld	a,(SHLOC)
	else
	IN	A, (DPIO1A)
	endif
	AND	1
	LD	H, 20H
	JR	NZ, DEC3
	LD	H, 0
DEC3:	LD	A, H
	OR	A
	JR	Z, DEC4
	LD	A, D
	AND	7FH
	JR	Z, DEC4
	LD	D, A
DEC4:	XOR	A
	LD	C, 8
	CALL	MFDE9
	RET	NZ
	RET	NC
	SUB	C
	LD	C, 1
	LD	E, D
	CALL	MFDE9
	RET	NZ
	RET	NC
	SUB	C
	LD	C, H
	LD	HL, TAB1	;TABELLE FUER ALLE TASTEN
	LD	D, 0
	LD	E, A
	ADD	HL, DE
	LD	A, (HL)
	CP	40H
	JR	C, MFD9F	;wenn Sondertaste
	ADD	A, C
DEC5:	LD	B, A
	IN	A, (DPIO1A)
	AND	40H		;Grafikmodus?
	JR	Z, DEC6
	SET	7, B		;dann Bit 7 setzen
DEC6:	LD	A, B
DEC7:	POP	BC
DEC8:	POP	BC
	POP	DE
	POP	HL
	OR	A
	RET
; Sondertasten
MFD9F:	BIT	7, C
	RET	NZ
	OR	A
	RET	Z
	CP	3		;STOPTASTE?
	JR	Z, MFDB2
	CP	10H		;SHIFT LOCK?
	JR	Z, MFDC9
	JR	C, DEC7
	CP	11H		;GRAFIK?
	JR	Z, MFDD8
;
MFDB2:	BIT	5, C
	JR	Z, MFDC3
	LD	HL, TAB2	;TABELLE DER SONDERTASTEN
;;	LD	BC, 24		;ANZAHL DER SONDERTASTEN
	LD	BC, 25		;ANZAHL DER SONDERTASTEN 15.08.2018
	CPIR
	RET	NZ
;;	LD	C, 23		;ANZAHL DER SONDERTASTEN - 1
	LD	C, 24		;ANZAHL DER SONDERTASTEN - 1 15.08.2018
	ADD	HL, BC
	LD	A, (HL)
MFDC3:	CP	1AH
	JR	C, DEC7
	JR	DEC5
;SHIFT LOCK
MFDC9:	if shlocFlg
        ld      hl, SHLOC
        ld      a, (hl)
        xor     1
        ld      (hl), a
	else
	IN	A, (DPIO1A)
	XOR	1
	OUT	(DPIO1A), A
	endif
ER21:	XOR	A
	LD	(LAKEY), A	;WAR NUR INTERNE CODIERUNG
	LD	A, 40		;LANGE REPEATPAUSE
	POP	BC
	JR	ERDC2
;GRAFIK
MFDD8:	IN	A, (DPIO1A)	;GRAFIK-LED EIN/AUS
	XOR	40H
	OUT	(DPIO1A), A
	JR	ER21
;
MFDE0:	RET	NZ
	PUSH	AF
	LD	A, E
	AND	B
	JR	Z, MFDE7
	LD	E, A
MFDE7:	POP	AF
	RET
;
MFDE9:	LD	B, 8
MFDEB:	ADD	A, C
	SRL	E
	RET	C
	DJNZ	MFDEB
	RET
; DEKODIERUNGSFEHLER
ERDEC:	LD	A, 83H		;PIO UND CTC NEU INIT
	OUT	(SPIOB), A
	XOR	A
	OUT	(DPIOA), A
	LD	A, 25H
	OUT	(CTC2), A
	LD	A, 96H
	OUT	(CTC2), A
	XOR	A
	LD	(LAKEY), A
ERDC2:	LD	(COUNT), A
	XOR	A
	JR	DEC8

	if rombank
;
;ROM-BANK-ROUTINE
;
ROMBK:	JP	NZ, CP1		;EPROM-BANK
	OUT	(78H), A	;BANK SCHALTEN
	LD	A, (0EC27H)	;BILDSCHIRMZELLE (1. ZEILE, LETZTES ZEICHEN)
;;	INC	A
;;	dec	a
	inc	a		; 15.08.2018
	LD	(0EC27H), A	;WERT ZURUECK
	JP	NZ, CPROM	;SUCHEN KOMMANDO IM SPEICHER
	INC	H
	RET

	endif

	if farb16

;CTRL-A, CTRL-D
CTRLAD:	LD	A, C
	DEC	A		;PRUEFEN CTRL-A
	JR	Z, UMZ		;JA, ZEICHENSATZ UMSCHALTEN
	SUB	3		;PRUEFEN CTRL-D
	JR	Z, UMBL		;UMSCHALTEN INK/BLINK
	DEC	A
	JP	MF8A1		;ZURUECK ZU OCH1

UMBL:
;;	OUT	(70H), A	;SETZEN INK/BLINK-FLIPFLOP
;;	LD	A, (MAPAR+7)	;(FARBRAMZELLE)
;;	BIT	5, A		;SCHWARZ-WEISS?
;;	RES	5, A
;;	JR	NZ, ABSP	;FARBVARIANTE
;;	SET	5, A		;LADEN FARBVARIANTE

        in      a, (DPIO1A)
	xor     1
	out     (DPIO1A), a
	ld      a, (0EFC8h)
	xor     20h 		; Toggle Bit 5

ABSP:	LD	(MAPAR+7), A	;IN DIE FARBRAMZELLE
	LD	A, (ATRIB)
	RES	7, A
	LD	(ATRIB), A
	RET

;;UMZ:	OUT	(74H), A	;UMSCHALTEN ZEICHENSATZ
UMZ:	OUT	(0BBH), A	;UMSCHALTEN ZEICHENSATZ
	RET
	endif

	if farb16
; Unterstützung für 16 Farben, CRT-Treiber (Teil 2):

; FARBBEHANDLUNG INK
INK16:	LD	A, (MAPAR+7)	;FARBRAMZELLE
	BIT	5, A		;FARBE?
	JR	Z, INKNEU
BLINK_:	LD	B, 8FH		;ALTE MASKE
	LD	A, E
	RET
INKNEU:	LD	B, 0FH		;NEUE MASKE
	LD	A, E
	RET
; FARBBEHANDLUNG BORDER
BORD:	LD	B, 0C5H		;NEUE MASKE
	SLA	C
	SLA	C
	SLA	C
	BIT	6, C		;PRUEFEN NEUE FARBE
	JR	Z, MFE64	;KEINE NEUE FARBE
	SET	1, C		;SETZEN FARBBIT NEU
	RES	6, C		;RUECKSETZEN GRAFIK
	RET
MFE64:	RES	1, C		;RUECKSETZEN FARBBIT
	RET
; FARBERWEITERUNG COLOR A-H
FARB16C:
	SUB	31H
	JP	C, CI		; >= 1
	CP	8
	JR	C, MFE77	; <= 8
	SUB	8
	CP	8
	JP	C, CI		; <= H
MFE77:	JP	MF941
; MIAT NEU
MIATN:	LD	C, A
	LD	A, (MAPAR+7)
	BIT	5, A		;PRUEFEN FARBE
	LD	A, C
	JR	Z, I_MIAT
	LD	C, 0
	SLA	A
	JP	MFADA
I_MIAT:	RLCA
	RLCA
	RLCA
	RLCA
	RET
	endif

	org	0FE8Fh
	ENDIF		; tastneu = 1

;
;TASTATUR - PIO ABFRAGEN
GPIOD:	DI
	IN	A, DPIOB
	CPL
	LD	D,A		;NEGIERTE MATRIXZEILE
	LD	A,3
	OUT	SPIOB, A
	LD	A,11111011B	;PRUEFEN CONTROL-TASTE
	OUT	DPIOA, A
	IN	A, DPIOB
	LD	H,A
	LD	A,11111110B	;PRUEFEN SHIFT-TASTE
	OUT	DPIOA, A
	IN	A, DPIOB
	LD	L,A
	LD	A,0CFH
	OUT	SPIOA, A
	LD	A,0FFH
	OUT	SPIOA, A
	LD	A,0CFH
	OUT	SPIOB, A
	XOR	A
	OUT	SPIOB, A
	OUT	DPIOB, A
	IN	A, DPIOA
	CPL
	LD	E,A		;NEGIERTE MATRIXSPALTE
	LD	A,80H		;SPIELHEBEL 1 ABFRAGEN
	OUT	DPIOB, A
	IN	A, DPIOA
	CPL
	LD	(JOYR),A
	LD	A,40H		;SPIELHEBEL 2 ABFRAGEN
	OUT	DPIOB, A
	IN	A, DPIOA
	CPL
	LD	(JOYL),A
	CALL	INITT		;TATSTATUR INIT.
	XOR	A
	OUT	DPIOA, A
	RET
;
	ORG	RESET+0ED6H
;
;*******************************************************************
;*	KASSETTEN - E/A                                            *
;*******************************************************************
;
;SCHREIBEN EINES BLOCKES
;
; Funktion: Schreiben eines Blockes
; a) Eingang
; 	- KARAM
; 	gerufen von: WRIT
; 	Parameter  : DMA  Blockadresse
; 		     BLNR Blocknummer
; 		     BC Anzahl der Vortonzeichen
; b) gerufene Programme
; 	- INIC1 CTC vorinitialialisieren
; 	- INIVT Vorton initialisieren
; 	- AUS1 Ausgabe 1 Bit
; 	- AUST Ausgabe Trennzeichen
; 	- KAUBT Ausgabe 1 Byte
; c) Ausgang
; 	- DYNST  Ausgabe der letzten Halbperiode
; d) Return
;
KARAM:
	DI
	XOR	A
	LD	(PSUM),A
karam0:	CALL	INIC1
	OUT	SPIOB, A	;TASTATUR AUS (A ist 3)
	CALL	INIVT		;VORTON INIT.
KARA1:	CALL	AUS1		;VORTON AUSGEBEN
	CPI
	JP	PE,KARA1	;BC MAL
	CALL	AUST		;TRENNZEICHEN
	LD	A,(BLNR)
	CALL	KAUBT		;BLOCKNUMMER AUSGEBEN
	LD	HL,(DMA)	;BLOCKADRESSE
	LD	B,80H		;ANZAHL BYTES
KARA2:	LD	A,(HL)
	CALL	KAUBT		;AUSGABE DATENBYTE
	LD	A,(PSUM)
	ADD	A, (HL)		;NEUE PRUEFSUMME
	LD	(PSUM),A
	INC	HL
	DJNZ	KARA2
	CALL	KAUBT		;PRUEFSUMME AUSGEBEN
	LD	A,D
	JR	DYNST		;LETZTE HALBPERIODE AUSGEBEN
;
;VORTON INITIALISIEREN
INIVT:	LD	A,85H		;Steuerwort CTC: (EI, Zeitkonstante folgt)
	OUT	CTC0, A		;CTC0
	LD	A,40H		;VORTON 1
	OUT	CTC0, A		;CTC0 Zeitkonstante: 2,4576 Mhz / 16 / 40h = 2400 Hz
	EI
	LD	D,A		;LAENGE HALBPERIODE
	RET
;
;SCHREIBEN EINES BYTES
;
; Funktion:   Ausgabe eines Bytes
; a) Eingang
; 	- KAUBT
; 	gerufen von: KARAM
; 	Parameter  : A Byte
; 		     D Länge Halbperiode vorheriges Bit
; 	- AUST
; 	gerufen von: KARAM
; 	Parameter  : D Länge Halbperiode vorheriges Bit
; 	- AUS1
; 	gerufen von: KARAM
; 	Parameter  : D Länge Halbperiode vorheriges Bit
; b)  gerufene Programme
; 	- AUS1, AUS0 Ausgabe 1 Bit, 0 Bit
; 	- DYNST Warten eine Halbperiode
; c) Ausgang
; 	-
; d) Return
; 	Parameter: D Länge Halbperiode vorheriges Bit
;
KAUBT:	PUSH	BC
	LD	C,A
	LD	B,8
KAUB1:	RRC	C
	PUSH	AF
	CALL	C, AUS1		;1 BIT
	POP	AF
	CALL	NC, AUS0	;0 BIT
	DJNZ	KAUB1
	POP	BC
AUST:	LD	E,80H		;TRENNZEICHEN Zeitkonstante: 2,4576 Mhz / 16 / 80h = 600 Hz
	JR	AUS
AUS0:	LD	E,20H		;0 BIT Zeitkonstante: 2,4576 Mhz / 16 / 20h = 1200 Hz
	JR	AUS
AUS1:	LD	E,40H		;1 BIT Zeitkonstante: 2,4576 Mhz / 16 / 40h = 2400 Hz
AUS:	LD	A,D
	CALL	DYNST		;LETZTE HALBPERIODE NOCH AUSGEB.
	LD	A,D		;1. HALBPERIODE NEUES BIT
DYNST:	LD	(ARB),A
DY1:	LD	A,(ARB)
	OR	A
	JR	NZ, DY1		;WARTEN BIS FLANKE AUSGEGEBEN
	LD	D,E		;LAENGE NEUE HALBPERIODE
	RET
;
;INTERRRUPTROUTINE ZUM SCHREIBEN
;
; Funktion: Interruptroutine Schreiben
; a) Eingang
; 	- IKACT
; 	Parameter: ARB Länge nächste Halbperiode39
; b) gerufene Programme
; 	-
; c) Ausgang
; 	-
; d) Return
; 	Parameter: ARB 0
;
IKACT:	PUSH	AF
	LD	A,3		;Steuerwort CTC (Reset)
	OUT	CTC0, A		;CTC0
	LD	A,85H		;Steuerwort CTC (EI, Zeitkonstante folgt)
	OUT	CTC0, A		;CTC0
	LD	A,(ARB)		;Zeitkonstante holen
	OUT	CTC0, A		;ZAEHLERWERT ENTSPR. ZEICHEN
	XOR	A
	LD	(ARB),A		;Arbeitszelle auf 0 setzen als Fertigmarkierung
	POP	AF
	EI
	RETI
;
;LESEN EINES BLOCKES
;
; Funktion: Lesen eines Blockes
; a) Eingang
; 	- MAREK
; 	gerufen von: RRAND
; 	Parameter  : DMA
; b) gerufene Programme
; 	- INIC1 CTC vorinitialisieren
; 	- LSTOP Warten eine Periode
; 	- LS1 Warten eine Halbperiode41
; 	- IBYTE Lesen eines Bytes
; c) Ausgang
; 	-
; d) Return
; 	Parameter: BLNR Blocknummer
; 		   PSUM Prüfsumme
; 		   CY 0 kein Fehler
; 		      1 Fehler
;
MAREK:
	DI
	CALL	INIC1
MAREK0:	OUT	SPIOB, A	;TASTATUR AUS
	OUT	SPIO1A, A
	LD	A,5
	OUT	CTC0, A		;CTC 0 ZUM ZEIT MESSEN
	LD	A,0B0H		;STARTWERT
	OUT	CTC0, A
	LD	A,0FH
	OUT	SPIO1A, A
	LD	A,0AH		;Interruptvektor 20A -> IKEP
	OUT	SPIO1A, A
	LD	A,0E7H		;SYSTEM PIO INTERRUPT ERLAUBT
	OUT	SPIO1A, A
	EI
MA1:	LD	B,22		;22 VORTOENE SUCHEN
MA2:	CALL	LSTOP		;EIN BIT/TRENNZEICHEN LESEN
	JR	C, MA1		;0 BIT GELESEN
	CP	A, 90H
	JR	C, MA1		;TRENNZEICHEN GELESEN
	DJNZ	MA2
	LD	B,2		;1 TRENNZEICHEN
MA3:	XOR	A
	LD	(PSUM),A
	LD	C,A
	LD	(ARB),A
	CALL	LS1		;EINE HALBPERIODE MESSEN
	CP	A, 52H
	JR	NC, MA3		;KEIN TRENNZEICHEN
	DJNZ	MA3
	CALL	IBYTE		;BLOCKNUMMER LESEN
	RET	C		;FEHLER
	LD	(BLNR),A
	LD	B,80H		;ANZAHL BYTES
	LD	HL,(DMA)	;BLOCKADRESSE
MA4:	CALL	IBYTE		;DATENBYTE LESEN
	RET	C		;FEHLER
	LD	(HL),A
	LD	A,(PSUM)
	ADD	A, (HL)		;NEUE PRUEFSUMME
	LD	(PSUM),A
	INC	HL
	DJNZ	MA4
	CALL	IBYTE		;PRUEFSUMME LESEN
	RET	C		;FEHLER
	LD	B,A
	LD	A,(PSUM)
	CP	A, B
	RET	Z		;IN ORDNUNG
	SCF
	RET			;FEHLER
;
;INTERRUPTROUTINE ZUM LESEN
;
; Funktion:   Interruptroutine lesen
; a) Eingang
; 	- IKEP
; b) gerufene Programme
; 	-
; c) Ausgang
; 	-
; d) Return
; 	Parameter A Länge einer Halbperiode
;
IKEP:	PUSH	AF
	IN	A, CTC0
	PUSH	AF
	LD	A,7
	OUT	CTC0, A
	LD	A,0B0H		;NEUE ZEITMESSUNG
	OUT	CTC0, A		;Startwert
	POP	AF
	LD	(ARB),A		;gemessener Wert
	POP	AF
	EI
	RETI
;
;LESEN EINES ZEICHENS
;
; Funktion: Lesen eines Bits
; a) Eingang
; 	- LSTOP
; 	gerufen von:     MAREK, IBYTE
; 	- LS1
; 	gerufen von:     MAREK
; b) gerufene Programme
; 	-
; c) Ausgang
; 	-
; d) Return
; 	Parameter:  C Länge der Periode
; 		     CY 1             0 Bit
; 		        0 und C < 90H Trennz.
; 		        0 und C >= 90H 1 Bit
;

;Bit	Wert	B0-x	*2	Return
;       KAUBT
;-------------------------------------
;0	20h	90h	120h	Cy=1
;1	40h	70h	E0h	> 90h
;Trennz	80h	30h	60h	< 90h

LSTOP:	XOR	A
	LD	(ARB),A
LS0:	LD	A,(ARB)
	OR	A
	JR	Z, LS0		;WARTEN AUF 1. FLANKE
	LD	C,A
	XOR	A
	LD	(ARB),A
LS1:	LD	A,(ARB)
	OR	A
	JR	Z, LS1		;WARTEN AUF 2. FLANKE
	ADD	A, C
	RET
;
;LESEN EINES BYTES
;
; Funktion: Lesen eines Bytes
; a) Eingang
; 	- IBYTE
; 	gerufen von: MAREK
; b) gerufene Programme
; 	- LSTOP  Lesen eines Bits
; c) Ausgang
; 	-
; d) Return
; 	Parameter: A, E  Byte
; 	           CY 1 Fehler
; 		      0 kein Fehler
;
IBYTE:	LD	D,8
	XOR	A
	LD	E,A
IB1:	CALL	LSTOP		;LESEN EIN ZEICHEN
	CCF
	JR	NC, IB2		;0 BIT
	CP	A, 90H
	RET	C		;TRENNZEICHEN
	SCF			;1 BIT
IB2:	RR	E
	DEC	D
	JR	NZ, IB1
	CALL	LSTOP		;LESEN TRENNZEICHEN
	LD	A,E
	RET
;
	END
