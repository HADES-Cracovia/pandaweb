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

#address should be 0xfe4d

my @setup;
$setup[0]->{name}    = "Status";
$setup[0]->{cmd}     = "JtagController-0xf308-JtagStatus";
$setup[0]->{refresh} = 1;
$setup[0]->{period}  = 0;

$setup[1]->{name}    = "CommonCtrl";
$setup[1]->{cmd}     = "JtagController-0xf308-JtagCommonControl";
$setup[1]->{refresh} = 1;
$setup[1]->{period}  = 0;

$setup[2]->{name}    = "Control";
$setup[2]->{cmd}     = "JtagController-0xf308-JtagControl";
$setup[2]->{refresh} = 1;
$setup[2]->{period}  = 0;

xmlpage::initPage(\@setup,$page);
 

 

1;


