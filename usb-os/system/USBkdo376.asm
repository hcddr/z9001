;-----------------------------------------------------
;
;	UTools Version 1.5 (von M. Leubner)
;
; Hilfsprogramme zur Arbeit mit USB-Sticks unter CP/M
;
;	USB-Direktkommando ausfuehren
;
; Umsetzung auf Z9001-OS: V:Pohlers 20.04.2016 
;-----------------------------------------------------

	cpu	Z80

	section usbkdo
	public	   erakdo

erakdo:
	ld	de, CONBU+2	; Filename direkt aus Konsolenbuffer holen
	call	SPACE		; Leerzeichen übergehen
	ex	de, hl
	call	usb__delete
	jr	nz, era_error
	xor	a
	ret
era_error:	
	ld	a, 13
	scf
	ret

	endsection
