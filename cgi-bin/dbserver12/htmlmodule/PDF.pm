package PDF;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use htmlmodule::Html;
use htmlmodule::DbDefs;



sub pdfload {
    my $datenhashref = shift;
    my $datensatznr = shift;
    my $filehandle = shift;
    my $filearrayref = shift;
#    my $deletepdf = shift;
#    my $oldfile = shift;

    my $pdffile;
    my $pdfpath;

    my %datenhash = %$datenhashref;

    my $pdfdir = &DbDefs::inputpdfdir;  #gibt Pfad zurück, in dem alle pdf-Dateien liegen


# Verzeichnis für user anlegen, falls es nicht existiert
    my $htmlaccessname = $ENV{REMOTE_USER};


    my $userpdfdir = $pdfdir.$htmlaccessname."\/";
    unless (-d $userpdfdir) {
	unless (mkdir ($userpdfdir, 0775)) {
	    print "kann pdf-Verzeichnis fuer User nicht anlegen!";
	    die;
	}
    }
    
    
    if ((defined ($filehandle)) and ($filehandle ne "") and (not($filearrayref))) {
	
#	überprüfen, ob angegebene Datei einigermaßen richtig ist
#	print "Filehandler $filehandle\n";


#	print "wwwww$filehandle";
	$filehandle =~ s/.*[\/\\](.*)/$1/;
#	print "wwww$filehandle";
	
	#my @extensions = qw(pdf, PDF, txt, doc, dvi);
	    
# print "<p>$filehandle</p>\n";
#	if ($filehandle !~ /^[A-Za-züäöÜÄÖ\.\-\d_\ ]+?\.([A-Za-züäöÜÄÖ]{3})$/) {
#	    print "<p>$filehandle ung&uuml;ltiger Dateiname</p>\n";
#	    die;
#	    return 0;
#	} 
#	else {
#	    my $extension = $1;
#	    if (!grep($extension, @extensions)) {
#		print "<p>$filehandle ung&uuml;ltige Dateiendung</p>\n";
#		die;
#	    }
#       }
	

# Pfad und Namen für die Datei generieren
	my $tempauthyear = ${$datenhash{$datensatznr}{author}}[0].$datenhash{$datensatznr}{year};
    
	$tempauthyear =~ m/(\w+).*?(\d+)/i;
	my $authyear = $1.$2;
	
	$pdffile = $authyear.".pdf";
	$pdfpath = $userpdfdir.$pdffile;
	my $alpha = "A";
	
	while (-e $pdfpath) {
	    $pdffile = $authyear.$alpha.".pdf";
	    $pdfpath = $userpdfdir.$pdffile;
	    $alpha++;
	}
#	$datenhash{$datensatznr}{pdffile} = $pdffile;
	
# pdf-datei speichern
        my $pdfstring;
        my $zeile;
	while ($zeile = <$filehandle>) {
#	    print $zeile;
	    $pdfstring.=$zeile;
	}
	open (PDFDAT, ">$pdfpath") or die "cant open $pdfpath\n";
	binmode PDFDAT;
	print PDFDAT $pdfstring;
#	print $pdfstring;
	close PDFDAT;


    }
    
########wird nicht mehr gebraucht, wenn zip-dateien geladen werden können
    elsif ($filearrayref) {
	my @filearray = @$filearrayref;

# Pfad und Namen für die Datei generieren
	my $tempauthyear = ${$datenhash{$datensatznr}{author}}[0].$datenhash{$datensatznr}{year};
    
	$tempauthyear =~ m/(\w+).*?(\d+)/i;
	my $authyear = $1.$2;
	
	$pdffile = $authyear.".pdf";
	$pdfpath = $userpdfdir.$pdffile;
	my $alpha = "A";
	
	while (-e $pdfpath) {
	    $pdffile = $authyear.$alpha.".pdf";
	    $pdfpath = $userpdfdir.$pdffile;
	    $alpha++;
	}
#################


# pdf-datei speichern
        my $pdfstring;
        my $zeile;
	foreach $zeile (@filearray) {
#	    print $zeile;
	    $pdfstring.=$zeile;
	}
	open (PDFDAT, ">$pdfpath") or die "cant open $pdfpath\n";
	binmode PDFDAT;
	print PDFDAT $pdfstring;
#	print $pdfstring;
	close PDFDAT;


    }


# wenn keine pdf-datei angegeben muss nach dem alten wert geguckt werden
#    elsif ($deletepdf ne "delpdf")  {
#	$datenhash{$datensatznr}{pdffile} = $oldfile;	
#    }


    my $testpath = $userpdfdir.$pdffile;   #$datenhash{$datensatznr}{pdffile};
    unless (-e $testpath) {
	die "Datei $testpath wurde nicht gefunden\n";
    }

#    $datenhashref = \%datenhash;
#    return $datenhashref;

    my $userpdfpath = $htmlaccessname."\/".$pdffile;

    return $userpdfpath; #pfad mit userverzeichnis zurückgeben 

}



sub pdfdelete {
    my $dbhandle = shift;
    my $loesch_id = shift;

    my $pdfdir = &DbDefs::inputpdfdir;  #gibt Pfad zurück, in dem alle pdf-Dateien liegen

# Verzeichnispfad für user
    my $htmlaccessname = $ENV{REMOTE_USER};


    my $userpdfdir = $pdfdir.$htmlaccessname."\/";
    

    my $filequery;
    my $filequeryerfolg;
    
    my $filequerytext = qq/ select pdffile from document where (documentid = $loesch_id)/;
    $filequery = $dbhandle->prepare($filequerytext);
    $filequeryerfolg = $filequery->execute();


    
    my $deletepdf;
    if (($deletepdf) = $filequery->fetchrow_array) {
	print "<p>documentid = $loesch_id\n</p>";
#	    print "DELETE $pdfdir.$deletepdf\n";
	unless (unlink ($pdfdir.$deletepdf)) {
	    print "<p>can not find ${pdfdir}$deletepdf\nmaybe its not in $userpdfdir</p>\n";
	}
	$filequery->finish;
    }
    return;
}


return 1;
    










