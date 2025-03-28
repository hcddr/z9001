		cpu	Z80

;		TITLE	'console command processor (CP/A)'
;	assembly language version of the CP/A console command processor
;
; reass, f¸r AS-Assembler V.Pohlers 15.10.2014
; 20.10.2014 Version CCP2 vom PC1715, 11.1.89 (h:\hobby\hobby0\cpa\120308 weitere versionen\cpa.tar.gz)

; segment RAM
CLKBCD:		equ	0050h		; BCD-Buffer f¸r CLK
COMREC:		equ	007Ch


; segment "ROM"
;;		org 0CC00h
BDOSR		equ	$+0806h
BIOSR		equ	$+1600h



TRAN		EQU	100H
TRANM		EQU	$
CCPLOC		EQU	$
;
;	********************************************************
;	*	Base of CCP contains the following code/data   *
;	*	ccp:	jmp ccpstart	(start with command)   *
;	*		jmp ccpclear    (start, clear command) *
;	*	ccp+6	127		(max command length)   *
;	*	ccp+7	comlen		(command length = 00)  *
;	*	ccp+8	' ... '		(16 blanks)	       *
;	********************************************************
;	* Normal entry is at ccp, where the command line given *
;	* at ccp+8 is executed automatically (normally a null  *
;	* command with comlen = 00).  An initializing program  *
;	* can be automatically loaded by storing the command   *
;	* at ccp+8, with the command length at ccp+7.  In this *
;	* case, the ccp executes the command before prompting  *
;	* the console for input.  Note that the command is exe-*
;	* cuted on both warm and cold starts.  When the command*
;	* line is initialized, a jump to "jmp ccpclear" dis-   *
;	* ables the automatic command execution.               *
;	********************************************************
;
loc_CC00:	JP	CCPSTART	;start ccp with possible initial command
loc_CC03:	JP	CCPCLEAR	;clear the command buffer
MAXLEN:		DB	127		;max buffer length
COMLEN:		DB	0		;command length (filled in by dos)
COMBUF:
		db "CP/A, ",0Dh,0Ah
                db "Akademie der Wissenschaften, ",0Dh,0Ah
                db "Institut fuer Informatik und Rechentechnik",0Dh,0Ah
                db "*****CCP*****, Version 11.01.89",0Dh,0Ah
                db  1Ah
		Db 128-($-COMBUF) dup (0)

;	total buffer length is 128 characters
;
;;DISKA		EQU	0004H		;disk address for current disk
BDOS		EQU	0005H		;primary bdos entry point
BUFF		EQU	0080H		;default buffer
FCB		EQU	005CH		;default file control block
;
RCHARF		EQU	1		;read character function
PCHARF		EQU	2		;print character function
PBUFF		EQU	9		;print buffer function
RBUFF		EQU	10		;read buffer function
BREAKF		EQU	11		;break key function
LIFTF		EQU	12		;lift head function (no operation)
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
RENF		EQU	23		;rename file function
LOGF		EQU	24		;return login vector
CSELF		EQU	25		;return currently selected drive number
DMAF		EQU	26		;set dma address
USERF		EQU	32		;set user number
;
;	special fcb flags
ROFILE		EQU	9		;read only file
SYSFILE		EQU	10		;system file flag
;
;	special characters
CR		EQU	13		;carriage return
LF		EQU	10		;line feed
LA		EQU	5FH		;left arrow
EOFILE		EQU	1AH		;end of file
;
;	utility procedures
crlf:
		ld	a, 0Dh
		call	printbc
		ld	a, 0Ah
printbc:
; print	character, but save b,c	registers
		push	bc
		ld	e, a
		ld	c, PCHARF
		call	BDOS
		pop	bc
		ret
;
;
;utility subroutines for intrinsic handlers
readerr:
;print the read error message
                call    print
                db "Read Error",7,'$'

saverr:
                call    print
                db "No Space",7,'$'

renmsg:

                call    print
                db "File exists",7,'$'

nofile:
;print no file message
                call    print
                db "No File$"

break:
                call    print
                db "*break*",7,'$'

allmsg:
                call    print
                db "ALL (Y/N)?$"

print:					;print error string
                call    crlf
                pop     de
                ld      c, 9
                call    5
