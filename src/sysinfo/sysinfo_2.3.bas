'--------------------------------------------------------
'Systeminfo V.Pohlers 18.05.2013, letzte Änderung 27.07.2020
'jkcemu 0.93
'java -jar %jkcemu% --bc -L DE -B0 -O3 -t Z9001 -A 300 -N SYSINFO -o sysinfo.tap sysinfo_2.3.bas
'--------------------------------------------------------

'27.07.2020 
'SYSINFO Fehler:
'I/O-Abfrage von 78H schaltet Bank 01 ein. Da SYSINFO im RAM läuft,
'ist das nicht weiter hinderlich, da beim Beenden wieder auf Bank 00
'gesetzt wird.
'I/O-Abfrage schaltet bei KRT in den GRAFIK-Modus und nichts geht mehr.
'War zuvor GRAFP geladen und mal im BASIC gespielt, kann man mit Blind-
'eingabe <ENTER> und 9 + <ENTER> ins System zurückgelangen.


declare sub main
declare function chksum (von,laenge)
declare FUNCTION ramtest(A)
declare sub ModulInfo(i)

A=0:B=0:V=0: 'globale Variable für ASM-Routinen

main: 'Hauptprogramm
end

'--------------------------------------------------------
sub Enter
'--------------------------------------------------------
local w$
  PRINT:PRINT "<ENTER>",:W$=INPUT$(1)
end sub

'--------------------------------------------------------
' Kurzinfo
'--------------------------------------------------------
'Assembler-Code
asm "get_os_version:"
asm " LD C,12"
asm " CALL 0005H"
asm " LD (VI_V),BC"
asm " RET"

'--------------------------------------------------------
'Speichertest ram-test adr. a, b=0 -> ram
FUNCTION ramtest(A)
'--------------------------------------------------------
  LOCAL B
  POKE A,255-PEEK(A):B=PEEK(A):POKE A,255-PEEK(A)
  B=B=(255-PEEK(A))
  ramtest = B:'Rueckgabewert zuweisen
END FUNCTION 

'--------------------------------------------------------
' Kurzinfo
'--------------------------------------------------------
sub Kurzinfo
  local r: 'V muss global sein f. get_os_version
  asm " call get_os_version": 'return V=Version
  INK YELLOW
  IF V=&H101 THEN
    PRINT "Z9001.84,";
  ELSEIF V=&H102 THEN
    PRINT "KC85/1 o. KC87.1x,";
  ELSEIF V=&H103 THEN
    PRINT "KC 87.2x,";
  ELSE
    PRINT "Z9001,";
  ENDIF
  'Farbe
  IF ramtest(&HE800) then PRINT " Farbe,"; : else : PRINT " S/W,";
  'RAM-Speicher
  R=16
  IF ramtest(&H4000) LET R=R+16
  IF ramtest(&H8000) LET R=R+16
  PRINT R,"K RAM"
  INK GREEN
END sub

'--------------------------------------------------------
' Speicherausbau
'--------------------------------------------------------

' chksum. Prüfsumme ab a, Anzahl b, result v
asm "CHKSUM: LD HL,(VI_A)"
asm " LD DE,(VI_B)"
asm " LD IX,0"
asm " LD B,0"
asm "CHKSUM1: LD C,(HL)"
asm " ADD IX,BC"
asm " INC HL"
asm " DEC DE"
asm " LD A,D"
asm " OR E"
asm " JR NZ,CHKSUM1"
asm " LD (VI_V),IX"
asm " RET"

'--------------------------------------------------------
function chksum (von,laenge)
'--------------------------------------------------------
  A=von
  B=laenge
  asm " call CHKSUM": 'return V=Summe
  chksum = V
end function 

'--------------------------------------------------------
' 1100 REM OS-Version
sub osVersion
'--------------------------------------------------------
local S
  asm " call get_os_version": 'return V=Version
  PRINT "OS V",str$(v/256),".",str$(v mod 256),
  ' Prüfsumme vergleichen
  S=chksum(&HF000,&H1000)
  ' OS 1.1 16690, OS 1.2 16318, OS 1.3 16387
  IF S=16690 OR S=16318 OR S=16387 THEN PRINT " (orig)":ELSE: PRINT " (modifiziert)"
