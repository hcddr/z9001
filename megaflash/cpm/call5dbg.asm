	cpu	z80
	
		org	7000h

;-----------------------------------------------------------------------------
; neuer BOS-Call
;-----------------------------------------------------------------------------

BOS		equ	0F314h		; orig. Call 5
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H

DMA		equ	001Bh
FCB		equ	005Ch
BLNR		equ	FCB+15
LBLNR		equ	FCB+16

rst_sbos	equ	28h		;der RST für den Sprungverteiler

;;	0	;OUTHX	Ausgabe (A) hexa
;;	1	;OUTHL	Ausgabe (HL) hexa
;;	2	;WAIT	Unterbrechung Lauf
;;	3	;color	Vordergrundfarbe (E)
;;	4	;CPROM	Suchen Namen
;;	5	;FMOV	FA-Programm in Speicher kopieren
;;	6	;FRUN	FA-Programm starten
;;	7	;KDOPAR	Kommandoparameter aufbereiten
;;	8	;INHEX	Konvertierung ASCII-Hex ab (DE) --> (HL)
;;	9	;PRST7	Ausgabe String bis Bit7=1


		align	100h
		
		jp	initdos
		db	"CALL5DBG",0
		jp	exitdos
		db	"NODBG   ",0
		db	0

;-----------------------------------------------------------------------------
; CAOS
;-----------------------------------------------------------------------------
	
jpbdos		jp	BOS

exitdos:	ld	hl, (jpbdos+1)
		ld	(6), hl
		ret

;-----------------------------------------------------------------------------
; DOS
;-----------------------------------------------------------------------------

initdos:
		ld	hl,(6)
		ld	(jpbdos+1), hl
		
		ld	hl, CBDOS
		ld	(6), hl
		ret

;-----------------------------------------------------------------------------
; neuer CALL 5-Händler
;-----------------------------------------------------------------------------
CBDOS:		push	af
		ld	a,c
		cp	13		; OPENR
		jr	c, CBDOS1
		jp	z, ca
		cp	14		; CLOSR
		jp	z, ca
		cp	15		; OPENW
		jp	z, ca
		cp	16		; CLOSW
		jp	z, ca
		cp	20		; READS
		jp	z, ca
		cp	21		; WRITS
		jp	z, ca
		cp	33		; RRAND
		jp	z, ca
CBDOS1:		pop	af
		jp	jpbdos

;

ca:		push	bc
		push	de
		push	hl

		cp	13
		ld	de, sOPENR
		jr	z,ca1
		cp	14
		ld	de, sCLOSR
		jr	z,ca1
		cp	15
		ld	de, sOPENW
		jr	z,ca1
		cp	16
		ld	de, sCLOSW
		jr	z,ca1
		cp	20
		ld	de, sREADS
		jr	z,ca1
		cp	21
		ld	de, sWRITS
		jr	z,ca1
		cp	33
		ld	de, sRRAND
		jr	z,ca1
ca1:		ld	c,9		; anzeige Funktionsname
		call	5
		;
		call	PRST7
		db	" DMA",' '+80h
		ld	hl,(DMA)
		call	OUTHL
		;
		call	PRST7
		db	" BLNR",' '+80h
		ld	a,(BLNR)
		call	OUTHX
		;
		call	PRST7
		db	" LBLNR",' '+80h
		ld	a,(LBLNR)
		call	OUTHX
		
		call	ocrlf

		pop	hl
		pop	de
		pop	bc
		pop	af
		jp	jpbdos	


sOPENR:		db	"OPENR",0
sCLOSR:		db	"CLOSR",0
sOPENW:		db	"OPENW",0
sCLOSW:		db	"CLOSW",0
sREADS:		db	"READS",0
sWRITS:		db	"WRITS",0
sRRAND:		db	"RRAND",0
	

;
;-------------------------------------------------------------------------------
;Ausgabe String bis Bit7=1
;-------------------------------------------------------------------------------
;
PRST7:		EX	(SP),HL			;Adresse hinter CALL
PRS1:		LD	A,(HL)
		INC	HL
		PUSH	AF
		and	7FH
		CALL	OUTA
		POP	AF
		BIT	7,A			;Bit7 gesetzt?
		JR	Z, PRS1			;nein
		EX	(SP),HL			;neue Returnadresse
		RET

;OUTHL Ausgabe (HL) hexa
;
OUTHL:		LD	A,H
		CALL	OUTHX
		LD	A,L
;
;                               
;OUTHX Ausgabe (A) hexa         
;                               
OUTHX:		PUSH	AF      
		RLCA            
		RLCA            
		RLCA            
		RLCA            
		CALL	OUTH1   
		POP	AF      
OUTH1:		AND	A, 0FH  
		ADD	A, 30H  
		CP	A, 3AH  
		JR	C, OUTH2
		ADD	A, 07H  
OUTH2:		CALL	OUTA    
		RET             
;                               
		end

;; normal Cassette
;; 
;; >SAVE T1 7000,7100
;; OPENW BLNR 00 LBLNR A8
;; 
;; start tape
;; 
;;  WRITS BLNR 01 LBLNR 02
;;  WRITS BLNR 02 LBLNR 02
;;  CLOSW BLNR 03 LBLNR 02
;; 
;; VERIFY ((Y)/N)?:
;; 
;; REWIND <--
;; OPENR BLNR 00 LBLNR 02
;; 
;; start tape
;; 
;;  READS BLNR 00 LBLNR 01
;;  READS BLNR 01 LBLNR 02
;;  READS BLNR 02 LBLNR 03
;; 
;; SAVE COMPLETE
;; 
;; 03 RECORD(S) WRITTEN
;; 03 RECORD(S) CHECKED
;; 
;; >                                       
;; 
   

;; aktuell DOS 17.02.2012 15:34

;; >CALL5DBG
;; >SAVE T1 7000,7100
;; OPENW BLNR FF LBLNR 04
;;  WRITS BLNR 01 LBLNR 02
;;  WRITS BLNR 02 LBLNR 02
;;  CLOSW BLNR 03 LBLNR 02
;; 
;; VERIFY ((Y)/N)?:
;; 
;; REWIND <--
;; OPENR BLNR 00 LBLNR 02
;; READS BLNR 00 LBLNR 01
;; READS BLNR 01 LBLNR 02
;; READS BLNR 02 LBLNR 03
;; READS BLNR 03 LBLNR 04
;; 
;; SAVE COMPLETE
;; 
;; 03 RECORD(S) WRITTEN
;; 04 RECORD(S) CHECKED
;; 
;; >                                  