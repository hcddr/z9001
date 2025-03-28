; Schiebespiel BLOCKS, basiert auf der Spielidee von Unblock Me von kiragames
; Volker Pohlers, 2020
; letzte Änderung: 18.01.2021

	cpu	z80

;-----------------------------------------------------------------------------
; AS-Funktionen
;-----------------------------------------------------------------------------

; obere 8 Bit: hi(CONBU)
hi              function x,(x>>8)&255

; untere 8 Bit: lo(CONBU)
lo              function x, x&255

; bws(zeile 0..23, spalte 0..39) analog print_at
;bws		function z,s,z*40+s+0EC00h
;bwsc		function z,s,z*40+s+0E800h

; bws(zeile 1..24, spalte 1..40) analog print_at
bws1		function z,s,(z-1)*40+(s-1)+0EC00h
bwsc1		function z,s,(z-1)*40+(s-1)+0E800h

;------------------------------------------------------------------------------
; switches
;------------------------------------------------------------------------------

;; english		equ	1		; 1 - englisch; 0 - deutsch
;; develop		equ	0		; 1 - Kommando N verfügbar
;; cheat		equ	1		; 1 - cheat verfügbar
;; bigpuzzles		equ	1		; 0 - 110 Puzzles


;------------------------------------------------------------------------------
; Z9001-OS-Kommandorahmen
;------------------------------------------------------------------------------

	org	300h

	jp	start
	if  english=1
	db	"BLOCKS  ",0
	else
	db	"SCHIEB  ",0
	endif
	db	0


;------------------------------------------------------------------------------
; Hauptprogramm
;------------------------------------------------------------------------------

start:	; cursor löschen
	;ld	c,DCU
	;call	5

	; Hintergrundbild/Oberfläche zeichnen
	ld	hl,mainpic
	call	decomp

	;kleines Eingabefenster setzen
	call	smallwindw

	;level init
	ld	a,0
	ld	(level),a
	ld	(hidden),a
	ld	(toggled),a
	ld	hl,0
	ld	(puzzle),hl

	ld	c,DCU
	call	5
	ld	c,CONSI
	call	5

	call	reset

	; hauptschleife
mainloop:
	ld	c,DCU
	call	5
	;

	ld	c,CONSI
	call	5
	cp	'Q'
	jr	z,ende
	cp	'B'		; deutsch, Beenden
	jr	z,ende

	;in a:kdo
	ld	hl,kdo
	ld	bc,kdotab-kdo
	cpir
	jr	nz,mainloop	; not found
	LD	A,KDOTAB-KDO-1
	SUB	C
	SRL	a	;A/2, je zwei Tasten pro Kdo möglich 
	ADD	A,A
	LD	HL,KDOTAB
	LD	C,A	;B=0
	ADD	HL,BC

	ld	e,(hl)
	inc	hl
	ld	d,(hl)		;kdo-adr
	ld	hl,mainloop
	push	hl		;ret-adr auf stack
	push	de		;kdo starten
	ret

ENDE:	call	fullwindw	;ganzes Fenster
	xor	a
	ret

vers:	db	DATE

; je 2 Tasten pro Kdo möglich
kdo:	db	'C','K'
	db	'R','N'
	db	'E',0bh	; cursor up
	db	'S',08h	; cursor left
	db	'D',09h	; cursor right
	db	'X',0Ah ; cursor down
	db	'e',0
	db	's',0
	db	'd',0
	db	'x',0
	if develop=1
	db	'T',0
	endif
	db	'A','a'
	db	' ',0dh	; enter

kdotab:
	dw	codeinp		; 'C'
	dw	reset           ; 'R'
	dw	cu_up           ; 'E'
	dw	cu_left         ; 'S'
	dw	cu_right        ; 'D'
	dw	cu_down         ; 'X'
	dw	mv_up           ; 'e'
	dw	mv_left         ; 's'
	dw	mv_right        ; 'd'
	dw	mv_down         ; 'x'
	if develop=1
	dw	solved          ; 'T'
	endif
	dw	next_stone	; 'A'
	dw	toggle		; ' '

