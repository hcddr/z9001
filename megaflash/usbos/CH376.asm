;******************************************************************************
;                      CH376 USB Driver for Z80 CPU
;******************************************************************************
; Based on code for the MZ800 by Michal Hucík http://www.8bit.8u.cz
; Based on code for the Mattel Aquarius Micro-Expander by Bruce Abbott
;   https://aquarius.je/bruce-abbotts-micro-expander/
;
;
; I/O ports
CH376_DATA_PORT         equ     28H     ; change this to match your hardware!
CH376_CONTROL_PORT      equ     CH376_DATA_PORT+1 ; A0 = high

; commands
CH376_CMD_SET_USB_SPEED equ     04H     ; set USB device speed (send 0 for 12Mbps, 2 for 1.5Mbps)
CH376_CMD_RESET_ALL     equ     05H     ; Execute hardware reset
CH376_CMD_CHECK_EXIST   equ     06H     ; check if file exists
CH376_CMD_READ_VAR32    equ     0CH     ; Read the specified 32-bit file system variables
CH376_CMD_WRITE_VAR32   equ     0DH     ; Set the specified 32-bit file system variables
CH376_CMD_SET_USB_MODE  equ     15H     ; set USB mode
CH376_CMD_GET_STATUS    equ     22H     ; get status
CH376_CMD_RD_USB_DATA   equ     27H     ; read data from USB
CH376_CMD_WR_REQ_DATA   equ     2DH     ; write data to USB
CH376_CMD_SET_FILE_NAME equ     2FH     ; set name of file to open, read etc.
CH376_CMD_DISK_CONNECT  equ     30H     ; check if USB drive is plugged in
CH376_CMD_DISK_MOUNT    equ     31H     ; mount disk
CH376_CMD_FILE_OPEN     equ     32H     ; open file
CH376_CMD_FILE_ENUM_GO  equ     33H     ; get next file info
CH376_CMD_FILE_CREATE   equ     34H     ; create new file
CH376_CMD_FILE_ERASE    equ     35H     ; delete file
CH376_CMD_FILE_CLOSE    equ     36H     ; close opened file
CH376_CMD_BYTE_LOCATE   equ     39H     ; seek into file
CH376_CMD_BYTE_READ     equ     3AH     ; start reading bytes
CH376_CMD_BYTE_RD_GO    equ     3BH     ; continue reading bytes
CH376_CMD_BYTE_WRITE    equ     3CH     ; start writing bytes
CH376_CMD_BYTE_WR_GO    equ     3DH     ; continue writing bytes
; status codes
CH376_INT_SUCCESS       equ     14H     ; command executed OK
CH376_INT_DISK_READ     equ     1DH     ; read again (more bytes to read)
CH376_INT_DISK_WRITE    equ     1EH     ; write again (more bytes to write)
CH376_ERR_OPEN_DIR      equ     41H     ; is directory, not file
CH376_ERR_MISS_FILE     equ     42H     ; file not found
; command status codes (command output data)
CH376_CMD_RET_SUCCESS   equ     51H     ; operation successfully
CH376_CMD_RET_ABORT     equ     5FH     ; operation failure
; variables
CH376_VAR_FILE_SIZE     equ     68H     ; file size variable
	

;------------------------------------------------------------------------------
;            Wait for about 10 us @ 4 MHz
;------------------------------------------------------------------------------
_usb__wait10us:	MACRO
	EX	(SP), HL	; 4.75 us
	EX	(SP), HL	; 4.75 us
	NOP			; 1.00 us
	ENDM

;------------------------------------------------------------------------------
;            Reset USB module and wait for about 35 ms
;------------------------------------------------------------------------------
usb__reset:
	LD	A, CH376_CMD_RESET_ALL
	OUT	(CH376_CONTROL_PORT), A
	PUSH	BC
	LD	BC, 0AC0DH	; 0DACH = 3500
.wait:	_usb__wait10us
	DJNZ	.wait
	DEC	C
	JR	NZ, .wait
	POP	BC
	RET

;------------------------------------------------------------------------------
;            Create root path
;------------------------------------------------------------------------------
usb__root:
        LD   A,'/'
        LD   (PathName),A
        XOR  A
        LD   (PathName+1),A
        RET

