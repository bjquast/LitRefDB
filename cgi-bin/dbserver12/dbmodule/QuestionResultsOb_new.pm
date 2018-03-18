package QuestionResultsOb;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use htmlmodule::Html;
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



#    my $dataof = $self->{dataofref};

#	print "<p>$dataof</p>\n";
#	print "<p>$dataof</p>\n";
#	print "<p>$dataof</p>\n";
#	print "<p>$dataof</p>\n";
#	print "<p>$dataof</p>\n";
#	print "<p>$self->{dataofref} dataof</p>\n";
#	print "<p>@{$self->{dataofref}} dataof</p>\n";



    unless (defined($self->{htmlaccessname})) {
	$self->{htmlaccessname}= $ENV{REMOTE_USER};
    }





    return $self;


}




sub resultprint {
    my $self = shift;
    my %parameter = @_;

    if ($parameter{sorting}) {
	$self->{sorting} = $parameter{sorting};
    }
  
    if ($parameter{checked}) {
	$self->{checked} = $parameter{checked};
    }

    if ($parameter{resultpart}) {
	$self->{resultpart} = $parameter{resultpart};
    }

    if ($parameter{delete}) {
	$self->{delete} = $parameter{delete};
    }





# first create table with docids

    unless (defined($self->{docidtable})) {

	my $questionstringquery;

	unless ($questionstringquery = $self->{dbhandle}->prepare (qq/select qtext, quser, dataof from question where questionid = "$self->{questionid}"/)) {die "questionstringquery prepare error $DBI::err: $DBI::errstr.\n";} 
	#&Html::dbquerytest("history_neu1");
	unless ($questionstringquery->execute()) {die "questionstringquery error $DBI::err: $DBI::errstr.\n";}
	
       
	my $quser;
	my $dataof;

	($self->{searchquestion}, $self->{htmlaccessname}, $dataof) = $questionstringquery->fetchrow_array;

	$questionstringquery->finish;


	my @dataofarray = split(/\;/, $dataof);
	$self->{dataofref} = \@dataofarray;


#	unless ($self->{dataofref}) {
#	    die "gnarr1 dataofref not defined";
#	}

	$self -> searching();
    }


    my $tempouttable = "tempouttable";
    my $insertquery;
    unless ($insertquery = $self->{dbhandle}->prepare(qq/create temporary table $tempouttable
					      select distinct d.documentid, d.refmanid, a.name, d.year, d.title, j.journaltitle, d.issue, b.booktitle, d.volume, s.seriestitle, d.startpage, d.endpage, d.pdffile, dit.relevance
					      from document d
					      inner join aut_writes_doc awd on (d.documentid = awd.documentid)
					      inner join author a on ((a.authorid = awd.authorid) and (awd.author_rank = 1))
					      left join journal j on (d.journalid = j.journalid)
					      left join book b on (d.bookid = b.bookid)
					      left join series s on (d.seriesid = s.seriesid)
					      inner join $self->{docidtable} dit on (d.documentid = dit.documentid)/)) {
	die "tempouttable insertquery prepare error $DBI::err: $DBI::errstr.\n";
    }



    my $resultnum;


    unless ($resultnum = $insertquery->execute()) {
	die "tempouttable insertquery execute error $DBI::err: $DBI::errstr.\n";
    }
#&Html::dbquerytest("last end");
    $resultnum+=0;


    $insertquery->finish;


    my $offset = 0;
    my $limit = 1000;


    if ($resultnum >= $limit) {
	$offset = ($self->{resultpart} * $limit);
    }

    if ($offset >= $resultnum) {
	$offset = 0;
    } 



    my @resultarray;
    my @doc_ids;


    my $checkedtext = "";
    if ($self->{checked} == 1) {
	$checkedtext = " checked=\"checked\"";
    }


    $self->{sorting} =~ s/author/name/;
# print $self->{sorting};


    if ($self->{sorting} eq "name") {
	$self->{showsort} = "name, year, title";
    }

    elsif ($self->{sorting} eq "year") {
	$self->{showsort} = "year, name, title";
    }

    elsif ($self->{sorting} eq "title") {
	$self->{showsort} = "title, relevance, year, name";
    }

    elsif ($self->{sorting} eq "relevance") {
	$self->{showsort} = "relevance, name, year";
    }



    my $outputquery = $self->{dbhandle}->prepare("select * from $tempouttable order by $self->{showsort} limit $offset, $limit");
#&Html::dbquerytest("select * from $tempouttable order by $self->{sorting} limit $offset, $limit");
    $outputquery->execute();
#    &Html::dbquerytest("last end");

    print "<form action=\"$self->{httppath}central.pl\" method=\"POST\">";

#   print "<hr>\n";

    print "<div id\=\"resulthead\">\n";

    print "\n";
    print "<table cellspacing=\"0\" cellpadding=\"3\" border = \"0\"\n";
    print "<tr valign = \"top\">\n";

    unless ($self->{delete}) {
	print "<td>\n";
	&Html::resultmenu();
	print "</td>\n";
	print "<td>\n"; 
	print '<input type="submit" value="submit">';
	print "</td>\n";
    }
    else {
	print "<td>\n";
	print "<b style=\"font-size:medium\">confirm to delete the checked datasets</b>\n";
	print "</td>\n";
	print "<td>\n"; 
	print '<input type="submit" value="delete datasets">';
	print "</td>\n";
	print "<input type = \"hidden\" name = \"action\" value = \"delete_now\">";
    }

    print "</tr>\n";
#    print "</table>\n";

#    print "<table cellspacing=\"0\" cellpadding=\"3\" border = \"0\"\n";
    print "<tr>\n";
    print "<td>\n"; 
    print "<b>number of matches: $resultnum</b>";
    print "</td>\n"; 


    print "<td>\n"; 
    if ($resultnum >= $limit) {
	my $counter = 0;
	my $max =  int($resultnum / $limit);
	while ($counter <= $max) {
	    print "<a href=\"$self->{httppath}results.pl?database=$self->{databasename}\&questionid=$self->{questionid}\&resultpart=$counter\&checked=$self->{checked}\&sorting=$self->{sorting}\">$counter</a>\&nbsp\;";
	    $counter++;
	}
    }
    print "</td>\n";
    print "</tr>\n";
    print "</table>\n";

    print "</div>\n";


    print "<div id\=\"resulttable\">\n";

    print "<table cellspacing=\"2\" cellpadding=\"2\" border = \"1\" bgcolor=\"#FFE5A7\">\n";
#    print "<tr>\n<td>\n";

    while (@resultarray = $outputquery->fetchrow_array) {

	print "<tr valign = \"top\">\n<td><input type =\"checkbox\" name = \"doc_id\" value = \"$resultarray[0]\"$checkedtext>";


	print "</td>\n";

	print "<td><a href=\"$self->{httppath}details.pl?database=$self->{databasename}\&doc_id=$resultarray[0]\&questionid=$self->{questionid}\&resultpart=$self->{resultpart}\&checked=1\&sorting=$self->{sorting}\" target = \"details\"><b>$resultarray[2] ($resultarray[3]): </b></a>\n";

	print "</td><td>$resultarray[4] \n";

	if ((defined ($resultarray[12])) and  ($resultarray[12])) {
	    print "<br><a href=\"$self->{pdfdir}$resultarray[12]\"><b>PDF</a>\n";
	}
	print "</td></tr>\n";


    } # while (@resultarray = $outputquery->fetchrow_array) - Schleife

    print "</table>\n";

    print "</div>\n";

    

    print "\n";
    print "<input type = \"hidden\" name = \"database\" value = \"$self->{databasename}\">";
    print "<input type = \"hidden\" name = \"sorting\" value = \"$self->{sorting}\">";
    print "<input type = \"hidden\" name = \"resultpart\" value = \"$self->{resultpart}\">";
    print "<input type = \"hidden\" name = \"checked\" value = \"$self->{checked}\">";
    print "<input type = \"hidden\" name = \"questionid\" value = \"$self->{questionid}\">";
    print "</form>\n";

    $outputquery->finish;

    return $self;

}







