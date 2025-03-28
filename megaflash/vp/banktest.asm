;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M/3.5M-Modul)
; (c) KOMA Alexander Schön, 2005-2007
; v.pohlers 03.02.2010 manuelles Durchblättern des Speichers
;------------------------------------------------------------------------------
		CPU z80
 
BDOS		equ 	5
codeStart	equ 	01000h
OUTA:		EQU	0F305H

; Systemvariablen 

joyr		  	equ  	013h
joyl		  	equ  	014h 
screen 			equ 	0ec00h
colors			equ 	0e800h 
;Zeichencodes
;
CUL:    		EQU     08H
CLS_:   		EQU     0CH
CRLF:   		EQU     0A0DH
CR:     		EQU     0DH
LF:     		EQU     0AH
ROT:    		EQU     0114H
GRUEN:  		EQU     0214H
GELB:   		EQU     0314H
BLAU:   		EQU     0414H
MAGENTA:		EQU     0514H
CYAN:   		EQU     0614H
WHITE:  		EQU     0714H 

;		org codeStart-128
		
		include "../includes.asm"		
						
				
		; KCC Steuerblock 
;		db "BANKTEST"
;		db "COM"			; Dateierweiterung
;		db 0,0,0,0,0,3			; Schnickschnack
;		dw codeStart			; startadresse
;		dw codeEnde
;		dw start
		
		org codeStart
			
		jp start	
		db "BANKTEST",0	
				
start:
		; a) Ausgabe des Startmenu's ......

		ld 	c,9 
		ld 	de, MenuTxt
		call 	BDOS
		
abfrage:
		; Abfrage der Tastatur 
		ld	c, 1
		call 	BDOS

		cp 	a,'1'
		jp	z, durchlauf

		cp 	a,'2'
		jp	z, bankeingabe

		cp 	a,'3'
		jp	nz, abfrage_w1
		ld	a, 042h
		out 	bankport,a
		jp 	start

abfrage_w1:
		cp 	a,'4'
		jp	z, tastaturTest

		cp 	a,'5'
		jp	z, tastaturTest2


		cp	a,'9'
		jr	nz, abfrage
		
		xor 	a,a
		ld 	(024h),a
		ld	(025h),a

		ld 	c,9 
		ld 	de, tschuess
		call 	BDOS
		
		xor	a,a
		out	bankport,a
		
		or 	a,a			; sonst denkt der KC, es lag ein Fehler vor 
		
		ret

; -----------------------------------------------------------------------------

		; hl = Bildschirmadresse
		; A  = was soll ich darstellen ?????
print_bits:
		ld	b, 8
print_bits_loop:
		rlca				; rotiere durch a und h		
		;rrca				; rotiere durch a und h		
		jr	c, print_bit_1
		ld	(hl), '0'
		jr	print_bits_weiter
print_bit_1:
		ld	(hl), '1'
print_bits_weiter:
		inc	hl
	
		dec	b
		jr	nz, print_bits_loop
		 
		ret 
	
; -----------------------------------------------------------------------

Tastaturtest2:		

		; Ausgabe des Textes ...

		ld 	c,9
		ld	de, tastaturmatrix
		call	bdos

Tastaturtest_loop2:
		call 	0fe8fh			; GPioD
		EI				; interrupts wieder einschalten ....
		; D		= negierte Zeile
		; E 		= negierte Spalte
		; H 		= Control
		; L		= Shift
	
		push 	de

		ld 	hl, 0e800h+4*40+5	; Farbspeicher
		ld	(hl),10
		
		ld	c, 8
tastaturtest_innerloop_y:
		push 	bc

		ld	c, 8

		ld	a, d
tastaturtest_innerloop_x:

                rrca    ; rotiere durch a und h
		ld	b,a			; save
		ld	a, 16+32+64		; später ... nicht zeichnen ...
		jr	nc, paint_bit_1

		bit	0, e
		jr	z, paint_bit_1
		ld	a, 1+2+4		; später zeichnen
paint_bit_1:
		ld	(hl),a
		inc	hl
		ld	(hl),a
		inc 	hl
		ld	(hl),a
		inc 	hl
		
		inc	hl
		
		ld	a,b

		dec	c
		jr	nz, tastaturTest_innerLoop_x
					
		ld	bc, 40+8
		add	hl, bc

		rr	e			; Zeile nach links 

		pop	bc

		dec	c
		jr	nz, tastaturTest_innerLoop_y

		pop	de

		; stoptaste gedrueckt ????
		bit 	6,e
		jr	z, Tastaturtest_loop2

		bit 	6,d
		jr	z, Tastaturtest_loop2	

		call	0fae9h

		jp 	start

; -----------------------------------------------------------------------

