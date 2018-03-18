package TablefromDoc;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;



# This module should build a temporary table that contains all data of the given documents. call with array of docids: $flatdoctable = &TablefromDoc::docidstable($dbhandle, $docidsref); call with temporary table containing docids: $flatdoctable = &TablefromDoc::tablefromdocids($dbhandle, $docidtableref); The column with the docids should be named documentid. 


sub alldocidstable {
    my $dbhandle = shift;
    my $tempdocidtable = "tempdocidtable";

    my $createdocidtable;

    unless ($createdocidtable = $dbhandle->prepare("create temporary table $tempdocidtable (documentid int(11), primary key (documentid))")) {
	die "create tempdocidtable prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($createdocidtable->execute()) {
	die "create tempdocidtable execute error $DBI::err: $DBI::errstr.\n";
    }


    my $insertquery;
    
# print "insert into $tempdocidtable \(documentid\) values $doc_ids_string";
    
    unless ($insertquery = $dbhandle->prepare ("insert into $tempdocidtable \(documentid\) select d.documentid from document d")) {
	die "insert tempdocidtable prepare error $DBI::err: $DBI::errstr.\n";
    }
#    print "$insertquery\n";
    unless ($insertquery->execute()) {
	die "insert tempdocidtable execute error $DBI::err: $DBI::errstr.\n";
    }
    $insertquery->finish;
    
    $createdocidtable->finish;
    
    my $flatdocumenttable = &tablefromdocids($dbhandle, $tempdocidtable);

    return $flatdocumenttable; 
}




sub docidstable {
    my $dbhandle = shift;
    my $docidsref = shift;

    my @doc_ids;
    if ($docidsref) {
	@doc_ids = @$docidsref;
    }


    my $tempdocidtable = "tempdocidtable";

    my $createdocidtable;



    unless ($createdocidtable = $dbhandle->prepare("create temporary table $tempdocidtable (documentid int(11), primary key (documentid))")) {
	die "create tempdocidtable prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($createdocidtable->execute()) {
	die "create tempdocidtable execute error $DBI::err: $DBI::errstr.\n";
    }


    my $doc_ids_string = join("\'\)\,\(\' ", @doc_ids); 
    $doc_ids_string = "\(\'".$doc_ids_string."\'\)";
    my $insertquery;
    
# print "insert into $tempdocidtable \(documentid\) values $doc_ids_string";
    
    unless ($insertquery = $dbhandle->prepare ("insert into $tempdocidtable \(documentid\) values $doc_ids_string")) {
	die "insert tempdocidtable prepare error $DBI::err: $DBI::errstr.\n";
    }
#    print "$insertquery\n";
    unless ($insertquery->execute()) {
	die "insert tempdocidtable execute error $DBI::err: $DBI::errstr.\n";
    }
    $insertquery->finish;
    
    $createdocidtable->finish;
    
    
    my $flatdocumenttable = &tablefromdocids($dbhandle, $tempdocidtable);
    
    return $flatdocumenttable; 
}



