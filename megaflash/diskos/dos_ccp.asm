;------------------------------------------------------------------------------
; Z9001
; (c) V. Pohlers 2012
; letzte Änderung 19.02.2012 19:16:56
;------------------------------------------------------------------------------
; CP/M-Disketten unter OS
; DRIVE,DIR,DELETE-Kommandos
;------------------------------------------------------------------------------

		cpu	z80

	section	ccp
	
		public	FILLFCB0a, comfcb, INITCCP,SETDISK

singleprg	equ	0

;-----------------------------------------------------------------------------
; DIR,DELETE,TYPE nach CP/M-CCP-Quellcode
;------------------------------------------------------------------------------

COMBUF		equ	100h

; BDOS		EQU	4006H		;primary bdos entry point
;;DISKo		EQU	BDOS+00DE8h	;disk address for current disk
;;BIOS		EQU	BDOS-6+0E00h
SELDSKF		equ	BIOS+3*9	;select disk function


BUFF		EQU	0080H		;default buffer
;FCB		EQU	005CH		;default file control block
;                               	
RCHARF		EQU	1		;read character function
PCHARF		EQU	2		;print character function
;PBUFF		EQU	9		;print buffer function
;RBUFF		EQU	10		;read buffer function
BREAKF		EQU	11		;break key function
;LIFTF		EQU	12		;lift head function (no operation)
INITF		EQU	13		;initialize bdos function
SELF		EQU	14		;select disk function
OPENF		EQU	15		;open file function
CLOSEF		EQU	16		;close file function
SEARF		EQU	17		;search for file function
SEARNF		EQU	18		;search for next file function
DELF		EQU	19		;delete file function
DREADF		EQU	20		;disk read function
DWRITF		EQU	21		;disk write function
MAKEF		EQU	22		;file make function
;RENF		EQU	23		;rename file function
;LOGF		EQU	24		;return login vector
CSELF		EQU	25		;return currently selected drive number
DMAF		EQU	26		;set dma address
USERF		EQU	32		;set user number
                                	
;	special characters      	
CR		EQU	13		;carriage return
LF		EQU	10		;line feed
LA		EQU	5FH		;left arrow
EOFILE		EQU	1AH		;end of file
                                	
;	special fcb flags       	
;ROFILE		EQU	9		;read only file
SYSFILE		EQU	10		;system file flag


; Z9001
OCRLF:		EQU	0F2FEH
OUTA:		EQU	0F305H
OSPAC:		EQU	0F310H

;-----------------------------------------------------------------------------
; OS-Rahmen für Kommandos

	if singleprg

		align	100h
	
		jp	DRIVE
		db	"DRIVE   ",0
		jp	DIRECT
		db	"DDIR    ",0
		jp	ERASE
		db	"DDELETE ",0
	;;	jp	DLOAD
	;;	db	"DLOAD   ",0
	;;	jp	DSAVE
	;;	db	"DSAVE   ",0
		db	0

		jp	INITCCP
		jp	fillfcb0a
		dw	comfcb

	else

	public	DRIVE, DIRECT, ERASE
	
	endif

;-----------------------------------------------------------------------------

; ext. CCP-Funktionen
; initialisierung
; FCB aufbereiten
; nötige Befehle: DIR, DEL, DRIV, (LOAD, SAVE)


;	utility procedures
;
;
PRINT:		;print string starting at b,c until next 00 entry
		PUSH	BC
		CALL	OCRLF
		POP	HL		;now print the string
PRIN0:		LD	A,(HL)
		OR	A
		RET	Z		;stop on 00
		INC	HL
		PUSH	HL		;ready for next
		CALL	OUTA
		POP	HL		;character printed
		JP	PRIN0		;for another character

NOFILE:		;print no file message
		LD	BC,NOFMSG
		JP	PRINT
NOFMSG:		DB	"NO FILE",0
;

INITIALIZE:	LD	C,INITF
		JP	BDOS
;
SELECT:		LD	E,A
		LD	C,SELF
		JP	BDOS

;
CSELECT:	;get the currently selected drive number to reg-A
		LD	C,CSELF
		JP	BDOS
;
SETDMA:		;set dma address to d,e
		LD	C,DMAF
		JP	BDOS
;
RESETDISK:	;return to original disk after command
		LD	A,(SDISK)
		OR	A
		RET	Z		;no action if not selected
		DEC	A
		LD	HL,CDISK	
		CP	(HL)
		RET	Z		;same disk
		LD	A,(CDISK)
		JP	SELECT
;


;------------------------------------------------------------------------------
; FILLFCB
;------------------------------------------------------------------------------

