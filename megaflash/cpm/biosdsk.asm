;-----------------------------------------------------------------------------
; Logischer Diskettentreiber
;-----------------------------------------------------------------------------

;CPA-Source: BIOSDSK.MAC

; Laufwerksauswahl
;=================
; i C: Laufw. (0=A:, 1=B: ...)
; i E: Bit 0 ist LOGIN-Bit von BDOS (=0, wenn LOGIN)

seldsk:		call	dgetpb			; HL auf DPH stellen, IX auf DPB
		ret	z			; Geraet ex. nicht
		ld	a, c
		ld	(ddrive), a		; Laufwerk merken
		bit	0, e			; LOGIN von BDOS?
		ret	nz			; nein

		push	hl			; ^DPH merken
		ld	hl, dbdev
		cp	(hl)			; LOGIN fuer gepuffertes Device?
		jr	nz, seldsk1		; nein
		ld	(hl), 0FFh		; Puffer ist ungueltig
		ld	hl, dbflg
		res	2, (hl)			;kein veraend. Puffer auszug.!

seldsk1:	bit	6, (ix+0Fh)		;Formaterkennung unterdr.?

;;		IF BIOSVER = 'CPMZ9OK'
;;
;;		jp	nz, seldsk23		;ja
;;
;;		ELSEIF BIOSVER <> 'CPMZ9OK'

		jr	z, seldsk1a
		ld	(byte_5D17), a
		ld	l, (ix+0Dh)
		ld	h, (ix+0Eh)
		ld	(word_5D18), hl
		ld	hl, unk_5D16
		call	dsktra
		jp	z, seldsk23
		pop	hl
		ld	hl, 0
		ret
seldsk1a:	equ	$

;;		ENDIF

		call	dbtrw			;Puffer freimachen und auf Lesen schalten
		ld	hl, dbnb
		ld	(hl), 0FFh		;Puffernummer ist ungueltig, obwohl evtl.
						;alle anderen Pufferparameter stimmen
						;(da nur 128 Bytes vom Puffer belegt sind)
		ld	a, c
		ld	(dfrmdv), a
		ld	(dbdev), a
		xor	a
		ld	(ix+0Fh), a		;ruecksetzen alle Flags
		ld	(ix+13h), a		;keine Weiter-Numm. auf Ruecks.
		ld	(ix+0Dh), a		;keine Systemspuren
		ld	(dfrmtr), a		;Spur 0
		ld	(dbtrk), a
		ld	(dbtrk+1), a
		inc	a
		ld	(dbsec), a		;Sektor 1
		ld	(dbsnb), a		;1 phys. Sektor lesen
; Stellen  Sektor-Translate-Tabelle 1,2,3,...
		push	ix
		ld	b, 1Ah			;max. Laenge der Tabelle
seldsk2:	ld	(ix+19h), a
		inc	ix
		inc	a
		djnz	seldsk2
		pop	ix
; Positionieren auf Spur 0 und analysieren Systemspuren
		call	dsidtr			;beliebigen Sekt.Id lesen
		jr	nz, seldsk6		;Fehler beim Lesen; Systemsp. annehmen
		ld	a, h
		ld	(dbslc), a		;setzen Spurformat fuer Sp. 0
		ld	hl, dbflg
		ld	b, (hl)			;merken Fehlerprotokoll-Bit
		set	4, (hl)			;kein Fehlerprotokoll
		push	hl
		call	dbtran			;Lesen Spur 0, Sektor 1
		pop	hl
		ld	(hl), b			;setzen Standard fuer Fehlerprotokoll-Bit
		jr	nz, seldsk6		;Fehler, Systemspuren annehmen
		push	iy
		ld	iy, (dbdma)
		ld	a, (iy+0)		;Format-Loeschbyte
		cp	0E5h			;leere Diskette/geloeschter Eintrag?
		jr	nz, seldsk3		;nein, weder/noch
		cp	(iy+1)			;auch danach 0e5h?
		jr	nz, seldsk4		;nein, geloeschter Dir-Eintrag
		dec	(ix+0Dh)		;Flag: leere Disk oder leere Systemsp.
		jr	seldsk4			;dpbofs auf 254
;
seldsk3:	cp	40h			;IBM-Format (SIOS-Daten-Diskette)?
		jr	z, seldsk5		;ja, 0 Systemspuren annehmen
		cp	20h			;<=31 ? ("S"YL ist groesser!)
		jr	nc, seldsk5		;nein, kann kein Directory sein; 0 Systemsp.
;Systemlader fuer PC1715 beginnt mit 02 oder 03
		ld	a, (iy+20h)		;bei SCP1715-Systemdiskette dort 00h, bei MicroDos dort 10h
		or	(iy+21h)		;bei SCP1715-Systemdiskette dort 00h, bei CP/A dort Dir-Eintrag (E5 oder Filename)
		jr	z, seldsk5		;beides 00h, kein Directory; 0 Systemsp.
seldsk4:	dec	(ix+0Dh)		;=255, wenn Directory; =254 wenn vorn leer
seldsk5:	pop	iy

