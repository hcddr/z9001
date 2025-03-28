; File Name   :	D:\user\volker\hobby\hobby0\z9001 s6005\SM.KCC
; Format      :	Binary file
; Base Address:	0000h Range: B580h - BE80h Loaded length: 0900h
; Segment type:	Pure code
; segment "ROM"

		cpu	z80


; enum PORTS
CTC1:		 = 81h			; System CTC1 Anwenderport
PIO1BD:		 = 89h			; PIO1 B Daten Anwenderport
PIO1BS:		 = 8Bh			; PIO1 B Kommando Anwenderport

IOBYT:		equ 0004h
LISW:		equ 0015h
KEYBU:		equ 0025h

unk_202:	equ	0202h			; Anwender CTC Kanal 1
unk_210:        equ	0210h                    ; ISR PIO B
unk_252		equ	0252h
 
 
 		org	2dfh

unk_2DF:	ds 1			
unk_2E0:	ds 1			
unk_2E1:	ds 1
byte_2E2:	ds 1			
					
byte_2E3:	ds 1			
					
byte_2E4:	ds 1			
					
byte_2E5:	ds 1			
					
byte_2E6:	ds 1			
					
byte_2E7:	ds 1			
unk_2E8:	ds 1
unk_2E9:	ds 1
unk_2EA:	ds 1
unk_2EB:	ds 1
byte_2EC:	ds 1			
byte_2ED:	ds 1			
byte_2EE:	ds 1			
word_2EF:	ds 2			
		ds 1
byte_2F2:	ds 1			
unk_2F3:	ds 1
		ds 1
word_2F5:	ds 2			
word_2F7:	ds 2			
word_2F9:	ds 2			
					
unk_2FB:	ds 1
unk_2FC:	ds 1
byte_2FD:	ds 1			
unk_2FE:	ds 1
 

;-------------------------------------------------------------------------------
;
;-------------------------------------------------------------------------------

		org 0B600h

aadr:		jp	start
aS3004:		db "S3004   ",0
		jp	eos
		db "#       ",0
		db    0
eos:		call	dini
		jp	0F089h
start:		ld	hl, unk_252
		ld	(word_2F5), hl
		ld	hl, 6
		ld	(word_2F7), hl
char_at:		call	dini
		call	sub_B6D6
		jp	loc_B748
dini:		ld	hl, ttyl
		di
		ld	(0EFE1h), hl	; ATTYL		  equ	  0EFE1h	  ; Adresse TTY-Treiber	fÅr LIST
		ld	hl, aS3004	; "S3004   "
		ld	(0EFEFh), hl	; TXLST		  equ	  0EFEFh	  ; Adresse einer Zeichenkette des aktuellen LIST-GerÑtes
		ld	a, (IOBYT)
		and	00111111b
		ld	(IOBYT), a
		ld	hl, loc_B752
dini1:					; IR-Tabelle f.	PIO
		ld	(unk_210), hl
		ld	b, 5
		ld	c, PIO1BS	; PIO1BS
		ld	hl, byte_B67D
		otir
		ld	a, 00000001b	; Bit0=Hi
		out	(PIO1BD), a	; User-Port
		ld	a, 00000011b	; Bit0 und Bit2	= Hi
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		ld	a, 10110111b	; EI,Zeitgeber,Vorteiler 256
		out	(CTC1),	a	; CTC
		xor	a
		out	(CTC1),	a	; Zeitkonstante	0 (=256)
		ld	(byte_2FD), a
		ld	hl, loc_B682	; CTC1-Interrupt-Routine
		ld	(unk_202),	hl	; Anwender CTC Kanal 1
		ld	b, 19h
dini2:		call	wait
		djnz	dini2
		xor	a
		ld	(KEYBU), a
		ei
		ret
byte_B67D:	db 10h
					; Interrupt Vektor (210h)
		db 11001111b		; PIO Mode 3
		db 11111100b		; Bit 0,2 Ausgabe, Rest	Eingabe
		db 10010111b		; EI, OR, LOW, Maske folgt
		db 10111111b		; Interrupt auf	Bit 3
;-------------------------------------------------------------------------------
; ISR CTC
;-------------------------------------------------------------------------------
loc_B682:		push	af		; CTC1-Interrupt-Routine
		ld	a, (byte_2FD)
		xor	1
		ld	(byte_2FD), a
		or	a
		jr	nz, loc_B696
		ld	a, 00000011b	; CTC DI, Reset
		out	(CTC1),	a	; System CTC1 Anwenderport
		ld	a, 1		; Pio Bit0=Hi
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
loc_B696:		pop	af
		ei
		reti
sub_B69A:		push	bc
		push	af
		ld	c, a
