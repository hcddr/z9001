;------------------------------------------------------------------------------
; CHIP8-Interpreter
; V.Pohlers, 2013
;------------------------------------------------------------------------------
; Interpreter, systemunabhängig
; based on Chip83 v0.1 by Joe Wingbermuehle; orig. für TI-83
; schon mehrfach verändert: V.Pohlers, 2013
;
; - die Grafikausgabe erfolgt in ein Pixelfeld gbuf (256 Byte)
;   das Rahmenprogramm muss dieses Pixelfeld auf den Bildschirm übertragen
;
; - Interface (s. chip8intf.asm)
;   c8_cls	BWS leeren
;   c8_drawbs	BWS anzeigen
;   c8_Error	Abbruch bei Fehler
;   c8_waitkey	Warten auf Tastendruck
;   c8_testkey	Tastaturabfrage
;   c8_sndon	Ton an
;   c8_sndoff	Ton aus
;------------------------------------------------------------------------------
; TODO: DRAW ist noch nicht vernünftig
;------------------------------------------------------------------------------

; in: (file) = Adresse des Pgm.
;     (progsize) = Länge

; in: HL = Adr. RAMB, enthält CHIP-8-Programm

chip8:	push	hl
;
	ld	hl,registers
	ld	b,16+2+1
ClearRegisters:
	ld	(hl),a
	inc	hl
	djnz	ClearRegisters
	ld	hl,stack
	ld	(stackPointer),hl
;
	pop	hl
	push	hl
	ld	de,-0200h	; Offset, orig. CHIP-8-Programme
	add	hl,de		; beginnen auf Adr. 0200h
	ld	(baseAddress),hl
	call	setScreen
	pop	hl
;	
main:	
;	ld	b,150		; Warteschleife
;delayLoop:
;	push	hl
;	pop	hl
;	djnz	delayLoop
; Abbruch?
	push	hl
	call	c8_testkey
	pop	hl
	cp	0feh		; Abbruchtaste?
	ret	z
;
	ex	de,hl
	ld	hl,(stackPointer)
	ld	bc,sram+30
	sbc	hl,bc		; Stacküberlauf?
	jp	z,stackError
;DelayTimer
	ld	hl,delayTimer
	ld	a,(hl)
	or	a
	jr	z,delayOver
	dec	a
	ld	(hl),a
delayOver:
;SoundTimer
	ld	hl,soundTimer
	ld	a,(hl)
	or	a
	jr	z,delayOver2
	dec	a
	ld	(hl),a
	jr	delayOver3
delayOver2:
	call	c8_sndoff
delayOver3:


; nächsten Befehl abarbeiten
	ex	de,hl
	ld	a,(hl)
	and	11110000b
	rra
	rra
	rra
	ld	b,0
	ld	c,a
	ld	ix,group_table
	add	ix,bc
	ld	c,(ix)
	ld	b,(ix+1)
	push	bc
	ret

group_table:
	dw	group0	; system instructions
	dw	group1	; jump address
	dw	group2	; call address
	dw	group3	; ske vx,byte
	dw	group4	; skne vx,byte
	dw	group5	; ske vx,vy
	dw	group6	; load vx,byte
	dw	group7	; add vx,byte
	dw	group8	; RR instructions
	dw	group9	; skne vx,vy
	dw	groupA	; ld I,address
	dw	groupB	; jump address+v0
	dw	groupC	; random vx,mask_byte
	dw	groupD	; draw vx,vy,size_nibble
	dw	groupE	; skne/ske vx,keypress
	dw	groupF	; misc.

; Fx instructions
groupF:	inc	hl
	ld	a,(hl)
