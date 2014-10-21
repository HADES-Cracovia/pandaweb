#!/usr/bin/perl

use warnings; 
use strict;

use Getopt::Long;
use English;
use Data::Dumper;

use HADES::TrbNet;

use constant false => 0;
use constant true => 1;

my $opt_help;
my @opt_endpoints;
my @opt_chains;
my $opt_offset = 0;
my $opt_polarity = 0;
my $opt_32channel = 0;
my $opt_finetune = false;
my $opt_verb;

GetOptions ('h|help'        => \$opt_help,
            'e|endpoints=s' => \@opt_endpoints,
            'c|chains=s'    => \@opt_chains,
            'o|offset=s'    => \$opt_offset,
            'p|polarity=i'  => \$opt_polarity,
            '32|32channel'  => \$opt_32channel,
            'f|finetune'    => \$opt_finetune,
            'v|verb'        => \$opt_verb);


my $endpoints = get_ranges(\@opt_endpoints);
my $chains    = get_ranges(\@opt_chains);

if( $opt_help ) {
    &help();
    exit(0);
}


#print Dumper $endpoints;
#print Dumper $chains;

if($opt_32channel == 1) {
    $opt_32channel="--32channel";
}
else {
    $opt_32channel="";
}


if($opt_finetune == true) {
    $opt_finetune="--finetune";
}
else {
    $opt_finetune="";
}


my $command;

my @pids=();
my %pids;

foreach my $endpoint (@$endpoints) {
  foreach my $chain (@$chains) {
    my $endpoint = sprintf("0x%04x", $endpoint);
    $command = "./thresholds_automatic.pl -e $endpoint -o $opt_offset -c $chain -p $opt_polarity $opt_32channel $opt_finetune";
    print "command: $command\n";
    my $pid = fork();
    if($pid==0) { #child
      my $res = qx($command);
      #print $res;
      exit;
    }
    else {
      push @pids, $pid;
      $pids{$pid} = 1;
    }
    #print $res;
  }
}

#print Dumper \%pids;

foreach my $endpoint (@$endpoints) {
  foreach my $chain (@$chains) {
    my $pid = wait();
    print "pid: $pid returned\n";
    #last if $pid == -1;
    delete $pids{$pid};
    #print Dumper \%pids;
  }
}

exit;


sub get_ranges {
    (my $ra_data) = @_;

    my @array;
    foreach my $str (@$ra_data) {
        $str=~s/-/\.\./g;
        $str=~s/\.\.\./\.\./g;
        my @val = split(/\,/, $str);
        #print Dumper \@val;
        foreach my $c_val (@val) {
            if($c_val =~ /\.\./) {
                #print "range: $c_val\n";
                (my $start, my $stop) = $c_val =~ /(\w+)\.\.(\w+)/;
                $start = hex($start) if($start=~/0x/);
                $stop = hex($stop) if($stop=~/0x/);
                #print "start $start, stop $stop\n";
                foreach ($start .. $stop) {
                    push @array, $_;
                }
                #print Dumper \@array;
            }
            else {
                $c_val = hex($c_val) if($c_val=~/0x/);
                push @array, int($c_val);
            }

        }

    }

    return \@array;

}


sub help {

print <<EOF;
usage:
run_threshold_on_system.pl |options]

example:
run_threshold_on_system.pl --endpoints=0x301-0x308,0x310..0x315,0x380 --chains=0..3 --offset=4 --polarity=0
will run for endpoints 0x301-0x308 and 0x310-0x315 and 0x380 for all chains (0..3)


EOF

}