; fcb scan and fill subroutine (entry is at fillfcb below)
;fill the comfcb, indexed by A (0 or 16)
;subroutines
DELIM:		;look for a delimiter
		LD	A,(DE)
		OR	A
		RET	Z		;not the last element
		CP	' '
		JP	C,COMERR	;non graphic
		RET	Z		;treat blank as delimiter
		CP	'='
		RET	Z
		CP	LA
		RET	Z		;left arrow
		CP	'.'
		RET	Z
		CP	':'
		RET	Z
		CP	';'
		RET	Z
		CP	'<'
		RET	Z
		CP	'>'
		RET	Z
		RET			;delimiter not found

DEBLANK:	;deblank the input line
		LD	A,(DE)
		OR	A
		RET	Z		;treat end of line as blank
		CP	' '
		RET	NZ
		INC	DE
		Jr	DEBLANK
;

ADDH:		;add a to h,l
		ADD	A,L
		LD	L,A
		RET	NC
		INC	H
		RET

; hier erweitert um die Initialisierung aus CCP, da erster Aufruf der Einzel-Programme
INITCCP:
;;		CALL	INITIALIZE	;0ffh in accum if $ file present
		ld	a,(DISKo)	;initial disk aus BDOS 0004
		LD	(CDISK),A	;clears user code nibble
		CALL	SELECT
; Init aus CCP:
		LD	DE,BUFF
		CALL	SETDMA		;default dma address at buff
;;		CALL	CSELECT
;;		LD	(CDISK),A	;current disk number saved


		;equivalent to fillfcb(0)
FILLFCB0a:	
		LD	HL,BUFF+2
		ld	(COMADDR),HL

		ld	a,(DISKo)	;initial disk aus BDOS 0004
		LD	(CDISK),A	;clears user code nibble

FILLFCB0:	LD	A,0
FILLFCB:	LD	HL,COMFCB
		CALL	ADDH
		PUSH	HL
		PUSH	HL		;fcb rescanned at end
		XOR	A
		LD	(SDISK),A	;clear selected disk (in case A:...)
		LD	HL,(COMADDR)
		EX	DE,HL		;command address in d,e
		CALL	DEBLANK		;to first non-blank character
		EX	DE,HL
		LD	(STADDR),HL	;in case of errors
		EX	DE,HL
		POP	HL		;d,e has command, h,l has fcb address
		;look for preceding file name A: B: ...
		LD	A,(DE)
		OR	A
		JP	Z,SETCUR0	;use current disk if empty command
		SBC	A,'A'-1
		LD	B,A		;disk name held in b if : follows
		INC	DE
		LD	A,(DE)
		CP	':'
		Jr	Z,SETDSK	;set disk name if :
		;set current disk
		DEC	DE		;back to first character of command
SETCUR0:	LD	A,(CDISK)
		LD	(HL),A
		Jr	SETNAME
SETDSK		;set disk to name in register b
		LD	A,B
		LD	(SDISK),A	;mark as disk selected
		LD	(HL),B
		INC	DE		;past the :
SETNAME		;set the file name field
		LD	B,8		;file name length (max)
SETNAM0:	CALL	DELIM
		Jr	Z,PADNAME	;not a delimiter
		INC	HL
		CP	'*'
		Jr	NZ,SETNAM1	;must be ?'s
		LD	(HL),'?'
		Jr	SETNAM2		;to dec count
SETNAM1:	LD	(HL),A		;store character to fcb
		INC	DE
SETNAM2:	DEC	B		;count down length
		Jr	NZ,SETNAM0
		;end of name, truncate remainder
TRNAME:		CALL	DELIM
		Jr	Z,SETTY		;set type field if delimiter
		INC	DE
		Jr	TRNAME
PADNAME:	INC	HL
		LD	(HL),' '
		DEC	B
		Jr	NZ,PADNAME
SETTY		;set the type field
		LD	B,3
		CP	'.'
		Jr	NZ,PADTY	;skip the type field if no .
		INC	DE		;past the ., to the file type field
SETTY0		;set the field from the command buffer
		CALL	DELIM
		Jr	Z,PADTY
		INC	HL
		CP	'*'
		Jr	NZ,SETTY1
		LD	(HL),'?'	;since * specified
		Jr	SETTY2
SETTY1:		;not a *, so copy to type field
		LD	(HL),A
		INC	DE
SETTY2:		;decrement count and go again
		DEC	B
		Jr	NZ,SETTY0
		;end of type field, truncate
TRTYP:		;truncate type field
		CALL	DELIM
		Jr	Z,EFILL
		INC	DE
		Jr	TRTYP
