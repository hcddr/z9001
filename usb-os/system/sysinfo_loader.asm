; Loader für Sysinfo
; vp 02.04.2020
; 05.10.2021 Umstellung auf ZX7 als Nachfolger von bitbuster_extreme

; Sysinfo = RAM-Programm 300h-1F0Fh (7k)
; wir haben aber nur 4k frei
; deshalb hier mit LZ77 ZX7 gepackt
; sonst würde LDIR reichen

; kc2bin.pl sysinfo.tap
; zx7 sysinfo.bin

	cpu	z80
	
	
	org	0D000h
	
	jp	loader
	db	"SYSINFO0",0
	db	0
	
loader:	ld	hl,bins
	ld	de,300h
	push	de		; Startadresse merken
	
	; kopieren
;;	ld	bc,bine-bins
;;	ldir

	call	dzx7_standard
	
	; und starten
	pop	hl
	jp	(hl)
	
	include	dzx7_standard.asm
	
bins
	binclude	SYSINFO.BIN.zx7
bine
