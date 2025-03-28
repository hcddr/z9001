#!/usr/bin/perl
# vp 29.04.2016, letzte Änderung

$ARGV[0] ||= 'packedroms.bin';    # testweise

die <<HELP unless @ARGV;
Aufruf: showrom.pl rom
zeigt Inhalt des erzeugten ROMs ähnlich DIR L an
HELP

open IN, "<$ARGV[0]";
binmode IN;
print "liste $ARGV[0]...\n";


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



# Test auf Kombi-Modul
read IN, $block, 0x100;
if ( $uz_modul == 1 ) {
  open OUT, ">$ARGV[0]_kombi.txt";
  print OUT "Kombi-Modul\n\n";
} else {
  open OUT, ">$ARGV[0]_mega.txt";
  print OUT "Mega-Modul. Achtung: Die EPROM-Adressen passen nur auf packedroms.bin!\n\n";
}

seek IN, 0, 0;              # auf Fileanfang

print OUT "EPROM    Bnk+Adr_Z9001 Typ Name     aadr-eadr Länge_im_EPROM / Typ\n\n";

while ( !eof(IN) ) {
  $pos = tell IN;
#  printf "%.4x\n", $pos;
  
  # nächste integrale xx00-Adresse
  read IN, $block, 0x100;

  # Bank und Position in Bank berechnen
  $bank        = int( $pos / $banksize );
  $pos_in_bank = $pos - $bank * $banksize;

  if ($uz_modul) {
    #Kombimodul
    $bank = 2 * $bank;
    if ( $pos_in_bank >= 10 * 1024 ) {
      $bank++;
      $pos_in_bank -= 10 * 1024;
    }
  }

  # Analyse
  
  # FA-Kommando
  if ( $block =~ /^\xFA\xFA/ ) {
    #		$name = substr($block,3,8);
    ( $ft_typ, $name, $aadr, $eadr, $sadr, $filelength, $category, $comment ) =
      unpack( "
				xx	# db	0FAh, 0FAh	; +0 Kennbytes
				C	# db	Dateityp	; +2 0-MC, 1-BASIC (s. includes.asm)
				A8	# db	'NAME    '	; +3 genau 8 Zeichen
				S	# dw	aadr		; +11 Anfangsadresse im RAM
				S	# dw	eadr		; +13 Endadresse im RAM
				S	# dw	sadr		; +15 Startadresse im RAM (oder FFFFh - nichtstartend)
				S	# dw	länge		; +17 (Datei-)Länge des nachfolgenden Programms
				C	# db	Dateikategorie	; +19 Standard 0 (s. includes.asm)
				a12	# db	'Kommentar   '	; +20 12 Zeichen, bel., z.B. Autor o.ä.
			", $block );
    printf OUT "%.8X %.2X %.4X FA  %-8s %.4X-%.4X %.4X ", $pos, $bank,
      $pos_in_bank + 0xC000, $name, $aadr, $eadr, $filelength;
    printf OUT "/ %.2X %.5s ", $ft_typ,
      ( 'MC', 'BASIC', 'HELP' )[ $ft_typ & 0x07 ]; # typ hex und dekodiert
    print OUT "\n";
  }
  # OS-Kommandos
  elsif ( $block =~ /^\xC3.{10}\x00/ ) {
    do {
      $name = substr( $block, 3, 8 );
      printf OUT "%.8X %.2X %.4X kdo %s\n", $pos, $bank, $pos_in_bank + 0xC000,
        $name;

      $block = substr( $block, 12 );
      # printf "%.2X %.2X %.2X %.2X %.2X %.2X %.2X %.2X %.2X %.2X %.2X %.2X\n", unpack ("CCCCCCCCCCCC",$block);
      
    #} while ( $block =~ /^\xC3.{10}\x00/ );
   } while ( $block =~ /^\xC3/ );
  }
}

close IN;
close OUT;