;
blank:
		ld	a, ' '
		jr	printbc		; print	character a
;
del_sub:				; readcom:nosub
		ld	hl, readcom+1
		ld	a, (hl)
		or	a
		ret	z
		ld	(hl), 0
		dec	a
		call	select
		ld	de, subfcb
		jr	delete
;
saveuser:
;save user#/disk# before possible ^c or transient
		ld	a, 0
		push	af
		add	a, a
		add	a, a
		add	a, a
		add	a, a
;
SETDISKA:
		or	0
		ld	(DISKA), a	;user/disk
		and	0Fh
		call	select
		pop	af
		call	setuser
		ld	de, buff
;
setdma:
;set dma address to d,e
		ld	c, DMAF
		jr	bdos_jmp
;
setuser:
		ld	(loc_CE98+1), a
		ld	e, a
		ld	c, USERF
		jr	bdos_jmp	;sets user number
;
setdisk:
		xor	a
		ld	(FCB), a
		ld	a, (SDISK+1)
		or	a
		ret	z
		dec	a
;
select:
		ld	(CDISK+1), a
		ld	e, a
		ld	c, SELF
		jr	bdos_jmp
;
openc:		;open comfcb
		xor	a
		ld	(COMREC), a		;clear next record to read
		ld	de, FCB
;
open:		;open the file given by d,e
		ld	c, OPENF
bdos_inr:	call	BDOS
		inc	a
		ret
;
closecom:
		ld	de, FCB
;
close:
		ld	c, CLOSEF
		jr	bdos_inr
;
searchcom:
		ld	de, FCB
		ld	c, SEARF
		jr	bdos_inr
;
searchn:
		ld	c, SEARNF
		jr	bdos_inr
;
deletecom:
		ld	de, FCB
;
delete:
		ld	c, DELF
bdos_jmp:	jp	BDOS
;
renamecom:
		ld	de, FCB
		ld	c, RENF
		jr	bdos_jmp
;
diskreadc:
		ld	de, FCB
;
diskread:
		ld	c, DREADF
bdos_cond:	call	BDOS
		or	a
		ret
;
diskwrite:
		ld	de, FCB
		ld	c, DWRITF
		jr	bdos_cond
;
sub_CD3F:
		ld	c, BREAKF
		jr	bdos_cond
;
break_key:
;check for a character ready at the console
		call	sub_CD3F
		ret	z
		call	break
		xor	a
		inc	a
		ret
;
sub_CD5B:
		call	deletecom
		ld	de, FCB
		ld	c, 22
		jr	bdos_inr
;
TRANSLATE:
;translate character in register A to upper case
		CP	61H
		RET	C		;return if below lower case a
		CP	7BH
		RET	NC		;return if above lower case z
		AND	5FH
		RET			;translated to upper case
;
sub_CD6E:
		ld	de, (COMADDR+1)
		call	deblank
		ld	(loc_D296+1), de
		ld	a, (de)
		or	a
		ret
;
fillfcb:
		ld	hl, FCB
fillfcb1:
		push	hl
		call	sub_CD6E
		jr	z, SETCUR0	;use current disk if empty command
		sub	'A'-1
		jr	c, SETCUR0
		ld	b, a		;disk name held in b if : follows
		inc	de
		ld	a, (de)
		cp	':'
		jr	z, SETDSK	;set disk name if :
		dec	de
;
SETCUR0:	;set current disk
		xor	a
		ld	(SDISK+1), a
		ld	a, (SETDISKA+1)
		jr	SETNAME
;
SETDSK:		;set disk to name in register b
		ld	a, b
		ld	(SDISK+1), a
		inc	de
;
SETNAME:	;set the file name field
		ld	(hl), a
		ld	b, 8		;file name length (max)
		call	SETTY0
		ld	a, (de)
		cp	2Eh ; '.'
		jr	nz, loc_CDC7
		inc	de
		call	SETTY0
;
loc_CDAE:	xor	a
		call	PADTY1
		ex	de, hl
		ld	(COMADDR+1), hl	;set new starting point
;
;recover the start address of the fcb and count ?'s
		pop	hl
		ld	bc, 11		;b=0, c=8+3
