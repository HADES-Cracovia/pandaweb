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
$setup[0]->{refresh} = 1;
$setup[0]->{period}  = 0;

$setup[1]->{name}    = "TrigValid";
$setup[1]->{cmd}     = "Nxyter-0x3800-TriggerValidate";
$setup[1]->{refresh} = 1;
$setup[1]->{period}  = 0;

xmlpage::initPage(\@setup,$page);
 

 

1;