;------------------------------------------------------------------------------
;FX1E	Adds VX to I.[3]
;------------------------------------------------------------------------------
	cp	1Eh
	jr	nz,FX2
	; ADD I,VX
	push	hl
	dec	hl
	call	readRegisterA
	ld	c,(hl)
	ld	hl,(registerI)
	add	hl,bc
	ld	a,h
	and	00001111b	; allows overflow at 12 bits (subtract)
	ld	h,a
	ld	(registerI),hl
	pop	hl
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;FX33	Stores the Binary-coded decimal representation of VX, with the most 
;       significant of three digits at the address in I, the middle digit at I plus 1, 
;       and the least significant digit at I plus 2. (In other words, take the decimal 
;       representation of VX, place the hundreds digit in memory at location in I, the 
;       tens digit at location I+1, and the ones digit at location I+2.)
;------------------------------------------------------------------------------
FX2:	cp	33h
	jr	nz,FX3
	; Store BCD of Vx in [I],[I+1],[I+2]
	; Fx33
	push	hl
	dec	hl
	call	readRegisterA
	ld	b,(hl)
	ld	hl,(registerI)
	ld	de,(baseAddress)
	add	hl,de
	ld	(hl),-1
	inc	hl
	ld	(hl),9
	inc	hl
	ld	(hl),9
	inc	b
FX2a:	ld	a,(hl)
	inc	a
	cp	10
	jr	nz,FX2b
	dec	hl
	ld	a,(hl)
	inc	a
	cp	10
	jr	nz,FX2c
	dec	hl
	inc	(hl)
	inc	hl
	xor	a
FX2c:	ld	(hl),a
	inc	hl
	xor	a
FX2b:	ld	(hl),a
	djnz	FX2a
	pop	hl
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;FX15	Sets the delay timer to VX.
;------------------------------------------------------------------------------
FX3:	cp	15h
	jr	nz,FX4
	; set delay timer
	push	hl
	dec	hl
	call	readRegisterA
	ld	a,(hl)
	ld	(delayTimer),a
	pop	hl
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;FX18	Sets the sound timer to VX.
;------------------------------------------------------------------------------
FX4:	cp	18h
	jr	nz,FX5
	; Set Soundtimer
	dec	hl
	ld	a,(hl)
	and	15
	ex	de,hl
	ld	c,a
	ld	b,0
	ld	hl,registers
	add	hl,bc
	ld	a,(hl)
	ld	(soundTimer),a
	ex	de,hl
	cp	0
	push	hl
	call	nz, c8_sndon
	pop	hl
	inc	hl
	inc	hl
	jp	main
	
;------------------------------------------------------------------------------
;FX07	Sets VX to the value of the delay timer.
;------------------------------------------------------------------------------
FX5:	cp	07h
	jr	nz,FX6
	; set Vx=delay timer
	push	hl
	dec	hl
	call	readRegisterA
	ld	a,(delayTimer)
	ld	(hl),a
	pop	hl
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;FX0A	A key press is awaited, and then stored in VX.
;------------------------------------------------------------------------------
FX6:	cp	0Ah
	jr	nz,FX7
	; wait for key press, store code in Vx
	push	hl
	call	c8_waitkey
	pop	hl
	ex	de,hl
	dec	de
	ex	af, af'		; A sichern
	ld	a,(de)
	call	readRegister
	ex	af, af'
	ld	(hl),a
	ex	de,hl
	inc	hl
	inc	hl	
	jp	main
FX7:	cp	65h
	jr	nz,FX8
;------------------------------------------------------------------------------
;FX65	Fills V0 to VX with values from memory starting at address I.[4]
;------------------------------------------------------------------------------
	; Read V0 to Vx from [I] to [I+x]
	push	hl
	dec	hl
	ld	a,(hl)
	and	00001111b
	ld	c,a
	ld	hl,(registerI)
	ld	de,(baseAddress)
	add	hl,de
	ld	de,registers
FX7a:	inc	c
	ld	b,0
	ld	a,c
	ldir
	ld	c,a
	ld	hl,(registerI)
	add	hl,bc
	dec	hl
	ld	(registerI),hl
	pop	hl
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;FX55	Stores V0 to VX in memory starting at address I.[4]
;------------------------------------------------------------------------------
FX8:	cp	55h
	jr	nz,FX9
	; Store V0 to Vx in [I] to [I+x]
	push	hl
	dec	hl
	ld	a,(hl)
	and	00001111b
	ld	c,a
	ld	hl,(registerI)
	ld	de,(baseAddress)
	add	hl,de
	ld	de,registers
	ex	de,hl
	jr	FX7a

