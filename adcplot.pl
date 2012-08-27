#!/usr/bin/perl -w
use warnings;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use HPlot;
use HADES::TrbNet;
# my $fh;

trb_init_ports() or die("could not connect to trbnetd");
# open $fh, "../../trb3/multitest/adcdump.txt" or die $!."\nFile  not found.";


my $plot = ();
$plot->{name}    = "ADC";
$plot->{file}    = "files/ADC";
$plot->{entries} = 1000;
$plot->{type}    = HPlot::TYPE_HISTORY;
$plot->{output}  = HPlot::OUT_SCREEN;
$plot->{titles}->[0] = "";
$plot->{xlabel}  = "sample";
$plot->{ylabel}  = "value";
$plot->{sizex}   = 1200;
$plot->{sizey}   = 900;
$plot->{ymin} = 0;
$plot->{ymax} = 2**12;
$plot->{nokey} = 1;
HPlot::PlotInit($plot);


while(1) {

trb_register_write(0xfadc,0xc000,0) or sleep 5 and next;
usleep(100);
my $mux1 = trb_register_read_mem(0xfadc,0xc006,1,1050) or sleep 5 and next;

foreach my $v (@{$mux1->{0xfadc}}) {
  HPlot::PlotAdd("ADC",$v & 0xfff,0);
  }
HPlot::PlotDraw("ADC");
sleep(1);
}