Tastaturtest:		

		; Ausgabe des Textes ...

		ld 	c,9
		ld	de, tastaturtestText
		call	bdos

Tastaturtest_loop:
		call 	0fe8fh			; GPioD
		EI				; interrupts wieder einschalten ....
		; D		= negierte Zeile
		; E 		= negierte Spalte
		; H 		= Control
		; L		= Shift

		ld	a, h
		exx
		ld	hl, 0ec00h+6*40+3
		call 	print_bits
		exx

		ld	a, l
		exx
		ld	hl, 0ec00h+8*40+3
		call 	print_bits
		exx

		ld	a, d
		exx
		ld	hl, 0ec00h+10*40+3
		call 	print_bits
		exx

		ld	a, e
		exx
		ld	hl, 0ec00h+12*40+3
		call 	print_bits
		exx

		ld	a, (joyl)
		exx
		ld	hl, 0ec00h+14*40+3
		call 	print_bits
		exx

		ld	a, (joyr)
		exx
		ld	hl, 0ec00h+16*40+3
		call 	print_bits
		exx
	
		; stoptaste gedrueckt ????
		bit 	6,e
		jr	z, Tastaturtest_loop

		bit 	6,d
		jr	z, Tastaturtest_loop

		call	0fae9h

		jp 	start

; ----------------------------------------------------------------------------------

durchlauf:
		ld 	c,9
		ld		de, durchlauftext
		call	bdos
		

		; Bildschirm vorbereiten
		; a) die farben für die Trackanzeige auf dem Bildschirm 
		ld	hl, colors+3*40+29
		ld	(hl), 16+32+64		; weiße Anzeige ......
		inc	hl
		ld	(hl), 16+32+64

		ld	c, 12			; 12 Zeilen ......
		ld	hl, colors+8*40+0

prepScreen:
		push	bc
		; b) die Zeilen, an der später die Hexadezimale Anzeige hin soll
		ld	(hl), 32		; erst mal zum testen ......
		ld	d, h
		ld	e,	l
		inc 	de			; eine Stelle weiter
		ld	bc, 30			; wieviel einfärben ?????
		ldir	

		ld	(hl), 16+32+64		; erst mal zum testen ......
		ld	bc, 10			; wieviel einfärben ?????
		ldir	

		pop 	bc
		dec	c
		jr	nz, prepScreen
		
		ld 	a,0			; Zaehler
schleife_Durchlauf: 
		push 	af
		
		; hier soll später die Trackanzeige hin ......
		ld	hl, screen+3*40+29
		
		; Anzeigen Hexadezimal
		call  OUTHX
		
		; Anzeige der ersten Zeilen Hexadezimales Zeuch .....
		ld	hl, screen+8*40		; wo soll's angezeigt werden ?????
		ld	de, 0c000h		; wo kommt's her ???

		ld	c,12			; 12 Zeilen
print_hex_and_ascii_values:
		push	bc

		ld	a, d
		call	outhx	
		ld	a, e
		call	outhx
		inc	hl	
		ld	c, 8			; 16 Speicheradressen ausgeben ....		
		
		push	de			; erste Speicherstelle merken, um sie später als
												; Ascii ausgeben zu kÃ¶nnen 		
print_hexas:
		ld	a, (de)
		call	outhx
		inc	hl
		inc	de
		
		dec	c
		jr	nz, print_hexas
	
		ld	c,8
		inc	hl
		inc	hl
		pop	de			; Speicherstelle ......

print_ascii:
		ld	a, (de)
		cp	a, 32
		jr	nc, print_ascii_w1
		ld	a,'.'
print_ascii_w1:
		ld	(hl),a
		inc	hl
		inc	de
		dec 	c
		jr	nz,print_ascii			

		pop	bc
		inc	hl
		dec	c
		jr	nz,print_hex_and_ascii_values
		
		ld	a,(000feh)
		cp	8
		jr	z, manuell1
				
		; Abfrage, ob eine Taste gedrueckt wurde ....
		ld	c, 11
		call	bdos

; neu vp: bei Cursor links/rechts manuelle Umschaltung
		cp	8
		jr	z, manuell1
		cp	9
		jr	z, manuell1

		or 	a,a
		jr	nz,durchlauf_ende

		ld	d,15
		call 	wait		
		
		pop	af
		inc	a
		jr	manuellx

manuell1	ld	a,8
		ld	(000feh), a

		ld	c,1
		call	bdos
		cp	8
		jr	nz, manuell2
		
		pop	af
		dec	a
		jr	manuellx
		
manuell2	cp	9
		jr	nz, manuell3
					
		pop	af
		inc	a
		jr	manuellx

manuell3	ld	a, 0
		ld	(000feh), a
		pop	af
		inc	a

