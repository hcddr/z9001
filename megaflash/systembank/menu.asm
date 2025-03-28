;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M/3.5M-Modul)
; (c) KOMA Alexander Schön, 2005-2007
; Adaptiert und erweitert f. Mega-Flash-Modul V. Pohlers 2012 
; neu: dyn. Aufbau der Ordner und der Listen; Scrollen des Dialogs; u.a.m
; letzte Änderung 23.09.2012 
;------------------------------------------------------------------------------
; Bank0: Menü
;------------------------------------------------------------------------------

		CPU 	z80undoc

; !!! Farbattributspeicher

; BIT	Funktion
;  0/1 	rot .... Hintergrund
;  1/2  grün... Hintergrund
;  2/4  blau ... Hintergrund

;  3/8  ungenutzt

;  4/16	rot ....\
;  5/32	grün ... > Vordergrund
;  6/64	blau .../

;  7    blinken


;Matrixcodes .....

;  d     e 	????
; 40	80	Space
; 40	10	ESC
; 80	01	Shift
; 40	20	Enter


;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M/3.5M-Modul)
; (c) KOMA Alexander Schön, 2005-2007
;------------------------------------------------------------------------------

; etwas Grafisches ......
; a.) Fenster - Ecken 

ecke_oben_links	  	equ  	193
ecke_oben_rechts  	equ  	137
ecke_unten_links  	equ  	136
ecke_unten_rechts 	equ  	200

; b.) Fenster - Seiten 
balken_links	  	equ  	159
balken_rechts	  	equ  	192
balken_oben	  	equ  	158
balken_unten      	equ  	248

; c) Schatten
schatten_oben	  	equ  	179
schatten_rechts	  	equ  	180
schatten_links	  	equ  	177
schatten_unten	  	equ  	182
schatten_ecke	  	equ  	176


; Farben
window_background 	equ  	7

; - - - - - - - - - - - - - - - - - - - - - - - - - - 
; Systemvariablen 

atrib		  	equ  	027h		; aktuelles Farbatribut 

p1rol		  	equ  	03bh
p2rol		  	equ  	03ch
p3rol		  	equ  	03dh
p4rol		  	equ  	03eh

screen 			equ 	0ec00h
colors			equ 	0e800h

p1rol_value	  	equ 	1900h 
p3rol_value	  	equ 	2900h

;******************************************************************************

	include	"../includes.asm"

GPIOD		equ 	0fe8fh			; GPIOD .... Tastaturpio direkt lesen
INPIO		equ	0fae9h                     ; INPIO .... Tastaturinit

		org 	300h

		jp 	start
;;		db 	"MENU    ",0		; aus Sicherheitsgründen kein OS-Rahmen
;;		db 	0			; falls Teile von MENU überschrieben werden


; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
; die graphische Oberfläche

		include "menu_maus.asm"

;******************************************************************************
; MENU
;******************************************************************************

start:
; die Sachen mit dem Cursor sind noetig, damit spaeter auszufuehrende Programme
; darauf zurueck greifen koennen und diese Code nicht erst im zu kopierenden
; Kode untergebracht werden muss

		ld	(sp_save), sp		; sp sichern

		; Bildschirmformat und Randfarbe einstellen

		call 	bildschirm_grundeinstellungen

		; cursor auf 1,1 setzen
		ld  	de, 0101h
		ld  	c, 18
		call 	5

		; cursor loeschen
		ld   	c,29
		call 	5

		; Mauscursor auf 0,0
		ld   	bc, 0000h		; muss sein, Sorry
		ld   	(maus_x),bc

		call 	baue_Bildschirm		; Bildschirm aufbauen .....

; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

prepare_main_loop:
		ld 	hl, maus_item_checker	; mausabhandlungsproz setzen
		ld 	(mauscall), hl

		call 	maus_prog_start
		call 	maus_an			; maus ist noch aus, also aktivieren
		call 	wait_no_key		; manchmal ist der User langsamer als das Programm, drueckt enter
						; laenger als gewollt und loest damit schon die naechste Aktion aus

main_loop:
		call 	maus_abfrage

		and 	a, 100000b		; erst wenn ein Button gedrueckt wurde, dann verlassen den Loop
		jr 	z, main_loop

;action_auswerten

		call 	maus_aus		; maus ausschalten, wie ueblich

		; !!! wir haben einen gedrueckten Button
		; --> gehe alle Items durch und untersuche, ob er der User etwas angeklickt hat

		ld  	a, (last_active_item)

		; hier ist das letzte Item gespeichert, über dem sich die Maus befand oder auch nicht's

		or  	a,a			; eventuell sind wir ja garn nicht ueber einem Icon
		jr  	z,prepare_main_loop

		ld  	iy, itemtab		; Tabelle der Items

		ld  	b,a
		ld  	a, itemanzahl		; Anzahl der Elemente

		sub 	a,b

		rla				; zaehler *2

		ld  	b,0
		ld  	c,a
		add 	iy,bc			; und zu iy dazu, um so das richtige Item zu ermitteln

		ld 	l,(iy)
		ld 	h,(iy+1)		; adresse heraus holen

		call 	check_item_ordner 	; zero gesetzt, falls Ordner_icon gefunden

		inc 	hl			; Adresse
		inc 	hl

		; ab hier die Daten oder das  Unterprogramm

		ld 	e, (hl)
		inc 	hl
		ld 	d, (hl)

		; de enthält nun das Unterprogramm oder die Adresse der Filetabelle
		; verzweige je nach Inhalt .....
		; !!! Flags immer noch vom Test her gesetzt ... hoffentlich

		call 	maus_get_Position	; alte Mausposition speichern
		push	bc

		jr  	nz, no_sub_menu
; Ordner aufklappen
		push 	de
		pop  	ix			; Filetable in ix speichern

		call 	dialog_template

		jr  	after_sub_menu_caller

; direkter Start
no_sub_menu:
		ex 	de,hl			; Adresse nun in Hl

		call 	subProgramm_rufer

after_sub_menu_caller:

		pop	bc			; Mausposition wieder holen
		ld	(maus_x),bc

		jr  	nc,prepare_main_loop 	; nur EXIT und ein aktiviertes Progi setzt das Carry

; -----------------
; Programm starten
; -----------------

		; !!!! in HL steht eventuell das letzte aufgerufene Programm
		; !!!! bitte beim folgenden Programmaufruf beachten

		; !!! untersuche, was passiert ist ...
		; 1.) all das tun, was Exit und Programmstart zusammen tun muessen

		; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
		; 1.a.)Ruecksetzen der RollWerte
		ld	bc, p1rol_value
		ld 	(p1rol),bc
		ld  	bc, p3rol_value
		ld 	(p3rol),bc

		; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
		; 1.b.)Tastatur abfangen und die Puffer loeschen
		; aufpassen, das Zeiger auf eventuell auszuführende Programme erhalten bleiben
		exx
		call 	wait_no_key
		exx
		xor  	a,a
		ld 	(024h),a		;LAKEY tastaturbuffer loeschen
		ld 	(025h),a		;KEYBU

		; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
		; nun der Test darauf, ob es ein Exit war oder nicht
		ld  	a, (last_active_item)
		cp  	a, itemanzahl		; war die letzte Aktion zufälig ein EXIT
		jr  	z, exit

		push 	hl			; Code fuer aufgerufenes Programm speichern
		or  	a,a			; carry wieder loeschen, sonst meint Bos, wir hatten einen Fehler

		; Stringadresse holen und nach de damit

		pop 	de			; Programmadresse und wiederholen

		; und ab zur entsprechenden Auswertungs- und Sprungroutine

		jp 	startproc

