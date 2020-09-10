; File Name   :	D:\volker\z9001\hexi\hexi.bin
; Base Address:	0000h Range: 3C00h - 3FC0h Loaded length: 03C0h
;-----------------------------------------------------------------------------
; HEX-Monitor, 1988 Klaus Schlenzig
; reass 2004 Volker Pohlers

;------------------------------------------------------------------------------
; Reihe Original-BauplÑne 70
; Klaus Schlenzig, Stefan Schlenzig
; Kleincomputer-Mosaik Hardware-Software
; Berlin, MilitÑrverlag der DDR, 1989
; 
; HEXI-Beschreibung
; 
; HEXI ist ein bildschirmorientierter Hexmonitor zum komfortablen Eingeben, Saven 
; und Laden von Hexdumps. Nach dem Laden erscheint am oberen Bildschirmrand die 
; Informationszeile, in der stÑndig die aktuelle Zeit ablesbar ist (siehe TIME-
; Kommando des Betriebsystems). Weiterhin wird die aktuelle Adresse mit ihren 
; Inhalten angezeigt. Mit den horizontalen Cursortasten kann man in der Zeile hin-
; und herwandern und so beliebige énderungen, sowohl an den Bytes wie in der 
; Adresse, vornehmen. Diese énderungen werden mit ENTER Åbernommen, und es wird 
; zur nÑchsten Adresse weitergeschaltet.
; 
; Mit den vertikalen Pfeiltasten kann um jeweils 8 Bytes zurÅck- bzw. 
; vorwÑrtsgeschaltet werden. Die letzten énderungen werden dabei nicht Åbernommen. 
; Bei öberschreiten der BildschirmrÑnder scrollt HEXI.
; 
; In HEXI sind verschiedene Kommandos verfÅgbar. Sie bestehen jeweils aus einem 
; Zeichen und kînnen Åberall in der Zeile eingegeben werden. Nach ENTER werden sie 
; aus- gefÅhrt:
; 
; / bzw. =, gefolgt von einer 4stelligen Hexzahl, schaltet auf die mit dieser Zahl 
; 	angesprochene Adresse,
; ;	schaltet von PrÅfsummen - auf ASCII-Anzeige am Ende der Zeile um (und 
; 	umgekehrt) - sehr nÅtzlich bei Textsuche,
; .	beendet die Eingabe und verlÑ·t HEXI.
; 
; Steht statt einer 2stelligen Hexzahl eine Kombination von Komma und ASCII-
; Zeichen, so wird dieses Zeichen nach ENTER automatisch in die entsprechende 
; Hexzahl gewandelt und in den Speicher eingetragen.
; 
; Weitere Kommandos, die aber nur am Zeilenanfang gegeben werden dÅrfen, sind:
; 
; ? 	öberprÅfen der letzten Kassettenaufzeichnung
; <Name Adr - Laden eines Files mit dem Namen ÆNameØ an Adresse Adr. Ist Adr 
; 	    (eine 4stellige Hexzahl) nicht angegeben, wird das File an seine 
; 	    Ursprungsadresse geladen.
; >Name Adr Aadr Eadr Stadr - Saven des Speicherbereichs ab Adresse Adr. In den 
; 			    Vorblock werden Anfangsadresse Aadr, Endadresse Eadr 
; 			    und Startadresse Stadr eingetragen.
; 			    
; Diese Trennung von Adresse des Speicherbereichs und Anfangsadresse erlaubt das 
; Speichern eines Bereichs, der spÑter von einer anderen Adresse ab eingeladen 
; werden soll. Der Parameter Stadr ist ÆoptionalØ, also nur bei Bedarf zu 
; verwenden. Fehlt er, nimmt ihn der Computer mit 0FFFFh an (Programm nicht 
; selbststartend). Der Name darf maximal 8 Zeichen lang sein und erhÑlt 
; automatisch den Typ.com angehÑngt.
; 
;------------------------------------------------------------------------------

		cpu	z80

		org 	3C00h

		jp	cmd_hexi
		db 	"HEXI    "
		db 	0
		db    	0

