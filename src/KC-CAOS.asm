	cpu	z80

;  **********************************
;  ***  BETRIEBSSYSTEM F]R KC 87  ***
;  ***  VERSION 3.1 , vp080331    ***
;  ***  DIRK AMBRAS , 01.07.1988  ***
;  **********************************
;
	ORG	08000H

CAOS:	JP	START
	DB	"#       "
	DB	0

BSST:	EQU	CAOS-00100H
JPM:	EQU	BSST+000FFH	; =0BBH: Systemerweiterung inaktiv, = EEH: Warmstart
AME:	EQU	BSST
HLM:	EQU	AME+1		; Merkzelle HL für UP, Parameter 1
DEM:	EQU	AME+3		; Merkzelle DE für UP, Parameter 2
BCM:	EQU	AME+5		; Merkzelle BC für UP, Parameter 3
MEMA:	EQU	AME+16		; Merkzelle A
MEMHL:	EQU	AME+17		; Merkzelle HL
MEMDE:	EQU	AME+19		; Merkzelle DE
MESC:	EQU	AME+21		; Merke ESC, 0: kein ESC-Modus, 20H: ESC-Modus
SPM:	EQU	AME+22		; Merkzelle SP
SCUR:	EQU	AME+24		; Symbol f. Cursor
FMHL:	EQU	AME+26
FLAG:	EQU	AME+30		; 0: im OS, 1: im BASIC-Modus
FFLAG:	EQU	AME+31
KEYTA:	EQU	AME+33
;Teil2
EKEY:	EQU	AME+000F8H	; + 248

