; MEGAROM-Testprogramm
; V.Pohlers 04.02.2010
; letzte Änderung 14.10.2012: eigene Bank wird übersprungen 
; 19.03.2020 auch f. Kombi
	
		cpu	z80

ROT:    		EQU     0114H
GRUEN:  		EQU     0214H
GELB:   		EQU     0314H
BLAU:   		EQU     0414H
MAGENTA:		EQU     0514H
CYAN:   		EQU     0614H
WHITE:  		EQU     0714H 

		include	../includes.asm
        	
		org	300h		; muss im RAM stehen (selbstmodifizierend)

; kein ReStart, da sonst Banknr in b nicht stimmt
;		jp	chkrom
;		db	"CHKROM  ",0
;		db	0
		
chkrom:		ld	de, txt1
		ld	c, 9
		call	5
		;	        	
		
		ld	a,b		; die eigene Bank (bei gepackten Programmen)
		ld	(eigenebank),a
		
		ld	a, -1
		ld	(mycurrbank), a
		
chkrom1:	ld	a,(mycurrbank)
		inc	a
		ld	(mycurrbank), a
		out	(bankport), a
		ld	hl,eigenebank
		cp	(HL)		; eigene Bank wird übersprungen (hier steht romchk drin)
		call	nz, chkrom2
		ld	a, (mycurrbank)
		cp	lastbank	; Bank FF überschritten?
		jr	nz, chkrom1
		
		ld	de, txte
		ld	c, 9
		call	5
		
		ld	a,systembank
		out	(bankport),a
		ret
        	
txt1:		dw	WHITE
		if megarom == "KOMBI"
		db	"KOMBIROM-Selbsttest, V.Pohlers, 2020",13,10,10
		else
		db	"MEGAROM-Selbsttest, V.Pohlers, 2010",13,10,10
		endif
		dw	GRUEN
		db	"Fuer jede Bank wird eine Pruefsumme",13,10
		db	"gebildet und mit einem Soll-Wert",13,10
		db	"verglichen.",13,10,10
		db	0
		
txte:		dw	GELB
		db	" Ende",13,10
		dw	GRUEN
		db	0

chksumtab:
		if megarom == "KOMBI"
		include "../kombi_chksum.inc"
		else
		include "../megarom_chksum.inc"
        	endif
        	
        	org	chksumtab+256
        	
mycurrbank	ds	1
eigenebank	ds	1
        	
chkrom2:	ld	hl,0C000h
		if megarom == "KOMBI"
		bit	0,a		; a=current bank
		ld	bc,10*1024
		jr	z,chkrom2a	; wenn gerade 10K-Bank
		ld	bc,6*1024	; sonst 6K
chkrom2a:	
		else	
		ld	bc,2800h
		endif
		ld	a, 0
chkrom3:	add	a, (hl)
		cpi			; nutzen für inc hl, dec bc
        	jp	pe, chkrom3	; bei PV = 1, d.h. BC <> 0

		ld	b, a		; istwert
		
        	; Vergleich mit Tabelle
		ld	a, (mycurrbank)
		ld	e,a
		ld	d,0
		ld	hl, chksumtab
		add	hl, de
		;add	hl, de		; bei 16-Bit-Prüfsummen
		ld	a, (hl)		; sollwert
		
		cp	b
        	jr	nz, not_ok
		
		; sonst ok
		ld	e, '.'
		ld	c, 2
		call	5
		ret		        	
        	
        	; Fehlerfall
not_ok:		; ld	a, sollwert	; steht in a
		ld	hl, txt2b
		call	outhx
		
		ld	a, b		; istwert
		ld	hl, txt2c
		call	outhx
		
		ld	a, (mycurrbank)
		ld	hl, txt2a
		call	outhx
		
		ld	de, txt2
		ld	c, 9
		call	5
		ret	

txt2:		dw	rot
		db	13,10,"Bank "
txt2a:		db	"xx Soll "
txt2b:		db	"xx Ist "
txt2c:		db	"xx", 13,10
		dw 	gruen
		db	0
   	

;OUTHX Schreiben (A) hexa an Pos (HL)
;
outhx:		push	af
		rlca
		rlca
		rlca
		rlca
		call	outh1
		pop	af
outh1:		and	0fh
		add	a, 30h
		cp	3ah
		jr	c, outh2
		add	a, 07h
outh2:		ld	(hl), a
		inc	hl
		ret

		end
		