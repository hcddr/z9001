;------------------------------------------------------------------------------
; Z9001 MEGA-ROM-Modul (2.5M/3.5M-Modul)
; (c) KOMA Alexander Schön, 2005-2007
;------------------------------------------------------------------------------

		cpu z80
		org 0300h
		BINCLUDE 	"treiber1_com.bin"

;
;Zeichencodes
;
CUL:    EQU     08H 
CLS_:   EQU     0CH  
CRLF:   EQU     0A0DH
CR:     EQU     0DH  
LF:     EQU     0AH  
ROT:    EQU     0114H
GRUEN:  EQU     0214H
GELB:   EQU     0314H
BLAU:   EQU     0414H
MAGENTA:EQU     0514H
CYAN:   EQU     0614H
WHITE:  EQU     0714H


;;		org	538h
treibersammlung: 
                ld de, treibertxt
                ld c,9
                call 5

                jp 0488h


TreiberTXT:
        db cls_
        dw CRLF
        dw GELB
        db "Treiber Sammlung:"
        dw CRLF
        DB "-----------------"
        dw CRLF    
        dw CRLF
        dw gruen
        db "Aufruf z.B. mit "
        dw white
        db "ASGN LIST:=CENTR"
        dw CRLF
        dw CRLF
        dw gruen
        db "Inhalt: "
        dw CRLF
        dw CRLF 

tr_Sammlung:    
        dw blau 
        db "   SIFE"
        dw gruen
        db ", "
        dw blau
        db "SIFA"
        dw gruen
        db ", "
        dw blau
        db "CENTR"
        dw gruen   
        db ", "
        dw blau 
        db "LX86"
        dw gruen
        db ", "
        dw blau
        db "TD40"
        dw gruen
        db ", "
        dw blau
        db "BEEP"
        dw CRLF
        dw CRLF 
        dw gruen
        
        db 0

		end
