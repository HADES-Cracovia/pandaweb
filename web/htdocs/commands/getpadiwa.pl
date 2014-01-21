#!/usr/bin/perl
use HADES::TrbNet;
use Data::Dumper;
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Content-type: text/html\r\n\r\n";
  }
else {
  use lib '..';
  use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
  print "Content-type: text/html\n\n";
  }


 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }

 

my ($board,$task);

if(exists $ENV{'QUERY_STRING'}) {
  ($board, $task) = split('-',$ENV{'QUERY_STRING'}); 
  }
else {
  ($board, $task) = @ARGV; 
}
if(!defined $board || !defined $task) {
  die "Not enough parameters";
  }
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
  elsif ($task eq "thresh" || $task eq "threshdump") {
    $num = 16;
    for(my $j=0;$j<16;$j++) {
      $ret->[$i*16+$j] = sendcmd(0x00000000+$j*0x10000,$i);
      }
    }
  }


  
if($task ne "threshdump") {  
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
  }
else {
  print "# Board\tChain\tLen\tDAC\tChannel\tCommand\tValue\n";
  foreach my $b (sort keys %{$ret->[0]}) {
    for(my $i=0; $i < 4*$num; $i++) {
      printf("  %04x\t0x%x\t1\t0\t%d\t8\t0x%04x\n",$b,1<<($i/16),$i%16,$ret->[$i]->{$b} & 0xffff);
      }
    }

  }
#  print "# Board   Chain     ChainLen    DAC     Channel       Command       Value\n";  
exit 1;