;------------------------------------------------------------------------------
; Für die Bedienung kann mit space/enter die Bedeutung der Cursortasten 
; zwischen select und move umgeschaltet werden
;------------------------------------------------------------------------------

toggle:	ld	a,(toggled)
	cpl	a
	ld	(toggled),a
	call	show
	ret

;------------------------------------------------------------------------------
; Fenster festlegen
;------------------------------------------------------------------------------

;kleines Eingabefenster at 22,23 - 22,37 (zeile, spalte)
smallwindw:	ld	hl, (22+1)*100h+(22-1)
		ld	(P1ROL), hl
		ld	hl, (37+1)*100h+(23-1)
		ld	(P3ROL), hl
		ld	hl, bws1(22,23)
		ld	(CURS), hl

		ld	hl, bws1(22,23)	; Cursor auf Fenster setzen
		ld	(CURS), hl

		ld	hl, bwsc1(22,23)	; Farbattribut übernehmen
		ld	a,(hl)
		ld	(ATRIB),a

		ld	a, 0Ch		; CLS
		call	outa
		ret

; volles Fenster
fullwindw:	ld	hl, 1900h	; 1-24 (25,0)
		ld	(P1ROL), hl
		ld	hl, 2900h	; 1-40 (41,0)
		ld	(P3ROL), hl

		ld	a,20h		; grün auf schwarz
		ld	(ATRIB),a
		ld	a, 0Ch
		call	outa
		ret

;------------------------------------------------------------------------------
; Hintergrundbild 
;------------------------------------------------------------------------------

mainpic
	if english=1
	binclude PICTURE4.COM.pic
	else
	binclude PICTURE6.COM.pic
	endif

;------------------------------------------------------------------------------
; decompact-routine f. Hintergrundbild
; in HL - Adr. gepacktes Bild
;------------------------------------------------------------------------------

decomp:		ld	de, 0E800h	; ziel
decomp1:	ld	a, (hl)
		cp	1		; 1 - Ende
		ret	z
		or	a		; 0 - RLE
		jr	z, decomp3
		ld	(de), a		; sonst zeichen übernehmen
		inc	de
decomp2:	inc	hl
		jr	decomp1
decomp3:	inc	hl
		ld	a, (hl)		; zeichen
		inc	hl
		ld	b, (hl)		; anzahl
decomp4:	ld	(de), a
		inc	de
		djnz	decomp4
		jr	decomp2

;------------------------------------------------------------------------------
; Codeeingabe
;------------------------------------------------------------------------------

codeinp:

