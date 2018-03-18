#!/usr/bin/perl -w

use strict;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use htmlmodule::Html;
use htmlmodule::DbDefs;


#getting the database from the form that calls dbstart.pl 
my $output = new CGI;
my $databasename = $output->param('database');




#getting the path for the cgi-directory of the perl-scripts
#gibt Pfad zurück, in dem alle Skripte liegen
my $httppath = &DbDefs::httppath();  


#print header for the html-site with Html::header
#html-header für die Seite ausdrucken mit modul Html::header 

my $htmltitle = "Reference Database";


&Html::header($httppath, $htmltitle);

&Html::frame();

#&Html::body();

#&Html::menu($httppath, $databasename);


print "<\/html>\n";
