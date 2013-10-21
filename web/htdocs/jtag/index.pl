&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use CGI ':standard';
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);

use lib qw|../commands htdocs/commands|;
use xmlpage;

my $page;

$page->{title} = "Jtag Controller Register";
$page->{link}  = "../";

my @setup;
$setup[0]->{name}    = "Status";
$setup[0]->{cmd}     = "JtagController-0xfe4d-JtagStatus";
$setup[0]->{period}  = 5000;

$setup[1]->{name}    = "CommonCtrl";
$setup[1]->{cmd}     = "JtagController-0xfe4d-JtagCommonControl";
$setup[1]->{period}  = -1;

$setup[2]->{name}    = "Control";
$setup[2]->{cmd}     = "JtagController-0xfe4d-JtagControl";
$setup[2]->{period}  = -1;

xmlpage::initPage(\@setup,$page);
 

 

1;


