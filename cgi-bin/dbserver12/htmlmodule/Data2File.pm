package Data2File;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);
use DBI;
use Encode;


  
sub risfilesave {

    my $ergebnishashref = shift;
    my $eigene = shift;
    my $notext = shift;
#    my $datafilehandle = shift;
    my $datastring;
    my %ergebnishash = %$ergebnishashref;


    my $element;    
    my $docschluessel;
    my $feldschluessel;
    my $zeilen;
    
    my $htmlaccessname = $ENV{REMOTE_USER};
#    print "<p>username: $htmlaccessname</p>\n";


#    my $stdout = select ($datafilehandle);


    foreach $element (sort{$a<=>$b} (keys (%ergebnishash))) {

	unless (($eigene eq "on") && ($htmlaccessname ne $ergebnishash{$element}{owner})) { 


	    if ($ergebnishash{$element}{doctype}) {
		# doctype und Begin des Datensatzes
		
		if ($ergebnishash{$element}{doctype} =~ s/article/JOUR/i){}
		elsif ($ergebnishash{$element}{doctype} =~ s/incollection/SER/i){}
		elsif ($ergebnishash{$element}{doctype} =~ s/inbook/CHAP/i){}
		elsif ($ergebnishash{$element}{doctype} =~ s/book/BOOK/i){}
		elsif ($ergebnishash{$element}{doctype} =~ s/unpublished/UNPB/i){}
		elsif ($ergebnishash{$element}{doctype} =~ s/phdthesis/THES/i){}
		elsif ($ergebnishash{$element}{doctype} =~ s/inproceedings/CONF/i){}
		else {
		    $ergebnishash{$element}{doctype} = "GEN";
		}
		
		$datastring.= "\r\nTY  - $ergebnishash{$element}{doctype}\r\n";
		
		
		# author
		my @authorlist;
		my $author;
		if ($ergebnishash{$element}{author}) {
		    @authorlist = @{$ergebnishash{$element}{author}};
		    foreach $author (@authorlist) {
			$author = encode("ibm850", (decode("iso-8859-15", $author)));
			$datastring.= "A1  - $author\r\n";
		    }
		}
		
		# year
		if ($ergebnishash{$element}{year}) {
		    $ergebnishash{$element}{year} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{year})));
		    $datastring.= "Y1  - $ergebnishash{$element}{year}\r\n";
		}
		
		# title
		if ($ergebnishash{$element}{title}) {
		    $ergebnishash{$element}{title} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{title})));
		    $datastring.= "T1  - $ergebnishash{$element}{title}\r\n";
		}
		
		
		#journal
		if ($ergebnishash{$element}{journal}) {
		    $ergebnishash{$element}{journal} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{journal})));
		    $datastring.= "JF  - $ergebnishash{$element}{journal}\r\n";
		}
		
		
		# issue
		if ($ergebnishash{$element}{issue}) {
		    $ergebnishash{$element}{issue} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{issue})));
		    $datastring.= "IS  - $ergebnishash{$element}{issue}\r\n";
		}
		
		# volume
		if ($ergebnishash{$element}{volume}) {
		    $ergebnishash{$element}{volume} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{volume})));
		    $datastring.= "VL  - $ergebnishash{$element}{volume}\r\n";
		}
		
		#book
		if ($ergebnishash{$element}{book}) {
		    $ergebnishash{$element}{book} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{book})));
		    $datastring.= "T2  - $ergebnishash{$element}{book}\r\n";
		}
		
		# series
		if ($ergebnishash{$element}{series}) {
		    $ergebnishash{$element}{series} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{series})));
		    $datastring.= "T3  - $ergebnishash{$element}{series}\r\n";
		}
		
		
		# bookeditor
		my @bookeditorlist;
		my $bookeditor;
		if ($ergebnishash{$element}{bookeditor}) {
		    @bookeditorlist = @{$ergebnishash{$element}{bookeditor}};
		    foreach $bookeditor (@bookeditorlist) {
			$bookeditor = encode("ibm850", (decode("iso-8859-15", $bookeditor)));
			$datastring.= "A2  - $bookeditor\r\n";
		    }
		}
		
		
		# serieseditor
		my @serieseditorlist;
		my $serieseditor;
		if ($ergebnishash{$element}{serieseditor}) {
		    @serieseditorlist = @{$ergebnishash{$element}{serieseditor}};
		    foreach $serieseditor (@serieseditorlist) {
			$serieseditor = encode("ibm850", (decode("iso-8859-15", $serieseditor)));
			$datastring.= "A3  - $serieseditor\r\n";
		    }
		}
		
		
		# isbn
		if ($ergebnishash{$element}{isbn}) {
		    $ergebnishash{$element}{isbn} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{isbn})));
		    $datastring.= "SN  - $ergebnishash{$element}{isbn}\r\n";
		}
		
		
		
		# verlag
		if ($ergebnishash{$element}{verlag}) {
		    $ergebnishash{$element}{verlag} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{verlag})));
		    $datastring.= "PB  - $ergebnishash{$element}{verlag}\r\n";
		}
		
		
		# verlagort
		if ($ergebnishash{$element}{verlagort}) {
		    $ergebnishash{$element}{verlagort} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{verlagort})));
		    $datastring.= "CY  - $ergebnishash{$element}{verlagort}\r\n";
		}
		
		# institution
		if ($ergebnishash{$element}{institution}) {
		    $ergebnishash{$element}{institution} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{institution})));
		    $datastring.= "PB  - $ergebnishash{$element}{institution}\r\n";
		}
		
		
		# startpage
		if ($ergebnishash{$element}{startpage}) {
		    $ergebnishash{$element}{startpage} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{startpage})));
		    $datastring.= "SP  - $ergebnishash{$element}{startpage}\r\n";
		}
		
		
		# endpage
		if ($ergebnishash{$element}{endpage}) {
		    $ergebnishash{$element}{endpage} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{endpage})));
		    $datastring.= "EP  - $ergebnishash{$element}{endpage}\r\n";
		}
		
		
		#abstract