manuellx	out	bankport,a
		cp	a,0
		jp	nz, schleife_Durchlauf
		jp	schleife_durchlauf-2
durchlauf_ende:	
		pop	af			; da liegt noch etwas auf dem Stack ....
						; hol es ....
										
		ld	a,0
		ld	(024h),a
		ld	(025h),a		
		jp 	start

; ----------------------------------------------------------------------------------
		
bankeingabe:
		ld	c,9
		ld 	de,bankeingabeText
		call	bdos
		
		ld	de, eingabebuffer

		; Eingabebuffer erst einmal loeschen .......
		ld	IX, eingabebuffer
		ld	a,0
		ld 	(IX+2),a
		ld 	(IX+3),a
		ld 	(IX+4),a
		
		ld	c,10
		ld	a,2			; Anzahl der Zeichen 
		ld	(de),a			; Anzahl der Zeichen eintragen
		call	bdos
		jp	c, start		; Stop 
		
		inc	de			; wieviele zeichen gab's????
		ld 	a,(de)
		or	a,a			; leer?
		jp	z, start

		ld	c,0			; hier wird's gespeichert 

ascII2Int:
		inc 	de			; die Daten .......
		ld	a,(de)

		or	a,a			; bei 0 ist Schluß
		jr	z, bankeingabe_ende		

		rlc	c			;*2
		rlc	c			;*4
		rlc	c			;*8
		rlc	c			;*16

		cp	a,'0'
		jp	c,start			; war kleiner als 0,l also raus hier ...
		cp	a,'9'+1
		jr	nc,bankeingabe_buchstabe
		
		sub	a,'0'
		add	a,c
		ld	c,a
		jr	ascII2Int		

bankeingabe_buchstabe:
		cp	a,'A'
		jp	c,start			; wieder unter einem a
		cp	a,'F'+1		
		jp	nc,start

		sub	a,'A'-10
		add	a,c
		ld	c,a
		jr	ascII2Int		

bankeingabe_ende:
		ld	a,c
		out	bankport, a
			
		
		jp 	start

; ----------------------------------------------------------------------------------
;OUTHX Ausgabe (A) hexa
; ----------------------------------------------------------------------------------

OUTHX:	
		PUSH	AF
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	OUTH1
		POP	AF
OUTH1:
		AND	A, 0FH
		ADD	A, 30H
		CP	A, 3AH
		JR	C, OUTH2
		ADD	A, 07H
OUTH2:	
		;CALL	OUTA
		ld    (HL),A
		inc	hl
		RET
		
; ----------------------------------------------------------------------------------
; W A I T
; ----------------------------------------------------------------------------------
; .... ganz normal bis eine bestimmte Zeitspanne angelaufen ist

wait:		
		push af
		push de
		ld   e, 0h

wait_loop
		dec de
		ld  a, d	; Flags werden blöderweise bei 16Bit Registern nicht beeinflußt .....
		or  a, a
		jr  nz, wait_loop

		pop  de
		pop  af

		ret
		

			;   0123456789012345678901234567890123456789
MenuTxt:	db cls_
		db 0ah,0dh
		dw magenta
		db 0ah,0dh
		db "        KOMA Bank&Tastatur Test's",0ah,0dh
		db "        -------------------------",0ah,0dh
		db 0ah, 0dh
		db 0ah,0dh
		dw gelb
		db "("
		dw white
		db "1"
		dw gelb
		db ") ..... Durchlauf aller Baenke", 0ah,0dh
		db 0ah,0dh
		db "("
		dw white
		db "2"
		dw gelb
		db ") ..... springe auf Bank"
		dw white
		db " (!!! hex.)", 0ah,0dh
		dw gelb
		db 0ah, 0dh
		db "("
		dw white
		db "3"
		dw gelb
		db ") ..... Der Sinn des Lebens war?"
		dw white
		db "(dez.)"
		db 0ah, 0dh
		dw gelb
		db "("
		dw white
		db "4"
		dw gelb 
		db ") ..... Tastaturprobleme",0ah,0dh
		db 0ah, 0dh		
		db "("
		dw white
		db "5"
		dw gelb 
		db ") ..... Tastaturprobleme die 2te",0ah,0dh
		db 0ah, 0dh		
		db "("
		dw white
		db "9"
		dw gelb 
		db ") ..... verlasse Programm",0ah,0dh
		db 0ah, 0dh
		db 0ah, 0dh
		dw gruen
		db "                was soll ich machen ?", 0ah,0dh
		db 0		

tschuess:
		db cls_
		db 0ah,0dh
		dw gruen
		db "tschuess, bis zum naechsten mal ....."
		db 0ah,0dh
		db 0ah,0dh
		db 0

		;  0123456789012345678901234567890123456789		