;------------------------------------------------------------------------------
;FX29	Sets I to the location of the sprite for the character in VX. Characters 0-F (in hexadecimal) are represented by a 4x5 font.
;------------------------------------------------------------------------------
FX9:	;cp	29h
	;jr	nz,FXA
	; Set I to 5 byte sprite for value in Vx
	dec	hl
	ld	a,(hl)
	ex	de,hl
	call	readRegister
	ld	a,(hl)
	add	a,a	; x2
	add	a,(hl)	; x3
	add	a,(hl)	; x4
	add	a,(hl)	; x5
	ld	c,a
	ld	hl,numericSprites
	add	hl,bc
	ld	bc,(baseAddress)
	sbc	hl,bc
	ld	(registerI),hl
	ex	de,hl
	inc	hl
	inc	hl
	jp	main

; System instructions (0nnn)
group0:	inc	hl
	ld	a,(hl)
;------------------------------------------------------------------------------
;00EE	Returns from a subroutine.
;------------------------------------------------------------------------------
	cp	0EEh
	jr	nz,group0_cls
	; Return
	ld	hl,(stackPointer)
	dec	hl
	ld	d,(hl)
	dec	hl
	ld	e,(hl)
	ld	(stackPointer),hl
	ex	de,hl
	jp	main

;------------------------------------------------------------------------------
;00E0	Clears the screen.
;------------------------------------------------------------------------------
group0_cls:
	cp	0E0h
	jr	nz,invalid	; exit in unrecognized 0hxxx instruction
	call	setScreen
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;0NNN	Calls RCA 1802 program at address NNN.
;------------------------------------------------------------------------------
invalid:
	ld	hl,invalid_text
	jr	error
stackError:
	ld	hl,stack_text
error:	jp	c8_error
invalid_text:
	db	"Invalid",0
stack_text:
	db	"Stack",0


;------------------------------------------------------------------------------
;1NNN	Jumps to address NNN.
;------------------------------------------------------------------------------
; Jump to address
group1:	ld	a,(hl)
	and	00001111b
	ld	d,a
	inc	hl
	ld	e,(hl)
	ld	hl,(baseAddress)
	add	hl,de
	jp	main

;------------------------------------------------------------------------------
;2NNN	Calls subroutine at NNN.
;------------------------------------------------------------------------------
; Call address
group2:	ld	a,(hl)
	and	00001111b
	ld	b,a
	inc	hl
	ld	c,(hl)
	inc	hl
	ex	de,hl
	ld	hl,(stackPointer)
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	ld	(stackPointer),hl
	ld	hl,(baseAddress)
	add	hl,bc
	jp	main

;------------------------------------------------------------------------------
;3XNN	Skips the next instruction if VX equals NN.
;------------------------------------------------------------------------------
; Skip next instruction if register x is equal to value b
group3:	ld	a,(hl)
	ex	de,hl
	call	readRegister
	ld	a,(hl)
	ex	de,hl
	inc	hl
	cp	(hl)
	inc	hl
	jp	nz,main
	inc	hl
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;4XNN	Skips the next instruction if VX doesn't equal NN.
;------------------------------------------------------------------------------
; Skip next instruction if register x in not equal to value b
group4:	ld	a,(hl)
	ex	de,hl
	call	readRegister
	ld	a,(hl)
	ex	de,hl
	inc	hl
	cp	(hl)
	inc	hl
	jp	z,main
	inc	hl
	inc	hl
	jp	main


