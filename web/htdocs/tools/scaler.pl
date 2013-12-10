#!/usr/bin/perl -w
use HADES::TrbNet;
use Storable qw(lock_store lock_retrieve);
use CGI::Carp qw(fatalsToBrowser);
use lib qw|../commands htdocs/commands|;
use xmlpage;
# use Data::TreeDumper;

my $olddata, my $t, my $dataarr;

$ENV{'DAQOPSERVER'}="localhost:0" unless (defined $ENV{'DAQOPSERVER'});
die "can not connect to trbnet-daemon on $ENV{'DAQOPSERVER'}: ".trb_strerror() unless (defined &trb_init_ports());


###############################
#### The content
###############################
if($ENV{'QUERY_STRING'} =~ /get/) {
  &htsponse(200, "OK");
  print "Content-type: text/html\r\n\r\n";

  my $q = $ENV{'QUERY_STRING'};
  $q = substr($q,3);
  if(-e "/tmp/scalers.$q.store") {
    $olddata = lock_retrieve("/tmp/scalers.$q.store");
    }
  my $data = trb_registertime_read_mem(0x3820,0xc001,0,64) or die trb_strerror();
  my $delay = ($data->{0x3820}->{time}->[0]||0) - ($olddata->{values}->{0x3820}->{time}->[0]||60000);
  $delay += 0x10000 if ($delay < 0);
  $delay *= 16.*125/100;
  $delay = 1E6 if $delay == 0;
  my $rate;
  for(my $i = 0; $i<64;$i++) {
    $rate->[$i] = (($data->{0x3820}->{value}[$i]||0) & 0x00ffffff) - (($olddata->{values}->{0x3820}->{value}[$i]||($data->{0x3820}->{value}[$i]||0)) & 0x00ffffff);
    $rate->[$i] += 0x01000000 if ($rate->[$i] < 0);
    $rate->[$i] = $rate->[$i] / ($delay/1E6); 
    }

  my @dat = $data->{0x3820}->{value};
  my $start = -9;
  my $historyexists = exists($olddata->{rate});
  if ($historyexists && scalar @{$olddata->{rate}} < 9) {
    $start = -(scalar @{$olddata->{rate}});
    }

  for(my $i = 0; $i < 4; $i++) {
    my $avgsum = 0; $sum = 0;
    for(my $j=0;$j<4;$j++) {
      $sum += $rate->[2*$j+8+$i*16];
      $avgsum += $rate->[2*$j+8+$i*16];
      if($historyexists) {
        foreach my $k ($start .. -1) {
          $avgsum += $olddata->{rate}->[$k]->[2*$j+8+$i*16]||0;
          }
        }
      }
    $avgsum /= 1-$start;
    print "<div><hr class=\"queryresult\"><table class='queryresult scalers'>";
    $t  = sprintf("<tr><td><b>Diamond $i</b><th>Average<th>Current<th>Ratio");
    $t .= sprintf("<td rowspan=\"6\"><img height=\"180\" width=\"700\" src=\"scaler.pl?plot%1d%d.%d\">",$i,$q,time()/5);
    $t .= sprintf("<tr><td>Sum<td>%d<td>%d<td>",$avgsum,$sum);
    for(my $j=0;$j<4;$j++) {
      my $avgrate = $rate->[2*$j+8+$i*16];
      if($historyexists) {
        foreach my $k ($start .. -1) {
          $avgrate += $olddata->{rate}->[$k]->[2*$j+8+$i*16]||0;
          }
        }
      $avgrate /= 1-$start;
      $t .= sprintf("<tr><td>INP %d<td>%d", $j+4+$i*8, $avgrate);
      $t .= sprintf("<td title=\"%d\">%d",$data->{0x3820}->{value}[2*$j+8+$i*16],$rate->[2*$j+8+$i*16]);
      $t .= sprintf("<td>%.1f%%",$rate->[2*$j+8+$i*16]/($sum||1E334)*100);
      }
    #$t =~ s/(?<=\d)(?=(?:\d\d\d)+\b)/&#8198;/g; 
    print $t;
    print "</table></div>\n";
    }


  printf("<hr classxtics=\"queryresult\"><p>Time between last two readings (mod 1.6s) %d ms",$delay/1000.);
  printf(".  %d entries",scalar @{$olddata->{rate}});
  if((scalar @{$olddata->{rate}}) >= 100) {
    shift(@{$olddata->{rate}});
    }
  push(@{$olddata->{rate}},$rate);
  $olddata->{values} = $data;
  lock_store($olddata,"/tmp/scalers.$q.store");
  }


###############################
#### The plot
###############################
elsif($ENV{'QUERY_STRING'} =~ /plot/) {
  &htsponse(200, "OK");
  print "Content-type: image/png\r\n\r\n";
  my $q = $ENV{'QUERY_STRING'};
  $num =  substr($q,4,1);

  $q = substr($q,5);
  @p = split('\.',$q);
#   print $q.".".$p[0];
  if(-e "/tmp/scalers.$p[0].store") {
    $data = lock_retrieve("/tmp/scalers.$p[0].store");
    }
  if(! ref($data) eq "ARRAY") {
    return;
    }
  my $cmd = "";
  $cmd .= "set terminal png font sans 6 size 700,180;\n";
  $cmd .= "set key off;\n";
  $cmd .= "unset xtics;\n";
  $cmd .= "set ylabel offset 1,0 \\\"kHz\\\";\n";
  $cmd .= "set lmargin 8;set rmargin 0.1;set tmargin 0.7; set bmargin 0.7;\n";
  $cmd .= "plot '-' with lines,'-' with lines,'-' with lines, '-' with lines\n";
  for(my $j=0; $j<4; $j++) {
    foreach my $r (@{$data->{rate}}) {
      $cmd .= ($r->[$num*16+8+2*$j]/1000.)."\n";
      }
    $cmd .= "\ne\n";
    }
  $cmd = "echo \"$cmd\" | gnuplot";
  my @o = qx($cmd);
  print @o;
  return 1;
  }


###############################
#### The page
###############################
else {
  &htsponse(200, "OK");
  print "Content-type: text/html\r\n\r\n";
  my $ts = time();
  my $page;
  $page->{title} = "Diamond Scaler Display";
  $page->{link}  = "../";
  $page->{getscript} = "scaler.pl";


  my @setup;
  $setup[0]->{name}    = "Scalers";
  $setup[0]->{cmd}     = "get".$ts;
  $setup[0]->{period}  = 1000;
  $setup[0]->{generic} = 0;


  xmlpage::initPage(\@setup,$page);
  }