loc_B69D:		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		and	10000000b	; Bit1 abfragen
		jr	nz, loc_B69D
		di
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		and	11111110b
		ld	b, 9
		jr	loc_B6B4
loc_B6AC:		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		and	11111110b
		rr	c
		adc	a, 0
loc_B6B4:		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		ld	a, 7Dh ; '}'
loc_B6B8:		dec	a
		jr	nz, loc_B6B8
		djnz	loc_B6AC
		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		or	1
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		ld	a, 7Dh ; '}'
loc_B6C5:		dec	a
		jr	nz, loc_B6C5
		pop	af
		scf
		ccf
		pop	bc
		ei
		ret
wait:		ld	d, 5Ch ; '\'
wait1:		dec	d
		ret	z
		jr	wait1
		ld	b, 0
sub_B6D6:		ld	b, 0
		call	sub_BD4F
		ld	b, 19h
loc_B6DD:		push	bc
		ld	b, 1
		call	sub_BD4F
		pop	bc
		djnz	loc_B6DD
		ld	b, 2
		call	sub_BD4F
		ld	hl, (word_2F7)
		call	sub_BCEB
		ld	a, b
		or	a
		jr	z, loc_B6FC
loc_B6F5:		ld	a, 71h ; 'q'
		call	sub_B69A
		djnz	loc_B6F5
loc_B6FC:		ld	a, 7Eh ; '~'
		call	sub_B69A
		ld	hl, (word_2F5)
		ld	de, (word_2F7)
		and	a
		sbc	hl, de
		call	sub_BCEB
loc_B70E:		push	bc
		ld	b, 3
		call	sub_BD4F
		pop	bc
		djnz	loc_B70E
		ld	b, 4
		call	sub_BD4F
		ld	hl, (word_2F5)
		push	hl
		ld	hl, (word_2F7)
		push	hl
		ld	hl, unk_2DF
		ld	(hl), 0
		ld	de, unk_2E0
		ld	bc, 20h	; ' '
		ldir
		pop	hl
		ld	(word_2F7), hl
		pop	hl
		ld	(word_2F5), hl
		ld	a, 6
		ld	(byte_2F2), a
		ld	(byte_2EC), a
		ld	hl, 28h	; '('
		ld	(word_2F9), hl
		ret
loc_B748:		ld	b, 8
		call	sub_BD4F
		xor	a
		ld	(unk_2FC), a
		ret
;-------------------------------------------------------------------------------
; ISR PIO
;-------------------------------------------------------------------------------
loc_B752:		push	af
		push	hl
		push	de
		push	bc
		ld	l, 3Ah ; ':'
loc_B758:		dec	l
		jr	nz, loc_B758
		ld	b, 9
loc_B75D:		in	a, (PIO1BD)	; PIO1 B Daten Anwenderport
		bit	3, a
		scf
		jr	nz, loc_B765
		ccf
loc_B765:		rr	c
		ld	l, 7Dh ; '}'
loc_B769:		dec	l
		jr	nz, loc_B769
		djnz	loc_B75D
		ld	a, c
		ld	(unk_2FB), a
		ld	a, (unk_2DF)
		or	a
		jr	nz, loc_B77F
		ld	a, 1
		ld	(unk_2DF), a
		jr	loc_B7EF
loc_B77F:		ld	a, (unk_2FC)
		or	a
		jr	nz, loc_B798
		ld	a, (unk_2FB)
		and	3Fh ; '?'
		cp	3Fh ; '?'
		jr	nz, loc_B7AE
		ld	(unk_2FC), a
		ld	b, 9
		call	sub_BD4F
		jr	loc_B7EF
loc_B798:		ld	a, (unk_2FB)
		cp	87h ; 'á'
		jr	nz, loc_B7AE
		xor	a
		ld	(unk_2FC), a
		ld	b, 0Ah
		call	sub_BD4F
		xor	a
		ld	(unk_2DF), a
		jr	loc_B7EF
loc_B7AE:		ld	a, 1
		ld	(unk_2DF), a
		ld	a, (unk_2FC)
		or	a
		jr	z, loc_B7D5
		ld	a, (unk_2FB)
		cp	83h ; 'É'
		jr	nz, loc_B7EF
		ld	a, 91h ; 'ë'
		call	sub_B69A
		ld	b, 21h ; '!'
loc_B7C7:		ld	a, 75h ; 'u'
		call	sub_B69A
		djnz	loc_B7C7
		ld	a, 92h ; 'í'
		call	sub_B69A
		jr	loc_B7EF