end sub


'--------------------------------------------------------

function MYINP(I)
  LOCAL B
  B = INP(I)
  IF I=&H78 
	OUT (&H75)=0
  ELSEIF I=&HB8 
	OUT (&HB8)=0	
  ENDIF
  MYINP = B:'Rueckgabewert zuweisen
end function

'--------------------------------------------------------
' 1300 REM ROM-Modul
sub ROMModul
'--------------------------------------------------------
local S
  IF ramtest(&HC000) then 
    PRINT "RAM"
  ELSE
  S=chksum(&HC000,&H2800)
  IF S=-26395 THEN 
			PRINT "EDIT/ASM (robotron)"
  ELSEIF S=-17313 
			PRINT "EDIT/ASM (tpaul)"
  ELSEIF S=-29931 
			PRINT "EDIT/ASM (UZ)"
'  ELSEIF S=-31677 
'			PRINT "EDIT/ASM (vp)"
  ELSEIF S=26156 
			PRINT "IDAS + EPROM (robotron)"
  ELSEIF S=-30444 
			PRINT "IDAS + QUICK (UZ)"
  ELSEIF S=-6809 
 			PRINT "BASIC 84"
  ELSEIF S=-7944 
			PRINT "BASIC 85"
  ELSEIF S=-8012 
			PRINT "BASIC 85a"
  ELSEIF S=5194
			PRINT "BASIC 86 (Plotter)"
  ELSEIF DEEK(&HC000)=&H0B18 THEN 
 			PRINT "BASIC (modifiziert)";S
  ELSEIF DEEK(&HC00F)=&H4343 THEN 
		IF MYINP(&H78) <> 255 THEN 
			PRINT "64K-SRAM-Modul"
	  	ELSE
			PRINT "MEGA-FLASH-Modul":' #CCp
		ENDIF
  ELSEIF DEEK(&HC033)=&H454D THEN 
			PRINT "MEGA-Modul (KOMA)":' #MEnu
  ELSEIF PEEK(&HC000)=&HC3 THEN 
  			PRINT "ROM (Id: ";S;")"
  ELSEIF S=-4096 Or S=-10240
			PRINT "kein Modul"
  ELSE 
 			PRINT "unbekannt (Id: ";S;")"
  ENDIF
  ENDIF
end sub

'--------------------------------------------------------
'64K-RAM-Modul
function ShadowRAM
'--------------------------------------------------------
local VR, HR
  out 4,1: VR = peek(&H4000)
  out 5,1: HR = peek(&H4000)
  out 4,1: poke &H4000, 42
  out 5,1: poke &H4000, 57
  out 4,1
  ShadowRAM = peek (&H4000) = 42
  out 5,1: poke &H4000, HR
  out 4,1: poke &H4000, VR
end function

'--------------------------------------------------------
sub Speicherausbau
'--------------------------------------------------------
  CLS
  REM PRINT:PRINT
  PRINT "Speicher-Scan"
  PRINT "====================================":PRINT:PRINT
  PRINT "FFFF +------+"
  PRINT "     !      !  ",: osVersion
  PRINT "F000 +------+"
  PRINT "     !      !  Bildspeicher"
  PRINT "EC00 +------+"
  PRINT "     !      !  ",:  'Farbe
  IF ramtest(&HE800) then PRINT "Farb-BWS (Farbvariante)" : else : PRINT "kein RAM (S/W-Geraet)"
  PRINT "E800 +------+"
  PRINT "     !      !  ",: ROMModul
  PRINT "C000 +------+"
  PRINT "     !      !  ",:'RAM8
  IF ramtest(&H8000) then PRINT "16K RAM-Modul" : else : PRINT "kein RAM"
  IF ShadowRAM then 
    PRINT "8000 +------+------+"
    PRINT "     !      !Shadow!  2x 16K-RAM"
    PRINT "4000 +------+------+"
  else
    PRINT "8000 +------+"
    PRINT "     !      !  ",:'RAM4
    IF ramtest(&H4000) then PRINT "16K RAM-Modul" : else : PRINT "kein RAM"
    PRINT "4000 +------+"
  endif
  PRINT "     !      !  System-RAM"
  PRINT "0000 +------+"
  PRINT:Enter
