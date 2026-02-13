;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M-Modul)
; (c) V. Pohlers 2011/2025 USB-Version
; letzte Änderung 2025 USB-Version
;------------------------------------------------------------------------------
; Loader für diverse CP/M-Versionen
; als Besonderheit wird nach dem Laden der MEGA-ROM weggeschaltet
;
; v2: Goodie für USB: Nach dem Laden wird das System im TPA bereitgestellt
; damit kann man mit Bordmitteln eine Boot-Disk erstellen!
; (geht allerdings nur mit CPA + ohne Autostart!)
; GO + SAVE 40 @CPMZ9.COM
;------------------------------------------------------------------------------
;vgl. bootmodl.asm

		cpu	z80undoc

rst_sbos	equ	28h		;der RST für den Sprungverteiler

;;	0	;OUTHX	Ausgabe (A) hexa
;;	1	;OUTHL	Ausgabe (HL) hexa
;;	2	;WAIT	Unterbrechung Lauf
;;	3	;color	Vordergrundfarbe (E)
;;	4	;CPROM	Suchen Namen
;;	5	;FMOV	FA-Programm in Speicher kopieren
;;	6	;FRUN	FA-Programm starten
;;	7	;KDOPAR	Kommandoparameter aufbereiten
;;	8	;INHEX	Konvertierung ASCII-Hex ab (DE) --> (HL)
;;	9	;PRST7	Ausgabe String bis Bit7=1


CR:     EQU     0DH  
LF:     EQU     0AH  
ROT:    EQU     0114H
GRUEN:  EQU     0214H
GELB:   EQU     0314H
BLAU:   EQU     0414H
MAGENTA:EQU     0514H
CYAN:   EQU     0614H
WHITE:  EQU     0714H


fcb		equ	5ch
conbu		equ	0080h

		org	300h
start0:		ld	de, startmsg
		ld	c,9
		call	5

start1:		ld	c,1		; consi
		call	5
		cp	03h		; STOP	-> Abbruch/Ende
		ret	z
		cp	'1'             ; Pgm. 1
		LD	HL,cpm1
		jr	z, start2
		cp	'2'             ; Pgm. 2
		LD	HL,cpm2
		jr	z, start2
		cp	'3'             ; Pgm. 3
		LD	HL,cpm3
		jr	z, start2
		cp	'4'             ; Pgm. 4
		LD	HL,cpm4
		jr	z, start2
		;
		jr	start1

start2:		ld	(auswahl),a
		ld	e,a		; auswahl anzeigen
		ld	c,2		; conso
		call	5
		
start3:		ld	de, loadmsg
		ld	c,9
		call	5
		
		; HL=Adr. Programmname
		; INTLN mit Programmnamen füllen (Länge, pgm-name, 0)
		ld	de,CONBU+2
		ld	bc,13		; 8.3 + 00
		ldir

		; PgmName anzeigen
		ld	de,CONBU+2
		ld	c,9
		call	5

		; Programm von Disk Laden
		LD	HL,dskbuf	; neue Zieladr.
		ld	a,'N'
		ld	(fcb+24),A	; kein OS-Programm, also Laden ohne Header
		ld	a,1		;  Dateiname "Name[.Typ]" muss in CONBU abgelegt sein
		ld	c,34		; CLOAD
		call	5
		xor	a	; ld	a,0
		ld	(fcb+24),A	; reset! falls Fehler!
		ret	c		; bei Fehler
		;
		
; ---------------------		
; Einschub: Dateigröße für SAVE aufbereiten und in ldmsg hinterlegen
		ld	hl,(fcb+25)	; LEADR
		ld	de,dskbuf
		sbc	hl,de		; HL=Programmlänge
		; durch 256 teilen (Page-Size, also einfach nur H nehmen)
		; ergebnis nach dezimal konvertieren
		xor	a		; ld	a,0
		or	l		; L<>0? Rest?
		jr	z, ld1
		ld	a,1		; dann eins dazuzählen 
ld1:		inc	a
		daa	
		dec	h
		jr	nz, ld1
		; in A steht jetzt dezimal die Anzahl der  Pages (100h-Blöcke) für SAVE
	 	; im ldmsg hinterlegen
	 	call	outad
; ---------------------		

		
		; Test auf korrektes @cpmz9
		; als 1. Byte muß 11h stehen, dann folgt die Ladeadresse
		; (also ursprünglich di und ld de, 8000h)
		ld	a, (dskbuf+1)
		cp	11h
		ld	a, '?'          ; Fehler "kein CPMZ9-System"
		jp	nz, error	; Fehlermeldung	anzeigen und zurück zum	OS
		ld	hl, (dskbuf+2)	; Parameter des Befehls LD DE, xxxx, also die Ladeadresse
		; merken Ladeadresse aus 1. Block
		ld	(loadadr), hl
		; Kopiere Rest nach Ladeadresse (4000 oder 8000)
		ex	de, hl		; de=loadadr
		ld	hl,dskbuf+80h
		ld	bc,4000h-dskbuf	; max 16K reichen ;-)
		ldir


