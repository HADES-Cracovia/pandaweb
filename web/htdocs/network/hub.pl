&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use CGI ':standard';
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

use lib qw|../commands htdocs/commands|;
use xmlpage;

my $page;

$page->{title} = "Hub Status Register";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "BasicStatus";
$setup[0]->{cmd}     = "Hub-0xfffe-BasicStatus";
$setup[0]->{period}  = -1;
$setup[0]->{address} = 1;

$setup[1]->{name}    = "Status";
$setup[1]->{cmd}     = "Hub-0xfffe-Status";
$setup[1]->{period}  = -1;
$setup[1]->{address} = 1;


$setup[2]->{name}    = "Config";
$setup[2]->{cmd}     = "Hub-0xfffe-Config";
$setup[2]->{period}  = -1;
$setup[2]->{address} = 1;

xmlpage::initPage(\@setup,$page);
 

 

1;


