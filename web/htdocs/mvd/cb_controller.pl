&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use CGI ':standard';
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

use lib qw|../commands htdocs/commands|;
use xmlpage;

my $page;

$page->{title} = "Converter Board Controller Register";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "Status";
$setup[0]->{cmd}     = "CbController-0xd002-CbStatus";
$setup[0]->{period}  = 1000;
$setup[0]->{address} = 1;

$setup[1]->{name}    = "SpiRam";
$setup[1]->{cmd}     = "CbController-0xd002-CbSpiRam";
$setup[1]->{period}  = 1000;
$setup[1]->{address} = 1;

$setup[2]->{name}    = "UcRegs";
$setup[2]->{cmd}     = "CbController-0xd002-CbUcRegs";
$setup[2]->{period}  = 1000;
$setup[2]->{address} = 1;

xmlpage::initPage(\@setup,$page);
 

 

1;



