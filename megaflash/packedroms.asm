;------------------------------------------------------------------------------
; Z9001 MEGA-FLASH-Modul (2.5M-Modul)
; (c) V. Pohlers 2011
; letzte Änderung 08.01.2013
;------------------------------------------------------------------------------
; bei Änderungen in dieser Datei unbedingt 'make depend' starten!
;------------------------------------------------------------------------------

        cpu 96C141			; Mikrocontroller mit großem Adressbereich
        maxmode on			; der Z80 reicht hier nicht.

	MACEXP  off

	include	includes.asm
	OUTRADIX 10


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

x_align	function x, (($+x-1)/x)*x
myalign	macro	size
	org	x_align(size)
	endm

myalign2	macro	size
	org	x_align(blocksize+size) - size
	endm

myspace	macro	size
	message	"\{$}, \{size}, \{($ # size)}"
	org	($ + size) - ($ # size)
	endm

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

; MACRO a d d f i l e
;
;addFile filename, aadr, [eadr], [sadr], name, typ, klasse, kommentar
;
;filename mit Pfad
;eadr kann bei ungepackten Daten leer bleiben (dann = aadr+filelength)
;sadr kann leer bleiben (dann = aadr)
;Name = 8 Zeichen; Suchname
;s.a. includes.asm
;typ = Dateityp (ft_MC, ft_BASIC, ft_BASICP; ft_packed als Offset addieren)
;Dateikategorie (fk_unknown, fk_tools, ...), wird für DIR und MENU genutzt
;Kommentar = max. 13 Zeichen, bel., wird für DIR und MENU genutzt
;
;bei TAP-Dateien xxx.tap schreiben -> include	"xxx.bin.inc"
;bei ASM-Dateien xxx.asm schreiben -> addFile	"xxx.bin",sadr,,,"NAME",ft_MC,fk_unknown,""
;für gepackte Version an den Filenamen .zx7 anhängen; an den Dateityp + ft_packed
;make erzeugt aus den TAP-Dateien bzw. ASM-Dateien alle benötigen binären Dateien u.a.

; align	100h verschwendet etwas Speicher, aber ist vermutlich leichter zu handlen

lfdnr	eval	0

addFile	macro	fileXname, aXadr, eXadr, sXadr, pXname, pXtyp, pXklasse, pXComment

lfdnr		eval	lfdnr+1
id		eval	"\{lfdnr}"

		align	100h

	if megarom == "KOMBI"
;; große bank (gerade Nr, blocksize) + kleine Bank (ungerade Nr., blocksize2) = 16K
;; 24.04.2015 die Berechnung stimmte nicht
;;	//  uz: offs in Eprom = bank/2*16K  + (bank mod 2) * 10k
;;	idx = this.megaROMSeg/2 * 0x4000 + this.megaROMSeg%2 * 0x2800;
;;	idx = addr - 0xC000 + idx; 

;nextbankpos: pos/16k + (pos-pos/16k) >= 10k ? 16k : 10k

bank_{id} 	eval 	(($ / (blocksize+blocksize2)) * 2 + systembank) 
pos_{id}	eval 	($ # (blocksize+blocksize2) + bankstart)
	if pos_{id} >= blocksize
bank_{id}	eval bank_{id}+1
pos_{id}	eval pos_{id}-blocksize2
	endif

;;	todo wenn gepackt und länge > freier speicher im block dann org neuer Block

	else
bank_{id} 	equ 	($ / blocksize + systembank)
pos_{id}	equ 	($ # blocksize + bankstart)
	endif

	if	"eXadr"<>""
eadr_{id}	eval	eXadr
	else
eadr_{id}	eval	aXadr+file_bis-file_von
	endif
	if	"sXadr"<>""
sadr_{id}	eval	sXadr
	else
sadr_{id}	eval	aXadr
	endif
	
		; Header
		db	0FAH,0FAH		; 2 magic marker FlAsH
		db	pXtyp			; 1
		db	substr(pXname+"        ",0,8)			; 8
		dw	aXadr, eadr_{id}, sadr_{id}	; 6
		dw	file_bis-file_von	; Länge 2
		db	pXklasse		; 1
		db	substr(pXComment+"             ",0,12)	; 12

		; file
		align	20h			; align könnte entfallen; Header ist 20h lang
file_von
		BINCLUDE  fileXname
file_bis

filename_{id} 	equ 	fileXname
name_{id}	equ	substr(pXname+"        ",0,8)
typ_{id}	equ	pXtyp
klasse_{id}	equ	pXklasse
aadr_{id}	equ	aXadr

		SHARED bank_{id}, pos_{id}, filename_{id}, aadr_{id}, eadr_{id}, sadr_{id}, name_{id}, typ_{id}, klasse_{id}

	; Speichertest
	if megarom == "KOMBI"
	if $ > (lastbank+1) * 8 * 1024
		warning "\{fileXname} passt nicht mehr aufs Modul!"
	endif
	else
	if $ > (lastbank+1) * blocksize
		warning "\{fileXname} passt nicht mehr aufs Modul!"
	endif
	endif


		endm


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; blocksize = 10K = Größe einer Bank

;Systembank
	BINCLUDE "systembank/bank0.bin"

packedCode_start equ $

;------------------------------------------------------------------------------

	if megarom == "MEGA"

;komplette Bänke
	myalign	blocksize
b_basic		equ ($ / blocksize + systembank)
	binclude "vp\basic_16d.bin"			; 16 Farben, korr. CSAVE
	myalign	blocksize
b_basicp	equ ($ / blocksize + systembank)
	binclude "vp\basic_16dp.bin"			; 16 Farben, korr. CSAVE, neues PRINT-AT
	myalign	blocksize
b_basic86	equ ($ / blocksize + systembank)
	binclude "z9001roms\plotter_grafik_600_112.rom"		; orig. BASIC86
	myalign	blocksize
	binclude "z9001roms\edas.rom"	;asm.rom funktioniert nicht (ASM/ROM4 defekt!)
	myalign	blocksize
	binclude "z9001roms\idas.rom"	; in ZM gepatcht, C3 03 F0 -> C3 00 00
	myalign	blocksize
	binclude "z9001roms\r80.rom"
	myalign	blocksize
	binclude "z9001roms\zsid.rom"
	myalign	blocksize
	binclude "z9001roms\bitex.rom"

	shared b_basic, b_basicp, b_basic86

;------------------------------------------------------------------------------

	elseif megarom == "MEGA8"

;komplette Bänke
	myalign	blocksize
b_basic		equ ($ / blocksize + systembank)
	binclude "vp\basic_16d.bin",0,blocksize			; 16 Farben, korr. CSAVE
	myalign	blocksize
b_basicp	equ ($ / blocksize + systembank)
	binclude "vp\basic_16dp.bin",0,blocksize		; 16 Farben, korr. CSAVE, neues PRINT-AT
	myalign	blocksize
b_basic86	equ ($ / blocksize + systembank)
	binclude "z9001roms\plotter_grafik_600_112.rom",0,blocksize		; orig. BASIC86
	myalign	blocksize
	binclude "z9001roms\edas.rom",0,blocksize


; die oberen 2K in einer Extra-Bank
; alles um ein Byte verschoben, damit die OS-RAHMEN nicht gefunden werden
	myalign	blocksize
b_hibanks1	equ ($ / blocksize + systembank)
	db	42
	binclude "vp\basic_16d.bin",blocksize,800h		; 16 Farben, korr. CSAVE
	binclude "vp\basic_16dp.bin",blocksize,800h		; 16 Farben, korr. CSAVE, neues PRINT-AT
	binclude "z9001roms\plotter_grafik_600_112.rom",blocksize,800h		; orig. BASIC86
	binclude "z9001roms\edas.rom",blocksize,800h-1
;

	shared b_basic, b_basicp, b_basic86

	myalign	blocksize
	binclude "z9001roms\idas.rom",0,blocksize	; in ZM gepatcht, C3 03 F0 -> C3 00 00
	myalign	blocksize
	binclude "z9001roms\zsid.rom",0,blocksize
	myalign	blocksize
	binclude "z9001roms\r80.rom"
	myalign	blocksize
	binclude "z9001roms\bitex.rom"


	myalign	blocksize
b_hibanks2	equ ($ / blocksize + systembank)
	db	42
	binclude "z9001roms\idas.rom",blocksize,800h	; in ZM gepatcht, C3 03 F0 -> C3 00 00
	binclude "z9001roms\zsid.rom",blocksize,800h
;

	shared b_hibanks1, b_hibanks2


		endif

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; die einzelnen Files

	if megarom <> "KOMBI"

	myalign	blocksize

;------------------------------------------------------------------------------
;	addFile filename, 				aadr,	[eadr],	[sadr],	name,		typ,			klasse,		kommentar
;------------------------------------------------------------------------------
; Programme VP

	addFile "systembank/menu.bin.zx7",		0300h,	0D20h,	,	"MENU", 	ft_MC+ft_packed+ft_systembank,	fk_tools,	"GEM X"
	include "hlp/system.hlp.bin.inc"

;n.n.	addFile	"vp/eprommer.bin",			300h,	0BA6h,	300h,	"EPROMMER",	ft_MC,			fk_tools,	""
	addFile	"vp/eprommer.bin.zx7",			300h,	0BA6h,	,	"EPROMCCL",	ft_MC+ft_packed,	fk_tools,	"Z1013/buebchen"
	addFile "vp/graf.bin.zx7",			08E60h,	0A7FFh,	0FFFFh,	"GRAF",		ft_MC+ft_packed,	fk_treiber,	"robotron Grafik"
	addFile "vp/graf14.bin.zx7",			08E60h,	0A7FFh,	0FFFFh,	"GRAF14",	ft_MC+ft_packed,	fk_treiber,	"1/4 Grafik"
	addFile "vp/grafp.bin.zx7",			08D60h,	0A7FFh,	0FFFFh,	"GRAFP",	ft_MC+ft_packed,	fk_treiber,	"KRT Grafik"
	addFile "vp/crt40p.bin.zx7",			0B000h,	0BB4Ah,	0B000h,	"CRT40P",	ft_MC+ft_packed,	fk_treiber,	"CRT-Treiber"
	addFile "vp/crt80p.bin.zx7",			0B000h,	0B766h,	0B000h,	"CRT80P",	ft_MC+ft_packed,	fk_treiber,	"CRT-Treiber"
	addFile "vp/globus87_sss.bin.zx7",		0401h,	012E4h,	000h,	"GLOBUS87",	ft_BASIC+ft_packed,	fk_demos,	"+GRAFx"
	addFile "vp/n-eck_sss.bin.zx7",			0401h,	06ECh,	000h,	"N-ECK",	ft_BASIC+ft_packed,	fk_demos,	"+GRAFx"
	addFile "vp/switch_zg.bin.zx7",			08000h,	09037h,	08000h,	"CRT40PZG",	ft_MC+ft_packed,	fk_treiber,	"COM"
	addFile "vp/uhr14_sss.bin.zx7",			0401h,	05F9h,	000h,	"UHR14   ",	ft_BASIC+ft_packed,	fk_demos,	"+GRAF14"
	addFile "vp/uhr_sss.bin.zx7",			0401h,	0696h,	000h,	"UHR",		ft_BASIC+ft_packed,	fk_demos,	"+GRAFx"
	addFile "vp/r+grdemop_sss.bin.zx7",		0401h,	02F68h,	000h,	"R+GRDEMO",	ft_BASIC+ft_packed,	fk_demos,	"+GRAFx"
	addFile "vp/r_grdem2_sss.bin.zx7",		0401h,	02F68h,	000h,	"R+GRDEM2",	ft_BASIC+ft_packed,	fk_demos,	"+GRAFx"

	addFile "vp/ossave.bin.zx7",			0A000h,	0A2ABh,	,	"OS-SAVE",	ft_MC+ft_packed,	fk_tools,	"R0111"
	addfile	"vp/emonas32.bin.zx7",			03200h,	,	,	"EMON32",	ft_MC+ft_bank1+ft_packed,fk_tools,	"EMON"
	addfile	"vp/emonas.bin.zx7",			0b200h,	,	,	"EMONB2",	ft_MC+ft_bank1+ft_packed,fk_tools,	"EMON 2 RAMs"
	addfile	"vp/bootmodl.bin.zx7",			0400h,	,	,	"BOOT",		ft_MC+ft_packed,	fk_cpm,		"boot robotron"
	addfile	"vp/boot_zfk.bin.zx7",			0400h,	,	,	"BOOTZFK",	ft_MC+ft_packed,	fk_cpm,		"boot rossendorf"
	addfile	"vp/epson.bin.zx7",			0A400H,	,	,	"EPSON",	ft_MC+ft_packed,	fk_treiber,	""
	addfile	"vp/kc_caos.bin.zx7",			08000H,	,	,	"KC-CAOS",	ft_MC+ft_Bank1+ft_packed,fk_tools,	""
;	addfile	"vp/sdx.bin",				0Bc00h,	,	,	"SDX",		ft_MC,			fk_tools,	"SD Kingstener"
;	addfile	"vp/sdx3f.bin",				03f00h,	,	,	"SDX3F",	ft_MC,			fk_tools,	"SD Kingstener"
	addfile	"vp/treiber_sammlung.bin.zx7",		0300h	,	,0538h,	"TR_SAMML",	ft_MC+ft_Packed,	fk_treiber,	"mp 10/87"
;	include	"vp/f83a4_com.bin.inc"
	addFile "vp/f83a4_com.bin.zx7",			0300h,	03A94h,	0300h,	"F83A4",	ft_MC+ft_packed,	fk_programmierung,"COM"
	addFile "vp/fdtest18os.bin.zx7",		04000h,	051D0h,	04000h,	"FDTEST18",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "vp/gd_com.bin.zx7",			06E00h,	07FFFh,	06E00h,	"GDRUCK",	ft_MC+ft_packed,	fk_treiber,	"COM"
	addFile "vp/k6313m_com.bin.zx7",		0B600h,	0BEFFh,	0B600h,	"K6313G1",	ft_MC+ft_packed,	fk_treiber,	"K6313G1 m"
	addFile "vp/ramtest.bin.zx7",			0300h,	0A04h,	0300h,	"RAMTEST",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "vp/sm_com.bin.zx7",			0B600h,	0BE47h,	0B600h,	"S3004O",	ft_MC+ft_packed,	fk_treiber,	"COM"
	addFile "vp/tester.bin.zx7",			0A000h,	0AFFFh,	0A000h,	"TESTER",	ft_MC+ft_packed,	fk_tools,	"DebuggerIHM"
	addFile "vp/testpara.bin.zx7",			0300h,	03BDh,	0300h,	"TESTPARA",	ft_MC+ft_packed,	fk_tools,	""

	addFile "vp/ftest13.rom.zx7",			08000h,	08627h,	08000h,	"FTEST13",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "robotron2/lpro16.rom.zx7",		08800h,	09BA7h,	08800h,	"LPRO",		ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "robotron2/test-12_com.bin.zx7",	03000h,	03200h,	0ffffh,	"TEST1213",	ft_MC+ft_packed,	fk_tools,	"COM"

	addfile	"vp/banktest.bin.zx7",			01000H,	,	,	"BANKTEST",	ft_MC+ft_packed,	fk_tools,	"A.S."

	addfile	"vp/chkrom.bin",			00300H,	,	,	"CHKROM",	ft_MC,	fk_tools,	"Selbsttest"
	addfile	"vp/chkrom2.bin",			00300H,	,	,	"CHKROM2",	ft_MC,	fk_tools,	"Selbsttest"

	include "hlp/f83.hlp.bin.inc"
	include "hlp/krt.hlp.bin.inc"
	include "hlp/save.hlp.bin.inc"

	addfile	"systembank/crc.bin.zx7",		300h,	,	,	"CRC",		ft_MC+ft_packed+ft_systembank,	fk_tools,	"CRC SDLC"
	addFile	"vp/SM-vp.bin.zx7",			0B600h,	,	,	"S3004",	ft_MC+ft_packed,	fk_treiber,	"S3004-VP"
	addFile "vp/sysinfo.bin.zx7", 			0300h, 01FFFh, 0300h, 	"SYSINFO ", 	ft_MC+ft_packed+ft_systembank, 	fk_tools, 	"vp"

	addFile "vp/crt40.bin.zx7",			0B000h,	0BB4Ah,	0B000h,	"CRT40",	ft_MC+ft_packed,	fk_treiber,	"CRT-Treiber"

	addFile "vp/device.bin.zx7",			00300h,	0051Fh,	00300h,	"DEVICE",	ft_MC+ft_packed,	fk_treiber,	"ASGN+IO"
	
	addFile "vp/word.bin.zx7",			00300h, 017FFh, 0300h,	"WORD",		ft_MC+ft_packed,	fk_buero,	"MicroWORD"
;05.02.2021
	addFile "vp/paintbox.bin.zx7",			04000h, 05DFFh, 04359h,	"PAINTBOX",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "vp/blocks.bin.zx7",			00300h,	,	,	"BLOCKS",	ft_MC+ft_packed,	fk_spiele_mc,	"unpackme"
	addFile "vp/schieb.bin.zx7",			00300h,	,	,	"SCHIEB",	ft_MC+ft_packed,	fk_spiele_mc,	"unpackme"
	
;------------------------------------------------------------------------------
;robotron-Kassetten
;die Zeilen sind enstanden durch tap2bin.pl (erzeut xxx.inc)
;an den Filenamen wurde .zx7 angehängt; an den Dateityp + ft_packed (für gepackte Version)
;und es wurden manuell Kategorie und Kommentar geändert

;n.n. = nicht nötig,	da schon im ROM drin

	addFile "robotron/basic_com.bin.zx7",		0300h,	02AFFh,	02400h,	"RAMBASIC",	ft_MC+ft_packed,	fk_programmierung,"R0111"
	addFile "robotron/r+remosa_sss.bin.zx7",	0401h,	01084h,	000h,	"R+REMOSA",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0111"

;;n.n.	addFile "robotron/eprom2a_com.bin.zx7",		02A00h,	02DA1h,	02A00h,	"EPROM2A",	ft_MC+ft_packed,	fk_tools,	"R0112"
;;n.n.	addFile "robotron/eprom6a_com.bin.zx7",		06A00h,	06DA1h,	06A00h,	"EPROM6A",	ft_MC+ft_packed,	fk_tools,	"R0112"
;;n.n.	addFile "robotron/eproma2_com.bin.zx7",		0A200h,	0A5A1h,	0A200h,	"EPROMA2",	ft_MC+ft_packed,	fk_tools,	"R0112"
	addFile "robotron/r+demo1_sss.bin.zx7",		0401h,	03B5Bh,	000h,	"R+DEMO1 ",	ft_BASIC+ft_packed,	fk_demos,	"R0112"
	addFile "robotron/r+demo2_sss.bin.zx7",		0401h,	03CBBh,	000h,	"R+DEMO2 ",	ft_BASIC+ft_packed,	fk_demos,	"R0112"
	addFile "robotron/r+demo3_sss.bin.zx7",		0401h,	033C5h,	000h,	"R+DEMO3 ",	ft_BASIC+ft_packed,	fk_demos,	"R0112"
;;	addFile "robotron/zm30_com.bin.zx7",		03000h,	03FFFh,	03000h,	"ZM30",		ft_MC+ft_packed,	fk_tools,	"R0112"

	addFile "vp/zm20a_3000.bin.zx7", 03000h, 03DEBh, 03000h, "ZM30", ft_MC+ft_packed, fk_tools, "V2.0A"
	addFile "vp/zm20a_A800.bin.zx7", 0A800h, 0B5EBh, 0A800h, "ZMA8", ft_MC+ft_packed, fk_tools, "V2.0A"

	addFile "robotron/r+hanoi_sss.bin.zx7",		0401h,	0E77h,	000h,	"R+HANOI ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0112"

	addFile "robotron/sprache1_com.bin.zx7",	06000h,	06E8Fh,	06000h,	"SPRACHE1",	ft_MC+ft_packed,	fk_treiber,	"R0113"
	addFile "robotron/sprache2_com.bin.zx7",	09800h,	0A68Fh,	09800h,	"SPRACHE2",	ft_MC+ft_packed,	fk_treiber,	"R0113"

	addFile "robotron/grplot_com.bin.zx7",		09800h,	0A7FFh,	0FFFFh,	"GRPLOT",	ft_MC+ft_packed,	fk_treiber,	"R0114"
	addFile "robotron/r+pldemo_sss.bin.zx7",	0401h,	02F5Ch,	000h,	"R+PLDEMO",	ft_BASIC+ft_packed,	fk_demos,	"R0114"

;;n.n.	addFile "robotron/inscript_com.bin.zx7",	0400h,	05341h,	0400h,	"INSCRIPT",	ft_MC+ft_packed,	fk_buero,	"R0115"
	addFile "robotron/script_com.bin.zx7",		0400h,	033FAh,	031D1h,	"SCRIPT",	ft_MC+ft_packed,	fk_buero,	"R0115"
	addFile "robotron/k6311g1_com.bin.zx7",		0B600h,	0BEFFh,	0B600h,	"K6311G1",	ft_MC+ft_packed,	fk_treiber,	"R0115"
	addFile "robotron/k6313g1_com.bin.zx7",		0B600h,	0BEFFh,	0B600h,	"K6313G1",	ft_MC+ft_packed,	fk_treiber,	"R0115"

;;n.n.	addFile "robotron/asm_com.bin.zx7",		01000h,	037FFh,	0FFFFh,	"EDAS",		ft_MC+ft_packed,	fk_programmierung,"R0121"
;;n.n.	addFile "robotron/zm70_com.bin.zx7",		07000h,	07CDAh,	07000h,	"ZM70",		ft_MC+ft_packed,	fk_tools,	"R0121"
;;n.n.	addFile "robotron/zma8_com.bin.zx7",		0A800h,	0B4DAh,	0A800h,	"ZMA8",		ft_MC+ft_packed,	fk_tools,	"R0121"

;;n.n.	addFile "robotron/idas_com.bin.zx7",		0400h,	01C00h,	0400h,	"RAMIDAS",	ft_MC+ft_packed,	fk_programmierung,"R0122"

	addFile "robotron/r+gauss_www.bin.zx7",		0401h,	0114Dh,	000h,	"R+GAUSS ",	ft_BASIC+ft_packed,	fk_buero,	"R0133"
	addFile "robotron/r+fplot_sss.bin.zx7",		0401h,	01451h,	000h,	"R+FPLOT ",	ft_BASIC+ft_packed,	fk_buero,	"R0133"
	addFile "robotron/r+mat_sss.bin.zx7",		0401h,	0C87h,	000h,	"R+MAT   ",	ft_BASIC+ft_packed,	fk_buero,	"R0133"
	addFile "robotron/r+plot_sss.bin.zx7",		0401h,	0CC7h,	000h,	"R+PLOT  ",	ft_BASIC+ft_packed,	fk_buero,	"R0133"
	addFile "robotron/r+sort_sss.bin.zx7",		0401h,	0F4Eh,	000h,	"R+SORT  ",	ft_BASIC+ft_packed,	fk_buero,	"R0133"

	addFile "robotron/text1_com.bin.zx7",		0700h,	03016h,	0700h,	"TEXT1",	ft_MC+ft_packed,	fk_buero,	"R0136"
;;txt	addFile "robotron/textdoku_txt.bin.zx7",	03014h,	04642h,	0FFFFh,	"TEXTDOKU",	ft_??+ft_packed,	fk_buero,	"R0136"

	addFile "robotron/r+clust_sss.bin.zx7",		0401h,	03843h,	000h,	"R+CLUST ",	ft_BASIC+ft_packed,	fk_buero,	"R0137"
	addFile "robotron/r+ktest_sss.bin.zx7",		0401h,	02601h,	000h,	"R+KTEST ",	ft_BASIC+ft_packed,	fk_buero,	"R0137"
	addFile "robotron/r+zufall_sss.bin.zx7",	0401h,	02572h,	000h,	"R+ZUFALL",	ft_BASIC+ft_packed,	fk_buero,	"R0137"
;;	addFile "robotron/r+zufallp_sss.bin.zx7",	0401h,	0B7Ch,	000h,	"R+ZUFALL",	ft_BASIC+ft_packed,	fk_buero,	"R0137"
	addFile "robotron/r+varana_sss.bin.zx7",	0401h,	032B8h,	000h,	"R+VARANA",	ft_BASIC+ft_packed,	fk_buero,	"R0137"

	addFile "robotron/r+afri1_sss.bin.zx7",		0401h,	03902h,	000h,	"R+AFRI1 ",	ft_BASIC+ft_packed,	fk_buero,	"R0145"
	addFile "robotron/r+flae1_sss.bin.zx7",		0401h,	014FAh,	000h,	"R+FLAE1 ",	ft_BASIC+ft_packed,	fk_buero,	"R0145"
	addFile "robotron/r+flae2_sss.bin.zx7",		0401h,	01D11h,	000h,	"R+FLAE2 ",	ft_BASIC+ft_packed,	fk_buero,	"R0145"
	addFile "robotron/r+mathex_sss.bin.zx7",	0401h,	01364h,	000h,	"R+MATHEX",	ft_BASIC+ft_packed,	fk_buero,	"R0145"
	addFile "robotron/r+mosaik_sss.bin.zx7",	0401h,	02BDEh,	000h,	"R+MOSAIK",	ft_BASIC+ft_packed,	fk_buero,	"R0145"

	addFile "robotron/r+lingen_sss.bin.zx7",	0401h,	027BCh,	000h,	"R+LINGEN",	ft_BASIC+ft_packed,	fk_buero,	"R0152"
	addFile "robotron/r+linreg_sss.bin.zx7",	0401h,	0275Dh,	000h,	"R+LINREG",	ft_BASIC+ft_packed,	fk_buero,	"R0152"
	addFile "robotron/r+linsym_www.bin.zx7",	0401h,	027E5h,	000h,	"R+LINSYM",	ft_BASIC+ft_packed,	fk_buero,	"R0152"

	addFile "robotron/r+funknu_sss.bin.zx7",	0401h,	0248Ch,	000h,	"R+FUNKNU",	ft_BASIC+ft_packed,	fk_buero,	"R0153"
	addFile "robotron/r+nlreg_sss.bin.zx7",		0401h,	02614h,	000h,	"R+NLREG ",	ft_BASIC+ft_packed,	fk_buero,	"R0153"
	addFile "robotron/r+polynu_sss.bin.zx7",	0401h,	01E6Ah,	000h,	"R+POLYNU",	ft_BASIC+ft_packed,	fk_buero,	"R0153"

	addFile "robotron/r+master_sss.bin.zx7",	0401h,	01423h,	000h,	"R+MASTER",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"
	addFile "robotron/r+mond_sss.bin.zx7",		0401h,	014C2h,	000h,	"R+MOND  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"
	addFile "robotron/r+nim_sss.bin.zx7",		0401h,	0155Fh,	000h,	"R+NIM   ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"
	addFile "robotron/r+othelo_sss.bin.zx7",	0401h,	01322h,	000h,	"R+OTHELO",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"
	addFile "robotron/r+skeet_sss.bin.zx7",		0401h,	0126Bh,	000h,	"R+SKEET ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"

	addFile "robotron/r+autocr_www.bin.zx7",	0401h,	014C2h,	000h,	"R+AUTOCR",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0166"
	addFile "robotron/r+halma_www.bin.zx7",		0401h,	01459h,	000h,	"R+HALMA ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0166"
	addFile "robotron/r+trumpf_www.bin.zx7",	0401h,	013BBh,	000h,	"R+TRUMPF",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0166"
	addFile "robotron/r+worte_www.bin.zx7",		0401h,	0136Bh,	000h,	"R+WORTE ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0166"
	addFile "robotron/r+ziele_www.bin.zx7",		0401h,	0F22h,	000h,	"R+ZIELE ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0166"

	addFile "robotron/r+grekal_sss.bin.zx7",	0401h,	013EFh,	000h,	"R+GREKAL",	ft_BASIC+ft_packed,	fk_buero,	"R0191"
	addFile "robotron/r+info_sss.bin.zx7",		0401h,	014F1h,	000h,	"R+INFO  ",	ft_BASIC+ft_packed,	fk_demos,	"R0191"
	addFile "robotron/r+memory_sss.bin.zx7",	0401h,	018EFh,	000h,	"R+MEMORY",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0191"
	addFile "robotron/r+morset_sss.bin.zx7",	0401h,	02018h,	000h,	"R+MORSET",	ft_BASIC+ft_packed,	fk_buero,	"R0191"
	addFile "robotron/r+pasch_sss.bin.zx7",		0401h,	01353h,	000h,	"R+PASCH ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0191"
	addFile "robotron/r+perdat_sss.bin.zx7",	0401h,	016E7h,	000h,	"R+PERDAT",	ft_BASIC+ft_packed,	fk_buero,	"R0191"

	addFile "robotron/r+budget_sss.bin.zx7",	0401h,	02CE0h,	000h,	"R+BUDGET",	ft_BASIC+ft_packed,	fk_buero,	"R0192"
	addFile "robotron/r+flohsp_sss.bin.zx7",	0401h,	016E3h,	000h,	"R+FLOHSP",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0192"
	addFile "robotron/r+hobbit_sss.bin.zx7",	0401h,	017EDh,	000h,	"R+HOBBIT",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0192"
	addFile "robotron/r+slalom_sss.bin.zx7",	0401h,	01574h,	000h,	"R+SLALOM",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0192"
	addFile "robotron/r+tbverz_sss.bin.zx7",	0401h,	0211Bh,	000h,	"R+TBVERZ",	ft_BASIC+ft_packed,	fk_buero,	"R0192"

	addFile "robotron/r+bruch1_sss.bin.zx7",	0401h,	0216Ah,	000h,	"R+BRUCH1",	ft_BASIC+ft_packed,	fk_buero,	"R0193"
	addFile "robotron/r+bruch2_sss.bin.zx7",	0401h,	03B9Ch,	000h,	"R+BRUCH2",	ft_BASIC+ft_packed,	fk_buero,	"R0193"
	addFile "robotron/r+graphm_sss.bin.zx7",	0401h,	01647h,	000h,	"R+GRAPHM",	ft_BASIC+ft_packed,	fk_buero,	"R0193"
	addFile "robotron/r+kin1_sss.bin.zx7",		0401h,	043E3h,	000h,	"R+KIN1  ",	ft_BASIC+ft_packed,	fk_buero,	"R0193"
	addFile "robotron/r+kin2_sss.bin.zx7",		0401h,	02BB0h,	000h,	"R+KIN2  ",	ft_BASIC+ft_packed,	fk_buero,	"R0193"
	addFile "robotron/r+si_sss.bin.zx7",		0401h,	03B66h,	000h,	"R+SI    ",	ft_BASIC+ft_packed,	fk_buero,	"R0193"
	addFile "robotron/r+vokale_sss.bin.zx7",	0401h,	0165Ch,	000h,	"R+VOKALE",	ft_BASIC+ft_packed,	fk_buero,	"R0193"

	; V24A1..A3-ROM
;	addFile "z9001roms/bm116.rom.zx7",		0b800h,	,	0ffffh,	"V24",		ft_MC+ft_packed,	fk_treiber,	"BM116.ROM"
	addFile "vp/bm116.bin.zx7",			0a800h,	,	0ffffh,	"V24",		ft_MC+ft_packed,	fk_treiber,	"BM116.ROM"

	include "hlp/zm.hlp.bin.inc"
	include "hlp/idas.hlp.bin.inc"
	include "hlp/edit.hlp.bin.inc"
	include "hlp/asm.hlp.bin.inc"

;------------------------------------------------------------------------------
;robotron2	von Robotron, aber nicht vertrieben
	addFile "robotron2/boalab_sss.bin.zx7",		0401h,	011B2h,	000h,	"BOALABYR",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/boalab2_sss.bin.zx7", 	0401h, 	011B2h, 000h, 	"BOALAB2 ", 	ft_BASIC+ft_packed, 	fk_unknown, 	"robotron"
	addFile "robotron2/catlab_sss.bin.zx7",		0401h,	012DEh,	000h,	"X+CATLAB",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/centip_sss.bin.zx7",		0401h,	01D2Dh,	000h,	"CENTIPED",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/comodore_com.bin.zx7",	0400h,	0B96h,	0400h,	"COMODORE",	ft_MC+ft_packed,	fk_unknown,	"robotron"
	addFile "robotron2/gammon_sss.bin.zx7",		0401h,	02A9Ch,	000h,	"K+GAMMON",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
;;	addFile "robotron2/histo_sss.bin.zx7",		0401h,	03BDBh,	000h,	"R+HISTO1",	ft_BASIC+ft_packed,	fk_buero,	"robotron"
	addFile "robotron2/history1_sss.bin.zx7",	0401h,	03C70h,	000h,	"R+HISTO1",	ft_BASIC+ft_packed,	fk_buero,	"robotron"
	addFile "robotron2/history2_sss.bin.zx7",	0401h,	03700h,	000h,	"R+HISTO2",	ft_BASIC+ft_packed,	fk_buero,	"robotron"
	addFile "robotron2/history4_sss.bin.zx7",	0401h,	0391Bh,	000h,	"R+HISTO4",	ft_BASIC+ft_packed,	fk_buero,	"robotron"
	addFile "robotron2/maus_sss.bin.zx7",		0401h,	02044h,	000h,	"S+MAULAB",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
;;	addFile "robotron2/mazogs_sss.bin.zx7",		0401h,	03C5Fh,	000h,	"MAZOGS  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "uz/mazogs.bin.zx7",		0401h,	04027h,	000h,	"MAZOGS  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron/uz"
	addFile "robotron2/messe_sss.bin.zx7",		0401h,	02871h,	000h,	"R+MESSE2",	ft_BASIC+ft_packed,	fk_demos,	"robotron"
	addFile "robotron2/newenter_sss.bin.zx7",	0401h,	02FA5h,	000h,	"ENTERPRI",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/othellom_com.bin.zx7",	0400h,	0B59h,	0400h,	"OTHELLOM",	ft_MC+ft_packed,	fk_spiele_mc,	"robotron"
	addFile "robotron2/pong_sss.bin.zx7",		0401h,	013D3h,	000h,	"K+PONG",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/prognose_sss.bin.zx7",	0401h,	0159Bh,	000h,	"PROGNOSE",	ft_BASIC+ft_packed,	fk_unknown,	"robotron"
	addFile "robotron2/r80kor_com.bin.zx7",		0400h,	02A00h,	0400h,	"R80KOR",	ft_MC+ft_packed,	fk_programmierung,"robotron"
	addFile "robotron2/r80_com.bin.zx7",		0400h,	02A00h,	0400h,	"R80",		ft_MC+ft_packed,	fk_programmierung,"robotron"
	addFile "robotron2/recher_sss.bin.zx7",		0401h,	02D2Bh,	000h,	"R+RECH",	ft_BASIC+ft_packed,	fk_unknown,	"robotron"
	addFile "robotron2/reversi_sss.bin.zx7",	0401h,	01174h,	000h,	"REVERSI ",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/spiedi_sss.bin.zx7",		0401h,	01528h,	000h,	"K+SPIEDI",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/tatum_sss.bin.zx7",		0401h,	06AB8h,	000h,	"TATUM   ",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"

	addFile	"vp/renew.bin.zx7",			0a200h,	,	,	"RENEW",	ft_MC+ft_packed,	fk_tools,	"robotron"

;------------------------------------------------------------------------------
; 14.02.2012 CP/M
	addFile "cpm/cpml.bin.zx7",			0300h,	,	,	"CPM",		ft_MC+ft_packed+ft_systembank,	fk_cpm,	"CP/M-Loader"
	addFile "cpm/cpm_r.rom.zx7",			08000h-80h,,	0ffffh,	"CPM-R",	ft_MC+ft_packed,	fk_cpm+fk_hidden,""
	addFile "cpm/cpm_zfk.rom.zx7",			08000h-80h,,	0ffffh,	"CPM-ZFK",	ft_MC+ft_packed,	fk_cpm+fk_hidden,""
	addFile "cpm/cpm-48k.rom.zx7",			04000h-80h,,	0ffffh,	"CPM-48K",	ft_MC+ft_packed,	fk_cpm+fk_hidden,""
	include "hlp/cpm.hlp.bin.inc"
	addFile "cpm/initkc.bin.zx7",			03000h,	,	,	"INITKC",	ft_MC+ft_packed,	fk_tools,	""


; 20.02.2012 DISK-OS
	addFile "cpm/call5dbg.bin",			07000h,	,	,	"CALL5DBG",	ft_MC+ft_systembank,			fk_tools,	""
	addFile "diskos/diskos.bin.zx7",		04000h,	,	,	"DOSX",		ft_MC+ft_packed,	fk_tools+fk_shadow,"DISK OS"
	addFile "diskos/diskos_noshadow.bin.zx7",	04000h,	,	,	"DOS4",		ft_MC+ft_packed,	fk_tools,	"DISK OS"
	include "hlp/dos.hlp.bin.inc"

; 25.04.2016 USB-VDIP
	addFile "diskos/usbos.bin.zx7",			0b600h,	,	,	"USBX",		ft_MC+ft_packed,	fk_tools,	"VDIP USB OS"
	include "hlp/usb.hlp.bin.inc"

;------------------------------------------------------------------------------
;soft1
	addFile "soft1/autorenn.bin.zx7",		0220h,	05300h,	04771h,	"AUTORENN",	ft_MC+ft_bank1+ft_packed,	fk_spiele_mc,	""
	addFile "soft1/bergwerk.bin.zx7",		07D0h,	037DEh,	02416h,	"BERGWERK",	ft_MC+ft_packed,	fk_spiele_mc,	""
	addFile "soft1/bit87com.bin.zx7",		0300h,	0197Fh,	0500h,	"BITEX87",	ft_MC+ft_packed,	fk_buero,	"COM"
	addFile "soft1/bitex5_c.bin.zx7",		0210h,	01D5Fh,	0524h,	"BITEX5",	ft_MC+ft_packed,	fk_buero,	"COM"
	addFile "soft1/bolero.bin.zx7",			0300h,	0976h,	0300h,	"BOLERO",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "soft1/chicken.bin.zx7",		03500h,	04820h,	03525h,	"CHICKEN",	ft_MC+ft_packed,	fk_spiele_mc,	""
	addFile "soft1/copx_com.bin.zx7",		01C00h,	02048h,	01C00h,	"COPX",		ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "soft1/copy3_1.bin.zx7",		0300h,	06F2h,	0300h,	"COPY3/1",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "soft1/copy4_3.bin.zx7",		0300h,	05C0h,	0300h,	"COPY4/3",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "soft1/cosd_com.bin.zx7",		0300h,	02CFFh,	0300h,	"COSD",		ft_MC+ft_packed,	fk_programmierung,"COM"
	addFile "soft1/i_grafik.bin.zx7",		0400h,	0230Fh,	0400h,	"I+GRAFIK",	ft_MC+ft_packed,	fk_unknown,	"COM"
	addFile "soft1/messdemo_sss.bin.zx7",		0401h,	06766h,	000h,	"MESSDEMO",	ft_BASIC+ft_packed,	fk_demos,	""
	addFile "soft1/movie.bin.zx7",			0400h,	0DD9h,	0400h,	"MOVIE",	ft_MC+ft_packed,	fk_demos,	"COM"
	addFile "soft1/space.bin.zx7",			0400h,	04100h,	0400h,	"SPACE",	ft_MC+ft_packed,	fk_spiele_mc,	""
	addFile "soft1/xybasic.bin.zx7",		01100h,	04630h,	01100h,	"XYBASIC",	ft_MC+ft_packed,	fk_programmierung,"COM"

;------------------------------------------------------------------------------
;soft2

	addFile "soft2-vp/4play_sss.bin.zx7",		0401h,	0146Eh,	000h,	"PLAY4   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/alpine_sss.bin.zx7",		0401h,	020ECh,	000h,	"ALPINE  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/alzan_sss.bin.zx7",		0401h,	02778h,	000h,	"ALZAN   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/atom_sss.bin.zx7",		0401h,	02AA1h,	000h,	"ATOM    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/ausbruch_sss.bin.zx7",	0401h,	01F98h,	000h,	"AUSBRUCH",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/auto1_sss.bin.zx7",		0401h,	0BACh,	000h,	"AUTO1   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/baelle_sss.bin.zx7",		0401h,	01C5Ch,	000h,	"BAELLE  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/beatles_sss_neu.bin.zx7",	0401h,	0296Eh,	000h,	"BEATLES ",	ft_BASIC+ft_packed,	fk_demos,	""
	addFile "soft2-vp/biokomp_sss.bin.zx7",		0401h,	01D49h,	000h,	"BIOKOMP ",	ft_BASIC+ft_packed,	fk_buero,	""
;;	addFile "soft2-vp/boalab_sss.bin.zx7",		0401h,	01094h,	000h,	"BOALAB  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/boerse_sss.bin.zx7",		0401h,	02D43h,	000h,	"BOERSE  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/bohne_sss.bin.zx7",		0401h,	015EDh,	000h,	"BOHNE   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/cave_sss.bin.zx7",		0401h,	01E1Dh,	000h,	"CAVE    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""

	addFile "soft2-vp/chess.bin.zx7",		1000h,	043FFh,	1100h,	"CHESS    ",	ft_MC+ft_packed,	fk_spiele_mc, "VCM KC85"

;;	addFile "soft2-vp/centip_sss.bin.zx7",		0401h,	01D2Dh,	000h,	"CENTIP  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/climber_sss.bin.zx7",		0401h,	02B74h,	000h,	"CLIMBER ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/dyna-l_sss.bin.zx7",		0401h,	0160Ah,	000h,	"DYNA-L  ",	ft_BASIC+ft_packed,	fk_buero,	""
	addFile "soft2-vp/Ebasic_com.bin.zx7",		0300h,	047FFh,	0300h,	"EBASIC",	ft_MC+ft_packed,	fk_programmierung,"COM"
	addFile "soft2-vp/eliza-d_sss.bin.zx7",		0401h,	011EDh,	000h,	"ELIZA-D ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/floor_sss.bin.zx7",		0401h,	02BA2h,	000h,	"FLOOR   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/forth_com.bin.zx7",		0300h,	01E1Ah,	030Ch,	"FORTH",	ft_MC+ft_packed,	fk_programmierung,"COM"
;	addFile "soft2-vp/galgen_sss.bin.zx7",		0401h,	0A71h,	000h,	"GALGEN  ",	ft_BASIC+ft_packed,	fk_unknown,	""
;ttt	addFile "soft2-vp/galgen_ttt.bin.zx7",		0B0Ah,	0BFF6h,	0E0Dh,	"ÔÔÔGALGE",	ft_MC+ft_packed,	fk_unknown,	"N  "
	addFile "soft2-vp/galopp_sss.bin.zx7",		0401h,	0159Ah,	000h,	"GALOPP  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/ganymed_sss.bin.zx7",		0401h,	01999h,	000h,	"GANYMED ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/geister_sss.bin.zx7",		0401h,	01545h,	000h,	"GEISTER ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/geo_1_sss.bin.zx7",		0401h,	01404h,	000h,	"GEO1   ",	ft_BASIC+ft_packed,	fk_buero,	""
	addFile "soft2-vp/handelsf_sss.bin.zx7",	0401h,	03686h,	000h,	"HANDELSF",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/helen_sss.bin.zx7",		0401h,	01A39h,	000h,	"HELEN   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/help87_sss.bin.zx7",		0401h,	0862h,	000h,	"HELP87  ",	ft_BASIC+ft_packed,	fk_tools,	""
	addFile "soft2-vp/jaeger90_sss.bin.zx7",	0401h,	025DCh,	000h,	"JAEGER90",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/kaefer_sss.bin.zx7",		0401h,	01578h,	000h,	"KAEFER  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/kaiser_sss.bin.zx7",		0401h,	030D7h,	000h,	"KAISER  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/kalender_sss.bin.zx7",	0401h,	06EEh,	000h,	"KALENDER",	ft_BASIC+ft_packed,	fk_buero,	""
	addFile "soft2-vp/kcpascal_com.bin.zx7",	027Fh,	02F2Fh,	0100Ch,	"PASCAL",	ft_MC+ft_packed,	fk_programmierung,"KCPascal 2.1"
	addFile "soft2-vp/knossos2_sss.bin.zx7",	0401h,	023E1h,	000h,	"KNOSSOS2",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/KNOSSOS_SSS.bin.zx7",		0401h,	01E74h,	000h,	"KNOSSOS ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/KUNGFU_SSS.bin.zx7",		0401h,	02756h,	000h,	"KUNGFU  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/ladderii_sss.bin.zx7",	0401h,	017C6h,	000h,	"LADDERII",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/ladder_sss.bin.zx7",		0401h,	03C4Bh,	000h,	"LADDER  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/leiter-2_sss.bin.zx7",	0401h,	0FE7h,	000h,	"LEITER-2",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/life_sss.bin.zx7",		0401h,	0CE8h,	000h,	"LIFE    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/M1_COM.bin.zx7",		0A500h,	0BFEBh,	0AB09h,	"M1",		ft_MC+ft_packed+ft_bank1,fk_tools,	"COM"
	addFile "soft2-vp/manager_sss.bin.zx7",		0401h,	05EE3h,	000h,	"MANAGER ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/mann_sss.bin.zx7",		0401h,	0B5Eh,	000h,	"MANN    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/mauer_sss.bin.zx7",		0401h,	0BADh,	000h,	"MAUER   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
;;robotron	addFile "soft2-vp/mazogs_sss.bin.zx7",		0401h,	03CCFh,	000h,	"MAZOGS  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/meteor_sss.bin.zx7",		0401h,	0660h,	000h,	"METEOR  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/mine_sss.bin.zx7",		0401h,	01184h,	000h,	"MINE    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/mintex_sss.bin.zx7",		0401h,	0B20h,	000h,	"MINTEX  ",	ft_BASIC+ft_packed,	fk_buero,	""
	addFile "soft2-vp/music_sss.bin.zx7",		0401h,	0614h,	000h,	"MUSIC   ",	ft_BASIC+ft_packed,	fk_demos,	""
	addFile "soft2-vp/musik_sss.bin.zx7",		0401h,	0C77h,	000h,	"MUSIK   ",	ft_BASIC+ft_packed,	fk_demos,	""
	addFile "soft2-vp/nibbler_sss.bin.zx7",		0401h,	012F3h,	000h,	"NIBBLER ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/othello_sss.bin.zx7",		0401h,	01322h,	000h,	"OTHELLO ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/packman_com.bin.zx7",		01000h,	01B00h,	01000h,	"PACKMAN",	ft_MC+ft_packed,	fk_spiele_mc,	"COM"
	addFile "soft2-vp/paravia_sss.bin.zx7",		0401h,	03224h,	000h,	"PARAVIA ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
;fkt. nicht!	addFile "soft2-vp/PERSEUS.bin.zx7",	0300h,	018FFh,	0411h,	"PERSEUS",	ft_MC+ft_packed,	fk_spiele_basic,"COM"
	addFile "soft2-vp/pferd_sss.bin.zx7",		0401h,	01003h,	000h,	"PFERD   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/pyramide_sss.bin.zx7",	0401h,	02D7Eh,	000h,	"PYRAMIDE",	ft_BASIC+ft_packed,	fk_spiele_basic,""
;;n.n.	addFile "soft2-vp/pyramide_sss_neu.bin.zx7",	0401h,	02D7Bh,	000h,	"PYRAMIDE",	ft_BASIC+ft_packed,	fk_unknown,	""
	addFile "soft2-vp/radier_sss.bin.zx7",		0401h,	0716h,	000h,	"RADIER  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/ralley_sss.bin.zx7",		0401h,	02C31h,	000h,	"RALLEY  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/rechnen_sss.bin.zx7",		0401h,	08C6h,	000h,	"RECHNEN ",	ft_BASIC+ft_packed,	fk_buero,	""
	addFile "soft2-vp/schatz_sss.bin.zx7",		0401h,	032F8h,	000h,	"SCHATZ  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/schild_sss.bin.zx7",		0401h,	0A4Eh,	000h,	"SCHILD  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/SEDEMO1_SSS.bin.zx7",		0401h,	0C45h,	000h,	"SE-DEMO1",	ft_BASIC+ft_packed,	fk_demos,	""
	addFile "soft2-vp/sirene_sss.bin.zx7",		0401h,	0614h,	000h,	"SIRENE  ",	ft_BASIC+ft_packed,	fk_demos,	""
	addFile "soft2-vp/skat_sss.bin.zx7",		0401h,	029BDh,	000h,	"SKAT    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/snake_sss.bin.zx7",		0401h,	01408h,	000h,	"SNAKE   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/sound2_sss.bin.zx7",		0401h,	0F97h,	000h,	"SOUND2  ",	ft_BASIC+ft_packed,	fk_demos,	""
	addFile "soft2-vp/sound_sss.bin.zx7",		0401h,	0148Ah,	000h,	"SOUND   ",	ft_BASIC+ft_packed,	fk_demos,	""
	addFile "soft2-vp/SP-TAFEL_SSS.bin.zx7",	0401h,	0D37h,	000h,	"SP-TAFEL",	ft_BASIC+ft_packed,	fk_demos,	""
	addFile "soft2-vp/sq_sss.bin.zx7",		0401h,	0231Ah,	000h,	"SQ      ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/startrek_sss.bin.zx7",	0401h,	0277Fh,	000h,	"STARTREK",	ft_BASIC+ft_packed,	fk_spiele_basic,""
;;n.n.	addFile "soft2-vp/tatum_sss.bin.zx7",		0401h,	06A77h,	000h,	"TATUM   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/taxi_sss.bin.zx7",		0401h,	0150Bh,	000h,	"TAXI    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/TURBO.bin.zx7",		020Ch,	01608h,	0400h,	"TURBO",	ft_MC+ft_packed,	fk_tools,	"S. Huth"
	addFile "soft2-vp/tennis_sss.bin.zx7",		0401h,	08B7h,	000h,	"TENNIS  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/tictac_sss.bin.zx7",		0401h,	0EA4h,	000h,	"TICTAC  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/treffer_sss.bin.zx7",		0401h,	0E9Dh,	000h,	"TREFFER ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/ufo-town_sss.bin.zx7",	0401h,	01831h,	000h,	"UFO-TOWN",	ft_BASIC+ft_packed,	fk_spiele_basic,""
;;	addFile "soft2-vp/URS2_skat_sss.bin.zx7",	0401h,	02A6Dh,	000h,	"URS 2   ",	ft_BASIC+ft_packed,	fk_unknown,	""
	addFile "soft2-vp/v-spiele2_sss.bin.zx7",	0401h,	0230Bh,	000h,	"V-SPIEL2",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/v-spiele_sss.bin.zx7",	0401h,	031D3h,	000h,	"V-SPIELE",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/v24k6313_com.bin.zx7",	0BA00h,	0BC00h,	0BA0Ah,	"V24K6313",	ft_MC+ft_packed,	fk_treiber,	"COM"
	addFile "soft2-vp/wobugor_com.bin.zx7",		07300h,	07FE9h,	0FFFFh,	"WOBUGOR",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "soft2-vp/wuerfeln_sss.bin.zx7",	0401h,	0A11h,	000h,	"WUERFELN",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/yahtzee_sss.bin.zx7",		0401h,	02176h,	000h,	"YAHTZEE ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/zwinger_sss.bin.zx7",		0401h,	06A4h,	000h,	"ZWINGER ",	ft_BASIC+ft_packed,	fk_demos,	""

;------------------------------------------------------------------------------
;P. Weigoldt  http://home.tiscali.de/petwe/kc.html

	;if	lastbank > 7fh

	addFile "weigoldt/conan.bin.zx7",		0401h,	0772Bh,	000h,	"W+CONAN   ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/connard.bin.zx7",		0401h,	0709Ch,	000h,	"W+CONNARD ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/datum.bin.zx7",		0401h,	086Ah,	000h,	"W+DATUM   ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/flipper.bin.zx7",		0401h,	01E88h,	000h,	"W+FLIPPER ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/hybo.bin.zx7",		0401h,	07947h,	000h,	"W+HYBO    ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/jagd.bin.zx7",		0401h,	0D33h,	000h,	"W+JAGD    ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/life.bin.zx7",		0401h,	0E99h,	000h,	"W+LIFE    ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/mond.bin.zx7",		0401h,	01146h,	000h,	"W+MOND    ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/mosaik.bin.zx7",		0401h,	0697h,	000h,	"W+MOSAIK  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/musik.bin.zx7",		0401h,	0BC1h,	000h,	"W+MUSIK   ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/othello.bin.zx7",		0401h,	01CE8h,	000h,	"W+OTHELLO ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/pascal.bin.zx7",		0401h,	06A7h,	000h,	"W+PASCAL  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/printex.bin.zx7",		0401h,	01415h,	000h,	"W+PRINTEX ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/puzzle.bin.zx7",		0401h,	0DFEh,	000h,	"W+PUZZLE  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/simulife.bin.zx7",		0401h,	07B9h,	000h,	"W+SIMULIFE",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/spiele1.bin.zx7",		0401h,	058E0h,	000h,	"W+SPIELE1 ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/test.bin.zx7",		0401h,	08B2h,	000h,	"W+TEST    ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/tharntis.bin.zx7",		0401h,	0779Fh,	000h,	"W+THARNTIS",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/tranai.bin.zx7",		0401h,	012BDh,	000h,	"W+TRANAI  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/u-boot.bin.zx7",		0401h,	011EEh,	000h,	"W+UBOOT  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"
	addFile "weigoldt/xx.bin.zx7",			0401h,	060Ah,	000h,	"W+XX      ",	ft_BASIC+ft_packed,	fk_spiele_basic,"Weigoldt"

	;endif

;------------------------------------------------------------------------------

	addFile "soft3/kcpascal.rom.zx7",		04000h,	,	,	"KCPASCAL",	ft_MC+ft_packed,	fk_programmierung,"Turbo-Pascal"
;;	addfile	"systembank/flash.bin",			01000h,	,	,	"FLASH",	ft_MC,			fk_unknown,	""
	addFile "soft3/perseus_pre.bin.zx7",		0300h,	0193Fh,	1900h,	"PERSEUS",	ft_MC+ft_packed,	fk_spiele_mc,	"COM"
	addFile "soft3/v24g_com.bin.zx7",		0BB00h,	0BFB8h,	0BB00h,	"V24G",		ft_MC+ft_packed,	fk_treiber,	"COM"

	addFile "soft3/bac87_sss.bin.zx7",		0401h, 01E87h, 000h,	"BAC87   ",	ft_BASIC+ft_packed,	fk_programmierung,"basicode"
	addFile "soft3/bac87c_sss.bin.zx7",		0401h, 020BFh, 000h,	"BAC87C   ",	ft_BASIC+ft_packed,	fk_programmierung,"basicode"

;05.01.2016 buggy.tap, hexi.tap einbinden
	;include "soft3/buggy.bin.inc"
	;addFile "soft3/buggy.bin", 01000h, 027FFh, 01000h, "BUGGY", ft_MC, fk_unknown, "COM"
	addFile "soft3/buggy.bin.zx7", 01000h, 027FFh, 01000h, "BUGGY", ft_MC+ft_packed, fk_spiele_mc, "Schlenzig"
	addFile "soft3/hexi.bin.zx7", 03C00h, 03FBFh, 03C00h, "HEXI", ft_MC+ft_packed, fk_tools, "Schlenzig"

;------------------------------------------------------------------------------

; soft4

	if	lastbank > 7fh

	addFile "soft4/b66_sss.bin.zx7", 		0401h, 02281h, 000h, 	"B66     ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/barrels_sss.bin.zx7", 		0401h, 01749h, 000h, 	"BARRELS ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/billiard_sss.bin.zx7",		0401h, 02A8Ah, 000h, 	"BILLIARD", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/czmuehle_sss.bin", 		0401h, 01F3Bh, 000h, 	"CZMUEHLE", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/dame_sss.bin.zx7", 		0401h, 019E3h, 000h, 	"DAME    ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/halma_sss.bin.zx7", 		0401h, 01459h, 000h, 	"HALMA   ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/helikopt_sss.bin.zx7", 		0401h, 027C0h, 000h, 	"HELIKOPT", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/lady_sss.bin.zx7", 		0401h, 03071h, 000h, 	"LADY    ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/lskeet_www.bin.zx7", 		0401h, 037EDh, 000h, 	"LSKEET  ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/melkli_sss.bin.zx7", 		0401h, 01507h, 000h, 	"MELKLI  ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/musik20_sss.bin.zx7", 		0401h, 032A1h, 000h, 	"MUSIK20 ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/musikmix_sss.bin.zx7", 		0401h, 0C62h, 000h, 	"MUSIKMIX", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/orgel_sss.bin.zx7", 		0401h, 012FBh, 000h, 	"ORGEL   ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/sound_sss.bin.zx7", 		0401h, 01A04h, 000h, 	"SOUND3  ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/sumaria_sss.bin.zx7", 		0401h, 01130h, 000h, 	"SUMARIA ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/werkesa_sss.bin.zx7", 		0401h, 022E5h, 000h, 	"WERKESA ", 	ft_BASIC+ft_packed, 		fk_unknown, ""
	addFile "soft4/z90-demo_sss.bin.zx7", 		0401h, 01D6Ch, 000h, 	"Z90-DEMO", 	ft_BASIC+ft_packed, 		fk_unknown, ""

;todo: Vergleichen mit soft-mega, ...

;------------------------------------------------------------------------------

; soft5 - rekonstruiert aus Mega-Modul

	addFile "soft5/17_4_sss.bin.zx7", 		0401h, 0211Eh, 000h, 	"K17_4   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
;;	addFile "soft5/6AUS49-3.bin.zx7", 		0401h, 04F3h, 000h, 	"6AUS49-3", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/a-z_sss.bin.zx7", 		0401h, 0B2Bh, 000h, 	"A-Z     ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/abfahrt_sss.bin.zx7", 		0401h, 0B3Eh, 000h, 	"ABFAHRT ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/alkohol_sss.bin.zx7", 		0401h, 03730h, 000h, 	"ALKOHOL ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/ampel_sss.bin.zx7", 		0401h, 0F5Eh, 000h, 	"AMPEL   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/angeln_sss.bin.zx7", 		0401h, 0CB6h, 000h, 	"ANGELN  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/angeln2_sss.bin.zx7", 		0401h, 0BE8h, 000h, 	"ANGELN2 ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/apollo_sss.bin.zx7", 		0401h, 03E7Bh, 000h,	"APOLLO  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/arith_com.bin.zx7", 		02100h, 02A7Fh, 02100h, "ARITH", 	ft_MC+ft_packed, 		fk_unknown, "COM"
	addFile "soft5/ballon_sss.bin.zx7", 		0401h, 0BB1h, 000h, 	"BALLON  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/barrels_sss.bin.zx7", 		0401h, 017BCh, 000h, 	"BARRELS ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/beatles_sss.bin.zx7", 		0401h, 0324Bh, 000h, 	"BEATLES ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/bild1_sss.bin.zx7", 		0401h, 0150Ah, 000h, 	"BILD1   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/bild2_sss.bin.zx7", 		0401h, 01680h, 000h, 	"BILD2   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/bild3_sss.bin.zx7", 		0401h, 018D2h, 000h, 	"BILD3   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/bild_sss.bin.zx7", 		0401h, 0151Eh, 000h, 	"BILD    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/blackho_sss.bin.zx7",		0401h, 022D0h, 000h, 	"BLACKHO ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/bohne_sss.bin.zx7", 		0401h, 0163Dh, 000h, 	"BOHNE   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/c-dur_sss.bin.zx7", 		0401h, 0C2Ch, 000h, 	"C-DUR   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/casino_sss.bin.zx7", 		0401h, 013F6h, 000h, 	"CASINO  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/cave2_sss.bin.zx7", 		0401h, 015EDh, 000h, 	"CAVE2   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/chaos_sss.bin.zx7", 		0401h, 01217h, 000h, 	"CHAOS   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/chaos2_sss.bin.zx7", 		0401h, 0122Dh, 000h, 	"CHAOS2  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/city_sss.bin.zx7", 		0401h, 013BCh, 000h, 	"CITY    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/climber2_sss.bin.zx7", 		0401h, 025BBh, 000h, 	"CLIMBER2", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/code_sss.bin.zx7", 		0401h, 0C57h, 000h, 	"CODE    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/coingame_sss.bin.zx7", 		0401h, 0BF7h, 000h, 	"COINGAME", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/comp-ta_sss.bin.zx7", 		0401h, 023F5h, 000h, 	"COMP-TA ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/crazy_sss.bin.zx7", 		0401h, 01B69h, 000h, 	"CRAZY   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/dame_sss.bin.zx7", 		0401h, 01A7Dh, 000h, 	"DAME    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/disk22_sss.bin.zx7", 		0401h, 01CB3h, 000h, 	"DISK22  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/domino_sss.bin.zx7", 		0401h, 06CBh, 000h, 	"DOMINO  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/dragon_sss.bin.zx7", 		0401h, 033DCh, 000h, 	"DRAGON  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/enter_sss.bin.zx7", 		0401h, 043BCh, 000h, 	"ENTER   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/fabas_ss_sss.bin.zx7", 		0401h, 0C01h, 000h, 	"FABAS_SS", 	ft_BASIC+ft_packed, 		fk_buero, ""
	addFile "soft5/falle_sss.bin.zx7", 		0401h, 0BE3h, 000h, 	"FALLE   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/fire_sss.bin.zx7", 		0401h, 01595h, 000h, 	"FIRE    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/fkt4_sss_sss.bin.zx7", 		0401h, 014D1h, 000h, 	"FKT4_SSS", 	ft_BASIC+ft_packed, 		fk_buero, ""
	addFile "soft5/flaggen_sss.bin.zx7", 		0401h, 0327Fh, 000h, 	"FLAGGEN ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/fleiss_sss.bin.zx7", 		0401h, 0126Bh, 000h, 	"FLEISS  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/flipper_sss.bin.zx7", 		0401h, 01664h, 000h, 	"FLIPPER ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/flyer_sss.bin.zx7", 		0401h, 02642h, 000h, 	"FLYER   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/formel1_sss.bin.zx7", 		0401h, 02536h, 000h, 	"FORMEL1 ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/formel1B_sss.bin.zx7", 		0401h, 0FFCh, 000h, 	"FORMEL1B", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/game_sss.bin.zx7", 		0401h, 0A00h, 000h, 	"GAME    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/garten_sss.bin.zx7", 		0401h, 01049h, 000h, 	"GARTEN  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/gasse_sss.bin.zx7", 		0401h, 0B40h, 000h, 	"GASSE   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/ghost_sss.bin.zx7", 		0401h, 01A6Eh, 000h, 	"GHOST   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/hellsehn_sss.bin.zx7", 		0401h, 09E2h, 000h, 	"HELLSEHN", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/historie_sss.bin.zx7", 		0401h, 015F5h, 000h, 	"HISTORIE", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/hit_sss.bin.zx7", 		0401h, 017A7h, 000h, 	"HIT     ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/hubi_sss.bin.zx7", 		0401h, 021FFh, 000h, 	"HUBI    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/hupfli_sss.bin.zx7", 		0401h, 01CA3h, 000h, 	"HUPFLI  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/invasion_sss.bin.zx7", 		0401h, 0EFFh, 000h, 	"INVASION", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/jagd_sss.bin.zx7", 		0401h, 0AD1h, 000h, 	"JAGD    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/jagd2_sss.bin.zx7", 		0401h, 0AF0h, 000h, 	"JAGD2   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/kamikaze_sss.bin.zx7", 		0401h, 02156h, 000h, 	"KAMIKAZE", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/katze_sss.bin.zx7", 		0401h, 012FCh, 000h, 	"KATZE   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/kc-hilfe_sss.bin.zx7", 		0401h, 03E43h, 000h, 	"KC-HILFE", 	ft_BASIC+ft_packed, 		fk_demos, ""
	addFile "soft5/kc87info_sss.bin.zx7", 		0401h, 02CAFh, 000h, 	"KC87INFO", 	ft_BASIC+ft_packed, 		fk_demos, ""
	addFile "soft5/keeps_sss.bin.zx7", 		0401h, 022D2h, 000h, 	"KEEPS   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/komba_ss_sss.bin.zx7", 		0401h, 0E25h, 000h, 	"KOMBA_SS", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/lambada_sss.bin.zx7", 		0401h, 092Eh, 000h, 	"LAMBADA ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/leben_sss.bin.zx7", 		0401h, 01962h, 000h, 	"LEBEN   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/leben2_sss.bin.zx7", 		0401h, 015A8h, 000h, 	"LEBEN2  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/leiter_sss.bin.zx7", 		0401h, 0ABBh, 000h, 	"LEITER  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/lido_sss.bin.zx7", 		0401h, 011A9h, 000h, 	"LIDO    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/life_sss.bin.zx7", 		0401h, 0D5Bh, 000h, 	"LIFE    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/lmet_sss.bin.zx7", 		0401h, 069Eh, 000h, 	"LMET    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/lodr_.bin.zx7", 			01C00h, 0B8FEh, 01C00h, "LODR", 	ft_MC+ft_packed,		fk_spiele_basic, ""
	addFile "soft5/ls_sss.bin.zx7", 		0401h, 0163Ah, 000h, 	"LS      ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/lspiel_sss.bin.zx7", 		0401h, 02031h, 000h, 	"LSPIEL  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/mau_sss.bin.zx7", 		0401h, 01392h, 000h, 	"MAU     ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/mauer_sss.bin.zx7", 		0401h, 01210h, 000h, 	"MAUER   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/maus_sss.bin.zx7", 		0401h, 015B9h, 000h, 	"MAUS    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
;;robotron	addFile "soft5/mazogs_sss.bin.zx7", 		0401h, 03CD2h, 000h, 	"MAZOGS  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/mist20_sss.bin.zx7", 		0401h, 01A37h, 000h, 	"MIST20  ", 	ft_BASIC+ft_packed, 		fk_demos, ""
	addFile "soft5/mondland_sss.bin.zx7",		0401h, 02CF4h, 000h, 	"MONDLAND", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/monopoly_sss.bin.zx7",		0401h, 03544h, 000h, 	"MONOPOLY", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/monster_sss.bin.zx7", 		0401h, 0179Ah, 000h, 	"MONSTER ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/muehle_sss.bin.zx7", 		0401h, 0113Ch, 000h, 	"MUEHLE  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/musi1-87_sss.bin.zx7", 		0401h, 01B92h, 000h, 	"MUSI1-87", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/name2_sss.bin.zx7", 		0401h, 049Bh, 000h, 	"NAME2   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/orbit_sss.bin.zx7", 		0401h, 01A0Eh, 000h, 	"ORBIT   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/othello2_sss.bin.zx7", 		0401h, 0237Fh, 000h, 	"OTHELLO2", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/p1_sss.bin.zx7", 		0401h, 04C3Fh, 000h, 	"P1      ", 	ft_BASIC+ft_packed, 		fk_demos, ""
	addFile "soft5/p2_sss.bin.zx7", 		0401h, 06187h, 000h, 	"P2      ", 	ft_BASIC+ft_packed, 		fk_demos, ""
	addFile "soft5/p3_sss.bin.zx7", 		0401h, 037D2h, 000h, 	"P3      ", 	ft_BASIC+ft_packed, 		fk_demos, ""
	addFile "soft5/p4_sss.bin.zx7", 		0401h, 05BA2h, 000h, 	"P4      ", 	ft_BASIC+ft_packed, 		fk_demos, ""
	addFile "soft5/poker_sss.bin.zx7", 		0401h, 03585h, 000h, 	"POKER   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/pyramide_sss.bin.zx7", 		0401h, 02E16h, 000h,	"PYRAMIDE", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/quiz_sss.bin.zx7", 		0401h, 01565h, 000h, 	"QUIZ    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/racer_sss.bin.zx7", 		0401h, 03A64h, 000h, 	"RACER   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/raetsel_sss.bin.zx7", 		0401h, 014FAh, 000h, 	"RAETSEL ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/rallye_sss.bin.zx7", 		0401h, 0820h, 000h, 	"RALLYE  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/raumflug_sss.bin.zx7", 		0401h, 01A83h, 000h, 	"RAUMFLUG", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/roboter_sss.bin.zx7", 		0401h, 0100Bh, 000h, 	"ROBOTER ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/roulette_sss.bin.zx7", 		0401h, 01690h, 000h, 	"ROULETTE", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/ruebe_sss.bin.zx7", 		0401h, 012B2h, 000h, 	"RUEBE   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/rumpi_sss.bin.zx7", 		0401h, 0675Ah, 000h, 	"RUMPI   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/saturn_sss.bin.zx7", 		0401h, 0160Eh, 000h, 	"SATURN  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/satz_sss.bin.zx7", 		0401h, 011E6h, 000h, 	"SATZ    ", 	ft_BASIC+ft_packed, 		fk_buero, ""
	addFile "soft5/simu_sss.bin.zx7", 		0401h, 01CB3h, 000h, 	"SIMU    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/skandal_sss.bin.zx7", 		0401h, 02E3Eh, 000h, 	"SKANDAL ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/skeet2_sss.bin.zx7", 		0401h, 0383Eh, 000h, 	"SKEET2  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/ski_sss.bin.zx7", 		0401h, 022FFh, 000h, 	"SKI     ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/skorps_sss.bin.zx7", 		0401h, 0BEBh, 000h, 	"SKORPS  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/smugle_sss.bin.zx7", 		0401h, 010E3h, 000h, 	"SMUGLE  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/snake2_sss.bin.zx7", 		0401h, 014B2h, 000h, 	"SNAKE2  ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/space_sss.bin.zx7", 		0401h, 027C5h, 000h, 	"SPACE   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/sport_sss.bin.zx7", 		0401h, 03239h, 000h, 	"SPORT   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/sq_sss.bin.zx7", 		0401h, 0238Dh, 000h, 	"SQ      ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/strasse_sss.bin.zx7", 		0401h, 01DAAh, 000h, 	"STRASSE ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/sumeria_sss.bin.zx7", 		0401h, 012D9h, 000h, 	"SUMERIA ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/tatum_sss.bin.zx7", 		0401h, 06B24h, 000h, 	"TATUM   ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/test_sss.bin.zx7", 		0401h, 014A5h, 000h, 	"TEST    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/tier_sss.bin.zx7", 		0401h, 0E3Bh, 000h, 	"TIER    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/treffer_sss.bin.zx7", 		0401h, 0F10h, 000h, 	"TREFFER ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/typ_att3_sss.bin.zx7", 		0401h, 0E25h, 000h, 	"TYP_ATT3", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/ufo-town_sss.bin.zx7", 		0401h, 018A4h, 000h, 	"UFO-TOWN", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/ufo2_sss.bin.zx7", 		0401h, 010E9h, 000h, 	"UFO2    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/ufo_sss.bin.zx7", 		0401h, 02A26h, 000h, 	"UFO     ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/vier_sss.bin.zx7", 		0401h, 014C7h, 000h, 	"VIER    ", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/wilddieb_sss.bin.zx7", 		0401h, 0169Fh, 000h, 	"WILDDIEB", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/zahl_com_sss.bin.zx7", 		0401h, 05CFBh, 000h, 	"ZAHL_COM", 	ft_BASIC+ft_packed, 		fk_spiele_basic, ""
	addFile "soft5/zmb_com.bin.zx7", 		03800h, 03FFFh, 03800h, "ZMB", 		ft_MC+ft_packed,		fk_tools, ""

	endif	; lastbank > 7fh

;------------------------------------------------------------------------------

	addFile "soft6/prettyC.bin.zx7", 		0300h, 0BFFFh, 0BD00h, "PRETTYC", 		ft_MC+ft_packed+ft_systembank,		fk_programmierung,"Dr.Wobst"
	include "hlp/prettyc.hlp.bin.inc"

;------------------------------------------------------------------------------
; Mini-CPM

	if minicpm

	myalign	blocksize
cpmCode equ $
cpmBank	equ $/blocksize
	binclude	"cpm/minicpm.bin"
	SHARED cpmBank, cpmCode

	myalign	blocksize
disk1_dump_start
cpmBank1	equ $/blocksize


	if lastbank = 0ffh
	binclude 	"minicpm/diskvp1.dmp"
	else
	binclude 	"minicpm/diskvp3.dmp"
	endif
	SHARED disk1_dump_start, cpmBank1

	if	minicpm_disk2

	myalign	blocksize

; disk2 passt nicht mehr komplett drauf, aber diese ist nur bis 20800 gefüllt.
	include	"minicpm/diskvp2.dmp.asm"
freeromsize 	equ 280000h - $ - disk2filledsize
	message	"Free ROM SIZE \{freeromsize}"
	if $ +  disk2filledsize > 280000h
		error "CP/M-Disk2 passt nicht mehr aufs Modul!"
	endif

disk2_dump_start
cpmBank2	equ $/blocksize
	binclude 	"minicpm/diskvp2.dmp"

	SHARED disk2_dump_start, cpmBank2
	endif
	endif



;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
	elseif megarom == "KOMBI"
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
;------------------------------------------------------------------------------
; die geraden Bänke sind 10k groß.

	if	lastbank = 0fh
	; nur 16 Bänke, davon 10 für minicpm

	org	02800h	; bank 1 
	binclude "z9001roms\idas.rom",0,017FFh		; in ZM gepatcht, C3 03 F0 -> C3 00 00

	org	04000h  ; bank 2 
b_basic		equ	2	; Banknummer
	binclude "vp\basic_16d.bin"			; 16 Farben, korr. CSAVE
	
	org	06800h  ; bank 3 
	include "hlp/system.hlp.bin.inc"
	include "hlp/idas.hlp.bin.inc"
	include "hlp/zm.hlp.bin.inc"
	addFile "diskos/usbos.bin.zx7",			0b600h,	,	,	"USBX",		ft_MC+ft_packed,	fk_tools,	"VDIP USB OS"
	include "hlp/usb.hlp.bin.inc"


	addFile "vp/grafp.bin.zx7",			08D60h,	0A7FFh,	0FFFFh,	"GRAFP",	ft_MC+ft_packed,	fk_treiber,	"KRT Grafik"
	addFile "vp/crt80p.bin.zx7",			0B000h,	0B766h,	0B000h,	"CRT80P",	ft_MC+ft_packed,	fk_treiber,	"CRT-Treiber"
	include "hlp/krt.hlp.bin.inc"
	addfile	"vp/bootmodl.bin.zx7",			0400h,	,	,	"BOOT",		ft_MC+ft_packed+ft_systembank,	fk_cpm,		"boot robotron"
	addFile "vp/sysinfo.bin.zx7", 			0300h, 01FFFh, 0300h, 	"SYSINFO ", 	ft_MC+ft_packed+ft_systembank, 	fk_tools, 	"vp"

	addFile "vp/zm20a_3000.bin.zx7", 03000h, 03DEBh, 03000h, "ZM30", ft_MC+ft_packed, fk_tools, "V2.0A"
	addFile "vp/zm20a_A800.bin.zx7", 0A800h, 0B5EBh, 0A800h, "ZMA8", ft_MC+ft_packed, fk_tools, "V2.0A"


	if minicpm = 0
	addfile	"vp/chkrom.bin",			00300H,	,	,	"CHKROM",	ft_MC,	fk_tools,	"Selbsttest"
	addFile "diskos/diskos.bin.zx7",		04000h,	,	,	"DOSX",		ft_MC+ft_packed,	fk_tools+fk_shadow,"DISK OS"
	include "hlp/dos.hlp.bin.inc"
	addfile	"vp/epson.bin.zx7",			0A400H,	,	,	"EPSON",	ft_MC+ft_packed,	fk_treiber,	""
	addFile "vp/f83a4_com.bin.zx7",			0300h,	03A94h,	0300h,	"FORTH",	ft_MC+ft_packed,	fk_programmierung,"COM"
	include "hlp/forth.hlp.bin.inc"
	addFile "vp/crt40.bin.zx7",			0B000h,	0BB4Ah,	0B000h,	"CRT40",	ft_MC+ft_packed,	fk_treiber,	"CRT-Treiber"
	addFile "vp/ramtest.bin.zx7",			0300h,	0A04h,	0300h,	"RAMTEST",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "cpm/initkc.bin.zx7",			03000h,	,	,	"INITKC",	ft_MC+ft_packed,	fk_tools,	""
	addFile "robotron/script_com.bin.zx7",		0400h,	033FAh,	031D1h,	"SCRIPT",	ft_MC+ft_packed,	fk_buero,	"R0115"
	addFile "soft1/copy4_3.bin.zx7",		0300h,	05C0h,	0300h,	"COPY4/3",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "soft2-vp/kcpascal_com.bin.zx7",	027Fh,	02F2Fh,	0100Ch,	"PASCAL",	ft_MC+ft_packed,	fk_programmierung,"KCPascal 2.1"

	endif

	else	; lastbank <> 0fh



	org	02800h	; bank 1 
	binclude "z9001roms\bitex.rom"

	org	04000h  ; bank 2 
b_basic		equ	2	; Banknummer
	binclude "vp\basic_16d.bin"			; 16 Farben, korr. CSAVE
	
	org	06800h  ; bank 3 
	addFile "systembank/menu.bin.zx7",		0300h,	0D20h,	,	"MENU", 	ft_MC+ft_packed+ft_systembank,	fk_tools,	"GEM X"
	include "hlp/system.hlp.bin.inc"
	include "hlp/asm.hlp.bin.inc"
	include "hlp/edit.hlp.bin.inc"
	include "hlp/idas.hlp.bin.inc"
	include "hlp/zm.hlp.bin.inc"


	org	08000h  ; bank 4 
b_basicp	equ	4	; Banknummer
	binclude "vp\basic_16dp.bin"			; 16 Farben, korr. CSAVE, neues PRINT-AT
	shared b_basic, b_basicp


	if	rom_uzander = 0

	org	0A800h  ; bank 5 
	binclude "z9001roms\idas.rom",0,017FFh		; in ZM gepatcht, C3 03 F0 -> C3 00 00

	org	0C000h  ; bank 6 
	binclude "z9001roms\edas.rom"			; in ZM gepatcht, C3 03 F0 -> C3 00 00


	org	0E800h  ; bank 7 
	addFile "robotron/eproma2_com.bin.zx7",		0A200h,	0A5A1h,	0A200h,	"EPROMA2",	ft_MC+ft_packed,	fk_tools,	"R0112"
	addFile	"vp/eprommer.bin.zx7",			300h,	0BA6h,	,	"EPROMCCL",	ft_MC+ft_packed,	fk_tools,	"Z1013/buebchen"
	addFile "vp/ossave.bin.zx7",			0A000h,	0A2ABh,	,	"OS-SAVE",	ft_MC+ft_packed,	fk_tools,	"R0111"
	include "hlp/save.hlp.bin.inc"
; 25.04.2016 USB-VDIP
	addFile "diskos/usbos.bin.zx7",			0b600h,	,	,	"USBX",		ft_MC+ft_packed,	fk_tools,	"VDIP USB OS"
	include "hlp/usb.hlp.bin.inc"
	addfile	"vp/chkrom.bin",			00300H,	,	,	"CHKROM",	ft_MC,	fk_tools,	"Selbsttest"

	
	else	; rom_uzander = 1

	org	0A800h  ; bank 5 
	binclude "uz\bank5_datum.rom"			; DATUM

	org	0C000h  ; bank 6 
	binclude "uz\idas_uz2.rom"		; Ulrichs Version

	org	0E800h  ; bank 7 
;	addFile "robotron/eproma2_com.bin.zx7",		0A200h,	0A5A1h,	0A200h,	"EPROMA2",	ft_MC+ft_packed,	fk_tools,	"R0112"
	addFile	"vp/eprommer.bin.zx7",			300h,	0BA6h,	,	"EPROMCCL",	ft_MC+ft_packed,	fk_tools,	"Z1013/buebchen"
	addFile "vp/ossave.bin.zx7",			0A000h,	0A2ABh,	,	"OS-SAVE",	ft_MC+ft_packed,	fk_tools,	"R0111"
	include "hlp/save.hlp.bin.inc"
; 25.04.2016 USB-VDIP
	addFile "diskos/usbos.bin.zx7",			0b600h,	,	,	"USBX",		ft_MC+ft_packed,	fk_tools,	"VDIP USB OS"
	include "hlp/usb.hlp.bin.inc"

	if $ > 10000h
		warning "memory overlapping (10000h  ; bank 8)!"
	endif
	org	10000h  ; bank 8 
	binclude "z9001roms\edas.rom"

;	org	12800h  ; bank 9 
; frei

	if	lastbank = 7fh
	if $ > 14000h
		warning "memory overlapping (14000h  ; bank 10)!"
	endif
	org	14000h  ; bank 10 
	binclude "z9001roms\r80.rom"
	endif


	endif	; rom_uzander
	
; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; die einzelnen Files
;die Zeilen sind enstanden durch tap2bin.pl (erzeut xxx.inc)
;an den Filenamen wurde .zx7 angehängt; an den Dateityp + ft_packed (für gepackte Version)
;und es wurden manuell Kategorie und Kommentar geändert
;------------------------------------------------------------------------------
;	addFile filename, 				aadr,	[eadr],	[sadr],	name,		typ,	klasse,		kommentar
;bei TAP-Dateien xxx.tap schreiben -> include	"xxx.bin.inc"
;
;  Beispiel für buggy.tap
;    include "soft3/buggy.bin.inc" einfügen, make depend, make
;  erzeugt datei soft3/buggy.bin.inc aus soft3/buggy.tap, dann dersen Inhalt ändern oder 
;  hierher kopieren:
;    addFile "soft3/buggy.bin", 01000h, 027FFh, 01000h, "BUGGY", ft_MC, fk_unknown, "COM"
;  geändert /Typ, Kommentar, Packed
;    addFile "soft3/buggy.bin.zx7", 01000h, 027FFh, 01000h, "BUGGY", ft_MC+ft_packed, fk_spiele_mc, "Schlenzig"

;------------------------------------------------------------------------------
; Programme VP

	addfile	"vp/bootmodl.bin.zx7",			0400h,	,	,	"BOOT",		ft_MC+ft_packed+ft_systembank,	fk_cpm,		"boot robotron"
;;	addfile	"vp/boot_zfk.bin.zx7",			0400h,	,	,	"BOOTZFK",	ft_MC+ft_packed+ft_systembank,	fk_cpm,		"boot rossendorf"
	addFile "vp/sysinfo.bin.zx7", 			0300h, 01FFFh, 0300h, 	"SYSINFO ", 	ft_MC+ft_packed+ft_systembank, 	fk_tools, 	"vp"

	addFile "vp/word.bin.zx7",			00300h,	017FFh, 0300h,	"WORD",	ft_MC+ft_packed,	fk_buero,	"MicroWORD"

	if	rom_uzander = 1

	if	lastbank = 7fh
	if $ > 18000h
		warning "memory overlapping 18000h  ; bank 12)!"
	endif
	org	18000h  ; bank 12 
	binclude "z9001roms\zsid.rom"
	endif	; lastbank = 7fh

	endif

	addFile "vp/graf14.bin.zx7",			08E60h,	0A7FFh,	0FFFFh,	"GRAF14",	ft_MC+ft_packed,	fk_treiber,	"1/4 Grafik"
	addFile "vp/grafp.bin.zx7",				08D60h,	0A7FFh,	0FFFFh,	"GRAFP",	ft_MC+ft_packed,	fk_treiber,	"KRT Grafik"
	addFile "vp/crt40p.bin.zx7",			0B000h,	0BB4Ah,	0B000h,	"CRT40P",	ft_MC+ft_packed,	fk_treiber,	"CRT-Treiber"
	addFile "vp/crt80p.bin.zx7",			0B000h,	0B766h,	0B000h,	"CRT80P",	ft_MC+ft_packed,	fk_treiber,	"CRT-Treiber"
	include "hlp/krt.hlp.bin.inc"
	addFile "vp/uhr14_sss.bin.zx7",			0401h,	0673h,	000h,	"UHR14   ",	ft_BASIC+ft_packed,	fk_demos,	"+GRAF14"
	addFile "vp/uhr_sss.bin.zx7",			0401h,	0696h,	000h,	"UHR",		ft_BASIC+ft_packed,	fk_demos,	"+GRAFx"
	addFile "vp/r+grdemop_sss.bin.zx7",		0401h,	02F68h,	000h,	"R+GRDEMO",	ft_BASIC+ft_packed,	fk_demos,	"+GRAFx"

;ist schon in bank0 drin, bei uz aber andere Variante
;	include "vp/zm20a_3000.bin.inc"
;	addFile "vp/zm20a_3000.bin.zx7", 03000h, 03DEBh, 03000h, "ZM3A", ft_MC+ft_packed, fk_tools, "V2.0A"
;	include "vp/zm20a_A800.bin.inc"
	if	rom_uzander = 0
	addFile "vp/zm20a_A800.bin.zx7", 0A800h, 0B5EBh, 0A800h, "ZMA8", ft_MC+ft_packed, fk_tools, "V2.0A"
	else
		db 3200 dup (0ffh)
	endif

	addFile "vp/globus87_sss.bin.zx7",		0401h,	012E4h,	000h,	"GLOBUS87",	ft_BASIC+ft_packed,	fk_demos,	"+GRAFx"
	addFile "vp/n-eck_sss.bin.zx7",			0401h,	06ECh,	000h,	"N-ECK",	ft_BASIC+ft_packed,	fk_demos,	"+GRAFx"
	addFile "vp/switch_zg.bin.zx7",			08000h,	09037h,	08000h,	"CRT40PZG",	ft_MC+ft_packed,	fk_treiber,	"COM"

	addfile	"vp/epson.bin.zx7",			0A400H,	,	,	"EPSON",	ft_MC+ft_packed,	fk_treiber,	""
	addfile	"vp/kc_caos.bin.zx7",			08000H,	,	,	"KC-CAOS",	ft_MC+ft_Bank1+ft_packed,fk_tools,	""
;	addfile	"vp/sdx.bin",				0Bc00h,	,	,	"SDX",		ft_MC,			fk_tools,	"SD Kingstener"
;	addfile	"vp/sdx3f.bin",				03f00h,	,	,	"SDX3F",	ft_MC,			fk_tools,	"SD Kingstener"

	addfile	"vp/treiber_sammlung.bin.zx7",		0300h	,	,0538h,	"TR_SAMML",	ft_MC+ft_Packed,	fk_treiber,	"mp 10/87"
	addFile "vp/f83a4_com.bin.zx7",			0300h,	03A94h,	0300h,	"FORTH",	ft_MC+ft_packed,	fk_programmierung,"COM"
	include "hlp/forth.hlp.bin.inc"

	addFile "vp/crt40.bin.zx7",			0B000h,	0BB4Ah,	0B000h,	"CRT40",	ft_MC+ft_packed,	fk_treiber,	"CRT-Treiber"
	addFile "vp/device.bin.zx7",			00300h,	0051Fh,	00300h,	"DEVICE",	ft_MC+ft_packed,	fk_treiber,	"ASGN+IO"

	addFile "vp/fdtest18os.bin.zx7",		04000h,	051D0h,	04000h,	"FDTEST18",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "vp/ramtest.bin.zx7",			0300h,	0A04h,	0300h,	"RAMTEST",	ft_MC+ft_packed,	fk_tools,	"COM"

	addFile "vp/ftest13.rom.zx7",			08000h,	08627h,	08000h,	"FTEST13",	ft_MC+ft_packed,	fk_tools,	"COM"
;	addFile "robotron2/lpro16.rom.zx7",		08800h,	09BA7h,	08800h,	"LPRO",		ft_MC+ft_packed,	fk_tools,	"COM"

	addfile	"vp/banktest.bin.zx7",			01000H,	,	,	"BANKTEST",	ft_MC+ft_packed,	fk_tools,	"A.S."


;------------------------------------------------------------------------------
; 14.02.2012 CP/M
;;	addFile "cpm/cpml.bin.zx7",			0300h,	,	,	"CPM",		ft_MC+ft_packed+ft_systembank,	fk_cpm,	"CP/M-Loader"
;;	addFile "cpm/cpm_r.rom.zx7",			08000h-80h,,	0ffffh,	"CPM-R",	ft_MC+ft_packed,	fk_cpm+fk_hidden,""
;;	addFile "cpm/cpm_zfk.rom.zx7",			08000h-80h,,	0ffffh,	"CPM-ZFK",	ft_MC+ft_packed,	fk_cpm+fk_hidden,""
;2. version f. ulrichs rom
	addFile "cpm/cpm-48k-uz.rom.zx7",		04000h-80h,,	05600h,	"CPM-48K",	ft_MC+ft_packed+ft_systembank,	fk_cpm,""
	;include "hlp/cpm_kombi.hlp.bin.inc"
	addFile "hlp/cpm_kombi.hlp.bin.zx7", 		07800h, , 0FFFFh, 	"CPM", 		ft_HELP+ft_packed, 	fk_unknown+fk_hidden, "HELP"
	addFile "cpm/initkc.bin.zx7",			03000h,	,	,	"INITKC",	ft_MC+ft_packed,	fk_tools,	""

; 20.02.2012 DISK-OS
	addFile "cpm/call5dbg.bin",			07000h,	,	,	"CALL5DBG",	ft_MC+ft_systembank,			fk_tools,	""
	addFile "diskos/diskos_kombi.bin.zx7",		04000h,	,	,	"DOSX",		ft_MC+ft_packed,	fk_tools+fk_shadow,"DISK OS"
	;;include "hlp/dos_kombi.hlp.bin.inc"
	addFile "hlp/dos_kombi.hlp.bin.zx7", 		07800h, , 0FFFFh, 	"DOS", 		ft_HELP+ft_packed, 	fk_unknown+fk_hidden, "HELP"


;------------------------------------------------------------------------------

	; V24A1..A3-ROM
;	addFile "z9001roms/bm116.rom.zx7",		0b800h,	,	0ffffh,	"V24",		ft_MC+ft_packed,	fk_treiber,	"BM116.ROM"
	addFile "vp/bm116.bin.zx7",			0a800h,	,	0ffffh,	"V24",		ft_MC+ft_packed,	fk_treiber,	"BM116.ROM"

	addFile "soft3/v24g_com.bin.zx7",		0BB00h,	0BFB8h,	0BB00h,	"V24G",		ft_MC+ft_packed,	fk_treiber,	"COM"

;------------------------------------------------------------------------------

	addFile "soft6/prettyC.bin.zx7", 		0300h, 0BFFFh, 0BD00h, "PRETTYC", 		ft_MC+ft_packed+ft_systembank,		fk_programmierung,"Dr.Wobst"
	include "hlp/prettyc.hlp.bin.inc"

;------------------------------------------------------------------------------
;robotron-Kassetten

	if lastbank > 1fh

	addFile "robotron/r+remosa_sss.bin.zx7",	0401h,	01084h,	000h,	"R+REMOSA",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0111"
	addFile "robotron/r+demo1_sss.bin.zx7",		0401h,	03B5Bh,	000h,	"R+DEMO1 ",	ft_BASIC+ft_packed,	fk_demos,	"R0112"
	addFile "robotron/r+demo2_sss.bin.zx7",		0401h,	03CBBh,	000h,	"R+DEMO2 ",	ft_BASIC+ft_packed,	fk_demos,	"R0112"
	addFile "robotron/r+demo3_sss.bin.zx7",		0401h,	033C5h,	000h,	"R+DEMO3 ",	ft_BASIC+ft_packed,	fk_demos,	"R0112"
	addFile "robotron/r+hanoi_sss.bin.zx7",		0401h,	0E77h,	000h,	"R+HANOI ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0112"
	addFile "robotron/sprache1_com.bin.zx7",	06000h,	06E8Fh,	06000h,	"SPRACHE1",	ft_MC+ft_packed,	fk_treiber,	"R0113"
	addFile "robotron/grplot_com.bin.zx7",		09800h,	0A7FFh,	0FFFFh,	"GRPLOT",	ft_MC+ft_packed,	fk_treiber,	"R0114"
	addFile "robotron/r+pldemo_sss.bin.zx7",	0401h,	02F5Ch,	000h,	"R+PLDEMO",	ft_BASIC+ft_packed,	fk_demos,	"R0114"
	addFile "robotron/script_com.bin.zx7",		0400h,	033FAh,	031D1h,	"SCRIPT",	ft_MC+ft_packed,	fk_buero,	"R0115"
	addFile "robotron/k6311g1_com.bin.zx7",		0B600h,	0BEFFh,	0B600h,	"K6311G1",	ft_MC+ft_packed,	fk_treiber,	"R0115"
	addFile "robotron/k6313g1_com.bin.zx7",		0B600h,	0BEFFh,	0B600h,	"K6313G1",	ft_MC+ft_packed,	fk_treiber,	"R0115"
	addFile "robotron/text1_com.bin.zx7",		0700h,	03016h,	0700h,	"TEXT1",	ft_MC+ft_packed,	fk_buero,	"R0136"
	addFile "robotron/r+afri1_sss.bin.zx7",		0401h,	03902h,	000h,	"R+AFRI1 ",	ft_BASIC+ft_packed,	fk_buero,	"R0145"
	addFile "robotron/r+master_sss.bin.zx7",	0401h,	01423h,	000h,	"R+MASTER",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"
	addFile "robotron/r+mond_sss.bin.zx7",		0401h,	014C2h,	000h,	"R+MOND  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"
	addFile "robotron/r+nim_sss.bin.zx7",		0401h,	0155Fh,	000h,	"R+NIM   ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"
	addFile "robotron/r+othelo_sss.bin.zx7",	0401h,	01322h,	000h,	"R+OTHELO",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"
	addFile "robotron/r+skeet_sss.bin.zx7",		0401h,	0126Bh,	000h,	"R+SKEET ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0165"
	addFile "robotron/r+autocr_www.bin.zx7",	0401h,	014C2h,	000h,	"R+AUTOCR",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0166"
	addFile "robotron/r+halma_www.bin.zx7",		0401h,	01459h,	000h,	"R+HALMA ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0166"
	addFile "robotron/r+trumpf_www.bin.zx7",	0401h,	013BBh,	000h,	"R+TRUMPF",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0166"
	addFile "robotron/r+grekal_sss.bin.zx7",	0401h,	013EFh,	000h,	"R+GREKAL",	ft_BASIC+ft_packed,	fk_buero,	"R0191"
	addFile "robotron/r+memory_sss.bin.zx7",	0401h,	018EFh,	000h,	"R+MEMORY",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0191"
	addFile "robotron/r+morset_sss.bin.zx7",	0401h,	02018h,	000h,	"R+MORSET",	ft_BASIC+ft_packed,	fk_buero,	"R0191"
	addFile "robotron/r+pasch_sss.bin.zx7",		0401h,	01353h,	000h,	"R+PASCH ",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0191"
	addFile "robotron/r+flohsp_sss.bin.zx7",	0401h,	016E3h,	000h,	"R+FLOHSP",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0192"
	addFile "robotron/r+hobbit_sss.bin.zx7",	0401h,	017EDh,	000h,	"R+HOBBIT",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0192"
	addFile "robotron/r+slalom_sss.bin.zx7",	0401h,	01574h,	000h,	"R+SLALOM",	ft_BASIC+ft_packed,	fk_spiele_basic,"R0192"

;------------------------------------------------------------------------------
;robotron2	von Robotron, aber nicht vertrieben
	addFile "robotron2/boalab_sss.bin.zx7",		0401h,	011B2h,	000h,	"BOALABYR",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/boalab2_sss.bin.zx7", 	0401h, 	011B2h, 000h, 	"BOALAB2 ", 	ft_BASIC+ft_packed, 	fk_unknown, 	"robotron"
	addFile "robotron2/catlab_sss.bin.zx7",		0401h,	012DEh,	000h,	"X+CATLAB",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/centip_sss.bin.zx7",		0401h,	01D2Dh,	000h,	"CENTIPED",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/comodore_com.bin.zx7",	0400h,	0B96h,	0400h,	"COMODORE",	ft_MC+ft_packed,	fk_unknown,	"robotron"
	addFile "robotron2/gammon_sss.bin.zx7",		0401h,	02A9Ch,	000h,	"K+GAMMON",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
;;	addFile "robotron2/histo_sss.bin.zx7",		0401h,	03BDBh,	000h,	"R+HISTO1",	ft_BASIC+ft_packed,	fk_buero,	"robotron"
	addFile "robotron2/history1_sss.bin.zx7",	0401h,	03C70h,	000h,	"R+HISTO1",	ft_BASIC+ft_packed,	fk_buero,	"robotron"
	addFile "robotron2/history2_sss.bin.zx7",	0401h,	03700h,	000h,	"R+HISTO2",	ft_BASIC+ft_packed,	fk_buero,	"robotron"
	addFile "robotron2/history4_sss.bin.zx7",	0401h,	0391Bh,	000h,	"R+HISTO4",	ft_BASIC+ft_packed,	fk_buero,	"robotron"
	addFile "robotron2/maus_sss.bin.zx7",		0401h,	02044h,	000h,	"S+MAULAB",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
;;	addFile "robotron2/mazogs_sss.bin.zx7",		0401h,	03C5Fh,	000h,	"MAZOGS  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "uz/mazogs.bin.zx7",		0401h,	04027h,	000h,	"MAZOGS  ",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron/uz"
	addFile "robotron2/messe_sss.bin.zx7",		0401h,	02871h,	000h,	"R+MESSE2",	ft_BASIC+ft_packed,	fk_demos,	"robotron"
	addFile "robotron2/newenter_sss.bin.zx7",	0401h,	02FA5h,	000h,	"ENTERPRI",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/othellom_com.bin.zx7",	0400h,	0B59h,	0400h,	"OTHELLOM",	ft_MC+ft_packed,	fk_spiele_mc,	"robotron"
	addFile "robotron2/pong_sss.bin.zx7",		0401h,	013D3h,	000h,	"K+PONG",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/prognose_sss.bin.zx7",	0401h,	0159Bh,	000h,	"PROGNOSE",	ft_BASIC+ft_packed,	fk_unknown,	"robotron"
	if	rom_uzander = 0
	addFile "robotron2/r80kor_com.bin.zx7",		0400h,	02A00h,	0400h,	"R80",	ft_MC+ft_packed,	fk_programmierung,"robotron"
;;	addFile "robotron2/r80_com.bin.zx7",		0400h,	02A00h,	0400h,	"R80",		ft_MC+ft_packed,	fk_programmierung,"robotron"
	endif
	addFile "robotron2/recher_sss.bin.zx7",		0401h,	02D2Bh,	000h,	"R+RECH",	ft_BASIC+ft_packed,	fk_unknown,	"robotron"
	addFile "robotron2/reversi_sss.bin.zx7",	0401h,	01174h,	000h,	"REVERSI ",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/spiedi_sss.bin.zx7",		0401h,	01528h,	000h,	"K+SPIEDI",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"
	addFile "robotron2/tatum_sss.bin.zx7",		0401h,	06AB8h,	000h,	"TATUM   ",	ft_BASIC+ft_packed,	fk_spiele_basic,"robotron"


;------------------------------------------------------------------------------
;soft1
	addFile "soft1/bolero.bin.zx7",			0300h,	0976h,	0300h,	"BOLERO",	ft_MC+ft_packed,	fk_tools,	"COM"
	if	rom_uzander = 0
	addFile "soft1/copy3_1.bin.zx7",		0300h,	06F2h,	0300h,	"COPY3/1",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "soft1/copy4_3.bin.zx7",		0300h,	05C0h,	0300h,	"COPY4/3",	ft_MC+ft_packed,	fk_tools,	"COM"
	else
	addFile "soft1/copy3_1.bin.zx7",		0300h,	06F2h,	0300h,	"COPY",	ft_MC+ft_packed,	fk_tools,	"COM"
	endif

;03.05.2017
	addFile "uz/analyse.bin.zx7", 0300h, 05A8h, 0300h, "ANALYSE", ft_MC+ft_packed, fk_tools, "COM"
	if	rom_uzander = 0
	addFile "uz/datum.bin.zx7", 0300h, 074Ah, 0300h, "DATUM", ft_MC+ft_packed, fk_tools, "COM"
	endif
	addFile "uz/othello_com.bin.zx7", 0400h, 0BECh, 0400h, "OTHELLO", ft_MC+ft_packed, fk_spiele_mc, "COM"
	addFile "uz/tapedir.bin.zx7", 0300h, 0602h, 0300h, "TAPEDIR", ft_MC+ft_packed, fk_tools, "COM"
	
	
	addFile "soft2-vp/beatles_sss_neu.bin.zx7",	0401h,	0296Eh,	000h,	"BEATLES ",	ft_BASIC+ft_packed,	fk_demos,	""


	addFile "soft3/bac87_sss.bin.zx7",		0401h, 01E87h, 000h,	"BAC87   ",	ft_BASIC+ft_packed,	fk_programmierung,"basicode"
	addFile "soft3/bac87c_sss.bin.zx7",		0401h, 020BFh, 000h,	"BAC87C   ",	ft_BASIC+ft_packed,	fk_programmierung,"basicode"



	endif	; lastbank > 1fh
	if	lastbank = 7fh

	addFile "soft2-vp/kcpascal_com.bin.zx7",	027Fh,	02F2Fh,	0100Ch,	"PASCAL",	ft_MC+ft_packed,	fk_programmierung,"KCPascal 2.1"
	addFile "soft3/kcpascal.rom.zx7",		04000h,	,	,	"KCPASCAL",	ft_MC+ft_packed,	fk_programmierung,"Turbo-Pascal"


	addFile "soft2-vp/boerse_sss.bin.zx7",		0401h,	02D43h,	000h,	"BOERSE  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/bohne_sss.bin.zx7",		0401h,	015EDh,	000h,	"BOHNE   ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/cave_sss.bin.zx7",		0401h,	01E1Dh,	000h,	"CAVE    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
;;	addFile "soft2-vp/centip_sss.bin.zx7",		0401h,	01D2Dh,	000h,	"CENTIP  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/chess.bin.zx7",		1000h,	043FFh,	1100h,	"CHESS    ",	ft_MC+ft_packed,	fk_spiele_mc, "VCM KC85"
	addFile "soft2-vp/climber_sss.bin.zx7",		0401h,	02B74h,	000h,	"CLIMBER ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/eliza-d_sss.bin.zx7",		0401h,	011EDh,	000h,	"ELIZA-D ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/handelsf_sss.bin.zx7",	0401h,	03686h,	000h,	"HANDELSF",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/jaeger90_sss.bin.zx7",	0401h,	025DCh,	000h,	"JAEGER90",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/kaefer_sss.bin.zx7",		0401h,	01578h,	000h,	"KAEFER  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/kaiser_sss.bin.zx7",		0401h,	030D7h,	000h,	"KAISER  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/kalender_sss.bin.zx7",	0401h,	06EEh,	000h,	"KALENDER",	ft_BASIC+ft_packed,	fk_buero,	""
	addFile "soft2-vp/knossos2_sss.bin.zx7",	0401h,	023E1h,	000h,	"KNOSSOS2",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/KNOSSOS_SSS.bin.zx7",		0401h,	01E74h,	000h,	"KNOSSOS ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/ladder_sss.bin.zx7",		0401h,	03C4Bh,	000h,	"LADDER  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/leiter-2_sss.bin.zx7",	0401h,	0FE7h,	000h,	"LEITER-2",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/life_sss.bin.zx7",		0401h,	0CE8h,	000h,	"LIFE    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""

;;testweise f. Ulrich 17.05.2016 
;;	addFile "vp\test_kombi.bin", 0300h, 034fh, 0300h, "KOMBI", ft_MC, fk_tools, "test"

	addFile "soft2-vp/manager_sss.bin.zx7",		0401h,	05EE3h,	000h,	"MANAGER ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
;;robotron	addFile "soft2-vp/mazogs_sss.bin.zx7",		0401h,	03CCFh,	000h,	"MAZOGS  ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/mintex_sss.bin.zx7",		0401h,	0B20h,	000h,	"MINTEX  ",	ft_BASIC+ft_packed,	fk_buero,	""
	addFile "soft2-vp/packman_com.bin.zx7",		01000h,	01B00h,	01000h,	"PACKMAN",	ft_MC+ft_packed,	fk_spiele_mc,	"COM"
	addFile "soft2-vp/paravia_sss.bin.zx7",		0401h,	03224h,	000h,	"PARAVIA ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/pyramide_sss.bin.zx7",	0401h,	02D7Eh,	000h,	"PYRAMIDE",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/skat_sss.bin.zx7",		0401h,	029BDh,	000h,	"SKAT    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/startrek_sss.bin.zx7",	0401h,	0277Fh,	000h,	"STARTREK",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/taxi_sss.bin.zx7",		0401h,	0150Bh,	000h,	"TAXI    ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/wobugor_com.bin.zx7",		07300h,	07FE9h,	0FFFFh,	"WOBUGOR",	ft_MC+ft_packed,	fk_tools,	"COM"
	addFile "soft2-vp/wuerfeln_sss.bin.zx7",	0401h,	0A11h,	000h,	"WUERFELN",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/yahtzee_sss.bin.zx7",		0401h,	02176h,	000h,	"YAHTZEE ",	ft_BASIC+ft_packed,	fk_spiele_basic,""
	addFile "soft2-vp/zwinger_sss.bin.zx7",		0401h,	06A4h,	000h,	"ZWINGER ",	ft_BASIC+ft_packed,	fk_demos,	""

	;include "soft3/buggy.bin.inc"
	;addFile "soft3/buggy.bin", 01000h, 027FFh, 01000h, "BUGGY", ft_MC, fk_unknown, "COM"
	addFile "soft3/buggy.bin.zx7", 01000h, 027FFh, 01000h, "BUGGY", ft_MC+ft_packed, fk_spiele_mc, "Schlenzig"
	addFile "soft3/hexi.bin.zx7", 03C00h, 03FBFh, 03C00h, "HEXI", ft_MC+ft_packed, fk_tools, "Schlenzig"


	endif	; lastbank = 7fh

	endif	; lastbank = 1fh
	
;-------------------------------------------------
; Mini-CPM

	if minicpm

; 1 Bank CPM gerade bank, da > 6k
; 
cpmBank	equ lastbank - 9


	org	cpmBank/2*16*1024
cpmCode equ $
	binclude	"cpm/minicpm_kombi.bin"
	if rom_uzander==1
	binclude	"cpm/minicpm_kombi.bin"
	endif
	
;	ROM-Disk


	org	cpmCode + 10*1024
	binclude 	"minicpm/diskvp3.dmp"


	endif	; minicpm



	if rom_uzander==1
;ENDE	
	org	(lastbank+1)/2*16*1024 - 100h
	db	0c3h, 0aeh, 0f6h	; jp	0, jp 0F6AEh
	db	"ENDE    ",0,0
	endif
;-------------------------------------------------


;------------------------------------------------------------------------------


	endif
;------------------------------------------------------------------------------


;; Ende
hier 	equ $
last_bank_id 	equ 	($ / blocksize + systembank)
last_pos_id	equ 	($ # blocksize + bankstart)
	SHARED hier, last_bank_id, last_pos_id, lfdnr


	if megarom == "MEGA"
	org 280000h-1
	db 0ffh
	else
	org 16*1024*((lastbank+1)/2)-1
	db 0ffh
	endif

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

	message "======================================="
	message	"packedrom.bin erstellt fuer: \{megarom}"
	message "======================================="


        end