seldsk6:
; Analysieren Datenspur

; SS/DS-Analyse
		ld	(ix+12h), 2		;Doppel-Step-Impulse
		ld	a, 3			;auf LOGIN-Spur
		call	dsidtt			;belieb. SektId Vorderseite lesen
		jr	nz, seldsk9		;Fehler, unsicheres Format
		ld	d, h			;d:=Sektorlcode, e:=Spur

;if dskds
		bit	0, (ix+18h)		;ist es ein DS-Laufwerk?
		jr	z, seldsk7		;nein, SS
		push	de			;merken Sektorlaengencode und Spur
		set	5, (ix+0Fh)
		ld	a, 7			;Rueckseite der Spur, ab der Format bei SS konstant
		call	dsidtt			;beliebigen Sekt.Id Ruecks. lesen
		ld	a, d			;merken side Ruecks.
		ld	l, e			;h:=Sektorlcode, l:=Spur Rueckseite
		pop	de			;wiederherstellen Vorderseite
		jr	nz, seldsk7		;Fehler beim Lesen, SS
		or	a
		sbc	hl, de			;Vorder- gleich Rueckseite?
		jr	z, seldsk8		;ja; 40 Tr/ 80 Tr unterscheiden
seldsk7:	res	5, (ix+0Fh)


; 40/80 Track Analyse
seldsk8:	ld	a, e			;trk
		sub	3			;waren 2 Steps richtig?
		jr	z, seldsk10		;ja
		dec	(ix+12h)		;Einzelstep-Impulse
		sub	3			;waere 1 Step richtig?
		jr	z, seldsk10		;ja
						;nein, unsicher
seldsk9:	ld	(ix+10h), 0FFh		;provozieren 'BAD SECTOR'
		ld	hl, 0			;erzeugen 'SELECT' Error
		ex	(sp), hl
		jp	seldsk23

; DS/SS und 40/80 ist unterschieden, es fehlt Sektorlaenge
seldsk10:	ld	a, d
		ld	(ix+10h), a		;definieren Sektorlaengencode
		or	a			;Sektorlaenge 128?
		jr	nz, seldsk11		;nein, Puffer reicht nicht

; Stellen Sektor-Translate-Tabelle 1,7,13,..
seldsv:		push	ix
		pop	hl
		ld	bc, 19h
		add	hl, bc
		ex	de, hl
		ld	hl, xlt
		ld	c, 1Ah
		ldir

seldsk11:	call	dtrsla			;stellen hl entspr. Sektorlaenge
		jr	nz, seldsk9		;unzulaessig
		ld	bc, 5			;Laenge eines Eintrags
		bit	1, (ix+12h)		;40 Tr. auf 80er LW?
		jr	nz, seldsk12		;ja
		ld	a, (ix+16h)		;40er LW?
		cp	40+1
		jr	c, seldsk12		;ja, 40 Tr. auf 40er LW
		add	hl, bc			;auf 80er Format stellen
seldsk12:	bit	5, (ix+0Fh)		;DS?
		jr	z, seldsk13		;nein
		add	hl, bc			;auf DS Format
		add	hl, bc

; DPB modifizieren entsprechend erkanntem Format
seldsk13:	ld	c, (hl)			;Zahl der benutzten Spuren
		ld	(ix+14h), c
		inc	hl
		ld	c, (hl)			;Anzahl 128er Sektoren pro Spur
		ld	(ix+0),	c
		inc	hl
		ld	c, (hl)			;Anzahl der Dir-Eintraege -1
		inc	hl
		ld	a, (hl)			;Anzahl der Systemspuren
		srl	a			;feste Anzahl erzwungen?
		jr	c, seldsk15		;ja
		bit	7, (ix+0Dh)		;kann Spur 0 Directory sein?
		jr	z, seldsk15		;nein, Standardanzahl setzen
		inc	(ix+0Dh)		;evtl. leere Systemspur?
		jr	z, seldsk14		;nein, 0 Systemspuren
		ld	b, a			;retten Anzahl Systemspuren
		ld	(dbtrk), a		;einlesen evtl. moeglicher Datenbeginn
		push	hl
		call	dbtran			; dauert bei falscher Spur etwas laenger
		pop	hl
		ld	a, b
		jr	nz, seldsk15		;Fehler, mit Systemspuren annehmen
		push	iy
		ld	iy, (dbdma)
		ld	a, (iy+0Eh)		;falls dort Dir, so Byte 14 von Dir =0
		cp	0E5h			;Daten auch leer?
		pop	iy
		ld	a, b
		jr	nz, seldsk15		;nein, vorn liegen nichtbelegte Systemspuren
seldsk14:	xor	a			;sonst ohne Systemspuren
seldsk15:	ld	(ix+0Dh), a
		or	a			;0 Systemspuren?
		jr	z, seldsk16		;ja
		ld	a, c			;Anzahl Dir-Eintraege -1
		cp	192-1			;>=192 Dir-Eintraege ?
		jr	c, seldsk16		;nein
		ld	c, 128-1		;780k hat 128 Dir-Eintraege