durchlauftext:
		db cls_
		dw gelb
		db 0ah,0dh
		db 0ah,0dh
		db 0ah,0dh
		db "Schalte auf Bank ........"
		db 0ah,0dh			
		db 0ah,0dh			
		db "       Abbruch mit beliebiger Taste !!!"
		dw white
		db 0
			
bankeingabeText:
		db 0ah,0dh
		db 0ah,0dh
		db 0ah,0dh
		db "Welche Bank soll's denn sein ??? - "
		dw white
		db 0

		;  0123456789012345678901234567890123456789		
tastaturtestText:
		db cls_
		db 0ah,0dh
		db 0ah,0dh
		db 0ah,0dh
		dw gelb
		db "  gib was Du hast ...."
		db 0ah,0dh			
		db 0ah,0dh			
		db 0ah,0dh			
		dw gruen
		db "H: "
		dw white
		db "11111111"
		dw gruen
		db " (Control negiert Bit 2)"
		db 0ah,0dh			
		db 0ah,0dh			
		db "L: "
		dw white
		db "11111111"
		dw gruen
		db " (Shift   negiert Bit 0)"
		db 0ah,0dh			
		db 0ah,0dh			
		db "D: "
		dw white
		db "11111111"
		dw gruen
		db " (negierte Matrixzeile)"
		db 0ah,0dh			
		db 0ah,0dh			
		db "E: "
		dw white
		db "11111111"
		dw gruen
		db " (negierte Matrixspalte)"
		db 0ah,0dh			
		db 0ah,0dh			
		db "JL "
		dw white
		db "11111111"
		dw gruen
		db " (Joystick Port L)"
		db 0ah,0dh			
		db 0ah,0dh			
		db "JR "
		dw white
		db "11111111"
		dw gruen
		db " (Joystick Port R)"
		db 0ah,0dh			
		db 0ah,0dh			
		db 0ah,0dh			
		dw gelb
		db "             Abbruch mit <STOP>"
		db 0

		;  0123456789012345678901234567890123456789		
tastaturmatrix:
		db cls_
		db 0ah,0dh		
		dw gruen
		db "	hau in die Tasten !!!! ...." 
		db 0ah,0dh		
		db 0ah,0dh		
		dw gelb	
		db "    ",168,160,160,160,164,160,160,160,164,160,160,160,164,160,160,160,164
		db          160,160,160,164,160,160,160,164,160,160,160,164,160,160,160,169, 0ah,0dh
		db "    ",161," 0 ",161," 8 ",161," @ ",161," H ",161," P ",161," X ",161,"LEF",161,"Sft",161,0ah,0dh
		db "    ",163,160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,166
		db 	160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,165,0ah,0dh
		db "    ",161," 1 ",161," 9 ",161," A ",161," I ",161," Q ",161," Y ",161,"RIG",161,"Col",161,0ah,0dh
		db "    ",163,160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,166
		db 	160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,165,0ah,0dh
		db "    ",161," 2 ",161," : ",161," B ",161," J ",161," R ",161," Z ",161,"DOW",161,"Ctr",161,0ah,0dh
		db "    ",163,160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,166
		db 	160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,165,0ah,0dh
		db "    ",161," 3 ",161," ; ",161," C ",161," K ",161," S ",161," :<",161," UP",161,"Gra",161,0ah,0dh
		db "    ",163,160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,166
		db 	160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,165,0ah,0dh
		db "    ",161," 4 ",161," / ",161," D ",161," L ",161," T ",161,"PAU",161,"ESC",161,"Lis",161,0ah,0dh
		db "    ",163,160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,166
		db 	160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,165,0ah,0dh
		db "    ",161," 5 ",161," = ",161," E ",161," M ",161," U ",161,"Ins",161,"Ent",161,"Run",161,0ah,0dh
		db "    ",163,160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,166
		db 	160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,165,0ah,0dh
		db "    ",161," 6 ",161," * ",161," F ",161," N ",161," V ",161," ^ ",161,"Sto",161,"Slo",161,0ah,0dh
		db "    ",163,160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,166
		db 	160,160,160,166,160,160,160,166,160,160,160,166,160,160,160,165,0ah,0dh
		db "    ",161," 7 ",161," ? ",161," G ",161," O ",161," W ",161,"   ",161,"Spa",161,"   ",161,0ah,0dh
		db "    ",167,160,160,160,162,160,160,160,162,160,160,160,162,160,160,160,162
		db          160,160,160,162,160,160,160,162,160,160,160,162,160,160,160,170, 0ah,0dh
		db 0ah,0dh		
		db 0ah,0dh		
		dw gruen
		db "              Abbruch mit >stop<"

 						
eingabebuffer: 
		db 1
		db 1
		db 0,0,0
			
codeEnde	equ $

		end
		