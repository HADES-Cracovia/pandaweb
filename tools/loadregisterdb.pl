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
  if(my ($addr,$set,$str) = $a =~ /^\s*0x(\w\w\w\w)\s+(\d)+((\s+0x\w+)+)/) {
#       print "$addr : $set : $str\n";
    my @vals = split(/\s+/,$str);
    shift(@vals) if($vals[0] eq '');
    my $i = 0;
    #print Dumper \@vals;
    foreach my $t (@vals) {
      if($t =~ /0x(\w+)/) {
        $cmd .= "trbcmd w 0x$addr 0x$reglist->{$set}->{$i++} $t\n";
	#print "cmd: $cmd\n";
        }
      }
    }
  }

# print Dumper $reglist;

#     if($2==1) {
# #       printf("%4x\t%1d\t%2x %2x %2x %2x\n",hex($1),$2,hex($3),hex($4),hex($5),hex($6));
# #       $cmd .= sprintf("trbcmd w 0x%04x 0xa049 0x%02x\n",hex($1),hex($3));
# #       $cmd .= sprintf("trbcmd w 0x%04x 0xa04b 0x%02x\n",hex($1),hex($4));
# #       $cmd .= sprintf("trbcmd w 0x%04x 0xa04d 0x%02x\n",hex($1),hex($5));
# #       $cmd .= sprintf("trbcmd w 0x%04x 0xa04f 0x%02x\n",hex($1),hex($6));
#       }
#     if($2==2) {
# #       printf("%4x\t%1d\t%2x %2x %2x %2x %2x %2x\n",hex($1),$2,hex($3),hex($4),hex($5),hex($6),hex($8),hex($10));
#       $cmd .= sprintf("trbcmd w 0x%04x 0xa0cd 0x%02x\n",hex($1),hex($3));
#       $cmd .= sprintf("trbcmd w 0x%04x 0xa0cf 0x%02x\n",hex($1),hex($4));
#       $cmd .= sprintf("trbcmd w 0x%04x 0xa0d1 0x%02x\n",hex($1),hex($5));
#       $cmd .= sprintf("trbcmd w 0x%04x 0xa0d3 0x%02x\n",hex($1),hex($6));
#       $cmd .= sprintf("trbcmd w 0x%04x 0xa0d5 0x%02x\n",hex($1),hex($8));
#       $cmd .= sprintf("trbcmd w 0x%04x 0xa0d7 0x%02x\n",hex($1),hex($10));
#       }

  
#$cmd .= "trbcmd w 0xfffd 0x20 0x200\n";
# print $cmd;
system($cmd);
# print "Done.\n\n";