exit:		ld 	a, ' '
		call 	cls_fast
		or 	a,a
		ret


;------------------------------------------------------------------------------
; Test, ob Ordner oder direkte Programmaadresse

check_item_ordner:
		; hl = Zeiger auf Itemanfang .....
		; Z Flag gesetzt, falls = Ordner_icon
		; !!! hl +2

		push 	de
		push 	bc

		ld   	bc, ordner_icon
		or  	a,a			; Carry löschen
		ld  	e, (hl)
		inc 	hl
		ld  	d, (hl)
		inc 	hl

		ex  	de, hl

		sbc 	hl, bc

		ex  	de, hl

		pop  	bc
		pop  	de

		ret



;------------------------------------------------------------------------------
subProgramm_rufer:
;		ld	sp, (sp_save)	; sp restaurieren
;                call 	INPIO           ; Tastaturinit
;		ld	bc, p1rol_value
;		ld 	(p1rol),bc
;		ld  	bc, p3rol_value
;		ld 	(p3rol),bc
;		;
;		ld	a, ' '
;		call	cls_fast

		jp	(hl)



;------------------------------------------------------------------------------
; Baue den grafikbildschirm auf ... Hintergrund, Icons, Menueleiste
baue_Bildschirm:
		; - - - - - - - - - - - - -
		; Bildschirm aufbauen .....
		ld	a,2
		call	cls_fast		; Bildschirm löschen

baue_Bildschirm_2ter_einsprung:
		; - - - - - - - - - - - - - - -
		; Variablen setzen ......
		ld	a, 0			; bisher kein Item activ
		ld	(last_active_Item),a

		; neue Bildschirmbegrenzung
		ld   bc, 2600h			; Zeile min - max
		ld   (p1rol), bc
		ld   bc, 1500h			; Spalte min - max
		ld   (p3rol), bc

		; - - - - - - - - - - - - -
		; die Kopfzeile zeichnen
		ld	a, 00000111b 		; schwarz auf weisen Untergrund
		ld	hl, colors
		ld	(hl),a
		ld	de, colors+1

		ld	bc,39			; nur 40 Zeichen
		push	bc
		ldir

		; Zeile leeren
		ld	a, ' '
		ld	hl,screen
		ld	(hl),a
		ld	de,screen+1
		pop 	bc
		push	bc
		ldir
		
		; Text ausgeben
		ld	hl, memorytext
		ld	de, screen+11
		call	print_text

		ld	hl, screen+40
		ld	de, screen+41
		ld	a,158
		ld	(hl),a
		pop	bc
		ldir				; 39 -> spart ein Byte ;-)

		; Item's zeichnen ....
		ld	ix, itemtab		; Itemtabelle anwaehlen
		ld	b,itemanzahl		; Anzahl der Ordner bzw. Elemente

		; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
		; Ordner auf dem Bildschirm ausgeben

item_print_loop:
		ld	l, (ix)			; Pointer auf neue Itemstruktur holen
		inc	ix
		ld	h, (ix)
		inc	ix

		push	bc			; zaehler speichern
		call	print_item		; Icon ausgeben
		pop	bc

		djnz	item_print_loop		; solange springen, bis alle Icon's gesetzt
		ret


;------------------------------------------------------------------------------
; teste, ob sich die Maus übereinem Icon befindet ...... !
maus_item_checker:

		exx

		ld	ix, itemtab		; Zeiger auf Itemstruktur
		ld	d, itemanzahl		; anzahl der Elemente ....

		exx

mausItemChecker_loop:

		ld	l,(ix)			; Pointer auf Itemstructur holen
		inc	ix
		ld	h,(ix)
		inc	ix

		; aktuelles Item bearbeiten

		ld	e, (hl)			; zeiger auf das Icon holen
		inc	hl
		ld	d, (hl)
		inc	hl

		push	de
		pop	iy			; Zeiger auf Icon nach Iy

		ld	d, (hl)			; x Position
		inc	hl
		ld	e, (hl)			; y Position
		inc	hl

		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		; Prüfe, ob der Mauszeiger auf dem gerade aktiven Icon ist ....
		; d <= b <= d + iy

		ld	a, d			; x
		cp	b				; e-b = itempos_x - maus_x
		jr	z, mausItemChecker_rechtslinks
		jr	nc, mausItemChecker_weiter

mausItemChecker_rechtslinks:

		add	a, (iy+4)		; maximale Breite des Icons
		cp	b
		jr	c, mausItemChecker_weiter

		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		ld	a, e
		cp	c
		jr	z, mausItemChecker_obenunten
		jr	nc, mausItemChecker_weiter

mausItemChecker_obenunten:

		add	a, (iy+5)
		cp	c
		jr	c, mausItemChecker_weiter


		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		; wenn hier angelangt, geoeffnetes Item anzeigen

		; test, ob ein wechsel des Icon's oberhaupt nünig ist ......

		exx
		ld	a, (last_active_item)
		cp	d
		exx

		jr	z, mausItemChecker_exit

		ld	b,d			; x,y Koordinaten auf BC
		ld	c,e			; für calcscreenPos

                push	hl			; structurpointer speichern

                ; bis hier her ....
                ; hl = strukturPointer

                ; Bildschirmadresse berechnen ....
                ; bc = x,y
                ; Ergebnis in hl


                call	calc_screen_pos
                ; !!!! screenpos in hl
                ex	de,hl

                ld	l, (iy+2)
                ld	h, (iy+3)

                ; - - - - - - - - - - - - - - - - - - - - -
                ; P R I N T _ I C O N

                ; de ... wohin damit
                ; hl ... Icon Typ
                ; - - - - - - - - - - - - - - - - - - - - -

                call	print_icon

                pop	hl

                ; und raus hier .....

		jr	mausItemChecker_leaveLoop

mausItemChecker_weiter:

		exx
		dec	d
		exx
		jr	nz, mausItemChecker_loop	; wenn b runtergezaehlt ist, war's das ...

mausItemChecker_leaveLoop:

		ld	ix, itemtab
		ld	b,itemanzahl		; Anzahl der Item's

		ld	a, (last_active_item)
		or	a,a
		jr	z, mausItemChecker_exit ; falls das letzte keins war.....


mausItem_checker_restore_item_loop:

		ld	c,a
		ld	a,b
		sub	a,c

		rla
		ld	c,a
		ld	b,0
		add	ix,bc

