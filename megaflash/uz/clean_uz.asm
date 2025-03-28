; Base Address:	0000h Range: CF00h - CF80h Loaded length: 0080h
;UZ, Reass: VP 10.10.2018 

		cpu	z80

		org 0CF00h

		jp	clean
		db "CLEAN   ",0
		db    0

;aadr		equ 300h
; UZ:
;Im SRAM werden Daten auch nach dem Ausschalten des Rechners gespeichert. Diese,
;und nur diese, sollen gelöscht werden können. Ein Löschen der Daten im System-
;RAM soll nicht erfolgen. Man könnte ja auch mal während des normalen Betriebes
;den SRAM löschen wollen, und dann ist der System-RAM auch gelöscht! Nach
;Programmende sollte ein Hinweis erfolgen, daß die Aktion abgeschlossen ist. NIMM
;DOCH BITTE MEINE VERSION AUS DEM V1708P! Hier ist alles richtig!
;also:

aadr		equ 	4000h		

clean:		ld	de, aLoeschen	; "Speicher \{aadr}-E7FFH loeschen? Y/[N]:"
		ld	c, 9
		call	5
		ld	c, 1
		call	5
		sub	'Y'
		jr	nz, clean1
		dec	a
		ld	hl, aadr
		push	hl
		ld	(hl), a
		ld	bc, 0C000h-aadr-1
		ld	de, aadr+1
		ldir
		pop	hl
		ld	de, 0C000h
		ld	bc, 2800h
		ldir
		ld	de, aGeloescht	; "\r\nSRAM geloescht\r\n"
		ld	c, 9
		call	5
clean1:		;jp	0F003h
		or	a
		ret

		outradix	16
aLoeschen:	db "Speicher \{aadr}H-E7FFH loeschen? Y/[N]:",0
aGeloescht:	db 0Dh,0Ah
		db "SRAM geloescht",0Dh,0Ah,0

		end
