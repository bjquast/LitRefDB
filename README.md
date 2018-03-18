# LitRefDB
Database application with old style web interface, used for managing literature refences in my research projects. Imports and exports bibtex and RIS format, new filters are welcome. It has a user management based on http basic authentication and is able to store attachements to the references.

## Requirements

Apache2: mod_cgi, mod_auth_basic, mod_ssl
Perl: CGI, CGI::Carp, DBI, Archive::Zip, IO::String, IO::File
MySQL database engine

## Installation

### Download

`git clone https://github.com/bjquast/LitRefDB.git`

### Database setup

Create database

`mysql -u root -p`

```SQL
mysql> create database dbserver12;
mysql> grant all on dbserver12.* to litdbuser@localhost identified by 'mysecretpassword';
mysql> exit
```

Load database scheme

`mysql dbserver12 -u root -p < .LitRefDB/database/dbserver12_schema.sql`

#### Issue #1

On new MySQL-instances some SQL-Statements in the software with GROUP_CONCAT() functions fail because of the group_concat_max_len limt set to 1024. I guess the limit is to small because the default encoding has changed to utf and thus uses more bytes per character.

This can be changed by adding the following line in the mysql config file (`/etc/mysql/mysql.conf.d/mysqld.cnf` on Ubuntu 17.10) in section [mysqld]:

`group_concat_max_len=4096`

Then restart mysql service

`sudo service mysql restart`


### Pathes to be defined

There are three pathes that should be defined before configuring the scripts:

1. Location of index.html and pdfdir in the DocumentRoot of webserver. Here I used:
`/var/www/html/dbserver12`
and
`/var/www/html/dbserver12/pdfdir`

2. Location of the password file for the database, here I used:
`/etc/dbserver12/dbpasswd`

3. Location of the cgi scripts, here I used:
`/usr/lib/cgi-bin/dbserver12/`



### Configure URLs in html.index

Change title and header in `./LitRefDB/html/index.html` to your requirements 

```html
[...]
  <title>Datenbank-Startseite</title>
[...]
     <td> <h2>ZooSyst-Literaturdatenbank</h2> </td>
     <td> <h1 align="right">Startseite</h1> </td>
```

Adapt the following link so that the URL fits your domain, URL-path to cgi-bin and database name 

```html
[...]
  <li><a href="https://192.168.1.79/cgi-bin/dbserver12/dbstart.pl?database=dbserver12">Datenbank</a></li>
[...]
```

### Configure URLs in Perl cgi-scripts

The configuration is done in the file `./LitRefDB/cgi-bin/dbserver12/htmlmodule/DbDefs`. There, the URL, paths to cgi-bin dir and to the password file for the database must be configured

Set the URL-path to cgi-bin folder:

```Perl
[...]
sub httppath {
# returns the path to the cgi-scripts. usage: $httppath = Html::httppath() 
    my $httppath = "https://example.com/cgi-bin/dbserver12/";
    return $httppath;
}
```

Set the path on the server where it can store PDF files (DocumentRoot + specific directory). This directory must have write access for the webserver user (e.g. www-data) 

```Perl
sub inputpdfdir {
    my $pdfdir = "/var/www/html/dbserver12/pdfdir/";
    return $pdfdir;
}
```
Set the URL to the PDF directory (Domain name + specific directory)

```Perl
sub outputpdfdir {
    my $pdfdir = "https://example.com/dbserver12/pdfdir/";
    return $pdfdir;
}
```

Set the username for the mysql database

```Perl
sub dbusername {
    my $username = "litdbuser";
    return $username;
}
```

Set the path to the file that contains the username and password of the database user

```Perl
sub passwordfile {
    my $passwordfile = "/etc/dbserver12/dbpasswd"; 
    return $passwordfile;
}
```

Set the database name 

```Perl
sub database {
    my $database = "dbserver12"; 
    return $database;
}
```

Set the host for the database connection 

```Perl
sub host {
    my $host = "127.0.0.1";
    return $host;
}
```

### Configure and copy the password file for the database user

Change the user and password in ./LitRefDB/pwfile/dbpasswd to the credentials for the database user

