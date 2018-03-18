#!/usr/bin/perl -w

use strict;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;

#use dbmodule::SearchDocId;
use dbmodule::DbConnect;
#use dbmodule::QuestionResults;
use dbmodule::QuestionResultsOb;
#use dbmodule::AllDatafromDoc;
use dbmodule::TablefromDoc;
use dbmodule::DocDelete;
use dbmodule::DataInput;
use dbmodule::CheckOwner;
use htmlmodule::Html;
use htmlmodule::DbDefs;
use htmlmodule::PrintDetails;
use htmlmodule::PDF;
#use htmlmodule::PDFO;
#use htmlmodule::PrintFlatTable;
#use dbmodule::searching;


my $output = new CGI();


#my $databasename = $output->param('database');

my $databasename = &DbDefs::database();

# connect to database
my $dbcon = DbConnect->new(database => $databasename);
my $dbhandle = $dbcon->connect_to_db();

my $httppath = &DbDefs::httppath;  #returns path for all scripts

#html-header f�r die Seite ausdrucken mit modul Html::header 
# print html-header
my $htmlcaption = "Reference database";
&Html::header($httppath, $htmlcaption);
&Html::body();

#&Html::menu($httppath, $databasename);



# Abfrageparameter �bernehmen
# get parameters for all actions
my $questionid = $output->param('questionid');
my $resultpart = $output->param('resultpart');
my $checked = $output->param('checked');
my $sorting = $output->param('sorting');
my $action = $output->param('action');
my @doc_ids = $output->param('doc_id');







if ($action eq "mark") {
    $checked = 1;
#    print "checked $checked\n";
#&QuestionResults::resultprint($dbhandle, $databasename, $httppath, $questionid, $sorting, $checked, $resultpart);

    my $resultobject = QuestionResultsOb->new(dbhandle => $dbhandle, database => $databasename, httppath => $httppath, questionid => $questionid);
    $resultobject -> resultprint (sorting => $sorting, checked => $checked, resultpart => $resultpart);

}
elsif ($action eq "unmark") {
    $checked = 0;
#    print "checked $checked\n";
#&QuestionResults::resultprint($dbhandle, $databasename, $httppath, $questionid, $sorting, $checked, $resultpart);

    my $resultobject = QuestionResultsOb->new(dbhandle => $dbhandle, database => $databasename, httppath => $httppath, questionid => $questionid);
    $resultobject -> resultprint (sorting => $sorting, checked => $checked, resultpart => $resultpart);
}

#=command
elsif ($action eq "details") {
    $checked = 0;
#    print "checked $checked\n";
    my $doc_idsref = \@doc_ids;
    my $tempdetailstable = &TablefromDoc::docidstable($dbhandle, $doc_idsref);
    my $resulthashref = &TablefromDoc::flattablehash($dbhandle, $tempdetailstable);
#    print "ready\n";
    my $erfolg = &PrintDetails::detailsoutput ($resulthashref, $databasename, $httppath, $checked);

}
#=cut


elsif ($action eq "save") {
    $checked = 0;
#    print "checked $checked\n";
#    my $doc_idsref = \@doc_ids;

my $exportall = 0; #$output->param('exportall');


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

}


elsif ($action eq "delete") {
    $checked = 1;
    my $doc_idsref = \@doc_ids;

    my $resultobject = QuestionResultsOb->new(dbhandle => $dbhandle, database => $databasename, httppath => $httppath, questionid => $questionid);

    $resultobject -> deletetable_from_docids (docidref => $doc_idsref);
    $resultobject -> resultprint (sorting => $sorting, checked => $checked, resultpart => $resultpart);
}


