use strict;
use warnings;
use warnings::register;

use lib "./include/";

use Cts;
use CtsConfig;
use CtsCommands;

use File::Basename;

our $endpoint;
use Carp;
$SIG{ __DIE__ } = sub { 
   my $error = $_[0];

   print 'HTTP/1.0 500 INTERNAL SERVER ERROR';
   print "\r\nContent-Type: text/html;\r\n\r\n";

   print "<pre>\r\n";

   if ($error =~ /unknown address/ and $error =~ /trb_register_read/ and $error =~ /0xa[012]/) {
      printf("Endpoint (0x%04x) responded, but could not read CTS registers. Does the endpoint contain a CTS?\n" . 
      "If the CTS uses a different address, change the default endpoint address in\n" . 
      "htdocs/CtsConfig.pm, or use the --endpoint parameter when starting the CTS tool.", $endpoint);
      
   } elsif ($error =~ /no endpoint has been reached/) {
      printf("Endpoint (0x%04x) not reached. Please ensure that \n" . 
      "(1) the correct DAQOPSERVER is used and\n" .
      "(2) the CTS is configured to this address.\n" .
      "If the CTS uses a different address, change the default endpoint address in\n" . 
      "htdocs/CtsConfig.pm, or use the --endpoint parameter when starting the CTS tool.", $endpoint);
   }
   
   print "\n\n\n--------------------- More details error description ------------------------------\n";
   print $error;
   
   print "</pre>\r\n";
};   

BEGIN {
   if (eval "require JSON::PP;") {
      *JSON_BIND:: = *JSON::PP::;
   } else {
      eval "require JSON;";
      *JSON_BIND:: = *JSON::XS::;
   }
}

sub printHeader {
   my $state = shift;
   my $type = shift;
   my $attachment = shift;
   $type = 'text/javascript' unless defined($type) && $type;
   
   if (defined( $state ) && $state eq 'error') {
      print 'HTTP/1.0 500 INTERNAL SERVER ERROR';
   } else {
      print 'HTTP/1.0 200 OK';
   }
   
   print "\r\nContent-Disposition: attachment; filename=$attachment;" if ($attachment);
   
   print "\r\nContent-Type: $type;\r\n\r\n";
   
}

sub connectToCTS {
   my $trb;

   $endpoint = CtsConfig->getDefaultEndpoint;
   my $cache = {'enumCache' => 0};
   
   my $port = int $ENV{'SERVER_PORT'};
   die("missing SERVER_PORT env variable") unless $port;

 # open cache create by monitor process to
 #  a) reduce the number of read accesses
 #  b) ensure the same interface is used
   open FH, "<" .  dirname(__FILE__) . "/monitor-$port/enum.js";
   if (tell(FH) != -1) {
      my $json = join ' ', <FH>;
      close FH;
      
      if ($json) {
         $cache = JSON_BIND->new->decode( $json );

         $ENV{'DAQOPSERVER'} = $cache->{'daqop'};
         $endpoint = hex $cache->{'endpoint'};
      }
   }
   
   eval {require "TrbNet.pm"};
   $trb = TrbNet->new($endpoint);
   
   return Cts->new($trb, $cache->{'enumCache'});
}


my $cts = connectToCTS( );

#print Dumper $cts;

my $query = $ENV{'QUERY_STRING'};

# escape sequences
while($query =~ /%([0-9a-fA-F]{2,2})/) {
  my $chr = chr(hex($1));
  $query=~ s/%$1/$chr/g;
}

if ($query eq "init") {
   printHeader;
   print JSON_BIND->new->allow_blessed->convert_blessed->encode({
      'registers' => $cts->getRegisters,
      'properties' => $cts->getProperties,
      'server' => {'port' => $ENV{'SERVER_PORT'}}
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
   
   printHeader;
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
   
   printHeader;
   print "1;";
} elsif ($query =~ /^dump,(shell|trbcmd)/) {
   my $mode = $1;
   my $attachment = 'cts-dump';
   
   $attachment .= $mode eq 'shell' ? '.sh' : '.trb';
   
   printHeader 'ok', 'text/plain', $attachment;

   print(commandDump($cts, $mode));
} else {
  printHeader 'error';
  print "Unknown command: $query\n";
}
1;