s0:	call	prnst0
	db	">", 0

	ld	de, CONBU
	ld	a,10		; max länge
	ld	(de),a
	ld	c,10		; rconb
	call	5
	jp	c, reset	; bei Stop
	inc	de
	ld	a,(de)
	cp	0
	jp	z, reset	; leere Eingabe

	if cheat=1
	;cheat aktivieren	(Eingabe vp)
	ld	hl,CONBU+2
	ld	a,(hl)
	cp	'v'
	jr	nz,sp0
	inc	hl
	ld	a,(hl)
	cp	'p'
	jr	nz,sp0
	ld	(hidden),a
	jr	s0

	; wenn cheat aktiv, dann direkte level-Eingabe (6 Zeichen, Level + puzzle (hex)
sp0:	ld	a,(hidden)
	cp	'p'
	jr	nz, sp1
	ld	hl,CONBU+2
	ld	a,(hl)
	cp	'0'
	jr	nz, sp1
	call	atoh	; level
	jr	c,s2
	ld	c,a
	call	atoh	; puzzle
	jr	c,s2
	ld	d,a
	call	atoh
	jr	c,s2
	ld	e,a
	jr	sp2
	endif

	; decodiere Puzzlecode
sp1:	ld	hl,CONBU+2
	call	decode
	jr	c, s2

sp2:	;test, ob puzzle in level verfuegbar
	ld	a,c
	cp	4	; level < 4 ?
	jr	nc,s2	; wenn level >= 4

	ld	b,c	; level
	inc	b
	ld	hl,lvl0cnt-2
sp2a:	inc	hl
	inc	hl
	djnz	sp2a
	ld	a,(hl)	; hl=lvl0cnt+2*level
	inc	hl
	ld	h,(hl)
	ld	l,a	; hl = Anz. Puzzles in Level
	or	a
	dec	hl	; wir zählen ab 0
	sbc	hl,de
	jr	c,s2	; wenn Anz. Puzzles kleiner akt. Level

	; sonst Puzzle selektieren
	ld	a,c
	ld	(level),a
	ld	(puzzle),de
	jp	reset	; und anzeigen
s2:
	call	prnst0
	if english=1
	db	"Error",0
	else
	db	"Fehler",0
	endif
	jp	s0

;------------------------------------------------------------------------------
; Puzzle reset
;------------------------------------------------------------------------------

reset
	; Puzzle aufbauen

	ld	a, (level)
	ld	c, a
	ld	de, (puzzle)
	call	getpuzzle	; gepacktes Puzzle im Puzzle-Bin suchen

	call	unpack		; nach stones entpacken

	ld	hl,-1
	ld	(moves),hl	; Anz. Schritte init

	ld	a,0
	ld	(toggled),a

	;set cursor
	ld	hl, stones	; 1st stone: red stone position
	ld	(custone),hl

	;Puzzle anzeigen
	call	show_mv		; show incl. moves++

	;show values

	;level	at 10,30
	ld	a, (level)	
	ld	b,a
	inc	b
	ld	de,8	; Länge
	ld	hl,Level0-8	; Klartextliste
res1:	add	hl,de
	djnz	res1
	ld	bc,8
	ld	de,bws1(10,30)	; Text anzeigen
	ldir

	;puzzle	at 12,33
	ld	de,bws1(12,33)
	ld	hl,(puzzle)
	inc	hl	; Anzeige ist ab 1
	call	hlkon	; Wert anzeigen

	ret

Level0	
	if english=1
	db "Beginner"	; 0
	db "Intermed"	; 1
	db "Advanced"	; 2
	db "  Expert"	; 3
	else
	db " einfach"	; 0
	db "  mittel"	; 1
	db "  schwer"	; 2
	db "  extrem"	; 3
	endif

;------------------------------------------------------------------------------
; Puzzle solved
;------------------------------------------------------------------------------

solved:	
	ld 	hl,geschafft
	ld	de,bws1(17,23)
	ld	bc,geschafft_e-geschafft
	ldir
	;
	call	nextpuzzle	; nächstes Puzzle selektieren
	;
	ld	a,0ch
	call	outa		; level-fenster löschen
	ld	a,(level)
	ld	c,a
	ld	de,(puzzle)
	call	encode		; Levelcode f. nächstes Puzzle anzeigen
	;
	ld	c,CONSI
	call	5		; warten auf taste
	;
	call	reset
	ret
	;
geschafft	
	if english=1
	db "* S O L V E D *"
	else
	db "* E R F O L G *"
	endif
geschafft_e


;------------------------------------------------------------------------------
; Selektiere Stein
;------------------------------------------------------------------------------

cu_init
	ld	iy,(custone)
	ld	e,(iy+0)	;cu_col
	ld	d,(iy+1)	;cu_row
	ld	c,255		;min_distance Anfangswert
	exx
	ld	bc,4
	exx
	;
	ld	ix,stones
	ld	a,(toggled)
	or	a
	ret

cu_up	
	call	cu_init
	jp	nz,mv_up
	
cu_up1	
	;liegt stein oberhalb aktuellem stein?
	ld	a,(ix+1)	;row
	cp	d		;cu_row
	;berechne abstand
	call	c, calc_distance	;wenn row < cu_row
;	
	exx
	add	ix,bc
	exx
	ld	a,(ix)
	cp	0ffh		; ende?
	jr	nz, cu_up1
;
	ld	(custone),iy
	call	show
	ret

cu_down
	call	cu_init
	jp	nz,mv_down
cu_down1	
	;liegt stein unterhalb aktuellem stein?
	ld	a,d		;cu_row
	cp	(ix+1)		;row
	;berechne abstand
	call	c, calc_distance	;wenn cu_row < row
;	
	exx
	add	ix,bc
	exx
	ld	a,(ix)
	cp	0ffh		; ende?
	jr	nz, cu_down1
;
	ld	(custone),iy
	call	show
	ret

cu_left
	call	cu_init
	jp	nz,mv_left
cu_left1	
	;liegt stein oberhalb aktuellem stein?
	ld	a,(ix+0)	;col
	cp	e		;cu_col
	;berechne abstand
	call	c, calc_distance	;wenn row < cu_row
;	
	exx
	add	ix,bc
	exx
	ld	a,(ix)
	cp	0ffh		; ende?
	jr	nz, cu_left1
;
	ld	(custone),iy
	call	show
	ret

cu_right
	call	cu_init
	jp	nz,mv_right
cu_right1	
	;liegt stein unterhalb aktuellem stein?
	ld	a,e		;cu_col
	cp	(ix+0)		;col
	;berechne abstand
	call	c, calc_distance	;wenn cu_row < row
;	
	exx
	add	ix,bc
	exx
	ld	a,(ix)
	cp	0ffh		; ende?
	jr	nz, cu_right1
;
	ld	(custone),iy
	call	show
	ret


; Abstand zw. Punkten (ix) und de berechnen
; ret a - distance
calc_distance
	push	bc
	ld	a,(ix+0)
	ld	b,e
	sub	b
	jp	p,calc_distance1
	neg
calc_distance1
	ld	hl,qtab
	ld	c,a
	ld	b,0
	add	hl,bc
	ld	a,(hl)
	push	af	; x^2
;
	ld	a,(ix+1)
	ld	b,d
	sub	b
	jp	p,calc_distance2
	neg
calc_distance2
	ld	hl,qtab
	ld	c,a
	ld	b,0
	add	hl,bc
	ld	a,(hl)
	pop	bc	; x^2
	add	a,b
	pop	bc
	ret	z	; Abstand 0, das ist der aktuelle block
;	
	;kleiner als aktuelle min_dist?
	cp	c		; min_distance
	ret	nc
	;wenn kleiner als aktuelle min, dist, dann
	ld	c,a		; neue min_distance
	push	ix
	pop	iy	; iy := ix
	ret
	
qtab	db	0,1,4,9,16,25


; testweise: einfach zum nächsten Stein aus der Liste springen
next_stone:
	ld	ix,(custone)
	ld	bc,4
	add	ix,bc
	ld	a,(ix)
	cp	0ffh		; ende?
	jr	nz, next_stone1
	ld	ix,stones	; sonst wieder bei 0 anfangen
next_stone1:
	ld	(custone),ix
	call	show
	ret


;------------------------------------------------------------------------------
; Bewege aktuellen Stein
; wenn move right, dann auch Test auf Ende
;------------------------------------------------------------------------------

;move up
mv_up:
	ld	ix,(custone)
	ld	a,(ix+2)	; orientation
	cp	0
	ret	nz		; kein senkrechter stein
	;
	ld	a,(ix+1)	; row
	cp	0
	ret	z		; oberer Rand
	;feld frei?
	dec	a		; zeile hoch
	ld	e,(ix)
	ld	d,a
	call	calc_pos0	; e = col, d = row
	ld	a,(hl)
	cp	' '		; leerzeichen an Pos?
	ret	nz		; nein
	; ja
	dec	(ix+1)		; zeile hoch
	call	show_mv		; show incl. moves++
	ret

;move down
mv_down:
	ld	ix,(custone)
	ld	a,(ix+2)	; orientation
	cp	0
	ret	nz		; kein senkrechter stein
	;
	ld	a,(ix+1)	; row
	ld	b,(ix+3)	; laenge
	add	a,b
	cp	6
	ret	nc		; a>=6, unterer Rand
	;feld frei?
	ld	e,(ix)
	ld	d,a
	call	calc_pos0	; e = col, d = row
	ld	a,(hl)
	cp	' '		; leerzeichen an Pos?
	ret	nz		; nein
	; ja
	inc	(ix+1)		; zeile runter
	call	show_mv		; show incl. moves++
	ret

; move left
mv_left:
	ld	ix,(custone)
	ld	a,(ix+2)	; orientation
	cp	1
	ret	nz		; kein waagerechter stein
	;
	ld	a,(ix)		; col
	cp	0
	ret	z		; linker Rand
	;feld frei?
	dec	a		; spalte links
	ld	e,a
	ld	d,(ix+1)
	call	calc_pos0	; e = col, d = row
	ld	a,(hl)
	cp	' '		; leerzeichen an Pos?
	ret	nz		; nein
	; ja
	dec	(ix)		; spalte links
	call	show_mv		; show incl. moves++
	ret

; move right
mv_right:
	; hier zuerst test, ob roter stein auf pos 4,2. wenn ja -> solved
	; (custone) = stones = (4,2) ?
	ld	hl,stones
	ld	de,(custone)
	or	a
	sbc	hl,de
	jr	nz, mv_right0
	ld	hl,(stones)
	ld	de,0204h
	or	a
	sbc	hl,de
	jr	nz,mv_right0
	;solved
	ld	ix,(custone)
	inc	(ix+0)		; spalte rechts
	call	show_mv
	jp	solved
mv_right0:
	ld	ix,(custone)
	ld	a,(ix+2)	; orientation
	cp	1
	ret	nz		; kein waagerechter stein
	;
	ld	a,(ix)		; col
	ld	b,(ix+3)	; laenge
	add	a,b
	cp	6
	ret	nc		; a>=6, rechter Rand
	;feld frei?
	ld	e,a
	ld	d,(ix+1)
	call	calc_pos0	; e = col, d = row
	ld	a,(hl)
	cp	' '		; leerzeichen an Pos?
	ret	nz		; nein
	; ja
	inc	(ix)		; spalte rechts
	call	show_mv		; show incl. moves++
	ret


;------------------------------------------------------------------------------
; nächstes Puzzle auswählen
; ret: level und puzzle mit Nachfolgewerten belegt
;------------------------------------------------------------------------------

nextpuzzle:
	;test, ob puzzle in level verfuegbar
	ld	a,(level)
	ld	b,a	; level
	inc	b
	ld	hl,lvl0cnt-2
np1:	inc	hl
	inc	hl
	djnz	np1	; hl=lvl0cnt+2*level
	ld	a,(hl)	
	inc	hl
	ld	h,(hl)
	ld	l,a	; hl = Anz. Puzzles in Level
	dec	hl	; wir zählen ab 0
	ld	de,(puzzle)
	inc	de	; next puzzle
	or	a
	sbc	hl,de
	jr	c,np2	; wenn Anz. Puzzles kleiner akt. Level
	;sonst bleibt level
	ld	(puzzle),de
	ret
np2:	ld	a,(level)
	cp	3
	ret	z	; level 4, letztes Puzzle erreicht
	inc	a
	ld	(level),a
	ld	de,0
	ld	(puzzle),de
	ret

;------------------------------------------------------------------------------
; Codieren Puzzle-Nummer
; in C level
;    DE puzzle
; out PRINT code (7 Zeichen)
; uses A, HL
;------------------------------------------------------------------------------

encode:
;levelcode ist Zufall A..Z, Bit 1+0 ist levelnr + 1
	ld	a,r
	and	a,1Ch
	add	a,c	;level
	add	a,'A'
	cp	'Z'+1
	jr	nc, encode
	ld	h,a
	call	outa

;prüfsumme ist levelcode*2 + hi puzzle + lo puzzle + 142
	ld	a,h	;levelcode
	add	a,a	;*2
	add	a,d
	add	a,e
	add	a,142
	call	outhx

;puzzlecode ist puzzle*4 + 4 bits Zufall
	ld	h,d
	ld	l,e
	add	hl,hl
	add	hl,hl	;puzzle*4
	ld	a,r	;obere 2 Bits zufall
	add	a,a
	and	0C0h
	add	a,h
	ld	h,a
	ld	a,r
	and	03h	;untere 2 Bits Zufall
	add	a,l
	ld	l,a
	call	outhl
	ret

;------------------------------------------------------------------------------
; Decodieren Puzzle-Nummer
; in HL Eingabepuffer
; out C level
;     DE puzzle
;     Cy Fehler
;------------------------------------------------------------------------------

;decode
;Beispiel level 2, puzzle 100 -> K884192 oder G804191 oder ..
; K - levelcode, 88 prüfsumme, 4192 puzzlecode

decode:
	ld	c,(hl)	; C=level-code
	inc	hl

	call	atoh	; B=prüfsumme
	ret	c
	ld	(prfsum),a
	call	atoh	; DE=puzzlecode
	ret	c
	and	3fh
	ld	d,a
	call	atoh
	ret	c
	ld	e,a
	srl	d
	rr	e
	srl	d
	rr	e	; DE = puzzle
; Prüfsumme
	ld	a,c
	add	a,a
	add	a,d
	add	a,e
	add	a,142
	ld	hl,prfsum
	cp	(hl)
	ret	c
;level
	ld	a,c
	dec	a
	and	a,3
	ld	c,a	; c = level
	ret

;------------------------------------------------------------------------------
; such_puzzle im Puzzle-ROM
; in C - level
;    DE - puzzle
; out DE=0, HL=Adr. Puzzle
;------------------------------------------------------------------------------

getpuzzle:
	ld	hl,lvl0cnt
gp2:	ld	a,c
	or	a	; level 0 ?
	jr	z, gp1	; ja
	ld	a,(hl)	; anz. puzzles im level
	inc	hl
	ld	b,(hl)
	inc	hl	
	push	hl
	ld	l,a
	ld	h,b
	add	hl,de	; zusammenaddieren
	ex	de,hl	; nach DE
	pop	hl
	dec	c
	jr	gp2	; bis level erreicht
	;Puzzle suchen
gp1:	ld	hl,puzzles
gp3:	ld	a,d	; de=lfd. Nr. des Puzzles im ROM
	or	e
	ret	z
	ld	a,0FFh	; Puzzleende
	cpir
	dec	de
	jr	gp3


;------------------------------------------------------------------------------
; Entpacke Puzzle
; in HL = puzzle-Ptr
;------------------------------------------------------------------------------

unpack:
	ld	(pptr),hl
	ld	b,0	; anzahl steine
	ld	de,stones

unp2:	ld	a,(hl)
	inc	hl
	cp	0ffh
	jr	z,unp1	; ende erreicht
	inc	b	; ein Stein mehr
	;

	;3 bit spalte 3 bit zeile 1 bit w/s, 1 bit 2/3
	;1. Zeichen ist das rote Teil
	ld	c,a
	ld	a,0
	rl	c
	rla
	rl	c
	rla
	rl	c
	rla
	ld	(de),a	; column
	inc	de
	;
	ld	a,0
	rl	c
	rla
	rl	c
	rla
	rl	c
	rla
	ld	(de),a	; row
	inc	de
	;
	ld	a,0
	rl	c
	rla
	ld	(de),a	; orientation
	inc	de
	;
	ld	a,0
	rl	c
	rla
	add	a,2
	ld	(de),a	; width
	inc	de
	jr	unp2

unp1:	ld	a,0ffh	; Ende Feldaufbau
	ld	(de),a
;;	ld	a, b
;;	ld	(pcnt), a
	ret


;------------------------------------------------------------------------------
; Show
; Anzeige des Spielfelds auf dem Bildschirm
; in stones stehen die Steine mit ihren aktuellen Positionen
; 1. Stein wird exta gezeichnet
;------------------------------------------------------------------------------


show_mv:
	ld	hl,(moves)
	inc	hl
	ld	(moves),hl
	;moves	14,33
	ld	de,bws1(14,33)
	call	hlkon
	
show:	;Textbereich (E R F O L G etc) leeren
	ld	b,40-23-1
	ld	a,' '
	ld 	hl,bws1(17,23)
show0:	ld	(hl),a
	inc	hl
	djnz	show0
	;
	;Anzeigefeld leeren
	ld	hl,bws1(11,4) ; Beginn Anzeige Feld
	ld	de,40-12
	ld	a,' '
	ex	af,af'
	ld	a,63h	; Farbattribut cyan auf gelb
	ex	af,af'
	ld	c,12
show2:	ld	b,12
show1:	ld	(hl),a
	res	2,h	;->Farb-BWS
	ex	af,af'
	ld	(hl),a
	ex	af,af'
	set	2,h
	inc	hl
	djnz	show1
	add	hl,de
	dec	c
	jr	nz, show2
	;
	;Ausgang leeren
	ld	hl,bws1(15,16)
	ld	de,40-2
	ld	c,2
show2a:	ld	b,2
show1a:	ld	(hl),a
	res	2,h	;->Farb-BWS
	ex	af,af'
	ld	(hl),a
	ex	af,af'
	set	2,h
	inc	hl
	djnz	show1a
	add	hl,de
	dec	c
	jr	nz, show2a

	;steine einfuegen
	ld	a,0
	ld	(pcnt),a	; anzahl steine
	ld	ix,stones	; aktuelle Steine
show3:	call	show_stone	; Stein zeichnen
	ld	de,4
	add	ix,de		; nächster Stein
	ld	a,(ix)
	cp	0ffh		; Ende ?
	jr	nz, show3	; nein
	;

	; aktuellen Stein markieren ("Cursor")
	; die linke obere Ecke des Steins bekommt extra Zeichen
showcursor:
	ld	ix,(custone)
	call	calc_pos
	ld	a,(toggled)
	or	a
	jr	z,showcu2
	ld	a,199
	jr	showcu1
showcu2:
	push	hl
	;red stone?
	ld	hl,stones
	ld	de,(custone)
	or	a
	sbc	hl,de
	pop	hl
	ld	a,selc		; normaler Stein
	jr	nz, showcu1
	ld	a,selcr		; roter Stein
showcu1:
	ld	(hl),a	; cursor-zeichen
	ret

; (ix) col, (ix+1) row
; ret hl := bws-anfang + 80*row+2*col
calc_pos:
	ld	e,(ix)		; col
	ld	d,(ix+1)	; row
; e = col, d = row
calc_pos0:
	ld	hl,bws1(11,4)-80 ; Beginn Anzeige Feld
	ld	bc,80
	inc	d		; +1
calc_pos1:
	add	hl,bc
	dec	d
	jr	nz, calc_pos1
	;ld	d,0		; d ist noch 0
	add	hl,de
	add	hl,de
	ret

; die Steine
waag2	db	2,4
	db	193,158,158,137		; +--+
	db	136,248,248,200		; +--+
waag3	db	2,6
	db	193,158,158,158,158,137	; +----+
	db	136,248,248,248,248,200	; +----+
senk2	db	4,2
	db	193,137			; ++
	db	159,192			; ||
	db	159,192			; ||
	db	136,200			; ++
senk3	db	6,2
	db	193,137			; ++
	db	159,192			; ||
	db	159,192			; ||
	db	159,192			; ||
	db	159,192			; ||
	db	136,200			; ++
red2	db	2,4
	db	255,255,255,255		; ****
	db	255,255,255,255		; ****

selc	equ	194
selcr	equ	195		; cursor red stone

	; 1. Stein ist red stone
	;ix+0	col 0..5
	;ix+1	row 0..5
	;ix+2	ori 1 = waagerecht nach rechts, 0 = senkrecht nach unten
	;ix+3	len 0 = 2, 1 = 3

show_stone:
	call	calc_pos
	ld	bc,40
	push	hl
	exx
	pop	hl

	; 1. Stein ist red stone
	ld	a,(pcnt)
	or	a
	jr	nz,show_stone1
	ld	de,red2
	inc	a
	ld	(pcnt),a
	jr	draw

show_stone1:
	ld	a,(ix+2)
	or	a
	jr	z,senk
	;waag
	ld	a,(ix+3)
	cp	2
	ld	de,waag2
	jr	z,draw
	ld	de,waag3
	jr	draw
senk:	ld	a,(ix+3)
	cp	2
	ld	de,senk2
	jr	z,draw
	ld	de,senk3
	jr	draw

draw:	ld	a,(de)	; anz zeilen
	ld	c,a
	inc	de
	ld	a,(de)	; anz spalten
	ld	b,a
	inc	de
draw2:	push	bc
draw1:	ld	a,(de)
	ld	(hl),a
	res	2,h	;->Farb-BWS
	ld	a,02h	; schwarz auf gruen
	ld	(hl),a
	set	2,h
	inc	hl
	inc	de
	djnz	draw1
	exx
	add	hl,bc
	push	hl
	exx
	pop	hl
	pop	bc
	dec	c
	jr	nz,draw2

	ret

;------------------------------------------------------------------------------
; Std.-Lib.
;------------------------------------------------------------------------------

	include	z9001.asm

;------------------------------------------------------------------------------
; PUZZLEROM erstellt mit pack_puzzles.pl
; 4 WORD Anzahl der Puzzles
; Puzzles gepackt, Ende eines Puzzles mit FF-Byte
; 1 Byte pro Stein, 1. Stein ist red stone
; 	bits 7..5	col 0..5
; 	bits 4..2	row 0..5
; 	bit 1		ori 1 = waagerecht nach rechts, 0 = senkrecht nach unten
; 	bit 0		len 0 = 2, 1 = 3
;------------------------------------------------------------------------------

;	org	1000h
puzzlerom:
	if bigpuzzles=1
	binclude	puzzles.tsv.rom
	elseif bigpuzzles=2
	binclude	testpuzzles.tsv.rom
	else
	binclude	puzzles110.tsv.rom
	endif

lvl0cnt:	equ	puzzlerom + 0
lvl1cnt:	equ	puzzlerom + 2
lvl2cnt:	equ	puzzlerom + 4
lvl3cnt:	equ	puzzlerom + 6

puzzles:	equ	puzzlerom + 8

;------------------------------------------------------------------------------
; Speicher
;------------------------------------------------------------------------------

;	org	2000h

prfsum:	ds	1
hidden:	ds	1	;p -> aktiviert direkte leveleingabe
toggled:	
	ds	1

field	ds	6*6

level:	ds	1	; current level 0..3
puzzle:	ds	2	; current puzzle 0..n-1
moves:	ds	2	; counter
pptr:	ds	2	; pointer zu aktuellem Puzzle im puzzlerom
custone:
	ds	2	; pointer zu aktuellem Stein im puzzlerom
pcnt:	ds	1	; anzahl steine

stones:	ds	17*4	; expandiertes Puzzle: je 4 Byte pro Stein, Ende mit FF
; 	4 Byte pro Stein, 1. Stein ist red stone
; 	+0	col 0..5
; 	+1	row 0..5
; 	+2	ori 1 = waagerecht nach rechts, 0 = senkrecht nach unten
; 	+3	len 0 = 2, 1 = 3
;max 17 Steine möglich (6x6 Felder, 2er-Steine, mind 1 muss zum Schieben frei bleiben)

ramende:	equ	$

;;	end
