use strict;
use warnings;

use lib "./include/";

use Cts;
use CtsConfig;
use JSON::PP;

sub connectToCTS {
   my $endpoint = shift;
   
   my $trb;

   eval {require "TrbNet.pm"};
   $trb = TrbNet->new($endpoint);
      
   return Cts->new($trb);
}

my $cts = connectToCTS( CtsConfig->getDefaultEndpoint );

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
} elsif ($query =~ /^write,([\w\d_,\.\[\]]+)$/) {
   my @values = split /,/, $1;
   my $regs = {};
   
   $cts->getTrb->startCachedWrites();
   
   while (my $key = shift @values) {
      if ($key =~ /^(.*)\.(.*)\[(\d+)\]$/) {
         my $val = $cts->getRegisters->{$1}->read()->{$2};
         $regs->{$1}{$2} = ($val & (0xFFFFFFFF ^ (1 << $3))) | (((shift @values) & 1) << $3);
      } elsif ($key =~ /^(.*)\.(.*)$/) {
         $regs->{$1} = {} unless ref $regs->{$1};
         $regs->{$1}{$2} = shift @values;
      } else {
         $regs->{$key} = shift @values;
      }
   }
   
   foreach my $key (keys $regs) {
      my $reg = $cts->getRegisters->{$key};
      #next unless defined $reg;
      $reg->write($regs->{$key});
   }

   $cts->getTrb->stopCachedWrites();
   
   print "1;";
}
   
1;
