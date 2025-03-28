#!/usr/bin/perl

die <<HELP unless @ARGV;
Aufruf: $0 picture3.com
extrahiert gepacktes image aus Paintbox-COM-Datei
as: binclude picture3.com.pic
HELP

open IN, "<$ARGV[0]";
binmode IN;

open OUT, ">$ARGV[0].pic";
binmode IN;

#Kopfblock überlesen
sysread IN, $block, 128; 

do {
	$blocksize = sysread IN, $block, 128; 
	
	$block =~ /\x01/g;
	$p = pos($block);
	print $i++, " $p\n";

	if ($p) {
		syswrite OUT, $block, $p;
		$blocksize=0;
	} else	{
		syswrite OUT, $block, $blocksize;
	}
} until ($blocksize==0);

close IN;
close OUT;