COL:	EQU	00027H		; aktuelles Farbattribut
CCOL:	EQU	00034H		; Puffer für das Attribut des von Cursor überlagerten Zeichens
MCUR:	EQU	0003FH		; Puffer für das vom Cursor überschriebene Zeichen
;
;   VERBINDUNGEN ZUM 2.TEIL
;
;SWIT:	EQU	CAOS+00AA4H
;KEY:	EQU	CAOS+00AF1H
;SAVE:	EQU	CAOS+00B86H
;VERIF:	EQU	CAOS+00C3BH
;LOAD:	EQU	CAOS+00C3FH
;
;
;**********************************
;* Sprungverteiler (#-Kdo steht oben !!!)
;**********************************

	JP	SWIT
	DB	"SWITCH  "
	DB	0
	JP	JUMP
	DB	"JUMP    "
	DB	0
	JP	MENU
	DB	"MENU    "
	DB	0
	JP	SAVE
	DB	"SAVE    "
	DB	0
	JP	VERIF
	DB	"VERIFY  "
	DB	0
	JP	LOAD
	DB	"LOAD    "
	DB	0
	JP	COLOR
	DB	"COLOR   "
	DB	0
	JP	MODIF
	DB	"MODIFY  "
	DB	0
	JP	DISP
	DB	"DISPLAY "
	DB	0
	JP	KEY
	DB	"KEY     "
	DB	0
	JP	KEYLI
	DB	"KEYLIST "
	DB	0
	JP	UPIN
	DB	"in      "
	DB	0
	JP	UPOUT
	DB	"out     "
	DB	0
	JP	WRITE
	DB	"write   "
	DB	0
	JP	TIME0
	DB	"time    "
	DB	0
	JP	VCOL
	DB	"vcolor  "
	DB	0
	JP	LDIR
	DB	"ldir    "
	DB	0
	JP	GOTO
	DB	"go      "
	DW	0
;
TEXTM:	DB	"*  KC-CAOS "
	DB	"3.1  *"
CRL:	DB	10
	DB	13
	DB	"%"
	DB	0

RESET:	DB	" (C) 89 D. "
	DB	"Ambras     "
	DB	"J.Techniker "
	DB	"HA-NEU"
CRL2:	DW	00D0AH
	DB	0
;

;
;**********************************
; Monitorerweiterung '#'
; Initialisierung
;**********************************
;
START:	LD	HL,JPM
	LD	A,(HL)
	CP	0BBH		; Erweiterung inaktiv?
	JP	Z,0F089H	; JPM = 0BBh -> Sprung ins OS, GOCPM
;
	LD	SP,001FEH
	LD	(SPM),SP
	CALL	COPYR		; neuen Unterprogrammverteiler für CALL 5 einrichten
;
	CP	0EEH		; JPM = 0EEh -> Warmstart
	JR	Z,WST
;
	LD	HL,BSST		; Arbeitsspeicherbereich
	PUSH	HL
	POP	DE
	INC	DE
	LD	(HL),0
	LD	BC,255
	LDIR			; leeren
;
	LD	DE,KEYTA
	LD	HL,MKEY
	LD	BC,92		; KEYLI-MKEY Länge der Liste
	LDIR
	LD	A,0F9H		; Cursorzeichen (Unterstich)
	LD	(SCUR),A	; festlegen
;
WST:	LD	A,046H		; blau auf cyan
	LD	(COL),A		; aktuelles Farbattribut setzen

	LD	A,030H
	LD	(0EFC8H),A	; E000-EFFF,F000-FFFF als ROM deklarieren

	LD	A,020H
	LD	(MCUR),A	; aktuelles Zeichen unter Cursor

	LD	A,010H		; Randfarbe Grün
	OUT	(088H),A	; setzen
;
	CALL	CLS
	LD	DE,RESET	; Copyright-Meldung
	CALL	PRNST
	LD	A,0
	LD	(MESC),A	; kein ESCAPE gedrückt
	JR	MENU2		; Menü anzeigen

;**********************************
;* Aufruf des Grundmenüs
;**********************************

MENU:	LD	SP,001FEH
	LD	(SPM),SP
	CALL	COPYR		; neuen Unterprogrammverteiler für CALL 5 einrichten
	CALL	CLS
MENU2:	LD	DE,TEXTM	; "KC-Caos 3.1"
	CALL	PRNST
	LD	A,0EEH
	LD	(JPM),A		; Warmstart merken
SUCH:	LD	H,0C0H		; Suche von 0C000h aufwärts
	LD	D,0F0H		; bis 0F000h
	CALL	SUCH2
	LD	HL,CAOS		; Suche von CAOS bis RESET
	LD	DE,RESET
	CALL	SUCH2
	LD	H,2		; Suche von 200h bis CAOS
	LD	DE,CAOS
	DEC	D
	DEC	D
	CALL	SUCH2
	LD	HL,LOAD		; suche von LOAD bis BF00h
	LD	D,0BFH
	CALL	SUCH2
	JP	INPUT		; Zeicheneingabe+Ausgabe abschließendes ENTER
;
SUCH2:	LD	L,0		; Suche an ..00h-Grenze
SUCH3:	PUSH	HL
;
SUCH4:	LD	A,(HL)
	CP	0C3H
	JR	NZ,SUCH6
	INC	HL
	INC	HL
	INC	HL
	PUSH	HL
	LD	A,(HL)
	CP	"#"
	JR	Z,SUCH5		; System-Erweiterung übergehen
	CP	028H
	JR	C,FO02		; Prg.mame beginnt mit Sonderzeichen
	CP	"\\"
	JR	NC,FO02		; Prg.mame beginnt mit Kleinbuchstaben
	PUSH	DE
	LD	D,H
	LD	E,L
	CALL	PRNST		; sonst Namen ausgeben
	POP	DE
SUCH5:	POP	HL
	PUSH	DE
	LD	DE,9
	ADD	HL,DE
	LD	DE,CRL
	CALL	PRNST
	POP	DE
	JR	SUCH4
;
SUCH6:	POP	HL
	LD	A,H
	INC	H
	CP	D
	JR	NZ,SUCH2
	RET
;nächste Suchposition
FO02:	POP	HL
	PUSH	DE
	LD	DE,9
	ADD	HL,DE
	POP	DE
	JR	SUCH4

;**********************************
; transportiert Speicherbereiche im Rechner
; Format: ldir Quelladresse Zieladresse Länge
;**********************************

LDIR:	LDIR
	RET

;**********************************
; Start eines Maschinenprogrammes auf der angegebenen Startadresse
; Format: go Startadresse
;**********************************

GOTO:	JP	(HL)


; schnelles Fensterlöschen
; über Srungverteiler eingebunden für ^C
;
CLS:	LD	A,(0003BH)	; 1. rollende Zeile - 1
	LD	D,A
CLS3:	LD	A,(0003CH)	; letzte zu rollende Zeile + 1
	SUB	D
	DEC	A
	LD	B,A
	CALL	CLS1
CLS2:	INC	D
	PUSH	DE
	PUSH	BC
	LD	(0002BH),DE	; aktuelle Spalte d. Cursors
	CALL	CLLN
	POP	BC
	POP	DE
	DJNZ	CLS2
;
CLS1:	LD	A,(0003BH)	; 1. rollende Zeile - 1
	INC	A
	PUSH	DE
	PUSH	BC
	LD	D,A
	LD	A,(0003DH)	; 1. zu rollende Spalte - 1
	INC	A
	LD	E,A
	LD	C,18		; SETCU 	Setzen logische Cursoradresse
	CALL	0F314H		; OS: BOS
	POP	BC
	POP	DE
	LD	A,020H
	LD	(MCUR),A	; aktuelles Zeichen unter Cursor
	RET

; Zeichenausgabe E
DRUCK:	PUSH	AF
	LD	A,E
	CP	32
	JR	NC,DRBS		; normales Zeichen
	PUSH	BC
	LD	C,2		; Sonderzeichen auseben über
	CALL	VKEY		; neuen Unterprogrammverteiler für CALL 5
	POP	BC
	POP	AF
	RET
; Druck Bildschirm
DRBS:	PUSH	HL
	PUSH	DE
	PUSH	AF
	LD	A,E
	CALL	GETHL		; Ermitteln aktuelle Cursorposition
	LD	(HL),A
	LD	A,(COL)		; aktuelles Farbattribut
	SET	3,A		;
	LD	(CCOL),A	; aktuelles Farbattribut Zeichen unter Cursor
	LD	E,9		; Cursor nach rechts
	CALL	DRUCK		; Zeichenausgabe E
	POP	AF
	POP	DE
	POP	HL
	POP	AF
	RET

; Ausgabe Zeichenkette ab (DE)
PRNST:	LD	A,(DE)
	OR	A
	RET	Z
	PUSH	DE
	LD	E,A
	CALL	DRUCK		; Zeichenausgabe E
	POP	DE
	INC	DE
	JR	PRNST

; Zeicheneingabe+Ausgabe abschließendes ENTER
INPUT:	XOR	A
	LD	(FLAG),A	; kein BASIC-Modus
	CALL	INLIN
	JR	ENT		; Ausgabe ENTER

; Eingabe einer Zeile, Abschluß mit ENTER
INLIN:	CALL	COPYR		; neuen Unterprogrammverteiler für CALL 5 einrichten
	LD	C,1		; CONSI
	CALL	5
	JR	INL2

; Reset Cursor
RESC:	CALL	GETCU		; Ermitteln aktuelle Cursorposition BC
	LD	(MEMDE),BC
	LD	A,(MCUR)	; aktuelles Zeichen unter Cursor
	LD	(BC),A
	RET

;
INL2:	LD	E,A
	PUSH	AF
	CALL	DRUCK		; Zeichenausgabe E
	CP	4		; ^D
	JR	NZ,NO4
	LD	A,(FFLAG)
	AND	A
	JR	Z,NO4
	POP	AF
	LD	E,2
	CALL	DRUCK		; Zeichenausgabe E
	LD	A,2
	RET
;
NO4:	POP	AF
	CP	13		; <ENTER>
	JR	Z,IN1
	CP	3		; <STOP>
	JR	Z,IN1
	JR	INLIN		; Eingabe einer Zeile, Abschluß mit ENTER
;
IN1:	LD	E,10		; Parallelausgabe auf LIST (^P)
	CALL	DRUCK		; Zeichenausgabe E
	LD	E,11		; Kontrollton EIN/AUS (^Q)
	CALL	DRUCK		; Zeichenausgabe E
	CALL	GETCU		; Ermitteln aktuelle Cursorposition BC
	PUSH	BC
	LD	E,10		; Parallelausgabe auf LIST (^P)
	CALL	DRUCK		; Zeichenausgabe E
	POP	DE
	RET

; Set Cursor
SETC:	LD	A,030H
	LD	(0EFC8H),A	; E000-EFFF,F000-FFFF als ROM deklarieren
	CALL	GETCU		; Ermitteln aktuelle Cursorposition BC
	LD	A,(BC)
	LD	(MCUR),A	; aktuelles Zeichen unter Cursor
	LD	A,(SCUR)	; Symbol f. Cursor
	CP	020H
	RET	C
	LD	(BC),A
	LD	HL,0FC00H	; -400H
	ADD	HL,BC
	LD	A,(CCOL)	; aktuelles Farbattribut Zeichen unter Cursor
	LD	(HL),A
	RET

; Ausgabe ENTER
ENT:	CP	3		; <STOP> ?
	JR	NZ,NO3
	LD	E,13		; <ENTER> ?
	CALL	DRUCK		; Zeichenausgabe E
	JP	RET

NO3:	INC	DE
	LD	A,(DE)
	CP	021H
	JP	C,RET
	LD	HL,CAOS
	LD	B,0F0H
	CALL	PSUCH
	JR	C,PROG
	LD	H,2
	LD	BC,CAOS
	DEC	B
	DEC	B
	CALL	PSUCH
	JR	C,PROG
	LD	E,"F"
	CALL	DRUCK		; Zeichenausgabe E
	JP	ERROR

PROG:	INC	DE
	PUSH	HL
	LD	A,(DE)
	CP	021H
	JR	C,NPARA
	DEC	DE
	JR	PARA

NPARA:	LD	A,0
	LD	(AME),A
	JP	GPARA

PARA:	LD	A,0
	LD	(AME),A
	PUSH	DE
	LD	DE,HLM
	LD	(MEMDE),DE
	POP	DE
	INC	DE
PARA1:	CALL	RHEX		; (DE) ff. als Hexzahl konvertieren
	JR	NC,PARA2
	LD	E,"P"
	CALL	DRUCK		; Zeichenausgabe E
	JP	ERROR

PARA2:	PUSH	DE
	LD	HL,(MEMDE)
	LD	DE,(MEMHL)
	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	LD	(MEMDE),HL
	LD	A,(AME)
	INC	A
	CP	11
	LD	(AME),A
	POP	DE
	JP	NC,GPARA
	INC	DE
	LD	A,(DE)
	CP	020H
	JR	NZ,PARA1
	JR	GPARA


; (DE) ff. als Hexzahl konvertieren
RHEX:	LD	HL,0
	LD	(MEMHL),HL
	XOR	A
	LD	HL,MEMA
	LD	(HL),A
RHEX1:	LD	A,(DE)
	CP	021H
	JR	C,NOTC
	JR	RHEX2
;
NOTC:	SCF
	CCF
	NOP
	NOP
	NOP
	RET
;
RHEX2:	SUB	030H
	RET	C
	CP	10
	JR	C,RH3
	SUB	7
	CP	10
	RET	C
	CP	16
	JR	C,RH3
	SCF
	RET
;
RH3:	INC	DE
	INC	(HL)
	INC	HL
	RLD
	INC	HL
	RLD
	DEC	HL
	DEC	HL
	JR	Z,RHEX1
	DEC	DE
	SCF
	RET

;
GPARA:	POP	HL
	LD	DE,RET
	PUSH	DE
	PUSH	HL
	LD	HL,(HLM)
	LD	DE,(DEM)
	LD	BC,(BCM)
	LD	A,(AME)
GJP:	RET
;
RET:	LD	SP,001FEH
	LD	(SPM),SP
	LD	E,"%"
	CALL	DRUCK		; Zeichenausgabe E
	CALL	COPYR		; neuen Unterprogrammverteiler für CALL 5 einrichten
	JP	INPUT		; Zeicheneingabe+Ausgabe abschließendes ENTER

; Programmsuche
PSUCH:	INC	B
	PUSH	DE
	LD	(MEMDE),DE
PSV:	LD	L,0
PS1:	PUSH	HL
PS2:	LD	A,(HL)
	CP	0C3H
	JR	NZ,PS4
	INC	HL
	INC	HL
	INC	HL
	PUSH	HL
	PUSH	DE
	PUSH	BC
	LD	DE,(MEMDE)
PSF:	LD	A,(DE)
	CP	021H
	JR	C,FOU
	CP	(HL)
	JR	NZ,NFOU
	INC	HL
	INC	DE
	JR	PSF

; nicht gefunden
NFOU:	POP	BC
	POP	DE
	POP	HL
	PUSH	DE
	LD	DE,9
	ADD	HL,DE
	POP	DE
	LD	DE,(MEMDE)
	JR	PS2

PS4:	POP	HL
	INC	H
	LD	A,H
	CP	B
	JR	C,PSV
	SCF
	CCF
	POP	DE
	LD	DE,(MEMDE)
	RET

; gefunden
FOU:	POP	BC
	POP	BC
	POP	HL
	DEC	HL
	LD	B,(HL)
	DEC	HL
	LD	C,(HL)
	PUSH	BC
	POP	HL
	POP	BC
	POP	BC
	SCF
	RET

; Fehlermeldung
ERRM:	DB	" ERROR"
	DW	00A0DH
	DW	00007H

; Fehler
ERROR:	CALL	ERR1		; Ausgabe " FEHLER"
	JR	RET

; Ausgabe " FEHLER"
ERR1:	PUSH	DE
	LD	DE,ERRM
	CALL	PRNST
	POP	DE
CAOSE:	RET


;**********************************
; Systemerweiterung inaktiv schalten
;**********************************

JUMP:	LD	A,0BBH
	LD	(JPM),A
	LD	HL,0F314H	; OS: BOS
	LD	(6),HL
	JP	0F089H		; OS: GOCPM

;**********************************
; stellt ab dem nächsten Zeichen die gewählte Farbkombination ein.
; Format: COLOR Vordergrundfarbe Hintergrundfarbe
;**********************************

COLOR:	LD	A,L
	DEC	A
	SLA	A
	SLA	A
	SLA	A
	SLA	A
	PUSH	AF
	LD	A,E
	POP	BC
	DEC	A
	OR	B
	LD	(COL),A
	RET

; A hexadezimal ausgeben
AHEX:	PUSH	AF
	PUSH	AF
	RRA
	RRA
	RRA
	RRA
	CALL	AHEX2
	POP	AF
	CALL	AHEX2
	POP	AF
	RET
;
AHEX2:	AND	00FH
	ADD	A,030H
	CP	03AH
	JR	C,ADR
	ADD	A,007H
ADR:	PUSH	DE
	LD	E,A
	CALL	DRUCK		; Zeichenausgabe E
	POP	DE
	RET

;HL hexadezimal + Leerzeichen ausgeben
HLHEX:	PUSH	AF
	PUSH	DE
	LD	A,H
	CALL	AHEX		; A hexadezimal ausgeben
	LD	A,L
	CALL	AHEX		; A hexadezimal ausgeben
	LD	E,020H
	CALL	DRUCK		; Zeichenausgabe E
	POP	DE
	POP	AF
	RET

;**********************************
; Beschreiben (modifizieren) von Speicherzellen
; Format: MODIPY Anfangsadreese
; Der angezeigte hexadezimale Wert der Speicherzelle kann auf diese
; Weise geändert werden. Gleichfalls ist die Eingabe eines ASCII-Zei-
; chens mit vorlaufendem Komma möglich. Nach einem Schrägstrich kann-
; ein anderer Speicherbereich gewählt werden.
; Durch die Eingabe des Punktes wird dieser Modus abgebrochen.
;**********************************

MTEXT:	DB	020H
	DW	00808H
	DW	00008H

MODIF:	CALL	HLHEX		; HL hexadezimal + Leerzeichen ausgeben
	LD	(HLM),HL
	LD	A,0
	LD	(AME),A
	LD	A,(HL)
	CALL	AHEX		; A hexadezimal ausgeben
	LD	DE,MTEXT
	CALL	PRNST
	CALL	INLIN		; Eingabe einer Zeile, Abschluß mit ENTER
	CALL	RHEX		; (DE) ff. als Hexzahl konvertieren
	JR	NC,RIG1
MERR:	CALL	ERR1		; Ausgabe " FEHLER"
	LD	HL,(HLM)
	JR	MODIF

RIG1:	LD	A,(HL)
	JR	Z,MERR
	LD	HL,MEMHL
	PUSH	DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	POP	DE
	LD	B,0
MSUCH:	PUSH	HL
	INC	DE
	CALL	RHEX		; (DE) ff. als Hexzahl konvertieren
	LD	A,(HL)
	OR	A
	JR	Z,EZ1
	INC	HL
	LD	A,(HL)
	POP	HL
MSET:	LD	(HL),A
	INC	B
	INC	HL
	LD	A,0
	LD	(AME),A
	PUSH	HL
EZ1:	POP	HL
	LD	A,(DE)
	CP	'.'		; Abbrechen ?
	RET	Z
	CP	','		; ASCII-Eingabe folgt
	JR	NZ,EZ2
	INC	DE
	LD	A,(DE)		; ASCII-Zeichen
	INC	DE
	JR	MSET

EZ2:	LD	A,B
	OR	A
	JR	NZ,EZ3
	INC	HL
EZ3:	LD	A,(DE)
	CP	':'
	JR	NZ,EZ4
	DEC	HL
	DEC	HL
	JR	MODIF
EZ4:	CP	'/'		; neuer Speicherbereich?
	JR	NZ,EZ5
	INC	DE
	CALL	RHEX		; (DE) ff. als Hexzahl konvertieren
	JR	C,MERR
	LD	HL,(MEMHL)
	JR	MODIF

EZ5:	CP	020H
	JR	NZ,MERR
	LD	A,(AME)
	INC	A
	LD	(AME),A
	CP	2
	JR	C,MSUCH
	JP	MODIF

;**********************************
; Anzeige beliebiger Speicherbereiche des Rechners
; Format: DISPLAY Anfangsadresse Endadresse
; Es werden jeweils 8 Byte hexadezimal mit den entsprechenden ASCII-
; Code angezeigt. Mit einer beliebigen Taste wird weitergeblättert.
; Durch Drücken der RUN-Taste wird in den MODIFY-Modus übergegangen.
; Mit der STOP-Taste kann die Speicheranzeige abgebrochen werden.
;**********************************

DISP:	CP	3
	JR	NC,SWJ
	LD	C,8
SWJ:	PUSH	BC
DISP2:	CALL	HLHEX		; HL hexadezimal + Leerzeichen ausgeben
	PUSH	HL
	LD	B,8
DIS2:	LD	A,(HL)
	CALL	AHEX		; A hexadezimal ausgeben
	DEC	B
	JR	Z,BEDZ
	PUSH	DE
	LD	E,020H
	CALL	DRUCK		; Zeichenausgabe E
	POP	DE
	INC	HL
	JR	DIS2
;
BEDZ:	PUSH	DE
	LD	E,32
	CALL	DRUCK		; Zeichenausgabe E
	LD	E,32
	CALL	DRUCK		; Zeichenausgabe E
	POP	DE
	POP	HL
	LD	B,8
DZE1:	PUSH	DE
	LD	E,(HL)
	LD	A,E
	CP	020H
	JR	NC,DZE2
	LD	E,0F8H
DZE2:	CALL	DRUCK		; Zeichenausgabe E
	POP	DE
	INC	HL
	DJNZ	DZE1
	PUSH	DE
	LD	DE,CRL2
	CALL	PRNST
	POP	DE
	PUSH	DE
	EX	DE,HL
	SBC	HL,DE
	EX	DE,HL
	POP	DE
	JR	C,DIEND
	DEC	C
	JR	NZ,DISP2
	PUSH	BC
	LD	C,1		; CONSI
	CALL	5
	POP	BC
	CP	3		; <STOP>?
	POP	BC
	RET	Z
	CP	01DH		; <RUN>?
	JR	NZ,SWJ
	JP	MODIF
DIEND:	POP	BC
	RET

ESC:	LD	HL,FMHL
	DEC	HL
	LD	(HL),0


;------------------------------------------------------------------------------
;neuer Unterprogrammverteiler für CALL 5
;------------------------------------------------------------------------------

;neuen Unterprogrammverteiler für CALL 5 einrichten
COPYR:	LD	HL,VKEY
	LD	(6),HL
	RET

; neuer Unterprogrammverteiler für CALL 5
VKEY:	LD	(MEMA),A
	LD	A,C
	CP	2
	JR	Z,DRKEY		; Umleitung CONSO
	CP	1
	JR	Z,FTAST		; Umleitung CONSI
	CP	022H
	JP	NC,VERW		; C >= 22, d.h. nicht def. UP
VMON:	LD	A,(MEMA)
	JP	0F314H		; OS: BOS


DRBAS:	LD	A,(0002BH)	; aktuelle Spalte d. Cursors
	LD	D,A
	LD	A,(0003DH)	; 1. zu rollende Spalte - 1
	INC	A
	SUB	D
	OR	A
	JP	Z,NKEY		; dann Ende
	JP	NKEY2		; sonst Zeichenausgabe

; Umleitung System-Call 5 CONSO
; Ausgabe eines Zeichens zum aktuellen CONST-Gerät
DRKEY:	LD	A,(COL)
	SET	3,A
	LD	(COL),A
	LD	A,(MEMA)
	PUSH	HL
	PUSH	BC
	PUSH	DE
	LD	A,E
	CP	020H
	JP	C,STCOD		; wenn Steuerzeichen
	CP	">"
	JR	Z,DRBAS
	JR	NKEY2		; Zeichenausgabe

; Umleitung System-Call 5 CONSI
; Eingabe eines Zeichen vom aktuellen CONST-Gerät
FTAST:	LD	A,(MEMA)
	PUSH	HL
	PUSH	BC
	PUSH	DE
	LD	HL,FMHL
	DEC	HL
	LD	A,(HL)
	AND	A
	JP	NZ,FEND
	CALL	SETC		; Set Cursor
	POP	DE
	POP	BC
	POP	HL
	PUSH	HL
	PUSH	BC
	PUSH	DE
	CALL	0F314H		; OS: BOS
	PUSH	AF
	CALL	RESC		; Reset Cursor
	LD	A,(FLAG)	; BASIC-Modus?
	AND	A
	JR	Z,BNO		; nein
	LD	A,(FFLAG)
	AND	A
	JR	NZ,BNO
; BASIC ja	
BJA:	LD	A,1
	LD	(FFLAG),A
	POP	AF
	CP	13
	JR	NZ,NO13
	LD	E,10
	CALL	DRUCK		; Zeichenausgabe E
	JP	BASET

; kein Enter-Zeichen
NO13:	LD	E,A
	CALL	DRUCK		; Zeichenausgabe E
	CALL	INLIN		; Eingabe einer Zeile, Abschluß mit ENTER
	JP	BASET

;BASIC no
BNO:	LD	HL,NRKEY	; Tabelle der belegten Funktions-Tasten
	POP	AF
	PUSH	HL
	POP	DE
	LD	BC,10
	CPIR			; Taste suchen
	JP	Z,FKEY		; wenn gefunden
	JR	NKEY		; sonst Ende

; Zeichenausgabe
NKEY2:	POP	DE
	PUSH	DE
	LD	C,2		; CONSO
	CALL	0F314H		; OS: BOS
NKEY:	POP	DE
	POP	BC
	POP	HL
	RET

;**********************************

;Cursor runter
STDR:	LD	E,A
	LD	A,(0003CH)	; letzte zu rollende Zeile + 1
	DEC	A
	LD	B,A
	LD	A,(0002CH)	; aktuelle Zeile d. Cursors
	SUB	B
	JR	Z,SCUP
	JR	NKEY2		; Zeichenausgabe

SCUPT:	CALL	GETHL		; Ermitteln aktuelle Cursorposition
	LD	A,(CCOL)	; aktuelles Farbattribut Zeichen unter Cursor
	LD	DE,0FC00H	; -400H
	ADD	HL,DE
	LD	(HL),A
	LD	HL,0E828H	; Beginn 2. Zeile Farbspeicher
	LD	DE,0E800H	; Beginn 1. Zeile Farbspeicher
	LD	BC,920		; 23 * 40
	PUSH	BC
	LDIR
	LD	HL,0EC28H	; Beginn 2. Zeile BWS
	LD	DE,0EC00H	; Beginn 1. Zeile BWS
	POP	BC
	LDIR
	CALL	CLLN
	XOR	A
	JP	NKEY		; Ende

;Scroll up
SCUP:	LD	A,(0003BH)	; 1. rollende Zeile - 1
	CP	0
	JR	NZ,SCUPN
	LD	A,(0003CH)	; letzte zu rollende Zeile + 1
	CP	25
	JR	NZ,SCUPN
	LD	A,(0003DH)	; 1. zu rollende Spalte - 1
	CP	0
	JP	NZ,SCUPN
	LD	A,(0003EH)	; letzte zu rollende Spalte + 1
	CP	41
	JR	Z,SCUPT
SCUPN:	LD	C,2		; CONSO
	CALL	0F314H		; OS: BOS
	CALL	CLLN
	JP	NKEY		;Ende

; Ermitteln aktuelle Cursorposition BC
GETCU:	PUSH	HL
	CALL	GETHL		; Ermitteln aktuelle Cursorposition
	PUSH	HL
	POP	BC
	POP	HL
	RET

; Ermitteln aktuelle Cursorposition
GETHL:	PUSH	BC
	PUSH	AF
	LD	DE,40		; Länge Bildschirmzeile
	LD	HL,0EC00H	; Beginn BWS
	LD	A,(0002CH)	; aktuelle Zeile d. Cursors
	LD	B,A
GETZ:	ADD	HL,DE
	DJNZ	GETZ
	SBC	HL,DE
	LD	A,(0002BH)	; aktuelle Spalte d. Cursors
	DEC	A
	LD	E,A
	ADD	HL,DE
	LD	DE,(0002BH)	; aktuelle Spalte d. Cursors
	POP	AF
	POP	BC
	RET

BASET:	PUSH	AF
	XOR	A
	LD	(FFLAG),A
	LD	A,(0003DH)	; 1. zu rollende Spalte - 1
	INC	A
	LD	(0002BH),A	; aktuelle Spalte d. Cursors
	LD	E,11		; CTRL/Q	Kontrollton EIN/AUS
	LD	C,2		; CONSO
	CALL	0F314H		; OS: BOS
	LD	DE,00362H	; BASIC INPBUF+1, EINGABEPUFFER
	LD	B,046H		; = 70, max. Länge BASIC-Zeile
	PUSH	DE
LDBAS:	CALL	GETHL		; Ermitteln aktuelle Cursorposition
	POP	DE
	LD	A,(HL)
	CP	020H
	CALL	Z,ZLEER
	LD	(DE),A
	CP	0		; Zeilenende
	JR	Z,LDBE
	INC	DE
	LD	C,2		; CONSO
	PUSH	DE
	LD	E,9		; Cursor nach rechts
	PUSH	BC
	CALL	0F314H		; OS: BOS
	POP	BC
	DJNZ	LDBAS
	POP	DE
LDBE:	LD	A,(0003DH)	; 1. zu rollende Spalte - 1
	INC	A
	LD	(0002BH),A	; aktuelle Spalte d. Cursors
	INC	B
	INC	B
	INC	B
	XOR	A
LDB0:	LD	(DE),A
	INC	DE
	DJNZ	LDB0
	POP	AF
	JP	NKEY		; Ende

ZLEER:	LD	A,(CCOL)	; aktuelles Farbattribut Zeichen unter Cursor
	BIT	3,A
	JR	NZ,ZL1
ZL0:	XOR	A
	RET
;
ZL1:	LD	A,020H
	RET

; CONSO-Treiber: CTRL/D Aktivierung BASIC-Fullscreen-Editor
TFLAG:	LD	A,(00338H)	; Merkzelle vom BASIC (RNDVR3+xx)
	CP	0D6H		; Test auf ROM-BASIC
	JP	NZ,NKEY		; Ende
	LD	A,(FLAG)
	XOR	1		; BASIC-Modeus togglen
	LD	(FLAG),A
	JP	NKEY		; Ende

FEND:	LD	HL,(FMHL)
	INC	HL
; Ausgabe Funktionsstasten-String ab (HL)
KEYF:	LD	(FMHL),HL
	LD	A,(HL)
	OR	A
	CALL	Z,ESCC		; Ende erreicht (Nullbyte) -> ESC rücksetzen
	LD	A,(HL)
	LD	HL,FMHL
	DEC	HL
	LD	(HL),A
	JP	NKEY		; Ende

; CONSO-Treiber: ESC
EESC:	CALL	ESCC
	JP	NKEY2		; Zeichenausgabe

ESCC:	LD	A,(MESC)	; Escape-Tasten-Druck merken/löschen
	XOR	020H		; toggle Flag
	LD	(MESC),A
	XOR	A
	RET

FKEY:	PUSH	AF		; Funktions-Tasten ausführen
	LD	A,(MESC)
	CP	0
	JR	NZ,ME1		; nur wenn vorheriges Zeichen Escape war
ME0:	POP	AF
	JP	NKEY		; Ende
;
ME1:	POP	AF
	XOR	A
	SBC	HL,DE
	EX	DE,HL		; DE = Offset in Tabelle der belegten Funktions-Tasten
	LD	HL,KEYTA
	LD	BC,00100H
CPIR:	DEC	E
	JR	Z,KEYF		; wenn zugehörigen String gefunden
	CPIR			; suche Abschluss des Strings (A=0)
	JR	CPIR		; weitersuchen

;
NRKEY:	DB	"0"		; Tabelle der belegten ESC-Tasten
	DB	"1"
	DB	"2"
	DB	"3"
	DB	"4"
	DB	"5"
	DB	"6"
	DB	"7"
	DB	"8"
	DB	"9"

MKEY:	DB	2		; ESC 0: <CL LN>
	DB	"%B"		; Basic starten
	DB	13		; <ENTER>
	DB	"32500"		; max. Speichergröße
	DW	13		; <ENTER>
	DB	"GOSUB"
	DB	0
	DB	"PRINTAT("	; ESC 1
	DB	0
	DB	"RETURN"	; ESC 2
	DB	0
	DB	"WINDOW"	; ESC 3
	DB	0
	DB	"EDIT"		; ESC 4
	DB	0
	DB	"AUTO"		; ESC 5
	DB	0
	DB	"INK5:PAP"	; ESC 6
	DB	"ER7:BORD"
	DB	"ER3"
	DW	13
	DB	"WINDOW:"
	DB	"CLS"
	DW	13
	DB	2
	DB	"%t"
	DB	13
	DB	11
	DB	11
	DB	01BH
	DW	0

;**********************************
; Aufruf und Anzeige der aktuellen Punktionstastenbelegung auf den
; Bildschirm.
;**********************************

KEYLI:	LD	B,0
	LD	DE,KEYTA
KL2:	PUSH	DE
	LD	DE,KEYM1
	CALL	PRNST
	LD	A,B
	CALL	AHEX2
	LD	DE,KEYM2	; Doppelpunkt ausgeben
	CALL	PRNST
	POP	DE
	CALL	PRKEY
	LD	DE,(MEMDE)
	INC	DE
	INC	B
	PUSH	DE
	LD	DE,CRL2
	CALL	PRNST
	POP	DE
	LD	A,B
	CP	00AH
	JR	C,KL2
	RET

KEYM1:	DB	"KEY "
	DB	0
KEYM2:	DB	" : "
	DB	0

PRKEY:	PUSH	AF
	PUSH	DE
PRK1:	LD	A,(DE)
	CP	0
	JR	Z,PRK3
	PUSH	DE
	CP	020H
	JR	NC,PRK2
	LD	A,0FFH
PRK2:	LD	E,A
	CALL	DRUCK		; Zeichenausgabe E
	POP	DE
	INC	DE
	JR	PRK1
;
PRK3:	LD	(MEMDE),DE
	POP	DE
	POP	AF
	RET

; CONSO-Treiber: Steuercodes
STCOD:	CP	00AH		; Cursor runter
	JP	Z,STDR
	CP	01BH		; <ESC>
	JP	Z,EESC
	CP	01DH		; <RUN>		Backspace
	JR	Z,ST01
	CP	00CH		; CTRL/L	Bildschirm löschen
	JR	Z,ST0C
	CP	01AH		; <INS>
	JP	Z,ST1A
	CP	019H		; tab left, CTRL/Y
	JP	Z,ST19
	CP	018H		; tab right, CTRL/X
	JP	Z,ST18
	CP	002H		; <CL LN>
	JR	Z,ST02
	CP	01FH		; <DEL>
	JP	Z,ST1F
	CP	004H		; CTRL/D 	Aktivierung BASIC-Fullscreen-Editor
	JP	Z,TFLAG
STE0:	JP	NKEY2		; Zeichenausgabe
STE1:	JP	NKEY		; Ende

MST01:	DW	02008H
	DW	00008H

; CONSO-Treiber: RUN
ST01:	LD	DE,MST01
	CALL	PRNST		; Backspace-Funktion
	JR	STE1		; Ende

; CONSO-Treiber: CTRL/L
ST0C:	CALL	CLS
	JR	STE1		; Ende

; CONSO-Treiber: CLLN
ST02:	CALL	CLLN
	JR	STE1		; Ende

CLLN:	LD	A,(0003DH)	; 1. zu rollende Spalte - 1
	INC	A
	LD	(0002BH),A	; aktuelle Spalte d. Cursors := 0
	LD	A,(0003DH)	; 1. zu rollende Spalte - 1
	LD	B,A
	LD	A,(0003EH)	; letzte zu rollende Spalte + 1
	SUB	B
	DEC	A
	LD	B,A
CLL1:	CALL	GETHL		; Ermitteln aktuelle Cursorposition
	PUSH	HL
	LD	DE,0FC00H
	ADD	HL,DE
	PUSH	HL
	POP	DE
	POP	HL
CLL2:	LD	A,(COL)
	RES	3,A
	LD	(DE),A
	LD	(CCOL),A	; aktuelles Farbattribut Zeichen unter Cursor
	LD	A,32
	LD	(HL),A
	LD	(MCUR),A	; aktuelles Zeichen unter Cursor
	INC	HL
	INC	DE
	DJNZ	CLL2
	RET

;(toter Code)
ST0A:	PUSH	AF
	LD	A,(0003CH)	; letzte zu rollende Zeile + 1
	LD	B,A
	LD	A,(0002CH)	; aktuelle Zeile d. Cursors(1-24)
	CP	B
	JR	C,ESTC
	LD	C,2
	LD	E,00AH		; Cursor down ausgeben
	CALL	0F314H		; OS: BOS
	CALL	CLLN
ESTC:	POP	AF
	RET

;(toter Code)
ST0B:	PUSH	AF
	LD	A,(0003BH)	; 1. rollende Zeile - 1
	LD	B,A
	LD	A,(0002CH)	; aktuelle Zeile d. Cursors(1-24)
	CP	B
	JR	NC,ESTC
	LD	C,2		; CONSO
	LD	E,00BH		; cu up
	CALL	0F314H		; OS: BOS
	CALL	CLLN
	JR	ESTC

; CONSO-Treiber: tab right, CTRL/X
ST18:	LD	A,(0003EH)	; letzte zu rollende Spalte + 1
	DEC	A
	LD	(0002BH),A	; aktuelle Spalte d. Cursors(1-40)
	JP	STE1		; Ende

; CONSO-Treiber: tab left, CTRL/Y
ST19:	LD	A,(0003DH)	; 1. zu rollende Spalte - 1
	INC	A
	LD	(0002BH),A	; aktuelle Spalte d. Cursors(1-40)
	JP	STE1		; Ende

; CONSO-Treiber: INS
ST1A:	CALL	GETHL		; Ermitteln aktuelle Cursorposition
	LD	A,(0003EH)	; letzte zu rollende Spalte + 1
	DEC	A
	LD	B,A
	LD	A,40
	SUB	B
	LD	B,A
	LD	A,40
	SUB	B
	SUB	E
	PUSH	AF
	LD	B,A
	LD	A,(HL)
	LD	(HL),32
ST1A1:	INC	HL
	LD	E,(HL)
	LD	(HL),A
	LD	A,E
	DJNZ	ST1A1
	CALL	GETCU		; Ermitteln aktuelle Cursorposition BC
	POP	AF
	LD	HL,0FC00H
	ADD	HL,BC
	LD	B,A
	LD	C,(HL)
	LD	A,(COL)
	SET	3,A
	LD	(HL),A
	LD	A,C
ST1A2:	INC	HL
	LD	E,(HL)
	LD	(HL),A
	LD	A,E
	DJNZ	ST1A2
	XOR	A
	JP	STE1		; Ende

; CONSO-Treiber: DEL
ST1F:	CALL	GETCU		; Ermitteln aktuelle Cursorposition BC
	LD	A,(0003EH)	; letzte zu rollende Spalte + 1
	DEC	A
	LD	H,A
	LD	A,40
	SUB	H
	LD	H,A
	LD	A,40
	SUB	H
	SUB	E
	PUSH	AF
	LD	E,A
	PUSH	DE
	EX	DE,HL
	LD	H,0
	ADD	HL,BC
	EX	DE,HL
	LD	(MEMDE),DE
	POP	DE
	PUSH	BC
	POP	HL
	LD	D,0
	PUSH	DE
	POP	BC
	PUSH	HL
	POP	DE
	INC	HL
	LDIR
	LD	HL,(MEMDE)
	LD	(HL),32
	CALL	GETCU		; Ermitteln aktuelle Cursorposition BC
	LD	HL,0FC00H
	ADD	HL,BC
	PUSH	HL
	INC	HL
	LD	A,(HL)
	LD	(CCOL),A	; aktuelles Farbattribut Zeichen unter Cursor
	DEC	HL
	POP	BC
	POP	AF
	LD	E,A
	PUSH	DE
	EX	DE,HL
	LD	H,0
	ADD	HL,BC
	EX	DE,HL
	LD	(MEMDE),DE
	POP	DE
	PUSH	BC
	POP	HL
	LD	D,0
	PUSH	DE
	POP	BC
	PUSH	HL
	POP	DE
	INC	HL
	LDIR
	LD	HL,(MEMDE)
	LD	A,(COL)
	RES	3,A
	LD	(HL),A
	JP	STE1		; Ende

;**********************************
; Lesen eines Portes des Rechners
; Format: in Portadresse
; Der gelesene Wert wird auf dem Bildschirm ausgegeben.
;**********************************

UPIN:	LD	C,L
	IN	A,(C)
	CALL	AHEX		; A hexadezimal ausgeben
	CALL	CRNL
	RET

;**********************************
; schreiben eines Portes des Rechners
; Format: out Portadresse Wert
; Der vorgegebene Wert wird auf den Port mit der Adresse ausgegeben.
;**********************************

UPOUT:	LD	C,L
	LD	A,E
	OUT	(C),A
	RET

;**********************************
;* Kdo time
;**********************************

TIME0:	OR	A
	JR	NZ,STIME	; Parameter folgen -> Zeit setzen
GTIME:	LD	A,(0001DH)	; Puffer für Stunden
	CALL	DRDEZ
	LD	E,':'
	CALL	DRUCK		; Zeichenausgabe E
	LD	A,(0001EH)	; Puffer für Minuten
	CALL	DRDEZ
	LD	E,':'
	CALL	DRUCK		; Zeichenausgabe E
	LD	A,(0001FH)	; Puffer für Sekunden
	CALL	DRDEZ
CRNL:	PUSH	DE
	LD	DE,CRL2
	CALL	PRNST
	POP	DE
	RET

DEHE:	CP	060H
	JR	C,MSJ
MSN:	XOR	A
	RET

MSJ:	LD	B,A
	SRL	B
	SRL	B
	SRL	B
	SRL	B
	INC	B
	LD	E,A
	XOR	A
ZAB:	ADD	A,10
	DJNZ	ZAB
	SUB	10
	LD	C,A
	LD	HL,MEMHL
	LD	(HL),E
	XOR	A
	RRD
	CP	10
	JR	NC,MSN
	LD	B,A
ZBC:	INC	C
	DJNZ	ZBC
	LD	A,C
	RET

; Zeit setzen
STIME:	LD	A,L
	LD	D,E
	LD	E,C
	CP	24
	JR	C,ST1
	XOR	A
ST1:	PUSH	DE
	CALL	DEHE
	LD	(0001DH),A	; Puffer für Stunden
	POP	DE
	LD	A,D
	PUSH	DE
	CALL	DEHE
	LD	(0001EH),A	; Puffer für Minuten
	POP	DE
	LD	A,E
	CALL	DEHE
	LD	(0001FH),A	; Puffer für Sekunden
	RET

; Anzeige A dezimal
DRDEZ:	INC	A
	CP	60
	JR	NZ,DRDW
	LD	A,059H
	JR	DEZ2
DRDW:	LD	H,0
	LD	L,A
	LD	C,0
	LD	DE,10
DEZ1:	INC	C
	SBC	HL,DE
	JR	NC,DEZ1
	ADD	HL,DE
	DEC	C
	SLA	C
	SLA	C
	SLA	C
	SLA	C
	LD	A,C
	OR	L
DEZ2:	CALL	AHEX		; A hexadezimal ausgeben
	RET

;**********************************
; Direkteingabe von ASCII-Zeichen in den Speicher
; Format: write Anfangsadresse
; Nach Betätigung der ENTER-Taste kann beliebiger Text in den Speicher
; geschrieben werden. Mit der STOP-Taste kann diese Funktion abge-
; brochen werden.
;**********************************

WRITE:	LD	C,1		; CONSI
	CALL	5
	CP	3		; <STOP>
	JR	Z,WRE
	CP	01DH		; <RUN>: Backspace
	JR	Z,WCLR
	CP	020H
	JR	C,WSTC		; wenn Steuerzeichen
	LD	(HL),A		; sonst Zeichen eintragen
WRIT2:	LD	E,A
	INC	HL
	CALL	DRUCK		; Zeichenausgabe E
	JR	WRITE
; STOP
WRE:	LD	(HL),0		; Abschluß: Nullbyte
	JR	WRE2

; Backspace, Zeichen löschen
WCLR:	LD	DE,(HLM)
	PUSH	HL
	SBC	HL,DE
	POP	HL
	JR	Z,WRITE
	LD	DE,MST01
	CALL	PRNST
	LD	(HL),0
	DEC	HL
	JR	WRITE
; Steuerzeichen: volles Kästchen ausgeben
WSTC:	LD	(HL),A
	LD	A,0FFH
	JR	WRIT2

; Anzeige von Anfangsadresse und Endadresse des beschriebenen Bereichs
WRE2:	PUSH	HL
	LD	HL,(HLM)	; Anfangsadresse
	CALL	CRNL
	CALL	HLHEX		; HL hexadezimal + Leerzeichen ausgeben
	LD	DE,KEYM2	; Doppelpunkt ausgeben
	CALL	PRNST
	POP	HL		; aktuelle Adresse
	CALL	HLHEX		; HL hexadezimal + Leerzeichen ausgeben
	JP	CRNL

;**********************************
; sofortige Umschaltung der Farbkombination des gesamten Bildschir-
; mes. Im Gegensatz zu COLOR wird bei diesem Kommando nicht zellenwel-
; se die neue Farbkombination ab aktueller Cursorposition erzeugt, son-
; dern der gesamte Bildschirm in der neuen Kombination eingefärbt.
;**********************************

VCOL:	LD	HL,0E800H
	LD	DE,0E801H
	LD	BC,003C0H	; 40*24
	LD	A,(COL)		; aktuelles Farbattribut
	LD	(HL),A
	LDIR			; kompletten Farbpeicher füllen
	RET


; erweiterter Unterprogrammverteiler für CALL 5
VERW:	CP	035H
	JP	NC,VMON		; ungültige Funktion
	SUB	022H
	LD	HL,VERM
	LD	D,0
	LD	E,A
	ADD	HL,DE
	ADD	HL,DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	PUSH	DE		; UP-Adresse auf Stack
	EX	AF,AF'
	EXX
	LD	(HLM),HL
	LD	(DEM),DE
	LD	(BCM),BC
	LD	(AME),A
	RET			; UP aufrufen

; zusätzliche Unterprogramme
VERM:	DW	SWIT		; C=22H
	DW	JUMP		; C=23H
	DW	MENU		; C=24H
	DW	SAVE		; C=25H
	DW	VERIF		; C=26H
	DW	LOAD		; C=27H
	DW	COLOR		; C=28H
	DW	MODIF		; C=29H
	DW	DISP		; C=2AH
	DW	KEY		; C=2BH
	DW	KEYLI		; C=2CH
	DW	WRITE		; C=2DH
	DW	VCOL		; C=2EH
	DW	RET		; C=2FH
	DW	AHEX		; C=30H	A hexadezimal ausgeben
	DW	HLHEX		; C=31H	HL hexadezimal + Leerzeichen ausgeben
	DW	INLIN		; C=32H Eingabe einer Zeile, Abschluß mit ENTER
	DW	RHEXH		; C=33H String ab (DE) als Hexzahl nach HL konvertieren
	DW	ERR1		; C=34H Ausgabe " FEHLER"

; String ab (DE) als Hexzahl nach HL konvertieren
RHEXH:	CALL	RHEX		; (DE) ff. als Hexzahl konvertieren
	LD	HL,(MEMHL)
	RET



;  **********************************
;  ***  BETRIEBSSYSTEM F]R KC 87  ***
;  ***  VERSION 3.0 ,  TEIL 2     ***
;  ***  DIRK AMBRAS , 01.07.1988  ***
;  **********************************
;
;CAOS:	EQU	07100H
;BSST:	EQU	CAOS-00100H
;	ORG	CAOS+00AA4H
;ERR1:	EQU	CAOS+00418H
;HLHEX:	EQU	CAOS+00462H
;PRNST:	EQU	CAOS+00259H
;RET:	EQU	CAOS+003A9H
;INLIN:	EQU	CAOS+0026EH
;DRUCK:	EQU	CAOS+00230H
;PRKEY:	EQU	CAOS+007DDH
;CRNL:	EQU	CAOS+0097BH
;AHEX:	EQU	CAOS+00442H
;KEYM1:	EQU	CAOS+007D4H
;AME:	EQU	BSST
;HLM:	EQU	BSST+00001H
;MEMDE:	EQU	BSST+00013H
;SCUR:	EQU	BSST+00018H
;KEYTA:	EQU	BSST+00021H
;EKEY:	EQU	BSST+000F8H
;

