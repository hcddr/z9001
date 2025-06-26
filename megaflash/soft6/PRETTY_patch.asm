;------------------------------------------------------------------------------
; Patcht PRETTYC.COM = PRETTYC.KCC
; V. Pohlers 20.03.2025
;------------------------------------------------------------------------------
; .BIN umbenennen in PRETTYC.COM
;------------------------------------------------------------------------------

	cpu	z80

	org	0
	
offs	equ	300h-80h		; orig aadr - Header

;	binclude INSTALL.COM		; f. Patch von INSTALL
	binclude PRETTYC.COM


;------------------------------------------------------------------------------
; Patchea PRETTYC
; orig. eigene Einleseroutine, diese ignoriert den Dateityp
; deshalb Patches für
; - keine Dateiendung 
; - Nutzen der BDOS-Funktion OPENR
; dazu Ändern des Copyriht-Schutzes
; - kein Prüfsummenschutz mehr (RET statt RET Z)
; - Speicherplatz wird wird für Patches genutzt
;------------------------------------------------------------------------------



	org	31f7h - offs

;ROM:31F7                ld      b, 8

	ld	b,11		; Dateiname+Endung 11 Zeichen mit 00 überschreibben



	org	31fdh - offs	

;ROM:31FD		 push	 de
;ROM:31FE		 call	 0F593h		 ; REQU, "start tape" anzeigen
;ROM:3201		 jp	 c, loc_2D3C	; bei Abbruch mit STOP
;ROM:3204		 pop	 hl
;ROM:3205		 call	 load_block	; Block direkt hinter Name laden (z.B. 21C)
;ab 3208 gehts weiter !!

	ld	(001bh),de	; DMA setzen, hinter Filename einlesen
	ld	hl,210h		; HL ist 210h 
	call	patch1+offs
	nop
patchret:


	org	4D09h - offs	; -280h = 4a8bh

; ROM:4D09 FE A8                       cp      0A8h ; '¿'      ; spezielle prüfsumme
; ROM:4D0B C8                          ret     z

	xor	A		; Z=1
	ld	a,0A8h		; orig. Wert
				; wird m.E. beides nicht genutzt, aber sicherheitshalber
				; melden wir uns wie im Original zurück
	ret

;orig: Schutz, falls copyright verändert wurde
;
; ROM:4D0C             schutz, falls copyright verändert wurde
; ROM:4D0C 97                          sub     a               ; a=0
; ROM:4D0D 2B                          dec     hl              ; hl=2cff
; ROM:4D0E 04                          inc     b               ; bc=108
; ROM:4D0F 00                          nop
; ROM:4D10 02                          ld      (bc), a
; ROM:4D11 02                          ld      (bc), a
; ROM:4D12 02                          ld      (bc), a
; ROM:4D13 2A D1 4E                    ld      hl, (word_4ED1)
; ROM:4D16 54                          ld      d, h
; ROM:4D17 5D                          ld      e, l
; ROM:4D18 CD 00 40                    call    sub_4000
; ROM:4D1B CD 00 40                    call    sub_4000
; ROM:4D1E EB                          ex      de, hl
; ROM:4D1F 2B                          dec     hl
; ROM:4D20 2B                          dec     hl
; ROM:4D21 CD 00 40                    call    sub_4000
; ROM:4D24 EB                          ex      de, hl
; ROM:4D25 CD 29 4D                    call    call_de
; ROM:4D28 DF                          rst     18h
; ROM:4D28             ; End of function sub_4CFB

patch1:
	push	de
	ld	de,5Ch		; name in FCB kopieren
	ld	bc,11		; Name+Typ
	ldir
	pop	de
	ld	c, 13	;Ruf OPENR
	CALL	5
	RET	NC	; kein Fehler
	or	a	
	jp	z, 2D3Ch	; bei Abbruch mit STOP, stack wird restauriert
	ret
patchend:


	message ".BIN umbenennen in PRETTYC.COM"

	end