loc_B7D5:		ld	a, (KEYBU)
		or	a
		jr	nz, loc_B7EF
		ld	a, (unk_2FB)
		and	3Fh ; '?'
		cp	3Eh ; '>'
		jr	z, loc_B7EF
		cp	38h ; '8'
		jr	nz, loc_B7F1
		ld	(unk_2FE), a
		xor	a
		ld	(2FFh),	a
loc_B7EF:		jr	loc_B832
loc_B7F1:		cp	39h ; '9'
		jr	nz, loc_B7FE
		xor	a
		ld	(unk_2FE), a
		ld	a, (2FFh)
		jr	loc_B82F
loc_B7FE:		ld	a, (unk_2FE)
		or	a
		jr	z, loc_B822
		ld	a, (2FFh)
		add	a, a
		ld	b, a
		add	a, a
		add	a, a
		add	a, b
		ld	b, a
		ld	a, (unk_2FB)
		sub	40h ; '@'
		ld	hl, unk_BD88
		ld	e, a
		ld	d, 0
		add	hl, de
		ld	a, (hl)
		sub	30h ; '0'
		add	a, b
		ld	(2FFh),	a
		jr	loc_B832
loc_B822:		ld	a, (unk_2FB)
		sub	40h ; '@'
		ld	hl, unk_BD88
		ld	c, a
		ld	b, 0
		add	hl, bc
		ld	a, (hl)
loc_B82F:		ld	(KEYBU), a
loc_B832:		ld	a, 00000011b
		out	(PIO1BD), a	; PIO1 B Daten Anwenderport
		ld	a, 10110111b
		out	(CTC1),	a	; System CTC1 Anwenderport
		xor	a
		out	(CTC1),	a	; System CTC1 Anwenderport
		ld	(byte_2FD), a
		pop	bc
		pop	de
		pop	hl
		pop	af
		ei
		reti
;------------------------------------------------------------------------------
; TTY-Treiber f. LIST (logischer Treiber)
;------------------------------------------------------------------------------
ttyl:		push	hl
		push	de
		push	bc
		inc	a		; A=FF?
		jr	nz, ttyl1
		call	dini		; ja ->	Initialisieren
		jr	ttyl4
ttyl1:		dec	a		; A=0?
		jr	nz, ttyl2	; A=2?
		in	a, (PIO1BD)	; ja ->	Statusabfrage
		and	10000000b
		jr	ttyl4
ttyl2:		dec	a		; A=2?
		dec	a
		jr	nz, ttyl3
		ld	a, c		; ja ->	Ausgabe	Zeichen
		call	sub_B86F
		or	a
		jr	ttyl4
ttyl3:		xor	a		; sonst
		ld	(LISW),	a	; Drucker aus
		scf			; Fehler
ttyl4:		pop	bc
		pop	de
		pop	hl
		ret
sub_B86F:	; FUNCTION CHUNK AT B999 SIZE 00000019 BYTES
; FUNCTION CHUNK AT B9E9 SIZE 0000001F BYTES
; FUNCTION CHUNK AT BA20 SIZE 00000089 BYTES
; FUNCTION CHUNK AT BB32 SIZE 0000000F BYTES
; FUNCTION CHUNK AT BC21 SIZE 00000054 BYTES
		ld	(byte_2E7), a
		ld	a, (byte_2EE)
		or	a
		jp	nz, loc_BC21
		ld	hl, (word_2EF)
		ld	a, l
		or	h
		jp	nz, loc_BC2C
		ld	a, (unk_2EB)
		or	a
		jp	nz, loc_BB32
		ld	a, (unk_2E0)
		or	a
		jp	nz, loc_BA82
		ld	a, (byte_2E7)
		cp	80h ; 'Ä'
		jr	c, loc_B89B
		ld	a, 20h ; ' '
		ld	(byte_2E7), a
loc_B89B:		cp	20h ; ' '
		jp	nc, loc_B999
		ld	a, (byte_2E7)
		ld	hl, ttyltab1	; Tabelle der Steuerzeichen
		call	such		; suche	Zeichen	A in Tabelle HL
		ld	hl, ttyltab2	; Tabelle der Steuerzeichen-Funktionen
		call	z, sub_BD0C
		ret
ttyltab1:	db    8
					; Tabelle der Steuerzeichen
		db    9
		db  0Ah
		db  0Bh
		db  0Ch
		db  0Dh
		db  1Bh
		db  0Fh
		db  12h
		db  0Eh
		db  14h
		db    7
		db    0
ttyltab2:	dw char_08
					; Tabelle der Steuerzeichen-Funktionen
		dw char_09
		dw char_0a
		dw char_0b
		dw char_0c
		dw char_0d
		dw char_1b
		dw char_0f
		dw char_12
		dw char_0e
		dw char_14
		dw char_07
