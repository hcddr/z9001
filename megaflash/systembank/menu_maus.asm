;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M/3.5M-Modul)
; (c) KOMA Alexander Schön, 2005-2007
;------------------------------------------------------------------------------

;vp: einbau randerkennung  via maus_rand


;maus_speed		equ  	05h	; minimale und
maus_speed		equ  	08h	; minimale und
maus_speed_slow		equ  	22h	; maximale Mausgeschwindigkeit


; ***************************************************************************************
; M A U S ...
; hier landen die kompletten Mausroutinen ......
; ***************************************************************************************

; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
; BITTE SO LASSEN, ES GEHT
; !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!


; ---------------------------------------------------------------------------------------
; M A U S A B F R A G E

; - testet einfach nur, ob die Pfeilstasten bzw. ESC, ENTER oder Space gedrueckt wurde und
;   gibt das Ergebnis in A zurück

; Return: A .... Auswertung in Bit's

; bit 	..... 	Taste
; 0		links
; 1 		rechts
; 2 		hoch
; 3		runter
; 4		ESC, Button
; 5		Enter, Space

; ---------------------------------------------------------------------------------------

maus_abfrage:

maus_loop_inner:
		; !!! af wird von Call gepusht und gepopt
		call 	0fe8fh			; GPIOD .... Tastaturpio direkt lesen
;vp: GPIOD entspricht i.W. der Abfrage des Spielhebels GSTIK
		ei
		; !!!! e enthaelt nicht nur die Info, ob Space oder Enter gerueckt wurde,
		; sondern auch gleich die Pfeilrichtung .... Zufall

		; D,E 	Natrixzeile und Spalte .... negiert ....
		; H = Controlltaste gedrueckt ????
		; L = Shifttaste gedrueckt

		; es folgen die verschiedenen Tastenauswertungen

		xor 	a,a			; a loeschen, damit externes Programm erkennt, das
		   				; nix passiert ist
		ld	(maus_Rand), a
maus_loop_inner_w0:

		; . . . . . . . . . . . . . . . . . . . . . .
		; Teste, ob ueberhaupt etwas passiert ist ......
		ld   	a,e
		or 	a,a 			; falls nicht's passiert zurueck
		ret 	z

		bit	6, d			; es geht mir nur um diese Zeile
		ret	z

		; . . . . . . . . . . . . . . . . . . . . . . . . . . . .
		; Test auf "Shift"
		; l ist noch von der Piotestroutine gesetzt oder geloescht
		ld   	d, maus_speed
		bit  	7,l
		jr   	nz, maus_loop_weiter

		; Shift wurde gedrueckt ......
		ld   	d, maus_speed_slow

		; eventuell noch bit 1 in e loeschen
		; !!! nur wenn l Bit 6 !=1
		; falls Bit gesetzt ist = 0, sonst 1
		; ist bit 1 gesetzt ... kein "<-" & Shift ---> bit7 loeschen
		bit	6,l
		jr   	z, maus_loop_weiter

		res 	0,e			; bitte loeschen ......

maus_loop_weiter:

		call 	wait

		; . . . . . . . . . . . . . . . . . . . . . . . . . . . . .
		;
		ld  	bc, (maus_x)		; aktuelle Mausposition holen, um x oder y zu vergroessern oder verkleinern

		; ab hier gehen die verschiedenen Test's los, oben , unten usw.......

check_left	; ---- test, ob es nach links geht ---
		bit 	0,e			; !!! z = 1, wenn Bit = 0
		jr  	z, check_right

		ld  	a, (p1rol)
		cp  	b
		jr  	nc,check_left1

		dec 	b			; b erniedrigen
		jr	check_right
check_left1:
		ld	a,e
		ld	(maus_Rand), a
		
		; . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

check_right:	; ---- test, ob es nach rechts geht ---
		bit 	1,e
		jr  	z, check_down

		ld  	a,(p2rol)
		cp 	b			; 38-b????
		jr  	c, check_right1

		inc  	b			; b um eins erhoehen
		jr	check_down
		
check_right1:
		ld	a,e
		ld	(maus_Rand), a

		; . . . . . . . . . . . . . . . . . . . . . . . . . . . . .

