# LitRefDB
Database application with old style web interface, used for managing literature refences in my research projects. Imports and exports bibtex and RIS format, new filters are welcome. It has a user management based on http basic authentication and is able to store attachements to the references.

## Requierements

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

`mysql dbserver12 -u root -p < ../dbserver12_schema.sql`

#### Issue #1

On new MySQL-instances some SQL-Statements in the software with GROUP_CONCAT() functions fail because of the group_concat_max_len limt set to 1024. I guess the limit is to small because the default encoding has changed to utf and thus uses more bytes per character.

This can be changed by adding the following line in the mysql config file (`/etc/mysql/mysql.conf.d/mysqld.cnf` on Ubuntu 17.10) in section [mysqld]:

`group_concat_max_len=4096`

Then restart mysql service

`sudo service mysql restart`

### Create directories and index.html for webserver

Create the needed folder in the document root of the webserver (here for Apache2 on Ubuntu 16.04): 

```
sudo mkdir -p /var/www/html/dbserver12/pdfdir
sudo chown -R www-data:www-data /var/www/html/dbserver12
```

### Configure URLs

Change title and header in LitRefDB/html/index.html to your requirements 

```html LitRefDB/html/index.html
[...]
  <title>Datenbank-Startseite</title>
[...]
     <td> <h2>ZooSyst-Literaturdatenbank</h2> </td>
     <td> <h1 align="right">Startseite</h1> </td>
```

Adapt the following link so that the URL fits your domain, URL-path to cgi-bin and database name 

```html LitRefDB/html/index.html
[...]
  <li><a href="https://192.168.1.79/cgi-bin/dbserver12/dbstart.pl?database=dbserver12">Datenbank</a></li>
[...]
```


### Configure and copy database password file


