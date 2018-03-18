package DbConnect;

use strict;
use warnings;
use DBI;
use htmlmodule::DbDefs;

# the modul provides the connection to the database

# dbconnection = DbConnect->new([username => "name"], [database => "dbasename"],[password => "password"], [host => "hostname"])
# $dbhandle = dbconnection->connect_to_db([username => "name"], [database => "dbasename"],[password => "password"], [host => "hostname"])   
# dbconnection->find_password([username => "name"], [database => "dbasename"],[password => "password"], [host => "hostname"])   



sub new {
    my $type = shift; 
    my $class = ref($type) || $type; 

    my $self = {@_};

    bless($self, $class); #das ganze wird zu einem Objekt gemacht

    unless (defined($self->{username})) {
	$self->{username} = &DbDefs::dbusername();
    }


    unless (defined($self->{passwordfile})) {
	$self->{passwordfile}= &DbDefs::passwordfile();
    }


    unless (defined($self->{password})) {
	$self->find_password();
    }


    if ((not (defined($self->{database}))) || ($self->{database} eq "")) {
	$self->{database}= &DbDefs::database();
    }

    unless (defined($self->{host})) {
	$self->{host}= &DbDefs::host();
    }

    return $self;
}




sub connect_to_db { #Verbindung zu einer! Datenbank herstellen 
# connect_to_db returns an open handle for a database if the parameters username, password and database are given. If no hostname is given, the default 127.0.0.1 will be taken. usage: $dbhandle = dbconnection->connect_to_db([username => "name"], [database => "dbasename"],[password => "password"], [host => "hostname"])   


    my $self = shift;
    my %parameter = @_;



    if ($parameter{username}) {
	$self->{username} = $parameter{username};
    }
  
    if ($parameter{password}) {
	$self->{password} = $parameter{password};
    }

    if ($parameter{database}) {
	$self->{database} = $parameter{database};
    }

    if ($parameter{host}) {
	$self->{host} = $parameter{host};
    }

    my $dbh = DBI->connect("DBI:mysql:$self->{database}:$self->{host}", "$self->{username}", "$self->{password}");

    unless ($dbh) {
	print "<p>\nDbConnect::connect_to_db: can not open database, check databasename, username and password</p>\n";
    }	

    return $dbh;
}



sub find_password {
# find_passwd looks for database password in a file that is not in the http_root. it needs a username for the database. usage: # dbconnection->find_password([passwordfile => "path"], [username => "name"], [database => "dbasename"],[password => "password"], [host => "hostname"])   



    my $self = shift;
    my %parameter = @_;



    if ($parameter{username}) {
	$self->{username} = $parameter{username};
    }
  
    if ($parameter{passwordfile}) {
	$self->{passwordfile} = $parameter{passwordfile};
    }


    open (PASSDAT, $self->{passwordfile}) or die ("\nDbConnect::findpasswd: Can not open passwordfile\n");
    my @datei = <PASSDAT>;
    close (PASSDAT);

    my $element;
    my $password;
    foreach $element (@datei) {
	if ($element  =~ m/($self->{username})\s*\"(.*)\"/) {
	    $self->{password} = $2;
	}
    }
    return $self;
}




return 1;







=command




sub find_dbs { #Datenbanken anzeigen, und Zugriffsmöglichkeit prüfen
# getting the databases, the user has access to. usage @databasearray = DbConnect::find_dbs (username, password)
    my $username = shift;
    my $password = shift;    
    my $mysqlbefehl = "mysqlshow -u $username -p$password"; #$password muss direkt hinter -p kommen
    my @databases = `$mysqlbefehl`;
    
    my @testdatabases;
    my $element;
    my $string;
    foreach $element (@databases) { #Datenbanknamen extrahieren
	if ($element =~ m/(\w+)/) {
	    unless (($element eq "mysql") || ($element eq "Databases") || ($element eq "test")) {
		push (@testdatabases, $1);
	    }
	}
    }
    return @testdatabases;
}


=cut