PADTY:		;pad the type field with blanks
		INC	HL
		LD	(HL),' '
		DEC	B
		Jr	NZ,PADTY
EFILL:		;end of the filename/filetype fill, save command address
		;fill the remaining fields for the fcb
		LD	B,3
EFILL0:		INC	HL
		LD	(HL),0
		DEC	B
		Jr	NZ,EFILL0
		EX	DE,HL
		LD	(COMADDR),HL	;set new starting point
		;recover the start address of the fcb and count ?'s
		POP	HL
		LD	BC,11	;b=0, c=8+3
SCNQ:		INC	HL
		LD	A,(HL)
		CP	'?'
		JP	NZ,SCNQ0
		;? found, count it in b
		INC	B
SCNQ0:		DEC	C
		Jr	NZ,SCNQ
		;number of ?'s in c, move to a and return with flags set
		LD	A,B
		OR	A
		RET


;------------------------------------------------------------------------------

SETDISK:	;change disks for this command, if requested
		XOR	A
		LD	(COMFCB),A	;clear disk name from fcb
		LD	A,(SDISK)
		OR	A
		RET	Z		;no action if not specified
		DEC	A
		LD	HL,CDISK	
		CP	(HL)
		RET	Z		;already selected
		JP	SELECT

;------------------------------------------------------------------------------

COMERR:
;error in command string starting at position
;'staddr' and ending with first delimiter
		CALL	oCRLF		;space to next line
		LD	HL,(STADDR)	;h,l address first to print
COMERR0:	;print characters until blank or zero
		LD	A,(HL)
		CP	' '
		Jr	Z,COMERR1	; not blank
		OR	A
		Jr	Z,COMERR1	; not zero, so print it
		CALL	OUTA
		INC	HL
		Jr	COMERR0		; for another character
COMERR1:	;print question mark
		LD	A,'?'
		CALL	OUTA
		CALL	OCRLF
		JP	0		;restart with next command		??? besser GOCPM oder RET


;------------------------------------------------------------------------------
; DDIR directory search
;------------------------------------------------------------------------------

ADDHCF:		;buff + a + c to h,l followed by fetch
		LD	HL,BUFF
		ADD	A,C
		CALL	ADDH
		LD	A,(HL)
		RET

DCNT:		DS	1	;disk directory count (used for error codes)

BDOSINR:	CALL	BDOS
		LD	(DCNT),A
		INC	A
		RET

SEARCHCOM:	;search for comfcb file
		LD	DE,COMFCB
		;search for the file given by d,e
		LD	C,SEARF
		Jr	BDOSINR

SEARCHN:	;search for the next occurrence of the file given by d,e
		LD	C,SEARNF
		Jr	BDOSINR
;

BREAKKEY:	;check for a character ready at the console
		LD	C,BREAKF
		CALL	BDOS
		OR	A
		RET	Z
		LD	C,RCHARF
		CALL	BDOS		;character cleared
		OR	A
		RET
;
; ------------
;
DIRECT:		CALL	INITCCP		;comfcb gets file name
		CALL	SETDISK		;change disk drives if requested
;
		LD	HL,COMFCB+1
		LD	A,(HL)		;may be empty request
		CP	' '
		Jr	NZ,DIR1		;skip fill of ??? if not blank
		;set comfcb to all ??? for current disk
		LD	B,11		;length of fill ????????.???
DIR0:		LD	(HL),'?'
		INC	HL
		DEC	B
		Jr	NZ,DIR0
		;not a blank request, must be in comfcb
DIR1:		LD	E,0
		PUSH	DE		;E counts directory entries
		CALL	SEARCHCOM	;first one has been found
		CALL	Z,NOFILE	;not found message
DIR2:		Jr	Z,ENDIR
		;found, but may be system file
		LD	A,(DCNT)	;get the location of the element
		RRCA
		RRCA
		RRCA
		AND	1100000B
		LD	C,A
		;c contains base index into buff for dir entry
		LD	A,SYSFILE
		CALL	ADDHCF		;value to A
		RLA
		Jr	C,DIR6		;skip if system file
		;c holds index into buffer
		;another fcb found, new line?
		POP	DE
		LD	A,E
		INC	E
		PUSH	DE
		;e=0,1,2,3,...new line if mod 4 = 0
		AND	01B
		PUSH	AF		;and save the test
		JP	NZ,DIRHDR0	;header on current line
		CALL	OCRLF
		PUSH	BC
		CALL	CSELECT
		POP	BC
		;current disk in A
		ADD	A,'A'
		CALL	OUTA
		LD	A,':'
		CALL	OUTA
		Jr	DIRHDR1		;skip current line hdr