mausItem_checker_restore_item_leave:

		; Item gefunden ....

		ld	l, (ix)			; Pointer herausloesen
		ld	h, (ix+1)

		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		inc	hl

		push	de			; Itemstructur
		pop	iy

		ld	b, (hl)			; x Adresse
		inc	hl
		ld	c, (hl)			; y Adresse

		; Bildschirmadresse berechnen ....
		; bc = x,y
		; Ergebnis in hl

		call	calc_screen_pos

		ld	e, (iy)			; da ich das Icon fuer geoeffnet will
		ld	d, (iy+1)

		ex	de,hl

		; - - - - - - - - - - - - - - - - - - - - -
		; P R I N T _ I C O N

		; de ... wohin damit
		; hl ... Icon Typ
		; - - - - - - - - - - - - - - - - - - - - -

		call	print_icon

mausItemChecker_exit:

		exx
		ld	a,d
		ld	(last_active_item),a
		exx

		ret


;------------------------------------------------------------------------------
; W A I T
; .... ganz normal bis eine bestimmte Zeitspanne angelaufen ist

wait:
		push af
		push de
		ld   e, 0h
wait_loop
		dec de
		ld  a, d			; Flags werden blöderweise bei 16Bit Registern nicht beeinflußt .....
		or  a, a
		jr  nz, wait_loop

		pop  de
		pop  af

		ret


;------------------------------------------------------------------------------
; .... bis der User endlich keine Taste mehr drückt

wait_no_key:
        	; zu begin testen, ob Taste gedrueckt ist ....
		; meist kommt ein Enter von der Eingabe her und beendet Menu gleich wieder

                call GPIOD 			; Tastaturpio direkt lesen

		push de
                call INPIO                     ; Tastaturinit
		pop  de


		ld   a, d
		or   a,a
		jr   nz, wait_no_key

		ld   a,e
		or   a,a
		jr   nz, wait_no_key

		ret


;------------------------------------------------------------------------------
; Koordinaten in Bildschirmadresse umrechnen Position berechnen ......
; b = x
; c = y koordinaten
; Ergebnis in HL

calc_screen_pos:

		push	de

		; !!! carry noch löschen ....

		; y*40+x ...... + screen

		ld   h, 0
		ld   l, c			; y .....

		add  hl,hl
		add  hl,hl
		add  hl,hl

		ld   d,h
		ld   e,l			; y zwischenspeichern

		add  hl,hl
		add  hl,hl
		add  hl,de			; y*32+y*8 = y*40

		ld   de, screen
		add  hl, de 			; y*40+screen

		ld   c,b			; x nach c
		ld   b,0

		add  hl, bc			; y*40+x+screen

		; Berechnungen abgeschlossen ....

		pop	de

		ret

;------------------------------------------------------------------------------
; P R I N T I T E M
; hL:		aktuelle Itemstructur

print_item:

		ld c,(hl)			; Iconpointer holen
		inc hl
		ld b,(hl)
		inc hl

		push bc				; Iconstructor auf iy
		pop  iy

;print_item_jump_here:

		; Icon Position holen
		ld b,(hl)
		inc hl
		ld c,(hl)
		inc hl

		; bildschirmposition berechnen ...
		; Werte in BC
		; Ergebnis in HL
		;     !!! soll aber nach DE, HL ist belegt

		ex    de,hl
		push  de
		call  calc_screen_pos 		; Bildschirmposition berechnen
		pop   de

		ex    de,hl			; !!!  Rückgabe in HL, aber schon belegt

		push  de

		ld    e, (iy)
		ld    d, (iy+1)

		push  de

		exx				; auf anderen Registersatz umschalten

		pop   hl
		pop   de			; iconposition

		call print_icon
		exx

		inc   hl			; ausfuehrcode ueberspringen
		inc   hl

		; Icon Schrift Position
		ld    e, (hl)
		inc   hl
		ld    d, (hl)
		inc   hl

		; bc bleibt = Bildschirmposition schon auf Bildschirm umgerechnet
		; hl bleibt = Text

		; . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
		; Ausgabe der ersten Zeile im BorlandPascal Style ... führende länge
		; ....
		; das Ganze ist etwas umständlich, später für die Verzeichnissausgabe mit dem Directorybefehl ganz
		; praktisch ....... der Aufbau des Strings macht die Suche für Dir mit Joker wesentlich einfacher

		ld  b, 0			; Zähler löschen ....
		ld  a, (hl)			; Zähler holen
		or  a,a				; wenn nichts da ist, dann war's das hier schon ....
		ret z

		push  de

		ld  c, a			; Anzahl der Zeichen
		inc hl				; Quelle auf Textanfang setzen ....
		ldir
		pop   de

		ld    c, 40
		ex    de,hl
		add   hl, bc
		ex    de,hl

		call print_text

		ret

;------------------------------------------------------------------------------
; Print_text ..... der String wird mit einer 0 beendet
; hl = von
; de = wohin

print_at:	push hl
		call calc_screen_pos
		pop  de				; von
		; !!! hl lieferte die "wohin" Adresse --> noch tauschen
		ex  de,hl

		; kein ret, da gleich noch die Ausgabe folgt und der Rücksprung davon ausgeführt wird ...
		; spart mind. noch einen jp oder/und ein ret 6

print_text:
		ld a,(hl)
		or a,a
		jr z, print_text_exit

		ldi
		jr print_text

print_text_exit:
		inc hl
		ret

;------------------------------------------------------------------------------
; P R I N T _ I C O N
; de ... wohin damit
; hl ... Icon Typ

print_icon:

print_icon_loop:
		ld 	a,(hl)			; Anzahl der Bytes lesen
		or 	a,a			; 0 Bytes ????
		ret	z

		push    de
		call 	print_text
		pop     de

		ld 	bc,40

		ex 	de,hl
		add	hl, bc
		ex 	de,hl

		jr	print_icon_loop

;print_icon_ende:

		ret


;******************************************************************************
; C L S .... Bildschirm löschen
; !!! in a den Farbcode zum löschen übertragen .....
;******************************************************************************

cls_fast:
		ld	bc, 0			; x,y
		ld	de, 02818h		; Breite, Hoehe
		call 	clear_box		; und loeschen

		call bildschirm_grundeinstellungen	; Rahmen, zukünftige Hintergrundfarbe usw.

		ret

;------------------------------------------------------------------------------
bildschirm_grundeinstellungen:

		ld  a, 32			; aktuelles Farbattr. auf Grü/schw. Hintergrund setzen
		ld  (atrib),a

		xor a,a				; Rahmen einstellen
		out 136,a

		ret


;------------------------------------------------------------------------------
; lösche einen angegebenen Bereich mit einer speziellen Farbe
; a = Farbe
; b,c = x,y
; d,e = Breite, Hoehe
; Return : DE ..... Berechnete Fensterpsotion im Bildschirmspeicher (rechte obere Ecke ....)

clear_Box:
		push	hl
		; push bc & push hl eh sinnlos, da schon von aufrufer geändert und eventuell vorher gepusht


		; a.) berechne die aktuell Bildschirmramposition
		call calc_screen_pos		; b = x, c = y koordinaten
						; !!! Ergebnis in HL

		push	hl

		ld	b, d			; Breite sichern
						; !!!! mußin B bleiben, C wird zur 40 - Breite und später, wenn b = 0 (Ende der inneren Schleife) BC zu HL addiert
		; b.) Bildschirmbreite - Boxbreite
		push 	af
		ld	a, 40
		sub	a, b
		ld	c, a
		pop	af

