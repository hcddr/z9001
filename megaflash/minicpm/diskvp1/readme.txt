          Hinweise
          ========


1. Inhalt der Systemdiskette

@CPMZ9   COM:	Betriebssystem, muss 1.File auf Diskette sein
CLOCK    COM:   Zeigt Uhrzeit in rechter oberer Bilschirmecke.
                Abschalten bei Arbeit mit Magnetband-Kassette!!
STAT     COM:	modifiziertes CP/M-STAT (I/O-Byte!)
SUBMIT   COM:	original CP/M-Submit
XSUB     COM:	   "     CP/M-XSUB
20Z      COM:	stellt 20-Zeilen Bildschirmode ein (BITEX!)
24Z      COM:	stellt 24-Zeilen-Mode ein (TURBO !)
DIP      COM:	Kopierprogramm, gut falls nur 1 Laufwerk
L80      COM:	original L80
M80      COM:	original M80
ULAD     DOC:	8-Bit-Wordstar(TP)-Datei!
POWER    COM:	original Power
ULAD     COM:	s. ULAD.DOC
BITEX    COM:	schneller Bildschirmeditor
ZSID     COM:	Debugger
TURBO    COM:	Turbo-Pascal, installiert fuer CP/M-Z9001
BITEX    DOC:	8-Bit-Wordstar-Datei
TURBO    MSG:	
TURBO    OVR:	
KCCPM    TXT:	16-Bit-Wordstar-Datei, Beschreibung CP/M-Z9001
ZBASIC   COM:	Heimcomputer-BASIC, Disketten-Version
ZDIR     COM:	Directory-Anzeige, beenden mit ESC
ZBASICT  COM:	HC-BASIC, liest von Kassette, schreibt auf Disk
                CLOCK muss abgeschaltet sein!!!
DPB      DOC:	Disk-Parameter-Block
BOALAB   ZBS:	Basic-Spiel
PASCH    ZBS:	dito
PFERD    ZBS:	dito
SKAT     ZBS:	dito
RESET    COM:	Ruecksetzen zum OS-Z9001
FORMATZ  COM:   Fuer CP/M-Z9001 autorisiertes Programm zum
                Formatieren (initialisieren) von Disketten.
                Standard fuer CP/M-Z9001 sind die Formate
                800K,400K und 200K (je nach Laufwerkstyp).
BOOT720  DAT:   Diese Dateien gehoeren zu FORMATZ und werden 
BOOT360  DAT:   beim Formatieren von MS-DOS-Disketten benoetigt.

2. Turbo-Pascal

Achtung: ^K musste wegen Tastatur mit ^E getauscht werden.
D.h., das ^K-Menu wird jetzt durch ^E erreicht!
Vor Aufruf von Turbo ist 24-Zeilen-Mode einzustellen

3. Bitex

Vor Bitex-Aufruf 20-Zeilen-Mode einstellen.

4. Fehlermeldungen

 - Folgende Fehlermeldungen werden bei
   fehlerhaftem Bootvorgang ausgegeben:

   N: falsches System (Name!)
   L: falsche Laenge des Systems
   ?: kein CCP am Systemanfang

 - BIOS-Fehlermeldungen (bei Disk-Arbeit)

   Die Fehlermeldung hat folgendes Format:

	{R|W} fc ;T,Si,Se=tthhss

	  ^
	  |___R: Fehler beim Lesen
	      W: Fehler beim Schreiben

   tt: Spur
   hh: Kopf (Side)
   ss: Sektor
       (alle hexadezimal)

   mit fc =

   R  Geraet nicht bereit, aber existent
   W  Diskette schreibgeschuetzt
   S  Sektor nicht gefunden
   T  Spurnummer zu gross oder nicht zu finden
   C  CRC-Fehler
   D  Laufwerk nicht existent
   U  keine Marke gefunden
   B  fehlerhafte Befehlsaugabe (interner Fehler)
   F  Fehler ber Ausfuehrung des Seek-Kommandos