;--------------------------------------------------------------
;            Open all subdirectory levels in path
;--------------------------------------------------------------
;    in: PathName = path eg. "/",0
;                            "/subdir1/subdir2/subdir3",0
;   out:     Z = OK
;           NZ = failed to open directory, A = error code
;
usb__open_path:
        PUSH   HL
        CALL   usb__ready               ; check for USB drive
        JR     NZ,.done                 ; abort if no drive
        LD     HL,PathName
        LD     A,CH376_CMD_SET_FILE_NAME
        OUT    (CH376_CONTROL_PORT),A   ; command: set file name (root dir)
        LD     A,'/'
        JR     .start                   ; start with '/' (root dir)
.next_level:
        LD     A,(HL)
        OR     A                        ; if NULL then end of path
        JR     Z,.done
        LD     A,CH376_CMD_SET_FILE_NAME
        OUT    (CH376_CONTROL_PORT),A   ; command: set file name (subdirectory)
.send_name:
        INC    HL
        LD     A,(HL)                   ; get next char of directory name
        CP     "/"
        JR     Z,.open_dir
        OR     A                        ; terminate name on '/' or NULL
        JR     Z,.open_dir
        CALL   UpperCase                ; convert 'a-z' to 'A-Z'
.start  OUT    (CH376_DATA_PORT),A      ; send char to CH376
        JR     .send_name               ; next char
.open_dir:
        XOR    A
        OUT    (CH376_DATA_PORT),A      ; send NULL char (end of name)
        LD     A,CH376_CMD_FILE_OPEN
        OUT    (CH376_CONTROL_PORT),A   ; command: open file/directory
        CALL   usb__wait_int
        CP     CH376_ERR_OPEN_DIR       ; opened directory?
        JR     Z,.next_level            ; yes, do next level.  no, error
.done:  POP    HL
        RET

;-----------------------------------------------------
;           Open Current Directory
;-----------------------------------------------------
;  out: z = directory opened
;      nz = error
;
; if current directory won't open then reset to root.
;
usb__open_dir:
    ld      hl,_usb_star
    CALL    usb__open_read          ; open "*" = request all files in current directory
    CP      CH376_INT_DISK_READ     ; opened directory?
    RET     Z                       ; yes, ret z
    CP      CH376_ERR_MISS_FILE     ; no, directory missing?
    RET     NZ                      ; no, quit with disk error
    Call    usb__root               ; yes, set path to root
    ld      hl,_usb_star
    CALL    usb__open_read          ; try to open root directory
    CP      CH376_INT_DISK_READ
    RET                             ; z = OK, nz = error

_usb_star:
   db  "*",0

;------------------------------------------------------------------------------
;                      Test if File Exists
;------------------------------------------------------------------------------
; Input:    HL = filename
;
; Output:    Z = file exists
;           NZ = file not exist or is directory, A = error code
;
usb__file_exist:
        CALL    usb__open_read          ; try to open file
        JR      Z,.close
        CP      CH376_ERR_OPEN_DIR      ; error, file is directory?
        JR      NZ,.done                ; no, quit
.close: PUSH    AF
        CALL    usb__close_file         ; close file
        POP     AF
.done:  CP      CH376_INT_SUCCESS       ; Z if file exists, else NZ
        RET

;------------------------------------------------------------------------------
;                      Get the size of a file
;------------------------------------------------------------------------------
; Input:    None
;
; Output:   DEHL = size of opened file (32 Bit)
;
usb__get_file_size:
	LD	A, CH376_CMD_READ_VAR32
	OUT	(CH376_CONTROL_PORT), A
	LD	A, CH376_VAR_FILE_SIZE
	OUT	(CH376_DATA_PORT), A
	IN	A, (CH376_DATA_PORT)
	LD	L, A
	IN	A, (CH376_DATA_PORT)
	LD	H, A
	IN	A, (CH376_DATA_PORT)
	LD	E, A
	IN	A, (CH376_DATA_PORT)
	LD	D, A
	RET