sub searching {
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



    my $counter = 0;
    my $oldtemptable = "temp".$counter;
#    print "$oldtemptable \n";


########################## Versuch mit Bewertungstabelle
    my $relevancetable = "rvtable1";
    &SearchDocId::creatervtable ($self->{dbhandle}, $relevancetable) or die "\ncan not build table for relevance of results\n";
    &SearchDocId::searchrelevances ($self->{dbhandle}, $relevancetable, \@searcharray) or die "\ncan not replace\n";



########################## Versuch mit Bewertungstabelle







# another try

    my @temptablearray;

    my $fieldname = shift (@searcharray);
    my $searchstring = shift (@searcharray);

#    print "<p>$searchstring</p>";

    &SearchDocId::createtmptable ($self->{dbhandle}, $oldtemptable) or die "\ncan not build tmp-tabelle\n";
    &SearchDocId::replace ($self->{dbhandle}, $oldtemptable, $fieldname, $searchstring) or die "\ncan not replace\n";

    push (@temptablearray, $oldtemptable);
    $counter++;
    $oldtemptable = "temp".$counter;
#    print "$oldtemptable \n";

    my $connection;

    while ($connection = shift (@searcharray)) {

#	print "connection $connection ";

	my $fieldname = shift (@searcharray);
	my $searchstring = shift (@searcharray);


	&SearchDocId::createtmptable ($self->{dbhandle}, $oldtemptable) or die "\ncan not build tmp-tabelle\n";
	&SearchDocId::replace ($self->{dbhandle}, $oldtemptable, $fieldname, $searchstring) or die "\ncan not replace\n";

	push (@temptablearray, $connection, $oldtemptable);
	$counter++;
	$oldtemptable = "temp".$counter;
#	print "$oldtemptable \n";
    }



    my $resulttable = shift @temptablearray;

#    print "<p>@temptablearray</p>";


    while ($connection = shift @temptablearray) {
	my $table1 = shift @temptablearray;
 
	if ($connection eq "AND") {
	    my $andtemptable = "andtable".$table1;
	    &SearchDocId::createtmptable ($self->{dbhandle}, $andtemptable) or die "\ncan not build tmp-tabelle\n";
	    &SearchDocId::andtable ($self->{dbhandle}, $resulttable, $table1, $andtemptable);

	    $resulttable = $andtemptable;
	}

	if ($connection eq "OR") {
	    &SearchDocId::ortable ($self->{dbhandle}, $resulttable, $table1);
	}



    }

    $oldtemptable = $resulttable;





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
	&SearchDocId::selecttonewtable ($self->{dbhandle}, $oldtemptable, "owner", $ownerquestionstring, $ownertemptable) or die "\ncan not replace\n";

	$oldtemptable = $ownertemptable;
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
    $self->{docidtable} = $oldtemptable;

    return $self;

}



