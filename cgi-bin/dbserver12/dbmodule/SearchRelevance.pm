package SearchByRelevance;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use htmlmodule::Html;
use dbmodule::SearchDocId;

#use dbmodule::searching;
use htmlmodule::DbDefs;


sub new {
    my $type = shift; 
    my $class = ref($type) || $type; 

    my $self = {@_};

    bless($self, $class); #das ganze wird zu einem Objekt gemacht

    unless (defined($self->{dbhandle})) {
	die "no database handle defined";
    }

#    unless ((defined($self->{questionid})) or (defined($self->{docidtable}))) {
#	die "no questionid or docidtable";
#    }

    if ((not (defined($self->{databasename}))) || ($self->{database} eq "")) {
	$self->{databasename}= &DbDefs::database();
    }

    unless (defined($self->{httppath})) {
	$self->{httppath}= &DbDefs::httppath();
    }

    unless (defined($self->{pdfdir})) {
	$self->{pdfdir}= &DbDefs::outputpdfdir();
    }


    unless (defined($self->{sorting})) {
	$self->{sorting}= "author";
    }


    unless (defined($self->{checked})) {
	$self->{checked}= 0;
    }


    unless (defined($self->{resultpart})) {
	$self->{resultpart}= 0;
    }

    unless (defined($self->{delete})) {
	$self->{delete}= 0;
    }

    unless (defined($self->{searchquestion})) {
	$self->{searchquestion}= "";
    }

    unless (defined($self->{dataofref})) {
	my @zwarray;
	push (@zwarray, "all");
	$self->{dataofref}= \@zwarray;
    }

    unless (defined($self->{htmlaccessname})) {
	$self->{htmlaccessname}= $ENV{REMOTE_USER};
    }


    return $self;
}


#neu

sub parsesearchstring {

    my $self = shift;
    my %parameter = @_;

    if ($parameter{searchquestion}) {
	$self->{searchquestion} = $parameter{searchquestion};
    }
  
    if ($parameter{dbhandle}) {
	$self->{dbhandle} = $parameter{dbhandle};
    }

    if ($parameter{dataofref}) {
	$self->{dataofref} = $parameter{dataofref};
    }

    if ($parameter{htmlaccessname}) {
	$self->{htmlaccessname} = $parameter{htmlaccessname};
    }


    unless ($self->{dataofref}) {
	die "<h4>dataofref not defined<\/4>\n";
    }


    my @dataof = @{$self->{dataofref}};
    my $questiontime = time();
    my $processid = $$; #pid ermitteln
    my $questionid = "$self->{htmlaccessname}"."$questiontime"."pid$processid";

    my @searcharray = split(/;;;/, $self->{searchquestion});
    my $dataofstring = join (";;;", @dataof);

    my $self->{searcharrayref} = \@searcharray;
    my $self->{dataofstring} = $dataofstring;;
}


#end neu

#neu