clearBox_loop:

		ld 	(hl), ' '		; Bildschirmspeicher
		res 	2,h			; ECxx -> E8xx
		ld 	(hl), a			; farbspeicher
		set   	2,h			; und wieder zurück

		inc 	hl

		dec   	b
		jr	nz, clearBox_loop

		; !!! B = 0; C = 40-Breite
		; !!! BC ist nun genau das, was zum ende der Zeile hinzu addiert werden muß, um genau an den Anfang der Box in
		; der nächstenZeile zu gelangen

		add	hl, bc			; 40- Breite dazu ...

		; !!! erst hier b wieder zur "Breite" machen
		ld 	b, d			; Breite für nächste Runde holen

		dec 	e
		jr	nz, clearBox_loop

		pop	de

		pop 	hl

		ret


;------------------------------------------------------------------------------
; T E X T E
;------------------------------------------------------------------------------

memoryText: 	db ".: Z9001 GEM X :.",0

helpText:	db "ENTER=o.k.",192, " SHIFT=langsamer",192," ESC=exit",0
helpText_ende:

copyrightText:  db "Mega-Flash-Modul",0
  		db "GEM-Menue (c) KOMA",0
		db "V.Pohlers 2012",0

;------------------------------------------------------------------------------
; I C O N S
;------------------------------------------------------------------------------

; Zeile x: Anzahl der Bytes, Daten

ordner_geschl:	db 134,45,135,0
		db 174,158,158,173,135,0
		db 159,"  ",192,124,0
		db 136,248,248,200,152,0
		db 0

ordner_offen:	db 134,45,135,0
		db 174,158,158,173,248,0
		db 159,"  ",192,153,0
		db 136,248,248,200,152,0
		db 0

diskette_offen	db 194,137,158,158,137,0
		db 193,158," "," ",192,0
		db 159," ",140," ",192,0
		db 159," ","n"," ",192,0
		db 136,248,"U",248,200,0
		db 0

diskette_geschl	db " "," "," "," "," ",0
		db " ",194,158,137," ",0
		db " ",159,"o",192," ",0
		db " ",136,"O",200," ",0
		db " "," "," "," "," ",0
		db 0

exit_geschl:    db " x",192,0,0
exit_offen:	db " X",192,0,0

frage_geschl:	db 192," ?",0,0
frage_offen: 	db 192," ",64,0,0

cpm_icon	dw diskette_geschl
		dw diskette_offen
		db 5,5

ordner_icon: 	dw ordner_geschl
		dw ordner_offen
		db 6,4			; Breite, Hoehe

exit_icon:	dw exit_geschl
		dw exit_offen
		db 3,1

frage_icon:	dw frage_geschl
		dw frage_offen
		db 4,1

;------------------------------------------------------------------------------
; M A U S C U R S O R
;------------------------------------------------------------------------------

mauscursor: 	db 143
		db 214

;------------------------------------------------------------------------------
; M E N U - Daten
;------------------------------------------------------------------------------



; berechne die aktuelle Bildschirmposition ........

calc_screen_pos_static	MACRO x,y
			dw	screen+y*40+x
			endM

exit_item:
		dw exit_icon			; Icon,
		db 0,0				; wo
		dw exit_subprogramm		; auszufuehrendes Unterprogramm
		calc_screen_pos_static 0,0
		db 0,0

frage_item:
		dw frage_icon
		db 36,0
		dw copyright_subprogramm	; auszufuehrendes Unterprogramm
		calc_screen_pos_static 0,0
		db 0,0

;wir brauchen derzeit 9 Ordnersymbole, also Anordnung wie bei KOMA
; Dateikategorie
;fk_unknown		equ	0
;fk_tools		equ	1
;fk_spiele_basic	equ	2
;fk_spiele_mc		equ	3
;fk_buero		equ	4
;fk_programmierung	equ	5
;fk_treiber		equ	6
;fk_demos		equ	7
;fk_cpm			equ	8


calc_item	MACRO pos,fktyp,textoffs	; by vp

nr		eval	(pos-1) / 4		; Anz. pro Reihe
x		EVAL	(pos-1-nr*4)*9 + 3
y		EVAL	nr*7 + 2
		
		dw ordner_icon
		db	x,y			; wohin
		dw	fktyp			; FileTable
		dw	screen+(y+4)*40+x+(textoffs)	; Text wohin
		endM

spiele1_item:	calc_item 1,fk_spiele_basic,-1
		db 6,"spiele"
		db   "basic",0

spiele2_item:	calc_item 2,fk_spiele_mc,-1
		db 6,"spiele"
		db   "  mc",0

buero_item:	calc_item 3,fk_buero,0
		db 5,"buero",0

sprachen_item:	calc_item 4,fk_programmierung,-2
		db 8,"sprachen"
		db   "  & co",0

treiber_item:	calc_item 5,fk_treiber,-1
		db 7,"treiber",0

demos_item:	calc_item 6,fk_demos,-1
		db 7,"demos &"
		db   " musik",0

;1
tools_item:	calc_item 7,fk_tools,0
		db 5,"tools"
		db 0

;0
sonstige_item:	calc_item 8,fk_unknown,-2
		db 8,"sonstige"
		db 0