;**********************************
; Mit SWITCH S Z kann ein RAM-Bereich S
; (4,8,C) als RAM oder ROM deklarieren.
; Z=0 RAM Z=1 ROM
;**********************************

SWIT:	CP	2
	JR	Z,SWSE
SWGE:	CP	1
	JR	Z,OKSW
SWERR:	CALL	ERR1		; Ausgabe " FEHLER"
	RET

OKSW:	PUSH	HL
	POP	DE
	PUSH	HL
SWPR:	LD	C,01BH		; GETM 	Abfrage der Speicherkonfiguration
	CALL	5
	LD	E,2		; <CL LN>
	CALL	DRUCK		; Zeichenausgabe E
	NOP
	POP	HL
	PUSH	AF
	CALL	HLHEX		; HL hexadezimal + Leerzeichen ausgeben
	POP	AF
	CP	1
	JR	Z,SWRAM
SWROM:	LD	DE,MROM
SWDR:	CALL	PRNST
	JP	CRNL

MROM:	DB	"- ROM"
	DB	0
MRAM:	DB	"- RAM"
	DB	0

SWRAM:	LD	DE,MRAM
	JR	SWDR

SWSE:	LD	A,E
	CP	2
	JR	NC,SWERR
	PUSH	HL
	POP	DE
	PUSH	HL
	LD	C,01CH		; SETM 	Setzen der Speicherkonfiguration
	CALL	5
	JR	SWPR

