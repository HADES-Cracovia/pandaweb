#!/usr/bin/env perl

use strict;
use warnings;
use Data::Dumper;

use lib "/home/hadaq/trbsoft/daqtools/dmon/code";
use Dmon;

use Getopt::Long;
use Log::Log4perl qw(get_logger);

use HADES::TrbNet;

use IPC::ShareLite qw( :lock );

use constant false => 0;
use constant true => 1;

my $share = IPC::ShareLite->new(
    -key     => 3214,
    -create  => 'yes',
    -destroy => 'yes'
    ) or die $!;

$share->store("dummy text");
#print "store res: $r\n";

my $hitregister = 0xc001;

my @valid_interval = (0x7800, 0x8800);
my $interval_step = ($valid_interval[1] - $valid_interval[0])/4;
my $start_value = int ( ($valid_interval[1] + $valid_interval[0])/2 );

my $sleep_time = 1.0;
my $accepted_dark_rate = 150;
my $number_of_iterations = 40; # at least 15 are recommended

my $endpoint = 0x0303;
my $mode = "padiwa";
my $help = "";
my $offset = 0;
my $opt_skip = 99;
my $polarity = 1;
my @channels  = ();
my $channel32 = undef;
my $opt_finetune = false;

our $chain = 0;

my $result = GetOptions (
    "h|help" => \$help,
    "c|chain=i" => \$chain,
    "e|endpoint=s" => \$endpoint,
    "m|mode=s" => \$mode,
    "p|polarity=i" => \$polarity,
    "o|offset=s" => \$offset,
    "32|32channel" => \$channel32,
    "s|skip=i" => \$opt_skip,
    "f|finetune" => \$opt_finetune,
    );
