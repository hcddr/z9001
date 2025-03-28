;------------------------------------------------------------------------------
; Z9001 MEGA-FLASH-Modul (2.5M-Modul)
; (c) V. Pohlers 2011
; letzte Änderung 08.01.2013
;------------------------------------------------------------------------------


;megarom			equ	"MEGA"			; A.Schön; 10K Bänke
;megarom			equ	"MEGA8"		; buebchen; 8K Bänke + 2K RAM
megarom			equ	"KOMBI"		; U.Zander; 128 x 16K Bänke, abwechselnd 10k und 6K, Rest von RAM aufgefüllt

;------------------------------------------------------------------------------
; orig. Hardware, 3 ROMs oder 5 ROMs. 10K-Bänke

		if megarom == "MEGA"

; Konfiguration
bankport		equ	0ffh		; Portadresse Modul
systembank		equ	000h		; erste Bank mit Flashsoftware. davor liegende Bänke werden nicht beachtet
						; (wg. Megamodul)
lastbank		equ	0ffh		; letzte zu durchsuchende Bank
;lastbank		equ	07fh		; letzte zu durchsuchende Bank (f. Winbond W29C020)
;27010 128K EPROM = 3fh
;27020 256K EPROM = 7fh
;27040 512K EPROM = ffh

bankstart		equ	0C000h
bankende		equ	0E800h		; +1
blocksize		equ	2800h		; 10K

minicpm			equ	1		; 1 = minicpm mit einbinden
;minicpm			equ	0		; 1 = minicpm mit einbinden
minicpm_disk2		equ	0		; 1 = disk2 (C:) für Mini-CPM mit einbinden

useincport		equ	0
sysbankretrn		equ	1		; nach Laden Systembank aktivieren

;------------------------------------------------------------------------------
; Buebchen-Rx3. Nur 8K-Bänke

		elseif megarom == "MEGA8"

; Konfiguration
bankport		equ	00ah		; Portadresse Modul
systembank		equ	000h		; erste Bank mit Flashsoftware. davor liegende Bänke werden nicht beachtet
						; (wg. Megamodul)
lastbank		equ	0ffh		; letzte zu durchsuchende Bank

bankstart		equ	0C000h
bankende		equ	0E800h		; +1
blocksize		equ	2000h		; 8K

minicpm			equ	0		; 1 = minicpm mit einbinden
minicpm_disk2		equ	0		; 1 = disk2 (C:) für Mini-CPM mit einbinden

useincport		equ	0
sysbankretrn		equ	1		; nach Laden Systembank aktivieren

;------------------------------------------------------------------------------
; Ulrichs ROM-Bank. Abwechselnd 10k und 6k-Bänke

		elseif megarom == "KOMBI"

; Konfiguration
bankport		equ	075h		; Portadresse Modul
bankportinc		equ	078h		; Portadresse Modul weiterschalten
systembank		equ	000h		; erste Bank mit Flashsoftware. davor liegende Bänke werden nicht beachtet
						; (wg. Megamodul)
lastbank		equ	00fh		; letzte zu durchsuchende Bank
;27010 128K EPROM = 128/16*2 = 16 Bänke	0fh
;27020 256K EPROM = 256/16*2 = 32 Bänke	1fh
;27040 512K EPROM = 512/16*2 = 64 Bänke	3fh
;27080 1M EPROM = 1024/16*2 = 128 Bänke	7fh

bankstart		equ	0C000h
bankende		equ	0E800h		; +1	10K
bankende2		equ	0D800h		; +1	6K
blocksize		equ	2800h		; 10K
blocksize2		equ	1800h		; 6K
useincport		equ	1		; Port 78H zum weiterschalten nutzen
sysbankretrn		equ	0		; nach Laden Systembank aktivieren
searchloopdelay		equ	0600h		; f. Warteschleife in cd_cprom4

minicpm			equ	1		; 1 = minicpm mit einbinden
minicpm_disk2		equ	0		; immer 0, wird bei Kombi nicht genutzt

rom_uzander		equ	0		; 1 - softwarezusammenstellung u.zander + ein paar extras

;------------------------------------------------------------------------------

		endif

banksize	equ	bankende-bankstart

; die FLASH-Dateitypen (f. packedroms.asm, addFile)
; Bit 7 = packed
; Bit 6543 = Bank
; Bit 210 Typ 0..7
ft_MC			equ	0
ft_BASIC		equ	1
ft_HELP			equ	2
ft_typ3			equ	3
ft_typ4			equ	4
ft_typ5			equ	5
ft_typ6			equ	6
ft_typ7			equ	7