;**********************************
; Aufruf der entsprechenden Funktionstastenbelegung zur Änderung.
; Format: KEY Z      (Z = 0 ... 9)
; Die Belegung kann byteweise von hinten durch Betätigung der RUN-Taste
; gelöscht werden. Anschließend ist eine neue Belegung möglich, die
; durch die Betätigung der STOP-Taste abgeschlossen wird.
;**********************************

KEY:	LD	A,L
KEY1:	CP	10
	RET	NC
	CALL	SKEY
	LD	DE,EKEY+1
	EX	DE,HL
	AND	A
	SBC	HL,DE
	JP	C,CRNL
	EX	DE,HL
	LD	C,E
	LD	B,D
TASTE:	PUSH	BC
	LD	C,1
	CALL	5
	POP	BC
	AND	A
	JR	Z,TASTE
	CP	3
	JR	NZ,DRKE
KEND:	JP	CRNL
DRKE:	CP	01DH		; <RUN>
	JR	Z,CLR
	PUSH	HL
	LD	HL,EKEY
	INC	(HL)
	DEC	(HL)
	POP	HL
	JR	NZ,TASTE
DR1:	LD	HL,EKEY
	LD	D,H
	LD	E,L
	INC	DE
	PUSH	BC
	LDDR
	POP	BC
	INC	HL
	LD	(HL),A
	INC	HL
	LD	E,A
	CP	32
	JR	NC,DR2
	LD	E,0FFH
