&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use CGI ':standard';
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

use lib qw|../commands htdocs/commands|;
use xmlpage;

my $page;

$page->{title} = "Nxyter Register";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "DataValid";
$setup[0]->{cmd}     = "Nxyter-0x3800-DataValidate";
$setup[0]->{period}  = -1;
$setup[0]->{address} = 1;


$setup[1]->{name}    = "TrigValid";
$setup[1]->{cmd}     = "Nxyter-0x3800-TriggerValidate";
$setup[1]->{period}  = -1;
$setup[1]->{address} = 1;

$setup[2]->{name}    = "OtherStuff";
$setup[2]->{cmd}     = "Nxyter-0x3800-TriggerValidate";
$setup[2]->{period}  = -1;
$setup[2]->{generic} = 1;

xmlpage::initPage(\@setup,$page);
 

 

1;