caddr:		dw 	300h		; aktuelle Adresse
cupos:		dw 	0EC50h		; aktuelle Bildschirmposition
ccol:		db 	5		; aktuelle Spalte (0..39 (29) )
cline:		db 	0		; aktuelle Zeile (0..20)
anzpar:		db 	0		; Anzahl Parameter
		db 	0
flgca:		db 	0		; Flag CKSUM <-> ASCII
aKopfzeile:	db 	"ADR  HEXI  c 88 SC"
aSumAscii:	db 	"SUM/ASCII"

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

con1:
		and	0Fh
		add	a, '0'
		cp	3Ah ; ':'
		ret	c
		add	a, 7
		ret

; konvertiere A	hexadezimal nach (HL..HL+1)
conhx:
		ld	c, a
		rrca
		rrca
		rrca
		rrca
		call	con1
		ld	(hl), a
		inc	hl
		ld	a, c
		call	con1
		ld	(hl), a
		inc	hl
		ret

; konvertiere DE hexadezimal nach (HL..HL+4)
conde:
		ld	a, d
		call	conhx		; konvertiere A	hexadezimal nach (HL..HL+1)
		ld	a, e
		call	conhx		; konvertiere A	hexadezimal nach (HL..HL+1)
		ld	(hl), ' '
		inc	hl
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

hex1:
		sub	'0'
		cp	0Ah
		ccf
		ret	nc
		sub	7
		cp	0Ah
		ret	c
		cp	11h
		ccf
		ret

; (HL..HL+1) zu	Hex-byte konvertieren nach A
hexa:
		ld	a, (hl)
		inc	hl
		call	hex1
		ret	c
		rla
		rla
		rla
		rla
		ld	c, a
		ld	a, (hl)
		inc	hl
		call	hex1
		ret	c
		or	c
		ret

; (HL..HL+3) als 4stellige Hexzahl nach	DE konvertieren
hexde:
		call	hexa		; (HL..HL+1) zu	Hex-byte konvertieren nach A
		ret	c
		ld	d, a
		call	hexa		; (HL..HL+1) zu	Hex-byte konvertieren nach A
		ret	c
		ld	e, a

testsp:
		ld	a, ' '          ; Test auf Leerzeichen
		cp	(hl)
		inc	hl
		ret	z
		scf
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

edit:
		ld	hl, (cupos)
		call	hexde		; (HL..HL+3) als 4stellige Hexzahl nach	DE konvertieren
		ret	c
		ld	(caddr), de
		ld	b, 8		; max 8	Byte
		ld	de, 80h		; Buffer
edit1:
		ld	a, ','          ; Eingabe von ASCII
		cp	(hl)
		jr	nz, edit2
		inc	hl
		ld	a, (hl)
		inc	hl
		jr	edit3
edit2:
		call	hexa		; Eingabe hex
		ret	c
edit3:
		ld	(de), a
		inc	de
		call	testsp		; Test auf Leerzeichen
		ret	c
		djnz	edit1
		ld	hl, 80h		; Buffer
		ld	de, (caddr)
		ld	c, 8
		ldir
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

; Anzeigen einer Zeile
line:
		ld	de, (caddr)
		ld	hl, (cupos)
		push	de
		call	conde		; konvertiere DE hexadezimal nach (HL..HL+4)
		ld	ix, 0		; PrÅfsumme
		ld	b, 8		; 8 Byte pro Zeile
		pop	de
		push	de
line1:
		ld	a, (de)
		push	de
		ld	e, a
		ld	d, 0
		add	ix, de		; PrÅfsumme berechnen
		pop	de
		call	conhx		; konvertiere A	hexadezimal nach (HL..HL+1)
		inc	de
		ld	(hl), ' '
		inc	hl
		djnz	line1
		pop	de
		ld	(hl), ' '
		inc	hl
		ld	a, (flgca)	; Flag CKSUM <-> ASCII
		or	a
		jr	nz, line2
		push	ix		; Anzeige PrÅfsumme
		pop	de
		call	conde		; konvertiere DE hexadezimal nach (HL..HL+4)
		ld	c, 3
		ld	d, h
		ld	e, l
		dec	hl
		ldir
		ret