sub return_docidtable {
    my $self = shift;
    if ($self->{docidtable}) {
	return $self->{docidtable};
    }
    else {
	return 0;
    }
}


sub deletetable_from_docids {
    my $self = shift;
    my %parameter = @_;


#    if ($parameter{checked}) {
#	$self->{checked} = $parameter{checked};
#    }

  
    if ($parameter{dbhandle}) {
	$self->{dbhandle} = $parameter{dbhandle};
    }


    if ($parameter{docidref}) {
	$self->{docidref} = $parameter{docidref};
    }

# set flag for resultprint
    $self->{delete} = 1;

# make sure that only the owners datasets can be choosen for deletion 
#    if ($parameter{htmlaccessname}) {
    $self->{htmlaccessname} = $ENV{REMOTE_USER}; 
#    }

    unless (defined $self->{docidref}) {
	die "<h4>no document ids given<\/h4>\n";
    }


    else {
	my @docidsarray = @{$self->{docidref}};


	my $deletedocidtable = "deletedocidtable";
	my $createdocidtable;

	unless ($createdocidtable = $self->{dbhandle}->prepare("create temporary table $deletedocidtable (documentid int(11) NOT NULL, primary key (documentid))")) {
	    die "create deletedocidtable prepare error $DBI::err: $DBI::errstr.\n";
	}
	unless ($createdocidtable->execute()) {
	    die "create deletedocidtable execute error $DBI::err: $DBI::errstr.\n";
	}
	my $doc_ids_string = join("\'\)\,\(\' ", @docidsarray); 
	$doc_ids_string = "\(\'".$doc_ids_string."\'\)";
	my $insertquery;
    
# print "insert into $deletedocidtable \(documentid\) values $doc_ids_string";
    
	unless ($insertquery = $self->{dbhandle}->prepare ("insert into $deletedocidtable \(documentid\) values $doc_ids_string")) {
	    die "insert deletedocidtable prepare error $DBI::err: $DBI::errstr.\n";
	}
#    print "$insertquery\n";
	unless ($insertquery->execute()) {
	    die "insert deletedocidtable execute error $DBI::err: $DBI::errstr.\n";
	}

	$insertquery->finish;
	$createdocidtable->finish;


# select only docids from user
	my $deleteownertable = "deleteownertable"; 

	my $ownerquestionstring = "o.name = \"".$self->{htmlaccessname}."\"";
	
	&SearchDocId::createtmptable ($self->{dbhandle}, $deleteownertable) or die "\ncan not build tmp-tabelle\n";
	&SearchDocId::selecttonewtable ($self->{dbhandle}, $deletedocidtable, "owner", $ownerquestionstring, $deleteownertable) or die "\ncan not replace\n";

	$deletedocidtable = $deleteownertable;
	$self->{docidtable} = $deletedocidtable;

	return $self;

    }



}


return 1;



=command
replace $tablename select distinct d.documentid from aut_writes_doc awd left join document d on (d.documentid = awd.documentid) inner join author a on (a.authorid = awd.authorid) where (a.name $searchstring)



replace $newtablename select distinct d.documentid from aut_writes_doc awd left join document d on (d.documentid = awd.documentid) inner join author a on (a.authorid = awd.authorid) inner join $oldtablename on ($oldtablename.documentid = d.documentid) where (a.name $searchstring)
=cut













=command
create temporary table tempouttable select distinct d.documentid, d.refmanid, a.name, d.year, d.title, j.journaltitle, d.issue, b.booktitle, d.volume, s.seriestitle, d.startpage, d.endpage from document d inner join aut_writes_doc awd on (d.documentid = awd.documentid) inner join author a on ((a.authorid = awd.authorid) and (awd.author_rank = 1)) left join journal j on (d.journalid = j.journalid) left join book b on (d.bookid = b.bookid) left join series s on (d.seriesid = s.seriesid) inner join doc_in_question diq on (d.documentid = diq.documentid) where (diq.questionid = \"guest1168308210pid7283\")"
=cut
