elsif ($action eq "delete_now") {
    $checked = 0;
    my $doc_idsref = \@doc_ids;

    my $resultobject = QuestionResultsOb->new(dbhandle => $dbhandle, database => $databasename, httppath => $httppath, questionid => $questionid);

    $resultobject -> deletetable_from_docids (docidref => $doc_idsref);
    my $deletetable =  $resultobject-> return_relevancetable();
    if ($deletetable) {
	my $deletepdfs = "on";
	unless (&DocDelete::deletedocs($dbhandle, $deletetable, $deletepdfs)) {
	    die "error while deleting datasets\n";
	}
    }


#$self->{httppath}results.pl?database=$self->{databasename}\&questionid=$self->{questionid}\&resultpart=$counter\&checked=$self->{checked}\&sorting=$self->{sorting}\">$counter</a


    print "<form action=\"${httppath}results.pl\" target = \"results\" method=\"POST\">";
    print "<div id\=\"resulthead\">\n";

    print "\n";
    print "<table cellspacing=\"0\" cellpadding=\"3\" border = \"0\"\n";
    print "<tr valign = \"top\">\n";


    print "<td>\n";
    print "<b style=\"font-size:medium\">datasets deleted</b>\n";
    print "</td>\n";
    print "<td>\n"; 
    print '<input type="submit" value="show results of last search">';
    print "</td>\n";
    print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">";
    print "<input type = \"hidden\" name = \"questionid\" value = \"$questionid\">";
#    print "<input type = \"hidden\" name = \"resultpart\" value = \"$resultpart\">";
    print "<input type = \"hidden\" name = \"checked\" value = \"$checked\">";
    print "<input type = \"hidden\" name = \"sorting\" value = \"$sorting\">";
    

    print "</tr>\n";
    print "</table>\n";


    print "</form>\n";

#    $resultobject -> resultprint (sorting => $sorting, checked => $checked, resultpart => $resultpart);
}



elsif ($action eq "insert") {
    my $htmlaccessname = $ENV{REMOTE_USER};

#    my $datahashref = &readform ($docidsref);
    my %emptyhash;
    $emptyhash{empty}{owner} = $htmlaccessname;
    my $emptyhashref = \%emptyhash;
    $checked = 0;

#############

    print "<form action=\"${httppath}central.pl\" method=\"POST\" enctype=\"multipart/form-data\">";
    print "\n";
    
    print "<div id\=\"detailhead\">\n";
    
    print "\n";
    print "<table cellspacing=\"1\" cellpadding=\"3\" border = \"0\"\n";
    print "<tr valign = \"top\">\n";
    
    print "<td>\n"; 
#    print '<input type="radio" name="action" value="change"checked="checked"> change';
#    print '<input type="radio" name="action" value="delete"> delete';
    print '<input type="radio" name="action" value="insert_as_new" checked="checked"> insert ';
    print "</td>\n";
    
    
    print "<td>\n"; 
    print "<input type=\"submit\" value=\"submit \"><input type=\"reset\" value=\"reset\">\n";
    print "</td>\n";

#    print "<td><a href=\"${httppath}results.pl?database=$databasename\&questionid=$questionid\&resultpart=$resultpart\&checked=0\&sorting=$sorting\" target = \"results\"><b>reload results of last search</b></a>\n";
    
    print "</tr>\n";
    print "</table>\n";
    
    print "</div>\n";
    
    
    
    print "<div id\=\"detailtable\">\n";
    my $erfolg = &PrintDetails::detailsoutput ($emptyhashref, $databasename, $httppath, $checked);
    print "</div>\n";
    
    
    print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">";
    print "<input type = \"hidden\" name = \"details\" value = \"on\">";
    print "<input type = \"hidden\" name = \"questionid\" value = \"$questionid\">";
#    print "<input type = \"hidden\" name = \"resultpart\" value = \"$resultpart\">";
    print "<input type = \"hidden\" name = \"checked\" value = \"$checked\">";
    print "<input type = \"hidden\" name = \"sorting\" value = \"$sorting\">";
    
    print '</form>';
    
    
##############


}