sub search {
    my $self = shift;
    my %parameter = @_;

    if ($parameter{searcharrayref}) {
	$self->{searcharrayref} = $parameter{searcharrayref};
    }

    if ($parameter{dataofstring}) {
	$self->{dataofstring} = $parameter{dataofstring};
    }


    my $counter = 0;
    my $oldtemptable = "temp".$counter;
#    print "$oldtemptable \n";

    my @temptablearray;

    my @searcharray = @$self->{searcharrayref};

    my $fieldname = shift (@searcharray);
    my $searchstring = shift (@searcharray);

#    print "<p>$searchstring</p>";


# table to store results from first question in simple table with documentids only, no column for relevance  
    &createtemptable ($self->{dbhandle}, $oldtemptable) or die "\ncan not build tmp-tabelle\n";

    &replace ($self->{dbhandle}, $oldtemptable, $fieldname, $searchstring) or die "\ncan not replace\n";

# create tables for results of single questions
    push (@temptablearray, $oldtemptable);
    $counter++;
    $oldtemptable = "temp".$counter;
#    print "$oldtemptable \n";

    my $connection;

    while ($connection = shift (@searcharray)) {

#	print "connection $connection ";

	my $fieldname = shift (@searcharray);
	my $searchstring = shift (@searcharray);


	&createtmptable ($self->{dbhandle}, $oldtemptable) or die "\ncan not build tmp-tabelle\n";
	&replace ($self->{dbhandle}, $oldtemptable, $fieldname, $searchstring) or die "\ncan not replace\n";

	push (@temptablearray, $connection, $oldtemptable);
	$counter++;
	$oldtemptable = "temp".$counter;
#	print "$oldtemptable \n";
    }


# table to store all docids and there relevance
    my $relevancetable = "docids_relevance";
    &createrelevancetable ($self->{dbhandle}, $relevancetable) or die "\ncan not build tmp-tabelle\n";



=command
relevancetable

update relevancetable r, temptable t set relevance = 1 where r.documentid = t.documentid   

if and: 
update relevancetable r, temptable t set r.relevance=r.relevance+1 where (r.documenid = t.documentid)   
update relevancetable r, temptable t set r.relevance=0 where (r.documenid not t.documentid)

if or: 
update relevancetable r, temptable t set r.relevance=r.relevance+1 where (r.documenid = t.documentid)

=cut


    my $table1 = shift @temptablearray;
    &relortable ($self->{dbhandle}, $relevancetable, $table1);


    print "<p>@temptablearray</p>";


    while ($connection = shift @temptablearray) {
	my $table1 = shift @temptablearray;
 
	if ($connection eq "AND") {
	    &relandtable ($self->{dbhandle}, $relevancetable, $table1);
	}

	if ($connection eq "OR") {
	    &relortable ($self->{dbhandle}, $relevancetable, $table1);
	}



    }



    my $owner;
    my $ownerquestionstring;
    my $allflagg = 0;

    my $ownertemptable = "ownertemptable";



    if (not defined (@dataof)) {
	$allflagg = 1;
	push (@dataof, "all");
	$dataofstring = join (";;;", @dataof);
    }
    else {
	foreach $owner (@dataof) {
	    if ($owner eq "all") {
		$allflagg = 1;
	    }
	}
    }






    unless ($allflagg == 1) {

	$ownerquestionstring = join ("\" OR o.name = \"", @dataof);
	$ownerquestionstring = "o.name = \"".$ownerquestionstring."\"";
	
	&SearchDocId::createtmptable ($self->{dbhandle}, $ownertemptable) or die "\ncan not build tmp-tabelle\n";
	&replace ($self->{dbhandle}, $ownertemptable, "owner", $ownerquestionstring) or die "\ncan not replace\n";

	&relandtable ($self->{dbhandle}, $relevancetable, $ownertemptable);

    }








# save questions and resulting docids in a table for later usage. The table saves up to 30 questions per user


# Tabelle für Abfragen verwalten. Die Tabellen question und doc_in_question sollen die letzten 30 Abfragen jedes users speichern, um diese weiter nutzen zu können.

# question enthält die Meta-Daten der Abfrage, wie user, zeit, etc, doc_in_question verknüpft die in der Abfrage erhaltenen documentids mit der questionid in question.

# check if there are more than 29 questions, if true remove the oldest question 
# prüfen ob mehr als 30 Einträge für den user in question

    my $questioncheck = $self->{dbhandle}->prepare (qq/select if (count(questionid) > 29, "true", "false"), min(qtime) from question where (quser = ?)/);
#&Html::dbquerytest("history1");
    $questioncheck->execute($self->{htmlaccessname});
    my $deleteboolean;
    my $deletetime;
    if  (($deleteboolean, $deletetime) = $questioncheck->fetchrow_array) {
	if ($deleteboolean eq "true") {
	    my $questionidquery = $self->{dbhandle}->prepare(qq/select questionid from question where ((quser = ?) and (qtime = ?))/);
#&Html::dbquerytest("history2");
	    $questionidquery->execute($self->{htmlaccessname}, $deletetime);

	    my $deleteqid;
	    if (($deleteqid) = $questionidquery->fetchrow_array) {

		my $questiondelete = $self->{dbhandle}->prepare(qq/delete from question where (questionid = ?)/); 
#&Html::dbquerytest("history3");
		$questiondelete->execute($deleteqid);	    
		$questiondelete->finish;

	    }
	    $questionidquery->finish;
	}
    }
    $questioncheck->finish;


 


    my $qtableinsert;
    unless ($qtableinsert = $self->{dbhandle}->prepare (qq/insert into question (questionid, quser, qtime, qtext, pid, dataof) values (?,?,?,?,?,?)/)) {die "prepare";} 
#&Html::dbquerytest("history5");
    unless ($qtableinsert->execute($questionid, $self->{htmlaccessname}, $questiontime, $self->{searchquestion}, $processid, $dataofstring)) {die "history table insert error $DBI::err: $DBI::errstr.\n";}
    $qtableinsert->finish;


    

    $self->{questionid} = $questionid;
    $self->{relevancetable} = $relevancetable;

    my $docidtable; #table without relevance-values, containing only docids with values > 0
    &SearchDocId::createtmptable ($self->{dbhandle}, $docidtable) or die "\ncan not build tmp-tabelle\n";
    &docidtablewithoutrelevance ($self->{dbhandle}, $relevancetable, $docidtable);

    $self->{docidtable} = $relevancetable;

    return $self;

}


