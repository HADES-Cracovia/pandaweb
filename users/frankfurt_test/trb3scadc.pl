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

#2 MHz SPI
system("trbcmd w $board 0xd41a 25");

my $cmd; my $s;

$cmd = 0xc3830000;
$s = Dmon::PadiwaSendCmd($cmd,$board,7);

usleep(1000);
$cmd = 0xd3830000;
$s = Dmon::PadiwaSendCmd($cmd,$board,7);
printf("0x%08x\t%i mV\n",$s->{$board},($s->{$board}>>19&0xfff)*2);

usleep(1000);
$cmd = 0xe5830000;
$s = Dmon::PadiwaSendCmd($cmd,$board,7);
printf("0x%08x\t%i mV\n",$s->{$board},($s->{$board}>>19)&0xfff);

usleep(1000);
$cmd = 0xf3830000;
$s = Dmon::PadiwaSendCmd($cmd,$board,7);
printf("0x%08x\t%i mV\n",$s->{$board},($s->{$board}>>19&0xfff)/2);


usleep(1000);
$cmd = 0xf3930000;
$s = Dmon::PadiwaSendCmd($cmd,$board,7);
printf("0x%08x\t%i mV\n",$s->{$board},($s->{$board}>>19&0xfff)*2);

usleep(1000);
$s = Dmon::PadiwaSendCmd(0,$board,7);
printf("0x%08x\t%.2f °C\n",$s->{$board},(($s->{$board}>>19)&0xfff)/16.);

#back to normal SPI speed
system("trbcmd w $board 0xd41a 7");
