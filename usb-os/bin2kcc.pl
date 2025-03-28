#!/usr/bin/perl
# vp 14.02.2018 erstellt

die <<HELP unless @ARGV;
Aufruf: bin2kcc bin-file [aadr] [sadr] [typ]
konvertiert bin-Dateien ins KCC-Format

HELP

$aadr = (oct '0x'.$ARGV[1]) || 0x100;
$sadr = (oct '0x'.$ARGV[2]) || $aadr;
$ext = $ARGV[3] || 'com';

($OUT = $ARGV[0]) =~ s/\..*/.$ext/i;

open IN, "<$ARGV[0]";
binmode IN;

open OUT, ">$OUT";
binmode OUT;

print "Schreibe $OUT ";


#Kopfblock schreiben
$name=uc $ARGV[0];
$name =~ s#\\#/#g;	#dos->unix
$name =~ s#.*/##;	#remove path
$name =~ s/\.(.*)//;	#remove ext
#print $name,"\n";

$size= -s $ARGV[0];

printf "NAME=%s SIZE=%s AADR=%.4X SADR=%.4X\n", $name,$size, $aadr, $sadr;

#KC-Header
print OUT pack("
	a8		   # dateiname: array[0..7] of char;
	a3		   # dateityp: array[0..2] of char;
	xx		   # e1, e2: byte;
	xxxc		   # psum, arb, blnr, lblnr: byte;
	sss		   # aadr, eadr, sadr: word;
	x		   # sby: byte;
	", $name, uc $ext, 3, $aadr, $aadr+$size-1, $sadr
);

print OUT "\x00"x(128-24);  # 1. Block für MC mit 00 auffüllen

#Daten schreiben
until (eof IN) {
	read IN, $block, 128; 
	if (eof (IN)) { $blocknr = 255 }	# der letzte Block erhält die Nr. FF
	# print OUT pack("C",$blocknr++);
	print OUT pack("a128", $block);
}

close IN;
close OUT;
