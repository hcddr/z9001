;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M-Modul)
; (c) V. Pohlers 2011
; letzte Änderung 25.10.2012 16:13
;------------------------------------------------------------------------------
; Info über Speicherausnutzung
; Anzahl FA-Programme: 277
; Gesamt-gepackt:  1214718
; Gesamt-Speicher: 1744575
;------------------------------------------------------------------------------

        	cpu 80C167			; Mikrocontroller mit großem Adressbereich
        	
		include	packedroms.inc
        	
groesse		set	0
gepackt		set	0 
position	set	bank_1 * 2800h
i		set	0
        	
		OUTRADIX 10
        	
        	REPT    lfdnr
i		set	i+1
id		set	"\{i}"
groesse 	set	groesse+eadr_{id}-aadr_{id}
lastposition	set	position
position 	set	bank_{id} * 2800h + pos_{id}
gepackt		set	gepackt + position - lastposition

        	ENDM
        	
		message	"Anzahl FA-Programme: \{id}"
		message	"Gesamt-gepackt:  \{gepackt}"
		message	"Gesamt-Speicher: \{groesse}"
		
		end
	