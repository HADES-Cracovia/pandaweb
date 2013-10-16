&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use CGI ':standard';
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

use lib qw|../commands htdocs/commands|;
use xmlpage;

my $page;

$page->{title} = "TrbNet Status Register";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "StatusRegisters";
$setup[0]->{cmd}     = "TrbNet-0xffff-StatusRegisters";
$setup[0]->{refresh} = 1;
$setup[0]->{period}  = 10000;

$setup[1]->{name}    = "BoardInfo";
$setup[1]->{cmd}     = "TrbNet-0xffff-BoardInformation";
$setup[1]->{refresh} = 1;
$setup[1]->{period}  = 0;


xmlpage::initPage(\@setup,$page);
 

 

1;


