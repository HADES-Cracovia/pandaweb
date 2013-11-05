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

$setup[2]->{name}    = "TriggerHandler";
$setup[2]->{cmd}     = "Nxyter-0x3800-TriggerHandler";
$setup[2]->{period}  = -1;
$setup[2]->{address} = 1;

$setup[3]->{name}    = "Testpulse";
$setup[3]->{cmd}     = "Nxyter-0x3800-TestPulse";
$setup[3]->{period}  = -1;
$setup[3]->{address} = 1;

$setup[4]->{name}    = "DataReceiver";
$setup[4]->{cmd}     = "Nxyter-0x3800-DataReceiver";
$setup[4]->{period}  = -1;
$setup[4]->{address} = 1;

$setup[5]->{name}    = "I2CRegister";
$setup[5]->{cmd}     = "Nxyter-0x3800-NxyterI2C";
$setup[5]->{period}  = -1;
$setup[5]->{address} = 1;

$setup[6]->{name}    = "OtherStuff";
$setup[6]->{cmd}     = "Nxyter-0x3800-TriggerValidate";
$setup[6]->{period}  = -1;
$setup[6]->{generic} = 1;

xmlpage::initPage(\@setup,$page);
 

 

1;


