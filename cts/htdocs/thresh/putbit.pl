&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";



use HADES::TrbNet;
use Data::Dumper;

 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }

my ($board,$addr,$op,$value) = split('-',$ENV{'QUERY_STRING'}); 

if(!defined $board || !defined $addr || !defined $op || !defined $value) {exit -1;}
$board = hex($board);
$addr = hex($addr);
$value = hex($value);

my $mode = 0;
$mode = 1 if($op eq "set") ;
$mode = 2 if($op eq "clr") ;
exit -1   if $mode == 0;


trb_register_modify($board,$addr,$mode,$value,0);
  
exit 1;