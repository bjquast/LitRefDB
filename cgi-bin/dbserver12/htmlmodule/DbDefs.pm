package DbDefs;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);

 
# this module should provide the special pathes and data for the database and cgi-scripts

sub httppath {
# returns the path to the cgi-scripts. usage: $httppath = Html::httppath() 
    my $httppath = "https://192.168.1.79/cgi-bin/dbserver12/";
    return $httppath;
}

sub inputpdfdir {
    my $pdfdir = "/var/www/html/dbserver12/pdfdir/";
    return $pdfdir;
}

sub outputpdfdir {
    my $pdfdir = "https://192.168.1.79/dbserver12/pdfdir/";
    return $pdfdir;
}

sub dbusername {
    my $username = "litdbuser";
    return $username;
}


sub passwordfile {
    my $passwordfile = "/etc/dbserver12/dbpasswd"; 
    return $passwordfile;
}

sub database {
    my $database = "dbserver12"; 
    return $database;
}

sub host {
    my $host = "127.0.0.1";
    return $host;
}





return 1;
