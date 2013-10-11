&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use CGI ':standard';
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

# use FindBin;
# use lib "$FindBin::Bin/..";
# use Environment;


my $configFile = SETUPFILE;
my $setup;


my ($command,$style) = split("-",$ENV{'QUERY_STRING'});

$command = "" unless defined $command;
$style   = ""  unless defined $style;

#   my $isSetup  = $command eq "setup";
  my $isDataValidate = $command eq "DataValidate";
  my $isTriggerValidate = $command eq "TriggerValidate";
#   my $isErrors = $command eq "errors";


initPage();





sub getDataValidate {
print <<EOF;
  <input type="button" class="stdbutton" onClick="getdataprint('../xml-db/get.pl?Nxyter-0x3800-DataValidate','content',false);" value="Refresh">
  <script language="javascript">setTimeout("getdataprint('../xml-db/get.pl?Nxyter-0x3800-DataValidate','content',false)",400);</script>
  <div id="content"></div>
EOF
  }

sub getTriggerValidate {
print <<EOF;
  <input type="button" class="stdbutton" onClick="getdataprint('../xml-db/get.pl?Nxyter-0x3800-TriggerValidate','content',false);" value="Refresh">
  <script language="javascript">setTimeout("getdataprint('../xml-db/get.pl?Nxyter-0x3800-TriggerValidate','content',false)",400);</script>
  <div id="content"></div>
EOF
  }
  
  

sub initPage {
  
  print <<EOF;
<HTML>
<HEAD>
<title>NXyter Status</title>
<link href="../layout/styles.css" rel="stylesheet" type="text/css"/>
<link href="blue.css" rel="stylesheet" title="Light Blue" type="text/css"/>
EOF
  printJavaScripts();
  print qq(
</HEAD>
<BODY>
<h2>NXyter Status</h2>
<div id="overview">
<div class="header">
  <span class=").($isDataValidate?"selected":"inactive").qq("><a href="?DataValidate">DataVal.</a></span>
  <span class=").($isTriggerValidate?"selected":"inactive").qq("><a href="?TriggerValidate">TrigVal.</a></span>
</div>

);
if($isSetup) {
  print '<div class="content">';
  print '</div>';
  }
if ($isDataValidate) {
  getDataValidate();
  }
if ($isTriggerValidate) {
  getTriggerValidate();
  }
print <<EOF ;

</div>
<div id="debugpane">
<div class="header">Debug Output</div>
debug text
</div>


</BODY>
</HTML>
EOF
}




sub printJavaScripts {

####### javascript function land ################

  print <<EOF;
<script language="javascript" src="scripts.js"></script>

<script language="javascript">

</script>
EOF
}