line2:
		ld	bc, 8		; Anzeige ASCII
		ex	de, hl
		ldir
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

; (HL..HL+4) als 4stellige Hexazahl nach (IX..IX+1) konvertieren
inhex:
		call	hexde		; (HL..HL+3) als 4stellige Hexzahl nach	DE konvertieren
		ld	(ix+0),	e
		inc	ix
		ld	(ix+0),	d
		inc	ix
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

prepfcb:
		ld	hl, 4F43h	; "CO"
		ld	(64h), hl
		ld	(anzpar), a	; Anzahl Parameter
		ld	a, 'M'
		ld	(66h), a	; Dateityp "COM" eintragen
		ld	hl, (cupos)
		inc	hl
		ld	bc, 8
		ld	a, ' '
		cp	(hl)
		scf
		ret	z
		ld	de, 5Ch		; FCB
prep1:
		ldi			; Namen	Åbertragen
		dec	c
		inc	c
		jr	z, prep3
		cp	(hl)
		jr	nz, prep1
		ld	b, c
		xor	a
prep2:
		ld	(de), a
		inc	de
		djnz	prep2
prep3:
		call	testsp		; Test auf Leerzeichen
		ret	c
		ld	a, (anzpar)	; Anzahl Parameter
		or	a
		ld	b, a
		ld	ix, 6Bh
		jr	z, prep5
prep4:
		call	inhex		; (HL..HL+4) als 4stellige Hexazahl nach (IX..IX+1) konvertieren
		ret	c
		djnz	prep4
prep5:
		call	inhex		; (HL..HL+4) als 4stellige Hexazahl nach (IX..IX+1) konvertieren
		call	clscr		; Bildschirm lîschen
		ret	nc
		ld	(ix-1),	0FFh
		ld	(ix-2),	0FFh
		or	a
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

; Anzeige aktualisieren
disp:
		ld	de, (ccol)	; aktuelle Position in Zeile
		ld	d, 0
		ld	hl, (cupos)
		add	hl, de
		ld	a, (hl)
		ld	(anzpar), a	; Anzahl Parameter
disp1:
		ld	a, 0F8h	; '¯'
		cp	(hl)
		jr	nz, disp2
		ld	a, (anzpar)	; Anzahl Parameter
disp2:
		ld	(hl), a
		ld	bc, 100h
disp3:
		push	bc
		ld	c, 24		; PRITI
		ld	de, 0EC14h	; Uhrzeit in Kopfzeile anzeigen
		call	5
		ld	c, 11		; CSTS
		call	5
		pop	bc
		jr	c, disp4	; bei Fehler
		or	a
		jr	nz, disp5	; wenn Taste gedrÅckt
disp4:
		xor	a
		dec	bc
		or	b
		or	c
		jr	nz, disp3
		jr	disp1
disp5:
		push	bc
		ld	c, 1		; CONSI
		call	5
		pop	bc
		jr	c, disp4	; bei Fehler
		ld	b, a
		ld	a, (anzpar)	; Anzahl Parameter
		ld	(hl), a
		ld	a, b
		cp	8		; Cursor left
		jr	nz, disp7
		ld	a, (ccol)	; aktuelle Position in Zeile
		or	a
		jr	z, disp1
		dec	a
		dec	hl
disp6:
		ld	(ccol),	a	; aktuelle Position in Zeile
		jr	disp		; Anzeige aktualisieren
disp7:
		cp	9		; Cursor right
		jr	nz, disp9
disp8:
		ld	a, (ccol)	; aktuelle Position in Zeile
		cp	29		; rechter Rand erreicht?
		jr	nc, disp1
		inc	a
		inc	hl
		jr	disp6