```
litdbuser "mysecretpassword"
```

Copy the password file to the location as set in `./LitRefDB/cgi-bin/dbserver12/htmlmodule/DbDefs.pm` above, e. g. 
`/etc/dbserver12/dbpasswd`

**This is stored in cleartext there, so set read rights for webserver only**

```
sudo mkdir /etc/dbserver12
sudo cp dbserver/pwfile/dbpasswd /etc/dbserver12/
sudo chown -R www-data:www-data /etc/dbserver12
sudo chmod -R g-rwx /etc/dbserver12
```

### Create directories for webserver

Create the needed folder in the document root of the webserver (here for Apache2 on Ubuntu 16.04): 

```
sudo mkdir -p /var/www/html/dbserver12/pdfdir
sudo chown -R www-data:www-data /var/www/html/dbserver12
```

### Copy the files to the appropriate directories

Copy the index.html from ./LitRefDB/html/ to the created folder:

```
sudo cp ./LitRefDB/html/index.html /var/www/html/dbserver12/
sudo chown -R www-data:www-data /var/www/html/dbserver12
```

Copy the Perl scripts to the cgi-bin folder and set the rights:

```
sudo cp ./LitRefDB/cgi-bin/dbserver12 /usr/lib/cgi-bin/
sudo chown -R root:www-data /usr/lib/cgi-bin/dbserver12
sudo chmod -R o-rwx /usr/lib/cgi-bin/dbserver12
sudo chmod -R ug+rx /usr/lib/cgi-bin/dbserver12
```
#### Issue #2
As of Ubuntu 17.10 . is not in Perl's @INC array. Thus the perl modules must be copied to /usr/local/lib/site-perl 

```
ls /usr/local/lib/site_perl
# if not exists:
sudo mkdir /usr/local/lib/site_perl
sudo cp -r /usr/lib/cgi-bin/dbserver12/htmlmodule /usr/local/lib/site_perl/
sudo cp -r /usr/lib/cgi-bin/dbserver12/dbmodule /usr/local/lib/site_perl/
sudo cp -r /usr/lib/cgi-bin/dbserver12/dbfilter /usr/local/lib/site_perl/
sudo chmod -R ugo+x /usr/local/lib/site_perl/
```

## Configure Apache2

### Set RewriteRule to enforce ssl connection

Because the web interface uses http basic authentication it is necessary to limit access to the https protocol. To achive that configure a RewriteRule in Apaches default configuration and limit access to the cgi-bin/dbserver12 directory in the ssl-configuration: 

Set up RewriteRules in **default** Apache config (e. g. /etc/apache2/sites-enabled/default.conf) to enforce ssl connection

```
# for the domain name
RewriteCond %{REQUEST_URI}   ^/dbserver12 [NC]
RewriteRule ^/(.*) https://www.<domainname>/dbserver12/$1 [NE,L]
RewriteCond %{REQUEST_URI}   ^/cgi-bin/dbserver12 [NC]
RewriteRule ^/(.*) https://www.<domainname>/cgi-bin/dbserver12/$1 [NE,L]
```

### Set up Directory directives in ssl configuration

Set up directory directives in your Apache configuration for **ssl** (e. g. /etc/apache2/sites-enabled/ssl.conf):

```
# basic authentication on html DocumentRoot
  <Directory /var/www/html/dbserver12>
        AuthUserFile /etc/apache2/dbserver12_passwd
        AuthType Basic
        AuthName dbserver12
        require valid-user
    </Directory>

  ScriptAlias /cgi-bin/ /usr/lib/cgi-bin/
 <FilesMatch "\.(cgi|shtml|phtml|php)$">
                  SSLOptions +StdEnvVars
  </FilesMatch>
  <Directory /usr/lib/cgi-bin>
                  SSLOptions +StdEnvVars
  </Directory>

# add a Directory directive that restrictes access to the dbserver12 dir in cgi-bin 
  <Directory /usr/lib/cgi-bin/slides_loader>
               AuthUserFile /etc/apache2/dbserver12_passwd
               AuthType Basic
               AuthName dbserver12
               Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
               require valid-user
  </Directory>
```




