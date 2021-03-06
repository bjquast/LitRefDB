package SearchDocId.zwischen;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use htmlmodule::Html;




sub createreltable { #tempor�re Tabelle mu� vorher gebaut werden, damit eindeutiger Schl�ssel bei replace-abfragen benutzt werden kann
    my $dbhandle = shift;
    my $tablename = shift;

    my $query;
    my $querytext = "create temporary table $tablename (documentid INT(11) NOT NULL, relevance INT(5) DEFAULT 0, PRIMARY KEY (documentid))";
    $query = $dbhandle->prepare($querytext);
#&Html::dbquerytest($querytext);
    my $erfolg = $query->execute;
    $query->finish;
    if ($erfolg) {
	return $tablename;
    }
    else {
	print "SearchDocId:createreltable: error create temporary table";
    }

# insert all docids into table, starting with relevance 0


    my $insertquerytext = "insert $tablename select d.documentid, 0 from document d";
    my $insertquery = $dbhandle->prepare($insertquerytext);
    $erfolg = $insertquery->execute;

    if ($erfolg) {
	return $tablename;
    }
    else {
	print "SearchDocId:createreltable: error insert docids in temporary table";
    }
}



##############

sub relevance {
    my $dbhandle = shift;
    my $tablename = shift;
    my $suchfeld = shift;
    my $searchstring = shift;

    if ($suchfeld eq "author / editor") {
	&relevance ($dbhandle, $tablename, "author", $searchstring) or die "\ncan not replace\n";
	&relevance ($dbhandle, $tablename, "bookeditor", $searchstring) or die "\ncan not replace\n";
	&relevance ($dbhandle, $tablename, "serieseditor", $searchstring) or die "\ncan not replace\n";
	return $tablename;
    }


    elsif ($suchfeld eq "editor") {
	&relevance ($dbhandle, $tablename, "bookeditor", $searchstring) or die "\ncan not replace\n";
	&relevance ($dbhandle, $tablename, "serieseditor", $searchstring) or die "\ncan not replace\n";
	return $tablename;
    }


    elsif ($suchfeld eq "title") {
	&relevance ($dbhandle, $tablename, "documenttitle", $searchstring) or die "\ncan not replace\n";
	&relevance ($dbhandle, $tablename, "journaltitle", $searchstring) or die "\ncan not replace\n";
	&relevance ($dbhandle, $tablename, "booktitle", $searchstring) or die "\ncan not replace\n";
	&relevance ($dbhandle, $tablename, "seriestitle", $searchstring) or die "\ncan not replace\n";
	return $tablename;
    }



    else {

	my $localtemptable = "localtemptable";

	my $createtmptext = "create temporary table $localtemptable (documentid INT(11) NOT NULL, relevance INT(5) DEFAULT 0, PRIMARY KEY (documentid))";
	my $createtmpquery = $dbhandle->prepare($createtmptext);
#&Html::dbquerytest($querytext);
	my $erfolg = $createtmpquery->execute;
	$createtmpquery->finish;
	unless ($erfolg) {
	    print "SearchDocId:relevance: error create temporary table";
	}



	my $query;
	my $querytext = &relevancequery($localtemptable, $suchfeld, $searchstring);
	
#	print "<p>$querytext</p>";
	
#	print "<p>frage $tablename, $suchfeld, $searchstring</p>";

	unless ($query = $dbhandle->prepare($querytext)) {die "1 error $DBI::err: $DBI::errstr.\n"};
	my $erfolg;
#&Html::dbquerytest($querytext);
	unless ($erfolg = $query->execute) {die "2 error $DBI::err: $DBI::errstr.\n"};
	$query->finish;



	my $updatequerytext = "update $tablename t1, $localtemptable t2 set t1.relevance = t1.relevance+1 where (t1.documentid = t2.documentid)";

	my $updatequery = $dbhandle->prepare($updatequerytext); 
	my $erfolg = $updatequery->execute;
	$updatequery->finish;

	if ($erfolg) {
	    return $tablename;
	}
	else {
	    print "SearchDocId:relevance: error update temporary table\n";
	}

    }
}    