#end neu


#neu
sub createrelevancetable {

#table with all docids to insert relevance values

    my $dbhandle = shift;
    my $tablename = shift;

    my $query;
    my $querytext = "create temporary table $tablename (documentid INT(11) NOT NULL, relevance INT(5) DEFAULT 0, PRIMARY KEY (documentid))";
    $query = $dbhandle->prepare($querytext);

###########
#&Html::dbquerytest($querytext);

    my $erfolg = $query->execute;
    $query->finish;


############
#    if ($erfolg) {
#	return $tablename;
#    }

    unless ($erfolg) {
	print "SearchDocId:createreltable: error create temporary table";
    }

my $insertdocidstext = "replace $tablename select documentid, 0 from document";
    $insertdocidsquery = $dbhandle->prepare($insertdocidstext);

    unless ($insertdocidsquery->execute) {
	print "createdocidtable: error insert (replace) docids\n";
    }
    $insertdocidsquery->finish;

    return $tablename;
}

#end neu



#neu? mit relevance-Spalte

sub createtmptable { #temporäre Tabelle muß vorher gebaut werden, damit eindeutiger Schlüssel bei replace-abfragen benutzt werden kann
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

#end neu



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


sub replacequery {
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

#neu
#uebernommen
    if ($suchfeld eq "owner") {
	$querytext = "replace $tablename select d.documentid from document d
                                inner join owner o on (d.ownerid = o.ownerid)
                                where ($searchstring)";
    }
# end neu

#    print "<p>$querytext</p>";
    return $querytext;
}





# neu

sub relandtable {

    my $dbhandle = shift;
    my $relevancetable = shift;
    my $temptablename = shift;


    my $orquery;
    my $orquerytext = &orrelevancequery($relenvancetable, $temptablename);

    unless ($orquery = $dbhandle->prepare($orquerytext)) {die "5 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($orquerytext);
    unless ($erfolg = $orquery->execute) {die "6 error $DBI::err: $DBI::errstr.\n"};
    $orquery->finish;


    my $notquery;
    my $notquerytext = &notrelevancequery($relenvancetable, $temptablename);

    unless ($notquery = $dbhandle->prepare($notquerytext)) {die "5 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($notquerytext);
    unless ($erfolg = $notquery->execute) {die "6 error $DBI::err: $DBI::errstr.\n"};
    $notquery->finish;
    
    return $relevancetable;

}



sub relortable {

    my $dbhandle = shift;
    my $relevancetable = shift;
    my $temptablename = shift;


    my $orquery;
    my $orquerytext = &orrelevancequery($relenvancetable, $temptablename);

    unless ($orquery = $dbhandle->prepare($orquerytext)) {die "5 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($orquerytext);
    unless ($erfolg = $orquery->execute) {die "6 error $DBI::err: $DBI::errstr.\n"};
    $orquery->finish;
    
    return $relevancetable;

}


sub docidtablewithoutrelevance {

    my $dbhandle = shift;
    my $relevancetable = shift;
    my $temptablename = shift;


    my $docidquery;
    my $docidquerytext = "replace $temptablename t select r.documentid from $relevancetable r where (relevance >0)";

    unless ($docidquery = $dbhandle->prepare($docidquerytext)) {die "5 error $DBI::err: $DBI::errstr.\n"};
    my $erfolg;
#&Html::dbquerytest($docidquerytext);
    unless ($erfolg = $docidquery->execute) {die "6 error $DBI::err: $DBI::errstr.\n"};
    $docidquery->finish;
  
    return $temptablename;

}




sub notrelevancequery{
    my $relevancetable = shift;
    my $temptablename = shift;

    my $querytext;
    $querytext = "update $relevancetable r, $temptable t set r.relevance=0 where (r.documentid != t.documentid)";
    return $querytext; 

}

sub orrelevancequery{
    my $relevancetable = shift;
    my $temptablename = shift;

    my $querytext;
    $querytext = "update $relevancetable r, $temptable t set r.relevance=r.relevance+1 where (r.documentid = t.documentid)";
    return $querytext; 
}

 