SCNQ:		inc	hl
		ld	a, (hl)
		cp	'?'
		jr	nz, SCNQ0
;? found, count it in b
		inc	b
SCNQ0:		dec	c
		jr	nz, SCNQ
;
;number of ?'s in c, move to a and return with flags set
		ld	a, b
		or	a
		ret
;
loc_CDC7:	call	PADTY
		jr	loc_CDAE
;
SETTY0:		;set the field from the command buffer
		call	delim
		jr	z, PADTY	;skip the type field if no .
		inc	hl
		cp	'*'
		jr	nz, SETTY1
		ld	(hl), '?'	;since * specified
		jr	SETTY2
;
SETTY1:		;not a *, so copy to type field
		ld	(hl), a
		inc	de
SETTY2:		;decrement count and go again
		djnz	SETTY0
;
;end of type field, truncate
TRTYP:		call	delim
		jr	z, EFILL
		inc	de
		jr	TRTYP
;
PADTY:		;pad the type field with blanks
		ld	a, ' '
PADTY1:		inc	hl
		ld	(hl), a
		djnz	PADTY1
EFILL:		;end of the filename/filetype fill, save command address
;fill the remaining fields for the fcb
		ld	b, 3
		ret
;
getnumber:	;read a number from the command line
		call	sub_CD6E
		jr	z, comerrn
		ld	c, 0
conv0:		call	delim
		jr	z, CONV1
		inc	de
		sub	'0'
		cp	10
		jr	nc, comerrn	;valid?
		ld	b, a
		ld	a, c		;recover value
		cp	1Ah
		jr	nc, comerrn
		add	a, a		;mult by 10
		add	a, a
		add	a, c
		add	a, a
		add	a, b
		ld	c, a		;save value
		jr	nc, conv0
comerrn:	jp	comerr
CONV1:		ld	(COMADDR+1), de
		ld	a, c		;recover value
		ret
;
; fcb scan and fill subroutine (entry is at fillfcb1 below)
;fill the comfcb, indexed by A (0 or 16)
;subroutines
delim:		;look for a delimiter
		ld	a, (de)
		push	hl
		push	bc
		ld	hl, delimtab
		ld	bc, 9
		cpir
		pop	bc
		pop	hl
		ret	z
		cp	20h ; ' '
		jr	c, comerrn
		ret
;
delimtab:	db    0
		db  20h
		db  3Dh	; =
		db  LA
		db  2Eh	; .
		db  3Ah	; :
		db  3Bh	; ;
		db  3Ch	; <
		db  3Eh	; >
;
deblank:	;deblank the input line
		ld	a, (de)
		or	a
		ret	z
		cp	' '
		ret	nz
		inc	de
		jr	deblank
;
sub_CE3E:	ld	bc, 0FF0Ah
loc_CE41:	inc	b
		sub	c
		jr	nc, loc_CE41
		add	a, c
		ld	c, a
		ld	a, b
		cp	0Ah
		ret
;
intrinsic:
;look for intrinsic functions (comfcb has been filled)
		ld	de, intvec
intrin0:	ld	hl, FCB+1	;beginning of name
		ld	b, 4		;length of match is in b
intrin1:	ld	a, (de)
		or	a
		ret	z
		cp	(hl)		;match?
		jr	nz, intrin2	;skip if no match
		inc	de
		inc	hl
		djnz	intrin1
;
;complete match on name
		ex	de, hl
		ld	e, (hl)
		inc	hl
		ld	d, (hl)
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		dec	hl
		ld	b, (hl)
		dec	hl
		ld	c, (hl)
		ld	(loc_D21B+1), bc
		scf
		ret
intrin2:	;mismatch, move to end of intrinsic
		inc	de
		djnz	intrin2
;
		inc	de
		inc	de
		jr	intrin0
;
USERFUNC:
		ld	de, FCB+9
		ld	a, (de)
		cp	' '
		jr	nz, USER0
;no file name, but may be disk switch
		ld	hl, aCom	; "COM"
		ld	de, FCB+9
		ld	bc, 3
		ldir
USER0:		;file name is present
		ld	hl, 0
		ld	(ext3+1), hl
		call	setdisk