#		if ($htmlaccessname eq $ergebnishash{$element}{owner}) {
		unless ($notext eq "on") {
		    if ($ergebnishash{$element}{abstract}) {
		    $ergebnishash{$element}{abstract} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{abstract})));
			$datastring.= "N2  - $ergebnishash{$element}{abstract}\r\n";
		    }
		}
		
		
		# keyword
		my @keywordlist;
		my $keyword;
		if ($ergebnishash{$element}{keyword}) {
		    @keywordlist = @{$ergebnishash{$element}{keyword}};
		    foreach $keyword (@keywordlist) {
			$keyword = encode("ibm850", (decode("iso-8859-15", $keyword)));
			$datastring.= "KW  - $keyword\r\n";
		    }
		}
		
		
		# species
		my @specieslist;
		my $speciesstring;
		if ($ergebnishash{$element}{species}) {
		    @specieslist = @{$ergebnishash{$element}{species}};
		    $speciesstring = join ("; ", @specieslist);
		    $speciesstring = encode("ibm850", (decode("iso-8859-15", $speciesstring)));
		    $datastring.= "M3  - $speciesstring\r\n";
		}
		
		
		if (($htmlaccessname eq $ergebnishash{$element}{owner}) && ($notext ne "on")) {
		    # notizen
		    if ($ergebnishash{$element}{notizen}) {
		    $ergebnishash{$element}{notizen} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{notizen})));
			$datastring.= "N1  - $ergebnishash{$element}{notizen}\r\n";
		    }
		}
		
		# pdffile
		if ($ergebnishash{$element}{pdffile}) {
		    $ergebnishash{$element}{pdffile} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{pdffile})));
		    $datastring.= "L1  - $ergebnishash{$element}{pdffile}\r\n";
		}
		
		# available
		if ($ergebnishash{$element}{available}) {
		    $ergebnishash{$element}{available} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{available})));
		    $datastring.= "AV  - $ergebnishash{$element}{available}\r\n";
		}
		
		# contactaddress
		if ($ergebnishash{$element}{contactaddress}) {
		    $ergebnishash{$element}{contactaddress} = encode("ibm850", (decode("iso-8859-15", $ergebnishash{$element}{contactaddress})));
		    $datastring.= "AD  - $ergebnishash{$element}{contactaddress}\r\n";
		}
		
		$datastring.= "ER  - \r\n";
		
	    }
	    
	    
	} 
    }	
    
    $datastring.= "\r\n";

