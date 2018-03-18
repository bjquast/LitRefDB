package SearchDocId;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use htmlmodule::Html;




#############new routines for relevance search


sub createrelevancetable {

#table with all docids to insert relevance values

    my $dbhandle = shift;
    my $tablename = shift;

    my $query;
    my $querytext = "create temporary table $tablename (documentid INT(11) NOT NULL, relevance INT(5) DEFAULT 0, PRIMARY KEY (documentid))";
    $query = $dbhandle->prepare($querytext);

###########

#    print "<p></p><p></p><p></p><p></p><p></p><p></p>";
#&Html::dbquerytest($querytext);

    my $erfolg = $query->execute;
    $query->finish;


############
#    if ($erfolg) {
#	return $tablename;
#    }

    unless ($erfolg) {
	print "SearchDocId:createrelevancetable: error create temporary table";
    }

    my $insertdocidstext = "replace $tablename select documentid, 0 from document";
    my $insertdocidsquery = $dbhandle->prepare($insertdocidstext);

#&Html::dbquerytest($insertdocidstext);


    unless ($insertdocidsquery->execute) {
	print "createrelevancetable: error insert docids, set relevance to 0\n";
    }
    $insertdocidsquery->finish;

    return $tablename;
}




sub relandtable {

    my $dbhandle = shift;
    my $relevancetable = shift;
    my $temptablename = shift;


#put results into temporary relevancetable
    my $temprelevancetable = "tempreltable".$temptablename;
    &createrelevancetable ($dbhandle, $temprelevancetable) or die "\ncan not build tmp-tabelle\n";

    my $temporquery;
    my $temporquerytext = &orrelevancequery($temprelevancetable, $temptablename);

    unless ($temporquery = $dbhandle->prepare($temporquerytext)) {die "10 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($temporquerytext);
    unless ($erfolg = $temporquery->execute) {die "11 error $DBI::err: $DBI::errstr.\n"};
    $temporquery->finish;

#set relevance to 0 for results not found in both $temprelevancetable and $relevancetable
# set relevance = relevance+1 for results found in both tables
    my $notquery;
    my $notquerytext = &notrelevancequery($temprelevancetable, $relevancetable);

    unless ($notquery = $dbhandle->prepare($notquerytext)) {die "12 error $DBI::err: $DBI::errstr.\n"};
#    my $erfolg;
#&Html::dbquerytest($notquerytext);
    unless ($erfolg = $notquery->execute) {die "13 error $DBI::err: $DBI::errstr.\n"}; #testet, ob $erfolg etwas anderes als undef zugewiesen wird
    $notquery->finish;

    my $upquery;
    my $upquerytext = "update $relevancetable set relevance=relevance+1 where (relevance > 0)";

    unless ($upquery = $dbhandle->prepare($upquerytext)) {die "12 error $DBI::err: $DBI::errstr.\n"};
#    my $erfolg;
#&Html::dbquerytest($upquerytext);
    unless ($erfolg = $upquery->execute) {die "13 error $DBI::err: $DBI::errstr.\n"};
    $upquery->finish;


# delete $temprelevancetable
    &droptemptable ($dbhandle, $temprelevancetable);
    
    return $relevancetable;

}



sub relortable {

    my $dbhandle = shift;
    my $relevancetable = shift;
    my $temptablename = shift;


    my $orquery;
    my $orquerytext = &orrelevancequery($relevancetable, $temptablename);

    unless ($orquery = $dbhandle->prepare($orquerytext)) {die "14 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($orquerytext);
    unless ($erfolg = $orquery->execute) {die "15 error $DBI::err: $DBI::errstr.\n"};
    $orquery->finish;
    
    return $relevancetable;

}


sub delete0relevance {

    my $dbhandle = shift;
    my $relevancetable = shift;


    my $docidquery;
    my $docidquerytext = "delete from $relevancetable where (relevance <= 0)";

    unless ($docidquery = $dbhandle->prepare($docidquerytext)) {die "16 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($docidquerytext);
    unless ($erfolg = $docidquery->execute) {die "17 error $DBI::err: $DBI::errstr.\n"};
    $docidquery->finish;
  
    return $relevancetable;

}




sub notrelevancequery{
    my $temprelevancetable = shift;
    my $relevancetable = shift;


    my $querytext;
    $querytext = "replace $relevancetable select r.documentid, 0 from $temprelevancetable r where (r.relevance = 0)";
    return $querytext; 

}

sub orrelevancequery{
    my $relevancetable = shift;
    my $temptablename = shift;

    my $querytext;
    $querytext = "update $relevancetable r, $temptablename t set r.relevance=r.relevance+1 where (r.documentid = t.documentid)";
    return $querytext; 
}



sub droptemptable {
    my $dbhandle = shift;
    my $tablename = shift;

    my $dropquery;
    my $dropquerytext = "drop temporary table $tablename";

    unless ($dropquery = $dbhandle->prepare($dropquerytext)) {die "12 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($dropquerytext);
    unless ($erfolg = $dropquery->execute) {die "13 error $DBI::err: $DBI::errstr.\n"};
    $dropquery->finish;

    return $tablename;
}

############# end routines for relevance search





sub createtmptable { #temporäre Tabelle muß vorher gebaut werden, damit eindeutiger Schlüssel bei replace-abfragen benutzt werden kann
    my $dbhandle = shift;
    my $tablename = shift;

    my $query;
    my $querytext = "create temporary table $tablename (documentid INT(11) NOT NULL, PRIMARY KEY (documentid))";
    $query = $dbhandle->prepare($querytext);

#    print "<p>1</p><p>2</p><p>3</p><p>4</p><p>5</p><p>6</p>";
#&Html::dbquerytest($querytext);
    my $erfolg = $query->execute;
    $query->finish;
    if ($erfolg) {
	return $tablename;
    }
    else {
	print " createtable-abfrage gescheitert error $DBI::err: $DBI::errstr.\n";
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

#new question in order to use replace for choosing user data. changed with introduction of relevance search 20130127
    if ($suchfeld eq "owner") {
	$querytext = "replace $tablename select d.documentid from document d
                                inner join owner o on (d.ownerid = o.ownerid)
                                where ($searchstring)";
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


























