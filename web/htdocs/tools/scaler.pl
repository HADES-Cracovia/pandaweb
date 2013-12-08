#!/usr/bin/perl -w
use HADES::TrbNet;
use Storable qw(lock_store lock_retrieve);
use CGI::Carp qw(fatalsToBrowser);
use Data::TreeDumper;

use lib qw|../commands htdocs/commands|;
use xmlpage;

my $olddata, my $t;

$ENV{'DAQOPSERVER'}="localhost:0" unless (defined $ENV{'DAQOPSERVER'});
die "can not connect to trbnet-daemon on $ENV{'DAQOPSERVER'}: ".trb_strerror() unless (defined &trb_init_ports());

###############################
#### The content
###############################
if($ENV{'QUERY_STRING'} =~ /get/) {
  &htsponse(200, "OK");
  print "Content-type: text/html\r\n\r\n";

  my $q = $ENV{'QUERY_STRING'};
  if(-e "/tmp/scalers.$q.store") {
    $olddata = lock_retrieve("/tmp/scalers.$q.store");
    }

  my $data = trb_registertime_read_mem(0x3820,0xc001,0,64) or die trb_strerror();
  my $delay = ($data->{0x3820}->{time}->[0]||0) - ($olddata->{0x3820}->{time}->[0]||0);
  $delay += 0x10000 if ($delay < 0);
  $delay *= 16.;
  $delay = 1E6 if $delay == 0;
  print STDERR $delay." ".$data->{0x3820}->{time}->[0]."\n";
  my $rate;
  for(my $i = 0; $i<64;$i++) {
    $rate->[$i] = (($data->{0x3820}->{value}[$i]||0) & 0x00ffffff) - (($olddata->{0x3820}->{value}[$i]||0) & 0x00ffffff);
    $rate->[$i] += 0x01000000 if ($rate->[$i] < 0);
    $rate->[$i] = $rate->[$i] / ($delay/1E6); 
    }

  my @dat = $data->{0x3820}->{value};

  for(my $i = 0; $i < 4; $i++) {
    my $sum = 0;
    for(my $j=0;$j<4;$j++) {
      $sum += $rate->[2*$j+8+$i*16];
      }
    print "<div><hr class=\"queryresult\"><table class='queryresult scalers'><tr>";
    $t  = sprintf("<tr><td><b>Diamond $i</b>");
    $t .= sprintf("<td>%d<td>Sum",$sum);
    for(my $j=0;$j<4;$j++) {
      $t .= sprintf("<tr><td>INP %d<td title=\"%d\">%d",$j+4+$i*8,$data->{0x3820}->{value}[2*$j+8+$i*16],$rate->[2*$j+8+$i*16]);
      $t .= sprintf("<td>(%.1f%%)",$rate->[2*$j+8+$i*16]/($sum||1E334)*100);
      }
    $t =~ s/(?<=\d)(?=(?:\d\d\d)+\b)/&#8198;/g; 
    print $t;
    print "</table></div>\n";
    }


  printf("<hr class=\"queryresult\"><p>Time between last two readings (mod 1.6s) %d ms",$delay/1000.);

  lock_store($data,"/tmp/scalers.$q.store");
  }


###############################
#### The page
###############################
else {
  &htsponse(200, "OK");
  print "Content-type: text/html\r\n\r\n";

  my $page;
  $page->{title} = "Diamond Scaler Display";
  $page->{link}  = "../";
  $page->{getscript} = "scaler.pl";


  my @setup;
  $setup[0]->{name}    = "Scalers";
  $setup[0]->{cmd}     = "get".time();
  $setup[0]->{period}  = 1000;
  $setup[0]->{generic} = 0;


  xmlpage::initPage(\@setup,$page);
  }