check_down:	; ---- test, ob es nach unten geht ---

		bit 	2,e			; !!! z = 1, wenn Bit = 0
		jr  	z, check_up

		ld  	a,(p4rol)
		cp  	c			; 38-b????
		jr  	c, check_up

		inc  	c			; b um eins erhoehen

check_up:	; ---- test, ob es nach oben geht ---

		bit 	3,e
		jr  	z, check_action

		ld  	a, (p3rol)
		cp  	c
		jr  	nc,check_action

		dec 	c

check_action:
		; tu was für die optik .... ist der Zeiger an irgend einem Rand ... nicht neu zeichnen .....

		push	hl			; Speichern für die Nachwelt ...... (shift und Control)
		push	de			; vor allem e und die unterprogramme brauchen es nicht zu tun

		or  	a,a			; Carry löschen
		ld  	hl, (maus_x)		; alte Mauspostion
		sbc 	hl, bc			; aktuelle subtrahieren

		jr    z, maus_abfrage_ende	; = 0 ?????

		call 	maus_aus

		ld  	(maus_x),bc		; neuen Wert zurueck schreiben


		; - - - - - - - - - - - - - - - - - - - - - - -
		; hier die individuellen Mausroutinen aufrufen

		call 	maus_prog_start		; !!! in BC steht schon die aktuelle Mausposition und braucht vom gerufenen Programm nicht nocheinmal
						; ermittelt werden
		call 	maus_an

maus_abfrage_ende:
		pop  	de
		pop  	hl
		ld   	a,e

		ret

; ----------------------------------------------------------------------------------
; M A U S      A U S
; ----------------------------------------------------------------------------------

maus_aus:
		push 	hl
		push 	de
		push 	bc
		push 	af

		ld  	bc, (maus_x)
		call 	calc_screen_pos

		; hl = Bildschirmadresse

		ld 	a,(mausspeicher)
		ld 	(hl),a
		ld 	bc,40
		add 	hl,bc
		ld 	a,(mausspeicher+1)
		ld 	(hl),a

		pop 	af
		pop 	bc
		pop 	de
		pop 	hl

		ret

; ----------------------------------------------------------------------------------
; M A U S      A N
; ----------------------------------------------------------------------------------

maus_an:
		push 	hl
		push 	de
		push 	bc

		ld   	bc, (maus_x)

		; berechne aus BC die aktuelle Bildschirmposition
		call 	calc_screen_pos		; Rueckgabe in HL

		; Mausuntergrund Feld 1 speichern
		ld   	a, (hl)
		ld   	(mausspeicher),a

		; Mauscursor Feld 1 Zeichenen
		ld   	de, mauscursor
		ld   	a,(de)
		ld   	(hl),a

		; neue Adresse brechnen .... einfach 40 Zeichen weiter
		inc  	de			; mauscursoradresse um eins erhoehen
		ld   	bc,40
		add  	hl,bc			; 40 Zeichen auf dem Bildschirm dazu addieren

		; wieder Untergrund speichern
		ld  	a,(hl)
		ld 	(mausspeicher+1),a

		; Mauszeiger setzen
		ld   a,(de)
		ld  (hl),a

		pop  bc
		pop  de
		pop  hl

		ret

; ----------------------------------------------------------------------------------
; Maus C U R S O R auf position x y setzen .....

; b = x Position
; c = y Position
; ----------------------------------------------------------------------------------

maus_goto:	; !!! keine Push's und Pop's .... machen Maus_aus & Maus_an
		call 	maus_aus
		ld   	(maus_x),bc
		call 	maus_an

		ret

; ----------------------------------------------------------------------------------
; M A U S get_position
; ----------------------------------------------------------------------------------

maus_get_position:
		ld  	bc, (maus_x)
		ret

; ----------------------------------------------------------------------------------
; M A U S    w a i t
; ----------------------------------------------------------------------------------

maus_wait:
		call 	maus_abfrage
		bit  	4,a
		jr   	nz, maus_wait
		ret

; ----------------------------------------------------------------------------------
; M A U S prog-start
; ----------------------------------------------------------------------------------

maus_prog_start:

                ld hl, (mauscall)	; z=1 -> am Rand
                jp (hl)

maus_prog_no_code:
                ret

