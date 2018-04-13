#!/usr/bin/perl -w

use strict;


use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use dbmodule::DbConnect;
use htmlmodule::Html;
use htmlmodule::DbDefs;




#getting the path for the cgi-directory of the perl-scripts
#gibt Pfad zurück, in dem alle Skripte liegen
my $httppath = &DbDefs::httppath();  


#print header for the html-site with Html::header
#html-header für die Seite ausdrucken mit modul Html::header 

my $htmltitle = "search for references";

&Html::header($httppath, $htmltitle);

&Html::body();

#getting the database from the form that calls searchform.pl 
my $output = new CGI;
my $databasename = $output->param('database');

my $dbcon = DbConnect->new(database => $databasename);
my $dbhandle = $dbcon->connect_to_db();




print "<form action=\"${httppath}fileimport.pl\" method=\"POST\" enctype=\"multipart/form-data\">\n";



print "<h4>Select file to import</h4>\n";


print "<h4><input type=\"checkbox\" name=\"ignore_doubles\" value=\"on\"> ignore duplicates while import</input></h4>\n";

	    
print "<h4> Datei\: <input type=\"file\" name=\"filehandle\"></h4>\n"; # maxlength=\"10000000\"></h4>\n"; # accept=\"text\/\*\"
print "<h4><input type=\"radio\" name=\"dateityp\" value=\"ris\" checked>  ris (Reference Manager)</input></h4>\n";
print "<h4><input type=\"radio\" name=\"dateityp\" value=\"bibtex\">  bibtex</input></h4>\n";

print "<h4><input type =\"checkbox\" name = \"inputzip\" value = \"on\"> load zip-file with datafile (*.ris or *.bib) and PDFs</h4>";

print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">\n";
print '<p><input type="submit" value="submit"><input type="reset" value="reset"></p>';



print '</form>';



#print foot of the html-site

&Html::foot();


#



