#!/usr/bin/perl -w

use strict;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use htmlmodule::Html;
use htmlmodule::DbDefs;
use dbmodule::DbConnect;



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

#print $databasename;

print <<"HEAD";
<h1>zoosyst reference database</h1> 
HEAD


my $query;
my $result;
my @owners;

my $querytext = qq/select name from owner/;
unless ($query = $dbhandle->prepare($querytext)) {
    die "could not prepare ownerquery\n";
}
$query->execute();
while (($result) = $query->fetchrow_array) {
    push (@owners, $result);
}

my @searchfields = ("author / editor", "title", "keyword", "year", "species", "author", "editor", "abstract", "documenttitle", "journaltitle", "booktitle", "seriestitle");

my @orderfields = ("author", "title", "year");

print "\<table cellspacing=\"0\" cellpadding=\"1\" border=\"0\" bgcolor=\"\#FFE5A7\">\n";
print "<form action=\"${httppath}central.pl\" target = \"results\" method=\"POST\">\n";


print "<tr>\n";
print "<td colspan = \"2\"><b>simple search</b></td>\n";
print "<td></td>\n";
print "</tr>\n";

print "<tr>\n";
print "<td colspan = \"3\"><input type=\"text\" name=\"fastsearchstring\" size=30 maxlength=200></td>\n";
print "</tr>\n";



print <<"SUBMIT1";
    <tr><td colspan = "2"><p><input type="submit" value="submit">
    <input type="reset" value="reset"></p></td>
    <td></td>
    </tr>

SUBMIT1


print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">\n";
print "<input type = \"hidden\" name = \"action\" value = \"search\">\n";
print "<input type = \"hidden\" name = \"doc_id\" value = \"\">\n";
print "<input type = \"hidden\" name = \"exportall\" value = \"1\">\n";
print "</form>\n";



=command
print "<tr>\n";
print <<"TRUNK";
  <tr>
    <td></td>
    <td>comparison</td>
    <td>
            <select name="trunk" size="1">
                            <option value="contains" selected>contains</option>
                            <option value="is_equal">is equal</option>
                          </select>
   </td>
TRUNK
print "</tr>\n";


print "<tr>\n";
print "<td></td>\n";
print "<td>order by\n";
print "</td>\n";
print "<td>\n<select name=\"sorting\" size=\"1\">\n";
foreach my $type (@orderfields) {
    print "<option value=\"$type\">$type</option>\n\t";
}
print "</select>\n";
print "</td>\n";
print "</tr>\n";


print "<tr valign\=\"top\">\n";
print "<td></td>\n";
print "<td>data of\n";
print "</td>\n";
print "<td>\n<select name=\"data_of\" size=\"3\" multiple>\n";

print "<option value=\"all\">all</option>\n\t";
foreach my $owner (@owners) {
    print "<option value=\"$owner\">$owner</option>\n\t";
}
print "</select>\n</td>\n";
print "</td>\n";
print "</tr>\n";





print <<"SUBMIT1";
    <tr><td colspan = "2"><p><input type="submit" value="submit">
    <input type="reset" value="reset"></p></td>
    <td></td>
    </tr>

SUBMIT1



print "<input type = \"hidden\" name = \"searchtype\" value = \"fastsearch\">\n";
print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">\n";
print "<input type = \"hidden\" name = \"action\" value = \"search\">\n";
print "</form>\n";
=cut



print "<form action=\"${httppath}central.pl\" target = \"results\" method=\"POST\">\n";


print "<tr>\n";
print "<td colspan = \"2\"><b>detailed search</b></td>\n";
print "<td></td>\n";
print "</tr>\n";


#print "<form action=\"${httppath}central.pl\" target = \"results\" method=\"POST\">\n";


#print a table with search-fields for the query on the database


my $fieldnum;

#print "\<table cellspacing=\"0\" cellpadding=\"1\" border=\"0\" bgcolor=\"\#FFE5A7\">\n";

print "<tr>\n";
print "<td></td>\n";
print "<td>search for<\/td>\n";
print "<td>in field\n\t<\/td>\n";
print "<\/tr>\n";