char_07:		ld	b, 0Bh
		jp	sub_BD4F
char_08:		ld	a, (byte_2F2)
		ld	b, a
		ld	a, (unk_2F3)
		sub	b
		ret	c
		ld	(unk_2F3), a
		ld	a, 72h ; 'r'
		jp	sub_B69A
char_09:					; sub_B86F+205j ...
; FUNCTION CHUNK AT B966 SIZE 0000002D BYTES
		ld	a, 71h ; 'q'
		call	sub_B69A
		ld	de, (word_2F7)
		ld	hl, (word_2F5)
		and	a
		sbc	hl, de
		ex	de, hl
		ld	hl, (unk_2F3)
		ld	a, (byte_2F2)
		ld	c, a
		ld	b, 0
		add	hl, bc
		ld	(unk_2F3), hl
		and	a
		sbc	hl, de
		ret	c
		call	char_0d
char_0a:		ld	hl, (word_2F9)
		jr	loc_B966
char_0b:		ld	hl, (word_2F9)
		jr	loc_B993
char_0d:		ld	a, 78h ; 'x'
		call	sub_B69A
		ld	hl, 0
		ld	(unk_2F3), hl
		ret
char_0c:		ld	b, 78h ; 'x'
char_0c_1:		ld	a, 75h ; 'u'
		call	sub_B69A
		djnz	char_0c_1
		ret
char_1b:		ld	a, 1
		ld	(unk_2E0), a
		ret
char_0f:		ld	a, (byte_2F2)
		cp	4
		ret	z
		ld	(byte_2EC), a
		ld	a, 4
		ld	(byte_2F2), a
		ld	a, 89h ; 'â'
		jr	char_12_1
char_12:		ld	a, (byte_2F2)
		cp	4
		ret	nz
loc_B94D:		ld	a, (byte_2EC)
		ld	(byte_2F2), a
		cp	6
		ld	a, 87h ; 'á'
		jr	z, char_12_1
		inc	a
char_12_1:		jp	sub_B69A
char_0e:		ld	a, 1
		jr	char_14_1
char_14:		xor	a
char_14_1:		ld	(unk_2E1), a
		ret
loc_B966:		ld	d, 75h ; 'u'
		ld	e, 81h ; 'Å'
loc_B96A:		push	de
		ld	de, 14h
		ld	bc, 0
loc_B971:		and	a
		sbc	hl, de
		jr	c, loc_B979
		inc	b
		jr	loc_B971
loc_B979:		add	hl, de
		ld	c, l
		srl	c
		inc	b
		inc	c
		pop	de
		ld	a, d
		dec	b
		jr	z, loc_B989
loc_B984:		call	sub_B69A
		djnz	loc_B984
loc_B989:		ld	a, e
		ld	b, c
		dec	b
		ret	z
loc_B98D:		call	sub_B69A
		djnz	loc_B98D
		ret
loc_B993:		ld	d, 76h ; 'v'
		ld	e, 82h ; 'Ç'
		jr	loc_B96A
loc_B999:					; sub_B86F:loc_BA44j ...
		ld	a, (byte_2E4)
		or	a
		jr	z, loc_B9E9
		ld	a, (byte_2E7)
		ld	hl, partab1
		call	such		; suche	Zeichen	A in Tabelle HL
		jr	nz, loc_B9E9
		ld	hl, partab2
		call	sub_BD38
		jr	loc_BA29
partab1:	db '['
		db '\\'
		db ']'
		db '{'
		db '|'
		db '}'
		db '~'
		db    0
partab2:	db  74h	; t
		db 0A9h	; ©
		db  27h	; '
		db  73h	; s
		db  76h	; v
		db 0A9h	; ©
		db  62h	; b
		db  75h	; u
		db  75h	; u
		db 0A9h	; ©
		db  62h	; b
		db  76h	; v
		db    0
		db 0A9h	; ©
		db  27h	; '
		db    0
		db  73h	; s
		db 0A9h	; ©
		db  27h	; '
		db  74h	; t
		db  76h	; v
		db 0A9h	; ©
		db  62h	; b
		db  75h	; u
		db  75h	; u
		db 0A9h	; ©
		db  62h	; b
		db  76h	; v
		db    0
		db 0A9h	; ©
		db  1Dh
		db 0A9h	; ©
		db  62h	; b
		db    0
		db 0A9h	; ©
		db  27h	; '
		db    0
		db 0A9h	; ©
		db  1Fh
		db 0A9h	; ©
		db  62h	; b
		db    0
		db 0A9h	; ©
		db    3
		db 0A9h	; ©
		db  29h	; )
		db    0