#    select ($stdout);

    return $datastring;

}



sub bibtexfilesave {

    my $ergebnishashref = shift;
    my $eigene = shift;
    my $notext = shift;
#    my $datafilehandle = shift;
    my $datastring;

    my %ergebnishash = %$ergebnishashref;
 
    my $element;    
    my $docschluessel;
    my $feldschluessel;
    my $zeilen;
    
    my $htmlaccessname = $ENV{REMOTE_USER};
#    print "<p>username: $htmlaccessname</p>\n";


    my %bibtexkeyshash;
    my $zwischenkey;

    my @outputarray;

    foreach $element (sort{$a<=>$b} (keys (%ergebnishash))) {


	unless (($eigene eq "on") && ($htmlaccessname ne $ergebnishash{$element}{owner})) { 
	    
# Schluessel für Eintrag erstellen


	    if ($ergebnishash{$element}{author}) {
		my $firstauthor = ${$ergebnishash{$element}{author}}[0];
		$firstauthor =~ s/\s*(\w+)\,*.*/$1/;
		$zwischenkey = $firstauthor;
		if ($ergebnishash{$element}{year}) {
		    $zwischenkey .= $ergebnishash{$element}{year};
		} 
	    } 
	    
	    
	    else {
		$zwischenkey = "anonymous".$element;
	    }
	    
	    
	    my $asciicode = 97;
	    my $bibtexkey = $zwischenkey;
	    while ($bibtexkeyshash{$bibtexkey}) {
		my $buchstabe = chr ($asciicode);
		
		$bibtexkey = $zwischenkey.$buchstabe;
		$asciicode++; 
		if ($asciicode > 122) {
		    $asciicode = 97;
		    $zwischenkey = $zwischenkey.$buchstabe;
		    $bibtexkey = $zwischenkey.$buchstabe;
		}
	    }
	    $bibtexkeyshash{$bibtexkey} = $bibtexkey;
	    
	    
	    push (@outputarray, "\@$ergebnishash{$element}{doctype}\{$bibtexkey");
	    
	    
#author
	    if ($ergebnishash{$element}{author}) { 
		my @authorlist = @{$ergebnishash{$element}{author}};
		
#lex Andres	

	foreach my $zwauthor (@authorlist)	{
		if ($zwauthor =~ m/\,/s) 
			{
				$zwauthor =~ s/(.*)\,(.*)/$2 $1/s;
				$zwauthor =~ s/\ +/\ /s;
				$zwauthor =~ s/^\ //s;
			}
	}	
		
		my $authorstring = join ( " and ", @authorlist);
		push (@outputarray, "\,\n\tauthor = \{$authorstring\}");
	    }
	    
	    
#title
	    $ergebnishash{$element}{doctype} = lc($ergebnishash{$element}{doctype});
	    
	    if ($ergebnishash{$element}{doctype} eq "inbook") {
		if ($ergebnishash{$element}{title}) { 
		    push (@outputarray, "\,\n\tchapter = \{\{$ergebnishash{$element}{title}\}\}");
		}
		if ($ergebnishash{$element}{book}) { 
		    push (@outputarray, "\,\n\ttitle = \{\{$ergebnishash{$element}{book}\}\}");
		}
	    }
	    elsif ($ergebnishash{$element}{doctype} eq "incollection") {
		if ($ergebnishash{$element}{title}) { 
		    push (@outputarray, "\,\n\ttitle = \{\{$ergebnishash{$element}{title}\}\}");
		}
		if ($ergebnishash{$element}{book}) { 
		    push (@outputarray, "\,\n\tbooktitle = \{\{$ergebnishash{$element}{book}\}\}");
		}
	    }
	    elsif ($ergebnishash{$element}{doctype} eq "inproceedings") {
		if ($ergebnishash{$element}{title}) { 
		    push (@outputarray, "\,\n\ttitle = \{\{$ergebnishash{$element}{title}\}\}");
		}
		if ($ergebnishash{$element}{book}) { 
		    push (@outputarray, "\,\n\tbooktitle = \{\{$ergebnishash{$element}{book}\}\}");
		}
	    }
	    elsif ($ergebnishash{$element}{doctype} eq "article") {
		if ($ergebnishash{$element}{title}) { 
		    push (@outputarray, "\,\n\ttitle = \{\{$ergebnishash{$element}{title}\}\}");
		}
		if ($ergebnishash{$element}{book}) {
		    push (@outputarray, "\,\n\tbooktitle = \{\{$ergebnishash{$element}{book}\}\}");
		}
	    }
	    else {
		if ($ergebnishash{$element}{title}) { 
		    push (@outputarray, "\,\n\ttitle = \{\{$ergebnishash{$element}{title}\}\}");
		}
		if ($ergebnishash{$element}{book}) {
		    push (@outputarray, "\,\n\tbooktitle = \{\{$ergebnishash{$element}{book}\}\}");
		}
	    }
	    
	    
	    
	    
	    # year
	    if ($ergebnishash{$element}{year}) {
		push (@outputarray, "\,\n\tyear = \{$ergebnishash{$element}{year}\}");
	    }
	    
	    
	    #journal
	    if ($ergebnishash{$element}{journal}) {
		push (@outputarray, "\,\n\tjournal = \{\{$ergebnishash{$element}{journal}\}\}");
	    }
	    
	    
	    # issue
	    if ($ergebnishash{$element}{issue}) {
		push (@outputarray, "\,\n\tnumber = \{$ergebnishash{$element}{issue}\}");
	    }
	    
	    # volume
	    if ($ergebnishash{$element}{volume}) {
		push (@outputarray, "\,\n\tvolume = \{$ergebnishash{$element}{volume}\}");
	    }
	    
	    
	    # series
	    if ($ergebnishash{$element}{series}) {
		push (@outputarray, "\,\n\tseries = \{\{$ergebnishash{$element}{series}\}\}");
	    }
	    
	    
	    # publisher
	    if ($ergebnishash{$element}{verlag}) { 
		push (@outputarray, "\,\n\tpublisher = \{\{$ergebnishash{$element}{verlag}\}\}");
	    }
	    
	    # address
	    if ($ergebnishash{$element}{verlagort}) { 
		push (@outputarray, "\,\n\taddress = \{\{$ergebnishash{$element}{verlagort}\}\}");
	    }
	    
	    
	    
	    # isbn
	    if ($ergebnishash{$element}{isbn}) {
		push (@outputarray, "\,\n\tisbn = \{$ergebnishash{$element}{isbn}\}");
	    }
	    
	    
	    # institution
	    if ($ergebnishash{$element}{institution}) {
		push (@outputarray, "\,\n\tinstitution = \{\{$ergebnishash{$element}{institution}\}\}");
	    }
	    
	    
#	    if ($htmlaccessname eq $ergebnishash{$element}{owner}) {
	    unless ($notext eq "on") {
		#abstract

		if ($ergebnishash{$element}{abstract}) {
		    push (@outputarray, "\,\n\tabstract = \{\{$ergebnishash{$element}{abstract}\}\}");
		}
	    }
	    
	    
	    # keyword
	    my @keywordlist;
	    my $keywordstring;
	    if ($ergebnishash{$element}{keyword}) {
#	    print "\nBLARG$ergebnishash{$element}{keyword}BLARG\n";
#	    print "\nBLARG${$ergebnishash{$element}{keyword}}[0]BLARG\n";
		@keywordlist = @{$ergebnishash{$element}{keyword}};
		$keywordstring = join  ("\; ", @keywordlist);
		push (@outputarray, "\,\n\tkeywords = \{$keywordstring\}");
		
	    }
	    
	    
	    # species
	    my @specieslist;
	    my $speciesstring;
	    if ($ergebnishash{$element}{species}) {
#	    print "\nBLARG$ergebnishash{$element}{species}\n";
		@specieslist = @{$ergebnishash{$element}{species}};
		$speciesstring = join ("; ", @specieslist);
		push (@outputarray, "\,\n\tspecies = \{$speciesstring\}");
	    }
	    
	    
	    if (($htmlaccessname eq $ergebnishash{$element}{owner}) && ($notext ne "on")) {
		# notizen
		if ($ergebnishash{$element}{notizen}) {
		    push (@outputarray, "\,\n\tnotes = \{\{$ergebnishash{$element}{notizen}\}\}");
		}
	    }
	    
	    # pdffile
	    if ($ergebnishash{$element}{pdffile}) {
		push (@outputarray, "\,\n\tpdffile = \{$ergebnishash{$element}{pdffile}\}");
	    }
	    
	    # available
	    if ($ergebnishash{$element}{available}) {
		push (@outputarray, "\,\n\tavailable = \{$ergebnishash{$element}{available}\}");
	    }

	    # contactaddress
	    if ($ergebnishash{$element}{contactaddress}) {
		push (@outputarray, "\,\n\taffiliation = \{\{$ergebnishash{$element}{contactaddress}\}\}");
	    }
	    
	    
	    
	    
	    # pages 
	    if (($ergebnishash{$element}{startpage}) && ($ergebnishash{$element}{endpage})) {
		my $pages  = "$ergebnishash{$element}{startpage}\-$ergebnishash{$element}{endpage}";
		push (@outputarray, "\,\n\tpages = \{$pages\}");
	    }
	    elsif (($ergebnishash{$element}{startpage}) && (not ($ergebnishash{$element}{endpage}))) { 
		push (@outputarray, "\,\n\tpages = \{$ergebnishash{$element}{startpage}\}");
	    }
	    elsif (($ergebnishash{$element}{endpage}) && (not ($ergebnishash{$element}{startpage}))) { 
		push (@outputarray, "\,\n\tpages = \{$ergebnishash{$element}{endpage}\}");
	    }
	    
	    
	    
	    # editor
	    if ($ergebnishash{$element}{bookeditor}) { 
		my @editorlist;
#	    print "\nBLARG$ergebnishash{$element}{bookeditor}BLARG\n";
#	    print "\nBLARG${$ergebnishash{$element}{bookeditor}}[0]BLARG\n";
		@editorlist = @{$ergebnishash{$element}{bookeditor}};
		my $editorstring = join (" and ", @editorlist);
		push (@outputarray, "\,\n\teditor = \{$editorstring\}");
	    }
	    
	    # serieseditor
	    if (defined ($ergebnishash{$element}{serieseditor})) {
#	    print "bllllaaarrrrrg$ergebnishash{$element}{serieseditor}\n@{$ergebnishash{$element}{serieseditor}}\n";
		
		my @editorlist;
		@editorlist = @{$ergebnishash{$element}{serieseditor}}; 
		my $editorstring = join (" and ", @editorlist);
		push (@outputarray, "\,\n\tserieseditor = \{$editorstring\}");
	    }
	    
	    
	    
	    push (@outputarray, "\n\}\n\n");
	    
	} # unless	
    } # foreach keys
    

#    my $stdout = select ($datafilehandle);


    my $printline;
    foreach $printline (@outputarray) {
	$printline =~ s/\"/\\textquotedbl /g; 
	$printline =~ s/\&/\\\&/g;

	$printline =~ s/\<i\>/\{\\em /gi; 
	$printline =~ s/\<\/i\>/\}/gi;
 
#	$printline =~ s/\!/\\\!/g;
#	$printline =~ s/\§/\\\§/g;
#	$printline =~ s/\$/\\\$/g;
#	$printline =~ s/\%/\\\%/g;
#	$printline =~ s/\//\\\//g;
#	$printline =~ s/\(/\\\(/g;
#	$printline =~ s/\)/\\\)/g;
#	$printline =~ s/\?/\\\?/g;
#	$printline =~ s/([\!\§\$\%\&\/\(\)\?])/$1/g;
	$datastring.= $printline;
    }
    
    $datastring.= "\n";

#    select $stdout;

    return $datastring;

}





return 1;











