loc_CE93:	call	openc
		jr	nz, loc_CEB1
loc_CE98:	ld	a, 0
		or	a
		jr	z, loc_CEA3
		xor	a
		call	setuser
		jr	loc_CE93
loc_CEA3:	ld	hl, CDISK+1
loc_CEA6:	ld	a, 0
;
CDISK:		cp	0
		jr	z, loc_CEE3
		call	select
		jr	loc_CE93
;file opened properly, read it into memory
loc_CEB1:	ld	de, TRAN	;transient program base
;
LOAD0:		push	de		;save dma address
		call	setdma
		call	diskreadc
		pop	hl
		jr	nz, LOAD1
;sector loaded, set new dma address and compare
		ld	de, buff
		push	hl
		ld	hl, (ext3+1)
		add	hl, de
		ld	(ext3+1), hl
		pop	hl
		add	hl, de
		ld	bc, (ext2+1)
		ld	de, TRANM	;has the load overflowed?
		ld	a, d
		cp	b
		jr	z, loc_CED7
		dec	b
loc_CED7:	ld	d, h
		ld	e, l
		sbc	hl, bc
		jr	c, LOAD0
		call	saverr
retcom:		jp	loc_D27E
loc_CEE3:	jp	comerr
LOAD1:		dec	a
		call	nz, readerr
		ret
;
ccpclear:
;clear the command buffer
		xor	a
		ld	(comlen), a
;drop through to start ccp
ccpstart:
;enter here from boot loader
		ld	sp, STACK
		ld	hl, (res1+1)
		ld	a, h
		or	l
		jr	z, loc_CF02
		ld	hl, (ext2+1)
		ld	(BDOS+1), hl
		jr	loc_CF37
		
