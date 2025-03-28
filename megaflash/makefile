#
# Makefile für Z9001/Z1013 MEGA-ROM-Modul (2.5M-Modul)
# VPohlers 14.09.2011

# Anpassen an den Speicherort des Arnold-Assemblers

AS=d:\\hobby3\\programme\\as\\bin\\asw.exe
P2BIN=d:\\hobby3\\programme\\as\\bin\\p2bin.exe
PERL=d:\\perl\\bin\\perl.exe


DEPENDFILE = .depend

#make		für Emulator
ALL:	system.asm $(DEPENDFILE) packedroms.bin megarom.bin
	$(PERL) megarom_chksum.pl
	$(PERL) showrom.pl

KOMBI:	packedroms.bin
	$(PERL) showrom.pl $<
	copy /y packedroms.bin kombimodul.bin

#make roms	für MegaROM
MEGA:	$(DEPENDFILE) packedroms.bin megarom_1.bin megarom_2.bin megarom_3.bin
	$(PERL) megarom_chksum.pl
	$(PERL) showrom.pl

#make roms	für MegaFlash
FLASH:	$(DEPENDFILE) packedroms.bin rom_1.bin rom_2.bin rom_3.bin rom_4.bin rom_5.bin
	$(PERL) megarom_chksum.pl
	$(PERL) showrom.pl

depend .depend:
	$(PERL) mkdepend.pl *.asm */*.asm > $(DEPENDFILE)
	echo.  > megarom_chksum.inc
	echo.  > kombi_chksum.inc

chksum: packedroms.bin
	$(PERL) megarom_chksum.pl

.PHONY: system.asm
system.asm:	
	touch	systembank\system.asm
	touch	includes.asm

-include $(DEPENDFILE)

z80files.inc:
	$(PERL) create_z80filesinc2.pl

minicpm/%.dmp:
	cmd /c cd minicpm & do.cmd $(PERL)

# Assemblieren einer Datei
%.bin:	%.asm
	$(AS) -cpu Z80 -L $< -a
	$(P2BIN) -r \$$-\$$ $*.p
#	del $*.p

# Hilfedateien konvertieren
%.hlp.bin.zx7 %.hlp.bin.inc:	%.hlp
	$(PERL) hlp2bin.pl $<
	zx7.exe -f $<.bin

# Konvertieren
%.bin %.bin.inc:	%.tap
	$(PERL) tap2bin.pl $<

# Komprimieren
%.zx7:	%
	zx7.exe -f $<


CLEAN_FILES=*.bin

#make clean	Aufräumen
clean:	
	del /s *.p
	del /s *.lst
	del $(CLEAN_FILES)
#	del $(DEPENDFILE)


#make clobber	noch mehr aufräumen
clobber: clean
	del /s *.inc
	del /s *.bin
	del /s *.zx7
	del minicpm\disk*.dmp
	del $(DEPENDFILE)

DATE=$(strip $(shell date /t))

DISTFILES = *.asm  */*.asm  */*.rom */*.tap */*.hlp \
	makefile *.exe *.pl *.pm *.txt makeall.bat \
	minicpm/do.cmd minicpm/*.cmd minicpm/*.pl minicpm/*.exe \
	minicpm/diskvp*/*.* \
	megarom.bin .depend 00liesmich fileXname rom_?.bin kombimodul.bin megamodul.pdf

ROMFILES = 00liesmich  packedroms.*.txt megarom.bin rom_?.bin kombimodul.bin megamodul.pdf

t: 
	echo $(DATE)

#make dist	Quellarchiv packen
dist:
	zip -r mega_flash.$(DATE).zip $(DISTFILES)

dist2:
	zip -r mega_flash.xxx.zip $(DISTFILES)

distrom romdist:
	zip -r mega_flash_roms.zip $(ROMFILES)