loc_B9E9:					; sub_B86F+139j
		ld	a, (byte_2E7)
		ld	hl, chrtab1
		call	such		; suche	Zeichen	A in Tabelle HL
		jr	nz, loc_BA20
		ld	a, b
		or	a
		jr	nz, loc_B9FF
		ld	a, (byte_2E6)
		or	a
		jr	z, loc_B9FF
		dec	b
loc_B9FF:					; sub_B86F+18Dj
		inc	b
		ld	hl, chrtab2
		call	sub_BD38
		jr	loc_BA29
chrtab1:	db '0'
		db '<'
		db '>'
		db    0
chrtab2:	db 0A9h	; ©
		db  0Dh
		db    0
		db 0A9h	; ©
		db  0Dh
		db 0A9h	; ©
		db  40h	; @
		db    0
		db 0A9h	; ©
		db  62h	; b
		db  75h	; u
		db 0A9h	; ©
		db  2Bh	; +
		db  76h	; v
		db    0
		db 0A9h	; ©
		db  62h	; b
		db 0A9h	; ©
		db  2Bh	; +
		db    0
loc_BA20:		ld	a, (byte_2E7)
		call	sub_BC80
		call	sub_BC75
loc_BA29:					; sub_B86F+197j
		ld	a, (byte_2E2)
		or	a
		jr	z, loc_BA34
		ld	b, 5
		call	sub_BD4F
loc_BA34:		ld	a, (byte_2E5)
		or	a
		jr	z, loc_BA47
		ld	a, (unk_2E8)
		xor	1
		ld	(unk_2E8), a
		jr	z, loc_BA47
loc_BA44:		jp	loc_B999
loc_BA47:					; sub_B86F+1D3j
		ld	a, (byte_2E3)
		or	a
		jr	z, loc_BA65
		ld	a, (unk_2E9)
		xor	1
		ld	(unk_2E9), a
		or	a
		jr	z, loc_BA60
		ld	b, 6
		call	sub_BD4F
		jp	loc_B999
loc_BA60:		ld	b, 7
		call	sub_BD4F
loc_BA65:		ld	a, (unk_2E1)
		or	a
		jp	z, char_09
		ld	a, (unk_2EA)
		xor	1
		ld	(unk_2EA), a
		jp	z, char_09
		call	char_09
		ld	a, 20h ; ' '
		ld	(byte_2E7), a
		jp	loc_B999
loc_BA82:		xor	a
		ld	(unk_2E0), a
		ld	a, (byte_2E7)
		ld	hl, unk_BACB
		call	such		; suche	Zeichen	A in Tabelle HL
		ld	hl, off_BAA9
		call	z, sub_BD0C
		xor	a
		ld	(unk_2EB), a
		ld	a, (byte_2E7)
		ld	hl, unk_BB26
		call	such		; suche	Zeichen	A in Tabelle HL
		ret	nz
		ld	a, b
		inc	a
		ld	(unk_2EB), a
		ret
off_BAA9:	dw char_0e
		dw char_0f
		dw char_p
		dw char_m
		dw char_2
		dw char_4
		dw char_5
		dw char_e
		dw char_f
		dw char_ul
		dw char_sl
		dw char_g
		dw char_h
		dw char_at
		dw char_1
		dw char_0
		dw char_t
unk_BACB:	db  0Eh
		db  0Fh
		db  50h	; P
		db  4Dh	; M
		db  32h	; 2
		db  34h	; 4
		db  35h	; 5
		db  45h	; E
		db  46h	; F
		db  5Fh	; _
		db  2Fh	; /
		db  47h	; G
		db  48h	; H
		db  40h	; @
		db  31h	; 1
		db  30h	; 0
		db  54h	; T
		db    0
char_p:		ld	a, 6
loc_BADF:		ld	(byte_2EC), a
		ld	a, (byte_2F2)
		cp	4
		ret	z
		jp	loc_B94D
		ret
char_m:		ld	a, 5
		jr	loc_BADF
char_2:		ld	hl, 28h	; '('
loc_BAF3:		ld	(word_2F9), hl
		ret
char_4:		ld	hl, 3Ch	; '<'
		jr	loc_BAF3
char_5:		ld	hl, 50h	; 'P'
		jr	loc_BAF3
char_1:		ld	hl, 15h
		jr	loc_BAF3
char_0:		ld	hl, 1Eh
		jr	loc_BAF3
char_e:		ld	a, 1
loc_BB0D:		ld	(byte_2E3), a
		ret
char_f:		xor	a
		jr	loc_BB0D
char_ul:		ld	a, 1
loc_BB16:		ld	(byte_2E6), a
		ret
char_sl:		xor	a
		jr	loc_BB16
char_g:		ld	a, 1
loc_BB1F:		ld	(byte_2E5), a
		ret
