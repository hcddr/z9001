; Zusatzmontitor Z9001 Version 2.0
; 1985/1986 F.Schwarzenberg 8036,Gamigstr.5
; reassembliert: V. Pohlers, 05.2008
;
; Software-Historie
; -----------------
;
; Version ZM30 Kassette R0112
; 	in den Geräte-Treibern PUNCH, LIST Register C und E vertauscht
;
; mp 10/87: Bei den ersten Varianten des ZM und Version 1.2 des OS-KC85/1 kann es
; bei den Treibern SIFA und TD40 unter Umständen Probleme mit der CTRL/P-Funktion
; (Hardcopy) geben. Deshalb sei an dieser Stelle auf die erforderlichen
; Korrekturen für eine saubere Arbeitsweise der ZM-Treiber hingewiesen
;
; 	"ZM30_121"				  "ZM30_112"
;
; 	3060: D3 8B*7B 2F CB FF D3 89 | ..{/.... ¦ D3 8B*79 2F CB FF D3 89 ¦ ..y/....
; 	30C0: E6 7F C9 CB*BB 3E CF D3 | .....>.. ¦ E6 7F C9 CB*B9 3E CF D3 ¦ .....>..
; 	30E0:*93 20 03 77 18 16 3E 1F | . .w..>. ¦*91 20 03 77 18 16 3E 1F ¦ . .w..>.
; 	30E8:*BB 30 11 34 3E 29 96 20 | .0.4>).  ¦*B9 30 11 34 3E 29 96 20 ¦ .0.4>).
; 	30F8: 0A CD 02 31*7B CD 02 31 | ...1{..1 ¦ 0A CD 02 31*79 CD 02 31 ¦ ...1y..1
; 	3100: B7 C9*0E 9A 06 09 E6 7F | ........ ¦ B7 C9*1E 9A 06 09 E6 7F ¦ ........
; 	3110: 10 F8 2F D3 89 FB C5*41 | ../....A ¦ 10 F8 2F D3 89 FB C5*43 ¦ ../....C
; 
; Version ZM30, ZM70, ZMA8 Kassette R0121 und R0121
; 	Die Versionen der Kassetten R121 (Assembler) und R122 (IDAS) sind identisch
; 	Basis für ROM=0-Version
; 
; idaszm2 IDAS-Modul VP
; 	IDAS ohne Meldung
; 	ZM mit Meldung "Z9001 MONITOR V2.0 (ROM) 1985" und mit EPROM (idaszm2)
; 	ZM hat Register C und E vertauscht wie in ZM30 der Kassette R0112
; 	ist Basis für ROM=2-Version 
; 
; idaszm1 IDAS-Modul von U. Zander und KC-Emu 
; 	IDAS mit Meldung "INTERPRETING DIALOG-ASSEMBLER"
; 	ZM mit Meldung "Z9001 MONITOR CENT. 1986" und mit RENEW und QUICK, NORMAL, QLOAD (idaszm1)
; 	ist Basis für ROM=1-Version 


		cpu	Z80
		page	0

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------


;		include	z9001.inc

; Systemspeicher
KEYBU		equ	0025h			; Tastaturpuffer
PU		equ	002Fh			; Hilfszelle
P1ROL		equ	003Bh			; 1. rollende Zeile - 1
FCB		equ	005Ch			; Dateiname 8 Zeichen
FNAME		equ	005Ch
FTYP		equ	0064h			; Dateityp 3 Zeichen
PSUM		equ	0069h			; Pruefsumme eines Datenblockes
LBLNR		equ	006Ch			; gesuchte Blocknummer bei Lesen
AADR		equ	006Dh			; Dateianfangsadresse
EADR		equ	006Fh			; Dateiendeadresse
SADR		equ	0071h			; Startadresse,	wenn Datei ein Maschinencodeprogramm ist


;Systemaufrufe
; 0F003h		; JP WBOOT
; 0F089h		; GOCPM
; 0F1EAh		; GVAL:	PARAMETER AUS EINGABEZEILE HOLEN
; 0F310h		; OSPAC
; 0F35Ch		; GETMS: EINGABE ZEICHENKETTE IN MONITORPUFFER
; 0F3F8h		; OPENR	OPEN FUER KASSETTE LESEN
; 0F578h		; LOA55: LESEN BLOCK
; 0F588h		; MOV
; 0F5A3h		; REA: AUSGABE FEHLERMELDUNG, WARTEN AUF BEDIENERREAKTION
; 0F5A6h		; REA1
; 0F5B9h		; COEXT: VORVERARBEITEN	EINER ZEICHENKETTE
; 0F5E2h		; ERINP
; 0F5EAh		; ERDIS	AUSGEBEN FEHLERMELDUNG
; 0F7B4h		; BAT: STEUERPROGRAMM FUER BATCH-MODE VON CONST
; 0F8F1h		; CRT: STEUERPROGRAMM DES CRT - TREIBERS 
; 0FD33h		; DECO0, DECODIEREN DER	TASTATURMATRIX



; Speichernutzung vor BEG
; ?? 16, 23h, 29h, 34h, 35h, 20h, 6Fh

; Register im Stack (offset aus reg_tab ausgewertet)
; (TOP)
; IR
; IY
; IX
; AF
; BC
; DE
; HL -> (M)
; DE
; BC
; AF
; SP
; .
; .
; HL -> (M)
; ..
; PC


;ZMKORR		equ	1	; 1 - korrigierte Version der R0112
;ROM		equ	2	; 0 - RAM-Version, 1=IDASZM (Centr), 2=IDASZM2 (mit EPROM)
;	org	03000h

; Sprungverteiler

beg:		jp	init		; Monitor-Neustart 
exrst38:	jp	rst38		; Trap-Eingang (RST 38H) 
		jp	error		; Error-Eingang 
		jp	GIOBY		; ABFRAGE I/O-BYTE
		jp	SIOBY		; SETZEN I/O-BYTE
		jp	eor0		; Test RAM-Größe 
		jp	getdez		; Eingabekonvertierung 
		jp	todez		; Ausgabekonvertierung 
		jp	params		; C Parameter holen
		jp	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
		jp	bin_e		; Ausgabe E binär
		jp	cass		; Kassetten-I/O: Filename abfragen+laden/speichern

begdat:		dw	beg
		dw 	end
		dw	0

;------------------------------------------------------------------------------
; OS-Funktionen
;------------------------------------------------------------------------------

zm_consi:	push	bc
		ld	c, 1		; CONSI: Eingabe eines Zeichens von CONST
		jr	syscall1

;
zm_readi:	push	bc
		ld	c, 3		; READI: Eingabe eines Zeichens von READ
		jr	syscall1


; Zeichenausgabe
zm_conso:	push	bc
		push	de
		ld	e, c
		ld	c, 2		; CONSO: Ausgabe eines Zeichens zu CONST
		jr	syscall2

;
zm_puno:	push	bc
		push	de
		ld	e, c
		ld	c, 4		; PUNO: Ausgabe eines Zeichens zu PUNCH
		jr	syscall2

;wird nicht genutzt
zm_listo:	push	bc
		push	de
		ld	e, c
		ld	c, 5		; LISTO: Ausgabe eines Zeichens zu LIST
		jr	syscall2

;
tm_csts:	push	bc
		ld	c, 0Bh		; CSTS: Abfrage Status CONST
;
syscall1:	push	de
syscall2:	push	hl
		call	5
		pop	hl
		pop	de
		pop	bc
		jp	c, error
		ret

;------------------------------------------------------------------------------
; PUN-Treiber
; Lochband-Stanzer SIF-1000 (SIFA)
;------------------------------------------------------------------------------

PUN:		ld	a, 01000111b
		out	(CTC1),	a	; System CTC1 Anwenderport
		out	(CTC1),	a	; System CTC1 Anwenderport
		ld	a, 00001111b
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		if ZMKORR=0
		ld	a, e
		else			
		ld 	a, c		; zm30 der ZMKORR
		endif
		cpl
		set	7, a
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		nop
		nop
		res	7, a
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
pun1:		call	stopkey
		jr	nc, pun3
pun2:		cpl
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		ret
;
pun3:		in	a, (CTC1)	; System CTC1 Anwenderport
		cp	01000111b
		jr	z, pun1
		ld	a, 01010111b
		out	(CTC1),	a	; System CTC1 Anwenderport
		out	(CTC1),	a	; System CTC1 Anwenderport
		ld	a, 0FFh
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
pun4:		call	stopkey
		jr	c, pun2
		in	a, (CTC1)	; System CTC1 Anwenderport
		cp	01010111b
		jr	z, pun4
		or	a
		ret
;
stopkey:	ld	a, (KEYBU)	; Tastaturpuffer
		sub	3
		or	a
		ret	nz
		ld	(KEYBU), a	; Tastaturpuffer
		scf
		ret

;------------------------------------------------------------------------------
; RDR-Treiber
; Lochband-Leser SIF-1000 (SIFE)
;------------------------------------------------------------------------------

rdr:		ld	a, 01000111b
		out	(CTC1),	a	; System CTC1 Anwenderport
		out	(CTC1),	a	; System CTC1 Anwenderport
		ld	a, 11001111b
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 01111111b
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
rdr1:		call	stopkey
		jr	c, pun2
		in	a, (CTC1)	; System CTC1 Anwenderport
		cp	01000111b
		jr	z, rdr1
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		cpl
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		and	7Fh
		ret

;------------------------------------------------------------------------------
; LST-Treiber für LIST
; V24-Drucker (TD40)
;------------------------------------------------------------------------------

list:		if ZMKORR=0
		res	7, e
		else			
		res 	7, c		; zm30 der ZMKORR
		endif
		ld	a, 11001111b
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
		ld	a, 11111110b
		out	(PIO1BS), a	; PIO1 B Kommando Anwenderport
list1:		call	stopkey
		jr	nc, list2
		ld	(LISW), a	; Schalter für Hardcopy
		ret
;
list2:		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		add	a, a
		jr	c, list1	; solange Drucker nicht bereit
		ld	hl, varlist
		ld	a, 0Dh
		if ZMKORR=0
		sub	e
		else			
		sub 	c		; zm30 der ZMKORR
		endif
		jr	nz, list3
		ld	(hl), a		; CR merken
		jr	list4
list3:		ld	a, ' '-1	; Steuerzeichen?
		if ZMKORR=0
		cp	e
		else			
		cp 	c		; zm30 der ZMKORR
		endif
		jr	nc, list4
		inc	(hl)		; hl = var1, aktuelle Position
		ld	a, 40+1		; Druckerbreite überschritten?
		sub	(hl)
		jr	nz, list4
		ld	(hl), a		; neue Position merken
		ld	a, 0Dh		; dann neue Zeile ausgeben
		call	list5
		ld	a, 0Ah
		call	list5
list4:
		if ZMKORR=0
		ld	a, e
		else			
		ld 	a, c		; zm30 der ZMKORR
		endif
		call	list5
		or	a
		ret

; V24-Ausgabe der Bits
list5:		if ZMKORR=0
		ld	c, 154		; Zeitkonstante 1200 Baud
		else			
		ld 	e, 154		; zm30 der ZMKORR
		endif
		ld	b, 9
		and	7Fh
		di
		rla
list6:		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		call	list7
		rra
		djnz	list6
		cpl
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		ei
;Warteschleife, 1200 Baud
list7:		push	bc
		if ZMKORR=0
		ld	b, c
		else			
		ld  	b, e		; zm30 der ZMKORR
		endif
list8:		djnz	list8
		pop	bc
		ret

;------------------------------------------------------------------------------
; UR1-Treiber
; das ist der Treiber Für Kassette (AP=T, AR=T)
;------------------------------------------------------------------------------

; UR1-Treiber für READER
ur1:		ld	a, 0FFh		
		ld	(PSUM), a	; merken von Kassette laden
		exx
		ld	(var1), hl
		exx
		jr	ur12
;
; UP1-Treiber für PUNCH
ur11:		xor	a		
		ld	(PSUM), a	; merken auf Kassette schreiben
;
ur12:		ld	sp, (000Bh)	; SPSV
		pop	hl		; Löschen der Rückkehradr.
		pop	hl		; Parameter 1
		pop	de		; Parameter 2
		ld	(AADR), hl
		ld	(EADR), de
		call	eor
		ld	de, -16h
		add	hl, de
		ld	sp, hl
		ld	hl, prompt
		push	hl
		ld	a, (PSUM)
		or	a		; auf Kassette schreiben?
		jr	nz, ur14
		; auf Kassette schreiben vorbereiten
		ld	bc, 100Bh	; B=10h, C=0Bh
		call	zm_conso	; Zeichenausgabe cu up
		ld	c, 9		; cu right
ur13:		call	zm_conso	; Zeichenausgabe
		djnz	ur13
		call	param		; 1 Parameter holen
		pop	hl
		ld	(SADR), hl
		call	out_crlf
ur14:		; Fehleradresse kellern
		ld	hl, error
		push	hl
;
;------------------------------------------------------------------------------
;
cass:		ld	de, aFilename	; Kassetten-I/O: Filename abfragen+laden/speichern
		call	zm_prnst
		call	0F35Ch		; GETMS: EINGABE ZEICHENKETTE IN MONITORPUFFER
		ret	c
		call	0F5B9h		; COEXT: VORVERARBEITEN	EINER ZEICHENKETTE
		ret	c
		call	0F1EAh		; GVAL:	PARAMETER AUS EINGABEZEILE HOLEN
		ld	de, FNAME
		ld	a, 8
		call	0F588h		; MOV
		ex	af, af'		; '
		jr	nc, cass1
		ld	hl, 4F43h	; "CO"
		ld	(FTYP), hl
		ld	a, 'M'
		ld	(FTYP+2), a
		jr	cass2
cass1:		call	0F1EAh		; GVAL:	PARAMETER AUS EINGABEZEILE HOLEN
		ld	a, 3
		ld	de, FTYP	; Dateityp 3 Zeichen
		call	0F588h		; MOV
cass2:		ld	a, (PSUM)
		or	a		; auf Kassette schreiben?
		jr	nz, cload	; nein, Laden
		call	csave		; sonst, Schreiben
		ret	c
		pop	hl
		ret
;
aFilename:	db "Filename:",0

; Laden
cload:		ld	hl, CONBU	; CCP-Eingabepuffer und	Standardpuffer f³r Kassetten-E/A
		ld	(DMA), hl
cload1:		call	0F3F8h		; OPENR	OPEN FUER KASSETTE LESEN
		jr	nc, cload4
		or	a
		scf
		ret	z
		cp	0Dh
		jr	z, cload2
		cp	0Bh
		jr	nz, cload3
cload2:		push	af
		scf
		call	0F5EAh		; ERDIS	AUSGEBEN FEHLERMELDUNG
		pop	af
		ld	b, 8
		ld	hl, CONBU	; CCP-Eingabepuffer und	Standardpuffer f³r Kassetten-E/A
		call	prnstr		; Stringausgabe, HL=String, B=Länge
		ld	c, '.'
		call	zm_conso	; Zeichenausgabe
		ld	b, 3
		call	prnstr		; Stringausgabe, HL=String, B=Länge
		call	out_crlf
		jr	cass		; Kassetten-I/O: Filename abfragen+laden/speichern
cload3:		call	0F5A3h		; REA: AUSGABE FEHLERMELDUNG, WARTEN AUF BEDIENERREAKTION
		jr	cload1
cload4:		ld	hl, (AADR)
		ld	de, (var1)
		add	hl, de
		ld	(DMA), hl
		call	0F578h		; LOA55: LESEN BLOCK
		ret	c
		pop	hl
		ld	de, (var1)
		ld	hl, (AADR)
		add	hl, de
		call	outhlsp		; Ausgabe HL + Space
		ld	hl, (EADR)
		add	hl, de
		call	outhlsp		; Ausgabe HL + Space
		ld	hl, (SADR)
		call	outhlsp		; Ausgabe HL + Space
		ld	de, aLoaded	; " loaded"
		jp	zm_prnst
;
aLoaded:	db " loaded",0

; Speichern
csave:		ld	hl, (EADR)
		ld	de, (AADR)
		or	a
		sbc	hl, de
		jp	c, 0F5E2h	; ERINP
		ld	hl, nokey
		push	hl
		call	zm_openw
		ret	c
		call	sp_stop		; Ausgabe Leerzeichen +	Test auf <STOP>
		jp	c, breaknw	; Break, "no records written"
		ex	de, hl
		ld	(DMA), hl
csave1:		ld	hl, (DMA)
		ld	de, 7Fh
		add	hl, de
		ld	de, (EADR)
		sbc	hl, de
		jr	nc, csave2
		call	zm_writs
		ld	(varsav), a
		ret	c
		call	sp_stop		; Ausgabe Leerzeichen +	Test auf <STOP>
		jp	c, break
		jr	csave1
csave2:		call	zm_closw
		ret	c
		ld	hl, varsav
		inc	(hl)
		ld	de, aVerifyYN	; "\n\rVerify ((Y)/N)?:"
		call	zm_prnst
		call	0F35Ch		; GETMS: EINGABE ZEICHENKETTE IN MONITORPUFFER
		jp	c, break
		ld	a, (CONBU+2)
		cp	'N'
		jp	z, savemsg1

;Verify
		ld	de, aRewind	; "\n\rRewind \x14\x01<==\x14\x02 "
		call	zm_prnst
		call	0F35Ch		; GETMS: EINGABE ZEICHENKETTE IN MONITORPUFFER
		jp	c, break
csave3:		ld	hl, CONBU	; CCP-Eingabepuffer und	Standardpuffer f³r Kassetten-E/A
		ld	(DMA), hl
		call	zm_openr
		jr	c, csave4
		call	stop		; Test,	ob <STOP> gedrückt -> Cy=1
		jr	nc, csave7
		jr	break
csave4:		or	a
		jr	z, break
		call	0F5A6h		; REA1
		jr	c, break
		jr	csave3
csave5:		call	zm_reads
		jr	nc, csave6
		call	0F5A6h		; REA1
		jr	c, break1
		jr	csave5
csave6:		ld	l, a
		call	stop		; Test,	ob <STOP> gedrückt -> Cy=1
		jr	c, break1
		ld	a, l
csave7:		ld	hl, CONBU	; CCP-Eingabepuffer und	Standardpuffer f³r Kassetten-E/A
		ld	(DMA), hl
		or	a
		jr	z, csave5
		ld	de, aSaveComplete ; "\n\r\x14\x01Save complete\n\r\n"
csave8:		call	zm_prnst
		ld	a, 14h
		call	zo_consa	; Zeichenausgabe A
		ld	a, 4
		call	zo_consa	; Zeichenausgabe A
		ld	a, (varsav)
		call	out_a		; Ausgabe A hexadezimal	ASCII 2	Stellen
		ld	de, aRecordSWritten ; "\x14\x02	Record(s) written\n\r"
		call	zm_prnst
		ld	a, 14h
		call	zo_consa	; Zeichenausgabe A
		ld	a, 4
		call	zo_consa	; Zeichenausgabe A
		ld	a, (LBLNR)
		dec	a
		call	out_a		; Ausgabe A hexadezimal	ASCII 2	Stellen
		ld	de, aRecordSChecked ; "\x14\x02	Record(s) checked\n\r\n"
		jp	zm_prnst

;
breaknw:	ld	de, aBreakByStopKey ; Break, "no records written"
		call	zm_prnst
		ld	de, aNo		; "\x14\x04No\x14\x02"
		call	zm_prnst
;
savemsg:	ld	de, aRecordSWritten ; "\x14\x02	Record(s) written\n\r"
		call	zm_prnst
		ld	de, aNo		; "\x14\x04No\x14\x02"
		call	zm_prnst
		ld	de, aRecordSChecked ; "\x14\x02	Record(s) checked\n\r\n"
		jp	zm_prnst
;
break:		ld	de, aBreakByStopKey ; "\n\r\x14\x01Break by \x14\x04\"STOP\"\x14\x01-Key!\x14\x02\n\r\r\n"
		call	zm_prnst
;
savemsg1:	ld	a, 14h
		call	zo_consa	; Zeichenausgabe A
		ld	a, 4
		call	zo_consa	; Zeichenausgabe A
		ld	a, (varsav)
		call	out_a		; Ausgabe A hexadezimal	ASCII 2	Stellen
		jr	savemsg
;
break1:		ld	de, aBreakByStopKey ; "\n\r\x14\x01Break by \x14\x04\"STOP\"\x14\x01-Key!\x14\x02\n\r\r\n"
		jr	csave8

aSaveComplete:	db 0Ah
		db 0Dh,14h,1,"Save complete",0Ah
		db 0Dh,0Ah,0
aRecordSWritten:db 14h,2," Record(s) written",0Ah
		db 0Dh,0
aRecordSChecked:db 14h,2," Record(s) checked",0Ah
		db 0Dh,0Ah,0
aVerifyYN:	db 0Ah
		db 0Dh,"Verify ((Y)/N)?:",0
aRewind:	db 0Ah
		db 0Dh,"Rewind ",14h,1,"<==",14h,2,' ',0
aBreakByStopKey:db 0Ah
		db 0Dh,14h,1,"Break by ",14h,4,"\"STOP\"",14h,1,"-Key!",14h,2,0Ah
		db 0Dh,0Dh,0Ah,0
aNo:	db 14h,4,"No",14h,2,0


;------------------------------------------------------------------------------
; allg. Unterprogramme
;------------------------------------------------------------------------------

; Ausgabe A hexadezimal	ASCII 2	Stellen
out_a:		push	af
		and	0F0h
		rlca
		rlca
		rlca
		rlca
		call	out_a1
		pop	af
		and	0Fh
out_a1:		add	a, '0'
		cp	'9'+1
		jr	c, out_a2
		add	a, 7
out_a2:		jr	zo_consa	; Zeichenausgabe A


;
zm_openw:	ld	c, 0Fh		; OPENW: Eröffnen Kassette schreiben
		jr	jmp_sys

;
zm_writs:	ld	c, 15h		; WRITS: Schreiben eines Blockes auf Kassette
		jr	jmp_sys

;
zm_closw:	ld	c, 10h		; CLOSW: Abschließen Kassette schreiben
		jr	jmp_sys

;
zm_prnst:	ld	c, 9		; PRNST: Ausgabe einer Zeichenkette zu CONST
		jr	jmp_sys

;
zm_openr:	ld	c, 0Dh		; OPENR: Eröffnen Kassette lesen
		jr	jmp_sys
;
zm_reads:	ld	c, 14h		; READS: Lesen eines Blockes von Kassette
jmp_sys:	jp	5

; Zeichenausgabe A
zo_consa:	ld	c, a
		jp	zm_conso	; Zeichenausgabe

; Ausgabe Leerzeichen +	Test auf <STOP>
sp_stop:	call	0F310h		; OSPAC


; Test,	ob <STOP> gedrückt -> Cy=1
stop:		call	0FD33h		; DECO0, DECODIEREN DER	TASTATURMATRIX
		ei
		or	a
		ret	z
		cp	3		; <STOP> ?
		scf
		ret	z
		ccf
		ret

nokey:		xor	a
		ld	(25h), a	; KEYBU
		ret

; ABFRAGE I/O-BYTE
GIOBY:		ld	a, (IOBYT)
		ret

; SETZEN I/O-BYTE
SIOBY:		ld	a, c
		ld	(IOBYT), a
		ret

;------------------------------------------------------------------------------
; Test RAM-Größe
;------------------------------------------------------------------------------

;
eor0:		push	hl
		call	eor		; EOR ermitteln
		ld	a, l
		sub	3Ch 		; ???
		jr	nc, eor01
		dec	h
eor01:		ld	b, h
		pop	hl
		ret

; EOR ermitteln
eor:		push	bc
eor1:		ld	hl, 0FFFFh
eor2:		inc	h		; nächste xxFFh-Adresse
		ld	a, (hl)
		cpl
		ld	(hl), a
		cp	(hl)
		cpl
		ld	(hl), a
		jr	nz, eor2	; solange RAM-Speicher
eor3:		inc	h		; nächste xxFFh-Adresse
		ld	a, (begdat+1)	; = HI(Programmanfang)
		cp	h
		jr	z, eor4		; max bis Programmstandort
		ld	a, (hl)
		cpl
		ld	(hl), a
		cp	(hl)
		cpl
		ld	(hl), a
		jr	z, eor3		; solange ROM-Speicher
eor4:		dec	h
		ld	bc, -(tab_reg-regrstor)
		add	hl, bc
		pop	bc
		ret

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

		IF ROM=0

aZ9001MonitorV2:db 0Dh,0Ah
		db 0Ch
		db 7,14h,2," Z9001 MONITOR V2.0 (RAM)",14h,4,"  1985 ",14h,2
		db 0Dh,0Ah,0
		
		ELSEIF ROM=1

aZ9001MonitorV2:db 0Dh,0Ah
		db 0Ch
		db 7,14h,2," Z9001 MONITOR CENT. ",14h,1,"1986       ",14h,2
		db 0Dh,0Ah,0

		ELSEIF ROM=2

aZ9001MonitorV2:db 0Dh,0Ah
		db 0Ch
		db 7,14h,2," Z9001 MONITOR V2.0 (ROM)",14h,4,"  1985 ",14h,2
		db 0Dh,0Ah,0
		
		ENDIF


init:		ld	de, 220h	; von 220 bis 22f (Startadressen der 5 User-Routinen) "jp error" schreiben
		ld	a, lo(220h+5*3)
init1:		ld	bc, 3
		ld	hl, exerr	; Adresse "jp error"
		ldir
		cp	e
		jr	nz, init1
;
		ld	a, 0C3h		; "JP", RST 38 initialisieren
		ld	(0038h), a
		ld	hl, exrst38
		ld	(0039h), hl
;
		ld	a, 1		; IO-Byte zurücksetzen
		ld  	(IOBYT), A
		ld 	sp,init2+1
init2		jp	eor1
		dw	init2a
;
init2a:		ld	sp, hl
		ex	de, hl
		ld	bc, tab_reg-regrstor
		ld	hl, regrstor	; Register restaurieren
		ldir
		ex	de, hl
		ld	bc, -6Fh
		add	hl, bc
		push	hl
		ld	bc, -20h
		add	hl, bc
		ld	(0036h), hl	; EOR
		ld	hl, 0
		ld	b, 9
init3:		push	hl
		djnz	init3
		ld	a, r
		ld	l, a
		ld	a, i
		ld	h, a
		push	hl
;
		ld	b, init-aZ9001MonitorV2	; Länge der Systemmeldung aZ9001MonitorV2
		call	zmmsg		; Ausgabe der Systemmeldung
;
		in	a, (PIO1AD)	; PIO1 A Daten Beeper, Border, 20Z
		set	2, a
		out	(PIO1AD), a	; PIO1 A Daten Beeper, Border, 20Z
;
		ld	hl, 1500h
		ld	(P1ROL), hl	; 1. rollende Zeile - 1
		ld	hl, (0EFE1h)	; Adresse TTY-Treiber für LIST
		push	hl
		call	inittreiber
		pop	hl
		ld	(0EFE1h), hl	; Adresse TTY-Treiber für LIST

;------------------------------------------------------------------------------
; Hauptschleife
;------------------------------------------------------------------------------

prompt:		ld	de, prompt
		push	de
		call	out_crlf
		ld	c, '='
		call	zm_conso	; Zeichenausgabe
		ld	c, '>'
		call	zm_conso	; Zeichenausgabe
prompt1:	call	zm_char		; Eingabe Buchstabe oder ENTER
		and	7Fh
		jr	z, prompt1
		sub	'A'             ; A = 0..19h
		ret	m
		cp	1Ah
		ret	nc
		add	a, a
		ld	hl, kdo_tab
		add	a, l
		ld	l, a
		ld	a, h
		adc	a, 0
		ld	h, a
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a		; HL=Adr. Kommando
		ld	c, 2		; Std. 2 Parameter
		jp	(hl)		; Kommando starten

; Sprungverteiler ZM-Kommandos
kdo_tab:	dw kdo_a		; Geraetezuweisung
		dw bye			; Rueckgabe an das OS
		dw convert		; Umrechnung Dezimalzahl in Hexadezimalzahl und	umgekehrt
		dw display		; Ausgabe von Speicherbereichen	auf Konsole (Hexdump)
		dw endblock		; Ausgabe eines	Endeblockes
		dw fill			; Beschreiben eines Speicherbereiches mit konst. Wert
		dw go			; Start	eines Anwenderprogramms
		dw kdo_h		; Bildung der Summe und	Differenz zweier Hexzahlen
		dw 220h
		dw kdo_j		; Nichtzerstoerender Speichertest
		dw 223h
		dw 226h
		dw move			; Transport eines Speicherbereiches auf	einen anderen Speicherbereich
		dw null
		dw 229h
		dw punch		; Ausgabe im INTEL-Hex-Format auf den Punch-Kanal
		dw kdo_q		; Lesen	und Schreiben auf I/O-Ports
		dw read			; Einlesen eines INTEL-Hex-Files ueber den Reader-Kanal
		dw Substitute		; Modifizieren von Speicherzellen
		dw Type			; Ausgabe in ASCII-Darstellung
		dw 22Ch
		dw kdo_v		; Vergleich eines Speicherbereiches mit	einem anderen
		dw write		; Schreiben von	ASCII-Zeichen in den Speicher
		dw kdo_x		; Ausgabe des Z80-Registersatzes
		dw kdo_y		; Suchen einer Zeichenfolge von	max. 255 byte
		dw kdo_z		; Ausgabe der höchsten RAM-Adresse (RAM-TOP)

exerr:		jp	error

;------------------------------------------------------------------------------
; A   Geraetezuweisung
;       C fuer CONSOL
;       R fuer READER
;       P fuer PUNCH
;     Folgende Zuordnungen sind moeglich
;       AC=C f.Konsole (m. BEEP)
;	 =V f.Konsole (o. BEEP)
;       AR=C f.Konsole
;	 =T f.Kassette
;       AP=C f.Konsole
;	 =T f.Kassette
;     Nach Anlauf des Monitors gilt
;       AC=V, AR=C, AP=C
;------------------------------------------------------------------------------

kdo_a:		call	zm_char		; Geraetezuweisung
		ld	hl, tab_asgn
		ld	bc, 400h	; B := 4, C := 0
		ld	de, 5
kdo_a1:		cp	(hl)		; Suche	Dest-Gerät
		jr	z, kdo_a2
		add	hl, de
		inc	c
		djnz	kdo_a1		; Suche	Dest-Gerät
		jr	kdo_a5
kdo_a2:		ld	e, c
kdo_a3:		call	zm_char		; Eingabe Buchstabe oder ENTER
		cp	'='
		jr	nz, kdo_a3
		call	zm_char		; Eingabe Buchstabe oder ENTER
		ld	bc, 400h	; B := 4, C := 0
kdo_a4:		inc	hl
		cp	(hl)
		jr	z, kdo_a6
		inc	c
		djnz	kdo_a4
kdo_a5:		jp	error
;
kdo_a6:		ld	a, 3
		inc	e
kdo_a7:		dec	e
		jr	z, kdo_a8
		sla	c
		sla	c
		rla
		rla
		jr	kdo_a7
kdo_a8:		cpl
		ld	d, a
kdo_a9:		call	getch		; nächstes Zeichen lesen; Test auf Leerzeichen oder Enter
		jr	nc, kdo_a9
		ld	a, (4)
		and	d
		or	c
		ld	c, a
		jp	SIOBY		; SETZEN I/O-BYTE

;------------------------------------------------------------------------------
;  B   Rueckgabe an das OS
;------------------------------------------------------------------------------

bye:		call	eor		; Rueckgabe an das OS
		ld	bc, tab_reg-regrstor
		add	hl, bc
		ld	(0036h), hl	; Speicher vor EOR wieder freigeben
		jp	0F003h		; JP WBOOT

;------------------------------------------------------------------------------
; Schreiben von ASCII-Zeichen in den
;      Speicher
;        W anfadr
;------------------------------------------------------------------------------

write:		call	param		; Schreiben von	ASCII-Zeichen in den Speicher
		call	out_crlf
		pop	hl
write1:		call	zm_consi7	; Zeicheneingabe, 7 Bit
		cp	3		; <STOP> ?
		jp	z, outnlhlsp	; Ausgabe CR,LF, HL hexa 4 Stellen, SP
		cp	8		; <Backspace> ?
		jr	z, write3
		ld	(hl), a		; Zeichen in Speicher schreiben
		ld	c, a
		inc	hl		; nächste Adresse
write2:		call	zm_conso	; Zeichenausgabe
		jr	write1
write3:		dec	hl
		ld	c, a
		jr	write2

;------------------------------------------------------------------------------
; C   Umrechnung Dezimalzahl in Hexa-
;     dezimalzahl und umgekehrt
;       CD (dez. z.) Dez. = > Hex.
;       CH (hex. z.) Hex. = > Dez.
;------------------------------------------------------------------------------

convert:	call	zm_char		; Umrechnung Dezimalzahl in Hexadezimalzahl und	umgekehrt
		cp	'D'
		jr	nz, convert1
		ld	hl, error
		push	hl
;
getdez:		ld	hl, 0
getdez1:	call	zm_char		; Eingabe Buchstabe oder ENTER
		cp	30h ; '0'
		jr	c, getdez2
		cp	3Ah ; ':'
		jr	nc, getdez2
		sub	30h ; '0'
		ld	d, h
		ld	e, l
		add	hl, hl
		ret	c
		add	hl, hl
		ret	c
		add	hl, de
		ret	c
		add	hl, hl
		ret	c
		ld	d, 0
		ld	e, a
		add	hl, de
		ret	c
		jr	getdez1
;
getdez2:	pop	de
		call	outsp		; Leerzeichen ausgeben
		call	outhl		; Ausgabe HL hexadezimal ASCII 4 Stellen
		ld	c, 'H'
		call	zm_conso	; Zeichenausgabe
		jr	bin_hl		; Ausgabe HL binär
;
convert1:	call	param		; 1 Parameter holen
		pop	hl
		call	bin_hl		; Ausgabe HL binär
;
todez:		ld	b, 10h
		ld	de, 0
		ld	c, e
todez1:		add	hl, hl
		ld	a, e
		adc	a, e
		daa
		ld	e, a
		ld	a, d
		adc	a, d
		daa
		ld	d, a
		ld	a, c
		adc	a, c
		ld	c, a
		djnz	todez1
		ld	b, c
		call	outsp		; Leerzeichen ausgeben
		ld	a, b
		or	a
		jr	z, todez2
		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
todez2:		ex	de, hl
		call	outhl		; Ausgabe HL hexadezimal ASCII 4 Stellen
		ld	c, 'D'
		jp	zm_conso	; Zeichenausgabe

; Ausgabe HL binär
bin_hl:		ld	e, h
		call	bin_e		; Ausgabe E binär
		ld	e, l
		call	bin_e		; Ausgabe E binär
		ld	c, 'B'
		jp	zm_conso	; Zeichenausgabe

; Anzeige HL, (HL), A

outmem:		ld	b, a
		call	outhlsp		; Ausgabe HL + Space
		ld	a, (hl)
		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
		call	outsp		; Leerzeichen ausgeben
		ld	a, b
		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
		jp	out_crlf

;------------------------------------------------------------------------------
; D   Ausgabe von Speicherbereichen
;     auf Konsole  (Hexdump)
;       D anfadr_endadr
;------------------------------------------------------------------------------

display:	call	twoparams	; Ausgabe von Speicherbereichen	auf Konsole (Hexdump)
display1:	call	outnlhlsp	; Ausgabe CR,LF, HL hexa 4 Stellen, SP
display2:	call	outsp		; Leerzeichen ausgeben
		ld	a, (hl)
		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
		call	nextadr1
		ld	a, l
		and	7
		jr	nz, display2
		jr	display1

;------------------------------------------------------------------------------
;  E   Ausgabe eines Endeblockes
;------------------------------------------------------------------------------

endblock:	call	param		; Ausgabe eines	Endeblockes
		call	pun_crlf
		ld	c, ':'
		call	zm_puno
		xor	a
		call	punch_a		; Ausgabe A auf	PUNCH
		pop	hl
		call	punch_hl
		ld	hl, 0
		call	punch_hl
		ld	a, 1Ah
		call	punch_a		; Ausgabe A auf	PUNCH
		jp	null
;------------------------------------------------------------------------------
; F   Beschreiben eines Speicherbe-
;     reiches mit konst. Wert
;       F anfadr_endadr_wert
;------------------------------------------------------------------------------

fill:		call	threeparams	; Beschreiben eines Speicherbereiches mit konst. Wert
fill1:		ld	(hl), c
		call	nextadr		; incl HL, HL=0	oder HL=DE?
		jr	nc, fill1
		pop	de
		jp	prompt

;------------------------------------------------------------------------------
; G   Start eines Anwenderprogramms
;       G anfadr
;------------------------------------------------------------------------------

go:		call	getch		; Start	eines Anwenderprogramms
		jr	c, go5
		jr	z, go1
		call	param1		; 1 Parameter holen; das aktuelle Zeichen gehört schon zum Parameter
		pop	de
		ld	hl, 34h	; ???
		add	hl, sp
		ld	(hl), d
		dec	hl
		ld	(hl), e
		ld	a, b
		cp	0Dh
		jr	z, go5
go1:		ld	d, 2
		ld	hl, 35h	; ???
		add	hl, sp
go2:		push	hl
		call	param		; 1 Parameter holen
		ld	e, b
		pop	bc
		pop	hl
		ld	a, b
		or	c
		jr	z, go3
		ld	(hl), c
		inc	hl
		ld	(hl), b
		inc	hl
		ld	a, (bc)
		ld	(hl), a
		inc	hl
		ld	a, 0FFh
		ld	(bc), a
go3:		ld	a, e
		cp	0Dh
		jr	z, go4
		dec	d
		jr	nz, go2
go4:		ld	a, 0C3h		; JP
		ld	(38h), a
		ld	hl, exrst38
		ld	(39h), hl
go5:		call	out_crlf
		pop	de
		ld	hl, 16h		; ???
		add	hl, sp
		jp	(hl)

;------------------------------------------------------------------------------
; J   Nichtzerstoerender Speichertest
;       J anfadr_endadr
;------------------------------------------------------------------------------

kdo_j:		call	twoparams
kdo_j1:		ld	a, (hl)
		ld	b, a
		cpl
		ld	(hl), a
		xor	(hl)
		jr	z, kdo_j2
		push	de
		ld	d, b
		ld	e, a
		call	outhlsp		; Ausgabe HL + Space
		call	bin_e		; Ausgabe E binär
		call	out_crlf
		ld	b, d
		pop	de
kdo_j2:		ld	(hl), b
		call	nextadr1
		jr	kdo_j1

;------------------------------------------------------------------------------
; M   Transport eines Speicherbereiches
;     auf einen anderen Speicherbereich
;       M anfadr_endadr_zieladr
;------------------------------------------------------------------------------

move:		call	threeparams	; Transport eines Speicherbereiches auf	einen anderen Speicherbereich
move1:		ld	a, (hl)
		ld	(bc), a
		inc	bc
		call	nextadr1
		jr	move1

;------------------------------------------------------------------------------
; R   Einlesen eines INTEL-Hex-Files
;     ueber den Reader-Kanal
;       R
;------------------------------------------------------------------------------

read:		call	param		; Einlesen eines INTEL-Hex-Files ueber den Reader-Kanal
		ld	a, b
		sub	0Dh
		ld	b, a
		ld	c, a
		pop	de
		jr	z, read1
		call	param		; 1 Parameter holen
		pop	bc
read1:		ex	de, hl
		exx
		call	out_crlf
read2:		call	readd7		; Zeicheneingabe 7 Bit
		sub	3Ah ; ':'
		ld	b, a
		and	0FEh ; '¦'
		jr	nz, read2
		ld	d, a
		call	read_2ziff	; Eingabe 2 Hexziffern -> A, aufsummieren auf D
		ld	e, a
		call	read_2ziff	; Eingabe 2 Hexziffern -> A, aufsummieren auf D
		push	af
		call	read_2ziff	; Eingabe 2 Hexziffern -> A, aufsummieren auf D
		exx
		pop	de
		ld	e, a
		push	bc
		push	de
		push	hl
		add	hl, de
		ex	(sp), hl
		pop	ix
		exx
		pop	hl
		call	read_2ziff	; Eingabe 2 Hexziffern -> A, aufsummieren auf D
		dec	a
		ld	a, b
		pop	bc
		jr	nz, read3
		add	hl, bc
		add	ix, bc
read3:		inc	e
		dec	e
		jr	z, read7
		dec	a
		jr	z, read8
read4:		call	read_2ziff	; Eingabe 2 Hexziffern -> A, aufsummieren auf D
		call	sub_77A3
		jr	nz, read4
read5:		call	read_2ziff	; Eingabe 2 Hexziffern -> A, aufsummieren auf D
		jr	z, read2
read6:		push	ix
		pop	hl
		call	outhl		; Ausgabe HL hexadezimal ASCII 4 Stellen
		jp	error
;
read7:		ld	a, h
		or	l
		ret	z
		ex	de, hl
		ld	hl, 34h	; '4'
		add	hl, sp
		ld	(hl), d
		dec	hl
		ld	(hl), e
		ret
;
read8:		ld	l, 1
read9:		call	sub_7780
		jr	c, read11

read10:		call	sub_77A3
		jr	nz, read9
		jr	read5
;
read11:		ld	c, a
		call	sub_7780
		ld	b, a
		exx
		push	bc
		exx
		ex	(sp), hl
		add	hl, bc
		ld	a, l
		call	sub_77A3
		ld	a, h
		pop	hl
		jr	read10

;
sub_7780:	dec	l
		jr	nz, loc_778A
		call	read_2ziff	; Eingabe 2 Hexziffern -> A, aufsummieren auf D
		dec	e
		ld	h, a
		ld	l, 8
loc_778A:	call	read_2ziff	; Eingabe 2 Hexziffern -> A, aufsummieren auf D
		sla	h
		ret

; Eingabe 2 Hexziffern -> A, aufsummieren auf D
read_2ziff:	push	bc
		call	read_ziff
		rlca
		rlca
		rlca
		rlca
		ld	c, a
		call	read_ziff
		or	c
		ld	c, a
		add	a, d
		ld	d, a
		ld	a, c
		pop	bc
		ret

;
sub_77A3:	ld	(ix+0),	a
		cp	(ix+0)
		jr	nz, read6
		inc	ix
		dec	e
		ret

;------------------------------------------------------------------------------
; S   Modifizieren von Speicherzellen
;       S anfadr
;------------------------------------------------------------------------------

Substitute:	call	param		; Modifizieren von Speicherzellen
		pop	hl		; anfadr
Substitute1:	ld	a, (hl)
		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
		call	outminus	; Ausgabe '-'-Zeichen, nächstes Zeichen lesen
		ret	c		; bei <ENTER>
		jr	z, Substitute2
		cp	5Fh ; '_'
		jr	z, Substitute4
		push	hl
		call	param1		; 1 Parameter holen; das aktuelle Zeichen gehört schon zum Parameter
		pop	de
		pop	hl
		ld	(hl), e
		ld	a, b
		cp	0Dh
		ret	z
;
Substitute2:	inc	hl
Substitute3:	ld	a, l
		and	3
		call	z, outnlhlsp	; Ausgabe CR,LF, HL hexa 4 Stellen, SP
		jr	Substitute1
Substitute4:	dec	hl
		jr	Substitute3

;------------------------------------------------------------------------------
; T   Ausgabe in ASCII-Darstellung
;       T anfadr_endadr
;------------------------------------------------------------------------------

Type:		call	twoparams	; Ausgabe in ASCII-Darstellung
Type1:		call	outnlhlsp	; Ausgabe CR,LF, HL hexa 4 Stellen, SP
		ld	b, 20h
Type2:		ld	a, (hl)
		and	7Fh
		cp	' '
		jr	nc, Type4
Type3:		ld	a, '.'
Type4:		cp	7Ch ; '|'
		jr	nc, Type3
		ld	c, a
		call	zm_conso	; Zeichenausgabe
		call	nextadr1
		djnz	Type2
		jr	Type1

;------------------------------------------------------------------------------
; Y   Suchen einer Zeichenfolge von max.
;     255 byte
;       Y byte_byte   u.s.w.
;------------------------------------------------------------------------------

kdo_y:		ld	d, 0		; Suchen einer Zeichenfolge von	max. 255 byte
kdo_y1:		call	param		; 1 Parameter holen
		pop	hl
		ld	h, l
		push	hl
		inc	sp
		inc	d
		ld	a, b
		sub	0Dh
		jr	nz, kdo_y1
		ld	b, a
		ld	c, a
		ld	h, a
		ld	l, d
		dec	l
		add	hl, sp
		push	hl
		push	bc
kdo_y2:		push	bc
		call	out_crlf
		pop	bc
kdo_y3:		pop	hl
		pop	ix
		ld	e, d
		ld	a, (ix+0)
		cpir
		jp	po, kdo_y6
		push	ix
		push	hl
kdo_y4:		dec	e
		jr	z, kdo_y5
		ld	a, (ix-1)
		cp	(hl)
		jr	nz, kdo_y3
		inc	hl
		dec	ix
		jr	kdo_y4
kdo_y5:		pop	hl
		push	hl
		dec	hl
		push	bc
		call	outhl		; Ausgabe HL hexadezimal ASCII 4 Stellen
		pop	bc
		jr	kdo_y2
kdo_y6:		inc	sp
		dec	e
		jr	nz, kdo_y6
		ret

;------------------------------------------------------------------------------
; P   Ausgabe im INTEL-Hex-Format auf den
;     Punch-Kanal
;       P anfadr_endadr (_stadr bei AP=T)
;------------------------------------------------------------------------------

punch:		call	twoparams	; Ausgabe im INTEL-Hex-Format auf den Punch-Kanal
punch1:		call	pun_crlf
		ld	bc, 3Ah	; ':'
		call	zm_puno
		push	de
		push	hl
punch2:		inc	b
		call	nextadr		; incl HL, HL=0	oder HL=DE?
		jr	c, punch5
		ld	a, 18h
		sub	b
		jr	nz, punch2
		pop	hl
		call	punch3
		pop	de
		jr	punch1
;
punch3:		ld	d, a
		ld	a, b
		call	punch_a		; Ausgabe A auf	PUNCH
		call	punch_hl
		xor	a
		call	punch_a		; Ausgabe A auf	PUNCH
punch4:		ld	a, (hl)
		call	punch_a		; Ausgabe A auf	PUNCH
		inc	hl
		djnz	punch4
		xor	a
		sub	d
		jp	punch_a		; Ausgabe A auf	PUNCH
;
punch5:		pop	hl
		pop	de
		xor	a
		jr	punch3

;------------------------------------------------------------------------------
; X   Ausgabe des Z80-Registersatzes
;       X  1.Registersatz
;       X' 2.Registersatz
;------------------------------------------------------------------------------

kdo_x:		call	zm_char		; Eingabe Buchstabe oder ENTER
		ld	hl, tab_reg
		cp	0Dh		; <Enter>?
		jr	z, kdo_x7
		cp	27h ; '''       ; zweiter Registersatz?
		jr	nz, kdo_x1
		ld	hl, tab_reg2
		call	zm_char		; Eingabe Buchstabe oder ENTER
		cp	0Dh		; <Enter>?
		jr	z, kdo_x7

; Register ändern
kdo_x1:		cp	(hl)		; Registernamen vergleichen
		jr	z, kdo_x2	; wenn gefunden
		bit	7, (hl)		; Tabellenende?
		jp	nz, error	; dann, Fehler
		inc	hl		; zum nächsten Registernamen
		inc	hl
		jr	kdo_x1
;		
kdo_x2:		call	outsp		; Leerzeichen ausgeben
kdo_x3:		inc	hl		; in Registertabelle
		ld	a, (hl)		; Offset für Registerwert
		ld	b, a
		and	3Fh ; '?'	; obere Bits ausblenden
		ex	de, hl
		ld	l, a
		ld	h, 0
		add	hl, sp
		ex	de, hl
		inc	hl
		ld	a, (de)		; Wert holen
		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
		bit	7, b
		jr	z, kdo_x4
		dec	de
		ld	a, (de)
		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
kdo_x4:		call	outminus	; Ausgabe '-'-Zeichen, nächstes Zeichen lesen
		ret	c
		jr	z, kdo_x6
		push	hl
		push	bc
		call	param1		; 1 Parameter holen; das aktuelle Zeichen gehört schon zum Parameter
		pop	hl
		pop	af
		push	bc
		push	af
		ld	a, l
		ld	(de), a
		pop	bc
		bit	7, b
		jr	z, kdo_x5
		inc	de
		ld	a, h
		ld	(de), a
kdo_x5:		pop	bc
		pop	hl
		ld	a, b
		cp	0Dh
		ret	z
kdo_x6:		bit	7, (hl)
		ret	nz
		jr	kdo_x3

; Register anzeigen
kdo_x7:		call	out_crlf
kdo_x8:		call	outsp		; Leerzeichen ausgeben
		ld	a, (hl)
		inc	hl
		or	a
		ret	m
		ld	c, a
		call	zm_conso	; Zeichenausgabe
		ld	c, '='
		call	zm_conso	; Zeichenausgabe
		ld	a, (hl)
		ld	b, a
		and	3Fh ; '?'
		inc	hl
		ex	de, hl
		ld	l, a
		ld	h, 0
		add	hl, sp
		ex	de, hl
		bit	6, b
		jr	nz, kdo_x10
		ld	a, (de)
		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
		bit	7, b
		jr	z, kdo_x8
		dec	de
		ld	a, (de)
kdo_x9:		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
		jr	kdo_x8
kdo_x10:	push	hl
		ld	a, (de)
		ld	h, a
		dec	de
		ld	a, (de)
		ld	l, a
		ld	a, (hl)
		pop	hl
		jr	kdo_x9

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

;
zmmsg:		ld	hl, aZ9001MonitorV2 ; "\r\n\f\a\x14\x02	Z9001 MONITOR V2.0 (RAM)\x14\x04  1985"...

;
prnstr:		ld	c, (hl)		; Stringausgabe, HL=String, B=Länge
		inc	hl
		call	zm_conso	; Zeichenausgabe
		djnz	prnstr		; Stringausgabe, HL=String, B=Länge
		call	tm_csts
		or	a
		ret	z
		call	zm_consi7	; Zeicheneingabe, 7 Bit
		cp	3		; <STOP> ?
		jr	z, error	; dann Abbruch
		call	zm_consi7	; Zeicheneingabe, 7 Bit
		ret

;
error:		call	eor
		ld	de, -16h
		add	hl, de
		ld	sp, hl
		ld	c, 7
		call	zm_conso	; Zeichenausgabe
		ld	c, '*'
		call	zm_conso	; Zeichenausgabe
		jp	prompt

; Zeicheneingabe und Vergleich mit D
zm_readd:	call	zm_readi
		cp	d
		ret

;------------------------------------------------------------------------------
; Ausgabe der höchsten RAM-Adresse (RAM-TOP)
;------------------------------------------------------------------------------

kdo_z:		call	eor
		ld	bc, tab_reg-regrstor
		add	hl, bc

; Ausgabe CR,LF, HL hexa 4 Stellen, SP
outnlhlsp:	call	out_crlf

; Ausgabe HL + Space
outhlsp:	call	outhl		; Ausgabe HL hexadezimal ASCII 4 Stellen

; Leerzeichen ausgeben
outsp:		ld	c, ' '
		jp	zm_conso	; Zeichenausgabe

;
pun_crlf:	ld	c, 0Dh
		call	zm_puno
		ld	c, 0Ah
		jp	zm_puno


;------------------------------------------------------------------------------
; N (Null): Ausgabe von binären Nullen auf den Punch-Kanal.
; (Lochbandvorschub, sinnlos bei AP=T)
;------------------------------------------------------------------------------

null:		call	punch_init	; Ausgabe 72 Nullen auf	Punch
		ret

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

; Konvertierung	low Nibble A in	Hex Ascii
hexa:		and	0Fh
		add	a, 90h ; 'É'
		daa			; DAA-Trick
		adc	a, 40h ; '@'
		daa
		ld	c, a
		ret

; zwei Parameter holen (HL, DE := DE|HL+003F)
twoparams:	call	params		; C Parameter holen
		pop	de		; parameter 2
		pop	hl		; parameter 1
		push	hl
		ld	a, d		; paramter 2 = 0?
		or	e
		jr	nz, twoparams1	; nein
		ld	de, 3Fh	; '?'   ; ja: 003F zum 1. Parameter addieren
		add	hl, de
		ex	de, hl
twoparams1:	pop	hl

; CR+LF ausgeben
out_crlf:	push	hl
		ld	b, 2		; Ausgabe der ersten zwei Zeichen der Systemmeldung (CR+LF)
		call	zmmsg
		pop	hl
		ret

; 3 Parameter holen -> HL, DE, BC
threeparams:	inc	c
		call	params		; C Parameter holen
		call	out_crlf
		pop	bc
		pop	de
		pop	hl
		ret

; 1 Parameter holen
param:	ld	c, 1

; C Parameter holen
params:		ld	hl, 0
params1:	call	zm_char		; Eingabe Buchstabe oder ENTER
params2:	ld	b, a		; Zeichen sichern
		call	tst_ziff	; Test auf Ziffer
		jr	c, params3	; Parameter auf	Stack legen
		add	hl, hl		; HL :=	HL*10h
		add	hl, hl
		add	hl, hl
		add	hl, hl
		or	l
		ld	l, a		; neue Ziffer dazuaddieren
		jr	params1
params3:	ex	(sp), hl	; Parameter auf	Stack legen
		push	hl
		ld	a, b		; Zeichen restaurieren
		call	tst_next	; folgt	Leerzeichen, Komma (Z=1) oder Enter (Cy=1)?
		jr	nc, params4
		dec	c
		ret	z
params4:	jp	nz, error
		dec	c
		jr	nz, params	; C Parameter holen
		ret

; 1 Parameter holen; das aktuelle Zeichen gehört schon zum Parameter
param1:		ld	c, 1
		ld	hl, 0
		jr	params2		; Zeichen sichern


;
nextadr1:	call	nextadr		; incl HL, HL=0	oder HL=DE?
		ret	nc
		pop	de
		ret

; incl HL, HL=0	oder HL=DE?
nextadr:	inc	hl
		ld	a, h
		or	l
		scf
		ret	z		; wenn HL=0 -> Cy=1
		ld	a, e
		sub	l
		ld	a, d
		sbc	a, h		; vgl DE-HL
		ret

;------------------------------------------------------------------------------
; H   Bildung der Summe und Differenz
;     zweier Hexzahlen
;       H zahl1_zahl2
;------------------------------------------------------------------------------

kdo_h:		call	twoparams	; Bildung der Summe und	Differenz zweier Hexzahlen
		push	hl
		add	hl, de
		call	outhlsp		; Ausgabe HL + Space
		pop	hl
		or	a
		sbc	hl, de

; Ausgabe HL hexadezimal ASCII 4 Stellen
outhl:		ld	a, h
		call	outa		; Ausgabe A hexadezimal	ASCII 2	Stellen
		ld	a, l

; Ausgabe A hexadezimal	ASCII 2	Stellen
outa:		push	af
		rrca
		rrca
		rrca
		rrca
		call	outa1
		pop	af
outa1:		call	hexa		; Konvertierung	low Nibble A in	Hex Ascii
		jp	zm_conso	; Zeichenausgabe


punch_init0:	ld	bc, 8FFh
		jr	puni1

; Ausgabe 72 Nullen auf	Punch
punch_init:	ld	bc, 4800h	; B=48H, C=0
puni1:		call	zm_puno
		djnz	puni1
		ret

;
read_ziff:	call	readd7		; Zeicheneingabe 7 Bit

; Test auf Ziffer
tst_ziff:	sub	30h ; '0'
		ret	c
		cp	17h
		ccf
		ret	c
		cp	0Ah
		ccf
		ret	nc
		sub	7
		cp	0Ah
		ret

; Ausgabe HL auf PUNCH
punch_hl:	ld	a, h
		call	punch_a		; Ausgabe A auf	PUNCH
		ld	a, l

; Ausgabe A auf PUNCH
punch_a:	push	af
		rrca
		rrca
		rrca
		rrca
		call	hexa		; Konvertierung	low Nibble A in	Hex Ascii
		call	zm_puno
		pop	af
		push	af
		call	hexa		; Konvertierung	low Nibble A in	Hex Ascii
		call	zm_puno
		pop	af
		add	a, d
		ld	d, a
		ret

; Ausgabe '-'-Zeichen, nächstes Zeichen lesen
outminus:	ld	c, '-'
		call	zm_conso	; Zeichenausgabe

; nächstes Zeichen lesen; Test auf Leerzeichen oder Enter
getch:	call	zm_char		; Eingabe Buchstabe oder ENTER

; folgt	Leerzeichen, Komma (Z=1) oder Enter (Cy=1)?
tst_next:	cp	' '
		ret	z
		cp	','
		ret	z
		cp	0Dh
		scf
		ret	z
		ccf
		ret

; Zeicheneingabe 7 Bit
readd7:		call	zm_readd	; Zeicheneingabe und Vergleich mit D
		and	7Fh
		ret

;------------------------------------------------------------------------------
; wird bei RST 38 ausgeführt
;------------------------------------------------------------------------------

rst38:		push	hl
		push	de
		push	bc
		push	af
		call	eor
		ex	de, hl
		ld	hl, 0Ah
		add	hl, sp
		ld	b, 4
		ex	de, hl
rst38_1:	dec	hl
		ld	(hl), d
		dec	hl
		ld	(hl), e
		pop	de
		djnz	rst38_1
		pop	bc
		dec	bc
		ld	sp, hl
		ld	hl, 25h
		add	hl, sp
		ld	a, (hl)
		sub	c
		inc	hl
		jr	nz, rst38_2
		ld	a, (hl)
		sub	b
		jr	z, rst38_4
rst38_2:	inc	hl
		inc	hl
		ld	a, (hl)
		sub	c
		jr	nz, rst38_3
		inc	hl
		ld	a, (hl)
		sub	b
		jr	z, rst38_4
rst38_3:	inc	bc
rst38_4:	ld	hl, 20h
		add	hl, sp
		ld	(hl), e
		inc	hl
		ld	(hl), d
		inc	hl
		inc	hl
		ld	(hl), c
		inc	hl
		ld	(hl), b
		push	bc
		ld	c, '$'
		call	zm_conso	; Zeichenausgabe
		pop	hl
		call	outhl		; Ausgabe HL hexadezimal ASCII 4 Stellen
		ld	hl, 25h
		add	hl, sp
		ld	bc, 200h
rst38_5:	ld	e, (hl)
		ld	(hl), c
		inc	hl
		ld	d, (hl)
		ld	(hl), c
		inc	hl
		ld	a, e
		or	d
		jr	z, rst38_6
		ld	a, (hl)
		ld	(de), a
rst38_6:	inc	hl
		djnz	rst38_5
		ex	af, af'		; '
		exx
		push	hl
		push	de
		push	bc
		push	af
		push	ix
		push	iy
		ld	a, i
		ld	b, a
		ld	a, r
		ld	c, a
		push	bc
		jp	prompt


;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

; Zeicheneingabe, 7 Bit
zm_consi7:	call	zm_consi
		and	7Fh
		ret


; Eingabe Buchstabe oder ENTER
zm_char:	call	zm_consi7	; Zeicheneingabe, 7 Bit
		ret	z
		inc	a
		ret	m
		dec	a
		cp	0Dh
		ret	z
		push	bc
		ld	c, a
		call	zm_conso	; Zeichenausgabe
		ld	a, c
		pop	bc
		cp	40h ; '@'
		ret	c
		cp	7Bh ; '{'
		ret	nc
		and	5Fh
		ret

;------------------------------------------------------------------------------
;  Q   Lesen und Schreiben auf I/O-Ports
;------------------------------------------------------------------------------

kdo_q:		call	zm_char		; Lesen	und Schreiben auf I/O-Ports
		cp	'O'
		jr	z, kdo_q_out
		cp	'I'
		jp	nz, error

; Porteingabe
		call	param		; 1 Parameter holen
		pop	bc
		in	e, (c)

; Ausgabe E binär
bin_e:		ld	b, 8
		call	outsp		; Leerzeichen ausgeben
bin_e1:		sla	e
		ld	a, 18h
		adc	a, a		; 2*18h	(="0") oder 2*18h+1 (="1")
		ld	c, a
		call	zm_conso	; Zeichenausgabe
		djnz	bin_e1
		ret

; Portausgabe
kdo_q_out:	call	params		; C Parameter holen
		pop	de
		pop	bc
		out	(c), e
		ret

;------------------------------------------------------------------------------
; V   Vergleich eines Speicherbereiches
;     mit einem anderen
;       V anfadr_endadr_zieladr
;------------------------------------------------------------------------------

kdo_v:		call	threeparams	; Vergleich eines Speicherbereiches mit	einem anderen
kdo_v1:		ld	a, (bc)		; Zieladr
		cp	(hl)		; Anfangsadr
		jr	z, kdo_v2	; wenn gleich
		push	bc
;sonst Anzeige der Unterschiede
		call	outmem		; Anzeige HL, (HL), A
		pop	bc
kdo_v2:		inc	bc
		call	nextadr1
		jr	kdo_v1		; Zieladr

;------------------------------------------------------------------------------
; Liste der Zuweisungsmöglichkeiten für Assign
;------------------------------------------------------------------------------

tab_asgn:	db 'C'		; CONSOLE				ZM-Treiber
;
		db 'C'		; AC=C für Konsole (mit Tastatur-Beep) 	const
		db 'V'		; AC=V für Konsole (ohne Tastatur-Beep)  	
		db 'B'		; AC=B für BATCH  			        
		db 'U'		; AC=U für User-Konsole  			
;
		db 'R'		; READER
;
		db 'C'		; AR=C für Konsole  		
		db 'P'          ; AR=P für LB-Leser (SIF-1000)  	rdr
		db 'T'          ; AR=T für Kassette (Tape)  		ur1
		db 'U'          ; AR=U für User-Read-Gerät 
;
		db 'P'		; PUNCH
;
		db 'C'         	; AP=C für Konsole  			
		db 'P'          ; AP=P für LB-Stanzer (SIF-1000)  	PUN
		db 'T'          ; AP=T für Kassette  			ur11
		db 'U'          ; AP=U für V24-Ausgabegerät (TD40)  	list
;
		db 'L'		; LIST
;
		db 'C'		; AL=C für Konsole              
		db 'V'          ; AL=V für Konsole              	(CRTLST)
		db 'L'          ; AL=L für V24-Drucker (TD40)   	list
		db 'U'          ; AL=U für SIF-1000-Ausgabegerät	PUN


;------------------------------------------------------------------------------
; Register restaurieren
; s. init2
; Register sichern s. rst38
;------------------------------------------------------------------------------

regrstor:	pop	bc
		ld	a, c
		ld	r, a
		ld	a, b
		ld	i, a
		pop	iy
		pop	ix
		pop	af
		pop	bc
		pop	de
		pop	hl
		ex	af, af'		; '
		exx
		pop	de
		pop	bc
		pop	af
		pop	hl
		ld	sp, hl
		nop
		ld	hl, 0
		jp	0

		db    0
		db    0
		db    0
		db    0
		db    0
		db    0

;------------------------------------------------------------------------------
; Tabellen für Registeranzeige
;------------------------------------------------------------------------------

tab_reg:	db 'A'
		db  15h		; Stackoffset Register
		db 'B'
		db  13h
		db 'C'
		db  12h
		db 'D'
		db  11h
		db 'E'
		db  10h
		db 'F'
		db  14h
		db 'H'
		db  31h
		db 'L'
		db  30h
		db 'M'
		db 031h+11000000b
		db 'P'
		db 034h+10000000b
		db 'S'
		db  17h+10000000b
		db 'I'
		db    3
		db 0C1h	; -		; bit7=1 Tabellenende
;Schattenregister
tab_reg2:	db 'A'
		db    9
		db 'B'
		db  0Bh
		db 'C'
		db  0Ah
		db 'D'
		db  0Dh
		db 'E'
		db  0Ch
		db 'F'
		db    8
		db 'H'
		db  0Fh
		db 'L'
		db  0Eh
		db 'M'
		db  0Fh+11000000b
		db 'X'
		db  07h+10000000b
		db 'Y'
		db  05h+10000000b
		db 'R'
		db    2
		db 0C1h	; -		; bit7=1 Tabellenende



		if ROM<>2
;------------------------------------------------------------------------------
; Copyright
;------------------------------------------------------------------------------

aF_schwarzenber:
		db " F.Schwarzenberg 8036,Gamigstr.5 ",0

;------------------------------------------------------------------------------
; CRT-Treiber für LIST
;------------------------------------------------------------------------------

		IF ROM<>0

		align 10h
;
CRTLST:		res     7, e
                ld      a, 11001111b
                out     (PIO1BS), a     ; PIO1 B Kommando Anwenderport
                xor     a
                out     (PIO1BS), a     ; PIO1 B Kommando Anwenderport
                ld      a, e
                out     (PIO1BD), a     ; PIO1 B Daten Anwenderport
                nop
                nop
                ld      a, 01010111b
                out     (CTC1), a       ; System CTC1 Anwenderport
                out     (CTC1), a       ; System CTC1 Anwenderport
                ld      a, 00001111b
                out     (PIO1BS), a     ; PIO1 B Kommando Anwenderport
                nop
                ld      a, e
                out     (PIO1BD), a     ; PIO1 B Daten Anwenderport
CRTLST1:        call    STOPKEY
                ret     c
                in      a, (CTC1)       ; System CTC1 Anwenderport
                cp      01010111b
                jr      z, CRTLST1
                xor     a
                ret

		ENDIF


		else
; Erweiterung ROM-Version IDASZM2 f. EPROM 
		
		endif

;------------------------------------------------------------------------------
; Sprungverteiler für OS-Kommandos
;------------------------------------------------------------------------------

		org	nextpage($)

		jp	eos		; OS-Erweiterung
		db "#       ",0
		jp	beg
		db "ZM      ",0
		
		if ROM=2
		jp	eprom
		db "EPROM   ",0
		else
		jp	renew
		db "RENEW   ",0
		endif

		db    0

;------------------------------------------------------------------------------
; "#       " OS-Erweiterung
;------------------------------------------------------------------------------

eos:		call	inittreiber
		ld	de, aEos	; "\v\x14\x01EOS\x14\x02\n\r"
		call	zm_prnst
		jp	0F089h		; GOCPM
;
inittreiber:	ld	de, 0EFC9h
		ld	hl, tab_treiber	; Tabelle der Gerätetreiber
		ld	bc, 20h	; ' '   ; aEOS-tab_treiber
		ldir
		ld	a, 11001111b
		out	(8Bh), a
		ld	a, 1111111b
		out	(8Bh), a
		xor	a
		ld	(varlist), a
		cpl
		out	(89h), a
		ret

;------------------------------------------------------------------------------
; Tabelle der Gerätetreiber
;------------------------------------------------------------------------------

tab_treiber:	dw const		; TTY-Treiber für CONST
		dw 0F8F1h		; CRT: STEUERPROGRAMM DES CRT - TREIBERS
		dw 0F7B4h		; BAT: STEUERPROGRAMM FUER BATCH-MODE VON CONST
		dw 0F8F1h		; CRT: STEUERPROGRAMM DES CRT - TREIBERS
;
		dw 0F8F1h		; CRT: STEUERPROGRAMM DES CRT - TREIBERS
		dw rdr			; RDR-Treiber für READER
		dw ur1			; UR1-Treiber für READER
		dw 0F8F1h		; CRT: STEUERPROGRAMM DES CRT - TREIBERS
;
		dw 0F8F1h		; CRT: STEUERPROGRAMM DES CRT - TREIBERS
		dw PUN			; PUN-Treiber für PUNCH
		dw ur11			; UP1-Treiber für PUNCH
		dw list			; UP2-Treiber für PUNCH
;
		dw 0F8F1h		; CRT: STEUERPROGRAMM DES CRT - TREIBERS
		IF ROM=1
		dw CRTLST		; CRT-Treiber für LIST
		ELSE
		dw 0F8F1h		; CRT: STEUERPROGRAMM DES CRT - TREIBERS
		ENDIF
		dw list			; LST-Treiber für LIST
		dw PUN			; UL-Treiber für LIST

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------

aEos:		db 0Bh,14h,1,"EOS",14h,2,0Ah
		db 0Dh,0

;------------------------------------------------------------------------------
; TTY-Treiber für CONST (wie OS, aber mit Tastaturklick)
;------------------------------------------------------------------------------

const:		call	0F8F1h		; TTY-Treiber für CONST
		push	af
		ld	a, (PU)		; Hilfszelle (aufgerufene Treiberfunktion ?)
		dec	a
		call	z, beep		; wenn PU=1, d.h. Funktion "Eingabe Zeichen"
		pop	af
		ret
; kurzen Ton ausgeben (Tastaturklick)
beep:		push	af
		push	bc
		ld	b, 0
		ld	c, 14h
		ld	a, 00000111b
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		ld	a, 10010110b
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		in	a, (PIO1AD)	; PIO1 A Daten Beeper, Border, 20Z
		set	7, a		; Beeper ein
		out	(PIO1AD), a	; PIO1 A Daten Beeper, Border, 20Z
;
beep1:		djnz	beep1
		dec	c
		jr	nz, beep1
		res	7, a		; Beeper aus
		out	(PIO1AD), a	; PIO1 A Daten Beeper, Border, 20Z
		ld	a, 00000011b
		out	(CTC0),	a	; System CTC0 Kassette,	Beeper
		pop	bc
		pop	af
		ret

		if rom<>2

;------------------------------------------------------------------------------
; Kommando RENEW (für BASIC)
;------------------------------------------------------------------------------

renew:		ld	hl, 0F089h	; GOCPM
		push	hl
		push	hl
		push	de
		push	af
		ld	hl, 404h	; erstes Zeichen der ersten BASIC-Zeile
renew1:		inc	hl		; nächstes Zeichen einer BASIC-Zeile
renew2:		xor	a
		cp	(hl)		; Zeilenende ?
		jr	nz, renew1
		inc	hl
		inc	hl
		ld	a, 4		; hi(4xxh)
		cp	h
		jr	nz, renew5
		cp	(hl)
		dec	hl
		jr	nz, renew2
		ld	(401h),	hl	; PRAM:	PROGRAMMSPEICHERANFADR.
		jr	renew4
renew3:		ex	de, hl
renew4:		ld	a, (hl)
		inc	hl
		ld	d, (hl)
		ld	e, a
		or	d
		jr	nz, renew3
		inc	hl
		ld	(3D7h),	hl	; SVARPT: ADRESSE DER LISTE DER EINFACHEN- UND STRINGVAR.
renew5:		pop	af
		pop	de
		pop	hl
		ret

		else
; IDASZM2		
eprom		equ	$
		endif

;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------


		IF ROM=0

varlist:	db 0   		; Hilfszelle für LIST
var1:		dw 0		; Hilfszelle Gerätetreiber u.a.
varsav:		db 19h		; Hilfszelle für CSAVE

		ELSE 		; ROM=1

		phase 230h

varlist:		equ	$
var1:		equ	varlist+1
varsav:		equ	var1+2

		dephase

   		ENDIF

end:		equ	$

;		end
