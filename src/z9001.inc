;-----------------------------------------------------------------------------
; Arbeitsspeicher 
;-----------------------------------------------------------------------------

IOBYT		equ	0004h		; IO-Byte (in SIO)
LISW		equ	0015h		; Schalter f�r Hardcopy (in SIO)

fcb1		equ	005Ch
fcb2		equ	006Ch
; Aufbau FCB
; 00	FDRIVE	Laufwerkscode (keins - 0, A - 1, B - 2)
; 01-08	FNAME	Dateiname, mit Leerzeichen aufgef�llt
; 09-0B	FTYP	Dateityp, mit Leerzeichen aufgef�llt
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

IOBYT		equ	0004h		; I/O-Byte zur Zuweisung log.Ger�t phy. Ger�t
SPSV		equ	000Bh		; Register f�r aktuellen Steck bei Eintritt in BOS
BCSV		equ	000Dh		; Register f�r BC bei Eintritt in BOS
ASV		equ	000Fh		; Register f�r A bei Eintritt in BOS
JOYR		equ	0013h		; Datenpuffer f�r Spielbebel 1
JOYL		equ	0014h		; Datenpuffer f�r Spielhebel 2
LISW		equ	0015h		; Schalter f�r Hardcopy. 0 kein Copy, 1 Copy
BSW		equ	0016h		; Schalter f�r Kontrollton. 0 kein Kontrollton, 1 Kontrollton
COLSW		equ	0017h		; Merkzelle f�r Farbsteuercode
DMA		equ	001Bh		; Zeiger auf Puffer f�r Kassetten-E/A
HOUR		equ	001Dh		; Puffer f�r Stunden
MIN		equ	001Eh		; Puffer f�r Minuten
SEC		equ	001Fh		; Puffer f�r Sekunden
COUNT		equ	0023h		; Z�hler zur Tastaturentprellung und REPEAT-Funktion der Tastatur
LAKEY		equ	0024h		; Merkzelle f�r letztes g�ltiges Zeichen von Tastatur
KEYBU		equ	0025h		; Tastaturpuffer
SHLOC		equ	0026h		; Schalter f�r SHIFT LOCK. 0 kein SHIFT LOCK, 1 SHIFT LOCK
ATRIB		equ	0027h		; aktuelles Farbattribut
CHARP		equ	002Bh		; aktuelle Spalte d. Cursors(1-40)
LINEP		equ	002Ch		; aktuelle Zeile d. Cursors(1-24)
CURS		equ	002Dh		; aktuelle physische Adresse des Cursors
PU		equ	002Fh		; Hilfszelle
WORKA		equ	0033h		; Hilfszelle
BUFFA		equ	0034h		; Puffer f�r das Attribut des von Cursor �berlagerten Zeichens
BU		equ	0035h		; Hilfszelle
EOR		equ	0036h		; Zeiger auf letzte f�r Anwender freie Adresse
P1ROL		equ	003Bh		; 1. rollende Zeile - 1
P2ROL		equ	003Ch		; letzte zu rollende Zeile + 1
P3ROL		equ	003Dh		; 1. zu rollende Spalte - 1
P4ROL		equ	003Eh		; letzte zu rollende Spalte + 1
BUFF		equ	003Fh		; Puffer f�r das vom Cursor �berschriebene Zeichen
PARBU		equ	0040h		; Hilfszelle zur Paramterpufferung
FCB		equ	005Ch		; Dateikontrollblock
FNAME		equ	005Ch		; Dateiname 8 Zeichen
FTYP		equ	0064h		; Dateityp 3 Zeichen
PSUM		equ	0069h		; Pr�fsumme eines Datenblockes
ARB		equ	006Ah		; Hilfszelle f�r Kassettentreiber
BLNR		equ	006Bh		; Blocknummer
LBLNR		equ	006Ch		; gesuchte Blocknummer bei Lesen
AADR		equ	006Dh		; Dateianfangsadresse
EADR		equ	006Fh		; Dateiendeadresse
SADR		equ	0071h		; Startadresse, wenn Datei ein Maschinencodeprogramm ist
SBY		equ	0073h		; Schutzbyte. 0 nicht gesch�tzt, 1 gesch�tzt
CONBU		equ	0080h		; CCP-Eingabepuffer und Standardpuffer f�r Kassetten-E/A
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

;n�chste ..00h Grenze: org nextpage($)
nextpage	function x, ((x+0ffh)/100h)*100h

;align-Ersatz: db zalign(80h) dup (?)
zalign		function x, ((($+x-1)/x)*x - $)