DR2:	PUSH	BC
	CALL	DRUCK		; Zeichenausgabe E
	POP	BC
	DEC	BC
	JR	TASTE

CLR:	DEC	HL
	LD	A,(HL)
	INC	HL
	AND	A
	JR	Z,TASTE
	DEC	HL
	PUSH	HL
	INC	HL
	INC	BC
	PUSH	BC
	LD	D,H
	LD	E,L
	DEC	DE
	LDIR
	LD	E,01DH		; <RUN>
	CALL	DRUCK		; Zeichenausgabe E
	POP	BC
	POP	HL
	JR	TASTE

SKEY:	LD	HL,KEYTA
	LD	B,A
	INC	B
	DEC	HL
	LD	(HL),0
SKEY1:	LD	A,(HL)
	AND	A
	INC	HL
	JR	NZ,SKEY1
	DJNZ	SKEY1
	PUSH	HL
	POP	DE
SKEY2:	CALL	PRKEY
	LD	HL,(MEMDE)
	RET

KAS1:	DB	"NAME : "
	DB	0
KAS2:	DB	"> "
	DB	0
KAS3:	DB	"? "
	DW	7
KAS4:	DB	"* "
	DW	7
KAS5:	DB	"COM"

;**********************************
; funktioniert analog dem KC 85/3
; Format: SAVE Anfangsadresse Endadresse (Startadresse)
; Es können beliebige COM-Files auf Magnetband gespeichert werden.
;**********************************

