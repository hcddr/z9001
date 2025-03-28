# 04.08.2009 Volker Pohlers
# erstellt dependecies-Datei für Arnold-Assembler

@ARGV = glob("@ARGV" || '*.asm');

#@ARGV = qw(vp/banktest.asm includes.asm);

#print "@ARGV\n";

# Aufsammeln
while (<>) {
	if (/^\s+(binclude|include|addfile)\s*"?(.*?)[",\s\n]/i) {
		#print "$_";
		#print "$ARGV: $2\n";
		$dep = $2;
		$dep =~ s#\\#/#g;
		$dependecies{$ARGV}{$dep} = 1;	# $dependecies{file}{include}
	}
}

# Zusammenfassen und Ausgeben
foreach $file (sort keys %dependecies) { 
	#print "$file:\t", join ( ' ', sort keys %{$dependecies{$file}} ), "\n" ;

	#für neue AS-Versionen > build 147 Unterverzeichnisse anders behandeln
	my ($subdir) = $file =~ m#(.+/)#;
	print "$file:\t", join ( ' ', sort ( 
		map { s#^.*/\.\./##; $_ }
		map { "$subdir$_" } keys %{$dependecies{$file}} ) ), "\n" ;
}