seldsk16:	ld	(ix+7),	c
		inc	hl
		ld	c, (hl)			;Abstand der Blockgroessentab.
		ld	b, 0
		add	hl, bc			;auf Blockgroessentabelle
		ld	c, (hl)
		ld	(ix+2),	c
		inc	hl
		ld	c, (hl)
		ld	(ix+3),	c
		inc	hl
		ld	c, (hl)
		ld	(ix+4),	c

; Bestimmen Zahl der abweichenden 128er-Sektoren ab Spur 0
		xor	a
		ld	(dfrmtr), a		;ab Spur 0
						;(gleichz. Spurkorr. bei falschen Doppelstepimpulsen)
seldsk17:	call	dsidtr			;beliebigen SektId lesen
		jr	nz, seldsk18		;Fehler
		ld	a, h			;Sektorlaenge
		cp	(ix+10h)		;gleich Disketten-Rest?
		jr	z, seldsk18		;ja
		ld	a, (ix+0Fh)
		and	3			;bisherige Anzahl abweichender Spuren
		cp	3			;Zaehler voll?
		jr	z, seldsk18		;ja
		inc	(ix+0Fh)		;erhoehen abweich. Spurzahl
		ld	hl, dfrmtr		;naechste (logische!) Spur
		inc	(hl)
		jr	seldsk17

seldsk18:
; Setzen Anzahl der logischen 128er Rekords im Puffer -1
; Es wird immer das Maximum gesetzt, dies setzt eine dichte
; Sektorfolge beim Transfer voraus! (so in dpbstr)
		ld	(ix+11h), 7

; Berechnen Speicherkapazitaet-1 in BDOS-Bloecken aus
; ((Tracks-dpbofs)*dpbspt/(2**dpbbls))-1
		ld	l, (ix+14h)
		xor	a
		ld	h, a			;hl:=log. Spurzahl
		ld	e, (ix+0Dh)
		ld	d, a			;de:=log. offset-Spurzahl
		sbc	hl, de
		ex	de, hl			;de:=log. Daten-Spurzahl
		ld	l, a			;hl:=0
		ld	b, (ix+0)
seldsk19:	add	hl, de
		djnz	seldsk19		;hl:=(tracks-dpbofs)*dpbspt
		ld	b, (ix+2)
seldsk20:	srl	h
		rr	l
		djnz	seldsk20
		dec	hl
		ld	(ix+5),	l
		ld	(ix+6),	h
		ld	a, (ix+7)		;Dir-Groesse
		inc	a
;;		IF  BIOSVER <> 'CPMZ9OK'
		and	0FCh
;;		ENDIF
		rrca
		rrca				;div 4, da 4 Dir-Eintr. /Sekt.
		ld	(ix+0Bh), a		;ist Sektorzahl = Check size
		ld	b, (ix+2)		;block shift
seldsk21:	rrca				;BDOS-Bloecke fuer Dir.
		djnz	seldsk21
		ld	b, a
		xor	a
seldsk22:	scf				;Allocation-Bits fuer Dir.
		rra
		djnz	seldsk22
		ld	(ix+9),	a

seldsk23:	pop	hl			;hl auf DPH
		ret				;Return Seldsk

;-----------------------------------------------------------------------------
; home
; auf Spur 0 zurueck (vor jedem Dir-Zugriff)
;-----------------------------------------------------------------------------

home:		ld	hl, dbflg
		bit	2, (hl)			;veraenderter Puffer?
		jr	nz, home1		;ja, nicht freigeben
		ld	a, 0FFh			;sonst Diskwechsel erlauben
		ld	(dbdev), a		;Puffer ist nicht aktiv

;-----------------------------------------------------------------------------
; settrk
; Einstellen Spur in Reg. BC
;-----------------------------------------------------------------------------

home1:		ld	bc, 0
settrk:		ld	(dtrack), bc
		ret

;-----------------------------------------------------------------------------
; Einstellen Sektor in Reg. BC
;-----------------------------------------------------------------------------
setsec:		ld	(dsectr), bc
		ret

;-----------------------------------------------------------------------------
; Einstellen DMA in Reg. BC
;-----------------------------------------------------------------------------
setdma:		ld	(ddma), bc
		ret

;-----------------------------------------------------------------------------
; Uebersetzung Sektornummer
; Translate-Tab-Adr. in DE, Eingangs-Sektornummer in BC,
;			    Ausgangs-Sektornummer in HL
; Es wird keine Translate-Tabelle benutzt, da die Sektor-
; nummernverwaltung verallgemeinert im nicht-Standard-DPB
; enthalten ist (auch fuer physische Sektorlaenge <>128)
;-----------------------------------------------------------------------------
sectran:	ld	h, b
		ld	l, c
		inc	hl		;Sektoren zaehlen in CP/A ab 1
		ret