disp9:
		cp	' '
		ret	c
		ld	(hl), a
		jr	disp8


;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

; suche	A bis Zeilenende
search:
		ld	hl, (cupos)
		ld	bc, 29
		cpir
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

; Bildschirm lîschen
clscr:
		ld	hl, 0E800h	; Farbspeicher lîschen
		ld	de, 0E801h
		ld	(hl), 70h
		ld	bc, 959		; 40*24-1
		push	bc
		ldir
		pop	bc
		ld	hl, 0EFBFh	; Zeichenspeicher lîschen
		ld	de, 0EFBEh
		ld	(hl), ' '
		lddr
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

; fcb anzeigen
fcb:
		ld	de, 0EC00h
		ex	de, hl
		call	conde		; konvertiere DE hexadezimal nach (HL..HL+4)
		ld	de, (6Dh)
		call	conde		; konvertiere DE hexadezimal nach (HL..HL+4)
		ld	de, (6Fh)
		call	conde		; konvertiere DE hexadezimal nach (HL..HL+4)
		ld	de, (71h)
		call	conde		; konvertiere DE hexadezimal nach (HL..HL+4)
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

csave:
		ld	hl, (6Bh)
		ld	a, 2
		ld	(6Ch), a
		ld	c, 15		; OPENW
		call	5
		ret	c
		ld	(1Bh), hl	; DMA
		call	fcb		; fcb anzeigen
		ld	hl, (6Fh)
		ld	de, (6Dh)
		or	a
		sbc	hl, de
csave1:
		ld	de, 80h
		or	a
		sbc	hl, de
		jr	c, csave2
		jr	z, csave2
		ld	c, 21		; WRITS
		call	5
		ret	c
		jr	csave1
csave2:
		ld	c, 16		; CLOSW
		call	5
		ret


;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

load1:
		ld	l, 20		; READS
		jr	load3
load2:
		ld	hl, 80h
		ld	(1Bh), hl
		ld	l, 13		; OPENR
load3:
		ld	c, l
		call	5
		ret	nc
		ld	h, a
		ld	de, 80h
		ld	a, 1
		ld	(de), a
		ld	c, 10		; RCONB
		call	5
		ret	c
		ld	a, h
		cp	0Bh
		jr	nc, load3
		ret


cload:
		ld	hl, (6Bh)
		push	hl
		call	load2
		pop	hl
		ret	c
		ld	a, h
		and	l
		xor	0FFh
		jr	nz, cload1
		ld	hl, (6Dh)
cload1:
		ld	(1Bh), hl
		call	fcb		; fcb anzeigen
cload2:
		call	load1
		ret	c
		or	a
		jr	z, cload2
		ret

;------------------------------------------------------------------------------
; 
;------------------------------------------------------------------------------

verify:
		call	load2
		ret	c
verify1:
		ld	hl, 80h
		ld	(1Bh), hl
		call	load1
		ret	c
		or	a
		jr	z, verify1
		ret

;------------------------------------------------------------------------------
; Hauptprogramm
;------------------------------------------------------------------------------

cmd_hexi:
		call	clscr		; Bildschirm lîschen
		ld	hl, aKopfzeile	; "ADR  HEXI  c 88 SC"
		inc	de
		ld	c, aSumAscii-aKopfzeile	; LÑnge	aKopfzeile
		ldir
		ld	e, 1Eh
		ld	c, con1-aSumAscii	; LÑnge	aSumAscii
		ldir
		ld	c, 18		; SETCU
		ld	de, 115h
		call	5
hexi1:
		call	line		; Anzeigen einer Zeile
hexi2:
		call	disp		; Anzeige aktualisieren
		push	af		; in A steht der Tastencode
		sub	0Ah
		and	0FEh
		cp	0Ah
		jr	z, hexi3
		call	edit
		jr	nc, hexi3
		pop	af
		ld	a, '.'          ; "." beendet HEXI
		call	search		; suche	A bis Zeilenende
		jr	nz, hexi4
		call	clscr		; Bildschirm lîschen
		ld	d, 1
		ld	e, d
		ld	c, 18		; SETCU
		call	5
		or	a
		ret