;------------------------------------------------------------------------------
;                        Open File for Writing
;------------------------------------------------------------------------------
; If file doesn't exist then creates and opens new file.
; If file does exist then opens it and sets size to 1.
;
; WARNING: overwrites existing file!
;
; Input:    HL = filename
;
; Output:    Z = success
;           NZ = fail, A = error code
;
usb__open_write:
        CALL    usb__open_read          ; try to open existing file
        JR      Z,.file_exists
        CP      CH376_ERR_MISS_FILE     ; error = file missing?
        RET     NZ                      ; no, some other error so abort
        LD      A,CH376_CMD_FILE_CREATE
        OUT     (CH376_CONTROL_PORT),A  ; command: create new file
        JP      usb__wait_int           ; and return
; file exists, set size to 1 byte (forgets existing data in file)
.file_exists:
        LD      A,CH376_CMD_WRITE_VAR32
        OUT     (CH376_CONTROL_PORT),A  ; command: set file size
        LD      A,CH376_VAR_FILE_SIZE
        OUT     (CH376_DATA_PORT),A     ; select file size variable in CH376
        LD      A,1
        OUT     (CH376_DATA_PORT),A     ; file size = 1
        XOR     A
        OUT     (CH376_DATA_PORT),A
        OUT     (CH376_DATA_PORT),A     ; zero out higher bytes of file size
        OUT     (CH376_DATA_PORT),A
        RET

;------------------------------------------------------------------------------
;    Write Bytes from Memory to open File
;------------------------------------------------------------------------------
;   in: HL = address of source data
;       DE = number of bytes to write
;
;  out: Z if successful
;       HL = next address
;
usb__write_bytes:
        PUSH    BC
        LD      A,CH376_CMD_BYTE_WRITE
        OUT     (CH376_CONTROL_PORT),A     ; send command 'byte write'
        LD      C,CH376_DATA_PORT
        OUT     (C),E                      ; send data length lower byte
        OUT     (C),D                      ; send data length upper byte
.loop:  CALL    usb__wait_int              ; wait for response
        JR      Z,.done                    ; return Z if finished writing
        CP      CH376_INT_DISK_WRITE       ; more bytes to write?
        JR      NZ,.done                   ; no, error so return NZ
        LD      A,CH376_CMD_WR_REQ_DATA
        OUT     (CH376_CONTROL_PORT),A     ; send command 'write request'
        IN      B,(C)                      ; B = number of bytes requested
        JR      Z,.next                    ; skip if no bytes to transfer
        OTIR                               ; output data (1-255 bytes)
.next:  LD      A,CH376_CMD_BYTE_WR_GO
        OUT     (CH376_CONTROL_PORT),A     ; send command 'write go'
        JR      .loop                      ; do next transfer
.done:  POP     BC
        RET

;--------------------------------------------------------------------
;                          Close File
;--------------------------------------------------------------------
;
usb__close_file:
        LD      A,CH376_CMD_FILE_CLOSE
        OUT     (CH376_CONTROL_PORT),A
        LD      A,1
        OUT     (CH376_DATA_PORT),A
        JP      usb__wait_int

;------------------------------------------------------------------------------
;                      Open a File or Directory
;------------------------------------------------------------------------------
; Input:   HL = filename (null-terminated)
;
; Output:   Z = OK
;          NZ = fail, A = error code
;                         $1D (INT_DISK_READ) too many subdirectories
;                         $41 (ERR_OPEN_DIR) 'filename'is a directory
;                         $42 (CH376_ERR_MISS_FILE) file not found
;
usb__open_read:
        CALL    usb__open_path          ; enter current directory
        RET     NZ
        CALL    usb__set_filename       ; send filename to CH376
        RET     NZ                      ; abort if error
        LD      A,CH376_CMD_FILE_OPEN
        OUT     (CH376_CONTROL_PORT),A  ; command: open file
        JP      usb__wait_int

;------------------------------------------------------------------------------
;                       Set File Name
;------------------------------------------------------------------------------
;  Input:  HL = filename
; Output:   Z = OK
;          NZ = error, A = error code
;
usb__set_filename:
        PUSH    HL
        CALL    usb__ready              ; check for USB drive
        JR      NZ,.done                ; abort if error
        LD      A,CH376_CMD_SET_FILE_NAME
        OUT     (CH376_CONTROL_PORT), A ; command: set file name
