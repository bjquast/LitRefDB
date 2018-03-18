#!/usr/bin/perl -w

use strict;
use warnings;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);


use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use dbmodule::DbConnect;
use dbmodule::TablefromDoc;
use htmlmodule::Data2File;
use htmlmodule::Html;
use htmlmodule::DbDefs;




#getting the path for the cgi-directory of the perl-scripts
#gibt Pfad zurück, in dem alle Skripte liegen
my $httppath = &DbDefs::httppath();  


my $pdfdir = &DbDefs::inputpdfdir;  #gibt Pfad zurück, in dem alle pdf-Dateien liegen


# Verzeichnis für user anlegen, falls es nicht existiert, um temporäre Dateien speichern zu können
# create directory for user if not exists, needed to save temporary files
my $htmlaccessname = $ENV{REMOTE_USER};


my $userpdfdir = $pdfdir.$htmlaccessname."\/";
unless (-d $userpdfdir) {
    unless (mkdir ($userpdfdir, 0775)) {
	print "kann pdf-Verzeichnis fuer User nicht anlegen!";
	die;
    }
}


#print header for the html-site with Html::header
#html-header für die Seite ausdrucken mit modul Html::header 

#my $htmltitle = "search for references";

#&Html::header($httppath, $htmltitle);

#&Html::body();

#getting the database from the form that calls searchform.pl 
my $output = new CGI;
my $databasename = $output->param('database');

my $dbcon = DbConnect->new(database => $databasename);
my $dbhandle = $dbcon->connect_to_db();


my $doc_ids_string = $output->param('doc_ids_string');
my $exportall = $output->param('exportall');
my $filetype = $output->param('filetype');
my $notext = $output->param('notext');
my $pdfzip = $output->param('pdfzip');


my $htmlaccessname = $ENV{REMOTE_USER}; # um den Benutzer für Suche nach eigenen Datensätzen zu ermitteln
my $owner_data = $output->param('owner_data');


#print "Content-type: text/plain\r\n\r\n";
#print "Content-type: text/references\r\n\r\n";



# print "eine testdatei\n";

my @doc_ids = split (" ", $doc_ids_string);

#print "@doc_ids\n";


my $resulthashref;


if ($exportall) {
    my $tempdetailstable = &TablefromDoc::alldocidstable($dbhandle);
#    print "ready\n";
    $resulthashref = &TablefromDoc::flattablehash($dbhandle, $tempdetailstable);
}

else {
    my $docidsref = \@doc_ids;
    my $tempdetailstable = &TablefromDoc::docidstable($dbhandle, $docidsref);
#    print "ready\n";
    $resulthashref = &TablefromDoc::flattablehash($dbhandle, $tempdetailstable);
}

#my %resulthash = %$resulthashref;
#foreach my $hashkey (keys (%resulthash)) {  
#    print "$resulthash{$hashkey}\n";
#}


my ($sec, $min, $hour, $day, $month, $year, $weekday, $yearday, $summertime) = localtime(time);
$year += 1900; 
my $questiontime = sprintf ("%04d%02d%02d", $year, $month+1, $day);
# my $processid = $$; #pid ermitteln

# my $datafilename = $userpdfdir."lit_"."$questiontime"."$processid".".temp";



# my $counter = 0;
# my $counterform = sprintf ("%d%d", $counter);

# my $newdatafilename = $datafilename.$counterform;

# if (-e $newdatafilename) {
#    $counter++;
#    $counterform = sprintf ("%d%d", $counter);
#    $datafilename.$counterform;
#    $newdatafilename = $datafilename.$counterform;
# }

# my $datafilehandle;
# open ($datafilehandle, ">$newdatafilename") or die "can not open temporary data file\n"; 

my $ext = "txt";

my $datastring;
if ($filetype eq "ris") {
    $datastring = &Data2File::risfilesave ($resulthashref, $owner_data, $notext);
    $ext = "ris";
}

elsif ($filetype eq "bibtex") {
    $datastring = &Data2File::bibtexfilesave ($resulthashref, $owner_data, $notext);
    $ext = "bib";
}

# unless ($erfolg) {
#    die "can not save data file\n";
# }
 
# close $datafilehandle;

if ($pdfzip eq "on") {
    my $ziparc = Archive::Zip->new();
    my %resulthash = %$resulthashref;
####problem owner_data    



    foreach my $element (sort{$a<=>$b} (keys (%resulthash))) {

	unless (($owner_data eq "on") && ($htmlaccessname ne $resulthash{$element}{owner})) {

	    if ($resulthash{$element}{pdffile}) {
		my $pdfpath = $pdfdir.$resulthash{$element}{pdffile};
		if (-e $pdfpath) {

#		    unless ($ziparc->addFile($pdfpath)) {
#			die "can not find $resulthash{$element}{pdffile}\n$element\n";
#		    }
		    if (my $zipmember = $ziparc->addFile($pdfpath, "$resulthash{$element}{pdffile}")) {
			$zipmember -> desiredCompressionMethod( COMPRESSION_STORED );
		    }
		    else {
			die "can not find $resulthash{$element}{pdffile}\n$element\n";
		    }
		}
	    }
	}
    }

#    if (my $zipmember = $ziparc->addFile($newdatafilename, "lit_$questiontime.$ext")) {
    if (my $zipmember = $ziparc->addString("$datastring", "lit_$questiontime.$ext")) {
	$zipmember -> desiredCompressionMethod( COMPRESSION_STORED );
    }
    else {
	die "can not add datastring\n";
#	die "can not find $newdatafilename\n";
    }
#    my ($tempfilehandle, $tempfilename) = Archive::Zip::tempFile($userpdfdir);
#    unless ($tempfilehandle) {
#	die "can not open temp-file\n";
#    }
#    $ziparc -> writeToFileNamed($tempfilename);


    print "Content-Disposition: inline; filename=\"lit_$questiontime.zip\" Content-Type: application/zip;\n\n";


    $ziparc -> writeToFileHandle('STDOUT', 0);
#    my $line;
#    while ($line = <$tempfilehandle>) {
#	    print $line;
#    }
#    close $tempfilehandle;
#    unlink ($tempfilename);

}
else {

    print "Content-Disposition: inline; filename=\"lit_$questiontime.$ext\" Content-Type: application/references;\n\n";

#    open ($datafilehandle, "<$newdatafilename") or die "can not read temporary data file\n"; 
#    my $line;
#    while ($line = <$datafilehandle>) {
#	    print $line;
#    }

    print $datastring;

}

# close $datafilehandle;
# unlink ($newdatafilename);

