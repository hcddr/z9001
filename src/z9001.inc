;-----------------------------------------------------------------------------
; Arbeitsspeicher 
;-----------------------------------------------------------------------------

IOBYT		equ	0004h		; IO-Byte (in SIO)
LISW		equ	0015h		; Schalter für Hardcopy (in SIO)

fcb1		equ	005Ch
fcb2		equ	006Ch
; Aufbau FCB
; 00	FDRIVE	Laufwerkscode (keins - 0, A - 1, B - 2)
; 01-08	FNAME	Dateiname, mit Leerzeichen aufgefüllt
; 09-0B	FTYP	Dateityp, mit Leerzeichen aufgefüllt
; 0C	PSUM
; 0D	ARB (?)
; 0E	BLNR
; 0F	LBLNR
; 10
; 11
; 12-13	AADR
; 14-15	EADR
; 16-17	SADR
; 18	SBY

CONBU		equ	0080h		; Eingabepuffer


; Systemzellen

IOBYT		equ	0004h		; I/O-Byte zur Zuweisung log.Gerät phy. Gerät
SPSV		equ	000Bh		; Register für aktuellen Steck bei Eintritt in BOS
BCSV		equ	000Dh		; Register für BC bei Eintritt in BOS
ASV		equ	000Fh		; Register für A bei Eintritt in BOS
JOYR		equ	0013h		; Datenpuffer für Spielbebel 1
JOYL		equ	0014h		; Datenpuffer für Spielhebel 2
LISW		equ	0015h		; Schalter für Hardcopy. 0 kein Copy, 1 Copy
BSW		equ	0016h		; Schalter für Kontrollton. 0 kein Kontrollton, 1 Kontrollton
COLSW		equ	0017h		; Merkzelle für Farbsteuercode
DMA		equ	001Bh		; Zeiger auf Puffer für Kassetten-E/A
HOUR		equ	001Dh		; Puffer für Stunden
MIN		equ	001Eh		; Puffer für Minuten
SEC		equ	001Fh		; Puffer für Sekunden
COUNT		equ	0023h		; Zähler zur Tastaturentprellung und REPEAT-Funktion der Tastatur
LAKEY		equ	0024h		; Merkzelle für letztes gültiges Zeichen von Tastatur
KEYBU		equ	0025h		; Tastaturpuffer
SHLOC		equ	0026h		; Schalter für SHIFT LOCK. 0 kein SHIFT LOCK, 1 SHIFT LOCK
ATRIB		equ	0027h		; aktuelles Farbattribut
CHARP		equ	002Bh		; aktuelle Spalte d. Cursors(1-40)
LINEP		equ	002Ch		; aktuelle Zeile d. Cursors(1-24)
CURS		equ	002Dh		; aktuelle physische Adresse des Cursors
PU		equ	002Fh		; Hilfszelle
WORKA		equ	0033h		; Hilfszelle
BUFFA		equ	0034h		; Puffer für das Attribut des von Cursor überlagerten Zeichens
BU		equ	0035h		; Hilfszelle
EOR		equ	0036h		; Zeiger auf letzte für Anwender freie Adresse
P1ROL		equ	003Bh		; 1. rollende Zeile - 1
P2ROL		equ	003Ch		; letzte zu rollende Zeile + 1
P3ROL		equ	003Dh		; 1. zu rollende Spalte - 1
P4ROL		equ	003Eh		; letzte zu rollende Spalte + 1
BUFF		equ	003Fh		; Puffer für das vom Cursor überschriebene Zeichen
PARBU		equ	0040h		; Hilfszelle zur Paramterpufferung
FCB		equ	005Ch		; Dateikontrollblock
FNAME		equ	005Ch		; Dateiname 8 Zeichen
FTYP		equ	0064h		; Dateityp 3 Zeichen
PSUM		equ	0069h		; Prüfsumme eines Datenblockes
ARB		equ	006Ah		; Hilfszelle für Kassettentreiber
BLNR		equ	006Bh		; Blocknummer
LBLNR		equ	006Ch		; gesuchte Blocknummer bei Lesen
AADR		equ	006Dh		; Dateianfangsadresse
EADR		equ	006Fh		; Dateiendeadresse
SADR		equ	0071h		; Startadresse, wenn Datei ein Maschinencodeprogramm ist
SBY		equ	0073h		; Schutzbyte. 0 nicht geschützt, 1 geschützt
CONBU		equ	0080h		; CCP-Eingabepuffer und Standardpuffer für Kassetten-E/A
INTLN		equ	0100h		; interner Zeichenkettenpuffer


;-----------------------------------------------------------------------------
; I/O
;-----------------------------------------------------------------------------

CTC0		equ	80h		; System CTC0 Kassette, Beeper
CTC1		equ	81h		; System CTC1 Anwenderport
CTC2		equ	82h		; System CTC2 Systemuhr
CTC3		equ	83h		; System CTC3 Systemuhr

PIO1AD		EQU	88H		; PIO1 A Daten Beeper, Border, 20Z
PIO1BD		EQU	89H		; PIO1 B Daten Anwenderport
PIO1AS		EQU	8AH		; PIO1 A Kommando
PIO1BS		EQU	8BH		; PIO1 B Kommando Anwenderport

PIO2AD		EQU	90H		; Tastatur-PIO2 A Daten
PIO2BD		EQU	91H		; Tastatur-PIO2 B Daten
PIO2AS		EQU	92H		; Tastatur-PIO2 A Kommando
PIO2BS		EQU	93H		; Tastatur-PIO2 B Kommando

;-----------------------------------------------------------------------------
; AS-Funktionen
;-----------------------------------------------------------------------------

; obere 8 Bit: hi(CONBU)
hi              function x,(x>>8)&255

; untere 8 Bit: lo(CONBU)
lo              function x, x&255

;nächste ..00h Grenze: org nextpage($)
nextpage	function x, ((x+0ffh)/100h)*100h

;align-Ersatz: db zalign(80h) dup (?)
zalign		function x, ((($+x-1)/x)*x - $)