.send_name:
        LD      A,(HL)
        CALL    dos__char               ; convert char to MSDOS equivalent
        OUT     (CH376_DATA_PORT),A     ; send filename char to CH376
        INC     HL                      ; next char
        OR      A
        JR      NZ,.send_name           ; until end of name
.done:  POP     HL
        RET

;------------------------------------------------------------------------------
;               Read Bytes from File into RAM
;------------------------------------------------------------------------------
; Input:  HL = destination address
;         DE = number of bytes to read
;
; Output: HL = next address (start address if no bytes read)
;         DE = number of bytes actually read
;          Z = successful read
;         NZ = error reading file
;          A = status code
;
usb__read_bytes:
        PUSH    BC
        PUSH    HL
        LD      A,CH376_CMD_BYTE_READ
        OUT     (CH376_CONTROL_PORT),A  ; command: read bytes
        LD      C,CH376_DATA_PORT
        OUT     (C),E
        OUT     (C),D                   ; send number of bytes to read
usb_read_loop:
        CALL    usb__wait_int           ; wait until command executed
        LD      E,A                     ; E = status
        LD      A,CH376_CMD_RD_USB_DATA
        OUT     (CH376_CONTROL_PORT),A  ; command: read USB data
        IN      B,(C)                   ; B = number of bytes in this block
        JR      Z,usb_read_next         ; number of bytes > 0?
        INIR                            ; yes, read data block into RAM
usb_read_next:
        LD      A,E
        CP      CH376_INT_SUCCESS       ; file read success?
        JR      Z,usb_read_end          ; yes, return
        CP      CH376_INT_DISK_READ     ; more bytes to read?
        JR      NZ,usb_read_end         ; no, return
        LD      A,CH376_CMD_BYTE_RD_GO
        OUT     (CH376_CONTROL_PORT),A  ; command: read more bytes
        JR      usb_read_loop           ; loop back to read next block
usb_read_end:
        POP     DE                      ; DE = start address
        PUSH    HL                      ; save HL = end address + 1
        OR      A
        SBC     HL,DE                   ; HL = end + 1 - start
        EX      DE,HL                   ; DE = number of bytes actually read
        POP     HL                      ; restore HL = end address + 1
        POP     BC
        CP      CH376_INT_SUCCESS
        RET

;------------------------------------------------------------------------------
;                        Delete File
;------------------------------------------------------------------------------
; Input:  HL = filename string
;
; Output:  Z = OK
;         NZ = fail, A = error code
;
usb__delete:
        CALL    usb__open_read
        RET     NZ
        LD      A,CH376_CMD_FILE_ERASE
        OUT     (CH376_CONTROL_PORT),A  ; command: erase file
        JR      usb__wait_int

;;; TBD: Check if we should simplify the loop by doing DJNZ
;------------------------------------------------------------------------------
;                   Wait for Interrupt and Read Status
;------------------------------------------------------------------------------
; output:  Z = success
;         NZ = fail, A = error code
;
usb__wait_int:
        PUSH    BC
        LD      BC,0                    ; wait counter = 65536
.wait_int_loop:
        IN      A,(CH376_CONTROL_PORT)  ; command: read status register
        RLA                             ; interrupt bit set?
        JR      NC,.wait_int_end        ; yes,
        DEC     BC                      ; no, counter-1
        LD      A,B
        OR      C
        JR      NZ,.wait_int_loop       ; loop until timeout
.wait_int_end:
        LD      A,CH376_CMD_GET_STATUS
        OUT     (CH376_CONTROL_PORT),A  ; command: get status
        NOP
        IN      A,(CH376_DATA_PORT)     ; read status byte
        CP      CH376_INT_SUCCESS       ; test return code
        POP     BC
        RET

;---------------------------------------------------------------------
;                     Check if CH376 Exists
;---------------------------------------------------------------------
;  out: Z = CH376 exists
;      NZ = not detected, A = error code 1 (no CH376)
;
usb__check_exists:
        LD      B,10
.retry: LD      A,CH376_CMD_CHECK_EXIST
        OUT     (CH376_CONTROL_PORT),A  ; command: check CH376 exists
        LD      A,01AH
        OUT     (CH376_DATA_PORT),A     ; send test byte
	_usb__wait10us
        IN      A,(CH376_DATA_PORT)
        CP      0E5H                    ; byte inverted?
        RET     Z
        DJNZ    .retry
        LD      A,1                     ; error code = no CH376
        OR      A                       ; NZ
        RET

