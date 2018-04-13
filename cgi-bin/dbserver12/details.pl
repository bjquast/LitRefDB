#!/usr/bin/perl -w

use strict;


use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use dbmodule::DbConnect;
# use dbmodule::AllDatafromDoc;
use htmlmodule::PrintDetails;
use htmlmodule::Html;
use dbmodule::TablefromDoc;

my $output = new CGI();

my $databasename;
unless ($databasename = $output->param('database')) {
    $databasename = &DbDefs::database();
}


# connect to database
my $dbcon = DbConnect->new(database => $databasename);
my $dbhandle = $dbcon->connect_to_db();

my $httppath = &DbDefs::httppath;  #returns path for all scripts

#html-header für die Seite ausdrucken mit modul Html::header 
# print html-header
my $htmlcaption = "Results";
&Html::header($httppath, $htmlcaption);
&Html::body();


my @doc_ids = $output->param('doc_id');
my $questionid = $output->param('questionid');
my $resultpart = $output->param('resultpart');
my $checked = $output->param('checked');
my $sorting = $output->param('sorting');




if ((@doc_ids) && (defined($questionid)) && (defined($resultpart)) && (defined($checked)) && (defined($sorting))) { #welche müssen wirklich definiert sein? defined nötig, da einige den Wert 0 haben können


    print "<form action=\"${httppath}central.pl\" method=\"POST\" enctype=\"multipart/form-data\">";
    print "\n";

    my $doc_idsref = \@doc_ids;
    my $temptable = &TablefromDoc::docidstable($dbhandle, $doc_idsref);
    my $ergebnishashref = &TablefromDoc::flattablehash($dbhandle, $temptable);


    print "<div id\=\"detailhead\">\n";

    print "\n";
    print "<table cellspacing=\"1\" cellpadding=\"3\" border = \"0\"\n";
    print "<tr valign = \"top\">\n";
    
    print "<td>\n"; 
    print '<input type="radio" name="action" value="change"checked="checked"> change ';
    print '<input type="radio" name="action" value="delete"> delete ';
    print '<input type="radio" name="action" value="insert"> insert new dataset ';
    print '<input type="radio" name="action" value="insert_as_new"> insert as new dataset ';
    print "</td>\n";


    print "<td>\n"; 
    print "<input type=\"submit\" value=\"submit \"><input type=\"reset\" value=\"reset\">\n";
    print "</td>\n";
    
    print "</tr>\n";
    print "</table>\n";
    
    print "</div>\n";



    print "<div id\=\"detailtable\">\n";
#my $ergebnishashref = &AllDatafromDoc::search($dbhandle, $doc_idsref);
    my $erfolg = &PrintDetails::detailsoutput ($ergebnishashref, $databasename, $httppath, $checked);
    print "</div>\n";


    print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">";
    print "<input type = \"hidden\" name = \"details\" value = \"on\">";
    print "<input type = \"hidden\" name = \"questionid\" value = \"$questionid\">";
    print "<input type = \"hidden\" name = \"resultpart\" value = \"$resultpart\">";
    print "<input type = \"hidden\" name = \"checked\" value = \"$checked\">";
    print "<input type = \"hidden\" name = \"sorting\" value = \"$sorting\">";
#my $docidstring = join (";", @doc_ids);
#print "<input type = \"hidden\" name = \"hiddendocids\" value = \"$docidstring\">";



    print '</form>';
}

else {

    print "<form action=\"${httppath}central.pl\" method=\"POST\" enctype=\"multipart/form-data\">";
    print "\n";

    print "<div id\=\"detailhead\">\n";

    print "\n";
    print "<table cellspacing=\"1\" cellpadding=\"3\" border = \"0\"\n";
    print "<tr valign = \"top\">\n";
    
    print "<td>\n"; 
    print '<input type="radio" name="action" value="insert"> insert new dataset ';
    print "</td>\n";


    print "<td>\n"; 
    print "<input type=\"submit\" value=\"submit \"><input type=\"reset\" value=\"reset\">\n";
    print "</td>\n";
    
    print "</tr>\n";
    print "</table>\n";
    
    print "</div>\n";


}


&Html::foot();

























