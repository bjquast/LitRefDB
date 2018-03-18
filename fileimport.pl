#!/usr/bin/perl -w

use strict;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );

use IO::String;
use IO::File;


# use dbmodule::SearchDocId;
use dbmodule::DbConnect;
use dbmodule::DataInput;
use htmlmodule::Html;
use dbfilter::Ris2Hash;
use dbfilter::Bibtex2Hash;




#getting the path for the cgi-directory of the perl-scripts
#gibt Pfad zurück, in dem alle Skripte liegen
my $httppath = &DbDefs::httppath();  


#print header for the html-site with Html::header
#html-header für die Seite ausdrucken mit modul Html::header 

my $htmltitle = "import datasets";

&Html::header($httppath, $htmltitle);

&Html::body();

#getting the database from the form that calls searchform.pl 
my $output = new CGI;
my $databasename = $output->param('database');

my $dbcon = DbConnect->new(database => $databasename);
my $dbhandle = $dbcon->connect_to_db();


my $filehandle = $output->param('filehandle');
my $dateityp = $output->param('dateityp');
my $ignore_doubles = $output->param('ignore_doubles');
my $inputzip = $output->param('inputzip');



my $htmlaccessname = $ENV{REMOTE_USER};


my $datenhashref;
#my @extensions = qw(ris txt bib);

print "<p>$filehandle</p>\n";

#if ($filehandle !~ /^[a-z\.\-\d_]+?\.([a-z]{3})$/) {
#    print "<p>unkown filename</p>\n";
#} 
#else {
#    my $extension = $1;
#    if (!grep($extension, @extensions)) {
#	print "<p>unknown filetype</p>\n";
#    }
#    else {

my $tempfh;
my $ziparc;

if ($inputzip eq "on") {
    $ziparc = Archive::Zip->new();
#    my $tempfh;
    my $tempstring;

    binmode ($filehandle);

    while (my $line = (<$filehandle>)) {
	$tempstring.= $line;
    } 

    $tempfh = IO::String->new($tempstring);

#    open ($tempfh, "<", \$tempstring) or die "can not open temp-file for input\n";# \$tempstring

#    seek ($tempfh, 0, 0);
#    close $tempfh;
#    open ($tempfh, "<", "/srv/www/htdocs/dbserver8_pdf/testtemp.tmp") or die "can not open temp-file for input\n";# \$tempstring

    unless (AZ_OK == ($ziparc->readFromFileHandle($tempfh))) { #geht eventuell nicht, siehe manpage -> readFromFileHandle
#    unless (AZ_OK == ($ziparc->read("/srv/www/htdocs/dbserver8_pdf/testtemp.tmp"))) {
	die "can not open zip-archive\n";
    }

    seek ($tempfh, 0, 0);


#    close $tempfh;

    my $datafh;
    my $datafilestring;

    $datafh = IO::String->new($datafilestring);

#    open ($datafh, ">", \$datafilestring) or die "can not open temp-file for datafile\n"; 
#   my $outdatafh;
#   open ($outdatafh, "<", \$datafilestring)  or die "can not open temp-file for datafile\n"; 

    my @datafiles;
    if ($dateityp eq "bibtex") {
	unless (@datafiles = $ziparc->membersMatching( '.*\.bib' )) {
	    die "no bibtex-file in archive\n";
	}
	foreach my $datafile (@datafiles) {
#	    print "<p>load $datafile</p>\n";
	    $datafile->extractToFileHandle($datafh);
	    seek ($datafh, 0, 0);
	    $datenhashref = &Bibtex2Hash::filter2hash($datafh);
	    &DataInput::input($dbhandle, $datenhashref, $htmlaccessname, $ignore_doubles, $ziparc);
	    print "<p>File import done</p>\n";
	}
    }
    elsif ($dateityp eq "ris") {
        unless (@datafiles = $ziparc->membersMatching( '.*\.ris' )) {
	    die "no ris-file in archive\n";
	}
	foreach my $datafile (@datafiles) {
#	    print "<p>load $datafile</p>\n";
	    $datafile->extractToFileHandle($datafh);
	    seek ($datafh, 0, 0);
#	    while (<$datafh>) {
#		print "<p>$_</p>\n";
#	    }
	    $datenhashref = &Ris2Hash::filter2hash($datafh);
#	    while (<$datafh>) {
#		print $_;
#	    }
###########
=command
	    my $pdftempstring;
	    my $pdffh = IO::String->new($pdftempstring);
	    my $zipmember;
	    if (($zipmember) = $ziparc->membersMatching(('.*Quast2001.pdf'))) {
		    my $extname = $zipmember->externalFileName();
		    print "<p>$extname</p>\n";
		    my $result;
#		    $datafile->extractToFileHandle($pdffh);
		    $zipmember->extractToFileHandle($pdffh);

#		    if (my $result = $zipmember->extractToFileHandle($pdffh)) {
		    seek ($pdffh, 0, 0);
		    while (<$pdffh>) {
			print "<p>$_</p>\n";
		    }

#		    unless ($datenhash{$datensatznr}{pdffile} = &PDF::pdfload(\%datenhash, $datensatznr, $pdffh)) {
#			$datenhash{$datensatznr}{pdffile} = "";
			print "<p>Ready</p>";
#		    }
#		}
#		else {
#		    my $extname = $zipmember->externalFileName();
#		    print "<p>could not extract $zipmember \($datenhash{$datensatznr}{pdffile}\) $extname</p>\n";
#		    $datenhash{$datensatznr}{pdffile} = "";
		    print "<p>A0</p>";
#		}
		    print "<p>ppppp$result</p>\n";

		
	    }
=cut
#########
	    &DataInput::input($dbhandle, $datenhashref, $htmlaccessname, $ignore_doubles, $ziparc);
	    print "<p>File import done</p>\n";
	}
    }
    close ($datafh);
#    close ($outdatafh);
}
else {
    if ($dateityp eq "bibtex") {
	$datenhashref = &Bibtex2Hash::filter2hash($filehandle);
	&DataInput::input($dbhandle, $datenhashref, $htmlaccessname, $ignore_doubles, $ziparc);
	print "<p>File import done</p>\n";
    }
    elsif ($dateityp eq "ris") {
	$datenhashref = &Ris2Hash::filter2hash($filehandle);
	&DataInput::input($dbhandle, $datenhashref, $htmlaccessname, $ignore_doubles, $ziparc);
	print "<p>File import done</p>\n";
    }
}

#    }
#}
$dbhandle->disconnect;



#print foot of the html-site

&Html::foot();



