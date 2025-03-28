; aus k:\hobby\hobby0\z9001 zm\idaszm1.rom
; reass VPohlers 24.09.2012
; macht ein versehentliches NEW vom ROMBASIC wieder rückgängig.


		cpu	z80

		org	0a200h

		jp	renew
		db	"RENEW	 ",0
		db	0

renew:		push	hl
		push	de
		push	af
		ld	hl, 404h
renew1:		inc	hl
renew2:		xor	a
		cp	(hl)
		jr	nz, renew1
		inc	hl
		inc	hl
		ld	a, 4
		cp	h
		jr	nz, renew5
		cp	(hl)
		dec	hl
		jr	nz, renew2
		ld	(401h),	hl
		jr	renew4
renew3:		ex	de, hl
renew4:		ld	a, (hl)
		inc	hl
		ld	d, (hl)
		ld	e, a
		or	d
		jr	nz, renew3
		inc	hl
		ld	(3D7h),	hl
renew5:		pop	af
		pop	de
		pop	hl
		ret