;---------------------------------------------------------------------
;                         Set USB Mode
;---------------------------------------------------------------------
;  out: Z = OK
;      NZ = failed to enter USB mode, A = error code 2 (no USB)
;
;  clobbers: B
;
usb__set_usb_mode:
        LD      B,10
.retry: LD      A,CH376_CMD_SET_USB_MODE
        OUT     (CH376_CONTROL_PORT),A  ; command: set USB mode
        LD      A,6
        OUT     (CH376_DATA_PORT),A     ; mode 6
	_usb__wait10us
	_usb__wait10us
        IN      A,(CH376_DATA_PORT)
        CP      CH376_CMD_RET_SUCCESS
        RET     Z
        DJNZ    .retry
        LD      A,2                     ; error code 2 = no USB
        OR      A                       ; NZ
        RET

;-------------------------------------------------------------------
;               is USB drive Ready to access?
;-------------------------------------------------------------------
; Check for presense of CH376 and USB drive.
; If so then mount drive.
;
; Output:  Z = OK
;         NZ = error, A = error code
;                          1 = no CH376
;                          2 = no USB
;                          3 = no disk (mount failure)
;
usb__ready:
        PUSH    BC
        call    usb__check_exists       ; CH376 hardware present?
        jr      nz,.done
        ld      c,1                     ; C = flag, 1 = before set_usb_mode
.mount:
        LD      B,5                     ; retry count for mount
.mountloop:
        CALL    usb__mount              ; try to mount disk
        JR      z,.done                 ; return OK if mounted
        DJNZ    .mountloop
        DEC     C                       ; already tried set_usb_mode ?
        JR      NZ,.done                ; yes, fail
        call    usb__set_usb_mode       ; put CH376 into USB mode
        JR      Z,.mount                ; if successful then try to mount disk
.done:  POP     BC
        RET

;------------------------------------------------------------------------------
;                            Mount USB Disk
;------------------------------------------------------------------------------
; output:  Z = mounted
;         NZ = not mounted
;          A = CH376 interrupt code
;
usb__mount:
        LD      A,CH376_CMD_DISK_MOUNT
        OUT     (CH376_CONTROL_PORT),A  ; command: mount disk
        JP      usb__wait_int           ; wait until done

;------------------------------------------------------------------------------
;                            Start/continue reading directory
;------------------------------------------------------------------------------
; Input:  HL = address of filename to be read
;
; output:  Z = success, filename read
;         NZ = error, end of file list
;          A = CH376 interrupt code
;         HL = points to the end address of the file info structure (HL = HL + 20H)
;
usb__dir_start:				; Read first directory entry
	PUSH	HL
	LD	HL, _usb_star		; First, open current directory
	CALL	usb__open_read
	POP	HL
	CP	CH376_INT_DISK_READ
	RET	NZ			; Path not found or other error
	JR	_read_file_info
usb__dir_continue:			; Read next directory entry
	LD	A, CH376_CMD_FILE_ENUM_GO
	OUT	(CH376_CONTROL_PORT), A
	CALL	usb__wait_int
	CP	CH376_INT_DISK_READ
	RET	NZ			; No more directory entries or other error
_read_file_info:
	PUSH	IX			; Save IX, will be used for indexing the file info
	PUSH	HL
	LD	A, CH376_CMD_RD_USB_DATA ; Read USB data
	OUT	(CH376_CONTROL_PORT), a
	PUSH	BC
	LD	C, CH376_DATA_PORT
	IN	B, (C)			; Get number of bytes to be read
	INIR				; Read all bytes
	POP	BC
	POP	IX			; Get file info start address (HL) into IX
	LD	A, (IX + 11)		; Get file attributes
	BIT	4, A			; Check if directory
	JR	Z, _done		; Not a directory
	LD	(IX + 8), 'D'		; If directory set file type to "DIR"
	LD	(IX + 9), 'I'
	LD	(IX + 10), 'R'
_done:
	XOR	A			; Success
	POP	IX			; Restore IX
	RET