sub relevancequery{ #das kann eigentlich die original-replacequery-routine bleiben?
    my $localtemptable = shift;
    my $suchfeld = shift;
    my $searchstring = shift;
    my $querytext;

#create temporary table bquast3 select bquast.documentid from bquast inner join bquast2 on (bquast.documentid = bquast2.documentid);


    if ($suchfeld eq "author") {
	$querytext = "replace $localtemptable select distinct d.documentid from aut_writes_doc awd
                        left join document d on (d.documentid = awd.documentid)
                        inner join author a on (a.authorid = awd.authorid) where (a.name $searchstring)";
    }

    if ($suchfeld eq "bookeditor") {
	$querytext = "replace $localtemptable select distinct d.documentid from author a
                        inner join edits_book eb on (a.authorid = eb.authorid)
                        inner join book b on (eb.bookid = b.bookid)
                        inner join document d on (b.bookid = d.bookid) where (a.name $searchstring)";
    }

    if ($suchfeld eq "serieseditor") {
	$querytext = "replace $localtemptable select distinct d.documentid from author a
                        inner join edits_series es on (a.authorid = es.authorid)
                        inner join series s on (es.seriesid = s.seriesid)
                        inner join document d on (s.seriesid = d.seriesid) where (a.name $searchstring)";
    }

    if ($suchfeld eq "keyword") {
	$querytext = "replace $localtemptable select distinct d.documentid from kword_in_doc kid
                        left join document d on (d.documentid = kid.documentid)
                        inner join keyword k on (k.keywordid = kid.keywordid) where (k.word $searchstring)";
    }

    if ($suchfeld eq "species") {
	$querytext = "replace $localtemptable select distinct d.documentid from species_in_doc sid
                        left join document d on (d.documentid = sid.documentid)
                        inner join species s on (s.speciesid = sid.speciesid) where (s.speciesname $searchstring)";
    }

    if ($suchfeld eq "year") {
	$querytext = "replace $localtemptable SELECT d.documentid from document d where (d.year $searchstring)";
    }

    if ($suchfeld eq "documenttitle") {
	$querytext = "replace $localtemptable SELECT d.documentid from document d where (d.title $searchstring)";
    }

    if ($suchfeld eq "journaltitle") {
	$querytext = "replace $localtemptable select d.documentid from document d
                        inner join journal j on (d.journalid = j.journalid) where (j.journaltitle $searchstring)";
    }

    if ($suchfeld eq "booktitle") {
	$querytext = "replace $localtemptable select d.documentid from document d
                                inner join book b on (d.bookid = b.bookid) where (b.booktitle $searchstring)";
    }

    if ($suchfeld eq "seriestitle") {
	$querytext = "replace $localtemptable select d.documentid from document d
                                inner join series s on (d.seriesid = s.seriesid) where (s.seriestitle $searchstring)";
    }

    if ($suchfeld eq "abstract") {
	$querytext = "replace $localtemptable SELECT d.documentid from document d where (d.abstract $searchstring)";
    }

#    print "<p>$querytext</p>";
    return $querytext;
}





##############






sub createtmptable { #tempor�re Tabelle mu� vorher gebaut werden, damit eindeutiger Schl�ssel bei replace-abfragen benutzt werden kann
    my $dbhandle = shift;
    my $tablename = shift;

    my $query;
    my $querytext = "create temporary table $tablename (documentid INT(11) NOT NULL, PRIMARY KEY (documentid))";
    $query = $dbhandle->prepare($querytext);
#&Html::dbquerytest($querytext);
    my $erfolg = $query->execute;
    $query->finish;
    if ($erfolg) {
	return $tablename;
    }
    else {
	print " createtable-abfrage gescheitert";
    }
}




