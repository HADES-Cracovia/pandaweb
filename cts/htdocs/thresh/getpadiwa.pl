#!/usr/bin/perl -w
&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";



use HADES::TrbNet;
use Data::Dumper;

 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }

my ($board,$task) = split('-',$ENV{'QUERY_STRING'}); 
$board = hex($board); 
 
 
 
sub sendcmd {
  my ($cmd,$chain) = @_;
  my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,1];
  trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});
  return trb_register_read($board,0xd412);
  }
   
 


my $ret;
my $num = 1;

for(my $i=0; $i < 4; $i++) {
  if ($task eq "temp") {
    $ret->[$i] = sendcmd(0x10040000,$i);
    }
  elsif ($task eq "id") {
    $num = 4;
    $ret->[$i*4+0] = sendcmd(0x10000000,$i);
    $ret->[$i*4+1] = sendcmd(0x10010000,$i);
    $ret->[$i*4+2] = sendcmd(0x10020000,$i);
    $ret->[$i*4+3] = sendcmd(0x10030000,$i);
    }
  }


  
  
foreach my $b (sort keys %{$ret->[0]}) {
  printf ("%04x",$b);
  for(my $i=0; $i < 4*$num; $i++) {
    if($task eq "id"){
      printf(" %04x",$ret->[$i]->{$b} & 0xffff);
      }
    else {
      printf(" %d",$ret->[$i]->{$b});
      }
    }
  print "&";
  }


  
exit 1;