;(high order 4bits=user code, low 4bits=disk#)
loc_CF02:	ld      hl, (6)
		ld      (res2+1), hl
loc_CF37:	ld	a, c
		and	0Fh
		ld	(SETDISKA+1), a
		ld	a, c
		rra
		rra
		rra
		rra
		and	0Fh		;user code
		ld	(saveuser+1), a
		call	setuser
		ld	c, INITF
		call	BDOS
		ld	a, h
		ld	(loc_CEA6+1), a
		inc	a
		inc	l
		jr	z, loc_CF23
		xor	a
loc_CF23:	ld	(readcom+1), a
;check for initial command
		ld	a, (comlen)
		or	a
		jr	nz, CCP0	;assume typed already
;
CCP:
;enter here on each command or error condition
		ld	sp, STACK
		call	saveuser
		call	crlf		;print d> prompt, where d is disk name
		ld	a, (CDISK+1)	;get current disk number
		add	a, 'A'
		call	printbc
		ld	a, (loc_CE98+1)
		or	a
		jr	z, loc_CF54
		call	sub_CE3E
		or	a
		jr	z, loc_CF4E
		add	a, '0'
		call	printbc
loc_CF4E:	ld	a, c
		add	a, '0'
		call	printbc
loc_CF54:	ld	a, '>'
		call	printbc
		call	readcom		;command buffer filled
CCP0:		;(enter here from initialization with command full)
		ld	hl, combuf
		ld	(COMADDR+1), hl
		call	saveuser
		call	fillfcb		;command fcb filled
		jp	nz, comerr	;the name cannot be an ambiguous reference
COMADDR:	ld	hl, combuf
		ld	(loc_D25C+1), hl
		ld	a, (SDISK+1)
		or	a
		jr	nz, loc_CF84
		ld	a, (FCB+5)
		cp	20h ; ' '
		jr	nz, loc_CF84
;check for an intrinsic function
		call	intrinsic
		jp	c, loc_D20E
loc_CF84:	jp	loc_D1F5
;
;individual intrinsics follow
direct:
;directory search
		call	fillfcb		;comfcb gets file name
		call	setdisk		;change disk drives if requested
		ld	hl, FCB+1
		ld	a, (hl)		;may be empty request
		cp	' '
		jr	nz, dir1	;skip fill of ??? if not blank
;set comfcb to all ??? for current disk
		ld	b, 11
dir0:		ld	(hl), '?'
		inc	hl
		djnz	dir0
;not a blank request, must be in comfcb
dir1:		call	searchcom
		jp	z, nofile	;not found message
		ld	d, 0FFh
		push	de
dir2:
;found, but may be system file
		dec	a
		rrca
		rrca
		rrca
		and	1100000b
		ld	hl, buff
		add	a, l
		ld	l, a
		push	hl
		pop	ix
		bit	7, (ix+0Ah)
		jr	nz, dir6
		pop	af
		inc	a
		and	3		; 4th column?
dircol:		equ $-1		
		push	af
		ld	a, ' '
		jr	nz, loc_CFCA
		call	crlf
		ld	a, (CDISK+1)
		add	a, 'A'
loc_CFCA:	call	printbc
		ld	a, ':'
		call	printbc
		call	blank
		ld	bc, 802h
loc_CFD8:	inc	ix
		ld	a, (ix+0)
		and	7Fh
		call	printbc
		djnz	loc_CFD8
		dec	c
		jr	z, dir6
		call	blank
		ld	b, 3
		jr	loc_CFD8
dir6:		call	break_key	;check for interrupt at keyboard
		jr	nz, enddir	;abort directory search
		call	searchn
		jr	nz, dir2	;for another entry
enddir:		;end of directory scan
		jp	retcom
;
;
erase:		call	fillfcb		;cannot be all ???'s
		cp	11
		jr	nz, erasefile
;erasing all of the disk
		call    allmsg
		call	readcom
		ld	hl, comlen
		dec	(hl)
		ret	nz
		inc	hl
		ld	a, (hl)
		cp	'Y'
		ret	nz
;ok, erase the entire diskette
		inc	hl
		ld	(COMADDR+1), hl	; otherwise error at retcom
erasefile:
		call	setdisk
		call	deletecom
		inc	a		;255 returned if not found
		call	z, nofile	;no file message if so
		jr	enddir
;
type:
		call	fillfcb
		jr	nz, comerr0	;don't allow ?'s in file name
		call	setdisk
		call	openc		;open the file
		jr	z, comerr0	;zero flag indicates not found
;file opened, read 'til eof
		call	crlf
		ld	bc, 128
type0:		ld	a, c
		cp	128		;end buffer
		jr	c, type1
;read another buffer full
		call	diskreadc
		jr	nz, typeeof	;hard end of file
		ld	bc, 0
type1:		ld	hl, BUFF
		add	hl, bc
		ld	a, (hl)
		cp	EOFILE
		jr	z, retcom0
		push	bc
		call	printbc
		call	break_key
		pop	bc
		jp	nz, retcom	;abort if break
		inc	bc
		jr	type0		;for another character
;
typeeof:	;end of file, check for errors
		dec	a
retcom0:	jp	z, retcom
		call	readerr
comerr0:	jp	comerr
;
save:		call	getnumber	; value to register a
		push	af		;save it for later
;
;should be followed by a file to save the memory image
		call	fillfcb
		jr	nz, comerr0	;cannot be ambiguous
		call	setdisk		;may be a disk change
		call	sub_CD5B
		jr	z, saverr0
		xor	a
		ld	(COMREC), a	; clear next record field
		ld	h, a
		pop	af		;#pages to write is in a, change to #sectors
		ld	l, a
		add	hl, hl
		ld	de, TRAN	;h,l is sector count, d,e is load address
save0:		;check for sector count zero
		ld	a, h
		or	l
		jr	z, save1	;may be completed
		dec	hl		;sector count = sector count - 1
		push	hl		;save it for next time around
		ld	hl, 128
		add	hl, de
		push	hl		;next dma address saved
		call	setdma		;current dma address set
		call	diskwrite
		pop	de
		pop	hl		;dma address, sector count
		jr	nz, saverr0	;may be disk full case
		jr	save0		;for another sector
;
save1:		;end of dump, close the file
		call	closecom
		inc	a		; 255 becomes 00 if error
		jr	nz, retsave	;for another command
saverr0:	;must be full or read only disk
		call	saverr
retsave:	jp	retcom
;
;
rename:
;rename a file on a specific disk
		call	fillfcb
		jr	nz, renerr2	;must be unambiguous
		ld	a, (SDISK+1)
		push	af		;save for later compare
		call	setdisk		;disk selected
		call	searchcom	;is new name already there?
		jr	nz, renerr3
;file doesn't exist, move to second half of fcb
		ld	hl, FCB
		ld	de, FCB+16
		ld	bc, 16
		ldir
;check for = or left arrow
		ld	hl, (COMADDR+1)
		ex	de, hl
		call	deblank
		cp	'='
		jr	z, ren1		;ok if =
		cp	LA
		jr	nz, renerr2
ren1:		ex	de, hl
		inc	hl
		ld	(COMADDR+1), hl	;past delimiter
;proper delimiter found
		call	fillfcb
		jr	nz, renerr2
;check for drive conflict
		pop	bc		;previous drive number
		ld	hl, SDISK+1
		ld	a, (hl)
		or	a
		jr	z, ren2
;drive name was specified.  same one?
		cp	b
		ld	(hl), b
		jr	nz, renerr2
ren2:		ld	(hl), b		;store the name in case drives switched
		xor	a
		ld	(FCB), a
		call	searchcom	;is old file there?
		jr	z, renerr1
;
;everything is ok, rename the file
		call	renamecom
retsave0:	jr	retsave
;
renerr1:	; no file on disk
		call	nofile
		jr	retsave0
renerr2:	; ambigous reference/name conflict
		jp	comerr
renerr3:	; file already exists
		call	renmsg
		jr	retsave0
;
user:
;set user number
		call	getnumber	; leaves the value in the accumulator
		cp	16
		jr	nc, renerr2	; must be between 0 and 15
		ld	(saveuser+1), a	;new user number set
		ret
;
;Weitere zusaetzliche residente Kommandos
;
; CLK hh:mm:ss tt.mm.jj
; Durch dieses Kommando koennen Uhrzeit und Datum (beide Angaben ab 50h in BCD-
; Form vom Kaltstart bzw. von ACCOUNT hinterlegt) neu gestellt werden. Dies kann
; sich z.B. nach Programmen, die diesen Bereich zerstoert oder wegen zu langer
; geschlossener Interrupts eine falsche Uhrzeit verursacht haben, als notwendig
; erweisen. Im angegebenen Parameterformat bedeutet (jeweils dezimal, auch
; einstellig erlaubt):
; hh:mm:ss  Stunden:Minuten:Sekunden
; tt.mm.jj  Tag.Monat.Jahr
; Alle Angaben ab ss koennen fehlen, in diesem Fall werden diese Werte nicht
; veraendert.
clk:
		ld	hl, CLKBCD
		ld	b, 6
clk1:		push	bc
		push	hl
		call	getnumber
		call    sub_CE3E
		jr      nc, renerr2
		pop     hl
		rld
		ld      a, c
		rld
		inc     hl
		pop     bc
		ld      de, (COMADDR+1)
		ld      a, (de)
		or      a
		ret     z
		inc     de
		ld      (COMADDR+1), de
		djnz    clk1
		ret
;
; EXT [d:]<filename>
; Das angegeben COM-File wird zu einem residenten Kommando erklaert, indem
; es vor BDOS, CCP und vor evtl. schon residenten zusaetzlichen Kommandos
; im Hauptspeicher abgelegt wird, um bei Aufruf statt von Diskette von dort
; nach 100h geladen zu werden. Hierdurch verringert sich jedoch der TPA
; entsprechend. Da residente Kommandos nur maximal 4 Zeichen lang sein
; duerfen, trifft dies auch auf <filename> zu.
ext:
		call	fillfcb
		jr	nz, comerrx
		ld	a, (FCB+5)	; Hat filename 5 Zeichen (oder mehr)?
		cp	' '
		jr	nz, comerrx
		call	intrinsic	; oder ist es ein internes Kommando?
		jr	c, renerrx
		ld	hl, extvece	; oder Kommnadoliste schon voll?
		sbc	hl, de
		jr	c, saverrx
		push	de
		call	USERFUNC
		ld	hl, (res1+1)
		ld	a, h
		or	l
		jr	nz, ext1
		ld	hl, (BIOSR+4)	; WBOOT-Adr.
		ld	(res1+1), hl
ext1:		ld	hl, loc_D20Ex
		ld	(BIOSR+4), hl
		ld	hl, FCB+1
		ld	bc, 4
		pop	de
		ldir
ext2:		ld	hl, TRANM
		push	hl
		xor	a
ext3:		ld      bc, 0
		sbc     hl, bc
		ex      de, hl
		ld      (hl), e
		inc     hl
		ld      (hl), d
		inc     hl
		ld      (hl), a
		ld      hl, (6)
		ex      de, hl
		dec     hl
		ld      (hl), d
		dec     hl
		ld      (hl), e
		dec     hl
		ld      (hl), 0C3h ; '+'
		ld      (ext2+1), hl
		ld      (6), hl
		pop     de
		dec     de
		ld      hl, 0FFh
		add     hl, bc
		ld      a, b
		or      c
		ret     z
		lddr
		ret
;
renerrx:	call	renmsg
		jr	comerrx
saverrx:	call	saverr
comerrx:	jp	comerr
;
;Streichen aller zusaetzlich residenten Kommandos
res:		ld	hl, TRANM
		ld	(ext2+1), hl
		xor	a
		ld	(extvec), a
res1:		ld	hl, 0
		ld	a, h
		or	l
		ret	z
		ld	(BIOSR+4), hl	; WBOOT-Adr.
		ld	hl, 0
		ld	(res1+1), hl
res2:		ld	hl, 0
		ld	(BDOS+1), hl
		ret
;
; SWAP    <Laufwerk>: <Laufwerk>:
; logisches Austauschen der beiden Laufwerke, z.B. macht "SWAP A: M:" nach dem
; Fuellen der RAM-Floppy diese zum Laufwerk A (schnelleres Nachladen bei WordStar,
; dBase u.ae.). Als Nebeneffekt bietet das Kommmando "SWAP A: A:" in Submit-
; Jobstroemen die Moeglichkeit fuer ein Disketten-Reset (^C-Ersatz).
swap:
		call	fillfcb
		call	swap_lw
		push	hl		; Adr. DPH LW1
		call	fillfcb
		call	swap_lw
		pop	de		; Adr. DPH LW2
		ld	b, 10h		; Laenge DPH
; DPHs vertauschen
swap1:		ld	a, (de)
		ld	c, (hl)
		ld	(hl), a
		ld	a, c
		ld	(de), a
		inc	de
		inc	hl
		djnz	swap1
;
loc_D20Ex:	ld      sp, 80h
		ld      a, 82h
		call    printbc
		ld      a, (DISKA)
		ld      c, a
		jp	loc_CC03	; CCP-Start ohne Kdo.ausf¸hrung
;		
swap_lw:	ld	a, (FCB)
		dec	a
		ld	c, a
		ld	e, 1
		call	BIOSR+3*9	; BIOS:	SELDSKF	select disk function
		ld	a, h		; HL=DPH
		or	l
		ret	nz
		jp	comerr
;
;
;
loc_D1F5:	ld	a, (FCB+1)	; 1. Buchstabe Filename
		cp	' '
		jr	nz, loc_D209	; Fehler, Filename gef¸llt
		ld	a, (SDISK+1)
		or	a
		jr	z, loc_D206
		dec	a
		ld	(SETDISKA+1), a
loc_D206:	jp	loc_D27E
;
loc_D209:	call	USERFUNC
		jr	loc_D23D
;		
loc_D20E:	ld	(loc_D27B+1), de
		ld	hl, TRANM
		or	a
		sbc	hl, de
		jp	c, loc_D278
loc_D21B:	ld	hl, 0
		or	a
		sbc	hl, de
		jr	z, loc_D23D
		push	hl
		ld	bc, 100h
		push	bc
		add	hl, bc
		ld	bc, (BDOS+1)
		or	a
		sbc	hl, bc
		pop	hl
		pop	bc
		jr	c, loc_D23A
		call	saverr
		jp	loc_D27E
;		
loc_D23A:	ex	de, hl
		ldir
loc_D23D:	ld	hl, 100h
		ld	(loc_D27B+1), hl
		call	fillfcb
		ld	a, (SDISK+1)
		ld	(FCB), a
		ld	hl, FCB+16	; 'l'
		call	fillfcb1
		ld	a, (SDISK+1)
		ld	(FCB+16), a
		xor	a
		ld	(COMREC), a
loc_D25C:	ld	hl, 0
		ld	b, 0
		ld	de, 81h	; 'Å'
loc_D264:	ld	a, (hl)
		ld	(de), a
		or	a
		jr	z, loc_D26E
		inc	b
		inc	hl
		inc	de
		jr	loc_D264
loc_D26E:	ld	a, b
		ld	(buff),	a
		ld	(COMADDR+1), hl
		call	crlf
loc_D278:	call	saveuser
loc_D27B:	call	100h
loc_D27E:	ld	sp, STACK
		call	saveuser
		call	fillfcb
		ld	a, (FCB+1)
		sub	20h ; ' '
SDISK:		or	0
		jr	z, loc_D2B1
comerr:		call	saveuser
		call	crlf
loc_D296:	ld	hl, combuf
loc_D299:	ld	a, (hl)
		cp	20h ; ' '
		jr	z, loc_D2A9
		or	a
		jr	z, loc_D2A9
		push	hl
		call	printbc
		pop	hl
		inc	hl
		jr	loc_D299
loc_D2A9:	ld	a, '?'
		call	printbc
loc_D2AE:	call	del_sub
loc_D2B1:	jp	CCP
;
;
readcom:
;read the next command into the command buffer
;check for submit file
		ld	a, 0
		or	a
		jr	z, nosub
		call	break_key
		jr	nz, loc_D2AE
;scanning a submit file
;change drives to open and read the file
		ld	a, (readcom+1)
		dec	a
		call	select
;have to open again in case xsub present
		ld	de, subfcb
		call	open
		jr	z, nosub	;skip if no sub
		ld	a, (subrc)
		dec	a		;read last record(s) first
		ld	(subcr), a	;current record to read
		ld	de, comlen
		call	setdma
		ld	de, subfcb
		call	diskread	;end of file if last record
		jr	nz, nosub
;disk read is ok, transfer to combuf
		ld	hl, submod
		ld	(hl), 0
		inc	hl
		dec	(hl)
		ld	de, subfcb
		call	close
		jr	z, nosub
		call	saveuser
		jr	noread
;
nosub:		;no submit file
		call	del_sub
;translate to upper case, store zero at end
		call	saveuser	;user # save in case control c
loc_D2FC:	call	sub_CD3F
		jr	z, loc_D2FC
		ld	c, RBUFF
		ld	de, maxlen
		call	BDOS
noread:		;enter here from submit file
;set the last character to zero for later scans
		ld	hl, comlen
		ld	b, (hl)		;length is in b
		inc	b
readcom0:	inc	hl
		djnz	readcom2
		ld	(hl), b		;store a zero
		ret
;
readcom2:	ld	a, (readcom+1)
		or	a
		jr	z, readcom3
		ld	a, (hl)
		push	hl
		call	printbc
		pop	hl
readcom3:	ld	a, (hl)		;get character and translate
		call	translate
		ld	(hl), a
		jr	readcom0
;
;	'submit' file control block
SUBFCB:		DB	0,"$$$     "	;file name is $$$
		DB	"SUB",0,0	;file type is sub
SUBMOD:		DB	0		;module number
SUBRC:		db	1 dup (0)	;record count filed
		Db	16 dup (0)	;disk map
SUBCR:		Db	1 dup (0)	;current record to read

aCom:		db "COM"
;
intvec:
;intrinsic function names (all are four characters)
		db "DIR "
		dw direct
		db "ERA "
		dw erase
		db "TYPE"
		dw type
		db "SAVE"
		dw save
		db "REN "
		dw rename
		db "USER"
		dw user
		db "CLK "
		dw clk
		db "EXT "
		dw ext
		db "RES "
		dw res
		db "SWAP"
		dw swap
		db "===="
		dw TRANM
		db "GO  "
		dw TRANM
;
extvec:		db    0,0,0,0
		dw    0
		db    0,0,0,0
		dw    0
		db    0,0,0,0
		dw    0
		db    0,0,0,0
		dw    0
extvece:	equ	$-1
		db    0

		db	800h-($-loc_CC00) dup (0FFh)
stack:
;;		end