sub replace {
    my $dbhandle = shift;
    my $tablename = shift;
    my $suchfeld = shift;
    my $searchstring = shift;

    if ($suchfeld eq "author / editor") {
	&replace ($dbhandle, $tablename, "author", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $tablename, "bookeditor", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $tablename, "serieseditor", $searchstring) or die "\ncan not replace\n";
	return $tablename;
    }


    elsif ($suchfeld eq "editor") {
	&replace ($dbhandle, $tablename, "bookeditor", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $tablename, "serieseditor", $searchstring) or die "\ncan not replace\n";
	return $tablename;
    }


    elsif ($suchfeld eq "title") {
	&replace ($dbhandle, $tablename, "documenttitle", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $tablename, "journaltitle", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $tablename, "booktitle", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $tablename, "seriestitle", $searchstring) or die "\ncan not replace\n";
	return $tablename;
    }



    else {
	my $query;
	my $querytext = &replacequery($tablename, $suchfeld, $searchstring);
	
#	print "<p>$querytext</p>";
	
#	print "<p>frage $tablename, $suchfeld, $searchstring</p>";

	unless ($query = $dbhandle->prepare($querytext)) {die "1 error $DBI::err: $DBI::errstr.\n"};
	my $erfolg;
#&Html::dbquerytest($querytext);
	unless ($erfolg = $query->execute) {die "2 error $DBI::err: $DBI::errstr.\n"};
	$query->finish;
	if ($erfolg) {
	    return $tablename;
	}
	else {
	    print " replace abfrage gescheitert\n";
	}

    }
}    
 


sub selecttonewtable {
    my $dbhandle = shift;
    my $oldtablename = shift;
    my $suchfeld = shift;
    my $searchstring = shift;
    my $newtablename = shift;




    if ($suchfeld eq "author / editor") {
	my $temptablename = $oldtablename."authtemp"; #the name of the table must be different for each call of this routine
	&createtmptable ($dbhandle, $temptablename) or die "\ncan not build tmp-tabelle\n";
	&replace ($dbhandle, $temptablename, "author", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $temptablename, "bookeditor", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $temptablename, "serieseditor", $searchstring) or die "\ncan not replace\n";
	&andtable ($dbhandle, $oldtablename, $temptablename, $newtablename);
	return $newtablename;
    }


    elsif ($suchfeld eq "editor") {
	my $temptablename = $oldtablename."editortemp"; #the name of the table must be different for each call of this routine
	&createtmptable ($dbhandle, $temptablename) or die "\ncan not build tmp-tabelle\n";
	&replace ($dbhandle, $temptablename, "bookeditor", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $temptablename, "serieseditor", $searchstring) or die "\ncan not replace\n";
	&andtable ($dbhandle, $oldtablename, $temptablename, $newtablename);
	return $newtablename;
    }


    elsif ($suchfeld eq "title") {
	my $temptablename = $oldtablename."titletemp"; #the name of the table must be different for each call of this routine
	&createtmptable ($dbhandle, $temptablename) or die "\ncan not build tmp-tabelle\n";
	&replace ($dbhandle, $temptablename, "documenttitle", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $temptablename, "journaltitle", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $temptablename, "booktitle", $searchstring) or die "\ncan not replace\n";
	&replace ($dbhandle, $temptablename, "seriestitle", $searchstring) or die "\ncan not replace\n";
	&andtable ($dbhandle, $oldtablename, $temptablename, $newtablename);
	return $newtablename;
    }


    else {
	my $query;
	my $querytext = &selecttonewquery($oldtablename, $suchfeld, $searchstring, $newtablename);
	
#	print "<p>$querytext</p>";
	
#	print "<p>frage $oldtablename, $suchfeld, $searchstring $newtablename</p>";
	
	unless ($query = $dbhandle->prepare($querytext)) {die "3 error $DBI::err: $DBI::errstr.\n"};
	my $erfolg;
#&Html::dbquerytest($querytext);
	unless ($erfolg = $query->execute) {die "4 error $DBI::err: $DBI::errstr.\n"};
	$query->finish;
	if ($erfolg) {
	    return $newtablename;
	}
	else {
	    print " selecttonew abfrage gescheitert";
	}
    }
}



