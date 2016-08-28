#!/usr/bin/perl

use warnings;
use strict;
use lib "../../perllibs";
use Dmon;
use Data::Dumper;
use HADES::TrbNet;
use Time::HiRes qq|usleep|;

trb_init_ports() or die trb_strerror();

my $board = hex($ARGV[0]);

#0 for TRB3sc, 1 for DiRich, 2 for Concentrator, 3 for PowerVoltages, 4 for PowerCurrents
my $mode = $ARGV[1] || 0;
my $t = [['mV (3.3)','mV (2.5)','mV (1.2)','mV (6)'],
         ['mV (3.3)','mV (2.5)','mV (1.1)',''],
         ['mV (3.3)','mV (2.5)','mV (1.2)','mA (@1.2)'],
         ['mV (3.3)','mV (2.5)','mV (1.2)','mV (1.1)'],
         ['mA (@1.1)','mA (@1.2)','mA (@2.5)','mA (@3.3)']];
my $channel = [7,7,7,6,5]; #SPI interface number

#1:4V, 2:2V, 3:1V
my $resolution = [[2,1,2,1],  [2,2,2,1],  [2,2,2,4],      [2,2,2,2],       [3,3,2,2]];
my $multiplier=  [[1,1,0.5,2],[1,1,0.5,0],[1,1,0.5,3.125],[1,1,0.5,0.5],   [2.5,1.25,1,0.5]];
my $modedesc =   [ 'Trb3sc',  'DiRich',   'Concentrator', 'Power-Voltages','Power-Currents'];

print "\nRunning in mode ".$modedesc->[$mode]."\n\n";


#2 MHz SPI
system("trbcmd w $board 0xd41a 25");

my $cmd; my $s;

$cmd = 0xc1830000 + ($resolution->[$mode][0] << 25);
$s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);

usleep(5000);
$cmd = 0xd1830000 + ($resolution->[$mode][1] << 25);
$s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
printf("0x%08x\t%i %s\n",$s->{$board},($s->{$board}>>19&0xfff)*$multiplier->[$mode][0],$t->[$mode][0]);

usleep(5000);
$cmd = 0xe1830000 + ($resolution->[$mode][2] << 25);
$s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
printf("0x%08x\t%i %s\n",$s->{$board},($s->{$board}>>19&0xfff)*$multiplier->[$mode][1],$t->[$mode][1]);

usleep(1000);
$cmd = 0xf1830000 + ($resolution->[$mode][3] << 25);
$s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
printf("0x%08x\t%i %s\n",$s->{$board},($s->{$board}>>19&0xfff)*$multiplier->[$mode][2],$t->[$mode][2]);

usleep(5000);
$cmd = 0xf3930000;
$s = Dmon::PadiwaSendCmd($cmd,$board,$channel->[$mode]);
printf("0x%08x\t%i %s\n",$s->{$board},($s->{$board}>>19&0xfff)*$multiplier->[$mode][3],$t->[$mode][3]);

usleep(5000);
$s = Dmon::PadiwaSendCmd(0,$board,$channel->[$mode]);
printf("0x%08x\t%.2f °C\n",$s->{$board},(($s->{$board}>>19)&0xfff)/16.);

#back to normal SPI speed
system("trbcmd w $board 0xd41a 7");
print "\n";