hexi3:
		jr	hexi15
hexi4:
		ld	a, '/'          ; "goto addr"
		call	search		; suche	A bis Zeilenende
		jr	nz, hexi6
hexi5:
		call	hexde		; (HL..HL+3) als 4stellige Hexzahl nach	DE konvertieren
		jr	c, hexi9
		ld	(caddr), de
		jr	hexi1
hexi6:
		ld	a, '='          ; "goto addr"
		call	search		; suche	A bis Zeilenende
		jr	z, hexi5
		ld	a, ';'          ; "Wechsel CKSUM <-> ASCII"
		call	search		; suche	A bis Zeilenende
		jr	nz, hexi9
		ld	a, (flgca)	; Flag CKSUM <-> ASCII
		cpl
		ld	(flgca), a	; Flag CKSUM <-> ASCII
hexi7:
		jr	hexi1
hexi8:
		jr	cmd_hexi
hexi9:
		ld	a, '>'          ; "SAVE >Name Adr Aadr Eadr Stadr"
		ld	hl, (cupos)
		cp	(hl)
		jr	nz, hexi12
		ld	a, 3		; 3+1 Parameter
		call	prepfcb		; FCB fÅllen
		jr	c, hexi14	; Ausgabe Piepston
		call	csave
		jr	nc, hexi8
		ld	c, 1		; CONSI
		call	5
hexi10:
		jr	hexi8
hexi11:
		jr	hexi2
hexi12:
		ld	a, '<'          ; "LOAD <Name Adr"
		cp	(hl)
		jr	nz, hexi13
		xor	a
		call	prepfcb		; FCB fÅllen
		jr	c, hexi14	; Ausgabe Piepston
		call	cload
		jr	hexi10
hexi13:
		ld	a, '?'          ; "verify"
		cp	(hl)
		jr	nz, hexi14	; Ausgabe Piepston
		call	clscr		; Bildschirm lîschen
		call	verify
		jr	hexi10
hexi14:
		ld	e, 7		; Ausgabe Piepston
		ld	c, 2		; CONSO
		call	5
		jr	hexi11
hexi15:
		call	line		; Anzeigen einer Zeile
		pop	af
		cp	0Bh		; Cursor UP
		jr	nz, hexi19
		ld	hl, (caddr)
		ld	de, 8
		sbc	hl, de
		ld	(caddr), hl
		ld	a, (cline)	; aktuelle Zeile (0..20)
		or	a
		jr	nz, hexi17
		ld	hl, 0EF98h	; scrollen
		ld	de, 0EFC0h
		ld	bc, 840		; 21*40
		lddr
hexi16:
		jr	hexi7
hexi17:
		dec	a
		ld	(cline), a	; aktuelle Zeile (0..20)
		ld	hl, (cupos)
		ld	de, 40
		sbc	hl, de
hexi18:
		ld	(cupos), hl
		jr	hexi7
hexi19:
		cp	10
		jr	nz, hexi22
hexi20:
		ld	hl, (caddr)
		ld	de, 8
		add	hl, de
		ld	(caddr), hl
		ld	a, (cline)	; aktuelle Zeile (0..20)
		cp	21		; 21 darzustellende Zeilen
		jr	c, hexi21
		ld	de, 0EC50h	; scrollen
		ld	hl, 0EC78h
		ld	bc, 840		; 21*40
		ldir
		jr	hexi16
hexi21:
		inc	a
		ld	(cline), a	; aktuelle Zeile (0..20)
		ld	hl, (cupos)
		ld	de, 40
		add	hl, de
		jr	hexi18
hexi22:
		cp	0Dh		; ENTER
		jr	nz, hexi23
		ld	a, 5
		ld	(ccol),	a	; aktuelle Position in Zeile
		jr	hexi20
hexi23:
		jr	hexi16


		end