SAVE:	CP	2
	JP	NC,OKSA
ERRS:	CALL	ERR1		; Ausgabe " FEHLER"
	RET

OKSA:	LD	(0006DH),HL	; FCB: AADR Dateianfangsadresse
	LD	(0001BH),HL	; DMA Zeiger auf Puffer für Kassetten-E/A
	LD	(0006FH),DE	; FCB: EADR Dateiendeadresse
	LD	HL,0FFFFH
	LD	(00071H),HL	; FCB: SADR Startadresse
	CP	2
	JR	Z,SAV1
	LD	(00071H),BC	; FCB: SADR Startadresse
	CP	4
	JR	NC,ERRS
SAV1:	LD	DE,KAS1
	CALL	PRNST
	CALL	INLIN
	LD	HL,7
	ADD	HL,DE
	LD	DE,0005CH	; FCB: FNAME Dateiname
	LD	B,8
	CALL	NAMCO
	LD	HL,KAS5
	LD	BC,3		; Dateityp eintragen
	LDIR
	LD	HL,(0006FH)	; FCB: EADR Dateiendeadresse
	LD	DE,(0006DH)	; FCB: AADR Dateianfangsadresse
	SBC	HL,DE
	ADC	HL,HL
	PUSH	HL
	XOR	A		; A=0 -> kein Schutz
	LD	(00073H),A	; FCB: SBY Schutzbyte
	DEC	D
	SBC	A,H
	PUSH	DE
	XOR	A
	CALL	AHEX		; A hexadezimal ausgeben
	CALL	0F44AH		; OPENW+5
	LD	DE,KAS2
	CALL	PRNST
	POP	DE
	POP	BC
	XOR	A
	CP	B
	JR	Z,SAV2
	LD	HL,(HLM)
	LD	(0001BH),HL	; DMA Zeiger auf Puffer für Kassetten-E/A
	LD	(0006DH),HL	; FCB: AADR Dateianfangsadresse
