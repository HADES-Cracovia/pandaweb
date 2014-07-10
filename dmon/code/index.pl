#!/usr/bin/perl -w
use CGI::Carp qw(fatalsToBrowser);

my $PATH = "";
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Content-type: text/html\r\n\r\n";
  $PATH = "htdocs/dmon/";
  }
else {
  print "Content-type: text/html\n\n";
  }



print qq$<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Monitoring Main Control Interface</title>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<link href="code/indexstyles.css" rel="stylesheet" type="text/css"/>
</head>
<body class="index" style="position:relative;background:#d8e8f8;width:750px;margin:auto;padding:120px 0 40px 0">
<script type="text/javascript">
function openwin(url) {
	win = window.open(url,"window1","width=600,height=400,scrollbars=no,status=no,location=no,menubar=no,resizable=no,titlebar=no,toolbar=no");
	win.focus();
	}
</script>
<div style="position:fixed;left:0;top:0;width:100%;height:40px;background:#d8e8f8;box-shadow:none;"></div>
<h1 style="position:fixed;top:5px;left:0px;width:100%;display:block;text-align:center;margin:26px 0 0px 0">DAQ Monitoring</h1>




<div class="linkbox" style="width:730px;"><h4>Main</h4><ul>
<li style="width:600px;"><a href="code/monitor.pl?1-window-QA" style="color:#d33">Tactical Overview (the central screen)</a></li>
</ul></div>



$;


print "<h3 style=\"clear:both;padding-top:30px;\">All available options</h3><ul class=\"optionlist\">\n";
my @o = qx(ls -1 $PATH*.htt);
foreach my $a (@o) {
  if ($a =~ m%$PATH(\w+).htt%) {
    print "<li><a href=\"code/monitor.pl?2-window-$1\">$1</a></li>\n";</li>
		}
	}
print "</ul><br>\n";



#<h3 style="padding-top:30px;clear:both">Help</h3>
#To select the information you want to have, specify any number of the options listed below, separated with '-' after the \"monitor.cgi?\".<p/>
#<ul><li>The first option for monitor.cgi may be a number specifying the update rate in seconds.</li>
#<li>The first or second option may be \"window\" to open the information in a pop-up with no toolbars and proper sizes. Note that only the first information box is used to determine the size - i.e. if there are two boxes to be shown, you  have to resize the window by hand. One remark: to work properly, you have to set all dom.disable_window_open* options in about:config to false.</li>
#<li>Everything is tested in the latest version (5 and above, not 2 or 3!) of the Firefox browser - there will be no support for any other kind of html-viewer.</li>
#</ul>
#<h5>Hints</h5>
#<ul><li>Window background will turn red if no update is possible. </li>
#<li>If you see a message "Server Error", press F5. </li>
#<li>If you want to stop updating, press Esc. </li>
#<li>To restart updating, press F5.</li>
#<li>Zoom in and out with Ctrl++ and Ctrl+-, normal zoom with Ctrl+0.</li>
#</ul>
#<h5>Examples</h5>
#<ul><li><a href="monitor.cgi?logfile-busy">monitor.cgi?logfile-busy</a></li>
#<li><a href="monitor.cgi?2-PTrates-busy">monitor.cgi?PTrates-busy</a></li>
#<li><a href="monitor.cgi?10-window-MDCRates">monitor.cgi?10-MDCRates</a></li>
#</ul>
print qq$
</body>
</html>
$;