elsif ($action eq "change") {
    my $docidsref = \@doc_ids;
    my $htmlaccessname = $ENV{REMOTE_USER};


    my $otherdocidsref = &CheckOwner::otherdocs($dbhandle, $docidsref, $htmlaccessname);
    my @otherdocids = @$otherdocidsref;

 
    if ($#doc_ids < 0) {
	print "<h4>You have not choosen one of your own datasets</h4>";
    }


#    print $#otherdocids, @otherdocids;

    elsif ($#otherdocids >= 0) { # hier wird nur an dieser Stelle kontrolliert, was dem User gehört und dann kategorisch abgelehnt. Nicht einfach ändern, da der folgende else Block sonst auch Daten von anderen Nutzern ändern würde
	print "<h4>Some of the choosen datasets can not be changed, because they belong to other users</h4>";
    } 
    else {
	my $datahashref = &readform ($docidsref);
	my $inserteddocidsref = &DataInput::input($dbhandle, $datahashref, $htmlaccessname);
	if ($inserteddocidsref) {
	    
	    my $resultobject = QuestionResultsOb->new(dbhandle => $dbhandle, database => $databasename, httppath => $httppath);
	    
	    $resultobject -> deletetable_from_docids (docidref => $docidsref);
	    my $deletetable =  $resultobject-> return_relevancetable();
	    if ($deletetable) {
		unless (&DocDelete::deletedocs($dbhandle, $deletetable)) {
		    die "error while deleting datasets\n";
		}
	    }
	}


#############

    print "<form action=\"${httppath}central.pl\" method=\"POST\" enctype=\"multipart/form-data\">";
    print "\n";
    
#    my $docidsref = \@doc_ids;
    my $temptable = &TablefromDoc::docidstable($dbhandle, $inserteddocidsref);
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

    print "<td><a href=\"${httppath}results.pl?database=$databasename\&questionid=$questionid\&resultpart=$resultpart\&checked=0\&sorting=$sorting\" target = \"results\"><b>reload results of last search</b></a>\n";
    
    print "</tr>\n";
    print "</table>\n";
    
    print "</div>\n";
    
    
    
    print "<div id\=\"detailtable\">\n";
    my $erfolg = &PrintDetails::detailsoutput ($ergebnishashref, $databasename, $httppath, $checked);
    print "</div>\n";
    
    
    print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">";
    print "<input type = \"hidden\" name = \"details\" value = \"on\">";
    print "<input type = \"hidden\" name = \"questionid\" value = \"$questionid\">";
#    print "<input type = \"hidden\" name = \"resultpart\" value = \"$resultpart\">";
    print "<input type = \"hidden\" name = \"checked\" value = \"$checked\">";
    print "<input type = \"hidden\" name = \"sorting\" value = \"$sorting\">";
    
    print '</form>';
    
    
##############



    }




=command
    print "<form action=\"${httppath}results.pl\" target = \"results\" method=\"POST\">";
    print "<div id\=\"detailhead\">\n";
    print "\n";
    print "<table cellspacing=\"0\" cellpadding=\"3\" border = \"0\"\n";
    print "<tr valign = \"top\">\n";


    print "<td>\n";
    print "<b style=\"font-size:medium\">dataset changed</b>\n";
    print "</td>\n";
    print "<td>\n"; 
    print '<input type="submit" value="reload results of last search">';
    print "</td>\n";
    print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">";
    print "<input type = \"hidden\" name = \"questionid\" value = \"$questionid\">";
    print "<input type = \"hidden\" name = \"resultpart\" value = \"$resultpart\">";
    print "<input type = \"hidden\" name = \"checked\" value = \"$checked\">";
    print "<input type = \"hidden\" name = \"sorting\" value = \"$sorting\">";
    

    print "</tr>\n";
    print "</table>\n";


    print "</form>\n";
=cut


}

