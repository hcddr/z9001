#!/usr/bin/perl
# vp 04.02.2010 13:54, letzte Änderung 07.07.2020 09:00:40


# Prüfsummen erzeugen

$ARGV[0] = 'packedroms.bin';

open IN, "<$ARGV[0]";
binmode IN;

print "chkrom $ARGV[0]...\n";


# Test auf Kombi-Modul
read IN, $block, 0x100;
if ( $block =~ /KOMBI-MODUL/ ) {
  print "für Kombi/64K-SRAM-Modul\n";
  $uz_modul = 1;
  $banksize = 16 * 1024;    # 16K
} else {
  print "für Mega-Modul\n";
  $banksize = 10 * 1024;    # 16K
}
seek IN, 0, 0;              # auf Fileanfang 



if ($uz_modul == 1) {
	
	#f. Kombi-Modul
	
	open IN, "<$ARGV[0]";
	binmode IN;
	
	open OUT, ">kombi_chksum.inc";
	
	#Filetyp ermitteln
	for ($i=0; $i<256; $i++) {
		read IN, $block, 10*1024; # 10K
		
		$chksum = unpack ("%8C*", $block);	# 8 Bit
		print OUT "	db $chksum	; Bank$i\n";
	
		$i++;
		read IN, $block, 6*1024; # 6K
		
		$chksum = unpack ("%8C*", $block);	# 8 Bit
		print OUT "	db $chksum	; Bank$i\n";
	}

	close OUT;
	
} else {

	open OUT, ">megarom_chksum.inc";
	
	#Filetyp ermitteln
	for ($i=0; $i<256; $i++) {
		read IN, $block, 10240; # 10K
		
		#$chksum = unpack ("%16C*", $block);	# 16 Bit
		#print OUT "	dw $chksum	; Bank$i\n";
	
		$chksum = unpack ("%8C*", $block);	# 8 Bit
		print OUT "	db $chksum	; Bank$i\n";
	}
	
	close OUT;
	
}

close IN;
