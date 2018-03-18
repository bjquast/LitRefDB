package Ris2Hash;

use strict;
use warnings;
use CGI;
use DBI;
use Encode;


# Dieses Modul soll Daten aus einer ris-Datei (ein Export-Typ des Reference-Managers) einlesen und in einen Hash schreiben. Der Hash soll von DataInput.pm genutzt werden können, um die Daten in die Datenbank einzutragen. Das Modul bekommt ein Dateihandle übergeben und gibt eine Referenz auf den gefüllten hash zurück.

# Hashreferenz = &Ris2Hash::filter2hash(Dateihandle);
# $datenhashref = &Ris2Hash::filter2hash($dateihandle);


sub filter2hash {


    my $filehandle = shift;
    my %datensatz;
    my @dateiarray;
    $dateiarray[0] = " "; #damit bei Abfrage der Länge nicht undefiniert rauskommt
    my $element;
    my $zwischen;
    my $datensatznummer = 0;
    my @zwischenarray;
    
    @zwischenarray = <$filehandle>;
    
    
#    print @zwischenarray;

    print "<p>Bitte warten</p>\n";
    
    
    foreach $element (@zwischenarray) {
	chomp ($element);


	$element =~ s//<i>/g;
	$element =~ s//<\/i>/g;

	my $decodestring = decode("ibm850", $element);
#	$element = encode("utf-8", $decodestring); 
	$element = encode("iso-8859-15", $decodestring); 



	if ($element =~ m/\r$/) {
	    chop ($element);
	}
	$element =~ s/\s/ /g;
	if ($element =~ m/^\w\w  - /) {
	    push (@dateiarray, $element);
	}
	else {
	    my $listelement = $#dateiarray;
	    $dateiarray[$listelement] .=" $element";
	}
    }
    
    
    
    
# in den hash einzufügende
# Felder:                       Kürzel  Tabelle.Spalte
#  doctype;                  #TY    document.doctype
#  refmanid;                 #ID    document.refmanid
#  title;                    #T1    document.title
#  autor;                    #A1    author.name (key in aut_writes_doc)
#  year;                     #Y1    document.year
#  notizen;                  #N1    document.notizen
#  @keyword;                 #KW    keyword.word
#  reprint;                  #RP
#  startpage;                #SP    document.startpage
#  endpage;                  #EP    document.endpage
#  journal;                  #JF    journal.journaltitle
#  journalsynonym1;          #JA    journal.titlesynonym1
#  volume;                   #VL    document.volume
#  issue;                    #IS    document.issue
#  verlag;                   #PB    verlag.verlagname
#  verlagort;                #CY    verlag.verlagort
#  available;                #AV    document.available
#  book;                     #T2    book.booktitle
#  series;                   #T3    series.seriestitle
#  @bookeditor;              #A2    author.name (key in edits_book)
#  @serieseditor;            #A3    author.name (key in edits_series)
#  language;                 #U1
#  abstractlanguage;         #U2
#  abstract;                 #N2    document.abstract
#  isbn;                     #SN    document.isbn
#  contactaddress;           #AD
    
    
    
    foreach $element (@dateiarray) {



	if ($element =~ m/TY  - /) {

	
# Ersetzen des Typs von Refman in bibtex-Typ
	
	    if ($element =~ s/ty\W+\-\W+jour/article/i){}
	    elsif ($element =~ s/ty\W+\-\W+book/book/i){}
	    elsif ($element =~ s/ty\W+\-\W+ser/incollection/i){}
	    elsif ($element =~ s/ty\W+\-\W+chap/inbook/i){}
	    elsif ($element =~ s/ty\W+\-\W+unpb/unpublished/i){}
	    elsif ($element =~ s/ty\W+\-\W+thes/phdthesis/i){}
	    elsif ($element =~ s/ty\W+\-\W+conf/inproceedings/i){}
	    
	    else {
		$element = "misc";
	    }
	    
# Die Datensätze fangen nicht unbedingt mit /TY  - / an, besser ist es, sie mit dem /ER  - / tag (end of record) hoch zu zählen 
#	    $datensatznummer++;

	    $datensatz{"$datensatznummer"}{"doctype"} = $element;
#      chomp ($datensatz{"$datensatznummer"}{"doctype"});
#      print $datensatznummer;
	}
	
	elsif ($element =~ m/ID  - /) {
	    $datensatz{"$datensatznummer"}{"refmanid"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"refmanid"});
	}
	
	elsif ($element =~ m/T1  - /) {
	    $datensatz{"$datensatznummer"}{"title"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"title"});
	}
	
	elsif (($element =~ m/A1  - /) || ($element =~ m/AU  - /)) {
	    $zwischen = substr ($element, 6);
#      chomp ($zwischen);
	    push (@{$datensatz{"$datensatznummer"}{"author"}}, $zwischen);
	}
	
	elsif (($element =~ m/Y1  - /) || ($element =~ m/PY  - /)) {
	    $datensatz{"$datensatznummer"}{"year"} = substr ($element, 6, 4); #Länge des Substrings auf 4 begrenzen, so dass nur Jahreszahlen übernommen werden und nicht Jahr/Monat/Tag
#      chomp ($datensatz{"$datensatznummer"}{"year"});
	}
	
	elsif ($element =~ m/N1  - /) {
	    $datensatz{"$datensatznummer"}{"notizen"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"notizen"});
	}
	
	elsif ($element =~ m/KW  - /) {
	    $zwischen = substr ($element, 6);
#      chomp ($zwischen);
	    push (@{$datensatz{"$datensatznummer"}{"keyword"}}, $zwischen);
	}
	
	elsif ($element =~ m/RP  - /) {
	    $datensatz{"$datensatznummer"}{"reprint"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"reprint"});
	}
	
	elsif ($element =~ m/SP  - /) {
	    $datensatz{"$datensatznummer"}{"startpage"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"startpage"});
	}
	
	elsif ($element =~ m/EP  - /) {
	    $datensatz{"$datensatznummer"}{"endpage"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"endpage"});
	}
	
	elsif ($element =~ m/JF  - /) {
	    $datensatz{"$datensatznummer"}{"journal"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"journal"});
	}
	
	elsif ($element =~ m/JA  - /) {
	    $datensatz{"$datensatznummer"}{"journalsynonym1"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"journalsynonym1"});
	}
	
	elsif ($element =~ m/VL  - /) {
	    $datensatz{"$datensatznummer"}{"volume"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"volume"});
	}

	elsif ($element =~ m/IS  - /) {
	    $datensatz{"$datensatznummer"}{"issue"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"issue"});
	}
	
	elsif ($element =~ m/PB  - /) {
	    $datensatz{"$datensatznummer"}{"verlag"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"publisher"});
	}
	
	elsif ($element =~ m/CY  - /) {
	    $datensatz{"$datensatznummer"}{"verlagort"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"city"});
	}
	
	elsif ($element =~ m/AV  - /) {
	    $datensatz{"$datensatznummer"}{"available"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"available"});
	}
	
	elsif ($element =~ m/T2  - /) {
	    $datensatz{"$datensatznummer"}{"book"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"book"});
	}
	
	elsif ($element =~ m/T3  - /) {
	    $datensatz{"$datensatznummer"}{"series"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"series"});
	}
	
	elsif ($element =~ m/A2  - /) {
	    $zwischen = substr ($element, 6);
#      chomp ($zwischen);
	    push (@{$datensatz{"$datensatznummer"}{"bookeditor"}}, $zwischen);
	}
	
	elsif ($element =~ m/A3  - /) {
	    $zwischen = substr ($element, 6);
#      chomp ($zwischen);
	    push (@{$datensatz{"$datensatznummer"}{"serieseditor"}}, $zwischen);
	}
	
	elsif ($element =~ m/U1  - /) {
	    $datensatz{"$datensatznummer"}{"language"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"language"});
	}
	
	elsif ($element =~ m/U2  - /) {
	    $datensatz{"$datensatznummer"}{"abstractlanguage"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"abstractlanguage"});
	}
	
	elsif ($element =~ m/N2  - /) {
	    $datensatz{"$datensatznummer"}{"abstract"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"abstract"});
	}
	
	elsif ($element =~ m/L1  - /) {
	    $datensatz{"$datensatznummer"}{"pdffile"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"isbn"});
	}

	elsif ($element =~ m/SN  - /) {
	    $datensatz{"$datensatznummer"}{"isbn"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"isbn"});
	}
	
	elsif ($element =~ m/AD  - /) {
	    $datensatz{"$datensatznummer"}{"contactaddress"} = substr ($element, 6);
#      chomp ($datensatz{"$datensatznummer"}{"contactaddress"});
	}

	elsif ($element =~ m/M3  - /) {
	    $zwischen = substr ($element, 6);
#      chomp ($zwischen);
	    my @specieslist = split (/\;\s*/, $zwischen);
	    $datensatz{"$datensatznummer"}{"species"} = \@specieslist;
	}


# wenn /ER  - / auftritt kommt nächster Datensatz
	elsif ($element =~ m/ER  - /) {
	    $datensatznummer++;
	}

    }
    my $anzahl = $datensatznummer;
# print "anzahl = $anzahl\n";
    
    
#    print "<h1>TITEL $datensatz{1}{title}</h1>";

    
    my $datenhashref = \%datensatz;
    return $datenhashref;
}

return 1;











