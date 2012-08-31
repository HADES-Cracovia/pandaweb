use strict;
use warnings;

use lib "./include/";

use Cts;
use JSON::PP;

sub connectToCTS {
   my $mode = shift;
   my $endpoint = shift;
   
   my $trb;
   if ($mode eq 'sim') {
      eval {require "TrbSim.pm"};
      $trb = TrbSim->new($endpoint);
      my $fp;
      open $fp, "<memory.dump";
      $trb->loadDump($fp);
      close $fp;

   } else{
      eval {require "TrbNet.pm"};
      $trb = TrbNet->new($endpoint);
   }
      
   return Cts->new($trb);
}
my $cts = connectToCTS 'trb', 0xf3c0;

my $query = $ENV{'QUERY_STRING'};

if ($query eq "init") {
   print JSON::PP->new->allow_blessed->convert_blessed->encode({
      'registers' => $cts->getRegisters,
      'properties' => $cts->getProperties
   });
} elsif ($query =~ /^(format|read),([\w\d_,]+)$/) {
   my $op = $1;
   my @keys = split /,/, $2;
   my %result = ();
   
   foreach my $key (@keys) {
      my $reg = $cts->getRegisters->{$key};
      next unless defined $reg;
      
      $result{$key} = $op eq "read" ? $reg->read() : $reg->format();
   }
   
   print JSON::PP->new->allow_blessed->convert_blessed->encode(\%result);
} elsif ($query =~ /^write,([\w\d_,\.]+)$/) {
   my @values = split /,/, $1;
   my $regs = {};
   
   while (my $key = shift @values) {
      if ($key =~ /^(.*)\.(.*)$/) {
         $regs->{$1} = {} unless ref $regs->{$1};
         $regs->{$1}{$2} = shift @values;
      } else {
         $regs->{$key} = shift @values;
      }
   }
   
   foreach my $key (keys $regs) {
      my $reg = $cts->getRegisters->{$key};
      next unless defined $reg;
      $reg->write($regs->{$key});
   }
   
   print "1";
}
   
1;
