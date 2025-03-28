#
# Makefile für Z9001 USB-Paket
# VPohlers 01.03.2019

# Anpassen an den Speicherort des Arnold-Assemblers

AS=/home/ronald/tmp/install/as/asl-current/asl
P2BIN=/home/ronald/tmp/install/as/asl-current/p2bin
PLIST=/home/ronald/tmp/install/as/asl-current/plist
PERL=perl

DEPENDFILE = .depend

# Zu erzeugende Dateien

FILES=vdipos.rom ch376os.rom sdosc0.rom sdos.com sdos38.com comfiles\x.com usb-stick\load87
COMFILES=comfiles\basic.com comfiles\graf.com comfiles\grafp.com comfiles\graf14.com comfiles\crt40.com comfiles\hlpedit.com comfiles\zm30.com comfiles\zma8.com

ALL:	$(FILES) $(DEPENDFILE)
COM:	$(COMFILES)

depend .depend:
	$(PERL) mkdepend.pl *.asm */*.asm > $(DEPENDFILE)

-include $(DEPENDFILE)

usb-stick\load87: comfiles/x.com
	copy /y comfiles\x.com usb-stick\load87

# ROM-Files
%.rom: %.bin
	cp $< $*.rom

# Assemblieren einer Datei
%.p %.bin:	%.asm
	$(AS) -cpu Z80 -L $< -a
	$(PLIST) $*.p
	$(P2BIN) -r \$$-\$$ $*.p
#	del $*.p

# Konvertieren
%.com:	%.bin
	rem Anfangsadresse ermitteln
	$(PERL) bin2kcc.pl $< $(shell $(PERL) p2adr.pl $*.p)
	copy /y $@ usb-stick

# Konvertieren
%.kcc:	%.bin
	rem Anfangsadresse ermitteln
	$(PERL) bin2kcc.pl $< $(shell $(PERL) p2adr.pl $*.p)
	del $*.kcc
	ren $*.com $*.kcc

# Komprimieren
%.zx7:	%
	zx7.exe -f $<

#%.bin:	%.tap
#	$(PERL) kc2bin.pl $<

CLEAN_FILES=*.bin *.p *.inc

#make clean	Aufräumen
clean:	
	del /s $(CLEAN_FILES)
	del comfiles\*.com
#	del $(DEPENDFILE)

#make clobber	noch mehr aufräumen
clobber: clean
	del $(DEPENDFILE)

DATE=$(strip $(shell date /t))

ROMFILES=*.rom usb-stick/*.* *.txt usb-os.pdf sd-os.pdf

DISTFILES=$(ROMFILES) *.asm  */*.asm  makefile *.exe *.pl */*.zx7

#make dist	Quellarchiv packen
dist:
	zip -r usb-os.$(DATE).zip $(DISTFILES)

dist2:
	zip -r usb-os.xxx.zip $(DISTFILES)

distrom romdist:
	zip -r usb-os-bin.zip $(ROMFILES)
