package DocDelete;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use htmlmodule::Html;
use htmlmodule::PDF;


sub deletedocs {
    my $dbhandle = shift;
    my $deldocidtable = shift;
    my $deletepdfs = shift;



# delete stepwise

# only delete pdf when the dataset should be deleted, not when it should be changed
    if ($deletepdfs eq "on") { 
	my $docidquery; 
	
	unless ($docidquery = $dbhandle->prepare(qq/select * from $deldocidtable/)) {
	    die "docidquery prepare error $DBI::err: $DBI::errstr.\n";
	}
	unless ($docidquery->execute()) {
	    die "docidquery execute error $DBI::err: $DBI::errstr.\n";
	}
	
	my $deletedocid;
	while (($deletedocid) = $docidquery->fetchrow_array()) {
	    &PDF::pdfdelete($dbhandle, $deletedocid);
	}
    }

#do not delete pdf-files, they can not be restored from bib file or mysqldump
#    unless ($fehler) {
#	&PDF::pdfdelete($dbhandle, $deletedocid);
#    }



# document
    my $docdelquery; 
    
    unless ($docdelquery = $dbhandle->prepare(qq/delete d from document d inner join $deldocidtable did on (d.documentid = did.documentid)/)) {
	die "docdelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($docdelquery->execute()) {
	die "docdelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $docdelquery->finish;
    
# awd
    my $awddelquery; 

    unless ($awddelquery = $dbhandle->prepare(qq/delete awd from aut_writes_doc awd left join document d using (documentid) where (d.documentid is NULL)/)) {
	die "awddelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($awddelquery->execute()) {
	die "awddelquery execute error $DBI::err: $DBI::errstr.\n";
    }

    $awddelquery->finish;


#book
    my $bookdelquery; 
    
    unless ($bookdelquery = $dbhandle->prepare(qq/delete b from book b left join document d using (bookid) where (d.bookid is NULL)/)) {
	die "bookdelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($bookdelquery->execute()) {
	die "bookdelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $bookdelquery->finish;

    
#edits_book
    my $ebdelquery; 

    unless ($ebdelquery = $dbhandle->prepare(qq/delete eb from edits_book eb left join book b using (bookid) where (b.bookid is NULL)/)) {
	die "ebdelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($ebdelquery->execute()) {
	die "ebdelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $ebdelquery->finish;

    
#series
    my $seriesdelquery; 
    
    unless ($seriesdelquery = $dbhandle->prepare(qq/delete s from series s left join document d using (seriesid) where (d.seriesid is NULL)/)) {
	die "seriesdelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($seriesdelquery->execute()) {
	die "seriesdelquery execute error $DBI::err: $DBI::errstr.\n";
	}
    
    $seriesdelquery->finish;
    
    
    my $esdlquery; 

    unless ($esdlquery = $dbhandle->prepare(qq/delete es from edits_series es left join series s using (seriesid) where (s.seriesid is NULL)/)) {
	die "esdlquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($esdlquery->execute()) {
	die "esdlquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $esdlquery->finish;
    

#author
    my $authordelquery; 
    
    unless ($authordelquery = $dbhandle->prepare(qq/delete a from author a left join aut_writes_doc awd on (a.authorid = awd.authorid) left join edits_book eb on (a.authorid = eb.authorid) left join edits_series es on (a.authorid = es.authorid) where (awd.authorid is NULL and eb.authorid is NULL and es.authorid is NULL)/)) {
	die "authordelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($authordelquery->execute()) {
	die "authordelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $authordelquery->finish;

    
#institution
    my $institutiondelquery; 
    
	unless ($institutiondelquery = $dbhandle->prepare(qq/delete i from institution i left join document d using (institutionid) where (d.institutionid is NULL)/)) {
	    die "institutiondelquery prepare error $DBI::err: $DBI::errstr.\n";
	}
    unless ($institutiondelquery->execute()) {
	die "institutiondelquery execute error $DBI::err: $DBI::errstr.\n";
	}
    
    $institutiondelquery->finish;
    
    
#journal
    my $journaldelquery; 
    
    unless ($journaldelquery = $dbhandle->prepare(qq/delete j from journal j left join document d using (journalid) where (d.journalid is NULL)/)) {
	die "journaldelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($journaldelquery->execute()) {
	die "journaldelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $journaldelquery->finish;
    
    
#verlag
    my $verlagdelquery; 

    unless ($verlagdelquery = $dbhandle->prepare(qq/delete v from verlag v left join document d using (verlagid) where (d.verlagid is NULL)/)) {
	die "verlagdelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($verlagdelquery->execute()) {
	die "verlagdelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $verlagdelquery->finish;
    
    
#kword_in_doc
    my $kwddelquery; 
    
    unless ($kwddelquery = $dbhandle->prepare(qq/delete kwd from kword_in_doc kwd left join document d using (documentid) where (d.documentid is NULL)/)) {
	die "kwddelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($kwddelquery->execute()) {
	die "kwddelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $kwddelquery->finish;
    
    
    
#keyword
    my $keyworddelquery; 
    
    unless ($keyworddelquery = $dbhandle->prepare(qq/delete k from keyword k left join kword_in_doc kwd using (keywordid) where (kwd.keywordid is NULL)/)) {
	die "keyworddelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($keyworddelquery->execute()) {
	die "keyworddelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $keyworddelquery->finish;

    
#spezies_in_doc
    my $spddelquery; 
    
    unless ($spddelquery = $dbhandle->prepare(qq/delete sid from species_in_doc sid left join document d using (documentid) where (d.documentid is NULL)/)) {
	die "spddelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($spddelquery->execute()) {
	die "spddelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $spddelquery->finish;
    



#species
    my $speciesdelquery; 

    unless ($speciesdelquery = $dbhandle->prepare(qq/delete s from species s left join species_in_doc sid using (speciesid) where (sid.speciesid is NULL)/)) {
	die "speciesdelquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($speciesdelquery->execute()) {
	die "speciesdelquery execute error $DBI::err: $DBI::errstr.\n";
    }
    
    $speciesdelquery->finish;

    
    
    
    return 1;

}

return 1;