sub tablefromdocids {
    my $dbhandle = shift;
    my $tempdocidtable = shift;


#build temporary doctable 

    my $doctable = "doctable";
    my $doctablequery;


    unless ($doctablequery = $dbhandle->prepare(qq/create temporary table $doctable
						select 
						d.documentid,
						d.refmanid,
						d.title,
						d.year,
						d.volume,
						d.issue,
						d.startpage,
						d.endpage,
						d.notizen,
						d.isbn,
						d.abstract,
						d.contactaddress,
						d.available,
						d.pdffile
						from document d inner join $tempdocidtable did on (d.documentid = did.documentid)/))
 {
	die "create doctablequery prepare error $DBI::err: $DBI::errstr.\n";
    }



    unless ($doctablequery->execute()) {
	die "create doctablequery execute error $DBI::err: $DBI::errstr.\n";
    }


    

#build temporary authortable 

    my $authortable = "authortable";
    my $createautquery = $dbhandle->prepare(qq/create temporary table $authortable (documentid int(11),
										   authorlist text,
										   primary key (documentid))/);
    unless ($createautquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createautquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createautquery->finish;

    my $authortablequery = $dbhandle->prepare(qq/insert into $authortable 
					      (documentid, authorlist)
					      select d.documentid,
					      group_concat(a.name order by awd.author_rank separator '; ')
					      from author a
					      inner join aut_writes_doc awd on (a.authorid = awd.authorid)
					      inner join $tempdocidtable d on (d.documentid = awd.documentid)
					      group by d.documentid/);
    unless ($authortablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($authortablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $authortablequery->finish;


#build temporary keywordtable 

    my $keywordtable = "keywordtable";
    
    my $createkwquery = $dbhandle->prepare(qq/create temporary table $keywordtable (documentid int(11),
										   keywordlist text,
										   primary key (documentid))/);
    unless ($createkwquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createkwquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createkwquery->finish;


    my $keywordtablequery = $dbhandle->prepare(qq/insert into $keywordtable 
					       (documentid, keywordlist)
					       select d.documentid,
					       group_concat(k.word separator '; ')
					       from keyword k
					       inner join kword_in_doc kid on (k.keywordid = kid.keywordid)
					       inner join $tempdocidtable d on (d.documentid = kid.documentid)
					       group by d.documentid/);
    unless ($keywordtablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($keywordtablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $keywordtablequery->finish;



#build temporary speciestable 

    my $speciestable = "speciestable";
    
    my $createspquery = $dbhandle->prepare(qq/create temporary table $speciestable (documentid int(11),
										   specieslist text,
										   primary key (documentid))/);
    unless ($createspquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createspquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createspquery->finish;


    my $speciestablequery = $dbhandle->prepare(qq/insert into $speciestable 
					       (documentid, specieslist)
					       select d.documentid,
					       group_concat(s.speciesname separator '; ')
					       from species s
					       inner join species_in_doc sid on (s.speciesid = sid.speciesid)
					       inner join $tempdocidtable d on (d.documentid = sid.documentid)
					       group by d.documentid/);
    unless ($speciestablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($speciestablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $speciestablequery->finish;




#build temporary edits_booktable 

    my $edits_booktable = "edits_booktable";
    
    my $createebquery = $dbhandle->prepare(qq/create temporary table $edits_booktable (documentid int(11),
										   edits_booklist text,
										   primary key (documentid))/);
    unless ($createebquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createebquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createebquery->finish;


    my $edits_booktablequery = $dbhandle->prepare(qq/insert into $edits_booktable 
						  (documentid, edits_booklist)
						  select d.documentid,
						  group_concat(a.name order by eb.editor_rank separator '; ')
						  from author a
						  inner join edits_book eb on (eb.authorid = a.authorid)
						  inner join book b on (b.bookid = eb.bookid)
						  inner join document doc on (doc.bookid = b.bookid)
						  inner join $tempdocidtable d on (d.documentid = doc.documentid)
						  group by d.documentid/);
    unless ($edits_booktablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($edits_booktablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $edits_booktablequery->finish;



#build temporary edits_seriestable 

    my $edits_seriestable = "edits_seriestable";
    
    my $createesquery = $dbhandle->prepare(qq/create temporary table $edits_seriestable (documentid int(11),
										   edits_serieslist text,
										   primary key (documentid))/);
    unless ($createesquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createesquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createesquery->finish;


    my $edits_seriestablequery = $dbhandle->prepare(qq/insert into $edits_seriestable 
						  (documentid, edits_serieslist)
						  select d.documentid,
						  group_concat(a.name order by es.serieseditor_rank separator '; ')
						  from author a
						  inner join edits_series es on (es.authorid = a.authorid)
						  inner join series s on (s.seriesid = es.seriesid)
						  inner join document doc on (doc.seriesid = s.seriesid)
						  inner join $tempdocidtable d on (d.documentid = doc.documentid)
						  group by d.documentid/);
    unless ($edits_seriestablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($edits_seriestablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $edits_seriestablequery->finish;
    


#build temporary journaltable 

    my $journaltable = "journaltable";
    
    my $createjournalquery = $dbhandle->prepare(qq/create temporary table $journaltable (documentid int(11),
											journaltitle text,
											titlesynonym1 tinytext,
											primary key (documentid))/);
    unless ($createjournalquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createjournalquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createjournalquery->finish;


    my $journaltablequery = $dbhandle->prepare(qq/insert into $journaltable 
					       (documentid, journaltitle, titlesynonym1)
					       select d.documentid,
					       j.journaltitle, j.titlesynonym1
					       from document doc
					       left join journal j on (doc.journalid = j.journalid)
					       inner join $tempdocidtable d on (d.documentid = doc.documentid)/);
    unless ($journaltablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($journaltablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $journaltablequery->finish;
    

#build temporary booktable 

    my $booktable = "booktable";
    
    my $createbookquery = $dbhandle->prepare(qq/create temporary table $booktable (documentid int(11),
										  booktitle text,
										  primary key (documentid))/);
    unless ($createbookquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createbookquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createbookquery->finish;


    my $booktablequery = $dbhandle->prepare(qq/insert into $booktable 
					       (documentid, booktitle)
					       select d.documentid,
					       b.booktitle
					       from document doc
					       left join book b on (doc.bookid = b.bookid)
					       inner join $tempdocidtable d on (d.documentid = doc.documentid)/);
    unless ($booktablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($booktablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $booktablequery->finish;



#build temporary seriestable 

    my $seriestable = "seriestable";
    
    my $createseriesquery = $dbhandle->prepare(qq/create temporary table $seriestable (documentid int(11),
										  seriestitle text,
										  primary key (documentid))/);
    unless ($createseriesquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createseriesquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createseriesquery->finish;


    my $seriestablequery = $dbhandle->prepare(qq/insert into $seriestable 
					       (documentid, seriestitle)
					       select d.documentid,
					       s.seriestitle
					       from document doc
					       left join series s on (doc.seriesid = s.seriesid)
					       inner join $tempdocidtable d on (d.documentid = doc.documentid)/);
    unless ($seriestablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($seriestablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $seriestablequery->finish;



#build temporary verlagtable 

    my $verlagtable = "verlagtable";
    
    my $createverlagquery = $dbhandle->prepare(qq/create temporary table $verlagtable (documentid int(11),
										      verlagname text,
										      verlagort varchar (50),
										      primary key (documentid))/);
    unless ($createverlagquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createverlagquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createverlagquery->finish;


    my $verlagtablequery = $dbhandle->prepare(qq/insert into $verlagtable 
					      (documentid, verlagname, verlagort)
					      select d.documentid,
					      v.verlagname,
					      v.verlagort
					      from document doc
					      left join verlag v on (doc.verlagid = v.verlagid)
					      inner join $tempdocidtable d on (d.documentid = doc.documentid)/);
    unless ($verlagtablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($verlagtablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $verlagtablequery->finish;



#build temporary doctypetable 

    my $doctypetable = "doctypetable";
    
    my $createdoctypequery = $dbhandle->prepare(qq/create temporary table $doctypetable (documentid int(11),
										  doctype varchar (30),
										  primary key (documentid))/);
    unless ($createdoctypequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createdoctypequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createdoctypequery->finish;


    my $doctypetablequery = $dbhandle->prepare(qq/insert into $doctypetable 
					       (documentid, doctype)
					       select d.documentid,
					       dt.doctype
					       from document doc
					       left join doctype dt on (doc.doctypeid = dt.doctypeid)
					       inner join $tempdocidtable d on (d.documentid = doc.documentid)/);
    unless ($doctypetablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($doctypetablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $doctypetablequery->finish;



#build temporary ownertable 

    my $ownertable = "ownertable";
    
    my $createownerquery = $dbhandle->prepare(qq/create temporary table $ownertable (documentid int(11),
										  owner varchar (50),
										  primary key (documentid))/);
    unless ($createownerquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createownerquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createownerquery->finish;


    my $ownertablequery = $dbhandle->prepare(qq/insert into $ownertable 
					       (documentid, owner)
					       select d.documentid,
					       o.name
					       from document doc
					       left join owner o on (doc.ownerid = o.ownerid)
					       inner join $tempdocidtable d on (d.documentid = doc.documentid)/);
    unless ($ownertablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($ownertablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $ownertablequery->finish;


#build temporary institutiontable 

    my $institutiontable = "institutiontable";
    
    my $createinstitutionquery = $dbhandle->prepare(qq/create temporary table $institutiontable (documentid int(11),
										  institution varchar (255),
										  primary key (documentid))/);
    unless ($createinstitutionquery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($createinstitutionquery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    $createinstitutionquery->finish;


    my $institutiontablequery = $dbhandle->prepare(qq/insert into $institutiontable 
					       (documentid, institution)
					       select d.documentid,
					       i.institution
					       from document doc
					       left join institution i on (doc.institutionid = i.institutionid)
					       inner join $tempdocidtable d on (d.documentid = doc.documentid)/);
    unless ($institutiontablequery) {die "$DBI::err: $DBI::errstr.\n";}
    unless ($institutiontablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $institutiontablequery->finish;



#build temporary flatdocumenttable 

    my $flatdocumenttable = "flatdocumenttable";
    my $flatdocumenttablequery;

    unless ($flatdocumenttablequery = $dbhandle->prepare(qq/create temporary table $flatdocumenttable
							 select 
							 dt.doctype,
							 a.authorlist,
							 d.year,
							 d.title,
							 j.journaltitle, j.titlesynonym1,
							 b.booktitle,
							 eb.edits_booklist,
							 s.seriestitle,
							 es.edits_serieslist,
							 d.documentid,
							 d.refmanid,
							 d.volume,
							 d.issue,
							 d.startpage,
							 d.endpage,
							 d.notizen,
							 d.isbn,
							 d.abstract,
							 d.contactaddress,
							 d.available,
							 d.pdffile,
							 k.keywordlist,
							 sp.specieslist,
							 v.verlagname, v.verlagort,
							 i.institution,
							 o.owner
							 

							 from $tempdocidtable td 
							 inner join $doctable d on (td.documentid = d.documentid)
							 left join $authortable a on (td.documentid = a.documentid)
							 left join $keywordtable k on (td.documentid = k.documentid)
							 left join $speciestable sp on (td.documentid = sp.documentid)
							 left join $edits_booktable eb on (td.documentid = eb.documentid)
							 left join $edits_seriestable es on (td.documentid = es.documentid)
							 left join $journaltable j on (td.documentid = j.documentid)
							 left join $booktable b on (td.documentid = b.documentid)
							 left join $seriestable s on (td.documentid = s.documentid)
							 left join $verlagtable v on (td.documentid = v.documentid)
							 left join $doctypetable dt on (td.documentid = dt.documentid)
							 left join $ownertable o on (td.documentid = o.documentid)
							 left join $institutiontable i on (td.documentid = i.documentid)/))
 {
	die "flatdocumenttablequery error $DBI::err: $DBI::errstr.\n";
    }

    unless ($flatdocumenttablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }

    $flatdocumenttablequery->finish;

#    print "flattable cmplete\n";

    return $flatdocumenttable; 
}


sub flattablearray {

    my $dbhandle = shift;
    my $flatdocumenttable = shift;
    my $sorting;

    unless ($sorting) {
	$sorting = "authorlist";
    }

    my @doctablearray;

    my $doctablequery;
    unless ($doctablequery = $dbhandle->prepare(qq/select * from $flatdocumenttable order by $sorting/)) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    
    unless ($doctablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }


    my @docarray = ( "doctype", "authorlist", "year", "title", "journaltitle", "titlesynonym1", "booktitle", "bookeditorlist", "seriestitle", "serieseditorlist", "documentid", "refmanid", "volume", "issue", "startpage", "endpage", "notes", "isbn", "abstract", "contactaddress", "available", "pdffile", "keywordlist", "specieslist", "publisher", "place", "institution", "owner"); 
							 

    push (@doctablearray, \@docarray);


    while ((@docarray) = $doctablequery->fetchrow_array) {
	push (@doctablearray, \@docarray);
    }



    $doctablequery->finish;

    my $doctablearrayref = \@doctablearray;
    return $doctablearrayref; 

}


sub flattablehash {

    my $dbhandle = shift;
    my $flatdocumenttable = shift;
    my $sorting;

    unless ($sorting) {
	$sorting = "authorlist";
    }

    my %doctablehash;

    my $doctablequery;
    unless ($doctablequery = $dbhandle->prepare(qq/select * from $flatdocumenttable order by $sorting/)) {
	die "$DBI::err: $DBI::errstr.\n";
    }
    
    unless ($doctablequery->execute()) {
	die "$DBI::err: $DBI::errstr.\n";
    }


    my $counter = 1;
    my @docarray;


    while ((@docarray) = $doctablequery->fetchrow_array) {

	#my $docid = $docarray[10];

	$doctablehash{$counter}{doctype} = $docarray[0];

	my @authorarray = split("; ", $docarray[1]); 
	$doctablehash{$counter}{author} = \@authorarray;

	$doctablehash{$counter}{year} = $docarray[2];
	$doctablehash{$counter}{title} = $docarray[3];
	$doctablehash{$counter}{journal} = $docarray[4];
	$doctablehash{$counter}{journalsynonym1} = $docarray[5];
	$doctablehash{$counter}{book} = $docarray[6];

	my @bookeditorarray = split("; ", $docarray[7]); 
	$doctablehash{$counter}{bookeditor} = \@bookeditorarray;

	$doctablehash{$counter}{series} = $docarray[8];

	my @serieseditorarray = split("; ", $docarray[9]); 
	$doctablehash{$counter}{serieseditor} = \@serieseditorarray;

	$doctablehash{$counter}{docid} = $docarray[10];
	$doctablehash{$counter}{refmanid} = $docarray[11];
	$doctablehash{$counter}{volume} = $docarray[12];
	$doctablehash{$counter}{issue} = $docarray[13];
	$doctablehash{$counter}{startpage} = $docarray[14];
	$doctablehash{$counter}{endpage} = $docarray[15];
	$doctablehash{$counter}{notizen} = $docarray[16];
	$doctablehash{$counter}{isbn} = $docarray[17];
	$doctablehash{$counter}{abstract} = $docarray[18];
	$doctablehash{$counter}{contactaddress} = $docarray[19];
	$doctablehash{$counter}{available} = $docarray[20];
	$doctablehash{$counter}{pdffile} = $docarray[21];


	my @keywordarray = split("; ", $docarray[22]); 
	$doctablehash{$counter}{keyword} = \@keywordarray;

	my @speciesarray = split("; ", $docarray[23]); 
	$doctablehash{$counter}{species} = \@speciesarray;


	$doctablehash{$counter}{verlag} = $docarray[24];
	$doctablehash{$counter}{verlagort} = $docarray[25];
	$doctablehash{$counter}{institution} = $docarray[26];
	$doctablehash{$counter}{owner} = $docarray[27];

	$counter++;
    }


    $doctablequery->finish;

    my $doctablehashref = \%doctablehash;
    return $doctablehashref; 


}




return 1;











=command  
sub search {

    my $dbhandle = shift;
    my $docidsref = shift;
    my @doc_ids = @$docidsref;
    my %ergebnishash;
    
    

#Abfragen mit prepare Vorbereiten

    my $documentquery = $dbhandle->prepare("select d.documentid, d.refmanid, d.title, d.year, d.issue, d.volume, d.startpage, d.endpage, d.notizen, d.isbn, d.abstract, d.contactaddress, d.available
                                       from document d
                                       where (d.documentid = ?)");
    
    my $authorquery = $dbhandle->prepare("select a.name
                                       from author a
                                       inner join aut_writes_doc awd on (a.authorid = awd.authorid)
                                       inner join document d on (d.documentid = awd.documentid)
                                       where (d.documentid = ?)
                                       order by awd.author_rank");

    
    my $keywordquery = $dbhandle->prepare("select k.word
                                       from keyword k
                                       inner join kword_in_doc kid on (k.keywordid = kid.keywordid)
                                       inner join document d on (d.documentid = kid.documentid)
                                       where (d.documentid = ?)");


    
    my $journalquery = $dbhandle->prepare("select j.journaltitle, j.titlesynonym1
                                       from document d
                                       left join journal j on (d.journalid = j.journalid)
                                       where (d.documentid = ?)");
    
    
    
    my $bookquery = $dbhandle->prepare("select b.booktitle
                                       from document d
                                       left join book b on (d.bookid = b.bookid)
                                       where (d.documentid = ?)");
    
    
    my $edits_bookquery = $dbhandle->prepare("select a.name
                                       from author a
                                       inner join edits_book eb on (eb.authorid = a.authorid)
                                       inner join book b on (b.bookid = eb.bookid)
                                       inner join document d on (d.bookid = b.bookid)
                                       where (d.documentid = ?) order by eb.editor_rank");
    
    
    
    my $seriesquery = $dbhandle->prepare("select s. seriestitle
                                       from document d
                                       left join series s on (d.seriesid = s.seriesid)
                                       where (d.documentid = ?)");
    
    
    my $edits_seriesquery = $dbhandle->prepare("select a.name
                                       from author a
                                       inner join edits_series es on (es.authorid = a.authorid)
                                       inner join series s on (s.seriesid = es.seriesid)
                                       inner join document d on (d.seriesid = s.seriesid)
                                       where (d.documentid = ?) order by es.serieseditor_rank"); 

    
    
    my $verlagquery = $dbhandle->prepare("select v.verlagname, v.verlagort
                                       from document d
                                       left join verlag v on (d.verlagid = v.verlagid)
                                       where (d.documentid = ?)");

    
    my $doctypequery = $dbhandle->prepare("select dt.doctype
                                       from document d
                                       left join doctype dt on (d.doctypeid = dt.doctypeid)
                                       where (d.documentid = ?)");


    my $ownerquery = $dbhandle->prepare("select o.name
                                       from document d
                                       left join owner o on (d.ownerid = o.ownerid)
                                       where (d.documentid = ?)");


    my $institutionquery = $dbhandle->prepare("select i.institution
                                       from document d
                                       left join institution i on (d.institutionid = i.institutionid)
                                       where (d.documentid = ?)");
    

    
    my $speciesquery = $dbhandle->prepare("select sp.speciesname
                                       from species sp
                                       inner join species_in_doc spid on (sp.speciesid = spid.speciesid)
                                       inner join document d on (d.documentid = spid.documentid)
                                       where (d.documentid = ?)");
    
    
    

# Abfragen für jedes Element ausführen 
    
    my $element;
    my $zwischen;
    my $zwischen2;
    my @zwischen;
    
    foreach $element (@doc_ids) {
# print "BLLLARRRG $element\n";
# print $datenbankname;
	
	$documentquery->execute ($element);
	if ((@zwischen) = $documentquery->fetchrow_array) {
	    $ergebnishash{$element}{dockey} = shift (@zwischen);
	    $ergebnishash{$element}{refmanid} = shift (@zwischen);
	    $ergebnishash{$element}{title} = shift (@zwischen);
	    $ergebnishash{$element}{year} = shift (@zwischen);
	    $ergebnishash{$element}{issue} = shift (@zwischen);
	    $ergebnishash{$element}{volume} = shift (@zwischen);
	    $ergebnishash{$element}{startpage} = shift (@zwischen);
	    $ergebnishash{$element}{endpage} = shift (@zwischen);
	    $ergebnishash{$element}{notizen} = shift (@zwischen);
	    $ergebnishash{$element}{isbn} = shift (@zwischen);
	    $ergebnishash{$element}{abstract} = shift (@zwischen);
	    $ergebnishash{$element}{contactaddress} = shift (@zwischen);
	    $ergebnishash{$element}{available} = shift (@zwischen);
	}
# geht hier mit shift weil Felder ohne Inhalt wohl auf undef oder NULL gesetzt werden, aber vorhanden sind

	
	my @authorlist;
	$authorquery->execute($element);
	while (($zwischen) = $authorquery->fetchrow_array) {
	    push (@authorlist, $zwischen);
	}
	if (@authorlist) {
	    $ergebnishash{$element}{author} = \@authorlist;
	}

	my @keywordlist;
	$keywordquery->execute($element);
	while (($zwischen) = $keywordquery->fetchrow_array) {
	    push (@keywordlist, $zwischen);
#    print "\nBLAARRRRRG$ergebnishash{$element}{keyword}\n";
#    foreach $element (@{$ergebnishash{$element}{keyword}}) {
#      print "$element\n";
#     }
	}
	if (@keywordlist) {
	    $ergebnishash{$element}{keyword} = \@keywordlist;
	}

	
	$journalquery->execute($element);
	if (($zwischen, $zwischen2) = $journalquery->fetchrow_array) {
	    $ergebnishash{$element}{journal} = $zwischen; #journaltitle und journalsynonym
	    $ergebnishash{$element}{journalsynonym1} = $zwischen2;
	}
	
	$bookquery->execute ($element);
	if (($zwischen) = $bookquery->fetchrow_array) {
	    $ergebnishash{$element}{book} = $zwischen;
	}
	
	my @bookeditorlist;
	$edits_bookquery->execute ($element);
	while (($zwischen) = $edits_bookquery->fetchrow_array) {
#	    print "\nBLAAAARG${zwischen}bookeditorBLAAAARG\n";
	    push (@bookeditorlist, $zwischen);
	}
	if (@bookeditorlist) {
	    $ergebnishash{$element}{bookeditor} = \@bookeditorlist;
	}


	$seriesquery->execute ($element);
	if (($zwischen) = $seriesquery->fetchrow_array) {
	    $ergebnishash{$element}{series} = $zwischen;
	}
	
	my @serieseditorlist;
	$edits_seriesquery->execute ($element);
	while (($zwischen) = $edits_seriesquery->fetchrow_array) {
	    push (@serieseditorlist, $zwischen);
	}
	if (@serieseditorlist) {
	    $ergebnishash{$element}{serieseditor} = \@serieseditorlist;
	}


	$verlagquery->execute ($element);
	if (($zwischen, $zwischen2) = $verlagquery->fetchrow_array) {
	    $ergebnishash{$element}{verlag} = $zwischen; #verlag und verlagort
	    $ergebnishash{$element}{verlagort} = $zwischen2;
	}

	
	$doctypequery->execute ($element);
	if (($zwischen) = $doctypequery->fetchrow_array) {
	    $ergebnishash{$element}{doctype} = $zwischen;
	}
# print "<h1>Doctype\:$ergebnishash{$element}{doctype}</h1>"; 
	
	$ownerquery->execute ($element);
	if (($zwischen) = $ownerquery->fetchrow_array) {
	    $ergebnishash{$element}{owner} = $zwischen;
	}
# print "<h1>owner\:$ergebnishash{$element}{owner}</h1>"; 
	
	$institutionquery->execute ($element);
	if (($zwischen) = $institutionquery->fetchrow_array) {
	    $ergebnishash{$element}{institution} = $zwischen;
	}

# print "<h1>institution\:$ergebnishash{$element}{institution}</h1>"; 

	my @specieslist;
	$speciesquery->execute ($element);
	while (($zwischen) = $speciesquery->fetchrow_array) {
#	    print "\nBLAAAARG${zwischen}speciesBLAAAARG\n";
	    push (@specieslist, $zwischen);
	}
	if (@specieslist) {
	    $ergebnishash{$element}{species} = \@specieslist;
	}

#  print "<p>doc_id: $element</p>\n";


    }
    
    
    $documentquery->finish;
    $authorquery->finish;
    $keywordquery->finish;
    $journalquery->finish;
    $bookquery->finish;
    $edits_bookquery->finish;
    $seriesquery->finish;
    $edits_seriesquery->finish;
    $verlagquery->finish;
    $doctypequery->finish;
    $ownerquery->finish;
    $institutionquery->finish;
    $speciesquery->finish;
    
#    $dbhandle->disconnect; #sollte nicht vom Modul geschlossen werden, damit dasaufrufende Skript Verbindung zur Datenbank behält

    my $ergebnishashref = \%ergebnishash;   
    return $ergebnishashref;
}

return 1;

=cut








#select a.name from author a inner join aut_writes_doc awd on (a.authorid = awd.authorid) inner join document d on (d.documentid = awd.documentid) where (d.documentid = ?) order by awd.author_rank


=command
create temporary table $authortable (documentid int(11),authorlist text,primary key (documentid))

insert into $authortable (documentid, authorlist) select d.documentid, group_concat(a.name order by awd.author_rank separator '; ') from author a inner join aut_writes_doc awd on (a.authorid = awd.authorid) inner join $tempdocidtable d on (d.documentid = awd.documentid) group by d.documntid

select d.documentid, group_concat(a.name order by eb.editor_rank separator '; ') from author a inner join edits_book eb on (eb.authorid = a.authorid) inner join book b on (b.bookid = eb.bookid) inner join document doc on (doc.bookid = b.bookid) inner join tempdocidtable d on (d.documentid = doc.documentid) group by d.documentid;

select d.documentid, j.journaltitle, j.titlesynonym1 from document doc left join journal j on (doc.journalid = j.journalid) inner join $tempdocidtable d on (d.documentid = doc.documentid)



=cut


=command

    my $flatdocumenttable = "flatdocumenttable";


    my $flattablequery;

    unless ($flattablequery = $dbhandle->prepare(qq/create temporary table $flatdocumentable
						 (documentid int(11),
						  refmanid varchar(50),
						  title text,
						  year varchar(4),
						  volume varchar (20),
						  issue varchar(20),
						  startpage int(11),
						  endpage int(11),
						  notizen text,
						  isbn varchar(20),
						  abstract mediumtext,
						  contactaddress tinyblob,
						  available varchar (255),

						  authors text,

						  primary key (documentid))/)
	    ) {
	die "create doctablequery prepare error $DBI::err: $DBI::errstr.\n";
    }

    unless ($flattablequery->execute()) {
	die "create flattablequery execute error $DBI::err: $DBI::errstr.\n";
    }



    my $documentquery;
    unless ($documentquery = $dbhandle->prepare(qq/insert into $flatdocumenttable 
						(documentid,
						 refmanid,
						 title,
						 year,
						 volume,
						 issue,
						 startpage,
						 endpage,
						 notizen,
						 isbn,
						 abstract,
						 contactaddress,
						 available
						 )
						select 
						d.documentid,
						d.refmanid,
						d.title,
						d.year,
						d.volume,
						d.issue,
						d.startpage,
						d.endpage,
						d.notizen,
						d.isbn,
						d.abstract,
						d.contactaddress,
						d.available
						from document d inner join $tempdocidtable did (d.documentid = did.documentid)/)) {
	die "$DBI::err: $DBI::errstr.\n";
    };
=cut






