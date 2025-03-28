; MEGAROM-Testprogramm
; V.Pohlers 04.02.2010
; letzte Änderung 14.10.2012: eigene Bank wird übersprungen 

; 24.05.2020 Variante2 Prüfung pro EPROM	
	
		cpu	z80undoc

ROT:    		EQU     0114H
GRUEN:  		EQU     0214H
GELB:   		EQU     0314H
BLAU:   		EQU     0414H
MAGENTA:		EQU     0514H
CYAN:   		EQU     0614H
WHITE:  		EQU     0714H 

		include	../includes.asm
        	
		org	300h		; muss im RAM stehen (selbstmodifizierend)
		
		jp	chkrom
		db	"CHKROM2 ",0
		db	0
		
chkrom:		ld	de, txt1
		ld	c, 9
		call	5
		;	        	
		
		ld	hl,0C000h
		call	chkrom2

		ld	hl,0C800h
		call	chkrom2

		ld	hl,0D000h
		call	chkrom2

		ld	hl,0D800h
		call	chkrom2

		ld	hl,0E000h
		call	chkrom2
		
		ld	de, txte
		ld	c, 9
		call	5
		
		ld	a,systembank
		out	(bankport),a
		ret
        	
txt1:		dw	WHITE
		db	"MEGAROM-Selbsttest, V.Pohlers, 2020",13,10,10
		dw	GRUEN
		db	"Fuer jeden ROM wird eine Pruefsumme",13,10
		db	"gebildet.",13,10,10
		db	0
		
txte:		dw	13,10
		dw	GRUEN
		db	0
       	       	
; Prüfsumme ab HL je 2KByte über alle Bänke 00..FF
chkrom2:			
	;	ld	hl,0C000h
		ld	a,0	; Bank
		ld	ix,0	; summe
		ld	d,0
		push	hl

chkrom2a:	push	af
		out	(bankport),a
		ld	bc,800h
		
chkrom3:	
		ld	e, (hl)
		add	ix,de
		cpi			; nutzen für inc hl, dec bc
        	jp	pe, chkrom3	; bei PV = 1, d.h. BC <> 0


		pop	af
		pop	hl
		push	hl
		
		inc	a
		jr	nz,chkrom2a

		pop	hl

		ld	hl, txt2c
		
		ld	a,ixh
		call	outhx
		ld	a,ixl
		call	outhx
		
		ld	de, txt2
		ld	c, 9
		call	5		

		ld	hl,txt2a
		inc	(hl)		; nächste ROM-Nr.

		ret		        	
        	

txt2:		dw	rot
		db	13,10,"ROM "
txt2a:		db	"1 = "
txt2c:		db	"xxxx", 13,10
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
		