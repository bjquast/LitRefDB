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


my @doc_ids = $output->param('doc_id');
my $exportall = $output->param('exportall');


print "<form action=\"${httppath}export.pl\" method=\"POST\" enctype=\"multipart/form-data\">\n";



print "<h4>Select filetype to export</h4>\n";
	    
print "<h4><input type=\"radio\" name=\"filetype\" value=\"ris\" checked>  ris (Reference Manager)</input></h4>\n";
print "<h4><input type=\"radio\" name=\"filetype\" value=\"bibtex\">  bibtex</input></h4>\n";
print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">";

print "<h4><input type =\"checkbox\" name = \"owner_data\" value = \"on\" checked=\"checked\"> export only my own datasets </h4>";

print "<h4><input type =\"checkbox\" name = \"notext\" value = \"on\"> do not export abstract and notes </h4>";

print "<h4><input type =\"checkbox\" name = \"pdfzip\" value = \"on\" checked=\"checked\"> export as zip-file with PDFs</h4>";

print "<input type = \"hidden\" name = \"doc_ids_string\" value = \"@doc_ids\">";
print "<input type = \"hidden\" name = \"exportall\" value = \"$exportall\">";

print '<p><input type="submit" value="save"><input type="reset" value="zur&uuml;cksetzen"></p>';

print '</form>';



#print foot of the html-site

&Html::foot();


#




