#!/usr/bin/perl
# vp 11.04.2019 

die <<HELP unless @ARGV;
Aufruf: p2adr pfile
extrahiert Anfangsadresse und Startadr. aus p-File
Startadr. kann hinter END in ASM-Datei angegeben werden
Fehlt sie, wird aadr genommen
HELP

open IN, "<$ARGV[0]";
binmode IN;

#Aadr
seek IN, 6, 0;		# SEEK_SET
read IN, $block, 6; 

($aadr,$dummy,$len) = unpack('SSS',$block);	# große S!

$sadr = $aadr;

# Startadr.
seek IN, -60, 2;	# SEEK_END
read IN, $block, 60; 

if ($block =~ /\x80(....)\x00AS/) {
	($sadr) = unpack('S',$1);
}

close IN;

printf "%X %X\n", $aadr, $sadr;