sub andtable {
    my $dbhandle = shift;
    my $oldtablename = shift;
    my $temptablename = shift;
    my $newtablename = shift;


    my $query;
    my $querytext = &andtablequery($oldtablename, $temptablename, $newtablename);

#    print "<p>$querytext</p>";

#    print "<p>frage $oldtablename, $temptablename, $newtablename</p>";

    unless ($query = $dbhandle->prepare($querytext)) {die "5 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($querytext);
    unless ($erfolg = $query->execute) {die "6 error $DBI::err: $DBI::errstr.\n"};
    $query->finish;
    if ($erfolg) {
	return $newtablename;
    }
    else {
	print " andtablequery failed\n";
    }
}




sub andtablequery{
    my $oldtablename = shift;
    my $temptablename = shift;
    my $newtablename = shift;
    my $querytext;

    $querytext = "insert into $newtablename select o.documentid from $oldtablename o inner join $temptablename t on (o.documentid = t.documentid)";
    return $querytext; 

}





sub ortable {
    my $dbhandle = shift;
    my $oldtablename = shift;
    my $temptablename = shift;


    my $query;
    my $querytext = &ortablequery($oldtablename, $temptablename);

#    print "<p>$querytext</p>";

#    print "<p>frage $oldtablename, $temptablename, $newtablename</p>";

    unless ($query = $dbhandle->prepare($querytext)) {die "5 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($querytext);
    unless ($erfolg = $query->execute) {die "6 error $DBI::err: $DBI::errstr.\n"};
    $query->finish;
    if ($erfolg) {
	return $temptablename;
    }
    else {
	print " ortablequery failed\n";
    }
}


sub ortablequery{
    my $oldtablename = shift;
    my $temptablename = shift;
    my $querytext;

    $querytext = "replace $oldtablename select documentid from $temptablename";
    return $querytext; 

}






sub replacequery{
    my $tablename = shift;
    my $suchfeld = shift;
    my $searchstring = shift;
    my $querytext;

#create temporary table bquast3 select bquast.documentid from bquast inner join bquast2 on (bquast.documentid = bquast2.documentid);



    if ($suchfeld eq "author") {
	$querytext = "replace $tablename select distinct d.documentid from aut_writes_doc awd
                        left join document d on (d.documentid = awd.documentid)
                        inner join author a on (a.authorid = awd.authorid) where (a.name $searchstring)";
    }

    if ($suchfeld eq "bookeditor") {
	$querytext = "replace $tablename select distinct d.documentid from author a
                        inner join edits_book eb on (a.authorid = eb.authorid)
                        inner join book b on (eb.bookid = b.bookid)
                        inner join document d on (b.bookid = d.bookid) where (a.name $searchstring)";
    }

    if ($suchfeld eq "serieseditor") {
	$querytext = "replace $tablename select distinct d.documentid from author a
                        inner join edits_series es on (a.authorid = es.authorid)
                        inner join series s on (es.seriesid = s.seriesid)
                        inner join document d on (s.seriesid = d.seriesid) where (a.name $searchstring)";
    }

    if ($suchfeld eq "keyword") {
	$querytext = "replace $tablename select distinct d.documentid from kword_in_doc kid
                        left join document d on (d.documentid = kid.documentid)
                        inner join keyword k on (k.keywordid = kid.keywordid) where (k.word $searchstring)";
    }

    if ($suchfeld eq "species") {
	$querytext = "replace $tablename select distinct d.documentid from species_in_doc sid
                        left join document d on (d.documentid = sid.documentid)
                        inner join species s on (s.speciesid = sid.speciesid) where (s.speciesname $searchstring)";
    }

    if ($suchfeld eq "year") {
	$querytext = "replace $tablename SELECT d.documentid from document d where (d.year $searchstring)";
    }

    if ($suchfeld eq "documenttitle") {
	$querytext = "replace $tablename SELECT d.documentid from document d where (d.title $searchstring)";
    }

    if ($suchfeld eq "journaltitle") {
	$querytext = "replace $tablename select d.documentid from document d
                        inner join journal j on (d.journalid = j.journalid) where (j.journaltitle $searchstring)";
    }

    if ($suchfeld eq "booktitle") {
	$querytext = "replace $tablename select d.documentid from document d
                                inner join book b on (d.bookid = b.bookid) where (b.booktitle $searchstring)";
    }

    if ($suchfeld eq "seriestitle") {
	$querytext = "replace $tablename select d.documentid from document d
                                inner join series s on (d.seriesid = s.seriesid) where (s.seriestitle $searchstring)";
    }

    if ($suchfeld eq "abstract") {
	$querytext = "replace $tablename SELECT d.documentid from document d where (d.abstract $searchstring)";
    }

#    print "<p>$querytext</p>";
    return $querytext;
}





sub selecttonewquery {
    my $oldtablename = shift;
    my $suchfeld = shift;
    my $searchstring = shift;
    my $newtablename = shift;
    my $querytext;




    if ($suchfeld eq "author") {
	$querytext = "replace $newtablename select distinct d.documentid from aut_writes_doc awd
                        left join document d on (d.documentid = awd.documentid)
                        inner join author a on (a.authorid = awd.authorid)
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (a.name $searchstring)";
    }

    if ($suchfeld eq "bookeditor") {
	$querytext = "replace $newtablename select distinct d.documentid from author a
                        inner join edits_book eb on (a.authorid = eb.authorid)
                        inner join book b on (eb.bookid = b.bookid)
                        inner join document d on (b.bookid = d.bookid)
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (a.name $searchstring)";
    }

    if ($suchfeld eq "serieseditor") {
	$querytext = "replace $newtablename select distinct d.documentid from author a
                        inner join edits_series es on (a.authorid = es.authorid)
                        inner join series s on (es.seriesid = s.seriesid)
                        inner join document d on (s.seriesid = d.seriesid)
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (a.name $searchstring)";
    }

    if ($suchfeld eq "keyword") {
	$querytext = "replace $newtablename select distinct d.documentid from kword_in_doc kid
                        left join document d on (d.documentid = kid.documentid)
                        inner join keyword k on (k.keywordid = kid.keywordid)
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (k.word $searchstring)";
    }

    if ($suchfeld eq "species") {
	$querytext = "replace $newtablename select distinct d.documentid from species_in_doc sid
                        left join document d on (d.documentid = sid.documentid)
                        inner join species s on (s.speciesid = sid.speciesid)
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (s.speciesname $searchstring)";
    }

    if ($suchfeld eq "documenttitle") {
	$querytext = "replace $newtablename SELECT d.documentid from document d
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (d.title $searchstring)";
    }

    if ($suchfeld eq "year") {
	$querytext = "replace $newtablename SELECT d.documentid from document d
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (d.year $searchstring)";
    }

    if ($suchfeld eq "journaltitle") {
	$querytext = "replace $newtablename select d.documentid from document d
                        inner join journal j on (d.journalid = j.journalid)
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (j.journaltitle $searchstring)";
    }

    if ($suchfeld eq "booktitle") {
	$querytext = "replace $newtablename select d.documentid from document d
                        inner join book b on (d.bookid = b.bookid)
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (b.booktitle $searchstring)";
    }

    if ($suchfeld eq "seriestitle") {
	$querytext = "replace $newtablename select d.documentid from document d
                        inner join series s on (d.seriesid = s.seriesid)
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (s.seriestitle $searchstring)";
    }

    if ($suchfeld eq "abstract") {
	$querytext = "replace $newtablename SELECT d.documentid from document d
                        inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                        where (d.abstract $searchstring)";
    }

    if ($suchfeld eq "owner") {
	$querytext = "replace $newtablename select d.documentid from document d
                                inner join owner o on (d.ownerid = o.ownerid)
                                inner join $oldtablename on ($oldtablename.documentid = d.documentid)
                                where ($searchstring)";
    }



    return $querytext;
}




return 1;



=command
replace $tablename select distinct d.documentid from aut_writes_doc awd left join document d on (d.documentid = awd.documentid) inner join author a on (a.authorid = awd.authorid) where (a.name $searchstring)"



replace $newtablename select distinct d.documentid from aut_writes_doc awd left join document d on (d.documentid = awd.documentid) inner join author a on (a.authorid = awd.authorid) inner join $oldtablename on ($oldtablename.documentid = d.documentid) where (a.name $searchstring)
=cut


