end sub


'--------------------------------------------------------
' 2000 REM Modulsuche
'--------------------------------------------------------

sub Bereich(i)
 print hex$(I,2);"-";hex$(I+7,2),
end sub

sub ModulInfo(i)
 IF MYINP(I) <> 255 then 
' print hex$(I,2);"-";hex$(I+7,2),
	 IF I=&H10 THEN 
			Bereich(i):PRINT " CPM-Floppy-Modul (Rossendorf)"
	 ELSEIF I=&H20 
			Bereich(i):PRINT " RAM-Floppy RAF2008"
	 ELSEIF I=&H58 
	 		Bereich(i):PRINT " GIDE"
	 ELSEIF I=&H60 
	 		Bereich(i):PRINT " RTC"
	 ELSEIF I=&H68 
	 		Bereich(i):PRINT " RTC"
	 ELSEIF I=&H78 
	 		PRINT "74-78 Kombi-/64K-SRAM-Modul"
	 ELSEIF I=&H80 
	 		Bereich(i):PRINT " CTC (System, Uhr)"
	 ELSEIF I=&H88 
	 		Bereich(i):PRINT " PIO1 (System, Userport)"
	 ELSEIF I=&H90 
			Bereich(i):PRINT " PIO2 (System, Tastatur)"
	 ELSEIF I=&H98 
			Bereich(i):PRINT " CPM-Floppy-Modul (robotron)"
	 ELSEIF I=&HA8 
			Bereich(i):PRINT " Druckermodul (CTC)"
	 ELSEIF I=&HB0 
			Bereich(i):PRINT " Druckermodul (SIO)"
	 ELSEIF I=&HB8 
			Bereich(i):PRINT " Grafikzusatz/KRT"
	 ELSEIF I=&HC1 
			Bereich(&HC0):PRINT " KCNET"
	 ELSEIF I=&HC8 
			Bereich(i):PRINT " E/A-Modul"
	 ELSEIF I=&HD0 
			Bereich(i):PRINT " Programmier-Modul"
	 ELSEIF I=&HDD 
			PRINT "DC-DF VDIP1-USB (PIO)"
	 ELSEIF I=&HE0 
			Bereich(i):PRINT " Spracheingabemodul"
	 ELSEIF I=&HF8 
			Bereich(i):PRINT " ADU-Modul"
	 ELSEIF I=&HFC 
			PRINT "FC-FF Buebchen-Brenner"
	 REM todo RAF-Suche über extra ASM-Code
	 ELSE 
	   PRINT " ???"
	 endif
 	PRINT
 endif
end sub


'--------------------------------------------------------
sub PortScan
'--------------------------------------------------------
local I
  CLS
  REM PRINT:PRINT
  PRINT "I/O-Scan"
  PRINT "====================================":PRINT
  PRINT "Port  Modul":PRINT:PRINT
  FOR I=0 TO 255 STEP 8:' die meisten Module sind uvst. dekodiert
  'wg Vollgrafik und RTC ist DI nötig
 asm " DI"
  ModulInfo(i)
  NEXT
  ModulInfo(&hC1):' KCNET
  ModulInfo(&hDD):' VDIP
  ModulInfo(&hFC):' Bübchen-Brenner
 asm " EI"
  Enter
end sub

'--------------------------------------------------------
' Farbtest
'--------------------------------------------------------
sub Farbtest
local i,zeile
  CLS
  REM PRINT:PRINT
  PRINT "Farbtest"
  PRINT "====================================":PRINT
