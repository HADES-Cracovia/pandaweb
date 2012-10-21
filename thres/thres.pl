#!/usr/bin/perl

use strict;
use warnings;

use QtCore4;
use QtGui4;
use Window;

use Getopt::Long;


my $help;
my @channels;
our $channel_str;

my $result = GetOptions (
    "help" => \$help,
    "channel=s" => \$channel_str
    );

if($help || $channel_str eq "") {
    usage();
    exit;
}

our $channel = int($channel_str);

if (!defined $channel) {
    usage();
    exit;
}


sub main {
    my $app = Qt::Application( \@ARGV );
    my $window = Window();
    $window->show();
    return $app->exec();
}

exit main();


sub usage {

    print "
usage: thres.pl --channel=<channel_number>

example:

thres.pl --channel=2
or in short
thres.pl -c 2
";


}


