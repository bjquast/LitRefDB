package Html;

use strict;
use warnings;
use CGI qw(:standart);
use CGI::Carp qw(fatalsToBrowser);


#this modul is the central point to print the header, menu and foot for all html pages
# &Html::header($sitename, $title, $caption);


# Dieses modul soll für alle skripte den header, das menu und den fuss für die html-seiten liefern
# &Html::header($sitename, $title, $caption);




sub header {
# prints the header for all html-sites. usage: Html::header(httppath, caption)
    my $httppath = shift;
    my $title = shift;

    unless ($title) {
	$title = "Reference Database";
    }

#    my $httppath = shift;
#    my $caption = shift;


#    my $sitename = "Reference Database";
#    my $title = "searchform";


    
    print "Content-type: text/html\r\n\r\n";


print <<"HEAD";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN"
"http://www.w3.org/TR/html4/loose.dtd">
	
<html>
  <head>
    <title>$title</title>
    <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-15">
    <meta name="GENERATOR" content="reference database">
    <meta name="author" content="Bj&ouml;rn Quast">
<style type="text/css">
body { font-family:Nimbus,Helvetica,Verdana,Arial,sans-serif; font-size:12px; color:black; margin:5;}
td { font-family:Nimbus,Helvetica,Verdana,Arial,sans-serif; font-size:12px; color:black; }
a:link { color:#9C2A37; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; }
a:visited { color:#525252; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; }
h1 { font-size:1.21em; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; }
h2 { font-size:1.01em; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; }
h3 { font-size:1.01em; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; }
h4 { font-size:1.01em; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; }
dt { font-size:1.01em; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; }
dd { font-size:1.01em; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; text-align:justify; }
p { font-size:1.01em; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; text-align:justify;}
li { font-size:1.01em; font-familiy:Nimbus,Helvetica,Verdana,Arial,sans-serif; }
select { font-family:Nimbus,Helvetica,Verdana,Arial,sans-serif; font-size:1.01em; color:black; }
input { font-family:Nimbus,Helvetica,Verdana,Arial,sans-serif; font-size:1.01; color:black; }

div#query {
  font-size: 1.01em;
  float: left; width: 40em;
  margin: 0; padding: 0;
  border: 0px;
}

div#menu {
  font-size: 1.01em;
  margin: 5; padding: 0;
  border: 0px;
}

div#resultmenu {
  font-size: 1.01em;
  margin: 5; padding: 0;
  border: 0px;
}

div#resulthead {
  position:absolute;
  top:0em; 
  left:0em;
  height:5em;
  width:100%;
  font-size: 1.01em;
  margin: 5; padding: 0;
  border: 0px;
  background-color: white;
}


html>body #resulthead {  /* nur fuer moderne Browser! */
  position: fixed;
}


div#resulttable {
  margin-top:5em;
}

div#detailhead {
  position:absolute;
  top:0em; 
  left:0em;
  height:3em;
  width:100%;
  font-size: 1.01em;
  margin: 0; padding: 0;
  border: 0px;
  background-color: white;
}


html>body #detailhead {  /* nur fuer moderne Browser! */
  position: fixed;
}


div#detailtable {
  margin-top:3em;
}


</style>

  </head>
      
HEAD

}


sub body {
    print "\n\<body\>\n";
}




sub frame {
    print <<"FRAME";


	<frameset cols="300, *">
	                <frame src="searchform.pl" name="search" marginwidth="5" marginheight="5" frameborder="1">
	        <frameset rows="50%, *">
		        <frame src="central.pl\?action=search" name="results" marginwidth="5" marginheight="5" frameborder="1">
			<frame src="details.pl" name="details" marginwidth="5" marginheight="5" frameborder="1">
		</frameset>
	</frameset>

FRAME

}



sub resultmenu {
# prints the resultmenu for all html-sites. usage: Html::resultmenu()


#    print "<hr>\n";

    print "<div id\=\"resultmenu\">\n";


print <<'SELECTBOX';
<b style="font-size:medium">action: 
    <select name="action" size=1>
    <option value="mark" selected>mark all</option>
    <option value="unmark">delete markings</option>
    <option value="details">show details</option>
    <option value="delete">delete marked datasets</option>
    <option value="save">export marked datasets</option>
    </select>
</b>
SELECTBOX

    print "</div>\n";

}



sub foot {
# prints a short foot for the html-sites and thus, closes the html and body-tags opened by html.header. usage: Html::foot() 
    print "</body>\n</html>\n";
}


sub dbquerytest {
    my $query =shift;
    my $starttime = time();
    print "<p>$starttime $query</p>";

}

	  
return 1;
    