SAV3:	PUSH	BC
	LD	A,(0006BH)	; FCB: BLNR Blocknummer
	CALL	AHEX		; A hexadezimal ausgeben
	CALL	BLRA
	LD	DE,KAS2
	CALL	PRNST
	POP	BC
	DJNZ	SAV3
SAV2:	LD	A,0FFH		; letzter Block
	LD	(0006BH),A	; FCB: BLNR Blocknummer
	CALL	AHEX		; A hexadezimal ausgeben
	CALL	BLRA
	LD	DE,KAS2
	CALL	PRNST
	JP	CRNL
BLRA:	LD	BC,160		; Länge Vorton
	LD	DE,(0001BH)	; DMA Zeiger auf Puffer für Kassetten-E/A
	JP	0F497H		; WRIT2+17H (call KARAM, Ausgabe Block)

NAMCO:	LD	A,(HL)
	CP	020H
	JR	Z,NCO1
	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	NAMCO
	RET

NCO1:	LD	A,0
NCO2:	LD	(DE),A
	INC	HL
	INC	DE
	DJNZ	NCO2
	RET

;**********************************
; führt einen Prüfsummenvergleich des gespeicherten Programmes aus
; und dient somit zur Kontrolle der Aufzeichnung auf Lesefehler.
;**********************************

VERIF:	LD	A,0
	JR	LO2