char_h:		xor	a
		jr	loc_BB1F
unk_BB26:	db  53h	; S
		db  57h	; W
		db  2Dh	; -
		db  4Bh	; K
		db  33h	; 3
		db  41h	; A
		db  4Ah	; J
		db  6Ah	; j
		db  51h	; Q
		db  23h	; #
		db  52h	; R
		db    0
loc_BB32:		ld	a, (unk_2EB)
		dec	a
		ld	b, a
		ld	hl, off_BB41
		xor	a
		ld	(unk_2EB), a
		jp	sub_BD0C
off_BB41:	dw char_s
		dw char_w
		dw char_mi
		dw char_k
		dw char_3
		dw char_a
		dw char_j
		dw char_jk
		dw char_q
		dw char_num
		dw char_r
char_num:		ld	a, (byte_2E7)
		call	sub_BCFF
		ld	de, (word_2F5)
		and	a
		sbc	hl, de
		ret	nc
		ld	(word_2F7), bc
		jp	char_at
char_q:		ld	a, (byte_2E7)
		cp	65h ; 'e'
		ret	nc
		call	sub_BCFF
		ld	de, (word_2F7)
		and	a
		ex	de, hl
		sbc	hl, de
		ret	nc
		ld	(word_2F5), bc
		jp	char_at
char_s:		ld	a, (byte_2E7)
		and	1
		or	a
		ld	a, (byte_2ED)
		jr	nz, loc_BBA7
		cp	1
		ret	z
		cp	2
		call	z, sub_BB9D
		ld	a, 1
		ld	(byte_2ED), a
sub_BB9D:		ld	a, 76h ; 'v'
		jp	sub_B69A
sub_BBA2:		ld	a, 75h ; 'u'
		jp	sub_B69A
loc_BBA7:		cp	2
		ret	z
		cp	1
		call	z, sub_BBA2
		ld	a, 2
		ld	(byte_2ED), a
		jr	sub_BBA2
char_t:		ld	a, (byte_2ED)
		cp	1
		jr	nz, loc_BBC5
		call	sub_BBA2
loc_BBC0:		xor	a
		ld	(byte_2ED), a
		ret
loc_BBC5:		cp	2
		ret	nz
		call	sub_BB9D
		jr	loc_BBC0
char_w:		ld	a, (byte_2E7)
		and	1
		or	a
		jp	z, char_14
		jp	char_0e
char_mi:		ld	a, (byte_2E7)
		and	1
		ld	(byte_2E2), a
		ret
char_3:		ld	a, (byte_2E7)
		ld	l, a
		ld	h, 0
		jp	loc_BAF3
char_a:		ld	a, (byte_2E7)
		ld	l, a
		ld	h, 0
		push	hl
		pop	de
		add	hl, hl
		add	hl, de
		jp	loc_BAF3
char_j:		ld	a, (byte_2E7)
		ld	l, a
		ld	h, 0
		jp	loc_B966
char_r:		ld	a, (byte_2E7)
		and	0Fh
		neg
		ld	(byte_2E4), a
		ret
char_jk:		ld	a, (byte_2E7)
		ld	l, a
		ld	h, 0
		jp	loc_B993
char_k:		ld	a, 2
		ld	(byte_2EE), a
		ld	a, (byte_2E7)
		ld	(word_2EF), a
		ret
loc_BC21:		xor	a
		ld	(byte_2EE), a
		ld	a, (byte_2E7)
		ld	(word_2EF+1), a
		ret
loc_BC2C:		ld	hl, (word_2EF)
		dec	hl
		ld	(word_2EF), hl
		ld	a, (byte_2E7)
		ld	b, 8
loc_BC38:		rlca
		jr	c, loc_BC3F
		djnz	loc_BC38
		jr	loc_BC6A
loc_BC3F:		rrca
		push	af
		push	bc
		dec	b
		jr	z, loc_BC4E
		sla	b
loc_BC47:		ld	a, 82h ; 'Ç'
		call	sub_B69A
		djnz	loc_BC47
loc_BC4E:		pop	bc
		pop	af
loc_BC50:		rlca
		jr	nc, loc_BC5A
		push	af
		ld	a, 63h ; 'c'
		call	sub_BC75
		pop	af
loc_BC5A:		dec	b
		jr	z, loc_BC6A
		inc	b
		push	af
		ld	a, 81h ; 'Å'
		call	sub_B69A
		call	sub_B69A
		pop	af
		djnz	loc_BC50
loc_BC6A:					; sub_B86F+3ECj
		ld	a, 0A5h	; '•'
		call	sub_B69A
		ld	a, 2
		call	sub_B69A
		ret
