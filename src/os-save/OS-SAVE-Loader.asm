; File Name   :	C:\user\hobby\rechner\Z9001\dev\os-save\OS-SAVE-Loader.KCC
; Format      :	Binary file
; Base Address:	0000h Range: 0080h - 0100h Loaded length: 0080h


		cpu	Z80

;------------------------------------------------------------------------------
; OS-SAVE 
; ein Block (FF); dieser wird nach 80h geladen
; Dieser Code lädt das Hauptprogramm blockweise
; führt eine Adresskorrektur aus und verschiebt den geladenen Block ans RAM-Ende
;------------------------------------------------------------------------------

		org 	80h

; Block 00 lesen; dieser enthält am Anfang 4 relevante Datenworte
; das Hauptprogramm wird vermutlich mit einem speziellen Programm 
; assembliert bzw. weiterverarbeitet. Es muß ein 00-Block mit vier Adressen 
; generiert werden, das eigentliche zu verschiebende Programm muß aller 70h 
; Byte mit 10h Byte Relocation-Informationen versehen werden.


loader:		xor	a		; A = 0
		ld	(6Ch), a	; LBLNR 0
		ld	hl, 100h	; Adresse 100h
		ld	(1Bh), hl	; DMA
		call	0F434h		; READ,	BLOCK 00 LESEN SEQUENTIELL
		ret	c
;
		ld	hl, (102h)	; Endeadresse (incl.)	= 1340h
		ld	de, (104h)	; 			= 0FC0h
		sbc	hl, de					; HL = 380h
		ex	de, hl					; DE = 380h
		ld	hl, (36h)	; EOR			; z.B. 3FFFh
		sbc	hl, de					; HL = 3C7F
		ld	l, 0					; HL = 3C00
		ld	de, (106h)	; 			= 0077h
		sbc	hl, de					; HL = 3B89
		ld	(75h), hl	; Zieladresse = Programmstart
		ld	(77h), hl	; Zieladresse f. Blöcke
		ld	de, (100h)	; Anfangsadresse	= 0F89h
		sbc	hl, de		; HL = Adressoffset 	; HL = 2C00
		ld	(40h), hl	; PARBU, Hilfszelle zur Parameterpufferung

;------------------------------------------------------------------------------
; Blöcke lesen
;
; die Blöcke 01..FF enthalten das Programm.
; Die letzten 16 Byte eines jeden Blocks enthalten die Adress-Korrektur-Angaben.

; Beispiel
; Block 01                                                                
; 0180: 21 FF*0F 22 36 00 21 23  00 22 82 00 CD EA F1 CD  
; 0190: 8E F2 20 2F 21 03*10 B7  ED 52 28 27 D5 1B 1B 1B  
; 01A0: E1 D5 36 20 11 09 00 19  11 18*10 7E B7 28 07 01  
; 01B0: 0C 00 ED B0 18 F5 12 D1  ED 52 E5 C1 D5 E1 13 36  
; 01C0: 00 ED B0 11 E4*0F CD 19* 13 2A 36 00 23 7C CD F6* 
; 01D0: 12 7D CD F6*12 11 FA*0F  C3 19*13 0A 0D 14 01 45  
; 01E0: 58 54 45 4E 44 45 44 20  4F 53 20 41 54 20 14 04  
; 01F0: 02 00 20 00 00 02 00 00  90 80 48 02 00 00 00 00 
;                                      |  |
;                                      |  -- Adr. 1D9 
;                                      ----- Adr. 1D6, 1D3
; usw.
;------------------------------------------------------------------------------

loader1:	ld	hl, 100h
		ld	(1Bh), hl	; DMA
		call	0F434h		; READ,	BLOCK LESEN SEQUENTIELL
		ret	c		; bei Lesefehler
		push	af		; A=1 bei EOF merken
		ld	b, 0Eh		; 15 x 8 Byte
		exx
		ld	hl, 100h	; Anfangsadresse Daten
		ld	de, 170h	; Anfangsadresse Korrektur
		exx
loader2:	exx
		ld	b, 8		; für je 8 Byte
		ld	a, (de)		; Korrekturbyte lesen
loader3:	rrca
		jr	nc, loader4
; Adress-Korrektur
		push	de
		ld	e, (hl)		; Lo-Byte lesen
		inc	hl
		push	hl
		ld	h, (hl)		; Hi-Byte lesen
		ld	l, e
		ld	de, (40h)	; Adressoffset
		add	hl, de		; addieren
		ex	de, hl
		pop	hl
		ld	(hl), d		; korrigierte Adresse
		dec	hl
		ld	(hl), e		; zurückschreiben
		pop	de
loader4:	inc	hl
		djnz	loader3		; für alle 8 Byte
;
		inc	de
		exx
		djnz	loader2		; für alle 8-Byte-Blöcke
; korrigierten Block an Zieladresse schreiben
		ld	hl, 100h
		ld	de, (77h)	; Zieladresse
		ld	bc, 70h		; 15x8 Byte verschieben
		ldir
		ld	(77h), de	; Zieladresse erhöhen
;
		pop	af		; letzter Block
		or	a
		jr	z, loader1	; nein -> weiterlesen
; Starten
		ld	hl, (75h)
		jp	(hl)

		end


;------------------------------------------------------------------------------

; Block 00 von OS-SAVE
; der Block 00 des Hauptprogramms wird nach 100h geladen

		org 100h

		dw 0F89h		; Anfangsadresse
		dw 1340h		; Endeadresse (incl.)
		dw 0FC0h
		dw 0077h

;------------------------------------------------------------------------------
