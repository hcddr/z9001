;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M-Modul)
; (c) V. Pohlers 2011
; letzte Änderung 23.12.2011
;------------------------------------------------------------------------------
; letzter Schritt
; Zerlegen und neu Zusammensetzen des ROMs passend für den Speicher des Mega-Moduls
;
; Der ROM ist 2K-scheibenweise aufgebaut: 
; Erst kommen die ersten 2K (c000-c7FF) aller BINs 0000000-0007F800,
; dann kommen ab 000800000 die nächsten 2K (c800-cFFF)
; dann kommen ab 001000000 die nächsten 2K (d000-d7FF)
; dann kommen ab 001800000 die nächsten 2K (d800-dFFF)
; dann kommen ab 002000000 die letzten 2K (e000-e7FF)
;------------------------------------------------------------------------------

; 1. ROM (1M)

        cpu 96C141			; Mikrocontroller mit großem Adressbereich
        maxmode on			; der Z80 reicht hier nicht.

        org 0000h

size	EQU 800h

t	EVAL 0

	while t < 2

counter EVAL 0

	while counter < 256

test 	eval counter*10240+size*t

		BINCLUDE  "packedRoms.bin", counter*10240+size*t, size

counter	EVAL counter+1

	endm

t	EVAL t+1
	endm

        end