;user defined (alle sonstigen fk_typen fk_cpm+1 .. 63
user_item:      calc_item 9,00ffh,-1
		db 7," user  "
		db   "defined",0

; OS-Rahmen-Programme
os_item:      	calc_item 10,0ff00h,-2
		db 8,"   os   "
		db   "programs",0

; OS-Rahmen-Programme
cpm_item:      	calc_item 11,fk_cpm,1
		db 3,"cpm",0

minicpm_item:
		dw cpm_icon			; Icon,
		db 29,16			; wo
		dw startcpm_Icon		; auszufuehrendes Unterprogramm
		calc_screen_pos_static 28,21
		db 7,"minicpm",0


;------------------------------------------------------------------------------
; alle Items in eine Tabelle ....
;------------------------------------------------------------------------------

itemTab: 	dw exit_item
		dw frage_item
		dw spiele1_item
		dw spiele2_item
		dw buero_item
		dw sprachen_item
		dw treiber_item
		dw demos_item
		dw tools_item
		dw sonstige_item
		dw user_item
		dw os_item
		dw CPM_item
		dw minicpm_item
itemtab_ende:

itemanzahl	equ (itemtab_ende-itemTab)/2


;------------------------------------------------------------------------------
; W I N D O W ....
; Carry nicht gesetzt .... die Mauseinstellungen werden uebersprungen
; b,c = x,y
; d,e = Breite, Hoehe
; - es wird erst die obere Kante, dann der Mittelteil und dann die untere Kante gezeichnet
; - Schatten und Hintergrund werden parallel dargestellt ....
; - ix wird zum zeichnen des Schattens benötigtund iy zum Zeichnen des Hintergrundes

window_balken:
		ld	b, d
window_balken_loop:
		ld 	(hl), a
		inc	hl
		dec	b
		jr	nz, window_balken_loop

		ret

;------------------------------------------------------------------------------
window:		push  hl
		push  bc

		jr   nc, window_w1		; soll die Maus eingeschraenkt werden ????

		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
		; Mausbewegung auf fenster eingrenzen ...

		ld   a, b			; x
		add  a, d			; Breite
		sub  a,3			; 2 Balken und Schatten

		ld   l, b			; xmin
		inc  l
		ld   h, a			; xMax
		ld   (p1rol), hl

		ld   a, c			; y
		add  a, e			; Höhe
		sub  a,3			; 2 Balken und schatten

		ld   l, c			; xmin
		inc  l
		ld   h, a			; xMax
		ld   (p3rol), hl

		; - - - - - - - - - - - - - - - - - - - - -
		; und die wMaus in das Fenster setzen

		push bc
		inc  b
		inc  c
		call maus_goto
		call maus_aus
		pop  bc

window_w1:
		push 	de

		; a.) Fensterhintergrund zeichnen .... Rückgabewertin de ist gleich die obere linke Ecke im Bildschirmspeicher
		ld	a, window_background
		call	clear_box

		ex	de,hl			; HL auf ersten Element des Fensters
		pop	de			; Breite, Höhe

		dec	d
		dec	d			; -2

		ld	a, 38			; - Balken rechts und links
		sub 	a, d
		ld	c, a			; 40-breite

		; b) die untere Kante
		; c.1) linke Ecke
		ld 	(hl), ecke_oben_links
		inc	hl

		; b.2) balken
		ld	a, balken_oben
		call	window_balken

		; b.3) rechte Ecke
		ld 	(hl), ecke_oben_rechts
		inc	hl

		; b.4) der Schatten rechts
		ld	(hl), schatten_oben

		; b.5) auf zur nächsten Zeile
		add	hl, bc			; b ist gerade 0, C ist belegt

		; c) die mittleren Zeilen
		dec	e			; die Höhewird für den Loop zu groß angegeben
		dec 	e
window_mid_loop:
		; c.1) die Balken rechts und links
		ld	(hl), balken_links
		ld	a, c			; save
		ld	c, d
		inc	c
		add	hl, bc
		ld	(hl), balken_rechts
		ld	c, a			; re_save
		inc	hl

		; c.2) Schatten
		ld	(hl), schatten_rechts
		add	hl, bc

		dec	e
		jr	nz, window_mid_loop

		; d) die untere Kante
		; d.1) linke Ecke
		ld 	(hl), ecke_unten_links
		inc	hl

		; d.2) balken
		ld	a, balken_unten
		call	window_balken

		; d.3) rechte Ecke
		ld 	(hl), ecke_unten_rechts
		inc	hl

		; d.4) der Schatten rechts
		ld	(hl), schatten_rechts

		; d.5) auf zur nächsten Zeile
		add	hl, bc			; b ist gerade 0, C ist belegt

		; e) der Schatten unten ....
		; e.1) linke Ecke
		ld 	(hl), schatten_links
		inc	hl

		; e.2) balken
		inc	d
		ld	a, schatten_unten
		call	window_balken

		; e.3) rechte Ecke
		ld 	(hl), schatten_ecke

; und warten, bis endlich die gedrueckte Taste losgelassen wurde
		call wait_no_key

		pop  bc
		pop  hl

		ret

;------------------------------------------------------------------------------
window_help_line:

; und noch die Hilfsline zeichnen .....

		push 	hl
		push 	de
		push 	bc

		ld 	a, 00000111b 		; schwarz auf weissem Untergrund
		ld 	hl, colors+23*40
		ld 	(hl),a
		ld 	de, colors+1+23*40

		ld 	bc,39			; nur 40 Zeichen
		push 	bc
		ldir

		; Text ausgeben
		ld 	hl, helptext
		ld 	de, screen+0*40+ ((41-helpText_ende+helpText) >> 1) ; zentriert
		call 	print_text

		ld 	hl, screen+22*40
		ld 	de, screen+22*40+1
		ld 	a, balken_unten
		ld 	(hl),a
		pop 	bc
		ldir

		pop 	bc
		pop 	de
		pop 	hl


		ret

;------------------------------------------------------------------------------
; Unterprogramme, die die einzelnen Items benoetigen
;------------------------------------------------------------------------------

exit_subprogramm:

		scf				; carry loeschen 
		
		ret

;------------------------------------------------------------------------------
copyright_subprogramm:

		push bc

		; Fenster zeichnen ......
		scf
		ld   bc, 0809h			; x,y Position
		ld   de, 1807h
		call window

		; erste Meldung setzen und Bildschirmposition berechnen
		ld   bc, 0c0ah
		ld   hl, copyrighttext
		call print_at

		ld   bc, 0b0ch
		call print_at

		ld   bc, 0d0eh
		call print_at

		pop  bc

		ld hl, maus_prog_no_code
		ld (mauscall), hl

		call maus_an
		call maus_wait

copyright_dialog_loop:
		call maus_abfrage

		bit 4,a
		jr z,copyright_dialog_loop

		call maus_aus

		; Fenster loeschen ......
		ld   a,  2
		ld   bc, 0809h			; x,y Position
		ld   de, 1908h
		call clear_box


		call baue_Bildschirm_2ter_einsprung

		or a,a				; Carry loeschen

		ret


;------------------------------------------------------------------------------
; Ordnerinhalt anzeigen + Programm auswählen

; maximal 3 Spalten
; maximal 16 Dateien	macht maximal 45 Dateien pro Ordner

; Spaltenbreite:
; - Name des Programms .................... 8
; - jeweils rechts und links ein Marker ... 2

; de = ix = fktyp

dialog_template:

		;;ld	a,R		; testweise
		;;ld	ix, flash_struct	; std. für 
		
		push	de
		call	fill_dir_array
		call	calc_flash_struct
		pop	de
		ld	(ix+max_daten),e
		ld	(ix+max_daten+1),d
	

		; gibt es ueberhaupt Elemente ??????
		; wenn nicht, erspar mir den Ärger.....

		ld a, (ix)			; Anzahl der Elemente
		or a,a
		ret Z				; falls keine Elemente gespeichert sind ..... Ende

		; Anzahl der Spalten ermitteln
		; - - - - - - - - - - - - - - - - - - - - -
		; Fensterbreite und Hoehe berechnen


		ld b, (ix+max_first_x)		; obere linke Ecke
		ld c, (ix+max_first_y)

		ld d, (ix+max_breite)		; Breite und Hoehe holen
		ld e, (ix+max_hoehe)

		; eine Art Grundzustand
		xor a,a				; 0
		ld (last_active_spalte), a	; alles mit 0 bestuecken
		ld (last_active_zeile), a

dialog_template0
		push bc				; damit wird später das Fenster wieder gelöscht
		push de

		push ix				; muss sein, da Window IX braucht .... Sorry

		; - - - - - - - - - - - - - - - - - - - - - - -
		; Fenster zeichnen ......
		; b,c = x,y
		; d,e = Breite, Hoehe

		; Test auf Scrollen? Dann Maus nicht verändern		
		ld	a,(maus_rand)		; test
		or	a			; a=0?
		jr	z,dialog_template01
		ld	hl,(maus_x)		; maus-pos. merken
		scf				; heisst Maus auf das aufzubauende Fenster einschränken ......
		call 	window			; Window zeichnen
		ld	(maus_x),hl		; maus-pos. restaurieren
		jr	dialog_template02
		