; Ermitteln DPH und DPB von (c) nach HL bzw. IX
; ret z		DPH existiert nicht, HL=0
; ret nz	ok, HL auf DPH, IX auf DPB
; BC,DE bleibt erhalten
dgetpb:		push	de
		ld	hl, 0
		ld	a, c
		cp	2		; nur LW 0 und 1 erlaubt
		jr	nc, dgetpb1 	; sonst Abbruch
		ex	de, hl		; DE = 0
		ld	hl, dphtab	; Adresstabelle fuer DPH's
		ld	e, c
		add	hl, de
		add	hl, de
		ld	a, (hl)
		inc	hl
		ld	h, (hl)
		ld	l, a		; HL=Adr. zum LW gehöriger DPH
		push	hl
		ld	e, 10
		add	hl, de
		ld	e, (hl)
		inc	hl
		ld	d, (hl)		; de:=^dpb
		push	de
		pop	ix		; IX=Adr. zugehöriger DPB
		pop	hl
dgetpb1:	pop	de
		ld	a, h
		or	l		; ret z bei hl=0
		ret

;-----------------------------------------------------------------------------
; Schreiben Sektor
; Register C (vom BDOS gestellt):
;	=0, wenn normales write
;	=1, wenn directory-write (sofort ausgeben)
;	=2, wenn Beginn eines neuen Datenblocks (kein preread)
;-----------------------------------------------------------------------------
write:		ld	e, c			;retten Reg. C
		ld	a, (ddrive)
		ld	c, a
		call	dgetpb			;ix:=dpb(ddrive)
		jr	z, drwerr		;Geraet ex. nicht

		ld	hl, dflg
		set	2, (hl)			;Write-Flag setzen
		ld	hl, dbflg
		set	0, (hl)			;Annahme preread notwendig
		ld	a, e			;A:= Write-Typ
		ld	(dwrtyp), a		;merken Write-Typ
		cp	2			;write to unallocated?
		jr	nz, write1		;nein
		ld	a, (ix+3)		;Zahl der 128-Sekt. im Block -1
		inc	a
		ld	(unacnt), a		;fuer diese Sekt. kein preread
		ld	hl, unadev
		ld	(hl), c

		ld	hl, (dtrack)
		ld	(unatrk), hl
		ld	a, (dsectr)
		ld	(dbnb), a

write1:		ld	hl, unacnt
		ld	a, (hl)
		or	a			;noch nicht geschr. Sekt. da?
		jr	z, alloc		;nein
		dec	a			;sonst Restzahl -1
		ld	(hl), a
		inc	hl
		ld	a, c
		cp	(hl)			;gleiches Geraet?
		jr	nz, alloc		;nein
		inc	hl
		ld	a, (dtrack)
		cp	(hl)			;gleiche Spur?
		jr	nz, alloc		;nein
		inc	hl
		ld	a, (dtrack+1)
		cp	(hl)
		jr	nz, alloc
		inc	hl
		ld	a, (dsectr)
		cp	(hl)			;gleicher Sektor?
		jr	nz, alloc		;nein
; Vorbereiten naechsten unalloc write-Aufruf
		cp	(ix+0)			;neue Spur?
		jr	c, write2		;nein
		dec	hl
		ld	d, (hl)
		dec	hl
		ld	e, (hl)
		inc	de
		ld	(hl), e
		inc	hl
		ld	(hl), d
		inc	hl
		xor	a			;Sektor auf Spuranfang
write2:		inc	a			;naechster Sektor
		ld	(hl), a
		ld	hl, dbflg
		res	0, (hl)			;anzeigen kein preread notw.
		jr	drw

; Abbruch read/write mit E/A-Fehler
drwerr:		ld	a, 1
		ret

;-----------------------------------------------------------------------------
; Lesen Sektor
;-----------------------------------------------------------------------------
read:		ld	a, (ddrive)
		ld	c, a
		call	dgetpb			;ix:=dpb(ddrive)
		jr	z, drwerr		;Geraet ex. nicht
		ld	hl, dflg
		res	2, (hl)			;Lesen anzeigen
		ld	hl, dbflg
		set	0, (hl)			;preread notwendig
		ld	a, 2
		ld	(dwrtyp), a

alloc:		xor	a
		ld	(unacnt), a		;Ende unalloc

; gemeinsamer Zweig read/write Floppy
drw:		ld	a, (dsectr)		;Sektornummer in 1..dpbspt ?
		dec	a			;ab 0 zaehlen
		jp	m, drwerr		;<0, Fehler
		cp	(ix+0)			;<dpbspt?
		jr	nc, drwerr		;nein, Fehler
		ld	b, a			;retten dsectr-1
		ld	a, (ix+0Fh)
		and	3			;Anzahl der abweich. 128er Spuren
		ld	e, a
		ld	d, 0
		ld	hl, (dtrack)
		or	a
		sbc	hl, de
		jp	c, drwsec		;ja, Sektorlaenge 128

		ld	a, (ix+10h)		;phys. Sektorlaenge 128?
		or	a			;d.h. mit Sektorversatz?
		jp	z, drwsec		;ja, keine Pufferung sinnvoll

		ld	a, b
		ld	d, (ix+11h)		;Puffermaske
		and	d			;rel. Sekt.nr. des BDOS-Blocks zum Puff.anf.
		push	af			;merken fuer move
		xor	b			;a ist Sektornr. des Puff.anf.
