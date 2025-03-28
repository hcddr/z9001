#!/usr/bin/perl
# vp 04.08.2009, letzte Änderung 15.12.2012

use List::Util qw[min max];

die <<HELP unless @ARGV;
Aufruf: tap2bin tap-file
konvertiert AF-TAP-Dateien ins (raw) BIN-Format (ohne Header!)
HELP

open IN, "<$ARGV[0]";
binmode IN;

($OUT = $ARGV[0]) =~ s/\.tap/\.bin/i;
die "Fehler: keine TAP-Datei!" if $OUT =~ /$ARGV[0]/i;

print "$OUT ";
open OUT, ">$OUT";
binmode OUT;

($INC = $ARGV[0]) =~ s/\.tap/\.bin.inc/i;
open INC, ">$INC";

# Header lesen
read IN, $block, 16; 
if ($block ne 'ÃKC-TAPE by AF. ') {
	close IN;
	print 'Kein TAP-Format!';
	exit;
}

# Kopfblock einlesen und Typ auswerten

# Blocknummer
read IN, $block, 1;
# block
read IN, $block, 128;


if ( $block =~ /^(\xD3\xD3\xD3|\xD7\xD7\xD7)/ ) {
	# if Basic
	print "BASIC\n";
	
	# bei basic: Dateiname und Pgm-Länge übergehen
	
	# orig: die Programme wurden ins BASIC geladen und dann
	# Speicherabzug ab Adresse 300h
	

	#BASIC-Header
	($typ, $name, $filelength) = unpack("
		a3		   # typ
		a8		   # name
		S		   # laenge: word; #großes S!
		", $block
	);
	$name =~ s/\x0//g;
	$typ =~ s/\x0//g;

	print "typ $typ, name $name, Länge $filelength\n";

#	printf INC qq(	addFile "$OUT", 0%02Xh, 0%02Xh, 0%02Xh, "$name", ft_BASIC, fk_unknown, "$typ"\n), 0x0401, 0x0401+$filelength, 0;
	printf INC qq(	addFile "$OUT.zx7", 0%02Xh, 0%02Xh, 0%02Xh, "$name", ft_BASIC+ft_packed, fk_unknown, "$typ"\n), 0x0401, 0x0401+$filelength, 0;

	# Header löschen
	substr($block,0,13) = '';
	$filelength += 13;	# Offset von gelöschtem Header

	syswrite OUT, $block, min($filelength, 128); 
	$filelength -= 128;
	
	while ($filelength > 0) {
		# Blocknummer
		read IN, $block, 1; 
		#printf "%.2lX ", ord $blocknr;
		
		# Block
		read IN, $_, 128;
		syswrite OUT, $_, min($filelength, 128);
		$filelength -= 128;
	}
	
	close IN;
	close OUT;
	
	
} else {# if nicht-basic
	print "MC\n";

	# bei nicht basic nur bis letzte_adresse speichern (
	# das letzte Byte auf der Endadresse wird nicht gespeichert
	#Fehler von A.Schön ??? )

	#KC-Header
	($name, $typ, , , , , , , $aadr, $eadr, $sadr) = unpack("
		a8		   # dateiname: array[0..7] of char;
		a3		   # dateityp: array[0..2] of char;
		xx		   # e1, e2: byte;
		xxxx		   # psum, arb, blnr, lblnr: byte;
		SSS		   # aadr, eadr, sadr: word;	#großes S!
		x		   # sby: byte;
		", $block
	);

	$name =~ s/\x0//g;
	$typ =~ s/\x0//g;

	print "name $name, typ $typ, aadr $aadr, eadr $eadr, sadr $sadr\n";
	
	if ($eadr==0) {
		$filelength = -s IN;
		$filelength -= 16;			# TAP-Header abziehen
		$filelength = ($filelength/129)*128;	# kcc-Länge
		$filelength -= 128;			# Header abziehen
		$eadr = $aadr + $filelength-1;
	}

#	printf INC qq(	addFile "$OUT", 0%02Xh, 0%02Xh, 0%02Xh, "$name", ft_MC, fk_unknown, "$typ"\n), $aadr, $eadr, $sadr;
	printf INC qq(	addFile "$OUT.zx7", 0%02Xh, 0%02Xh, 0%02Xh, "$name", ft_MC+ft_packed, fk_unknown, "$typ"\n), $aadr, $eadr, $sadr;

	#$filelength = $eadr-$aadr;
	# eigentlich
	$filelength = $eadr-$aadr + 1;

	#print "name $name, typ $typ, filelength $filelength\n";
	
	while ($filelength > 0) {
		# Blocknummer
		read IN, $block, 1; 
		#printf "%.2lX ", ord $block;
		
		# Block
		read IN, $_, 128;
		#print OUT $_; # wäre ok für 'neue_anwender' 
		syswrite OUT, $_, min($filelength, 128);
		$filelength -= 128;
	}
	
	close IN;
	close OUT;
	close INC;
}
