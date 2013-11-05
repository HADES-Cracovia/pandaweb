&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use CGI ':standard';
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

use lib qw|../commands htdocs/commands|;
use xmlpage;

my $page;

$page->{title} = "MVD Read-out Controller Register";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "RocStatus";
$setup[0]->{cmd}     = "Mvd-0xfe4d-RocStatus";
$setup[0]->{period}  = 5000;
$setup[0]->{address} = 1;

$setup[1]->{name}    = "RocStatus";
$setup[1]->{cmd}     = "Mvd-0xfe4d-RocStatus";
$setup[1]->{period}  = -1;
$setup[1]->{generic} = 1;

xmlpage::initPage(\@setup,$page);
 

 

1;


