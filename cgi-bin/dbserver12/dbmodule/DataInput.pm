package DataInput;


use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;

use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use IO::String;
use IO::File;


use htmlmodule::PDF;
# use dbmodule::DbConnect;



# Dieses modul soll die Daten aus einem Hash in die Datenbank einfügen. Der Hash hat einen ersten Schlüssel, der den Datensatz kennzeichnet und einen zweiten Schlüssel, der das Feld im Datensatz benennt. Das modul soll den Hash entweder von einem import-Filter-Skript (db_import.pl) bekommen oder von einer html-Seite (datainsert.pl).

# &Datainput::input(Datenbankhandle, Referenz auf Datenhash, owner (=username aus .htaccess));
# &DataInput::input($dbhandle, $datenhashref, $owner);







sub input {
    my $dbhandle = shift;
    my $datenhashref = shift;
    my $owner = shift;
    my $ignore_doubles = shift;
    my $ziparc = shift;

    my %datenhash = %$datenhashref;

    my $datensatznr;
    my @dockeyarray;
    my $dockeyarrayref;




#Alle Tabellen sperren, in den Abfragen dürfen keine aliasse wie document d sein, da Abfrage sonst nicht funktioniert 

# die Sperrung sollte einzeln für die schleifendurchläufe durchgeführt werden


 my $locktablestext = $dbhandle->prepare(qq/lock tables author write, aut_writes_doc write, doctype write, document write, edits_book write, edits_series write, book write, series write, journal write, keyword write, kword_in_doc write, owner write, species write, species_in_doc write, verlag write, institution write/);


my $tablelockerfolg;
    unless ($tablelockerfolg = $locktablestext->execute) {
	die "<h1>konnte Tabellen nicht sperren</h1>\n";
    }


# Abfragen vorbereiten damit sie nicht bei jedem Datensatz neu vorbereitet werden müssen, ist schneller, aber auch etwas unübersichtlicher

# Frage ob Titel schon vorhanden und nach Autoren und Jahr  
    my $documentquery = $dbhandle->prepare (qq/select document.documentid, document.year, author.name from document
			    inner join aut_writes_doc on (document.documentid = aut_writes_doc.documentid)
			    inner join author on (author.authorid = aut_writes_doc.authorid)
			    where (document.title = ?)/);

# wenn schon vorhanden document.doubleflagg in altem dokument auf 1 setzen
    my $updatedoubleflagg =$dbhandle->prepare(qq/update document set document.doubleflagg = 1
							  where (document.documentid = ?)/);

# author
    my $authorquery = $dbhandle->prepare(qq/SELECT author.authorid
                            FROM author
                            WHERE (author.name = ?)/);


    my $insertauthor = $dbhandle->prepare(qq/INSERT INTO author (name)
                            VALUES (?)/);

# aut_writes_doc
    my $insertawd = $dbhandle->prepare(qq/INSERT INTO aut_writes_doc (authorid, author_rank, documentid)
                            VALUES (?,?,?)/);

# journal
    my $journalquery = $dbhandle->prepare(qq/SELECT journal.journalid, journal.journaltitle, journal.titlesynonym1
                            FROM journal
                            WHERE (journal.journaltitle = ?) OR (journal.titlesynonym1 = ?)/);

    my $insertjournal = $dbhandle->prepare(qq/INSERT INTO journal (journaltitle, titlesynonym1)
                            VALUES (?, ?)/);


    my $updatejournaltitle = $dbhandle->prepare("UPDATE journal SET journal.journaltitle = ?
                                WHERE journal.titlesynonym1 = ?");

    my $updatejournalid = $dbhandle->prepare("UPDATE document SET document.journalid = ?
                                WHERE document.documentid = ?");

# keyword
    my $keywordquery = $dbhandle->prepare("SELECT keyword.keywordid
                                FROM keyword
                                WHERE (keyword.word = ?)");

    my $insertkeyword = $dbhandle->prepare("INSERT INTO keyword (word) VALUES (?)");

# keyword_in_doc
    my $insertkwd = $dbhandle->prepare("INSERT INTO kword_in_doc (keywordid, documentid)
                                VALUES (?,?)");

# book und edits_book

    my $concat_editsbookquery = $dbhandle->prepare(qq/select book.bookid, book.booktitle,
						   group_concat(author.name order by edits_book.editor_rank separator '; ')
						   from book
						   left join edits_book on (book.bookid = edits_book.bookid)
						   inner join author on (edits_book.authorid = author.authorid)
						   where (book.booktitle = ?) group by book.bookid/);



#	my $bookquery = $dbhandle->prepare(qq/select book.bookid from book where (book.booktitle = ?)/);

#	my $edits_bookquery = $dbhandle->prepare(qq/select author.name
#                                       from book
#                                       left join edits_book on (book.bookid = edits_book.bookid)
#                                       inner join author on (edits_book.authorid = author.authorid)
#                                       where (book.bookid = ?) order by edits_book.editor_rank/);


  # book
#    my $insertbook = $dbhandle->prepare("INSERT INTO book (booktitle) VALUES (?)");
# muss in der Schleife abgefragt werden, damit auf den bookkey mit last_insert_id zugegriffen werden kann  
    my $updatebookid = $dbhandle->prepare("UPDATE document SET document.bookid = ?
                                WHERE document.documentid = ?");
    
  # edits_book
  # nicht vergessen: vor authoreintrag prüfen, ob nicht schon vorhanden
    my $insert_bookeditor = $dbhandle->prepare("INSERT INTO author (name)
                                             VALUES (?)");
    
    my $insertedits_book = $dbhandle->prepare("INSERT INTO edits_book (authorid, editor_rank, bookid)
                                    VALUES (?,?,?)");
    


# series und edits_series
    my $concat_editsseriesquery = $dbhandle->prepare(qq/select series.seriesid, series.seriestitle,
						   group_concat(author.name order by edits_series.serieseditor_rank separator '; ')
						   from series
						   left join edits_series on (series.seriesid = edits_series.seriesid)
						   inner join author on (edits_series.authorid = author.authorid)
						   where (series.seriestitle = ?) group by series.seriesid/);



#    my $seriesquery = $dbhandle->prepare(qq/select series.seriesid from series where (series.seriestitle = ?)/);

#    my $edits_seriesquery = $dbhandle->prepare(qq/select author.name
#					       from series
#					       left join edits_series on (series.seriesid = edits_series.seriesid)
#					       inner join author on (edits_series.authorid = author.authorid)
#					       where (series.seriesid = ?) order by edits_series.serieseditor_rank/);



# series # muss wegen lastinsertid-abfrage in Einfügeschleife prepariert werden
#    my $insertseries = $dbhandle->prepare("INSERT INTO series (seriestitle) VALUES (?)");

    my $updateseriesid = $dbhandle->prepare("UPDATE document SET document.seriesid = ?
                                     WHERE document.documentid = ?");


#####################################################
# wenn nur titelsynonym vorhanden, sollte eventuell anders gehen 
#      my $update = $dbhandle->prepare("UPDATE journal SET journal.seriesid = ?
#                                       WHERE journal.titlesynonym1 = ?");

# ist eh fraglich, ob hier ein journal in eine serie gepackt werden soll, weil eventuell ein anderer Datensatz zwar das journal enthält, aber nicht die Serie. siehe das problem mit dem kapitelnamen "annelida", der in verschiedenen Büchern auftaucht, was zu chaos geführt hat.
#      my $updateseriesid_journalsynonym1 = $dbhandle->prepare("UPDATE journal SET journal.seriesid = ?
#                                       WHERE journal.titlesynonym1 = ?");

#      my $updateseriesid_journal = $dbhandle->prepare("UPDATE journal SET journal.seriesid = ?
#                                       WHERE journal.journaltitle = ?");

#      my $updateseriesid_book = $dbhandle->prepare("UPDATE book SET book.seriesid = ?
#                                       WHERE book.booktitle = ?");
############################################



  # edits_series
  # nicht vergessen: vor editoreintrag prüfen, ob author nicht schon vorhanden
    my $insert_serieseditor = $dbhandle->prepare("INSERT INTO author (name)
                                               VALUES (?)");

    my $insertedits_series = $dbhandle->prepare("INSERT INTO edits_series (authorid, serieseditor_rank, seriesid)
                                      VALUES (?,?,?)");



# verlag
    my $verlagquery = $dbhandle->prepare("SELECT verlag.verlagid
                                 FROM verlag
                                 WHERE (verlag.verlagname = ?)");

    my $insertverlag = $dbhandle->prepare("INSERT INTO verlag (verlagname, verlagort) VALUES (?, ?)");


    my $updateverlagid = $dbhandle->prepare("UPDATE document SET document.verlagid = ?
                                     WHERE document.documentid = ?");



#############################################
# wenn nur synonym angegeben ist
#    my $updateverlagid_journalsynonym = $dbhandle->prepare("UPDATE journal SET journal.verlagid = ?
#                                       WHERE journal.titlesynonym1 = ?");
#    
#    my $updateverlagid_journalsynonym1 = $dbhandle->prepare("UPDATE journal SET journal.verlagid = ?
#                                       WHERE journal.titlesynonym1 = ?");
#
#    my $updateverlagid_journal = $dbhandle->prepare("UPDATE journal SET journal.verlagid = ?
#                                       WHERE journal.journaltitle = ?");
#    
#    my $updateverlagid_book = $dbhandle->prepare("UPDATE book SET book.verlagid = ?
#                                       WHERE book.booktitle = ?");
#    
#    my $updateverlagid_series = $dbhandle->prepare("UPDATE series SET series.verlagid = ?
#                                       WHERE series.seriestitle = ?");
##################################




# species
    my $speciesquery = $dbhandle->prepare("SELECT species.speciesid
                                FROM species
                                WHERE (species.speciesname = ?)");

    my $insertspecies = $dbhandle->prepare("INSERT INTO species (speciesname) VALUES (?)");

# species_in_doc
    my $insertspecies_in_doc = $dbhandle->prepare("INSERT INTO species_in_doc (speciesid, documentid)
                                VALUES (?,?)");



# owner
    my $ownerquery = $dbhandle->prepare(qq/select ownerid from owner
					where (owner.name = ?)/);

    my $insertowner = $dbhandle->prepare(qq/insert into owner (name)
					 values (?)/);

    my $updateownerid = $dbhandle->prepare(qq/update document set document.ownerid = ?
						 where (document.documentid = ?)/); 


# doctype
    my $doctypequery = $dbhandle->prepare(qq/select doctypeid from doctype
					where (doctype.doctype = ?)/);

    my $insertdoctype = $dbhandle->prepare(qq/insert into doctype (doctype)
					 values (?)/);

    my $updatedoctypeid = $dbhandle->prepare(qq/update document set document.doctypeid = ?
						 where (document.documentid = ?)/); 


# institution
    my $institutionquery = $dbhandle->prepare(qq/select institutionid from institution
					where (institution.institution = ?)/);

    my $insertinstitution = $dbhandle->prepare(qq/insert into institution (institution)
					 values (?)/);

    my $updateinstitutionid = $dbhandle->prepare(qq/update document set document.institutionid = ?
						 where (document.documentid = ?)/); 



    my @zipmemberlist;

    if ($ziparc) {
	@zipmemberlist = $ziparc -> memberNames();
    }


# hier Schleife für das Einfügen

JUMP:    foreach $datensatznr (sort (keys (%datenhash))) {



# wenn autoren vorhanden, diese einlesen, sonst der autorenliste "unknown" zuweisen
	if  ((not defined($datenhash{$datensatznr}{author})) || ($datenhash{$datensatznr}{author} eq "")) {

	    push (@{$datenhash{$datensatznr}{author}}, "unknown");
#	    print "BLLLARG autor eingefügt";
	}




	my @authorlist = @{$datenhash{$datensatznr}{author}};


# if the hash contains no title set title to "no title"
	if ((not defined($datenhash{$datensatznr}{title})) || ($datenhash{$datensatznr}{title} eq "")) {
	    $datenhash{$datensatznr}{title} = "no title";
	}
    

# Überprüfen ob Titel mit dem selben Jahr schon vorhanden, mögliche doppelte in einer Spalte document.doubleflagg markieren (Autoren überprüfen macht nicht so viel Sinn, weil die eventuell andere Schreibweisen des Vornamens/der Initialen haben und damit nicht erkannt werden würden


# Frage ob Titel schon vorhanden und nach Autoren und Jahr  
#    my $documentquery = $dbhandle->prepare (qq/select d.documentid, d.year, a.name from document d
#			    inner join aut_writes_doc awd on (d.documentid = awd.documentid)
#			    inner join author a on (a.authorid = awd.authorid)
#			    where (d.title = ?)/);
    
	$datenhash{$datensatznr}{doubleflagg} = 0;
	$documentquery->execute ($datenhash{$datensatznr}{title});
    
	
	
# wenn schon vorhanden document.doubleflagg in altem dokument auf 1 setzen
#    my $updatedoubleflagg =$dbhandle->prepare(qq/update document set document.doubleflagg = 1
#							  where (document.documentid = ?)/);

################hier muss abfrage rein, die auch mehrere schon vorhandene gleiche titel erkennt

	my %docergebnishash;
	
	my @docvorhanden;
	while (@docvorhanden = $documentquery->fetchrow_array) {
	    $docergebnishash{$docvorhanden[0]}{year} = $docvorhanden[1];
	}
	my $schluessel;
	foreach $schluessel (keys (%docergebnishash)) {
	    if ($docergebnishash{$schluessel}{year} eq $datenhash{$datensatznr}{year}) {
		if ($ignore_doubles eq "on") {
#		    print "<p>dataset: $authorlist[0] $datenhash{$datensatznr}{year} $datenhash{$datensatznr}{title} not imported, because possible double </p>\n";
		    next JUMP;
		}
		else {
		    $updatedoubleflagg->execute($docvorhanden[0]);
		    $datenhash{$datensatznr}{doubleflagg} = 1;
		}
	    }
	}
	
#	     print "11111111111111111111111111111111111111111111111111";

#=command
# copy pdf to pdfdir 

#	my $delete_pdfdummy;
#	my $oldfiledummy;


#	     print $datenhash{$datensatznr}{filehandle},"xxxxxxxxxx";
# if $datahash comes from import filter the entry $datenhash{$datensatznr}{pdffile} contains the filename and a filehandle must be opened
# if $datahash comes from change or insert the entry a filehandle is given with $datenhash{$datensatznr}{filehandle} but $datenhash{$datensatznr}{pdffile} should not exist 


	my $filearrayref;
	my @filearray;


####load pdf from zip file, $datenhash{$datensatznr}{pdffile} contains the name of the pdf



	if ($ziparc) {
	    my $pdftempstring;
	    my $pdffh = IO::String->new($pdftempstring);
#	    my $pdffh;
#	    open ($pdffh, ">", \$pdftempstring) or die "can not open temp-file for datafile\n";
	    binmode ($pdffh);
	    
	    my @zipmember;
	    my $newfilepath;

	    if ($datenhash{$datensatznr}{pdffile}) {
#put backslashes into filename and path if there are non alphanumeric signs 
		$newfilepath = $datenhash{$datensatznr}{pdffile};
		$newfilepath =~ s/([^\w\.\/])/\\$1/g;
		$newfilepath =~ s/\\\\/\//g;
		$newfilepath =~ s/\W+$//;


		my $test;
#		while ((!((@zipmember) = $ziparc->membersMatching(".*$newfilepath"))) && ($newfilepath =~ s/^.*?\///)) {
# andersrum durchsuchen, sonst endet die Suche wenn eine gleichnamige Datei in einem hoeheren Verzeichnis gefunden wird
		while ((!((@zipmember) = $ziparc->membersMatching(".*$newfilepath"))) && ($newfilepath =~ s/^.*?\///)) {
		    1;
		}
	    }

# try refmanid as pdfname for Alex data

	    if ($#zipmember != 0 ) {
		if ($datenhash{$datensatznr}{refmanid}) {

		    my $refmantext;
		    foreach my $pdfname (@zipmemberlist) {
			if ($pdfname =~ m/.*${datenhash{$datensatznr}{refmanid}}.*/i) {
			    $refmantext = $pdfname;
			    $refmantext =~ s/.*\/(.*)/$1/;
			    unless ((@zipmember) = $ziparc->membersMatching(".*$refmantext.*")) {
				print "\n<p>$refmantext not found<\/p>"; 
			    }

			}
		    }

#		    my $refmantext = $datenhash{$datensatznr}{refmanid};
#		    $refmantext = lc($refmantext);
#		    $refmantext = ucfirst($refmantext);
#		    if ($refmantext =~ m/\d+(\D+)/) {
#			my $letter = uc($1);
#			$refmantext =~ s/(\d+)\D+/$1$letter/;
#		    }
#		    unless ((@zipmember) = $ziparc->membersMatching(".*$refmantext\..*")) {
#			print "\n<p>$refmantext not found<\/p>"; 
#		    }
		}
	    }


	    if ($#zipmember == 0 ) {
		    my $extname = $zipmember[0]->externalFileName();
#		    print "<p>$extname</p>\n";
		    $zipmember[0]->extractToFileHandle($pdffh);
		    seek ($pdffh, 0, 0);
		    unless ($datenhash{$datensatznr}{pdffile} = &PDF::pdfload(\%datenhash, $datensatznr, $pdffh)) {
			$datenhash{$datensatznr}{pdffile} = undef;
#			print "A0";
		    }
	    }		
#		else {
#		    my $extname = $zipmember->externalFileName();
#		    print "<p>could not extract $zipmember \($datenhash{$datensatznr}{pdffile}\) $extname</p>\n";
#		    $datenhash{$datensatznr}{pdffile} = "";
#		    print "A0";
#		}


	    
	    else { 

		if ($datenhash{$datensatznr}{pdffile}) {

		    print "<p>$datenhash{$datensatznr}{pdffile} = $newfilepath not found in zip archive</p>\n";
		    $datenhash{$datensatznr}{pdffile} = undef;
#		print "A0";
		}
	    }
	    close ($pdffh);
	}



# copy pdf-file, if an existing dataset is copied 

	else { # else to if ($ziparc)

	    if (($datenhash{$datensatznr}{pdffile}) && (not($datenhash{$datensatznr}{filehandle}))) {
##		    print "$datenhash{$datensatznr}{pdffile}";

		if (-e $datenhash{$datensatznr}{pdffile}) {
		    if (open(PDFFILE, "</$datenhash{$datensatznr}{pdffile}")) {
			@filearray = <PDFFILE>;
			$filearrayref = \@filearray;
			close (PDFFILE);
			
##		    $datenhash{$datensatznr}{filehandle} = $filehandle;
##		    print "$datenhash{$datensatznr}{pdffile}";
			

			unless ($datenhash{$datensatznr}{pdffile} = &PDF::pdfload(\%datenhash, $datensatznr, $datenhash{$datensatznr}{filehandle}, $filearrayref)) {
			    $datenhash{$datensatznr}{pdffile} = undef;
			}	
		    }
		    else {
			die "read filehandle error";
		    }
		}
		else {
		    print "<p>$datenhash{$datensatznr}{pdffile} not found</p>\n";
		}
	    }
##################
	
	    else {
		
		
# delete pdf-file from a dataset  
		if (($datenhash{$datensatznr}{delete_pdf} eq "delpdf") && ($datenhash{$datensatznr}{oldpdffile})) {
		    &PDF::pdfdelete($dbhandle, $datensatznr);
		    $datenhash{$datensatznr}{oldpdffile} = undef;
#	     print "A1";
		}
		
# replace a pdf-file	    
		if (($datenhash{$datensatznr}{filehandle}) && ($datenhash{$datensatznr}{oldpdffile})) {
		    &PDF::pdfdelete($dbhandle, $datensatznr);
		    $datenhash{$datensatznr}{oldpdffile} = undef;
#	     print "A2";
		    unless ($datenhash{$datensatznr}{pdffile} = &PDF::pdfload(\%datenhash, $datensatznr, $datenhash{$datensatznr}{filehandle})) {
			$datenhash{$datensatznr}{pdffile} = undef;
#	     print "A3";
		    }	
#	     print "A3A";
		}
		
		
# load new pdf-file	    
		elsif (($datenhash{$datensatznr}{filehandle}) && (not($datenhash{$datensatznr}{oldpdffile}))) {
#	     print "A4";
		    unless ($datenhash{$datensatznr}{pdffile} = &PDF::pdfload(\%datenhash, $datensatznr, $datenhash{$datensatznr}{filehandle})) {
			$datenhash{$datensatznr}{pdffile} = undef;
#	     print "A5";
		    }	
		}
		
# keep the old pdf-file	    
		elsif ((not($datenhash{$datensatznr}{filehandle})) && ($datenhash{$datensatznr}{oldpdffile})) {
		    $datenhash{$datensatznr}{pdffile} = $datenhash{$datensatznr}{oldpdffile};
#	     print "A6";
		}
	    }		
	}	
#	print "======$datenhash{$datensatznr}{pdffile}";
################
#=cut
	
	

	my ($insertyear, $insertmonth, $insertday, $inserthour, $insertminute, $insertsecond)  = (localtime)[5,4,3,2,1,0];
my $inserttime = sprintf ("%04d%02d%02d%02d%02d%02d", $insertyear, $insertmonth + 1, $insertday, $inserthour, $insertminute, $insertsecond);
	
	
	
# Dokumentdaten in document einfügen,
# wird hier prepariert, damit die anschliessende Abfrage nach der last_insert_id den Schlüssel des zuletzt eingegebenen Dokuments ermittelt. Danach werden beide Abfragen (insertdocument und last_insert_id) geschlossen. Wenn die insert-Abfrage offen bleibt und in jedem Schleifendurchlauf wiederholt wird ermittelt last_insert_id den ersten Wert der innerhalb dieses Threads eingefügt wurde, also den beim ersten Schleifendurchlauf eingefügten Schlüssel (document.documentid)
	
	my $insertdocument = $dbhandle->prepare(qq/INSERT INTO document (refmanid, title, year, volume, issue, startpage, endpage, notizen, isbn, abstract, contactaddress, doubleflagg, available, pdffile, inserttime)
						VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)/);
	
	$insertdocument->execute ($datenhash{$datensatznr}{refmanid}, $datenhash{$datensatznr}{title},
				  $datenhash{$datensatznr}{year},
				  $datenhash{$datensatznr}{volume}, $datenhash{$datensatznr}{issue},
				  $datenhash{$datensatznr}{startpage}, $datenhash{$datensatznr}{endpage},
				  $datenhash{$datensatznr}{notizen}, $datenhash{$datensatznr}{isbn},
				  $datenhash{$datensatznr}{abstract}, $datenhash{$datensatznr}{contactaddress},
				  $datenhash{$datensatznr}{doubleflagg}, $datenhash{$datensatznr}{available}, 
				  $datenhash{$datensatznr}{pdffile}, $inserttime) or die $insertdocument->errstr;



# Schluessel des gerade eingetragenen document-titles ermitteln
# abfrage der last_insert_id durchgeführt, muss vor dem schliessen der insert-abfrage ausgeführt werden, da sonst kein wert ermittelt wird, ist auch wichtig, da sonst eventuell nicht die zugehörige id ermittelt wird. Es sollte wohl überprüft werden, ob die insertfunktion funktioniert hat, da sonst falscher wert zurückgegeben wird?

	my $lastdocidquery = $dbhandle->prepare(qq/SELECT last_insert_id()/);
	$lastdocidquery->execute ();
	my $dockey;
	unless (($dockey) = $lastdocidquery->fetchrow_array) {
	    die "<p>cant get the doc_id of dataset<p>"; 
	}
	$lastdocidquery->finish;
	$insertdocument->finish;
	

# print "<p>blaaaarrrrrg $dockey</p>\n";	
	
# author
	
	my $rank = 0;
	my $authorid;
	my $authorname;
	foreach $authorname (@authorlist) {
	    $rank++;
	    $authorquery->execute ($authorname);
	    if (not (($authorid) = $authorquery->fetchrow_array)) {
		$insertauthor->execute ($authorname);
		$authorquery->execute ($authorname);
		($authorid) = $authorquery->fetchrow_array;
	    }
	    $insertawd->execute($authorid, $rank, $dockey);
	}
	
	
	
# keyword
	
	if ($datenhash{$datensatznr}{keyword}) {
	    my @keywordlist = @{$datenhash{$datensatznr}{keyword}};
	    my $keywordid;
	    my $keyword;
	    foreach $keyword (@keywordlist) {
		$keywordquery->execute ($keyword);
		if (not (($keywordid) = $keywordquery->fetchrow_array)) {
		    $insertkeyword->execute ($keyword);
		    $keywordquery->execute ($keyword);
		    ($keywordid) = $keywordquery->fetchrow_array;
		}
		$insertkwd->execute($keywordid, $dockey);
	    }
	} #Ende der if ($datensatz{$datensatznr}{keyword}) - Anweisungen
	
    
	
#Journal

	if ($datenhash{$datensatznr}{journal} or $datenhash{$datensatznr}{journalsynonym1}) {
	    $journalquery->execute ($datenhash{$datensatznr}{journal}, $datenhash{$datensatznr}{journalsynonym1});
	    my $journalid;
	    my $journaltitle;
	    my $synonym1;
# Überprüfen ob in Datenbank Journaleintrag vorhanden, sonst eintragen
	    if (not (($journalid, $journaltitle, $synonym1) = $journalquery->fetchrow_array)) {
		$insertjournal->execute ($datenhash{$datensatznr}{journal}, $datenhash{$datensatznr}{journalsynonym1});
		$journalquery->execute ($datenhash{$datensatznr}{journal}, $datenhash{$datensatznr}{journalsynonym1});
		($journalid, $journaltitle, $synonym1) = $journalquery->fetchrow_array;
	    }

# Wenn in Datenbank nur Titelsynonym, in Datensatz aber Titel und Synonym den Titel aus dem Datensatz in die Datenbank einfügen
	    if (($datenhash{$datensatznr}{journal} and $datenhash{$datensatznr}{journalsynonym1}) and (not ($journaltitle)))  {
		$updatejournaltitle->execute($datenhash{$datensatznr}{journal}, $synonym1);
	    }
	    $updatejournalid->execute($journalid, $dockey);
	}
    


# book und edits_book


	if ($datenhash{$datensatznr}{book}) {


# concat book and book_editors
	    my $tempbookid;
	    my $bookid;
	    my $booktitle;
	    my $book_editor;
	    my $bookeditors;
	    my @bookeditorlist;
#	    my $bookeditorstring = join ('; ', @bookeditorlist);
	    my $same_book = 0;



	    if ($datenhash{$datensatznr}{bookeditor}) {
		@bookeditorlist = @{$datenhash{$datensatznr}{bookeditor}};
	    }


	    my $bookeditorstring = join ('; ', @bookeditorlist);


	    my $book_in_database;
	    my $book_in_hash = $datenhash{$datensatznr}{book}.$bookeditorstring;

	    #print "<p>bla</p>bla<p>bla</p><p>bla</p>bla<p>bla</p><p>book $datenhash{$datensatznr}{book} bookeditorstring $bookeditorstring \n</p>"; 


	    $concat_editsbookquery->execute($datenhash{$datensatznr}{book}) or die ("$DBI::err: $DBI::errstr.\n");

 	    while (($tempbookid, $booktitle, $bookeditors) = $concat_editsbookquery->fetchrow_array) {
		$book_in_database = $booktitle.$bookeditors;
		#print "<p></p><p></p><p>\$book_in_database: $book_in_database\n</p>"; 

		if ($book_in_database eq $book_in_hash) {
		    $same_book = 1;
		    $bookid = $tempbookid;
		#print "<p>same book:#################### \$book_in_database: $book_in_database, \$book_in_hash: $book_in_hash\n</p>";
		}
		else {
		    $same_book = 0;
		#print "<p>not same book: \$book_in_database: $book_in_database, \$book_in_hash: $book_in_hash\n</p>";
		}
	    }




# abfrage ob Buch mit diesen Editoren schon vorhanden
#	    my $zwischen_book_id;
#	    my $bookid;
#	    my $same_book = 0;
#	    my @bookidarray;
#	    my $book_editor;
#	    my @bookeditorlist;
#	    my $bookeditorstring = "";


#	    if ($datenhash{$datensatznr}{bookeditor}) {
#		@bookeditorlist = @{$datenhash{$datensatznr}{bookeditor}};
#		$bookeditorstring = join (' ', @bookeditorlist);
#	    }

#	    $bookquery->execute($datenhash{$datensatznr}{book});

# 	    while (($zwischen_book_id) = $bookquery->fetchrow_array) {
#		push (@bookidarray, $zwischen_book_id);
#	    }

#	    foreach $zwischen_book_id (@bookidarray) {
#		my @zwischenarray;
#		$edits_bookquery->execute($zwischen_book_id);
#
#		while (($book_editor) = $edits_bookquery->fetchrow_array) {
#		    push (@zwischenarray, $book_editor);
#		}
#
#		my $zwischenstring = "";
#		$zwischenstring = join (' ', @zwischenarray);	     
#		if ($zwischenstring eq $bookeditorstring) {
#		    $same_book = 1;
#		    $bookid = $zwischen_book_id;
#		}
#	    }


	    if ($same_book == 1) { 
		$updatebookid->execute($bookid, $dockey);
	    }
	    else {
		my $insertbook = $dbhandle->prepare("INSERT INTO book (booktitle) VALUES (?)");
		$insertbook->execute ($datenhash{$datensatznr}{book});
# hier muss last_insert_id abgefragt werden, da $bookquery->execute ($datenhash{$datensatznr}{book}); eventuell die falsche id von dem schon vorher existierenden Eintrag ergibt
		my $lastbookidquery = $dbhandle->prepare(qq/SELECT last_insert_id()/);
		$lastbookidquery->execute ();
		
		unless (($bookid) = $lastbookidquery->fetchrow_array) {
		    die "<h4>konnte den key des letzten eingegebenen Buches nicht ermitteln!<h/4>"; 
		}
		$lastbookidquery->finish;
		$insertbook->finish;
		
		my $rank = 0;
		my $authorid;
		foreach $book_editor (@bookeditorlist) {
		    $rank++;
		    $authorquery->execute ($book_editor);
		    if (not (($authorid) = $authorquery->fetchrow_array)) {
			$insertauthor->execute ($book_editor);
			$authorquery->execute ($book_editor);
			($authorid) = $authorquery->fetchrow_array;
		    }
		    $insertedits_book->execute($authorid, $rank, $bookid);
		}
		$updatebookid->execute($bookid, $dockey);
	    }
	}	
    
	
    
#series und edits_series


	if ($datenhash{$datensatznr}{series}) {

# abfrage ob Serie mit Editoren schon vorhanden



# concat series and series_editors
	    my $tempseriesid;
	    my $seriesid;
	    my $seriestitle;
	    my $series_editor;
	    my $serieseditors;
	    my @serieseditorlist;
#	    my $serieseditorstring = join ('; ', @serieseditorlist);
	    my $same_series = 0;



	    if ($datenhash{$datensatznr}{serieseditor}) {
		@serieseditorlist = @{$datenhash{$datensatznr}{serieseditor}};
	    }


	    my $serieseditorstring = join ('; ', @serieseditorlist);


	    my $series_in_database;
	    my $series_in_hash = $datenhash{$datensatznr}{series}.$serieseditorstring;

	    $concat_editsseriesquery->execute($datenhash{$datensatznr}{series}) or die ("$DBI::err: $DBI::errstr.\n");

 	    while (($tempseriesid, $seriestitle, $serieseditors) = $concat_editsseriesquery->fetchrow_array) {
		$series_in_database = $seriestitle.$serieseditors;
		#print "<p>bla</p>bla<p>bla</p><p>bla</p>bla<p>bla</p><p>\$series_in_database: $series_in_database\n</p>"; 

		if ($series_in_database eq $series_in_hash) {
		    $same_series = 1;
		    $seriesid = $tempseriesid;
		#print "<p>same series: \$series_in_database: $series_in_database, \$series_in_hash: $series_in_hash\n</p>";
		}
		else {
		    $same_series = 0;
		#print "<p>same series: \$series_in_database: $series_in_database, \$series_in_hash: $series_in_hash\n</p>";
		}
	    }



=command
	    my $seriesid;
	    my $zwischen_series_id;
	    my $same_series;
	    my @seriesidarray;
	    my $series_editor;
	    my @serieseditorlist;
	    my $serieseditorstring ="";

	    if ($datenhash{$datensatznr}{serieseditor}) {
		@serieseditorlist = @{$datenhash{$datensatznr}{serieseditor}};
		$serieseditorstring = join (' ', @serieseditorlist);
	    }

	    $seriesquery->execute($datenhash{$datensatznr}{series});

 	    while (($zwischen_series_id) = $seriesquery->fetchrow_array) {
		push (@seriesidarray, $zwischen_series_id);
	    }

	    foreach $zwischen_series_id (@seriesidarray) {
		my @zwischenarray;
		$edits_seriesquery->execute($zwischen_series_id);

		while (($series_editor) = $edits_seriesquery->fetchrow_array) {
		    push (@zwischenarray, $series_editor);
		}

		my $zwischenstring = "";
		$zwischenstring = join (' ', @zwischenarray);	     

		if ($zwischenstring eq $serieseditorstring) {
		    $same_series = 1;
		    $seriesid = $zwischen_series_id;
		}
	    }
=cut


	    if ($same_series) { 
		$updateseriesid->execute($seriesid, $dockey);
	    }
	    else {
		my $insertseries = $dbhandle->prepare("INSERT INTO series (seriestitle) VALUES (?)");
		$insertseries->execute ($datenhash{$datensatznr}{series});
# hier muss last_insert_id abgefragt werden, da bei gleichnamiger Serie sonst falsche seriesid gefundenwerden könnte
		my $lastseriesidquery = $dbhandle->prepare(qq/SELECT last_insert_id()/);
		$lastseriesidquery->execute ();
		unless (($seriesid) = $lastseriesidquery->fetchrow_array) {
		    die "<h4>konnte den key der letzten eingegebenen Serie nicht ermitteln!<h/4>"; 
		}
		$lastseriesidquery->finish;
		$insertseries->finish;
		
		my $rank = 0;
		my $authorid;
		foreach $series_editor (@serieseditorlist) {
		    $rank++;
		    $authorquery->execute ($series_editor);
		    if (not (($authorid) = $authorquery->fetchrow_array)) {
			$insertauthor->execute ($series_editor);
			$authorquery->execute ($series_editor);
			($authorid) = $authorquery->fetchrow_array;
		    }
		    $insertedits_series->execute($authorid, $rank, $seriesid);
		}
		$updateseriesid->execute($seriesid, $dockey);
	    
##############################################	    
# seriesid in journal und book updaten
#
#		if ($datenhash{$datensatznr}{journalsynonym1}) {
#		    $updateseriesid_journalsynonym1->execute($seriesid, $datenhash{$datensatznr}{journalsynonym1});
#		}
#		elsif ($datenhash{$datensatznr}{journal}) {
#		    $updateseriesid_journal->execute($seriesid, $datenhash{$datensatznr}{journal});
#		}
#		
#		if ($datenhash{$datensatznr}{book}) {
#		    $updateseriesid_book->execute($seriesid, $datenhash{$datensatznr}{book});
#		}
###########################################



	    } #Ende der if ($datensatz{$datensatznr}{series}) - Anweisungen	    
	}

	    

# species    

	if ($datenhash{$datensatznr}{species}) {
	    my @specieslist = @{$datenhash{$datensatznr}{species}};
	    my $speciesid;
	    my $species;
	    foreach $species (@specieslist) {
		$speciesquery->execute ($species);
		if (not (($speciesid) = $speciesquery->fetchrow_array)) {
		    $insertspecies->execute ($species);
		    $speciesquery->execute ($species);
		    ($speciesid) = $speciesquery->fetchrow_array;
		}
		$insertspecies_in_doc->execute($speciesid, $dockey);
	    }
	} #Ende der if ($datensatz{$datensatznr}{species}) - Anweisungen
	
	
# owner

#    my $ownerquery = $dbhandle->prepare(qq/select ownerid from owner
#					where (owner.name = ?)/);

#    my $insertowner = $dbhandle->prepare(qq/insert into owner (name)
#					 values (?)/);

#    my $update_ownerid = $dbhandle->prepare(qq/update document set document.ownerid = ?
#						 where (document.documentid = ?)/); 

	if ($owner) {
	    $ownerquery->execute ($owner);
	    my $ownerid;

# Überprüfen ob in Datenbank owner vorhanden, sonst eintragen
	    if (not (($ownerid) = $ownerquery->fetchrow_array)) {
		$insertowner->execute ($owner);
		$ownerquery->execute ($owner);
		($ownerid) = $ownerquery->fetchrow_array;
	    }
	    $updateownerid->execute($ownerid, $dockey);
	}	



# verlag
	
	if ($datenhash{$datensatznr}{verlag}) {
	    $verlagquery->execute ($datenhash{$datensatznr}{verlag});
	    my $verlagid;

# Überprüfen ob in Datenbank verlag vorhanden, sonst eintragen
	    if (not (($verlagid) = $verlagquery->fetchrow_array)) {
		$insertverlag->execute ($datenhash{$datensatznr}{verlag}, $datenhash{$datensatznr}{verlagort});
		$verlagquery->execute ($datenhash{$datensatznr}{verlag});
		($verlagid) = $verlagquery->fetchrow_array;
	    }
	    $updateverlagid->execute($verlagid, $dockey);


###########################
#	    if ($datenhash{$datensatznr}{journalsynonym1}) {
#		$updateverlagid_journalsynonym1->execute($verlagid, $datenhash{$datensatznr}{journalsynonym1});
#	    }
#	    elsif ($datenhash{$datensatznr}{journal}) {
#		$updateverlagid_journal->execute($verlagid, $datenhash{$datensatznr}{journal});
#	    }
#	    
#	    if ($datenhash{$datensatznr}{book}) {
#		$updateverlagid_book->execute($verlagid, $datenhash{$datensatznr}{book});
#	    }
#
#	    if ($datenhash{$datensatznr}{series}) {
#		$updateverlagid_series->execute($verlagid, $datenhash{$datensatznr}{series});
#	    }
####################################


	}


#doctype
	if ($datenhash{$datensatznr}{doctype}) {
	    $doctypequery->execute ($datenhash{$datensatznr}{doctype});
	    my $doctypeid;

# Überprüfen ob in Datenbank doctype vorhanden, sonst eintragen
	    if (not (($doctypeid) = $doctypequery->fetchrow_array)) {
		$insertdoctype->execute ($datenhash{$datensatznr}{doctype});
		$doctypequery->execute ($datenhash{$datensatznr}{doctype});
		($doctypeid) = $doctypequery->fetchrow_array;
	    }
	    $updatedoctypeid->execute($doctypeid, $dockey);
	}	



#institution
	if ($datenhash{$datensatznr}{institution}) {
	    unless ($institutionquery->execute ($datenhash{$datensatznr}{institution})) {die "frage tut nicht $DBI::err: $DBI::errstr.";} #war wichtig, um rauszubekommen, das welcher fehler vorlag (tabelle war nicht gelockt
	    my $institutionid;
# Überprüfen ob in Datenbank institution vorhanden, sonst eintragen
	    if (not (($institutionid) = $institutionquery->fetchrow_array)) {
		$insertinstitution->execute ($datenhash{$datensatznr}{institution});
		$institutionquery->execute ($datenhash{$datensatznr}{institution});
		($institutionid) = $institutionquery->fetchrow_array;
	    }
	    $updateinstitutionid->execute($institutionid, $dockey);
	}	


	
	push (@dockeyarray, $dockey);
    }

    my $tablereleasetext = $dbhandle->prepare(qq/unlock tables/);

    my $tableunlockerfolg;
    unless ($tableunlockerfolg = $tablereleasetext->execute) {
	die "<h1>konnte Tabellen nicht entsperren</h1>\n";
    }


	
# alle Abfragen schliessen
    $documentquery->finish;
    $updatedoubleflagg->finish;
    $authorquery->finish;
    $insertauthor->finish;
    $insertawd->finish;
    $journalquery->finish;
    $insertjournal->finish;
    $updatejournaltitle->finish;
    $updatejournalid->finish;
    $keywordquery->finish;
    $insertkeyword->finish;
    $insertkwd->finish;
#    $bookquery->finish;
#    $edits_bookquery->finish;
    $concat_editsbookquery->finish;
    $updatebookid->finish;
    $insert_bookeditor->finish;
    $insertedits_book->finish;
    $concat_editsseriesquery->finish;
#    $seriesquery->finish;
#    $edits_seriesquery->finish;
    $updateseriesid->finish;
#    $updateseriesid_journalsynonym1->finish;
#    $updateseriesid_journal->finish;
#    $updateseriesid_book->finish;
    $insert_serieseditor->finish;
    $insertedits_series->finish;
    $verlagquery->finish;
    $insertverlag->finish;
    $updateverlagid->finish;
#    $updateverlagid_journal->finish;
#    $updateverlagid_journalsynonym1->finish;
#    $updateverlagid_book->finish;
#    $updateverlagid_series->finish;
    $speciesquery->finish;
    $insertspecies->finish;
    $insertspecies_in_doc->finish;
    $ownerquery->finish;
    $insertowner->finish;
    $updateownerid->finish;
    $doctypequery->finish;
    $insertdoctype->finish;
    $updatedoctypeid->finish;
    $institutionquery->finish;
    $insertinstitution->finish;
    $updateinstitutionid->finish;



    
    $dockeyarrayref = \@dockeyarray;
    return $dockeyarrayref;
}	
    	

		
return 1;



=command
select document.documentid, document.year, author.name from document			    inner join aut_writes_doc on (document.documentid = aut_writes_doc.documentid)			    inner join author on (author.authorid = aut_writes_doc.authorid)    where (document.title like "%te%")



    SELECT author.authorid FROM author WHERE (author.name like "%al%");
	

SELECT journal.journalid, journal.journaltitle, journal.titlesynonym1 FROM journal WHERE (journal.journaltitle  like"%be%") OR (journal.titlesynonym1 like"%ba%");

select author.name from book left join edits_book on (book.bookid = edits_book.bookid) inner join author on (edits_book.authorid = author.authorid) where (book.bookid = 3) order by edits_book.editor_rank;


select author.name from series left join edits_series on (series.seriesid = edits_series.seriesid) inner join author on (edits_series.authorid = author.authorid) where (series.seriesid = 5) order by edits_series.serieseditor_rank



select book.bookid, book.booktitle, group_concat(author.name order by edits_book.editor_rank separator '; ') from book left join edits_book on (book.bookid = edits_book.bookid) inner join author on (edits_book.authorid = author.authorid) where (book.bookid = ?) group by book.bookid;



select series.seriesid, series.seriestitle, group_concat(author.name order by edits_series.serieseditor_rank separator '; ') from series left join edits_series on (series.seriesid = edits_series.seriesid) inner join author on (edits_series.authorid = author.authorid) where (series.seriestitle = ?) group by series.seriesid


=cut











