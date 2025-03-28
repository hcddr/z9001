#!/usr/bin/perl
# vp 02.04.2012, last modified 09.06.2020

use List::Util qw[min max];
use File::Basename;


die <<HELP unless @ARGV;
Aufruf: hlp2bin textfile
konvertiert HLP-Dateien ins BIN-Format
- Endebyte 00 wird angefügt
- Farben werden interne Steuercodes konvertiert
  <RED> <GREEN>	<YELLOW> <BLUE> <MAGENTA> <CYAN> <WHITE>
HELP

#########################################
# konvertieren in Z9001-Codes
#########################################

open IN, "<$ARGV[0]";

($OUT = $ARGV[0]) =~ s/$/.bin/i;
print "$OUT ";
open OUT, ">$OUT";
binmode OUT;

while (<IN>) {
	chomp;
	s/<RED>/\x14\x01/g;
	s/<GREEN>/\x14\x02/g;
	s/<YELLOW>/\x14\x03/g;
	s/<BLUE>/\x14\x04/g;
	s/<MAGENTA>/\x14\x05/g;
	s/<CYAN>/\x14\x06/g;
	s/<WHITE>/\x14\x07/g;
	print OUT $_, "\r\n";
}

print OUT $line, "\x00";	# Ende-Kennzeichen
close OUT;
close IN;

#########################################
# include-Datei erstellen
#########################################

($INC = $ARGV[0]) =~ s/$/.bin.inc/i;
open INC, ">$INC";
{
	$typ = 'HELP';
	$aadr = 0x7800;
	$filelength = -s $OUT;
	$eadr = $aadr + $filelength;
	$sadr = 0xFFFF;
	$name = uc basename($ARGV[0]); $name=~ s/\..*//;

	print "name $name, typ $typ, aadr $aadr, eadr $eadr, sadr $sadr\n";

	my $fname = $OUT;
	$fname =~ s#^.*?/##;	# erstes Verzeichnis abtrennen f.as build 147ff.
	
	printf INC qq(	addFile "$fname.zx7", 0%02Xh, 0%02Xh, 0%02Xh, "$name", ft_HELP+ft_packed, fk_unknown+fk_hidden, "$typ"\n), $aadr, $eadr, $sadr;

	$filelength = $eadr-$aadr + 1;

	#print "name $name, typ $typ, filelength $filelength\n";
	
	close INC;
}