dialog_template01:
		scf				; heisst Maus auf das aufzubauende Fenster einschränken ......
		call window			; Window zeichnen
dialog_template02:
		call window_help_line		; und die Infolinie am unteren Bildschirmrand ebenfalls
		pop ix

		; vp: Scrollmarker zeichnen
		; B = 1. Spalte
		ld	a,(ix+max_elemente)
		cp	(ix+max_elemente_ges)
		jr	z, dialog_template1	; alle Elemente werden angezeigt -> kein Scrollmarker nötig
		push	bc
		ld	e,b
		ld	d,0
		ld	hl, screen+40*12	; mittlere Zeile
		add	hl,de
		ld	(hl), 180		; Zeichen links im Rahmen
		ld	e,(ix+max_breite)
		add	hl,de
		ld	(hl), 159		; Zeichen rechts im Rahmen
		pop	bc

dialog_template1
		inc b
		inc b				; hier das erste Element zeichnen
		inc c

		call calc_screen_pos

		ex  de,hl			; Ergebnis muß nach DE

		ld  l, (ix+max_daten)		; Zeiger auf die Daten, die im Fenster dargestellt werden sollen
		ld  h, (ix+max_daten+1)

		exx
		ld  b, (ix+max_zeilen)		; Anzahl der Zeilen
		ld  c, (ix+max_spalten) 	; und Spalten holen
		exx


		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

		push de				; wird eventuell spaeter fuer die 2te und 3te Spalte nocheinmal
						; benoetigt
						
		ld	hl, dir_array	; gefundene Prg.
		;Offs. vorhanden?
		ld	a, (ix+max_elemente_offs)
		or	a
 		jr	z, print_files_loop
		;Offs. beachten
		push	bc
		ld	bc, 12
print_files_loop1
		add	hl,bc
		dec	a
		jr	nz, print_files_loop1
		pop	bc
		
print_files_loop:
		inc hl				; die Startadresse der Programme uebergehen
;
		ld  a,(hl)			; 
		cp	0cch			; Ende erreicht? (Endekennzeichen s. MENU_OS/MENU_FA)
		jr  z, print_files_leaveLoop
;
		inc hl
		inc hl				; hl zeigt nun auf den Dateinamen

		call print_text			; Programmnamen ausgeben

		; 40-8 Zeichen dazu ..... und das naechste Element zeichnen
		ex  de,hl			; in DE ===> Bildschirmposition
		ld  a,b				; Zaehler speichern
		ld  bc,31

		; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
		; Balken zeichnen
		; !!! auch, wenn nur eine Spalte, da der Balken = dem Rand und dadurch mehrere Zeilen
		; abfragecode gespart werden

		inc hl
		ld  (hl), balken_rechts

		add hl,bc
		ld  b,a				; und wieder holen
		ex  de,hl

		exx
		dec b				; zeilencounter herunter zaehlen
		exx
		jr  nz, print_files_loop

		; !!! in hl ist noch der Filepointer gespeichert
		pop  de				; letzte oberste Bildschirmadresse
		ex  de,hl			; Tausch, um Addieren zu können
		ld   bc, 12
		add  hl, bc			; naechste Spalte ist adressiert
		ex  de,hl

		exx
		ld  b,(ix+max_zeilen)		; wieder die Zeilenanzahl eintragen, ist zum Glück noch in a gespeichert
		dec c				; Spaltenzahl verringern
		exx

		push	de			; muss sein, sonst würde der Pop beim verlassen des loops den Stack durcheinander bringen
		jr  nz,print_files_loop

print_files_leaveLoop:
		pop de				; es ist halt noch da, also hole es

;print_files_weiter:

		push ix

		; - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -


		ld hl, maus_call_fileDialog
		ld (mauscall), hl

		call maus_prog_start		; damit schon einmal etwas selectiert ist
		call maus_an
		call maus_wait

templatedialog_maus_loop:
		call maus_abfrage		; Mauszeiger und FileSelektor bewegen
						; bei jeder Aktion wird maus_call_fileDialog aufgerufen

		; neu Zeichnen?
		push	af			; a sichern

		ld	a,(ix+max_elemente)
		cp	(ix+max_elemente_ges)
		jr	z, templatedialog_maus_loop1	; alle Elemente werden angezeigt -> kein Scrollen nötig

		ld	a,(maus_rand)		; test (1=linker Rand, 2=rechter Rand)
		or	a			; a=0?
		jr	z, templatedialog_maus_loop1	; dann nicht neu zeichnen
		
		; sonst Dialog neu zeichnen
		ld	b,(ix+max_zeilen)
		ld	c,(ix+max_elemente_offs)

		; linker Rand?
		cp	1
		jr	nz, chkrand1		; sonst rechter Rand
		ld	a,c
		sub	a,b
		jr	c, templatedialog_maus_loop1
		jr	chkrand2

chkrand1	; rechter Rand
		ld	a,c
		add	a,b
		cp	(ix+max_elemente_ges)
		jr	nc, templatedialog_maus_loop1
chkrand2		
		; max_elemente_offs setzen
		ld	(ix+max_elemente_offs),a
		
		pop	af			; a rücksichern
		pop  	ix			; Stack restaurieren
		pop 	de
		pop 	bc
		jp	dialog_template0	; wenn Flag gesetzt, neu zeichnen

templatedialog_maus_loop1
		
		pop	af			; a rücksichern
		and a, 00110000b		; ESC und Space sind als Ergebnis möglich
		jr z, templateDialog_maus_loop


		; weiter wenn ESC oder SPACE

;templateDialog_auswerten:

		pop  ix

		; . . . . . . . . . . . . . . . . . . . . . . . . . . .
		; Bildschirm wieder herstellen
		pop de				; breite, Hoehe
		pop bc				; x,y

		push ix
		push af
		inc d				; Schatten !!!!
		inc e
		ld   a, 2
		call clear_box

		; den Bildschirm unten noch in Ordnung bringen
		ld hl, screen+ 22*40
		ld de, screen+ 22*40+1
		ld (hl), 20h
		ld bc, 79
		ldir

		; noch den Farbbereich .... !!! obere der beiden Zeilen ist schon in Ordnung ....
		ld hl, colors+ 23*40
		ld de, colors+ 23*40+1
		ld (hl), 2
		ld bc, 39
		ldir

		call baue_Bildschirm_2ter_einsprung
		pop af
		pop ix

		bit 5,a				; Enter oder Space ????
		jr  z, _esc_hit

		; Element heraus suchen ...
		call	calc_index_pos
		jr  c, _esc_hit			; dann war's das


		; fertig ..... zeiger HL steht jetzt auf Rahmen

;		inc hl
;		inc hl
;		inc hl

		scf				; Carry setzen
						; ---> MainLoop wird danach verlassen und das Programm gestartet
		jr dialog_template_exit