DIRHDR0:	CALL	OSPAC		;after last one
		LD	A,':'
		CALL	OUTA
DIRHDR1:	CALL	OSPAC
		;compute position of name in buffer
		LD	B,1		;start with first character of name
DIR3:		LD	A,B
		CALL	ADDHCF		;buff+a+c fetched
		AND	7FH		;mask flags
		;may delete trailing blanks
		CP	' '
		Jr	NZ,DIR4		;check for blank type
		POP	AF
		PUSH	AF		;may be 3rd item
		CP	3
		Jr	NZ,DIRB		;place blank at end if not
		LD	A,9
		CALL	ADDHCF		;first char of type
		AND	7FH
		CP	' '
		Jr	Z,DIR5
		;not a blank in the file type field
DIRB:		LD	A,' '		;restore trailing filename chr
DIR4:		CALL	OUTA		;char printed
		INC	B
		LD	A,B
		CP	12
		Jr	NC,DIR5
		;check for break between names
		CP	9
		Jr	NZ,DIR3		;for another char
		;print a blank between names
		push	bc
		CALL	OSPAC
		pop	bc
		Jr	DIR3
DIR5:		;end of current entry
		POP	AF		;discard the directory counter (mod 4)
DIR6:		CALL	BREAKKEY	;check for interrupt at keyboard
		Jr	NZ,ENDIR	;abort directory search
		CALL	SEARCHN
		Jr	DIR2		;for another entry
ENDIR:		;end of directory scan
		POP	DE		;discard directory counter
;
		call	RESETDISK
		jp	ENDCOM1
		;JP	RETCOM
;
;
;------------------------------------------------------------------------------
;DDEL
;------------------------------------------------------------------------------

ERASE:
		CALL	INITCCP		;cannot be all ???'s
		CP	11
		JP	NZ,ERASEFILE
		;erasing all of the disk
		LD	BC,ERMSG
		CALL	PRINT
		LD	c,1		; CONSI
		call	5
		AND	A, 0DFH		;NUR GROSSBUCHSTABEN
		CP	'Y'
		JP	NZ, RETCOM
		;ok, erase the entire diskette
ERASEFILE:
		CALL	SETDISK
		LD	DE,COMFCB
		;delete the file given by d,e
		LD	C,DELF
		CALL	BDOS
		INC	A		;255 returned if not found
		CALL	Z,NOFILE	;no file message if so
		JP	RETCOM
;
ERMSG:		DB	"ALL (Y/N)?",0
;
;------------------------------------------------------------------------------

RETCOM:		;reset disk before end of command check
		CALL	RESETDISK
;
ENDCOM:		;end of intrinsic command
		CALL	FILLFCB0	;to check for garbage at end of line
		LD	A,(COMFCB+1)
		SUB	' '
		ld	a,0
		LD	HL,SDISK
		OR	(HL)
;0 in accumulator if no disk selected, and blank fcb
		JP	NZ,COMERR
ENDCOM1:	CALL	OCRLF
		or	a
		RET

;------------------------------------------------------------------------------
; DDRIVE
; Laufwerkswechsel
;------------------------------------------------------------------------------

DRIVE:		
		CALL	FILLFCB0a
;load user function and set up for execution
		LD	A,(COMFCB+1)
		CP	' '
		JP	NZ,COMERR
;no file name, but may be disk switch
		LD	A,(SDISK)	;selected disk for current operation
		OR	A
		RET	Z		;no disk name if 0
		DEC	A
; erst mal in BIOS testen, ob es das LW überhaupt gibt		
		LD	C,A
		call	SELDSKF		; BIOS+3*9	;select disk function
		LD	a,h
		or	l
		jr	nz, DRIVE1	;ok
		LD	BC,DRIVMSG	;Fehler
		CALL	PRINT
		JP	ENDCOM
		
DRIVE1:		ld	a,(SDISK)
		dec	a
		LD	(CDISK),A	;current disk
		LD	(DISKo),A	;user/disk BDOS 0004h
		CALL	SELECT	; SELECT nur, wenn auch Laufwerk ex.
		JP	ENDCOM
DRIVMSG:	DB	"NO DRIVE",0

;-----------------------------------------------------------------------------

;	data areas
;	command file control block
COMFCB:		DS	32	;fields filled in later
COMREC:		DS	1	;current record to read/write
CDISK:		DS	1	;current disk
SDISK:		DS	1	;selected disk for current operation

STADDR:		DS	2	;starting address of current fillfcb request
BPTR:		DS	1	;buffer pointer
COMADDR:	DW	82h	;address of next to char to scan

;-----------------------------------------------------------------------------

	endsection