drwbnr:		srl	a			;ermitteln Puffernr in Spur
		rr	d			;noch Bits in Puffermaske?
		jr	nz, drwbnr		;ja
; Test, ob dieser Puffer da ist
		push	af			;merken Puffernummer
		ld	hl, dbnb
		cp	(hl)			;richtige Puffernummer?
		jr	nz, dbn			;nein
		ld	hl, (dtrack)
		ld	de, (dbtrk)
		or	a
		sbc	hl, de
		jr	nz, dbn
		ld	a, (dbdev)		;zum Puffer gehoeriges Geraet
		cp	c			;richtiges Geraet?
		jr	z, dbmat		;ja, Sektor steht im Puffer

dbn:		push	bc			;retten ddrive
		call	dbtrw			;veraenderten Puffer ausgeben
		pop	bc			;c:=ddrive
		ld	hl, dbdev
		ld	(hl), c
		ld	hl, (dtrack)
		ld	(dbtrk), hl
		call	dgetpb			;ix:=dpb(c)
		ld	b, (ix+10h)
		ld	hl, dbslc
		ld	(hl), b
		ld	a, (ix+11h)		;Zahl der 128er Sektoren -1
		inc	a
		add	a, a			;CY:=0
		inc	b			;fuer djnz, falls dpbslc=0
dbsnbz:		rrca				;Zahl der phys. Sekt. im Puff.
		djnz	dbsnbz
		ld	d, a			;merken
		xor	a
		pop	bc			;b:=geforderte Puffernr.
		push	bc
		ld	hl, dbnb
		ld	(hl), b
		inc	b
		dec	b			;Puffernr. 0?
		jr	z, dbsec0		;ja
dbsecz:		add	a, d			;0. phys. Sekt. im Puffer
		djnz	dbsecz			;=dbsnb.*Puffernr.
dbsec0:		ld	e, a			;merken Pufferanf.-Sektor
		ld	b, (ix+10h)
		ld	a, (ix+0)
		inc	b			;wegen djnz
		add	a, a
dbsecm:		srl	a			;phys. Sektoranzahl
		djnz	dbsecm
		sub	e			;Restsektorzahl auf Spur
		cp	d			;>= Zahl zu transferierender?
		jr	nc, dbseco		;ja
		ld	d, a			;sonst nur Restsektorzahl
dbseco:		inc	e			;Sektoren zaehlen ab 1
		ld	a, e
		ld	(dbsec), a		;Sektor
		ld	a, d
		ld	(dbsnb), a		;Sektorzahl
		ld	hl, dbflg
		res	2, (hl)
		bit	0, (hl)			;muss neuer Puffer gel. werden?
		jr	nz, dbprr		;ja
; nur dann kein preread, wenn Rest BDOS-Block >= phys. Puff.
; und Rest BDOS-Block auf Pufferanfang beginnt
		ld	a, (unacnt)
		cp	(ix+11h)		;Restzahl-1 >= Puffergr.-1 ?
		jr	c, dbprr		;nein, preread
		ld	a, (dsectr)		;Sektornr.
		dec	a			;ab 0 zaehlen
		and	(ix+11h)		;rel. Sekt.nr. des BDOS-Blocks zum Pufferanfang
		jr	nz, dbprr
		ld	(dberrf), a		;fehlerfrei gel. anzeigen
dbprr:		call	nz, dbtran		;Puffer lesen

; Sektor in/aus Puffer holen
dbmat:		pop	af			;Puffernr. in Spur wegschm.
		pop	af			;128-er Index im Puffer
		push	af
		rra				;Sektornb*128 berechnen
		ld	b, a
		ld	c, 0
		rr	c
		ld	hl, fdcbuffer
		add	hl, bc			;Adresse im Puffer
		ld	de, rwbuffer	;--> in CPA: ld	de,(ddma)	;Nutzer-DMA
		ld	a, (dflg)
		bit	2, a			;Schreiben?
		jr	z, dsmove		;nein
		ld	a, (dbflg)
		set	2, a			;anzeigen Puffer beschrieben
		ld	(dbflg), a
		ex	de, hl
dsmove:		ld	bc, 128
		call	flldir
		pop	af			;128-Index im Puffer
		cp	(ix+11h)		;letzter Sektor im Puffer
		jr	z, dmovew		;ja, Puffer ausgeben
		ld	a, (dwrtyp)
		cp	1			;write to directory?
dmovew:		call	z, dbtrw		;ja, veraend. Puffer ausgeben
		ld	a, (dberrf)		;Ergebnis letztes dbtran
		ret

; Schreiben Puffer, wenn notw.
dbtrw:		ld	hl, dbflg
		bit	2, (hl)			;Puffer veraendert?
		ret	z			;nein, Schreiben unterdruecken

; gemeinsamer Zweig Lesen/Schreiben Puffer
dbtran:		ld	hl, dbflg
		call	dsktra
		ld	(dberrf), a		;Fehlerflag stellen
		ld	hl, dbflg
		res	2, (hl)			;Puffer ist nicht beschrieben
		ret

