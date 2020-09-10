; File Name   :	C:\user\hobby\rechner\Z9001\dev\os-save\OS-SAVE-Tabelle.KCC
; Format      :	Binary file
; Base Address:	0000h Range: 0F89h - 1379h Loaded length: 03F0h

;------------------------------------------------------------------------------
; OS-SAVE 
; Dieser Code wird an die Zieladresse verschoben (incl. Adresskorrektur)
;------------------------------------------------------------------------------

		cpu	z80

; Systemzellen

; DMA:		
; KEYBU:	
; EOR:		
; FTYP:		
; LBLNR:	
; AADR:		
; EADR:		
; SADR:		

DMA		equ	001Bh		; Zeiger auf Puffer für Kassetten-E/A
KEYBU		equ	0025h		; Tastaturpuffer
EOR		equ	0036h		; Zeiger auf letzte für Anwender freie Adresse
PARBU		equ	0040h		; Hilfszelle zur Paramterpufferung
FCB		equ	005Ch		; Dateikontrollblock
FNAME		equ	005Ch		; Dateiname 8 Zeichen
FTYP		equ	0064h		; Dateityp 3 Zeichen
LBLNR		equ	006Ch		; gesuchte Blocknummer bei Lesen
AADR		equ	006Dh		; Dateianfangsadresse
EADR		equ	006Fh		; Dateiendeadresse
SADR		equ	0071h		; Startadresse, wenn Datei ein Maschinencodeprogramm ist
SBY		equ	0073h		; Schutzbyte. 0 nicht geschützt, 1 geschützt
CONBU		equ	0080h		; CCP-Eingabepuffer und Standardpuffer für Kassetten-E/A
INTLN		equ	0100h		; interner Zeichenkettenpuffer


		org	0F89h

start:		ld	hl, aCold-1
		ld	(EOR), hl
		ld	hl, 23h	; '#'
		ld	(CONBU+2), hl
		call	0F1EAh
		call	0F28Eh
		jr	nz, start3
		ld	hl, aCold	; "#	   "
		or	a
		sbc	hl, de
		jr	z, start3
		push	de
		dec	de
		dec	de
		dec	de
		pop	hl
		push	de
		ld	(hl), 20h ; ' '
		ld	de, 9
		add	hl, de
		ld	de, unk_1018
start1:		ld	a, (hl)
		or	a
		jr	z, start2
		ld	bc, 0Ch
		ldir
		jr	start1
;
start2:		ld	(de), a
		pop	de
		sbc	hl, de
		push	hl
		pop	bc
		push	de
		pop	hl
		inc	de
		ld	(hl), 0
		ldir
;
start3:		ld	de, aExtendedOsAt ; "EXTENDED OS AT "
		call	upprs
		ld	hl, (EOR)
		inc	hl
		ld	a, h
		call	aanz
		ld	a, l
		call	aanz
		ld	de, aH		; "H"
		jp	upprs

aExtendedOsAt:	db 0Ah
		db 0Dh,14h,1,"EXTENDED OS AT ",14h,4,0
aH:		db 'H',14h,2,0Ah
		db 0Dh,0

		; org 1000h

		jp	cold
aCold:		db "#       ",0
		jp	save
		db "SAVE    ",0
unk_1018:	db    0
		db    0
; Platz für weitere Kommandos, Ende der Liste mit 00h 00h
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db  22h	; "
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh
		db    0
		db 0FFh

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

cold:		ld	de, aEos	; "EOS"
		call	upprs
		jp	0F089h

aEos:		db 0Bh,14h,1,"EOS",14h,2,0Ah
		db 0Dh,0

;------------------------------------------------------------------------------
; SAVE filename[.filetyp] aadr eadr [sadr]
;------------------------------------------------------------------------------

save:		ex	af, af'
		ld	hl, 0F5E6h
		push	hl
		ret	c
; Einlesen Name
		call	eing
		ret	z
		ex	af, af'
		ret	c
		ld	a, (100h)
		or	a
		ret	z
		cp	9
		ret	nc
		ld	de, FNAME
		ld	a, 8
		call	0F588h
; Einlesen Dateityp
		ld	a, c
		cp	'.'
		jr	z, sa1
		ld	hl, 4F43h	; "COM"
		ld	(FTYP),	hl
		ld	a, 'M'
		ld	(FTYP+2), a
		or	a
		jr	sa2

sa1:		call	eing
		ret	z
		ex	af, af'
		ret	c
		ld	a, 3
		cp	b
		ret	c
		ld	de, FTYP
		call	0F588h
; Einlesen Anfangsadresse
sa2:		call	eing
		ret	nz
		ret	c
		ex	af, af'
		ret	c
		ld	(AADR),	de
; Einlesen Endadresse
		call	eing
		ret	nz
		ret	c
		ld	(EADR),	de
		ex	af, af'
		jr	nc, sa3
; Einlesen Startadresse
		ld	de, (AADR)
		jr	sa4

sa3:		call	eing
		ret	nz
		ret	c
		ex	af, af'
		ret	nc

sa4:		ld	(SADR),	de
		pop	hl
		ld	hl, (EADR)
		ld	de, (AADR)
		or	a
		sbc	hl, de
		jp	c, 0F5E2h
;
; Ausgeben auf Band
;
		ld	hl, nokey
		push	hl
		call	upopw
		ret	c
		call	saa1
		jp	c, saa2
		ex	de, hl
		ld	(DMA), hl
sav2:		ld	hl, (DMA)
		ld	de, 7Fh	; ''
		add	hl, de
		ld	de, (EADR)
		sbc	hl, de
		jr	nc, sav1
		call	upwrs
		ld	(puf1),	a
		ret	c
		call	saa1
		jp	c, saa3
		jr	sav2