;**********************************
; - Laden von COM-Files in den Rechner
; Nach der Eingabe von LOAD und dem Lesen des Kopfblockes des Program-
; mes  wird der Name, Anfangsadresse, Endadresse und Startadresse an-
; gezeigt. Wird nach LOAD eine Adresse angegeben, so wird das Programm
; auf dieser Adresse als Anfangsadresse geladen. Gleichzeitig wird ein
; Autostart unterdrückt. Die neue LOAD-Routine ist auch in der Lage,
; KC 85/3 Files zu lesen. Dies ist für das Brennen von MC-Programmen
; für den KC mittels Eprommer-Modul interessant. Beim Laden von MC-
; Files des KC 85/3 ist zu beachten, daß der KC 87 auf der Adresse 200H
; die Interrupttabelle ablegt. Da viele KC 3 - Programme auf dieser
; Adresse beginnen, ist zum Kopieren eine höhere Adresse zu wählen.
;**********************************

LOAD:	CP	0
	JR	Z,LO1
	CP	1
	JR	Z,LO2
	CALL	ERR1		; Ausgabe " FEHLER"
	RET

LO1:	LD	A,2
LO2:	LD	(MEMDE),A
	LD	A,0
	LD	(AME),A
	POP	HL
	LD	(MEMDE-2),HL
	PUSH	HL
	LD	(MEMDE+3),SP
	LD	(HLM+8),A
	LD	BC,00100H
	LD	HL,00080H
	LD	E,0EFH
	EXX
	LD	HL,00080H
	SCF
	CCF
	CALL	LDM2
	EX	DE,HL
	LD	HL,00080H
	LD	B,8
	PUSH	DE
PNAM:	LD	E,(HL)
	CALL	DRUCK		; Zeichenausgabe E
	INC	HL
	DJNZ	PNAM
	LD	E,32
	CALL	DRUCK		; Zeichenausgabe E
	LD	A,(MEMDE)
	CP	1
	LD	DE,(HLM)
	LD	HL,(00091H)
	JR	NZ,PA1
	PUSH	DE
	POP	HL
PA1:	LD	(HLM),HL
	LD	HL,(00093H)
	JR	NZ,PA2
	PUSH	DE
	LD	DE,(00091H)
	SBC	HL,DE
	LD	DE,(HLM)
	ADD	HL,DE
	POP	DE
PA2:	LD	(HLM+2),HL
	JR	PKC3
PEK3:	LD	A,0FFH
	CP	H
	JR	NZ,PA21
	CP	L
	JR	Z,PA31
PA21:	LD	HL,(00095H)
	PUSH	AF
	LD	A,H
	CP	0FFH
	JR	NZ,PA2E
	LD	A,L
	CP	0FFH
	JR	Z,PA2VE
PA2E:	POP	AF
	LD	DE,(00091H)
	SBC	HL,DE
	LD	DE,(HLM)
	ADD	HL,DE
	JR	PA3

PA2VE:	POP	AF
	JR	PA3

PKC3:	LD	A,(HLM+8)
	CP	1
	JR	NZ,PEK3
PA31:	LD	HL,0FFFFH
PA3:	LD	(HLM+4),HL
	LD	HL,(HLM)
	CALL	HLHEX		; HL hexadezimal + Leerzeichen ausgeben
	LD	HL,(HLM+2)
	CALL	HLHEX		; HL hexadezimal + Leerzeichen ausgeben
	LD	HL,(HLM+4)
	CALL	HLHEX		; HL hexadezimal + Leerzeichen ausgeben
	POP	DE
	CALL	CRNL
	EX	DE,HL
	LD	HL,(HLM)
BLEIN:	SCF
	CALL	LDMA
	CALL	0F310H		; OSPAC
	EXX
	INC	B
	EXX
	PUSH	BC
	LD	BC,00080H
	LD	HL,(HLM)
	ADD	HL,BC
	LD	(HLM),HL
	POP	BC
	JR	BLEIN

LDMA:	PUSH	AF
	LD	A,(MEMDE)
	CP	0
	JR	NZ,LDM1
	LD	HL,128
LDM1:	LD	(HLM),HL
	POP	AF
LDM2:	LD	(0001BH),HL	; DMA Zeiger auf Puffer für Kassetten-E/A
	JR	C,BL1
LDM3:	CALL	0FF59H		; MAREK, Lesen eines Blockes
BE1:	CALL	0FAE3H		; INITA, Initialisierung Tastatur
	EX	AF,AF'
	EXX
	LD	A,E
	OR	A
	JR	NZ,BLV
	LD	A,C
	LD	(0006BH),A	; FCB: BLNR Blocknummer
BLV:	LD	A,(0006BH)	; FCB: BLNR Blocknummer
	CP	0FFH
	JP	Z,BLT
	CP	C
	JR	NZ,FBL
KC31:	INC	C
	EXX
	EX	AF,AF'
	RET

FBL:	CP	1
	JR	NZ,KC1
	INC	C
	CP	C
	JP	Z,KC3
	DEC	C
KC1:	CP	C
	EXX
	LD	HL,(HLM)
BERR:	PUSH	AF
	LD	A,(AME)
	CP	1
	JP	Z,REP1
	LD	A,1
	LD	(AME),A
	LD	E,32
	CALL	DRUCK		; Zeichenausgabe E
	POP	AF
	CALL	AHEX		; A hexadezimal ausgeben
	LD	DE,KAS3
	CALL	PRNST
	JP	LDMA
BL1:	LD	A,(0006BH)	; FCB: BLNR Blocknummer
	PUSH	DE
	PUSH	AF
	LD	A,(EKEY+2)
	LD	E,A
	POP	AF
	CP	E
	JR	Z,B1E
	LD	(EKEY+2),A
	CALL	AHEX		; A hexadezimal ausgeben
	LD	DE,KAS2
	CALL	PRNST
B1E:	LD	E,8
	CALL	DRUCK		; Zeichenausgabe E
	LD	A,0
	LD	(AME),A
	POP	DE
	LD	HL,LOU1
	DI
	LD	(00202H),HL
	EI
	LD	A,087H
	OUT	(081H),A
	LD	A,2
	OUT	(081H),A
	JP	LDM3

LOU1:	LD	A,0A7H
	OUT	(081H),A
	LD	HL,LOU2		; Interruptroutine f. Anwender CTC Kanal 1
	LD	(00202H),HL	; in Interrupttabelle eintragen
	XOR	A
	OUT	(081H),A
	LD	D,12
	LD	HL,LOU3
	EX	(SP),HL
	EI
	RETI

LOU3:	LD	B,016H
LOU4:	CALL	0FFD1H		; LSTOP, Lesen Eines Zeichens
	JR	C,LOU3
	CP	090H
	JR	C,LOU3
	DJNZ	LOU4
	LD	A,3
	OUT	(081H),A
	JP	0FF83H		; MA3-2, Lesen Eines Blockes

; Interruptroutine f. Anwender CTC Kanal 1
LOU2:	DEC	D
	JR	NZ,LOUE
	LD	A,3
	OUT	(081H),A
	LD	HL,BE1
LOU5:	POP	DE
	CALL	0FCBCH
	JR	NZ,LOU5
	LD	DE,0FAE3H
	PUSH	DE
LOUE:	EI
	RETI

LBL:	CALL	CRNL
	LD	HL,(MEMDE+3)
	LD	SP,HL
	LD	HL,(MEMDE-2)
	EX	(SP),HL
	LD	A,(MEMDE)
	OR	A
	RET	Z
	LD	HL,(HLM+4)
	JP	(HL)

KASKC:	DB	"KC85/3"
	DB	"-FILE"
	DB	0

KC3:	PUSH	DE
	LD	DE,KASKC
	CALL	PRNST
	CALL	CRNL
	POP	DE
	PUSH	AF
	LD	A,1
	LD	(HLM+8),A
	POP	AF
	JP	KC31
REP1:	POP	AF
	PUSH	DE
	CALL	AHEX		; A hexadezimal ausgeben
	LD	DE,KAS4
	CALL	PRNST
	POP	DE
	JP	LDMA

BLT:	PUSH	AF
	LD	A,(AME)
	CP	1
	JP	Z,REP1
	POP	AF
	LD	E,32
	CALL	DRUCK		; Zeichenausgabe E
	LD	A,0FFH
	CALL	AHEX		; A hexadezimal ausgeben
	LD	DE,KAS2
	CALL	PRNST
	JP	LBL


; ? nicht verwendet ?
BKEY:	LD	DE,KEYM1
	CALL	PRNST
	LD	C,1
	CALL	5
	PUSH	AF
	LD	E,A
	CALL	DRUCK		; Zeichenausgabe E
	CALL	CRNL
	POP	AF
	SUB	030H
	JP	KEY1

	end
	