_esc_hit:
		or a,a				; Carry loeschen
						; Mainloop wird später nicht verlassen und der User kann sich weiter
						; im Menu bewegen

dialog_template_exit:

		ret


;------------------------------------------------------------------------------
; Ermittlung Position in dir_array

calc_index_pos:

		; Element heraus suchen ...
		ld  a, (last_active_spalte)	; Anzahl der zu untersuchenden Spalten
		ld  c,a				; spaltenzaehler
		inc c

		ld  b, (ix+max_zeilen)		; maximale Zeilenanzahl pro Spalte
		xor a,a				; a= 0

finde_gewaehltes_element_start:

		dec c
		jr  z, finde_gewaehltes_element_w1	; sobald ein ueberlauf stattfindet, raus aus der Schleife

		add a,b				; maxZeilen dazu

		jr  finde_gewaehltes_element_start

finde_gewaehltes_element_w1:


		ld  b,a

		ld a, (last_active_zeile)
		add a,b
		; -> fast fertig, habe nur den Index

		;vp
		ld	b, (ix+max_elemente_offs)
		add 	a,b

		; test darauf, ob eventuell die maximale Elementanzahl ueberschritten wurde

		ld  h, 0
		ld  l, a

		ld  d, a			; Index nach h
		ld  a, (ix+max_elemente_ges)	; anzahl der Element
		dec a				; damit es nur bei einem Vergleich bleibt ....
		cp  d				; anzahl der Elemente-aktuelles Element
		ret  c				; dann war's das

		add hl,hl			; hl*2
		add hl,hl			; hl*4

		push hl

		add hl,hl			; hl*8

		pop  bc
		add hl,bc			; hl*8 + hl*4

		ld  bc, dir_array		; anfang tabelle
		add hl, bc			; + offset

		; fertig ..... zeiger HL steht jetzt auf Rahmen

		or	a			; cy=0
		ret
		
;------------------------------------------------------------------------------
; Aufruf, wenn Feld im Dateidialog selektiert wurde (bzw. bei jeder Mausbewegung)
; Aufruf erfolgt indirekt über menu_maus.mauscall innerhalb templatedialog_maus_loop
; in: z=1 -> am Rand 

maus_call_fileDialog:

		; 1.) die alte Markierung loeschen

		ld   de, (last_active_zeile)
		ld   a, ' '			; Markierungszeichen links und rechts
		; in de wird spalte, Zeile uebergeben
		call calc_file_pos		; alte Position

		; 2.)
		; aus der augenblicklichen Mausposition wird die aktuelle Spalte und Zeile berechnet

		; 2.a.) Mausposition ermitteln

		call maus_get_position		; bc enthaelt nun die Mausdaten

		; 2.b.)
		; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
		; aktuelles y berechnen
		ld   a, c			; y nach a
		ld   e, (ix+max_first_y)	; y Position der oberen linken FensterEcke
		inc  e				; der Text geht's eins weiter unten los
		sub  a,e			; in a steht nun die aktuelle Zeile
		ld   e,a
		; die Zeilenberechnung ist fertig und steht in "e"

		; -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -  -
		ld   a, b			; aktuelles x nach a
		ld   d, (ix+max_first_x)
		inc  d
		sub  a,d			; a hat die Vorstufe zur fertigen Spalteninfo in sich

		ld   d,0-1			; counter .... erste Spalte-1 ist voreingestellt

finde_spalten_zahl_loop:
		inc d				; spaltenzahl erhoehen
		sub a, 12
		jr  nc, finde_spalten_zahl_loop ; falls ein ueberlauf stattfindet war's das

		; die Spaltenberechnunhg ist fertig und steht in "d"

maus_file_dialog_weiter:

		ld   (last_active_zeile),de
		ld   a, '"'			; ": neue Auswahl mit file_marker "..." markieren
		call calc_file_pos

;VP TODO
; Anzeige Fileinfos ...
		; info_zeile leeren
		ld	a, ' '
		ld	hl, screen+23*40
		ld	(hl),a
		ld	de, screen+23*40+1
		ld	bc, 39
		ldir

		; Programm im Dir-Array suchen
		call 	calc_index_pos
		ret	c			; außerhalb des Dir-Arrays
						; dann leere Zeile
		; Info-Zeile füllen
		call	show_info

		ret



;******************************************************************************
; ab hier fast alles neu für Mega-Flash
;******************************************************************************

	include	"menu_dir.asm"

;------------------------------------------------------------------------------

clear_screen:	push	de
                ld  	h, 0e8h			; BWS löschen
		call 	clear_help
                ld  	h, 0ech			; Farb-BWS löschen
		call 	clear_help

		ld 	c, 30			; !!! Curosor ist eh schon geloescht, alo nicht noch einmal
		call 	5			; löschen lassen .... ergibt nur ein sinnloses Zeichen
						
                ld  	de, 0101h
                ld  	c, 18			; cursorposition einschalten
                call 	5
		pop	de
		ret

clear_help:	ld 	l, 00h
		ld 	(hl), ' '
		ld 	d, h
		ld 	e, 01
                ld 	bc, 40*24-1
		ldir
		ret

;------------------------------------------------------------------------------
; CPM starten

CONBU:		EQU	0080H		;CCP ZEICHENKETTENPUFFER
GVAL:    	EQU	0F1EAh

startcpm_icon:
		; HL=Adr. Programmname
		; INTLN mit Programmnamen füllen (Länge, pgm-name, 0)
		LD	hl,cpmprg
		ld	de,CONBU+2
		ld	bc,9
		ldir
		CALL	GVAL		;PARAMETER HOLEN
		; Programm suchen
		LD 	IYl,0FFh	;Suchtyp für FA-Rahmen; FF=alles suchen
		rst	rst_sbos
		db	4		;CPROM	TRANSIENTKOMMANDO SUCHEN
		jr	z, cmpl
		; nicht gefunden
		ret
cmpl:		; gefunden
		ld	sp, (sp_save)	; sp restaurieren
		;
		push	hl		; Startadr.
		push	iy
		;
                call 	INPIO           ; Tastaturinit
		ld	bc, p1rol_value
		ld 	(p1rol),bc
		ld  	bc, p3rol_value
		ld 	(p3rol),bc
		;
		ld	a, ' '
		call	cls_fast
		;
		pop	iy
		pop	hl
		rst	rst_sbos
		db	11		;JMPHL  Programm starten
		ret			;zurück um OS


cpmprg		db	"MINICPM",0


;------------------------------------------------------------------------------
calc_file_pos:

		push af

		ld   a, e
		ld   c, (ix+max_first_y)
		inc  c
		add  a,c
		ld   c,a			; fertig

		ld   a, d
		ld   b, a
		inc  b
		ld   a,-12			; Länge ein Eintrag

finde_x_loop:
		add  a,12			; Länge ein Eintrag
		djnz finde_x_loop

		ld   b,(ix+max_first_x)
		inc  b
		add  a,b
		ld   b,a			; fertig

		; BC ist fertig und enthaelt die aktuellen Info's
		call calc_screen_pos		; Bildschirmadresse brechnen
						; !!! HL enthät Bildschirmadresse
						; b=x bleibt erhalten

		pop  af

		; neues Element zeichnen
		ld   (hl), a
		ld   de,9
		add  hl,de
		ld   (hl), a

		ret