;
sav1:		call	upclw
		ret	c
		ld	hl, puf1
		inc	(hl)
		ld	de, aVerifyYN	; "VERIFY ((Y)/N)?:"
		call	upprs
		call	0F35Ch
		jp	c, saa3
		ld	a, (CONBU+2)
		cp	'N'
		jp	z, saa4
;
; Verify
;
		ld	de, aRewind	; "REWIND <--"
		call	upprs
		call	0F35Ch
		jp	c, saa3

sav4:		call	upopr
		jr	c, sav4a
		call	saa5
		jr	nc, sav5
		jr	saa3

sav4a:		or	a
		jr	z, saa3
		call	0F5A6h
		jr	c, saa3
		jr	sav4

sav8:		call	upres
		jr	nc, sav7
		call	0F5A6h
		jr	c, saa6
		jr	sav8

sav7:		ld	l, a
		call	saa5
		jr	c, saa6
		ld	a, l

sav5:		ld	hl, 80h	; '€'
		ld	(DMA), hl
		or	a
		jr	z, sav8
		ld	de, aSaveComplete ; "SAVE COMPLETE"

saa7:		call	upprs
		ld	a, 14h
		call	upcod
		ld	a, 4
		call	upcod
		ld	a, (puf1)
		call	aanz
		ld	de, aRecordSWritten ; "	RECORD(S) WRITTEN"
		call	upprs
		ld	a, 14h
		call	upcod
		ld	a, 4
		call	upcod
		ld	a, (LBLNR)
		dec	a
		call	aanz
		ld	de, aRecordSChecked ; "	RECORD(S) CHECKED"
		jp	upprs

saa2:		ld	de, aBreakByStopKey ; "BREAK BY "STOP"-KEY!"
		call	upprs
		ld	de, aNo		; "NO"
		call	upprs

saa8:		ld	de, aRecordSWritten ; "	RECORD(S) WRITTEN"
		call	upprs
		ld	de, aNo		; "NO"
		call	upprs
		ld	de, aRecordSChecked ; "	RECORD(S) CHECKED"
		jp	upprs

saa3:		ld	de, aBreakByStopKey ; "BREAK BY "STOP"-KEY!"
		call	upprs
;
; Abschluss
;
saa4:		ld	a, 14h
		call	upcod
		ld	a, 4
		call	upcod
		ld	a, (puf1)
		call	aanz
		jr	saa8

saa6:		ld	de, aBreakByStopKey ; "BREAK BY "STOP"-KEY!"
		jr	saa7

aSaveComplete:	db 0Ah
		db 0Dh,14h,1,"SAVE COMPLETE",0Ah
		db 0Dh,0Ah,0
aRecordSWritten:db 14h,2," RECORD(S) WRITTEN",0Ah
		db 0Dh,0
aRecordSChecked:db 14h,2," RECORD(S) CHECKED",0Ah
		db 0Dh,0Ah,0
aVerifyYN:	db 0Ah
		db 0Dh,"VERIFY ((Y)/N)?:",0
aRewind:	db 0Ah
		db 0Dh,"REWIND ",14h,1,"<--",14h,2,' ',0
aBreakByStopKey:db 0Ah
		db 0Dh,14h,1,"BREAK BY ",14h,4,"\"STOP\"",14h,1,"-KEY!",14h,2,0Ah
		db 0Dh,0Dh,0Ah,0
aNo:		db 14h,4,"NO",14h,2,0

;------------------------------------------------------------------------------
; Parametereingabe Hexzahl
;------------------------------------------------------------------------------

eing:		call	0F1EAh
		ret	nz
		push	hl
		push	bc
		ld	de, 100h
		call	ein3
		pop	bc
		pop	hl
		jr	c, ein1
		cp	a
		ret
;
ein1:		cp	a
		jp	0F5E2h
;
ein3:		ld	a, (de)
		or	a
		scf
		ret	z
		ld	a, 4
		call	0F836h
		ret	c
		ld	hl, puf2
		ld	b, 2
ein2:		call	ein4
		ret	c
		ld	(hl), a
		call	ein4
		ret	c
		rld
		dec	hl
		djnz	ein2
		ld	de, (puf1)
		ret
;
ein4:		ld	a, (de)
		inc	de
		cp	30h ; '0'
		ret	c
		cp	3Ah ; ':'
		ccf
		ret	nc
		and	0DFh ; 'ß'
		sub	7
		cp	40h ; '@'
		ccf
		ret

;------------------------------------------------------------------------------
; Ausgabe A hexadezimal
;------------------------------------------------------------------------------

aanz:		push	af
		and	0F0h
		rlca
		rlca
		rlca
		rlca
		call	aan1
		pop	af
		and	0Fh
aan1:		add	a, 30h ; '0'
		cp	3Ah ; ':'
		jr	c, aan2
		add	a, 7
aan2:		jr	upcod

;------------------------------------------------------------------------------
; Systemaufrufe
;------------------------------------------------------------------------------

upopw:		ld	c, 0Fh
		jr	c5

upwrs:		ld	c, 15h
		jr	c5

upclw:		ld	c, 10h
		jr	c5

upprs:		ld	c, 9
		jr	c5

upopr:		ld	c, 0Dh
		jr	c5

upres:		ld	c, 14h
		jr	c5

upcod:		ld	c, 2
		ld	e, a

c5:		jp	5

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

saa1:		call	0F310h
;
saa5:		call	0FD33h
		ei
		or	a
		ret	z
		cp	3
		scf
		ret	z
		ccf
		ret

puf1:		db 	0
puf2:		db    	0

nokey:		xor	a
		ld	(KEYBU), a
		ret

		end