; Lesen beliebigen Sektor-Id.
dsidtt:		ld	(dfrmtr), a		;Eingang fuer Spur in A
dsidtr:		ld	hl, dfrcdb
		jr	dsktra

; gemeinsamer Zweig Read/Write 128-Sektor einzeln
drwsec:		ld	hl, dflg


;*********************************************************
; Umkleidung des physischen Disketten-Transfers
;*********************************************************

; Parameter: HL auf CDB mit folgender Struktur:
; +0: cdbfl	;Flags	(Struktur angepasst an ft.kom)
diof00	equ	0	;** frei fuer Anw. ** (frueher Verify nach Schreiben)
diofid	equ	1	;fest	;=1, wenn nur Sektid. zu lesen
diofwr	equ	2	;fest	;=1, wenn Schreiben
dioffm	equ	3	;fest	;=1, wenn temporaer FM-Format erzwungen
dioftr	equ	4		;=1, wenn keine Fehlermeldung (und -behandlg)
diofhd	equ	5		;=1, wenn Kopf hochnehmen ("noerr")
diofps	equ	6		;=1, wenn trk,sid,sec schon physisch
diofs1	equ	7	;fest	;=1, wenn Rueckseite

; ab hier unwichtig bei "diofhd" in cdbfl =1 (noerr)
; +1: cdbdev	;logisches Geraet 0 .. dphnb-1
; +2: cdbtrk	;log./phys. Spur
; +3: cdbsid	;bel./phys. Seite
; +4: cdbsec	;log./phys. Sektor
; +5: cdbslc	;Sektorlaengencode (0=128, 1=256, 2=512, 3=1024)
; +6: cdbsnb	;Anz. zu uebertr. ph. Sekt. (wenn =0, so nur position.)
; ab hier nur wichtig, wenn "diofid" in cdbfl =0:
; +7,8: cdbdma	;Transferadresse

; Return, falls nicht "diofhd" in cdbfl =1:
;	A=0 (ret z) bei fehlerfrei, sonst A=1 (ret nz) bei cdbfl, "dioftr" =0
;	oder Returncode phys. Transfer
;	E:=trk, D:=sid ,L:=sec, H:=len
;	BC,IX unveraendert

dsktra:		push	bc
		ld	de, diocdb		;CDB des Nutzers auf internen Hilfsspeicher
		ld	bc, 9			;da modifiziert
		push	de
		call	flldir			;falls Original im ROM-Adressbereich
		pop	hl			;hl auf diocdb
		pop	bc
		bit	5, (hl)			;Kopf hochnehmen?
		jp	nz, noerr		;ja, kein Transfer
		push	bc
		push	ix
		push	hl
		inc	hl
		ld	c, (hl)			;logisches Laufwerk
		call	dgetpb			;IX auf DPB stellen
		pop	hl			;wiederherstellen hl
		ld	a, 'D'			;falls LW nicht ex.
		jp	z, dioert		;LW ex. nicht
		bit	6, (hl)			;trk,sid,sec schon physisch?
		jr	nz, diophy		;ja
; Track, Side und Sector entpsr. Diskettenformat setzen
		inc	hl
		inc	hl
		ld	d, (hl)			;Track
		ld	e, d			;merken
		inc	hl
		inc	hl
		ld	c, (hl)			;Sektornummer ab 1
		dec	c			;Sektornr. ab 0
		bit	4, (ix+0Fh)		;Fortsetzung Dsk. auf Ruecks.?
		jr	nz, diots2		;ja
		bit	5, (ix+0Fh)		;ungerade Spuren auf Rueckseite?
		jr	z, diotrs		;nein, einseitig
		srl	d			;Spur halbieren
		jr	nc, diotrs		;gerade Spur, Vorderseite
		jr	diots1			;auf Rueckseite
diots2:		ld	b, (ix+14h)		;log. Spurzahl
		srl	b			;Spuren auf Vorderseite
		ld	a, d
		sub	b			;Spur auf Vorderseite?
		jr	c, diotrs		;ja, Spur in d unveraendert lassen
						;40 ->  0; 41 ->  1; ...; 79 ->  39
						;77 ->  0; 78 ->  1; ...;153 ->  76
		bit	3, (ix+0Fh)		;Ruecks. von aussen nach innen?
		jr	nz, diots4		;ja
		cpl				;40 -> -1; 41 -> -2; ...; 79 -> -40
						;77 -> -1; 78 -> -2; ...;153 -> -77
		add	a, b			;40 -> 39; 41 -> 38; ...; 79 ->   0
						;77 -> 76; 78 -> 75; ...;153 ->   0
diots4:		ld	d, a
diots1:		ld	a, (diocdb)
		set	7, a			;vermerken Rueckseite
		ld	(diocdb), a
		ld	a, (ix+13h)		;Versch. der Sektornr. auf Rueckseite
		add	a, c			;Sektornr. evtl. weiterzaehlen
		ld	c, a
		ld	a, 1			;side:=1
		jr	diotss