for ($fieldnum = 1; $fieldnum <= 5; $fieldnum++) {

    print "<tr>\n";


    print "<td>";
    print "<select name=\"andor$fieldnum\" size=\"1\">\n";
    print "<option value=\"AND\">AND<\/option>\n";
    print "<option value=\"OR\" selected>OR<\/option>\n";
    print "<\/select>\n";
    print "<\/td>";


    print "<td><input type=\"text\" name=\"searchstring$fieldnum\" size=12 maxlength=200></td>\n";
    print "<td><select name=\"field$fieldnum\" size=\"1\">";

    my $i = 1;
    foreach my $type (@searchfields) {

	unless ($fieldnum == $i) {
	    print "<option value=\"$type\">$type</option>\n\t";
	}
	else {
	    print "<option value=\"$type\" selected>$type</option>\n\t";
	}
	$i++;
    }
    print "<\/select>\n</td>\n";
    print "</tr>\n";
} 



#print "<tr>\n";
#print "<td colspan\=\"3\">\n";
#print "<hr>\n";
#print "</td>\n";
#print "</tr>\n";



print "<tr>\n";
print <<"TRUNK";
  <tr>
    <td></td>
    <td>comparison</td>
    <td>
            <select name="trunk" size="1">
                            <option value="contains" selected>contains</option>
                            <option value="is_equal">is equal</option>
                          </select>
   </td>
TRUNK
print "</tr>\n";


print "<tr>\n";
print "<td></td>\n";
print "<td>order by\n";
print "</td>\n";
print "<td>\n<select name=\"sorting\" size=\"1\">\n";
foreach my $type (@orderfields) {
    print "<option value=\"$type\">$type</option>\n\t";
}
print "</select>\n";
print "</td>\n";
print "</tr>\n";


print "<tr valign\=\"top\">\n";
print "<td></td>\n";
print "<td>data of\n";
print "</td>\n";
print "<td>\n<select name=\"data_of\" size=\"3\" multiple>\n";

print "<option value=\"all\">all</option>\n\t";
foreach my $owner (@owners) {
    print "<option value=\"$owner\">$owner</option>\n\t";
}
print "</select>\n</td>\n";
print "</td>\n";
print "</tr>\n";


print <<"SUBMIT";
<tr>
    <td colspan = "2"> <p><input type="submit" value="submit">
    <input type="reset" value="reset"></p></td>
    <td></td>
</tr>

SUBMIT



print "</table>\n";
#print "<input type = \"hidden\" name = \"searchtype\" value = \"detailedsearch\">\n";
print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">\n";
print "<input type = \"hidden\" name = \"action\" value = \"search\">\n";
print "<input type = \"hidden\" name = \"doc_id\" value = \"\">\n";
print "<input type = \"hidden\" name = \"exportall\" value = \"1\">\n";
print "</form>\n";


print <<"MANAGE";
<table cellspacing="0" cellpadding="2" border="0">

<tr>
<td><a href="${httppath}help.pl">help</a></td>
<td><a href="${httppath}exportform.pl?database=$databasename\&exportall=1" target="results">export data</a></td>
<td><a href="${httppath}importform.pl?database=$databasename" target="results">import data</a></td>
</tr>
</table>

MANAGE


#print foot of the html-site

&Html::foot();


#





=command

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
print <<'ENDE';
<table cellspacing="10" cellpadding="5" border="0" width = "95%" align = "center"><tr>
 <td> <p align = "justify">Hinweis: Suchworte k&ouml;nnen in beliebige Felder eingetragen werden. Leere Felder werden bei der Suche nicht beachtet. Je nach gew&auml;hlter Verkn&uuml;pfungsart werden alle Felder mit Eintragungen entweder mit AND oder mit OR verkn&uuml;pft. Die Art der Suche: "enth&auml;lt" trunkiert die gesuchten Worte vorne und hinten, die Eingabe "ist genau" f&uuml;hrt zu einer Suche nach genau diesem Wort. Werden mehrere Worte in einem Feld angegeben, wird genau dieser "String" aus mehreren Worten gesucht.</p></td>
</tr>
</table>
</body>
</html>
ENDE
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


=cut











