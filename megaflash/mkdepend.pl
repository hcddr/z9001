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

# 2. Ebene beachten
foreach $file (keys %dependecies) { 
	foreach $subfile (keys %{$dependecies{$file}}) {        
		if (%{$dependecies{$subfile}}) {
			foreach $subsubfile (keys %{$dependecies{$subfile}}) {
				#print "$file --> $subfile --> $subsubfile\n";
				$dependecies{$file}{$subsubfile} = 2;
			}
		}
	}
}


# Zusammenfassen und Ausgeben
foreach $file (sort keys %dependecies) { 
	#print "$file:\t", join ( ' ', sort keys %{$dependecies{$file}} ), "\n" ;
	my $bin=$file;
	$bin =~ s/\..+/.bin/;
	#print "$bin:\t$file ", join ( ' ', sort keys %{$dependecies{$file}} ), "\n" ;

	#für neue AS-Versionen > build 147 Unterverzeichnisse anders behandeln
	my ($subdir) = $file =~ m#(.+/)#;
	print "$bin:\t$file ", join ( ' ', sort ( 
		map { s#^.*/\.\./##; $_ }
		map { "$subdir$_" } keys %{$dependecies{$file}} ) ), "\n" ;
}
