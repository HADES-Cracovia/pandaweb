#!/usr/bin/perl -w
use warnings;

use FileHandle;
use Getopt::Long;
use Data::Dumper;

my $cmd;
my $reglist = {};

open FILE, "$ARGV[0]" or die $!."\nFile name required.";

while (my $a = <FILE>) { 
  if(my ($set,$str) = $a =~ /^\s*(\d+)\s*((0x\w\w\w\w\s*)*)/) {
    my @vals = split(/\s+/,$str);
    my $i = 0;
    foreach my $t (@vals) {
#        print "$t\n";
      if($t =~ /0x(\w\w\w\w)/) {
        $reglist->{$set}->{$i++}=$1;
        }
      }
    }
#0x2000       1     0x38     0x38     0x38     0x38     0x38     0x38
  if(my ($addr,$set,$str) = $a =~ /^\s*0x(\w\w\w\w)\s+(\d+)((\s+0?x?\w+)+)/) {
#       print "$addr : $set : $str\n";
    my @vals = split(/\s+/,$str);
    shift(@vals) if($vals[0] eq '');
    my $i = 0;
    #print Dumper \@vals;
    foreach my $t (@vals) {
      if($t =~ /0?x?(\w+)/) {
        $cmd .= "trbcmd w 0x$addr 0x$reglist->{$set}->{$i++} $t\n";
	#print "cmd: $cmd\n";
        }
      }
    }
  }

print $cmd;
system($cmd);
# print "Done.\n\n";