;------------------------------------------------------------------------------
; Berechne Werte für die Menü-GEM-Darstellung
; in A = name_elemente, max 3 x 16 Felder

; Formeln:
; 	 name_elemente		equ	xxx
; 	 name_max_spalten	equ	(name_elemente/16+1)
; 	 name_max_zeilen	equ	((name_elemente+(name_max_spalten-1))/name_max_spalten)
; 	 name_breite		equ	12*name_max_spalten
; 	 name_first_x		equ	(40-name_breite) >> 1
; 	 name_hoehe		equ	name_max_zeilen+2
; 	 name_first_y		equ	(24-name_hoehe) >> 1
; 

max_elemente		equ 	0
max_spalten		equ 	1
max_zeilen 		equ 	2
max_breite		equ 	3
max_first_x		equ 	4
max_hoehe		equ 	5
max_first_y 		equ 	6
max_daten		equ 	7	; 2 Byte fktyp vom item, wird in dialog_template gefüllt
max_elemente_ges	equ	9
max_elemente_offs	equ	10

anz_max_elemente_in_dialog	equ	48

calc_flash_struct
		ld	ix, flash_struct
		
		ld	(ix+max_elemente_ges),a
		cp	a,anz_max_elemente_in_dialog
		jr	c,calc_flash_struct0
		ld	a,anz_max_elemente_in_dialog-1		; max. 47 Werte
calc_flash_struct0
		ld	(ix+max_elemente), a	; max_elemente
		ld	e,a			; merken
		srl	a
		srl	a
		srl	a
		srl	a			; a/16
		inc	a
		ld	d,a			; merken
		ld	(ix+max_spalten),a	
		add	a,e
		dec	a			; a=name_elemente+(name_max_spalten-1)
		ld	b,-1
calc_flash_struct1
		inc	b
		sub	a,d
		jr	nc,calc_flash_struct1
		ld	(ix+max_zeilen),b
		inc	b
		inc	b
		ld	(ix+max_hoehe), b	; name_max_zeilen+2
		ld	a,24
		sub	b
		srl	a
		ld	(ix+max_first_y), a	; (24-(name_max_zeilen+2)) >> 1
		;
		ld	a,d			; name_max_spalten
		add	a,a			; *2
		add	a,d			; *3
		add	a,a			; *6
		add	a,a			; *12
		ld	(ix+max_breite), a
		ld	c,a
		ld	a,40
		sub	c
		srl	a
		ld	(ix+max_first_x), a	; (40-name_max_breite) >> 1	
		;
		xor	a
		ld	(ix+max_elemente_offs), a	; offset
		ret

;------------------------------------------------------------------------------
; Dateien aufsammeln

; ab dir_array werden die anzuzeigenden Files aufgesammelt. Pro File sind 12 Byte
; reserviert. Das Suchen der Dateien ist nach menu_dir.asm ausgelagert.

;je File 12 Byte:
; 	3 Byte Header (Banknr, Adr im Modul), 8 Byte Name, 0
; 	also analog OS-Header 
; in: e = kategorie
; 
fill_dir_array:
	ld	a,e
	ld	(FAKategorie),a
	ld	iy, dir_array
	;
	ld	a,d
	cp	0ffh
	jr	z,fill_dir_array_os
	;
	call	MENU_FA			; --> menu_dir.asm
	jr	fill_dir_array1
fill_dir_array_os
	call	MENU_OS			; --> menu_dir.asm
fill_dir_array1
	ld	a,(DirCnt)
	ret

;
;------------------------------------------------------------------------------
;startproc: Starten: 
; - Procedure wird von allen Programmen aufgerufen
; - bekommt auf "de" die Adresse des Aufrufstring im Speicher
; -             "hl" die Adresse des gerufenen Programmes
; -             ab 100h+1 .... den Aufrufstring

FCB: 		EQU	005Ch 		;Dateikontrollblock

startproc:

; - Bei FA-Header Header nach FCB kopieren 
; - (currbank) = bank
; - HL = Adr. Prg.
; - Typ in IYu ablegen
; - JMPHL aufrufen (besser cmpl nutzen) 


;		include system-prg ...
;		ld	sp, (sp_save)	; sp restaurieren

		push	hl

		; Code umlagern nach 120h
		ld	hl,sp_up
		ld	de,sp_up_ziel
		ld	bc,sp_upe-sp_up
		ldir

		pop	hl
		ld	a,(hl)
		ld	(currbank),a		; (currbank) = bank

		call	sp_up			; FA-Rahmen nach FCB kopieren
		
		ld	ix,flash_struct
		ld	a,(ix+max_daten+1)
		cp	0ffh			; OS-Programm?
		ld	b,0c3h
		jr	z, startproc1
		;
		;;ld	a,(fcb+fa_typ)		; FA-Typ
		ld	a, 0FAh
		ld	b,a

startproc1	ld	iyu, b
		jp	cmpl			; und starten

;----------------------
; FA-Rahmen nach FCB kopieren
; folgender Code wird nach 120h (tmpcmd) kopiert
; er darf deshalb nicht zu lang werden (BDOS-Stack beachten)

sp_up
		phase	tmpcmd+20h
sp_up_ziel
		ld	a,(hl)			; bank
		out	bankport, a
		inc	hl
		ld	a,(hl)
		inc	hl
		ld	h,(hl)
		ld	l,a			;hl=Adr.FA-Rahmen im ROM
;
		ld	a,(ix+max_daten+1)
		cp	0ffh			; OS-Programm?
		ld	b,0c3h
		jr	z, sp_up1

		ld	de,FCB			;FA-Header in FCB kopieren
		ld	bc,20h
		ldir				;HL=Adr. Prg.
;
sp_up1		ld	a, systembank
		out	bankport, a
		RET				;Z=1 von CALL LOCK
		dephase
		
sp_upe
		
;------------------------------------------------------------------------------
; RAM-Bereiche

sp_save			ds	2

flash_struct		ds	11	; Speicher für Dialog-Parameter

; alles rund um die ....... M A U S 

mausspeicher    	ds	2	;( !!! 2 Bytes nötig)
last_active_item	ds	1	;( speichert aktuellen Ordner) 
mauscall	 	ds	2	;( Adresse der Mausroutine, die 
					;  beim nach dem Bewegen des Mauszeigers aufgerufen werden soll) 
maus_X		 	ds	1	; aktuelle MausPosition
maus_Y		 	ds	1	;   - - -  " - - - 
maus_Rand		ds	1

;window_start_x	 	ds	1
;window_start_y	 	ds	1

last_active_zeile	ds	1
last_active_spalte	ds	1
last_active_adresse  	ds	2	; 2 Byte

;f. fill_dir_array
DirCnt			DS	1	; Zähler für Gesamt-Anzahl der Einträge
FAKategorie		DS	1	; gesuchte Kategorie
dir_array		equ	$	; Buffer für gefundene Rahmen

        end