elsif ($action eq "insert_as_new") {
    my $docidsref = \@doc_ids;
    my $htmlaccessname = $ENV{REMOTE_USER};

    my $datahashref = &readform ($docidsref);
    unless ($datahashref) {
	die "no datahashref\n";
    }

    my %datahash = %$datahashref;
    my $doc_id;

# put pdf-filename to $datahash{$doc_id}{pdffile}, so that it is copied to a new file in DataInput 
    my $pdfdir = &DbDefs::inputpdfdir;
    foreach $doc_id (sort (keys (%datahash))) {
	if (($datahash{$doc_id}{oldpdffile}) && (not($datahash{$doc_id}{filehandle}))) {
	    $datahash{$doc_id}{pdffile} = $pdfdir.$datahash{$doc_id}{oldpdffile};
	}
	elsif (($datahash{$doc_id}{oldpdffile}) && ($datahash{$doc_id}{filehandle})) {
	    $datahash{$doc_id}{oldpdffile} = ''; #to prevent the old pdf-file to be overwritten if an dataset is copied. DataInput.pm checks wether there is an old pdf-file and replaces it, if there is a filehandle. 
	}
    }



    my $inserteddocidsref = &DataInput::input($dbhandle, $datahashref, $htmlaccessname);
    unless ($inserteddocidsref) {
	die ("no data inserted\n");
    }

#############

    print "<form action=\"${httppath}central.pl\" method=\"POST\" enctype=\"multipart/form-data\">";
    print "\n";
    
#    my $docidsref = \@doc_ids;
    my $temptable = &TablefromDoc::docidstable($dbhandle, $inserteddocidsref);
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

    print "<td><a href=\"${httppath}results.pl?database=$databasename\&questionid=$questionid\&resultpart=$resultpart\&checked=0\&sorting=$sorting\" target = \"results\"><b>reload results of last search</b></a>\n";
    
    print "</tr>\n";
    print "</table>\n";
    
    print "</div>\n";
    
    
    
    print "<div id\=\"detailtable\">\n";
    my $erfolg = &PrintDetails::detailsoutput ($ergebnishashref, $databasename, $httppath, $checked);
    print "</div>\n";
    
    
    print "<input type = \"hidden\" name = \"database\" value = \"$databasename\">";
    print "<input type = \"hidden\" name = \"details\" value = \"on\">";
    print "<input type = \"hidden\" name = \"questionid\" value = \"$questionid\">";
#    print "<input type = \"hidden\" name = \"resultpart\" value = \"$resultpart\">";
    print "<input type = \"hidden\" name = \"checked\" value = \"$checked\">";
    print "<input type = \"hidden\" name = \"sorting\" value = \"$sorting\">";
    
    print '</form>';
    
    
##############
    
}



elsif ($action eq "search") {

# Abfrageparameter �bernehmen
# get parameters for query
    my $truncation = $output->param('trunk');
    my $sorting = $output->param('sorting');
    
    
    my @dataof = $output->param('data_of'); # the data of which users should be searched
    
    my $htmlaccessname = $ENV{REMOTE_USER}; # get the user
    
    
    
    my @searcharray;
    my $fieldname;
    my $searchstring;
    my $connection = "OR";
    my $i;
    my $searchtext;
    
    
#	my $searchtype = $output->param("searchtype");
    
    
    if ($searchstring = $output->param("fastsearchstring")) {
	
#	    if ($searchstring eq "") {
#		$searchstring = "%";
#	    } 
	
	my @tempsearcharray = split (m/\s/, $searchstring);
	
	my $searchword;
	while ($searchword = shift (@tempsearcharray)) {
	    if ($truncation eq "contains") {
		$searchword = "LIKE \"\%".$searchword."\%\"";
	    }
	    else {
		$searchword = "LIKE \"".$searchword."\"";
	    }
	    
	    push (@searcharray, $connection, "title", $searchword);
	    push (@searcharray, $connection, "author / editor", $searchword);
	    push (@searcharray, $connection, "keyword", $searchword);
	    push (@searcharray, $connection, "abstract", $searchword);
	    push (@searcharray, $connection, "species", $searchword);
	    
	    $searchtext .=$connection." ".$searchword." ";
	}
	$searchtext .= $searchtext." in title, author, keyword, abstract, species";
    }
    
    
    
    
#	if ($searchtype eq "detailedsearch") {
    
    for ($i=1; $i <=5; $i++) {
	if ($searchstring = $output->param("searchstring$i")) {
	    
	    $connection = $output->param("andor$i");
	    push (@searcharray, $connection);
	    
	    if ($truncation eq "contains") {
		$searchstring = "\%".$searchstring."\%"; 
	    }
	    
	    $searchstring = "LIKE \"".$searchstring."\"";
	    $fieldname = $output->param("field$i");
	    push (@searcharray, $fieldname, $searchstring);
	    $searchtext .= $connection." ".$searchstring." in ".$fieldname." ";
	}
    }  
#	}
    
    
    
    if ($#searcharray < 0) {
	my $searchword = "LIKE \"\"";
	$connection = "OR";
#	    $truncation = "contains";
	push (@searcharray, $connection, "title", $searchword);
#	    push (@searcharray, $connection, "author / editor", $searchword);
#	    push (@searcharray, $connection, "keyword", $searchword);
#	    push (@searcharray, $connection, "abstract", $searchword);
#	    push (@searcharray, $connection, "species", $searchword);
	$searchtext .= $searchword." in title";
	@dataof = ("$htmlaccessname");
    }
    
    
    shift @searcharray;	
    
    
	
# print @searcharray;
    
# print "search for $searchtext\n";
    
    
    my $searchquestion = join (";;;", @searcharray);
    my $dataofref = \@dataof;
    
#	print "dataof",@dataof;
    
#	print $searchquestion;
    
#	    my $docidtable = &searching::searching($searchquestion, $dbhandle, $dataofref, $htmlaccessname);
#	my @searchresult = @$searchresultref;
#	my $questionid = $searchresult[0];
#	my $docidtable = $searchresult[1];
    
    my $checked = 0;
    my $resultpart = 0;
    
#	print "searching ready";
    
#	    &QuestionResults::resultprint($dbhandle, $databasename, $httppath, $questionid, $sorting, $checked, $resultpart);
    
    my $resultobject = QuestionResultsOb->new(dbhandle => $dbhandle, database => $databasename, httppath => $httppath);
    $resultobject -> searching (searchquestion => $searchquestion, dataofref => $dataofref, htmlaccesname => $htmlaccessname);
    $resultobject -> resultprint (sorting => $sorting, checked => $checked, resultpart => $resultpart);
    
    
}



