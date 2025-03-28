; Testprogramm für GVAL-Funktion (Parameterübergabe an Programme)
; Aufruf T ..beliebige Parameter..
; Angezeigt wird der Eingabepuffer CONBU
; der erkannte Parameter mit Typ und Wert (INTLN)
; der Zustand des Eingabepuffers CONBU nach Erkennen des Parameters

; Beispiel: 
; >T   45  ABC (mit nachfolgenden Leerzeichen)
; CONBU >    45  ABC  <
; Zahl 2D Laenge=2 "45"			erster Paramter A=2Dh=45
; CONBU >        ABC  <			Parameter wird in CONBU gelöscht
; Text Laenge=3 "ABC"			zweiter Parameter Text "ABC"
; CONBU >             <			Parameter wird in CONBU gelöscht
; Text Laenge=0				da Leerzeichen folgen, könnte ein 3. Parameter sein
; CONBU >             <
; -- kein weiterer Parameter --    	ist aber nicht der Fall (Ende mit Länge 0)
;					ohne Leerzeichen am Ende wäre nach 2. Parameter Schluss mit Cy'=1


		cpu	z80

CONBU:		EQU	80H		;CCP ZEICHENKETTENPUFFER
INTLN:		equ	0100h		; interner Zeichenkettenpuffer
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H
GVAL		equ	0F1EAh
	
		org	300h
		
;-------------------------------------------------------------------------------
; Kommando-Rahmen
;-------------------------------------------------------------------------------

		jp	para		
;		db	"TESTPARA", 0
		db	"T       ", 0
		db	0

;-------------------------------------------------------------------------------
; TESTPARA
;-------------------------------------------------------------------------------

para:		ex	af, af'			; '
		jr	c, ende			; keine weiteren Parameter
		
next_param:	
		call	anz_conbu		; Anzeige CONBU

;nächsten Parameter holen		
		call	gval

; GVAL
; Funktion: Löschen internen Puffer (INTLN).
; 	    Übernahme Parameter aus CONBU nach INTLN
; 	    Test auf Parameterart
; 	    Konvertieren Parameter, wenn dieser ein Wert ist
; Return
; 	Parameter: Z  1 Parameter war Dezimalzahl
; 		      0 Parameter war keine Zahl
; 		   CY  0 kein Fehler
; 		       1 Fehler im Parameter
; 		   A  Konvertierte max. 2stellige Dezimalzahl, wenn Z = 1 und CY = 0 
; 		   C  den Parameter begrenzendes Trennzeichen
; 		   B  Länge des Parameters
; 		   HL  Adresse des nächsten Zeichens in CONBU
; 		   CY’ 0 weitere Parameter in CONBU (ist in Doku falsch!)
; 		       1 keine weiteren Parameter (ist in Doku falsch!)
; 		   A’ den Parameter begrenzendes Trennzeichen
; 		   INTLN  Länge des Parameters
; 		   INTLN+1. . . übernommener Parameter
; 		   CONBU übernommener Parameter und Trennzeichen gelöscht mit
; 			 Leerzeichen

		jr	z,zahl_parameter	; Z=1 -> Parameter ist Dezimalzahl
		
		;  Parameter ist keine Zahl
		call	prnst
		db	"Text ", 0
		jr	para1
		
		; Parameter ist Dezimalzahl
zahl_parameter:		
		push	af			; Cy-Flag merken
		call	prnst
		db	"Zahl ", 0
		pop	af

		jr	nc, para0		; Fehler in Zahl?
		; Cy=1 Fehler im Parameter
		call	prnst
		db	"mit Fehler! ",0
		
para0		call	outhx			; Anzeige Wert A		
		call	OSPAC

		; Parameter anzeigen
		; Parameter liegt auf INTLN+1, Länge in INTLN
para1:		call	prnst
		db	"Laenge=", 0
		ld	a, (INTLN)		; Länges des Parameters
		add	a,'0'
		call	OUTA
		call	OSPAC

		ld	a, (INTLN)
		or	A
		jr	z,para2			; bei Länge 0 nicht anzeigen

		; parameter 
		ld	a,'"'
		call	outa 

		ld	de, INTLN+1
		ld	c,9
		call	5			; Anzeige Text	

		ld	a,'"'
		call	outa 
	
para2		call	OCRLF
		ex	af, af'			;'
		; CY’ = 1 keine weiteren Parameter 
		jr	c, ende			; wenn kein Parameter folgt
		jr	next_param		; sonst nächsten Parameter anzeigen
;
;
ende:		call	anz_conbu
		call	prnst
		db	"-- kein weiterer Parameter --"
		db	0dh,0ah,0
;		
		or	a
		ret
;

;------------------------------------------------------------------------------
;UP, Ausgabe nachfolgenden String bis 0-Byte
;-------------------------------------------------------------------------------
;
prnst:		EX	(SP),HL			;Adresse hinter CALL
PRS1:		LD	A,(HL)
		INC	HL
		or	A			;Ende (A=0=?
		JR	Z, PRS2			;ja
		CALL	OUTA
		JR	PRS1			;nein
PRS2:		EX	(SP),HL			;neue Returnadresse
		RET


;-------------------------------------------------------------------------------
; Anzeige CONBU
; Zeigt Consolebuffer als >...< 
; Consolebuffer hat abschließendes 00-Byte
;-------------------------------------------------------------------------------
anz_conbu:	call	prnst
		db	"CONBU >", 0
		
		ld	de, CONBU+2
anz		ld	c,9
		call	5
		ld	a, '<'
		call	outa
		call	OCRLF
		ret

;------------------------------------------------------------------------------

;OUTHL Ausgabe (HL) hexa
;
OUTHL:		LD	A,H
		CALL	OUTHX
		LD	A,L
;
;OUTHX Ausgabe (A) hexa
;
OUTHX:		PUSH	AF
		RLCA
		RLCA
		RLCA
		RLCA
		CALL	OUTH1
		POP	AF
OUTH1:		AND	A, 0FH
		ADD	A, 30H
		CP	A, 3AH
		JR	C, OUTH2
		ADD	A, 07H
OUTH2:		CALL	OUTA
		RET

;------------------------------------------------------------------------------

		end
