use strict;
use warnings;
use warnings::register;

use lib "./include/";

use Cts;
use CtsConfig;

use File::Basename;

BEGIN {
   if (eval "require JSON::PP;") {
      *JSON_BIND:: = *JSON::PP::;
   } else {
      eval "require JSON;";
      *JSON_BIND:: = *JSON::XS::;
   }
}


sub connectToCTS {
   my $trb;


 # open cache create by monitor process to
 #  a) reduce the number of read accesses
 #  b) ensure the same interface is used
   open FH, "<" .  dirname(__FILE__) . "/monitor/enum.js";
   my $json = join ' ', <FH>;
   close FH;
   
   my $cache = JSON_BIND->new->decode( $json );

   $ENV{'DAQOPSERVER'} = $cache->{'daqop'};
   my $endpoint = hex $cache->{'endpoint'};
   
   eval {require "TrbNet.pm"};
   $trb = TrbNet->new($endpoint);
   
   return Cts->new($trb, $cache->{'enumCache'});
}

my $cts = connectToCTS( );

my $query = $ENV{'QUERY_STRING'};

if ($query eq "init") {
   print JSON_BIND->new->allow_blessed->convert_blessed->encode({
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
   
   print JSON_BIND->new->allow_blessed->convert_blessed->encode(\%result);
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
   
   foreach my $key (keys %$regs) {
      my $reg = $cts->getRegisters->{$key};
      #next unless defined $reg;
      $reg->write($regs->{$key});
   }

   $cts->getTrb->stopCachedWrites();
   
   print "1;";
}
   
1;
