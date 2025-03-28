#!/usr/bin/perl
# vp 31.10.2009 erstellt

$OUT = $ARGV[0] || 'leerdisk.dum';

open OUT, ">$OUT";
binmode OUT;

$ARGV[1] ||= 800;

print OUT "\xE5"x($ARGV[1]*1024);  # 800K-Diskette, mit E5 init.

close OUT;
