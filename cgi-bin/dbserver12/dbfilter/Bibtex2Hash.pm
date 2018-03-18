package Bibtex2Hash;

use strict;
use warnings;
use CGI;
use DBI;


# Dieses Modul soll Daten aus einer bibtex-Datei einlesen und in einen Hash schreiben. Der Hash soll von DataInput.pm genutzt werden können, um die Daten in die Datenbank einzutragen. Das Modul bekommt ein Dateihandle übergeben und gibt eine Referenz auf den gefüllten hash zurück.

# Hashreferenz = &Bibtex2Hash::filter2hash(Dateihandle);
# $datenhashref = &Bibtex2Hash::filter2hash($dateihandle);


sub filter2hash {


    my $filehandle = shift;
    my $zeile;
    my $dateistring;
    my %datenhash;
    my %zwischenhash;


#    open (OUTDAT, ">/home/bquast/bibtexverarb.txt") or die "cant open Datei";

# datei in $dateistring einlesen

    while ($zeile = <$filehandle>) {
	$dateistring.=$zeile;
    }



# $dateistring in einzelne Datensätze aufteilen 

    my @datensatzarray = split (/\s*\@\W*(\w+)\s*([\{\(])([^\,]+)/, $dateistring);#
    shift @datensatzarray;  #durch split ensteht ein 1.element vor dem ersten Datensatztrenner (@...)


# einen zwischenhash bauen der zu jedem Datensatz den doctype und die Daten enthält. erster Schluessel ist der identifier aus der bibtex-datei

    my $doctype;
    my $klammer;
    my $bibtex_id;
    my $data;

    while (($doctype, $klammer, $bibtex_id, $data) = splice (@datensatzarray, 0, 4)) {
	$zwischenhash{$bibtex_id}{doctype} = $doctype;
	$zwischenhash{$bibtex_id}{klammer} = $klammer;
	$zwischenhash{$bibtex_id}{bibtex_id} = $bibtex_id;
 	$zwischenhash{$bibtex_id}{data} = $data;

	if ($klammer eq "\{") {
	    $zwischenhash{$bibtex_id}{data} =~ s/(.*)\}.*?/$1/s;
#	    print "$bibtex_id: $zwischenhash{$bibtex_id}{data} \|\|\n";
	}
	if ($klammer eq "\(") {
	    $zwischenhash{$bibtex_id}{data} =~ s/(.*)\).*?/$1/s;
	}


    }




# Datensätze in einer Schleife bearbeiten, Die Daten jedes Datensatzes werden in in die Angaben zu Autor, Titel etc. unterteilt, Bibtex-formatierungen werden umgewandelt, die einzelnen Daten werden in %datenhash gespeichert, der dann zurückgegeben werden soll.
  

    foreach $bibtex_id (sort (keys (%zwischenhash))) {


# Daten nach den Schluesseln (zb.: author =  ) in Datenfelder aufteilen und abwechselnd mit Schluessel in zwischenarray packen

	my @zwischenarray;
	if (@zwischenarray = split (/\,\s*(\w+)\s*\=/, $zwischenhash{$bibtex_id}{data})) {
	    shift @zwischenarray;

	    my $schluesselfeld;
	    my $datenfeld;
#	    my $datenneu;

#	    print OUTDAT "\nDatensatz: $bibtex_id\n";


#alle Datenfelder eines Datensatzes umformatieren und entsprechend dem zugehörigen Schluessel in %datenhash packen, Der erste Schluessel von %datenhash ist $bibtex_id aus der äusseren Schleife, der dem bibtex-identifier entspricht.
 
	    while (($schluesselfeld, $datenfeld) = splice (@zwischenarray, 0, 2)) {

#		print OUTDAT "datenfeld: $datenfeld \n";


#akzentuierte Vokale umwandeln 

		$datenfeld =~ s/\{\\\"\{?u\}?\}/ü/g;
		$datenfeld =~ s/\{\\\"\{?o\}?\}/ö/g;
		$datenfeld =~ s/\{\\\"\{?a\}?\}/ä/g;
		$datenfeld =~ s/\{\\\"\{?U\}?\}/Ü/g;
		$datenfeld =~ s/\{\\\"\{?O\}?\}/Ö/g;
		$datenfeld =~ s/\{\\\"\{?A\}?\}/Ä/g;
		$datenfeld =~ s/\\textquotedbl /\"/g;
		$datenfeld =~ s/\\\&/\&/g;
		$datenfeld =~ s/\{\\em (.*?)\}/\<i\>$1\<\/i\>/g;


# äusserste Klammern oder Anführungszeichen in __0 umwandeln, um später innere Klammern in Mustern benutzen zu können

		my $anfstring;
		if ($datenfeld =~ m/(\".*\")/s) {
		    $anfstring = $1;
		    $anfstring =~ s/\"(.*)\"/\_\_0$1\_\_0/s;
		}

		my $bracestring;
		if ($datenfeld =~ m/(\{.*\})/s) {
		    $bracestring = $1;
		    $bracestring =~ s/\{(.*)\}/\_\_0$1\_\_0/s;
		}


# wenn von Klammern und Anführungsstrichen umgebene Strings vorhanden sind, den längeren String nehmen
 
		if (($bracestring) && ($anfstring)) {
		    if ((length ($bracestring)) >= (length ($anfstring))) {
			$datenfeld = $bracestring;
		    }

		    else {
			$datenfeld = $anfstring;
		    }
		} 
		elsif ($bracestring) {
		    $datenfeld = $bracestring;
		}
		elsif ($anfstring) {
		    $datenfeld = $anfstring;
		}
		elsif ($datenfeld =~ m/(\d\d+)/) { #beim Feld year müssen keine Klammern vorhanden sein 
		    $datenfeld = $1;
		}
		else {
		    print "bei $bibtex_id fehlen wahrscheinlich Klammern oder Anführungszeichen um die Daten\n";
		}


#einsortieren und formatieren
		$schluesselfeld = lc ($schluesselfeld);


# doctype
		$datenhash{$bibtex_id}{doctype} = $zwischenhash{$bibtex_id}{doctype};

# bibtex_id
		$datenhash{$bibtex_id}{bibtex_id} = $zwischenhash{$bibtex_id}{bibtex_id};


#author
#		my @authorarray;
		if ($schluesselfeld eq "author") {


# and das innerhalb von geschweiften Klammern steht in \and umwandeln, so dass es nicht Autorn trennt

		    while ($datenfeld =~ m/\{[^\}]*?\sand\s[^\{]*?\}/s) {
			($datenfeld =~ s/(\{[^\}]*?\s)and(\s[^\{]*?\})/$1\\and$2/gis);
		    }

#autoren mit den übriggebliebenen \sand\s trennen
		    
		    my @authorarray;
		    my @authorzwischenarray = split (/\sand\s/, $datenfeld);
		    my $author;
		    foreach $author (@authorzwischenarray) {


#__0 rausnehmen			
			$author =~ s/\_\_0//g;
			$author =~ s/\\//g;
			
			unless (($author =~ m/\,/) || ($author =~ m/\s*\{.*\}\s*/s)) {
			    $author =~ s/(.*)\s([\-\S]+)/$2\, $1/s;
			}

#Klammern rausnehmen

			$author =~ s/\{//g;
			$author =~ s/\}//g;

			push (@authorarray, $author);

		    }
		    $datenhash{$bibtex_id}{author} = \@authorarray;
		    
		} #author




# editor

		if ($schluesselfeld eq "editor") {


# and das innerhalb von geschweiften Klammern steht in \and umwandeln, so dass es nicht Autorn trennt

		    while ($datenfeld =~ m/\{[^\}]*?\sand\s[^\{]*?\}/s) {
			($datenfeld =~ s/(\{[^\}]*?\s)and(\s[^\{]*?\})/$1\\and$2/gis);
		    }

#editoren mit den übriggebliebenen \sand\s trennen
		    
		    my @editorarray;
		    my @editorzwischenarray = split (/\sand\s/, $datenfeld);
		    my $editor;
		    foreach $editor (@editorzwischenarray) {


#__0 rausnehmen			
			$editor =~ s/\_\_0//g;
			$editor =~ s/\\//g;
			
			unless (($editor =~ m/\,/) || ($editor =~ m/\s*\{.*\}\s*/s)) {
			    $editor =~ s/(.*)\s([\-\S]+)/$2\, $1/s;
			}

#Klammern rausnehmen

			$editor =~ s/\{//g;
			$editor =~ s/\}//g;

			push (@editorarray, $editor);

		    }
		    $datenhash{$bibtex_id}{bookeditor} = \@editorarray;
		    
		} #editor



# serieseditor 
# obwohl serieseditor ein eigenes Feld ist, soll es hier wie die Autoren und Editorenlisten gehandhabt werden, um alle Felder, die Autoren beinhalten gleich zu haben. Eigene Listen, für die kein vergleichbarer Eintrag existiert, wie etwa keyword, sollen aber als mit Semikolon getrennte Listen gespeichert werden.

		if ($schluesselfeld eq "serieseditor") {


# and das innerhalb von geschweiften Klammern steht in \and umwandeln, so dass es nicht Autorn trennt

		    while ($datenfeld =~ m/\{[^\}]*?\sand\s[^\{]*?\}/s) {
			($datenfeld =~ s/(\{[^\}]*?\s)and(\s[^\{]*?\})/$1\\and$2/gis);
		    }

#serieseditoren mit den übriggebliebenen \sand\s trennen
		    
		    my @serieseditorarray;
		    my @serieseditorzwischenarray = split (/\sand\s/, $datenfeld);
		    my $serieseditor;
		    foreach $serieseditor (@serieseditorzwischenarray) {


#__0 rausnehmen			
			$serieseditor =~ s/\_\_0//g;
			$serieseditor =~ s/\\//g;
			
			unless (($serieseditor =~ m/\,/) || ($serieseditor =~ m/\s*\{.*\}\s*/s)) {
			    $serieseditor =~ s/(.*)\s([\-\S]+)/$2\, $1/s;
			}

#Klammern rausnehmen

			$serieseditor =~ s/\{//g;
			$serieseditor =~ s/\}//g;

			push (@serieseditorarray, $serieseditor);

		    }
		    $datenhash{$bibtex_id}{serieseditor} = \@serieseditorarray;
		    
		} #serieseditor








		$datenfeld =~ s/\_\_0//g;
		$datenfeld =~ s/\\//g;
		$datenfeld =~ s/\{//g;
		$datenfeld =~ s/\}//g;
		    



# chapter und title in inbook
		if ($datenhash{$bibtex_id}{doctype} eq "inbook") { 

#		    # chapter
		    if ($schluesselfeld eq "chapter") {
			$datenhash{$bibtex_id}{title} = $datenfeld;
		    }
#		    # title
		    if ($schluesselfeld eq "title") {
			$datenhash{$bibtex_id}{book} = $datenfeld;
		    }
		}
# title sonst		
		else {
                    # title
		    if ($schluesselfeld eq "title") {
			$datenhash{$bibtex_id}{title} = $datenfeld;
		    }
                    # booktitle
		    if ($schluesselfeld eq "booktitle") {
			$datenhash{$bibtex_id}{book} = $datenfeld;
		    }
		}


# series
		if ($schluesselfeld eq "series") {
		    $datenhash{$bibtex_id}{series} = $datenfeld;
		}


# journal
		if ($schluesselfeld eq "journal") {
		    $datenhash{$bibtex_id}{journal} = $datenfeld;
		}


# keyword
		if ($schluesselfeld eq "keywords") {
		    my @keyword = split (/\;\s*/, $datenfeld);
		    $datenhash{$bibtex_id}{keyword} = \@keyword;
		}


# species
		if ($schluesselfeld eq "species") {
		    my @species = split (/\;\s*/, $datenfeld);
		    $datenhash{$bibtex_id}{species} = \@species;
		}


# pages
		if ($schluesselfeld eq "pages") {
		    if ($datenfeld =~ m/(\d+)\-(\d+)/) {
			$datenhash{$bibtex_id}{startpage} = $1;
			$datenhash{$bibtex_id}{endpage} = $2;
		    }
		    elsif ($datenfeld =~ m/(\d+)/) {
			$datenhash{$bibtex_id}{endpage} = $1;
		    }
		}


#year 
		if ($schluesselfeld eq "year") {
		    $datenfeld =~ s/\s//g;
		    $datenhash{$bibtex_id}{year} = $datenfeld;
		}


# institution
		if ($schluesselfeld eq "institution") {
		    $datenhash{$bibtex_id}{institution} = $datenfeld;
		}


# school
		if ($schluesselfeld eq "school") {
		    $datenhash{$bibtex_id}{institution} = $datenfeld;
		}


# notes
		if ($schluesselfeld eq "notes") {
		    $datenhash{$bibtex_id}{notizen} = $datenfeld;
		}


# volume
		if ($schluesselfeld eq "volume") {
		    $datenhash{$bibtex_id}{volume} = $datenfeld;
		}


# number
		if ($schluesselfeld eq "number") {
		    $datenhash{$bibtex_id}{issue} = $datenfeld;
		}


# publisher
		if ($schluesselfeld eq "publisher") {
		    $datenhash{$bibtex_id}{verlag} = $datenfeld;
		}


# address
		if ($schluesselfeld eq "address") {
		    $datenhash{$bibtex_id}{verlagort} = $datenfeld;
		}


# available
		if ($schluesselfeld eq "available") {
		    $datenhash{$bibtex_id}{available} = $datenfeld;
		}


# abstract
		if ($schluesselfeld eq "abstract") {
		    $datenhash{$bibtex_id}{abstract} = $datenfeld;
		}


# isbn
		if (($schluesselfeld eq "isbn") || ($schluesselfeld eq "issn")) {
		    $datenhash{$bibtex_id}{isbn} = $datenfeld;
		}


# affiliation
		if ($schluesselfeld eq "affiliation") {
		    $datenhash{$bibtex_id}{contactaddress} = $datenfeld;
		}


# pdffile
		if ($schluesselfeld eq "pdffile") {
		    $datenhash{$bibtex_id}{pdffile} = $datenfeld;
		}


# crossref
		if ($schluesselfeld eq "crossref") {
		    $datenhash{$bibtex_id}{crossref} = $datenfeld;
		}

#		print OUTDAT "blarrrrg $datenfeld\n";


	    }
	}
    }



    foreach $bibtex_id (sort (keys %datenhash)) {
	if (defined ($datenhash{$bibtex_id}{crossref})) {
	    my $crossref = $datenhash{$bibtex_id}{crossref};
	    if ($datenhash{$crossref}) {
		my $schluessel;
		foreach $schluessel (sort (keys (%{$datenhash{$crossref}}))) {
#		    print "$bibtex_id, $crossref\n";
		    unless ($datenhash{$bibtex_id}{$schluessel}) {
			$datenhash{$bibtex_id}{$schluessel} = $datenhash{$crossref}{$schluessel};
#			print "$bibtex_id enthält jetzt unter $schluessel den Wert: $datenhash{$bibtex_id}{$schluessel}\n";
		    }
		}
	    }
	}
    }



######################
#    foreach my $schluessel3 (sort (keys %datenhash)) {
#	print OUTDAT "\n\n$schluessel3  = \n";
#	foreach my $schluessel4 (sort (keys %{$datenhash{$schluessel3}})) { 
#	    if ($schluessel4 eq "author") {
#		foreach my $author (@{$datenhash{$schluessel3}{author}}) {
#		    print OUTDAT "author: $author\|\|\n";
#		}
#	    }
#	    else {
#		print OUTDAT "$schluessel4: \-\- $datenhash{$schluessel3}{$schluessel4}\|\|\n";
#	    }
#	}
#    }
#####################		



#    close OUTDAT;
    my $datenhashref = \%datenhash;
    return $datenhashref;

}

return 1;