;----------------------		
; Einschub: Bootdiskettenerstellung vorbreiten
; ein einfaches Kopieren nach 100h und dann SAVE 40 @CPMZ9.COM
; funktioniert leider nicht
; Grund: das Z9001-CPM nutzt beim Bootvorgang
; Speicher zw. 180h und 400h
; deshalb wird ein Mini-Umlade-Programm am Ende der ersten 16k abgelegt
; und auf 100h ein JP dorthin eingetragen
; mit GO wird dann dieses Umlade-Programm gestartet
; anschließend kann mit Bordmitteln das CPM gespeichert werden (SAVE 40 @CPMZ9.COM)


		; TPA-Starter ans RAM End der ersten 16K kopieren
		; dieser obere Speicher bleibt dann unverändert
		di			; ab jetzt Stack nicht mehr verändern!
		
		ld	hl,tplda
		ld	de,tpadr
		ld	bc,tplde-tplda
		ldir
		;
		;TPA-"Programm"		; -> GO
		ld	a,0c3h
		ld	(100h),a
		ld	hl,tpadr	; starten am RAM-Ende
		ld	(101h),hl
;----------------------		


		; Start auf Ladeadresse+1600h
ldcpm8:		ld	bc, 1600h	; Offset CCP+BDOS
		ld	hl, (loadadr)	; zu Ladeadr. addieren
		add	hl, bc
; bei orig. CPM wegschalten ROM
		ld	a,(auswahl)
		cp	'3'
		jr	nc, ldcpm9 	; >=3 
		
		ld	(0FC00h), a	; Schalt-ROM-Modul ausschalten
		; in	a, (7)		; R/W setzen im 64K-RAM-Modul
		out	(7), a		; R/W setzen im 64K-RAM-Modul

; Start CPM
ldcpm9:		ld	a, 0		; Boot-Laufwerk
		jp	(hl)		; und starten des BIOS


;-----------------------------------------------------------------------------
; Ausgabe A BCD->ASCII
; speichern in ldmsg

outad:		ld	hl,ldmsg1-tpadr+tplda	; orig. code.adr
		push	af
		rrca
		rrca
		rrca
		rrca
		call	outa1
		pop	af
outa1:		and	0Fh
		add	a, 30h 		; '0'
		ld	(hl),a
		inc	hl
		ret
	
;-----------------------------------------------------------------------------
; TPA-Starter 
; Starten mit GO
;-----------------------------------------------------------------------------

tpadr		equ	4000h-80h

tplda:
		phase	tpadr

		; Kopieren CPM-System nach 100h
		ld	hl,dskbuf
		ld	de,100h
		ld	bc,4000h-dskbuf	; max. Länge
		ldir
		ld	de,ldmsg
		ld	c,9
		call	5
		ret
ldmsg		db	"SAVE "
ldmsg1		db	"00 @CPMZ9.COM$"
		dephase
tplde:		
				
;-----------------------------------------------------------------------------
; Fehlermeldung	anzeigen und zurück zum	OS
;-----------------------------------------------------------------------------
error:		push	af
		ld	de, aBootError	; "Boot-Error: "
		ld	c, 9
		call	5		; PRNST	Ausgabe	Zeichenkette
		pop	af
		ld	c, 2
		ld	e, a
		call	5		; CONSO	Ausgabe	Zeichen	E
		;
		
;		in	a, (6)		; 64K-RAM-Modul Write Only
;		ld	(0F800h), a	; Schalt-ROM-Modul einschalten
		;
		jp	0		; Systemwarmstart

;------------------------------------------------------------------------------

startmsg
	        dw GELB
	        db CR, LF
	        db "CP/M-Loader USB", cr, lf
	        DB "---------------", CR, LF    
	        db CR, LF
	        dw gruen
	        db "1 - CP/M orig. robotron", CR, LF
	        db "2 - CP/M orig. ZFK Rossendorf", CR, LF
	        db "3 - CP/M 48K robotron Mega", CR, LF
	        db "4 - CP/M 48K robotron Kombi", CR, LF
	        db CR, LF
	        dw white
	        db "Auswahl: "
	        db 0

loadmsg:	dw gruen
		db CR, LF
		db CR, LF, "lade...",0


;-----------------------------------------------------------------------------

aBootError:	db	"Boot-Error: ", 0


cpm1		db	"CPM_R.CPM",0
cpm2		db	"CPM_ZFK.CPM",0
cpm3		db	"CPM-48K.CPM",0
cpm4		db	"CPM-48KU.CPM",0

;auswahl		ds	1
;loadadr		ds	2
auswahl		equ	7dh
loadadr		equ	7eh



dskbuf		equ	0800h

		end

; nach Start steht Kopie des CPMs im TPA
; speichern auf leere Diskette mit 
; SAVE 40 @CPMZ9.COM	(10240 Byte, bei rossendorf entsprechend mehr!) 

; save xx 100h-Blöcke	also 10240:40

