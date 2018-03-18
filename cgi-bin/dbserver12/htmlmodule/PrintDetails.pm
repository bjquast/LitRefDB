package PrintDetails;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use htmlmodule::Html;
use htmlmodule::DbDefs;
use dbmodule::DbConnect;
# use dbmodule::DoctypeList;


# This module gets a reference to a hash containing all data of one or several documents and print the data 
# Dieses modul soll die Referenz auf einen Hash übergeben bekommen, der alle Daten zu einem Dokument enthält und diese dann als Tabelle in html ausgeben

# &DetailsAnzeige::anzeigen(Referenz auf Hash mit Daten, Datenbankname [,Checkbox zum Löschen, keine Löschen/Ändern-links anzeigen]);
# &DetailsAnzeige::anzeigen($datenhashref, $datenbankname, 1, 1);


 
#my $httppfad = &Html::httppfad;  #gibt Pfad zurück, in dem alle Skripte liegen

  
sub detailsoutput {

    my $ergebnishashref = shift;
    my $databasename = shift;
    my $httppath = shift;
    my $checked = shift;
    my %ergebnishash = %$ergebnishashref;
    my $checkbox;
    my $nolinks;    


    my $pdfdir = &DbDefs::outputpdfdir;

    unless ($databasename) {
	$databasename = &DbDefs::database();
    }
    my $dbcon = DbConnect->new(database => $databasename);
    my $dbhandle = $dbcon->connect_to_db();

#    unless ($checkbox = shift) {
#	$checkbox = 0;
#    } 

    unless ($nolinks = shift) {
	$nolinks = 0;
    }


    my $element;    
    my $docschluessel;
    my $feldschluessel;
    my $authorstring;
    my @authorlist;
    my $bookeditorstring;
    my @bookeditorlist;
    my $serieseditorstring;
    my @serieseditorlist;
    my $keywordstring;
    my @keywordlist;
    my $speciesstring;
    my @specieslist;
    my $zeilen;
    
    my $htmlaccessname = $ENV{REMOTE_USER};
#    print "<p>username: $htmlaccessname</p>\n";

    foreach $element (sort {$a<=>$b}(keys(%ergebnishash))) {
	
	# doc_id
#	print "<h4>Hashkey zum sortieren: $element</h4>\n";
	print  "<table cellspacing=\"1\" cellpadding=\"1\" border=\"0\" bgcolor=\"#FFE5A7\">";
	print "<tr>\n";
	
	# doc_id
	# print "<td colspan = \"2\">doc_id: $ergebnishash{$element}{docid}</td>\n</tr>\n<tr>\n";
	
	# doctype

	my %doctypes = ("article" => "1",
			"inbook" => "1",
			"book" => "1",
			"incollection" => "1",
			"unpublished" => "1",
			"phdthesis" => "1",
			"inproceedings" => "1",
			"misc" => "1");


	my $doctypequery;
	unless ($doctypequery = $dbhandle->prepare(qq/select doctype from doctype/)) {
	    die "doctypequery prepare error $DBI::err: $DBI::errstr.\n";
	}
	
	unless ($doctypequery->execute()) {
	    die "doctypequery execute error $DBI::err: $DBI::errstr.\n";
	}

	my $doctype;
	while (($doctype) = $doctypequery->fetchrow_array) {
	    $doctypes{$doctype} = "1";
	} 

	$doctypequery -> finish;

	if ($ergebnishash{$element}{doctype}) {
	    $doctypes{$ergebnishash{$element}{doctype}} = "1";
	}

	print "<td valign = \"top\"><b>Documenttype </b></td>\n";
	print "<td valign = \"top\"><select name=\"doctype$ergebnishash{$element}{docid}\" size=1>\n";

	my $doctypekey;
	foreach $doctypekey (sort (keys (%doctypes))){
	    my $selected;
	    if ($doctypekey eq $ergebnishash{$element}{doctype}) {
		$selected = " selected";
	    }
	    else {
		$selected = "";
	    }
	    print "<option value=\"$doctypekey\"$selected>$doctypekey</option>\n";
	}
	print "</select>\n<\/td>";

#	print "<td valign = \"top\"><input type=\"text\" name=\"doctype$ergebnishash{$element}{docid}\" size=31 maxlength=30 value = \"$ergebnishash{$element}{doctype}\"></td>\n";
	print "</tr>\n<tr>\n";


=command
print <<'SELECTBOX';
    <td valign = "top">
    <select name="doctype$element" size=1>
    <option value="article" selected>article</option>
    <option value="inbook">inbook</option>
    <option value="book">book</option>
    <option value="incollection">incollection</option>
    <option value="unpublished">unpublished</option>
    <option value="phdthesis">phdthesis</option>
    <option value="inproceedings">inproceedings</option>
    <option value="misc">misc</option>
    </select>
    </td>
SELECTBOX
=cut




	# author
	if ($ergebnishash{$element}{author}) {
	    @authorlist = @{$ergebnishash{$element}{author}};
	    $authorstring = join ("; ", @authorlist);
	}
	else {
	    $authorstring = "";
	}
	$zeilen = (int ((length ($authorstring) +5) /100 +1));
	print "<td valign = \"top\"><b>Author(s) </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"author$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$authorstring</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	# year
	print "<td valign = \"top\"><b>Year </b></td>\n";
	print "<td valign = \"top\"><input type=\"text\" name=\"year$ergebnishash{$element}{docid}\" size=5 maxlength=4 value = \"$ergebnishash{$element}{year}\"></td>\n";
	print "</tr>\n<tr>\n";
	
	# title
	$zeilen = (int ((length ($ergebnishash{$element}{title}) +5) /100 +1));
	print "<td valign = \"top\"><b>Title </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"title$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{title}</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	#abstract
	$zeilen = (int ((length ($ergebnishash{$element}{abstract}) +5) /100 +1));
	print "<td valign = \"top\"><b>Abstract </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"abstract$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{abstract}</textarea></td>\n";
	print "</tr>\n<tr>\n";

	# keyword
	if ($ergebnishash{$element}{keyword}) {
	    @keywordlist = @{$ergebnishash{$element}{keyword}};
	    $keywordstring = join ("; ", @keywordlist);
	}
	else {
	    $keywordstring = "";
	}
	$zeilen = (int ((length ($keywordstring) +5) /100 +1));
	print "<td valign = \"top\"><b>Keywords </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"keyword$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$keywordstring</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	
	# species
	if ($ergebnishash{$element}{species}) {
	    @specieslist = @{$ergebnishash{$element}{species}};
	    $speciesstring = join ("; ", @specieslist);
	}
	else {
	    $speciesstring = "";
	}
	$zeilen = (int ((length ($speciesstring) +5) /100 +1));
	print "<td valign = \"top\"><b>Species </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"species$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$speciesstring</textarea></td>\n";
	print "</tr>\n<tr>\n";

	#journal
	$zeilen = (int ((length ($ergebnishash{$element}{journal}) +5) /100 +1));
	print "<td valign = \"top\"><b>Journal </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"journal$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{journal}</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	# volume
	print "<td valign = \"top\"><b>Volume / Bandnr. </b></td>\n";
	print "<td valign = \"top\"><input type=\"text\" name=\"volume$ergebnishash{$element}{docid}\" size=21 maxlength=20 value = \"$ergebnishash{$element}{volume}\"></td>\n";
	print "</tr>\n<tr>\n";
	
	# issue
	print "<td valign = \"top\"><b>Issue / Chapternr. </b></td>\n";
	print "<td valign = \"top\"><input type=\"text\" name=\"issue$ergebnishash{$element}{docid}\" size=21 maxlength=20 value = \"$ergebnishash{$element}{issue}\"></td>\n";
	print "</tr>\n<tr>\n";
	
	#book
	$zeilen = (int ((length ($ergebnishash{$element}{book}) +5) /100 +1));
	print "<td valign = \"top\"><b>Booktitle </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"book$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{book}</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	# series
	$zeilen = (int ((length ($ergebnishash{$element}{series}) +5) /100 +1));
	print "<td valign = \"top\"><b>Seriestitle </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"series$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{series}</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	# bookeditor
	if ($ergebnishash{$element}{bookeditor}) {
	    @bookeditorlist = @{$ergebnishash{$element}{bookeditor}};
	    $bookeditorstring = join ("; ", @bookeditorlist);
	}
	else {
	    $bookeditorstring = "";
	}
	$zeilen = (int ((length ($bookeditorstring) +5) /100 +1));
	print "<td valign = \"top\"><b>Editor(s) </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"bookeditor$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$bookeditorstring</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	
	# serieseditor
	if ($ergebnishash{$element}{serieseditor}) {
	    @serieseditorlist = @{$ergebnishash{$element}{serieseditor}};
	    $serieseditorstring = join ("; ", @serieseditorlist);
	}
	else {
	    $serieseditorstring = "";
	}
	$zeilen = (int ((length ($serieseditorstring) +5) /100 +1));
	print "<td valign = \"top\"><b>Serieseditor(s) </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"serieseditor$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$serieseditorstring</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	# isbn
	print "<td valign = \"top\"><b>ISBN / ISSN </b></td>\n";
	print "<td valign = \"top\"><input type=\"text\" name=\"isbn$ergebnishash{$element}{docid}\" size=21 maxlength=20 value = \"$ergebnishash{$element}{isbn}\"></td>\n";
	print "</tr>\n<tr>\n";
	
	# verlag
	$zeilen = (int ((length ($ergebnishash{$element}{verlag}) +5) /100 +1));
	print "<td valign = \"top\"><b>Publisher </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"verlag$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{verlag}</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	# verlagort
	$zeilen = (int ((length ($ergebnishash{$element}{verlagort}) +5) /100 +1));
	print "<td valign = \"top\"><b>Place </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"verlagort$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{verlagort}</textarea></td>\n";
	print "</tr>\n<tr>\n";
	
	# institution
	$zeilen = (int ((length ($ergebnishash{$element}{institution}) +5) /100 +1));
	print "<td valign = \"top\"><b>Institution </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"institution$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{institution}</textarea></td>\n";
	print "</tr>\n<tr>\n";

	# startpage
	print "<td valign = \"top\"><b>Startpage </b></td>\n";
	print "<td valign = \"top\"><input type=\"text\" name=\"startpage$ergebnishash{$element}{docid}\" size=6 maxlength=11 value = \"$ergebnishash{$element}{startpage}\"></td>\n";
	print "</tr>\n<tr>\n";
	
	# endpage
	print "<td valign = \"top\"><b>Endpage </b></td>\n";
	print "<td valign = \"top\"><input type=\"text\" name=\"endpage$ergebnishash{$element}{docid}\" size=6 maxlength=11 value = \"$ergebnishash{$element}{endpage}\"></td>\n";
	print "</tr>\n<tr>\n";
	

	if ($htmlaccessname eq $ergebnishash{$element}{owner}) {
	    # notizen
	    $zeilen = (int ((length ($ergebnishash{$element}{notizen}) +5) /100 +1));
	    print "<td valign = \"top\"><b>Notes </b></td>\n";
	    print "<td valign = \"top\"><textarea name=\"notizen$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{notizen}</textarea></td>\n";
	    print "</tr>\n<tr>\n";
	}

        #pdffile
	print "<td valign = \"top\"><b>PDF-Datei </b></td>\n";
	if ($ergebnishash{$element}{pdffile}) {
	    print "<td>";
	    print  "<table cellspacing=\"0\" cellpadding=\"0\" border=\"0\" width = \"100\%\">\n";
	    print "<tr><td><b><a href=\"${pdfdir}$ergebnishash{$element}{pdffile}\">$ergebnishash{$element}{pdffile}</a></b>\n";
	    print "<input type = \"hidden\" name = \"oldpdffile$ergebnishash{$element}{docid}\" value = \"$ergebnishash{$element}{pdffile}\">\n";

	    print "</td>\n";
	    print "<td><input type=\"file\" name=\"filehandle$ergebnishash{$element}{docid}\" maxlength=\"1000\"></td>\n";
	    print "<td><input type =\"checkbox\" name = \"delete_pdf$ergebnishash{$element}{docid}\" value = \"delpdf\"> delete PDF-file</td>"; 
	    print "<\/tr>\n";
	    print "<\/table>\n"; 
	    print "<\/td>";

	}
	else {
	    print "<input type = \"hidden\" name = \"oldpdffile$ergebnishash{$element}{docid}\" value = \"\">\n";
	    print "<td valign = \"top\"><input type=\"file\" name=\"filehandle$ergebnishash{$element}{docid}\" maxlength=\"1000\"></td>\n"; 
	}
	print "</tr>\n<tr>\n";
	
	# available
	$zeilen = (int ((length ($ergebnishash{$element}{available}) +5) /100 +1));
	print "<td valign = \"top\"><b>Availability </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"available$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{available}</textarea></td>\n";
	print "</tr>\n<tr>\n";

	# contactaddress
	$zeilen = (int ((length ($ergebnishash{$element}{contactaddress}) +5) /100 +1));
	print "<td valign = \"top\"><b>Address </b></td>\n";
	print "<td valign = \"top\"><textarea name=\"contactaddress$ergebnishash{$element}{docid}\" rows=\"$zeilen\" cols=\"100\">$ergebnishash{$element}{contactaddress}</textarea></td>\n";
	print "</tr>\n<tr>\n";

	# owner
	print "<td valign = \"top\">Dataset of </td>\n";
	print "<td valign = \"top\">$ergebnishash{$element}{owner}</td>\n";
	print "</tr>\n";
	

#=command
    
        my $checkedtext = "";
	if ($checked == 1) {
	    $checkedtext = " checked=\"checked\"";
	}


	if (($ergebnishash{$element}{owner} eq $htmlaccessname) && ($element ne "empty")) {
	    print "<tr>\n";
	    print "<td valign = \"top\">delete / change this dataset</td>\n";
	    print "<td>\n";
	    print "<input type =\"checkbox\" name = \"doc_id\" value = \"$ergebnishash{$element}{docid}\"$checkedtext>";
	    print "</td>\n</tr>\n";

	}


	else {
	    print "<input type = \"hidden\" name = \"doc_id\" value = \"$ergebnishash{$element}{docid}\">\n";
	}
#=cut


	print "</table>\n";

	print "<hr>\n";


#	print "<tr>\n";
#	print "<td></td>\n";
#	print "<td> <p><input type=\"submit\" value=\"&auml;ndern \"><input type=\"reset\" value=\"alle zur&uuml;cksetzen\"></p></td>\n";
#	print "</tr>\n";
    
	
	
	
    } # foreach $element (@doc_ids) {
    
    
    print "\n";


############test
#    foreach my $envkey (%ENV) {
#	print "<p>-->$envkey $ENV{$envkey}</p>\n"
#    }
#
###########

}

return 1;











