;------------------------------------------------------------------------------
;5XY0	Skips the next instruction if VX equals VY.
;------------------------------------------------------------------------------
; Skip next instruction if register x is equal to register y
group5:	push	hl
	call	readRegisterA
	ex	de,hl
	pop	hl
	inc	hl
	push	hl
	ld	a,(hl)
	call	readRegisterHigh
	ld	a,(hl)
	ex	de,hl
	cp	(hl)
	pop	hl
	inc	hl
	jp	nz,main
	inc	hl
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;6XNN	Sets VX to NN.
;------------------------------------------------------------------------------
; Load register x with byte b (6xkk)
group6:	ld	a,(hl)
	ex	de,hl
	call	readRegister
	ex	de,hl
	inc	hl
	ld	a,(hl)
	ld	(de),a
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;7XNN	Adds NN to VX.
;------------------------------------------------------------------------------
; Add register x with byte b
group7:	ld	a,(hl)
	ex	de,hl
	call	readRegister
	ld	a,(hl)
	ex	de,hl
	inc	hl
	add	a,(hl)
	ld	(de),a
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;8XY0	Sets VX to the value of VY.
;8XY1	Sets VX to VX or VY.
;8XY2	Sets VX to VX and VY.
;8XY3	Sets VX to VX xor VY.
;8XY4	Adds VY to VX. VF is set to 1 when there's a carry, and to 0 when there isn't.
;8XY5	VY is subtracted from VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
;8XY6	Shifts VX right by one. VF is set to the value of the least significant bit of VX before the shift.[2]
;8XY7	Sets VX to VY minus VX. VF is set to 0 when there's a borrow, and 1 when there isn't.
;8XYE	Shifts VX left by one. VF is set to the value of the most significant bit of VX before the shift.[2]
;------------------------------------------------------------------------------
group8:	ld	a,(hl)
	and	00001111b
	ld	c,a
	ld	b,0
	ld	ix,registers
	add	ix,bc		; ix->registerA
	inc	hl
	ld	a,(hl)
	ex	de,hl
	call	readRegisterHigh
	ld	a,(hl)
	push	af
	ld	hl,group8_table
	ld	a,(de)
	and	00000111b
	ld	c,a
	add	hl,bc
	ld	a,(hl)
	ld	l,a
	ld	h,b
	ld	bc,group8_off
	add	hl,bc
	pop	af
	ld	bc,group8_cont
	push	bc
	jp	(hl)
group8_cont:
	ld	(ix),a
	ld	a,1
	jr	c,group8_c
	xor	a
group8_c:
	ld	(registerF),a
	ex	de,hl
	inc	hl
	jp	main

group8_table:
	db	load_RR-group8_off	; 8xx0 000
	db	or_RR-group8_off	; 8xx1 001
	db	and_RR-group8_off	; 8xx2 010
	db	xor_RR-group8_off	; 8xx3 011
	db	add_RR-group8_off	; 8xx4 100
	db	sub_RR-group8_off	; 8xx5 101
	db	shr_RR-group8_off	; 8xx6 110	(also shl_RR if 0Eh)
	db	subn_RR-group8_off	; 8xx7 111

group8_off:
load_RR:
	ret

or_RR:	or	(ix)
	ret

and_RR:	and	(ix)
	ret

xor_RR:	xor	(ix)
	ret

add_RR:	add	a,(ix)
	ret

sub_RR:	neg
	add	a,(ix)
	ret

shr_RR:	ld	a,(de)
	bit	3,a
	jr	nz,shl_RR
	ld	a,(ix)
	rra
	ret

shl_RR:	ld	a,(ix)
	rla
	ret

subn_RR:
	sub	(ix)
	ccf
	ret

;------------------------------------------------------------------------------
;9XY0	Skips the next instruction if VX doesn't equal VY.
;------------------------------------------------------------------------------
; skip next instruction if register x is not equal to register y
group9:	push	hl
	call	readRegisterA
	ex	de,hl
	pop	hl
	inc	hl
	push	hl
	ld	a,(hl)
	call	readRegisterHigh
	ld	a,(hl)
	ex	de,hl
	cp	(hl)
	pop	hl
	inc	hl
	jp	z,main
	inc	hl
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;ANNN	Sets I to the address NNN.
;------------------------------------------------------------------------------
; Load register I with word
groupA:	ld	a,(hl)
	and	00001111b
	ld	d,a
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	(registerI),de
	jp	main

