package TrbSim;
use warnings;
use strict;

sub new {
   my $type = $_[0];
   my $endpoint = $_[1];
   my $self = {
      '_data' => {},
      '_endpoint' => $endpoint,
      '_known_registers' => {}
   };
   
   bless($self, $type);
   return $self;
}

sub read {
   # Trb->read($address, $len = 1)
   #  Reads $len registers starting at $address
   #  Returns integer if $len==1 else a reference to an array

   my $self = $_[0];
   my $address = $_[1];
   my $len = defined $_[2] ? $_[2] : 1;
   
   if (1 == $len) {
      my $data = $self->{'_data'}->{$address};
      return defined $data ? $data : undef;
   } else {
      my $result = [];
      for(my $i=0; $i < $len; $i++) {
         push $result, $self->read($address + $i);
      }
      
      return $result;
   }
}

sub write {
   # Trb->write($address, $data)
   #  if $data is scalar, it is interpreted as an 32bit integer and
   #  written to the register $address
   #  if $data is a reference to an array, all entries are sequentially
   #  written to the memory area starting at $address;

   my $self = $_[0];
   my $address = $_[1];
   my $data = $_[2];
   
   if (not ref $data) {
      $self->{'_data'}->{$address} = $data & 0xFFFFFFFF;
   } elsif (ref $data eq "ARRAY") {
      for(my $i=0; $i < @$data; $i++) {
         $self->write($address + $i, $data->[$i]);
      }
   }
}

sub loadDump {
   # TrbSim->loadDump($fp)
   #  reads in file provided with the file pointer $fp and
   #  sets values listed in the input. The following format 
   #  (used by the trbcmd rm command) is expected:
   #
   #  Each line contains one value "0xADDRESS 0xVALUE"
   #  Comments after data are allowed and can be sepearated by
   #  any non-hex char.
   #
   #  All lines not matching this format are skipped.
   my $self = $_[0];
   my $fp   = $_[1];

   while (my $line = <$fp>) {
      if ($line =~ /^\s*0x([\da-f]+)\s+0x([\da-f]+)/) {
         $self->write(hex($1), hex($2));
      }
   }
}

sub getEndpoint {
   # TrbSim->getEndpoint()
   #  returns id of endpoint simulated
   $_[0]->{'_endpoint'}
}

sub addKnownRegister {
   # TrbSim->addKnownRegister( $reg )
   #  where $reg is a reference to a TrbRegister instance
   my $self = shift;
   my $reg = shift;
   
   $self->{'_known_registers'}{$reg->getAddress} = $reg;
}

# prefetching is not sensible for simulation.
# methods are implemented only for compatibility
sub clearPrefetch {}
sub addPrefetchRegister {}
sub prefetch {}

1;