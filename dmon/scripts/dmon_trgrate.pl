#!/usr/bin/perl -w

use warnings;
use POSIX qw(strftime);
use FileHandle;
use lib "./code";
use lib "../tools";
use HADES::TrbNet;
use Time::HiRes qw(usleep);
use Dmon;
use HPlot;

my %config = do $ARGV[0];
my $flog = Dmon::OpenQAFile();
trb_init_ports() or die trb_strerror();

my $old;
my $summing = 0;
my $cnt = 0;


my $plot = ();
$plot->{name}    = "TriggerRate";
$plot->{file}    = Dmon::DMONDIR."TriggerRate";
$plot->{entries} = 600;
$plot->{type}    = HPlot::TYPE_HISTORY;
$plot->{output}  = HPlot::OUT_PNG;
$plot->{titles}->[0] = "";
$plot->{xlabel}  = "Time [s]";
$plot->{ylabel}  = "Rate [Hz]";
$plot->{sizex}   = 750;
$plot->{sizey}   = 270;
$plot->{xscale}  = 5;
$plot->{nokey}   = 1;
$plot->{buffer}  = 1;
HPlot::PlotInit($plot);

my $str = Dmon::MakeTitle(10,6,"TriggerRate",0);
   $str .= qq@<img src="%ADDPNG TriggerRate.png%" type="image/png">@;
   $str .= Dmon::MakeFooter();
Dmon::WriteFile("TriggerRate",$str);




while(1) {
  my $r = trb_register_read($config{CtsAddress},0xa000);
  my $value    = $r->{$config{CtsAddress}};
  my $rate     = ($value||0) - ($old||0);
     $rate += 2**32 if $rate < 0;
  
  if( defined $old) {
    $summing += $rate;
    HPlot::PlotAdd('TriggerRate',$rate*5,0);
    print $rate;
    
    unless($cnt++ % 10) {
      my $title    = "Rate";
      my $value    = $summing/2;
      my $longtext = $value." triggers pre second";
      my $status   = Dmon::GetQAState('above',$value,(15,2,1));
      Dmon::WriteQALog($flog,"trgrate",5,$status,$title,$value,$longtext,'2-TriggerRate');
 
      HPlot::PlotDraw('TriggerRate');
      $summing = 0;
      }
    }
  $old = $value;    
  usleep(200000);
}