diotrs:		xor	a			;side:=0
diotss:		ld	(diocsi), a		;phys. Seite setzen
		ld	a, d
		ld	(dioctr), a		;phys. Spur setzen
		ld	a, e			;log. Spurnr. zurueck nach A
		push	ix
		pop	hl
		ld	de, 19h			;d:=0
		add	hl, de
		cp	(ix+0Dh)		;Systemspur?
		jr	c, diossp		;ja, Sektornummern nicht logisch
		ld	e, c
		add	hl, de			;HL entspr. Index in dpbstr
		ld	c, d			;c:=0
diossp:		ld	a, c			;phys. Sektornr. ab 0
		add	a, (hl)			;+echte Sektornr.
		ld	(diocse), a		;phys. Sektor setzen
diophy:
; i ret, BC, IX im Stack
; i cdb auf diocdb
; i IX auf DPB

;interne Wiederholung dsktra
		push	ix			;retten IX fuer evtl. Wiederholung
		ld	hl, diocdb
		push	hl
		ld	a, (hl)			;side 0/1, -/FM, read/write, -/sectid l.
		and	8Eh			;(1 shl diofs1)+(1 shl dioffm)+(1 shl diofwr)+(1 shl diofid)
		ld	b, a
		ld	a, (ix+18h)		;5"/8", FM/MFM, 40/80, Verify nach Schreiben
		and	78h			;and (1 shl dpbt80)+(1 shl dpbt5z)+(1 shl dpbtdd)+(1 shl dpbtwv) ;aus DPB
		xor	b
		bit	4, (hl)			;Fehlerbehandlung unterdruecken?
		jr	z, dionft		;nein
		inc	a
dionft:		ld	(ft.kom), a
		inc	hl
		ld	a, (ix+15h)		;physische LW-Nr.
		ld	(ft.lwn), a
		inc	hl
		ld	a, (hl)
		ld	(ft.trk), a
		inc	hl
		ld	a, (hl)
		ld	(ft.sid), a
		inc	hl
		ld	a, (hl)
		ld	(ft.sec), a
		inc	hl
		ld	a, (hl)
		ld	(ft.len), a
		inc	hl
		ld	a, (hl)
		ld	(ft.anz), a		;Anzahl der Stepimpulse
		ld	a, (ix+12h)		;Schrittzeit
		ld	(ft.stp), a
		ld	a, (ix+17h)
		ld	(ft.sti), a
		ld	hl, (diocad)
		ld	(ft.adr), hl
		call	floppy			;$$$ phys. Transfer $$$
		pop	hl			;HL wieder auf Paramfeld-Adresse
		pop	ix			;IX wieder auf DPB

; Fehlerprotokoll
dioert:		bit	4, (hl)			;Fehlerprotokoll und -behandlung  unterdr.?
		jr	nz, dtrok		;ja
		or	a			;Returncode
		jr	z, dtrok		; -> fehlerfrei
		cp	'R'			;not ready?
		jp	z, diophy		;ja, Wiederholung
		ld	(derrcd), a		;Fehlercode
		bit	2, (hl)			;war lesen?
		ld	a, 'R'
		jr	z, derrr		;ja
		ld	a, 'W'
derrr:		ld	(derrrw), a
		ld	hl, ft.trk		;phys. Spur
		ld	de, derrtr	; "XXXXXX\a"
		call	mbreco		; (HL) nach hex	konvertieren, Eintragen	nach (DE), 2x inc DE
		ld	hl, ft.trk+1
		call	mbreco		; (HL) nach hex	konvertieren, Eintragen	nach (DE), 2x inc DE
		ld	hl, ft.sec		;Seite
		call	mbreco		; (HL) nach hex	konvertieren, Eintragen	nach (DE), 2x inc DE
		ld	hl, derrms
		call	biosms
		ld	a, 1		;return mit Fehler
dtrok:		or	a		;stellen Z-Flag
		ld	de, (ft.trk)	;E:=trk, D:=sid
		ld	hl, (ft.sec)	;L:=sec, H:=len
		pop	ix
		pop	bc
		ret

; Stellen HL entsprechend Sektorlaengencode in (A)
; ret nz bei unzulaessigem
dtrsla:		or	a
		ld	hl, dtrsl0	; bei A=0 (128)
		ret	z
		dec	a
		ld	hl, dtrsl1	; bei A=1 (256)
		ret	z
		dec	a
		ld	hl, dtrsl2	; bei A=2 (512)
		ret	z
		dec	a
		ld	hl, dtrsl3	; bei A=3 (1024)
		ret

;************************************************
;	Steuertabellen
;************************************************

; Modifizierungstabellen entspr. Sektorlaenge und LW-Typ
;-------------------------------------------------------

; Struktur:

dsltrk	equ	0		;benutzte Spuren
dslspt	equ	dsltrk+1	;Sektoren/Spur
dsldir	equ	dslspt+1	;Dir-Eintraege
dsloff	equ	dsldir+1	;2*offset
				;[+Flag fuer festes offset]
