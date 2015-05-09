#!/usr/bin/perl 

use strict;
use warnings;

use Parallel::ForkManager;
use Getopt::Long;

my $help;
my $opt_invert;
my $opt_stretch;
my @opt_endpoints;
my @opt_chains;

my $result = GetOptions (
    "h|help" => \$help,
    "i|invert=s" => \$opt_invert,
    "e|endpoints=s" => \@opt_endpoints,
    "s|stretch=s" => \$opt_stretch,
    "c|chains=s" => \@opt_chains,
    );

if($help) {
    usage();
    exit;
}

usage() unless ($opt_invert && @opt_endpoints && @opt_chains);

#my $arg=$ARGV[0];
#my @padiwas = split /\s+/, $arg;

my $endpoints = get_ranges(\@opt_endpoints);
my $chains    = get_ranges(\@opt_chains);


my $MAX_PROCESSES = 100;
my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

#my $padiwa_invert_setting = "0xffff";

my $str_endpoints= join " ", @opt_endpoints;

print "current padiwa range: $str_endpoints\n";

print "\tsetting padiwa invert-setting to $opt_invert ";
execute_command("invert $opt_invert");
$pm->wait_all_children;
print "\n";

#print "result of invert\n";
#execute_command("invert", "verbose");
#exit

# print "\tturn off all leds ";
# execute_command("led 0x10");
# $pm->wait_all_children;
# print "\n";


print "\tset temp compensation to 0x02c0 ";
execute_command("comp 0x02c0");
$pm->wait_all_children;
print "\n";


if($opt_stretch) {
    print "\tset stretching to $opt_stretch";
    execute_command("stretch $opt_stretch");
    $pm->wait_all_children;
    print "\n";
}


exit;

sub execute_command {

  (my $padiwa_command, my $verbosity) = @_;

  foreach my $cur_endpoint (@$endpoints) {
    my $pid = $pm->start and next;
    $cur_endpoint = sprintf "0x%4x", $cur_endpoint;
    #print "$cur_endpoint ";

    for my $chain (0..2) {
      my $c="/home/hadaq/trbsoft/daqtools/padiwa.pl $cur_endpoint $chain $padiwa_command";
      if (!$verbosity) { $c.= " >/dev/null" };
      #print $c . "\n";
      my $res = qx($c); die "could not execute command $c" if $?;
      if($verbosity) { print "$res"; }
    }

    $pm->finish; # Terminates the child process 
  };


}


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


sub usage {


	print "usage:
./prepare_padiwas_invert_leds.pl <--invert \"0xffff\" of --invert \"0x0000\"> <--endpoints=<list of enpoints>> <--chains=<list of chains>> [--help]
";

     exit;


}
