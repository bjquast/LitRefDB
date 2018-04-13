#!/usr/bin/perl -w

use strict;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;

#use dbmodule::SearchDocId;
use dbmodule::DbConnect;
#use dbmodule::QuestionResults;
use dbmodule::QuestionResultsOb;
use htmlmodule::Html;
use htmlmodule::DbDefs;



my $output = new CGI();


my $databasename = $output->param('database');

# connect to database
my $dbcon = DbConnect->new(database => $databasename);
my $dbhandle = $dbcon->connect_to_db();

my $httppath = &DbDefs::httppath;  #returns path for all scripts

#html-header für die Seite ausdrucken mit modul Html::header 
# print html-header
my $htmlcaption = "Results";
&Html::header($httppath, $htmlcaption);
&Html::body();

#&Html::menu($httppath, $databasename);



# Abfrageparameter übernehmen
# get parameters for results
my $questionid = $output->param('questionid');
my $resultpart = $output->param('resultpart');
my $checked = $output->param('checked');
my $sorting = $output->param('sorting');



#&QuestionResultsOb::resultprint($dbhandle, $databasename, $httppath, $questionid, $sorting, $checked, $resultpart);
    my $resultobject = QuestionResultsOb->new(dbhandle => $dbhandle, database => $databasename, httppath => $httppath, questionid => $questionid);
    $resultobject -> resultprint (sorting => $sorting, checked => $checked, resultpart => $resultpart);


&Html::foot();
    
$dbhandle->disconnect;