IF ramtest(&HE800) THEN
  PRINT"Vordergrund"
  PRINT"schw rot  gruengelb blau lila cyan weiss";
  for zeile = 1 to 6
    for i = 0 to 7 
      INK i: print CHR$(255);CHR$(255);CHR$(255);CHR$(255);CHR$(255);
    next i
  next zeile
  INK GREEN: PAPER 0: 'BLACK
  
  PRINT:PRINT"Hintergrund"
  PRINT"schw rot  gruengelb blau lila cyan weiss";
  for zeile = 1 to 6
    for i = 0 to 7
      PAPER i: print "     ";
    next i
  next zeile
  INK GREEN: PAPER 0: 'BLACK
ELSE
  PRINT "Keine Farbkarte gefunden!"
ENDIF
  Enter
end sub

'--------------------------------------------------------
' 64K-Test
'--------------------------------------------------------

sub ShadowRAMTest
local i
local erranz
  erranz = 0
  CLS
  REM PRINT:PRINT
  PRINT "Test 64K-RAM-Modul"
  PRINT "====================================":PRINT
IF ShadowRAM THEN
  PRINT:PRINT"Teste Vordergrund-RAM 4000-7FFF..."
  FOR i = &H4000 to &H7FFE
    poke i, &h31
  next i
  FOR i = &H4000 to &H7FFE
    if peek(i) <> &h31 PRINT hex$(i,4)," soll 31 ist ",hex$(peek(i),2): erranz = erranz + 1
  next i
  PRINT:PRINT"Teste Hintergrund-RAM 4000-7FFF..."
  out 5,1: 'shadow on
  FOR i = &H4000 to &H7FFE
    poke i, &h32
  next i
  FOR i = &H4000 to &H7FFE
    if peek(i) <> &h32 PRINT hex$(i,4)," soll 32 ist ",hex$(peek(i),2): erranz = erranz + 1
  next i
  out 4,1: 'shadow off
  PRINT:PRINT"Vergleich mit Vordergrund-RAM..."
  FOR i = &H4000 to &H7FFE
    if peek(i) <> &h31 PRINT hex$(i,4)," soll 31 ist ",hex$(peek(i),2): erranz = erranz + 1
  next i
  PRINT:PRINT"Teste RAM 8000-BFFF..."
  FOR i = &H8000 to &HBFFF
    poke i, &h34
  next i
  FOR i = &H8000 to &HBFFF
    if peek(i) <> &h34 PRINT hex$(i,4)," soll 34 ist ",hex$(peek(i),2): erranz = erranz + 1
  next i
  PRINT:PRINT"Teste Hi-RAM C000-E7FF..."
  out 7,1: 'Hi on
  FOR i = &HC000 to &HE7FF
    poke i, &h33
  next i
  FOR i = &HC000 to &HE7FF
    if peek(i) <> &h33 PRINT hex$(i,4)," soll 33 ist ",hex$(peek(i),2): erranz = erranz + 1
  next i
  out 6,1: 'Hi off
ELSE
  PRINT "Kein 64K-RAM-Modul gefunden!"
ENDIF
  PRINT
  PRINT "Beendet.", erranz, "Fehler"
  PRINT:Enter
end sub


'--------------------------------------------------------
' Hauptprogramm
'--------------------------------------------------------
sub main
local W
DO 
  INK GREEN: PAPER 0:'BLACK
  cls
  PRINT "Systeminfo 2.3  V.Pohlers 27.07.2020"
  PRINT "====================================":PRINT:PRINT:PRINT
  Kurzinfo:PRINT:PRINT:PRINT
  PRINT "  Speicher-Scan .... 1":PRINT
  PRINT "  I/O-Scan ......... 2":PRINT
  PRINT "  Test Farbe ....... 7":PRINT
  PRINT "  Test 64K-RAM ..... 8":PRINT
  PRINT "  Ende ............. 9":PRINT
  PRINT
  DO
    INPUT "Auswahl ";W
  LOOP UNTIL W>=1 AND W<=9
  IF W=1 THEN 
    Speicherausbau
  ELSEIF W=2 THEN
    PortScan
  ELSEIF W=7 THEN
    Farbtest
  ELSEIF W=8 THEN
    ShadowRAMTest
  ELSEIF W=9 THEN
    OUT 255,0: 'Mega-ROM-Bank 0
    EXIT: 'Programm beenden
  ENDIF
LOOP
end sub

