&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use CGI ':standard';
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

use lib qw|../commands htdocs/commands|;
use xmlpage;

my @setup;
$setup[0]->{name}    = "DataValid";
$setup[0]->{cmd}     = "Nxyter-0x3800-DataValidate";
$setup[0]->{refresh} = 1;
$setup[0]->{period}  = 0;

$setup[1]->{name}    = "TrigValid";
$setup[1]->{cmd}     = "Nxyter-0x3800-TriggerValidate";
$setup[1]->{refresh} = 1;
$setup[1]->{period}  = 0;

xmlpage::initPage(\@setup);
 

 

1;





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
  
