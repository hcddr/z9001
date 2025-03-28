#!/usr/bin/perl
# vp 13.12.2012, letzte Änderung 15.12.2012 

use List::Util qw[min max];

die <<HELP unless @ARGV;
Aufruf: tap2fa tap-file 
konvertiert AF-TAP-Dateien ins (raw) BIN-Format (mit FA-Header)
HELP

open IN, "<$ARGV[0]";
binmode IN;

($OUT = $ARGV[0]) =~ s/\.tap/\.bin/i;
die "Fehler: keine TAP-Datei!" if $OUT =~ /$ARGV[0]/i;

print "$OUT ";
open OUT, ">$OUT";
binmode OUT;

# Header lesen
sysread IN, $block, 16; 
if ($block ne 'ÃKC-TAPE by AF. ') {
	close IN;
	print 'Kein TAP-Format!';
	exit;
}

# Kopfblock einlesen und Typ auswerten

# Blocknummer
sysread IN, $block, 1;
# block
sysread IN, $block, 128;


if ( $block =~ /^(\xD3\xD3\xD3|\xD7\xD7\xD7)/ ) {
	# if Basic
	print "BASIC\n";
	$ft_typ = 1;
	
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

	#print FA-Header
	syswrite OUT, pack("
		CC	# db	0FAh, 0FAh	; +0 Kennbytes
		C	# db	Dateityp	; +2 0-MC, 1-BASIC (s. includes.asm)
		A8	# db	'NAME    '	; +3 genau 8 Zeichen
		S	# dw	aadr		; +11 Anfangsadresse im RAM
		S	# dw	eadr		; +13 Endadresse im RAM
		S	# dw	sadr		; +15 Startadresse im RAM (oder FFFFh - nichtstartend)
		S	# dw	länge		; +17 (Datei-)Länge des nachfolgenden Programms
		C	# db	Dateikategorie	; +19 Standard 0 (s. includes.asm)
		a12	# db	'Kommentar   '	; +20 12 Zeichen, bel., z.B. Autor o.ä.
	"
	, 0xFA,0xFA, $ft_typ, uc $name, 0x401, 0x0401+$filelength, 0, $filelength, 0, $typ
	);

	# Header löschen
	substr($block,0,13) = '';
	$filelength += 13;	# Offset von gelöschtem Header

	syswrite OUT, $block, min($filelength, 128); 
	$filelength -= 128;
	
	while ($filelength > 0) {
		# Blocknummer
		sysread IN, $block, 1; 
		printf "%.2lX ", ord $blocknr;
		
		# Block
		sysread IN, $_, 128;
		syswrite OUT, $_, min($filelength, 128);
		$filelength -= 128;
	}
	syswrite OUT, "\x03";
	
	close IN;
	close OUT;
	
	
} else {# if nicht-basic
	print "MC\n";
	$ft_typ = 0;

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

	#$filelength = $eadr-$aadr;
	# eigentlich
	$filelength = $eadr-$aadr + 1;


	#print FA-Header
	syswrite OUT, pack("
		CC	# db	0FAh, 0FAh	; +0 Kennbytes
		C	# db	Dateityp	; +2 0-MC, 1-BASIC (s. includes.asm)
		A8	# db	'NAME    '	; +3 genau 8 Zeichen
		S	# dw	aadr		; +11 Anfangsadresse im RAM
		S	# dw	eadr		; +13 Endadresse im RAM
		S	# dw	sadr		; +15 Startadresse im RAM (oder FFFFh - nichtstartend)
		S	# dw	länge		; +17 (Datei-)Länge des nachfolgenden Programms
		C	# db	Dateikategorie	; +19 Standard 0 (s. includes.asm)
		a12	# db	'Kommentar   '	; +20 12 Zeichen, bel., z.B. Autor o.ä.
	"
	, 0xFA,0xFA, $ft_typ, uc $name, $aadr, $eadr, $sadr, $filelength, 0, $typ
	);

	#print "name $name, typ $typ, filelength $filelength\n";
	
	while ($filelength > 0) {
		# Blocknummer
		sysread IN, $block, 1; 
		#printf "%.2lX ", ord $block;
		
		# Block
		sysread IN, $_, 128;
		#print OUT $_; # wäre ok für 'neue_anwender' 
		syswrite OUT, $_, min($filelength, 128);
		$filelength -= 128;
	}
	
	close IN;
	close OUT;
}
