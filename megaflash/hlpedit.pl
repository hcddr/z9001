#!/usr/bin/env perl

# Editor für HLP-Dateien für das Mega-Modul zum KC87
# Textdateien mit Farbmarkerungen
# <RED> <GREEN> <YELLOW> <BLUE> <MAGENTA> <CYAN> <WHITE>
# feste Fensterbreite von 40 Zeichen
# weitere Umwandlung in internes Format mit hlp2bin

# Oberfläche hlpedit.ui erstellt mit guibuilder-win32-ix86-20070129.exe
# vp120919

use Tk;
use strict;
use hlpedit_ui;


#------------------------------------------------------------------------------
# Main
#------------------------------------------------------------------------------

our $version='Version 0.9';

my $infile;
my $filepath = '';

hlpedit::userinit() if defined &hlpedit::userinit;

our $top = MainWindow->new();
$top->title("hlpedit Z9001 Mega-Flash");
hlpedit::ui($top);


#Tags definieren
$hlpedit::text->tagConfigure('RED', -foreground => 'red');
$hlpedit::text->tagConfigure('GREEN', -foreground => 'green');
$hlpedit::text->tagConfigure('YELLOW', -foreground => 'yellow');
$hlpedit::text->tagConfigure('BLUE', -foreground => 'blue');
$hlpedit::text->tagConfigure('MAGENTA', -foreground => 'magenta');
$hlpedit::text->tagConfigure('CYAN', -foreground => 'cyan');
$hlpedit::text->tagConfigure('WHITE', -foreground => 'white');

$top->bind('<F2>', \&hlpedit::mb_load);
$top->bind('<F3>', \&hlpedit::mb_save);
$top->bind('<F4>', \&hlpedit::mb_saveas);

hlpedit::run() if defined &hlpedit::run;

Tk::MainLoop();

1;

#------------------------------------------------------------------------------
# Hilfe
#------------------------------------------------------------------------------

sub hlpedit::mb_help {
  	$hlpedit::menu->messageBox (-title => 'Info über', -message => <<"EOF", -type => 'OK')
© 2012
Volker Pohlers

Programm zum Erstellen und Bearbeiten
der Hilfe-Dateien für das HELP-Kommando
des Mega-Flash-Moduls zum KC87

$version
EOF
}

#------------------------------------------------------------------------------
# Datei laden
#------------------------------------------------------------------------------

sub hlpedit::mb_load {

    	my $types = [ 
    		['text files', ['*.hlp', '*.txt'] ],
    		['all files', '*']
    	   ];			# Filetypen
	my $path = $filepath;
	$path =~ tr|/|\\|;					# Backslashes bilden

	$infile = $top->getOpenFile(-filetypes => $types, -initialdir => $path);	# FileDialog

	return 0 unless defined($infile);			# Abbruch, falls "Abbrechen" gedrückt

	open (FILE, $infile) or return 0;

	# wenn Datei gefunden, dann alten Text löschen
	$hlpedit::text->delete("1.0", "end");		# alten Text löschen

	# Text einlesen
	local $/;
	my $text = <FILE>;
	close(FILE);

	# Farben in Tags umwandeln
	my $color = 'GREEN';	# Standardfarbe
	while ($text =~ /(.*?)<(RED|GREEN|YELLOW|BLUE|MAGENTA|CYAN|WHITE)>/gs) {
		$hlpedit::text->insert("end", "$1", $color); #Text in alter Farbe einfügen
		$color = $2; #neue Farbe
	}
	# Text hinter letzter Farbmarkierung
	$text =~ /.*>(.*)$/gs;
	$hlpedit::text->insert("end", "$1", $color); #restl. Text einfügen
}

#------------------------------------------------------------------------------
# Datei speichern
#------------------------------------------------------------------------------

sub hlpedit::mb_saveas {
    	my $types = [ 
    		['text files', ['*.hlp', '*.txt'] ],
    		['all files', '*']
    	   ];			# Filetypen
	my $path = $filepath;
	$path =~ tr|/|\\|;					# Backslashes bilden

	$infile = $top->getSaveFile(-filetypes => $types, -initialdir => $path, -initialfile => $infile);	# FileDialog

	hlpedit::mb_save();
}

sub hlpedit::mb_save {

	return unless $infile;					# Abbruch, falls "Abbrechen" gedrückt

	open (FILE, '>'.$infile) or return;
	$hlpedit::text->dump(-command => \&mysave, '1.0', 'end');
	close FILE;
}

sub mysave {
	my ($key, $value, $index) = @_;
	#print "$key, <<$value>>\n";
	if ($key eq 'tagon') { print FILE "<$value>" } 
	if ($key eq 'text') { print FILE "$value" } 
}

#------------------------------------------------------------------------------
# Farbe setzen
#------------------------------------------------------------------------------

sub hlpedit::btn_color {
	my $color = $_[0];
	return unless $hlpedit::text->tagRanges('sel');
	
	#Tags innerhalb der Selection entfernen bzw. verkleinern
	my $mark = $hlpedit::text->index('sel.first');
	my $text = $hlpedit::text->getSelected;
	$hlpedit::text->deleteSelected;
	
	$hlpedit::text->insert($mark, $text, $color);
}

#------------------------------------------------------------------------------
# sonstiges
#------------------------------------------------------------------------------

sub hlpedit::text_xscrollcommand {
}