sub_BC75:					; sub_B86F+3E7p
		push	af
		ld	a, 0A9h	; '©'
		call	sub_B69A
		pop	af
		call	sub_B69A
		ret
sub_BC80:		ld	hl, unk_BC8B
		sub	20h ; ' '
		ld	e, a
		ld	d, 0
		add	hl, de
		ld	a, (hl)
		ret
unk_BC8B:	db  71h	; q
		db  42h	; B
		db  43h	; C
		db  41h	; A
		db  48h	; H
		db    4
		db    2
		db  17h
		db  1Dh
		db  1Fh
		db  1Bh
		db  25h	; %
		db  64h	; d
		db  62h	; b
		db  63h	; c
		db  40h	; @
		db  0Dh
		db  11h
		db  10h
		db  0Fh
		db  0Eh
		db  0Ch
		db  0Bh
		db  0Ah
		db    9
		db    8
		db  13h
		db  3Bh	; ;
		db    0
		db  2Eh	; .
		db    0
		db  35h	; 5
		db  3Dh	; =
		db  30h	; 0
		db  18h
		db  20h
		db  14h
		db  34h	; 4
		db  3Eh	; >
		db  1Ch
		db  12h
		db  21h	; !
		db  32h	; 2
		db  24h	; $
		db  2Ch	; ,
		db  16h
		db  2Ah	; *
		db  1Eh
		db  2Fh	; /
		db  1Ah
		db  36h	; 6
		db  33h	; 3
		db  37h	; 7
		db  28h	; (
		db  22h	; "
		db  2Dh	; -
		db  26h	; &
		db  31h	; 1
		db  38h	; 8
		db  3Fh	; ?
		db  3Ch	; <
		db  3Ah	; :
		db  19h
		db    1
		db  2Bh	; +
		db  61h	; a
		db  4Eh	; N
		db  57h	; W
		db  53h	; S
		db  5Ah	; Z
		db  49h	; I
		db  60h	; `
		db  55h	; U
		db    5
		db  4Bh	; K
		db  50h	; P
		db  4Dh	; M
		db  4Ah	; J
		db  5Ch	; 
		db  5Eh	; ^
		db  5Bh	; [
		db  52h	; R
		db  59h	; Y
		db  58h	; X
		db  56h	; V
		db  5Dh	; ]
		db  4Fh	; O
		db  4Ch	; L
		db  5Fh	; _
		db  51h	; Q
		db  54h	; T
		db  65h	; e
		db  66h	; f
		db  67h	; g
		db  47h	; G
		db    0
sub_BCEB:		push	bc
		push	de
		ld	b, 0
		ld	de, 6
loc_BCF2:		and	a
		sbc	hl, de
		jr	c, loc_BCFA
		inc	b
		jr	loc_BCF2
loc_BCFA:		ld	l, b
		pop	de
		pop	bc
		ld	b, l
		ret
sub_BCFF:		push	de
		ld	l, a
		ld	h, 0
		add	hl, hl
		push	hl
		pop	de
		add	hl, hl
		add	hl, de
		pop	de
		push	hl
		pop	bc
		ret
sub_BD0C:					; sub_B86F+223p ...
		ld	a, b
		add	a, a
		ld	e, a
		ld	d, 0
		add	hl, de
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		ex	de, hl
		jp	(hl)
; suche	Zeichen	A in Tabelle HL
such:					; sub_B86F+136p ...
		push	hl
		push	af
		xor	a
		ld	bc, 0FFFFh
		cpir
		pop	af
		pop	de
		push	de
		push	af
		and	a
		sbc	hl, de
		dec	hl
		push	hl
		pop	bc
		pop	af
		pop	hl
		push	hl
		cpir
		pop	de
		ret	nz
		dec	hl
		and	a
		sbc	hl, de
		ld	b, l
		xor	a
		or	a
		ret
sub_BD38:					; sub_B86F+194p ...
		ld	a, b
		or	a
		jr	z, loc_BD46
loc_BD3C:		push	bc
		ld	bc, 0FFFFh
		xor	a
		cpir
		pop	bc
		djnz	loc_BD3C
loc_BD46:		ld	a, (hl)
		or	a
		ret	z
		inc	hl
		call	sub_B69A
		jr	loc_BD46
sub_BD4F:		push	hl
		push	bc
		push	af
		ld	hl, unk_BD5C
		call	sub_BD38
		pop	af
		pop	bc
		pop	hl
		ret
unk_BD5C:	db  71h	; q
		db  71h	; q
		db  95h	; ï
		db    0
		db  72h	; r
		db  8Fh	; è
		db    0
		db  87h	; á
		db  84h	; Ñ
		db    0
		db  71h	; q
		db  8Fh	; è
		db    0
		db  7Fh	; 
		db  78h	; x
		db    0
		db 0A9h	; ©
		db    1
		db    0
		db 0A6h	; ¶
		db    1
		db 0A5h	; •
		db    1
		db    0
		db 0A6h	; ¶
		db 0FFh
		db 0A5h	; •
		db 0FFh
		db    0
		db  91h	; ë
		db  98h	; ò
		db  96h	; ñ
		db  9Ch	; ú
		db  9Bh	; õ
		db    0
		db  92h	; í
		db  97h	; ó
		db    0
		db  91h	; ë
		db  98h	; ò
		db    0
		db 0AAh	; ™
		db  10h
		db    0
unk_BD88:	db  31h	; 1
		db  51h	; Q
		db  41h	; A
		db  59h	; Y
		db  32h	; 2
		db  57h	; W
		db  53h	; S
		db  58h	; X
		db  33h	; 3
		db  45h	; E
		db  44h	; D
		db  43h	; C
		db  34h	; 4
		db  52h	; R
		db  46h	; F
		db  56h	; V
		db  35h	; 5
		db  54h	; T
		db  47h	; G
		db  42h	; B
		db  36h	; 6
		db  5Ah	; Z
		db  48h	; H
		db  4Eh	; N
		db  37h	; 7
		db  55h	; U
		db  4Ah	; J
		db  4Dh	; M
		db  38h	; 8
		db  49h	; I
		db  4Bh	; K
		db  2Ch	; ,
		db  39h	; 9
		db  4Fh	; O
		db  4Ch	; L
		db  2Eh	; .
		db  30h	; 0
		db  50h	; P
		db  5Ch	; 
		db  2Dh	; -
		db  7Eh	; ~
		db  5Dh	; ]
		db  5Bh	; [
		db  1Bh
		db  27h	; '
		db  1Ah
		db  1Fh
		db  19h
		db    8
		db  1Dh
		db  0Ah
		db  0Bh
		db    9
		db    8
		db  0Dh
		db  20h
		db    0
		db    0
		db    0
		db  1Ch
		db  14h
		db    0
		db    0
		db    0
		db  21h	; !
		db  71h	; q
		db  61h	; a
		db  79h	; y
		db  22h	; "
		db  77h	; w
		db  73h	; s
		db  78h	; x
		db  40h	; @
		db  65h	; e
		db  64h	; d
		db  63h	; c
		db  2Bh	; +
		db  72h	; r
		db  66h	; f
		db  76h	; v
		db  25h	; %
		db  74h	; t
		db  67h	; g
		db  62h	; b
		db  26h	; &
		db  7Ah	; z
		db  68h	; h
		db  6Eh	; n
		db  2Fh	; /
		db  75h	; u
		db  6Ah	; j
		db  6Dh	; m
		db  28h	; (
		db  69h	; i
		db  6Bh	; k
		db  3Bh	; ;
		db  29h	; )
		db  6Fh	; o
		db  6Ch	; l
		db  3Ah	; :
		db  3Dh	; =
		db  70h	; p
		db  7Ch	; |
		db  5Fh	; _
		db  3Fh	; ?
		db  7Dh	; }
		db  7Bh	; {
		db    2
		db  27h	; '
		db  1Fh
		db  1Fh
		db  18h
		db    8
		db  1Dh
		db  0Ah
		db  0Bh
		db    9
		db    8
		db  0Dh
		db  20h
		db    0
		db    0
		db    0
		db    0
		db  15h
		db    0
		db    0
		db    0
		db  65h	; e
		db  11h
		db    1
		db  19h
		db  65h	; e
		db  17h
		db  13h
		db  18h
		db  63h	; c
		db    5
		db    4
		db    3
		db  24h	; $
		db  12h
		db    6
		db  16h
		db  40h	; @
		db  14h
		db    7
		db    2
		db  23h	; #
		db  1Ah
		db    8
		db  0Eh
		db  75h	; u
		db  15h
		db  0Ah
		db  0Dh
		db  6Fh	; o
		db    9
		db  0Bh
		db  2Ah	; *
		db  3Ch	; <
		db  0Fh
		db  0Ch
		db  27h	; '
		db  3Eh	; >
		db  10h
		db  1Ch
		db  7Ch	; |
		db  7Eh	; ~
		db  1Dh
		db  1Bh
		db  1Bh
		db  5Eh	; ^
		db    0
		db    0
		db  18h
		db  19h
		db  1Dh
		db  0Ah
		db  0Bh
		db    9
		db    8
		db  0Dh
		db  20h
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
		db    0
eadr:		db    0
; end of "ROM"
		end
