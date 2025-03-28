;------------------------------------------------------------------------------
; Bios-Include-Dateien
; die Dateien werdem mehrfach eingebunden, deshalb hier zentral
;------------------------------------------------------------------------------

	if cpa=1
		include	bioschrdrv.asm
	else		
		include	bioschrdrv_noio.asm
	endif
		include	biosrafmini.asm
		include biosrof.asm

