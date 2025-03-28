#
# Makefile für Z9001
# VPohlers 12.02.2021

# Anpassen an den Speicherort des Arnold-Assemblers

AS=d:\\hobby3\\programme\\as\\bin\\asw.exe
P2BIN=d:\\hobby3\\programme\\as\\bin\\p2bin.exe
PLIST=d:\\hobby3\\programme\\as\\bin\\plist.exe
PERL=d:\\perl\\bin\\perl.exe

# Zu erzeugende Dateien

FILES=chip8.com
SOURCES=PICTURE8.COM

ALL:	$(FILES)

chip8.bin: chip8.asm chip8intf.asm chip8intp.asm PICTURE8.COM.pic z9001.asm chip8hexi.asm

PICTURE%.COM.pic: PICTURE%.COM
	$(PERL) strip_picture.pl $<

# Assemblieren einer Datei
%.p %.bin:	%.asm
	$(AS) -cpu Z80 -L $< -a
	$(PLIST) $*.p
	$(P2BIN) -r \$$-\$$ $*.p
#	del $*.p

# Konvertieren
%.kcc %.com:	%.bin
	rem Anfangsadresse ermitteln
	$(PERL) bin2kcc.pl $< $(shell $(PERL) p2adr.pl $*.p)
	copy /y $@ *.kcc

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

ROMFILES=$(FILES) chip8.kcc chip8.txt ch8-2\*.* ch8-games\*.*

DISTFILES=$(ROMFILES) $(SOURCES) *.asm makefile *.exe *.pl 

#make dist	Quellarchiv packen
dist:
	zip -r chip8.$(DATE).zip $(DISTFILES)

dist2:
	zip -r chip8.xxx.zip $(DISTFILES)

distrom romdist:
	zip -r chip8-bin.zip $(ROMFILES)