dslfo	equ	1		;festes offset
dslvo	equ	0		;offset =0, falls Directory mgl.
dslblk	equ	dsloff+1	;rel. Adr. Tab. BDOS-Blockgroesse
dsll	equ	5		;Laenge eines Eintrags

; Reihenfolge
; 5", 40 Tr, SS
; 5", 80 Tr, SS
; 5", 40 Tr, DS
; 5", 80 Tr, DS

; 128
dtrsl0:
	db	40,26,63,2*2+dslvo,dbl1k-$-4	;CP/M Standard
	db	80,26,127,2*2+dslvo,dbl2k-$-4
	db	80,26,127,2*0+dslfo,dbl2k-$-4
	db	160,26,127,2*0+dslfo,dbl2k0-$-4

; 256
dtrsl1:
	db	40,32,63,2*3+dslfo,dbl2k-$-4	;SCP Hausformat A51xx
	db	80,32,63,2*3+dslfo,dbl2k-$-4	;SCP
	db	80,32,127,2*4+dslfo,dbl2k-$-4
	db	160,32,127,2*4+dslfo,dbl2k0-$-4	;SCP Hausformat PC1715

; 512
dtrsl2:
	db	40,36,63,2*0+dslfo,dbl1k-$-4
	db	80,36,127,2*0+dslfo,dbl2k-$-4
	db	80,36,127,2*0+dslfo,dbl2k-$-4
	db	160,36,127,2*0+dslfo,dbl2k0-$-4

; 1024
dtrsl3:
	db	40,40,63,2*2+dslvo,dbl1k-$-4	;CP/A Standard A51xx
	db	80,40,127,2*2+dslvo,dbl2k-$-4	;CP/A
	db	80,40,127,2*0+dslvo,dbl2k-$-4	;CP/A
	db	160,40,191,2*4+dslvo,dbl2k0-$-4	;CP/A (und SCP)

; Modifizierungstabellen fuer BDOS-Blockgroesse
dbl1k:	db	3,7,0		;Bl. Shift, Bl. Mask, Ext. Mask
dbl2k:	db	4,0fh,1
dbl2k0:	db	4,0fh,0		;fuer Kapazitaet >255

; log. Sektortranslate-Tabelle fuer 26*128
xlt:	db	1,7,13,19,25,5,11,17,23,3,9,15,21
	db	2,8,14,20,26,6,12,18,24,4,10,16,22


; Fehlermeldung Disk I/O Error
; Genau so lang (kurz), wie in Statuszeile Platz dafuer da ist!
; und das sind 17 Bytes!

derrms:		db	 0Dh ;
		db	 0Ah ;
derrrw:		db	'X'
derrcd:		db	"X;T,Si,Se="
derrtr:		db	"XX"
derrts:		db	"XX"
derrsc:		db	"XX"
		db	7
		db	0

;;		IF BIOSVER <> 'CPMZ9OK'
unk_5D16:	db  10h
byte_5D17:	db 0FFh
word_5D18:	dw 0
		db    1 ;
		db    1 ;
		db    0 ;
;;		ENDIF

; CDB fuer Bestimmung Spurformat
dfrcdb:		db	 12h 		;(1 shl diofid)+(1 shl dioftr)
dfrmdv:		db	0FFh		;Geraet
dfrmtr:		db	0FFh		;Spur
		db	0FFh 		;Seite (bel.)
		db	   1 		;Sektor (bel.)
;;		IF BIOSVER = 'CPMZ9OK'
;;		db	   0 		;Sektorlaengencode (bel.)
;;		ELSEIF BIOSVER <> 'CPMZ9OK'
		db	   1 		;
;;		ENDIF
		db	   1 		;Sektoranzahl (>0)

; Puffer-CDB
dbflg:	db	0
dbdev:	db	0FFh
dbtrk:	db	0FFh
dbsid:	db	0FFh
dbsec:	db	0FFh
dbslc:	db	0FFh
dbsnb:	db	0FFh
dbdma:	dw	fdcbuffer

; CDB fuer ungepufferte E/A
dflg:	db	0
ddrive:	db	0
dtrack:	db	0FFh
	db	0FFh 		;Seite
dsectr:	db	0FFh
	db	0 		;128 Bytes Sektorlaenge
	db	1 		;immer nur 1 Sektor

unacnt:	db	0
unadev:	db	0FFh
unatrk:	db	0FFh
unasec:	db	0

dbnb:	db	0FFh
dwrtyp:	db	0FFh
dberrf:	db	0		;Ergebnisflag letztes dbtran

;Arbeitsbereiche logischer Floppy-Treiber im BIOS-RAM
flldir:		ldir		;Floppy-Puffer <-> Nutzer-DMA
		ret

;CDB-Hilfsspeicher fuer dsktra-Aufruf
diocdb:	db	0FFh
diocde:	db	0FFh
dioctr:	db	0FFh
diocsi:	db	0FFh
diocse:	db	0FFh
diocsl:	db	0FFh
diocsn:	db	0FFh
diocad:	dw	0FFFFh


