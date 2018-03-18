package CheckOwner;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use dbmodule::SearchDocId;
#use htmlmodule::Html;


sub mydocs {
    my $dbhandle = shift;
    my $docidsref = shift;
    my $htmlaccessname = shift;

    my @docids = @$docidsref;


##############
#shooting blackbirds with cannonballs

    my $docidtable = "docidtable";
    my $createdocidtable;
    
    unless ($createdocidtable = $dbhandle->prepare("create temporary table $docidtable (documentid int(11) NOT NULL, primary key (documentid))")) {
	die "create docidtable prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($createdocidtable->execute()) {
	die "create docidtable execute error $DBI::err: $DBI::errstr.\n";
    }
    my $docidsstring = join("\'\)\,\(\' ", @docids); 
    $docidsstring = "\(\'".$docidsstring."\'\)";
    my $insertquery;
    
# print "insert into $deletedocidtable \(documentid\) values $doc_ids_string";
    
    unless ($insertquery = $dbhandle->prepare ("insert into $docidtable \(documentid\) values $docidsstring")) {
	die "insert docidtable prepare error $DBI::err: $DBI::errstr.\n";
    }
#    print "$insertquery\n";
    unless ($insertquery->execute()) {
	die "insert docidtable execute error $DBI::err: $DBI::errstr.\n";
    }

    $insertquery->finish;
    $createdocidtable->finish;


# select only docids from user
    my $ownertable = "checkownertable"; 

    my $ownerquestionstring = "o.name = \"".$htmlaccessname."\"";
    &SearchDocId::createtmptable ($dbhandle, $ownertable) or die "\ncan not build tmp-tabelle\n";
    &SearchDocId::selecttonewtable ($dbhandle, $docidtable, "owner", $ownerquestionstring, $ownertable) or die "\ncan not replace\n";
    
    $docidtable = $ownertable;


    my $docidquery;
    unless ($docidquery = $dbhandle->prepare ("select documentid from $docidtable")) {
	die "docidquery prepare error $DBI::err: $DBI::errstr.\n";
    }
#    print "$insertquery\n";
    unless ($docidquery->execute()) {
	die "docidquery execute error $DBI::err: $DBI::errstr.\n";
    }

    my @mydocids;
    my $docid;
    while (($docid) = $docidquery->fetchrow_array) {
	push (@mydocids, $docid);
    }

    $insertquery->finish;
    $createdocidtable->finish;


    my $mydocidsref = \@mydocids;
    
    return $mydocidsref;
}    



sub otherdocs {
    my $dbhandle = shift;
    my $docidsref = shift;
    my $htmlaccessname = shift;

    my @docids = @$docidsref;


##############
#shooting blackbirds with cannonballs

    my $docidtable = "docidtable";
    my $createdocidtable;
    
    unless ($createdocidtable = $dbhandle->prepare("create temporary table $docidtable (documentid int(11) NOT NULL, primary key (documentid))")) {
	die "create docidtable prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($createdocidtable->execute()) {
	die "create docidtable execute error $DBI::err: $DBI::errstr.\n";
    }
    my $docidsstring = join("\'\)\,\(\' ", @docids); 
    $docidsstring = "\(\'".$docidsstring."\'\)";
    my $insertquery;


    
#    print "insert into $deletedocidtable \(documentid\) values $doc_ids_string";
    
    unless ($insertquery = $dbhandle->prepare ("insert into $docidtable \(documentid\) values $docidsstring")) {
	die "insert docidtable prepare error $DBI::err: $DBI::errstr.\n";
    }
#    print "$insertquery\n";
    unless ($insertquery->execute()) {
	die "insert docidtable execute error $DBI::err: $DBI::errstr.\n";
    }

    $insertquery->finish;
    $createdocidtable->finish;

#    print "||create temporary table $docidtable (documentid int(11) NOT NULL, primary key (documentid))";
#    print "||insert into $docidtable \(documentid\) values $docidsstring";



# select only docids from user
    my $ownertable = "checkownertable"; 

    my $ownerquestionstring = "o.name != \"".$htmlaccessname."\"";
    &SearchDocId::createtmptable ($dbhandle, $ownertable) or die "\ncan not build tmp-tabelle\n";
    &SearchDocId::selecttonewtable ($dbhandle, $docidtable, "owner", $ownerquestionstring, $ownertable) or die "\ncan not replace\n";
    
    $docidtable = $ownertable;


    my $docidquery;
    unless ($docidquery = $dbhandle->prepare ("select documentid from $docidtable")) {
	die "docidquery prepare error $DBI::err: $DBI::errstr.\n";
    }
    unless ($docidquery->execute()) {
	die "docidquery execute error $DBI::err: $DBI::errstr.\n";
    }

#    print "||$docidquery\n";

    my @otherdocids;
    my $docid;
    while (($docid) = $docidquery->fetchrow_array) {
	push (@otherdocids, $docid);
    }

    $insertquery->finish;
    $createdocidtable->finish;

#    print "||select documentid from $docidtable";
#    print "||otherdocs\n", @otherdocids;

    my $otherdocidsref = \@otherdocids;

    
    return $otherdocidsref;
}    



return 1;