;-------------------------------------------------
;          Lowercase->Uppercase
;-------------------------------------------------
; in-out; A = char
;
UpperCase:
       CP  'a'     ; >='a'?
       RET  C
       CP   'z'+1  ; <='z'?
       RET  NC
       SUB  20H    ; a-z -> A-Z
       RET

; TBD: Replace (41-1) with (pathsize - 1)
;----------------------------------------------------------------
;                         Set Path
;----------------------------------------------------------------
;
;    In:    HL = string to add to path (NOT null-terminated!)
;            A = string length
;
;   out:    DE = original end of path
;            Z = OK
;           NZ = path too long
;
; path with no leading '/' is added to existing path
;         with leading '/' replaces existing path
;        ".." = removes last subdir from path
;
dos__set_path:
        PUSH   BC
        LD     C,A               ; C = string length
        LD     DE,PathName
        LD     A,(DE)
        CP     '/'               ; does current path start with '/'?
        JR     Z,.gotpath
        CALL   usb__root         ; no, create root path
.gotpath:
        INC    DE                ; DE = 2nd char in pathname (after '/')
        LD     B,41-1            ; B = max number of chars in pathname (less leading '/')
        LD     A,(HL)
        CP     '/'               ; does string start with '/'?
        JR     Z,.rootdir        ; yes, replace entire path
        JR     .path_end         ; no, goto end of path
.path_end_loop:
        INC    DE                ; advance DE towards end of path
        DEC    B
        JR     Z,.fail           ; fail if path full
.path_end:
        LD     A,(DE)
        OR     A
        JR     NZ,.path_end_loop
; at end-of-path
        LD     A,'.'             ; does string start with '.' ?
        CP     (HL)
        JR     NZ,.subdir        ; no
; "." or ".."
        INC    HL
        CP     (HL)              ; ".." ?
        JR     NZ,.ok            ; no, staying in current directory so quit
.dotdot:
        DEC    DE
        LD     A,(DE)
        CP     '/'               ; back to last '/'
        JR     NZ,.dotdot
        LD     A,E
        CP     PathName & 0FFH   ; at root?
        JR     NZ,.trim
        INC    DE                ; yes, leave root '/' in
.trim:  XOR    A
        LD     (DE),A            ; NULL terminate pathname
        JR     .ok               ; return OK
.rootdir:
        PUSH   DE                ; push end-of-path
        JR     .nextc            ; skip '/' in string, then copy to path
.subdir:
        PUSH   DE                ; push end-of-path before adding '/'
        LD     A,E
        CP     (PathName & 0FFH)+1   ; at root?
        JR     Z,.copypath       ; yes,
        LD     A,'/'
        LD     (DE),A            ; add '/' separator
        INC    DE
        DEC    B
        JR     Z,.undo           ; if path full then undo
.copypath:
        LD     A,(HL)            ; get next string char
        CALL   dos__char         ; convert to MSDOS
        LD     (DE),A            ; store char in pathname
        INC    DE
        DEC    B
        JR     Z,.undo           ; if path full then undo and fail
.nextc: INC    HL
        DEC    C
        JR     NZ,.copypath      ; until end of string
.nullend:
        XOR    A
        LD     (DE),A            ; NULL terminate pathname
        JR     .copied
; if path full then undo add
.undo:  POP    DE                ; pop original end-of-path
.fail:  XOR    A
        LD     (DE),A            ; remove added subdir from path
        INC    A                 ; return NZ
        JR     .done
.copied:
        POP    DE                ; DE = original end-of-path
.ok     CP     A                 ; return Z
.done:  POP    BC
        RET

;------------------------------------------------------------------------------
;              Convert Character to MSDOS equivalent
;------------------------------------------------------------------------------
;  Input:  A = char
; Output:  A = MDOS compatible char
;
; converts:-
;     lowercase to upppercase
;     '=' -> '~' (in case we cannot type '~' on the keyboard!)
;
dos__char:
        CP      'a'
        JR      C,.uppercase
        CP      'z'+1          ; convert lowercase to uppercase
        JR      NC,.uppercase
        AND     5FH
.uppercase:
        CP      '='
        RET     NZ             ; convert '=' to '~'
        LD      A,'~'
        RET