;------------------------------------------------------------------------------
;BNNN	Jumps to the address NNN plus V0.
;------------------------------------------------------------------------------
; Jump to address + register0
groupB:	ld	a,(hl)
	and	00001111b
	ld	d,a
	inc	hl
	ld	e,(hl)
	ld	hl,(registers)
	ld	h,0
	add	hl,de
	ld	de,(baseAddress)
	add	hl,de
	jp	main

;------------------------------------------------------------------------------
;CXNN	Sets VX to a random number and NN.
;------------------------------------------------------------------------------
; register x = random number & byte
groupC:	ld	a,r
	rra
	ld	bc,(randomNum)
	add	a,c
	ld	(randomNum),a
	ld	a,(hl)
	and	00001111b
	push	hl
	ld	e,a
	ld	d,0
	ld	hl,registers
	add	hl,de
	ex	de,hl
	pop	hl
	inc	hl
	ld	a,(hl)
	and	c
	ld	(de),a
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;DXYN	Draws a sprite at coordinate (VX, VY) that has a width of 8 pixels and a 
;       height of N pixels. Each row of 8 pixels is read as bit-coded (with the most 
;       significant bit of each byte displayed on the left) starting from memory 
;       location I; I value doesn't change after the execution of this instruction. As 
;       described above, VF is set to 1 if any screen pixels are flipped from set to 
;       unset when the sprite is drawn, and to 0 if that doesn't happen.
;------------------------------------------------------------------------------
; Draw sprite stored at [I] to Vx,Vy with hight N (#DXYN)
groupD:	ld	a,(hl)
	ex	de,hl
	call	readRegister
	ld	a,(hl)
	and	63
	ex	af,af'		; x coordinate in i
	inc	de
	ld	a,(de)
	call	readRegisterHigh
	ld	a,(hl)		; y coordinate in c
	and	31
	;add	a,(64/2)-(32/2)
	ld	c,a
	ex	de,hl
	ld	ix,(registerI)	; pointer in ix
	ld	de,(baseAddress)
	add	ix,de
	ld	a,(hl)
	and	00001111b
	ld	b,a		; height N in b
;
	push	hl
	xor	a
	ld	(registerF),a
	ld	h,a		; 0
	ld	l,c		; hl := y
	ld	e,l		; 
	ld	c,0
	ex	af,af'		; x-Koordinate
	cp	64-8		; Rand erreicht?
	jr	c,sl0a
	ld	c,0FFh
sl0a:	;add	a,(96/2)-(64/2)
	ld	d,h		; 0, de := y
	add	hl,hl		; hl
	add	hl,hl		; hl
	add	hl,hl		; hl := 8*y
	ld	e,a		; de := x
	and	7
	push	af
	srl	e
	srl	e
	srl	e		; x/8
	add	hl,de
	ld	de,gbuf
	add	hl,de		; hl := Pos. im BWS 8*y+x/8
;	
sl1:	ld	d,(ix)		; auszugebendes Byte 
	ld	e,0
	pop	af		; x and 7
	push	af
	or	a
	jr	z,sl3
sl2:	srl	d
	rr	e
	dec	a
	jr	nz,sl2
sl3:	ld	a,(hl)
	and	d
	call	nz,setCarry
	ld	a,(hl)
	xor	d
	ld	(hl),a
	inc	hl
	ld	a,c
	or	a
	jr	nz,sl4
	ld	a,(hl)
	and	e
	call	nz,setCarry
	ld	a,(hl)
	xor	e
	ld	(hl),a
;
sl4:	ld	de,8-1		; nächste Zeile
	add	hl,de
;	
	ex	de,hl
	ld	hl,gbuf+64*32/8	; Bufferende überschritten?
	sbc	hl,de
	jr	c,sl5
	ex	de,hl
; nächstes Byte des Sprits
	inc	ix
	djnz	sl1
; fertig
sl5:	pop	af
	pop	hl
	inc	hl
	call	c8_drawbs
	jp	main
setCarry:
	ld	a,1
	ld	(registerF),a
	ret

;
groupE:	inc	hl
	ld	a,(hl)
;------------------------------------------------------------------------------
;EX9E	Skips the next instruction if the key stored in VX is pressed.
;------------------------------------------------------------------------------
	cp	9Eh
	jr	nz,skipKey2
	; Skip next instruction if key Vx is down.
	call	checkKey
	jp	nz,main
	inc	hl
	inc	hl
	jp	main

;------------------------------------------------------------------------------
;EXA1	Skips the next instruction if the key stored in VX isn't pressed.
;------------------------------------------------------------------------------
skipKey2:
	; Skip next instruction if key Vx is up.
	call	checkKey
	jp	z,main
	inc	hl
	inc	hl
	jp	main

checkKey:
	dec	hl
	ld	a,(hl)
	inc	hl
	push	hl
	call	readRegister	; (hl) = X
	push	hl
	call	c8_testkey
	pop	hl
	cp	(hl)
	pop	hl
	inc	hl
	ret

;------------------------------------------------------------------------------
; clear screen
;------------------------------------------------------------------------------

setScreen:
	push	hl
	;CLS, Rahmen zeichnen
	call	c8_CLS
	pop	hl
	ret

;------------------------------------------------------------------------------
; ret: HL = Adr. Register
;------------------------------------------------------------------------------

readRegisterA:
	ld	a,(hl)
readRegister:
	and	00001111b
readRegister_skip:
	ld	b,0
	ld	c,a
	ld	hl,registers
	add	hl,bc
	ret

readRegisterHigh:
	and	11110000b
	rra
	rra
	rra
	rra
	jr	readRegister_skip

;------------------------------------------------------------------------------
; System-Sprite-Tabelle
;------------------------------------------------------------------------------

numericSprites:
	db	11110000b	; 0
	db	10010000b
	db	10010000b
	db	10010000b
	db	11110000b
	db	00010000b	; 1
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	11110000b	; 2
	db	00010000b
	db	11110000b
	db	10000000b
	db	11110000b
	db	11110000b	; 3
	db	00010000b
	db	11110000b
	db	00010000b
	db	11110000b
	db	10010000b	; 4
	db	10010000b
	db	11110000b
	db	00010000b
	db	00010000b
	db	11110000b	; 5
	db	10000000b
	db	11110000b
	db	00010000b
	db	11110000b
	db	10000000b	; 6
	db	10000000b
	db	11110000b
	db	10010000b
	db	11110000b
	db	11110000b	; 7
	db	00010000b
	db	00010000b
	db	00010000b
	db	00010000b
	db	11110000b	; 8
	db	10010000b
	db	11110000b
	db	10010000b
	db	11110000b
	db	11110000b	; 9
	db	10010000b
	db	11110000b
	db	00010000b
	db	00010000b
	db	01100000b	; A
	db	10010000b
	db	11110000b
	db	10010000b
	db	10010000b
	db	11100000b	; B
	db	10010000b
	db	11100000b
	db	10010000b
	db	11100000b
	db	01100000b	; C
	db	10000000b
	db	10000000b
	db	10000000b
	db	01100000b
	db	11100000b	; D
	db	10010000b
	db	10010000b
	db	10010000b
	db	11100000b
	db	11110000b	; E
	db	10000000b
	db	11100000b
	db	10000000b
	db	11110000b
	db	11110000b	; F
	db	10000000b
	db	11100000b
	db	10000000b
	db	10000000b


; Speicher 
sram	equ	$

registers	ds	15		; 16 gprs V0..VE
registerF	ds	1		; VF, last register of the 16 gprs
registerI	ds	2		; Index register 2 bytes
delayTimer	ds	1		; Delay Timer register
soundTimer	ds	1		; Sound Timer register
randomNum	ds	1		; Random number variable
baseAddress	ds	2		; base address 2 bytes
stackPointer	ds	2		; stack pointer 2 bytes
;delayDelay	ds	1 	
;curfat		equ	sram+26		; 2 bytes
;file		equ	sram+28		; 2 bytes
;progsize	equ	sram+30		; 2 bytes
stack		ds	32		; 32 Byte


;		align	100h		; f. debug
gbuf		ds 	64*32/8  + 1	; BWS, 256 Byte

;RAMB		equ	2000h		; Arbeitsspeicher für CHIP8, 0E00h Bytes