sub readform {

    my $doc_idsref = shift;
    my @doc_ids = @$doc_idsref;
    my $doc_id;
    my %datahash;



    foreach $doc_id (@doc_ids) {

	my $element;
	
	
	$datahash{$doc_id}{doctype} = $output->param("doctype$doc_id");	
	$datahash{$doc_id}{year} = $output->param("year$doc_id");
	$datahash{$doc_id}{title} = $output->param("title$doc_id");
	$datahash{$doc_id}{journal} = $output->param("journal$doc_id");
	$datahash{$doc_id}{issue} = $output->param("issue$doc_id");
	$datahash{$doc_id}{volume} = $output->param("volume$doc_id");
	$datahash{$doc_id}{book} = $output->param("book$doc_id");
	$datahash{$doc_id}{series} = $output->param("series$doc_id");
	$datahash{$doc_id}{isbn} = $output->param("isbn$doc_id");
	$datahash{$doc_id}{verlag} = $output->param("verlag$doc_id");
	$datahash{$doc_id}{verlagort} = $output->param("verlagort$doc_id");
	$datahash{$doc_id}{startpage} = $output->param("startpage$doc_id");
	$datahash{$doc_id}{endpage} = $output->param("endpage$doc_id");
	$datahash{$doc_id}{abstract} = $output->param("abstract$doc_id");
	$datahash{$doc_id}{notizen} = $output->param("notizen$doc_id");
	$datahash{$doc_id}{institution} = $output->param("institution$doc_id");
	$datahash{$doc_id}{available} = $output->param("available$doc_id");
	$datahash{$doc_id}{contactaddress} = $output->param("contactaddress$doc_id");
	
	
	foreach $element (keys (%datahash)) {
	    chomp ($datahash{$doc_id}{$element});
	    if ($datahash{$doc_id}{$element} =~ m/\r$/) {
		chop ($datahash{$doc_id}{$element});
	    }
	    $datahash{$doc_id}{$element} =~ s/\s/ /g;
	}
	
	my $author;
	my @authorlist;
	if ($author = $output->param("author$doc_id")) {
	    chomp ($author);
	    $author  =~ s/\r//g;
	    $author  =~ s/\n/;/g;
	    $author  =~ s/;\s+/;/g;
	    if ($author =~ m/;$/) {
		chop ($author);
	    }
	    @authorlist = split (/;/,$author);
	    $datahash{$doc_id}{author} = \@authorlist;
	}

	my $bookeditor = $output->param("bookeditor$doc_id");
	chomp ($bookeditor);
	$bookeditor  =~ s/\r//g;
	$bookeditor  =~ s/;\s+/;/g;
	$bookeditor  =~ s/\n/;/g;
	if ($bookeditor =~ m/;$/) {
	    chop ($bookeditor);
	}
	my @bookeditorlist = split (/;/,$bookeditor);
	$datahash{$doc_id}{bookeditor} = \@bookeditorlist;
	
	my $serieseditor = $output->param("serieseditor$doc_id");
	chomp ($serieseditor);
	$serieseditor  =~ s/\r//g;
	$serieseditor  =~ s/;\s+/;/g;
	$serieseditor  =~ s/\n/;/g;
	if ($serieseditor =~ m/;$/) {
	    chop ($serieseditor);
	}
	my @serieseditorlist = split (/;/,$serieseditor);
	$datahash{$doc_id}{serieseditor} = \@serieseditorlist;
	
	my $keyword = $output->param("keyword$doc_id");
	chomp ($keyword);
	$keyword  =~ s/\r//g;
	$keyword  =~ s/;\s+/;/g;
	$keyword  =~ s/\n/;/g;
	if ($keyword =~ m/;$/) {
	    chop ($keyword);
	}
	my @keywordlist = split (/;/,$keyword);
	$datahash{$doc_id}{keyword} = \@keywordlist;

	my $species = $output->param("species$doc_id");
	chomp ($species);
	$species  =~ s/\r//g;
	$species  =~ s/;\s+/;/g;
	$species  =~ s/\n/;/g;
	if ($species =~ m/;$/) {
	    chop ($species);
	}
	my @specieslist = split (/;/,$species);
	$datahash{$doc_id}{species} = \@specieslist;
#	print "<h1>species:@specieslist</h1>";
	





# falls pdf-datei angegeben wurde
#my $newpdffile = $output->param("filehandle$doc_id");
#my $oldpdffile = $output->param("oldpdffile$doc_id");
#my $deletepdf = $output->param("delete_pdf$doc_id");

	$datahash{$doc_id}{filehandle} = $output->param("filehandle$doc_id");
	$datahash{$doc_id}{oldpdffile} =  $output->param("oldpdffile$doc_id");
	$datahash{$doc_id}{delete_pdf} =  $output->param("delete_pdf$doc_id");


=command
#nur ein test
	if ($datahash{$doc_id}{oldpdffile}) {
	    print 'if ($datahash{$doc_id}{oldpdffile})';
	}
	unless ($datahash{$doc_id}{oldpdffile}) {
	    print 'unless ($datahash{$doc_id}{oldpdffile})';
	}
	unless (defined($datahash{$doc_id}{oldpdffile})) {
	    print 'unless (defined($datahash{$doc_id}{oldpdffile}))';
	}
	if ($datahash{$doc_id}{oldpdffile} eq "") {
	    print '($datahash{$doc_id}{oldpdffile} eq \"\")';
	}
	if (not defined ($datahash{$doc_id}{oldpdffile})) {
	    print '(not defined ($datahash{$doc_id}{oldpdffile}))';
	}
	unless ($datahash{$doc_id}{gruenkohl}) {
	    print 'unless ($datahash{$doc_id}{gruenkohl})';
	}
	unless (defined($datahash{$doc_id}{gruenkohl})) {
	    print 'unless (definde($datahash{$doc_id}{gruenkohl}))';
	}
=cut


#	my $dhashref = \%datahash;

#	$dhashref = &PDF::pdfload($dhashref, $doc_id, $filehandle, $delete_pdf, $oldfile);	

#	%datahash = %$dhashref;
	
    }	
    
    my $datahashref = \%datahash;
    return $datahashref;



} 



&Html::foot();

$dbhandle->disconnect;

