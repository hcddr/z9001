#!/usr/bin/perl
# vp 31.10.2009 erstellt

$IN = $ARGV[0] || 'disk2.dum';

# Datei komplett einlesen
open IN, "<$IN";
binmode IN;
$dsk = '';
until (eof IN) {
	# Block
	read IN, $_, 100*1024;
	$dsk .= $_;
}
close IN;

$dsk = reverse $dsk;

while (substr($dsk,$i++,1) eq "\xE5") {}

open OUT,">$IN.asm";
print OUT "disk2filledsize\tequ ",length($dsk)-$i+1, "\n";
close OUT;