ft_typmask		equ	00000111b	; Maske für Typ
ft_bankmask		equ	01111000b	; Maske für Bank
;
ft_systembank		equ	15 << 3		; Wert speziell f. systembank reserviert
;;ft_bank0		equ	0 << 3		; 0 wird als default umgesetzt
ft_bank1		equ	1 << 3		; als Offset addieren
ft_bank2		equ	2 << 3
ft_bank3		equ	3 << 3
ft_bank4		equ	4 << 3
ft_bank5		equ	5 << 3
ft_bank6		equ	6 << 3
ft_bank7		equ	7 << 3
ft_bank8		equ	8 << 3
ft_bank9		equ	9 << 3
ft_bank10		equ	10 << 3
ft_bank11		equ	11 << 3
ft_bank12		equ	12 << 3
ft_bank13		equ	13 << 3
ft_bank14		equ	14 << 3
;
ft_packed		equ	1 << 7		; als Offset addieren

; die FLASH-Dateikategorien (f. packedroms.asm, addFile)
; wird in MENU ausgewertet
fk_unknown		equ	0
fk_tools		equ	1
fk_spiele_basic		equ	2
fk_spiele_mc		equ	3
fk_buero		equ	4
fk_programmierung	equ	5
fk_treiber		equ	6
fk_demos		equ	7
fk_cpm			equ	8
; die Werte 9..31 sind noch nicht vergeben
; die Werte 16..31 können individuell genutzt werden
; Bit 5 ist reserviert für zukünftige Erweiterungen
;fk_xxx			equ	1 << 5		; als Offset addieren
fk_shadow		equ	1 << 6		; als Offset addieren	; Shadow-RAM wird vorher zugeschaltet
fk_hidden		equ	1 << 7		; als Offset addieren	; Datei wird bei DIR nicht aufgelistet

;----------------------
;FA-Header
;;	0	2x0FAH, magic marker FlAsH
;;	2	FLASH-Dateityp
;;	3	Name (8 Zeichen)
;;	11	aadr, eadr, sadr
;;	17	länge
;;	19	FLASH-Dateikategorien
;;	20	Kommentar (12 Zeichen)

fa_magic	equ	0			; als Offset addieren
fa_typ		equ	2
fa_name		equ	3
fa_aadr		equ	11
fa_eadr		equ	13
fa_sadr		equ	15
fa_length	equ	17
fa_kategorie	equ	19
fa_comment	equ	20

;------------------------------------------------------------------------------
; Arbeitsspeicher

currbank	equ	0042h		; aktuelle Bank
firstent:	equ	currbank+1	; temp. Zelle f. Menu
DATA:		equ	firstent+1	; Konvertierungsbuffer
ARG1:		equ	DATA+2		; 1. Argument
ARG2:		equ	ARG1+2		; 2. Argument
ARG3:		equ	ARG2+2		; 3. Argument
ARG4:		equ	ARG3+2		; 4. Argument
bkswcode	equ	ARG4+2		; bank switch code 004E-0059
tmpcmd		equ	0110h		; temporärer Programmcode 0110h-01CFh

; Systemerweiterung
syserw		equ	0C025h
syserw_reset	equ	syserw
syserw_cold	equ	syserw+3
syserw_gocpm	equ	syserw+6
nr_lastbank	equ	syserw+9

;------------------------------------------------------------------------------
; Sprungverteiler
rst_sbos	equ	28h		;der RST für den Sprungverteiler

;0 OUTHX	Ausgabe (A) hexa
;1 OUTHL	Ausgabe (HL) hexa
;2 WAIT		Unterbrechung Lauf
;3 color	Vordergrundfarbe (E)
;4 CPROM	Suchen Namen
;5 FMOV		FA-Programm in Speicher kopieren
;6 FRUN		FA-Programm starten
;7 KDOPAR	Kommandoparameter aufbereiten
;8 INHEX	Konvertierung ASCII-Hex ab (DE) --> (HL)
;9 PRST7	Ausgabe String bis Bit7=1
;10 GOCPM	Warmstart
;11 JMPHL	Program starten (nach CPROM)
;12 cp_cdnxbk	Bankumschalt-Code umlagern nach tmpcmd
;13 stopkey	Test, ob <STOP> gedrückt -> Cy=1
;14 cload	Datei laden. in: (fcb), hl, a
;15 csave	Datei speichern. in: (fcb), a
;16 COOUT	Ausgabe ab (HL) (B) Zeichen, nur Buchstaben

;------------------------------------------------------------------------------
;AS-Funktionen
hi              function x,(x>>8)&255
lo              function x, x&255
; bws(zeile 0..23, spalte 0..39) analog print_at
bws		function z,s,z*40+s+0EC00h
bwsc		function z,s,z*40+s+0E800h
