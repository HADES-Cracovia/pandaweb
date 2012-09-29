package TrbNet;

use warnings;
use strict;

use HADES::TrbNet;

sub new {
   my $type = $_[0];
   my $endpoint = $_[1];
   
   trb_init_ports() or die trb_strerror();
   
   my $self = {
      '_endpoint' => $endpoint,
      '_known_registers' => {},
      '_prefetch' => {},
      '_write_cache' => {},
      '_cached_writes' => 0
   };
   
   bless($self, $type);
   return $self;
}

sub read {
   # Trb->read($address, $len = 1, $withTime = 0)
   #  Reads $len registers starting at $address
   #  Returns integer if $len==1 else a reference to an array

   # if value of single read is found in prefetch cache the cached value
   # is returned. call clearPrefetch before reading to ensure the
   # value is actually read from endpoint
   
   my $self = shift;
   my $address = shift;
   
   my $len = shift;
   $len = 1 unless $len;

   my $withTime = shift;

   if (1 == $len) {
   # In write cache ?
      my $write = $self->{'_write_cache'}{$address};
      if (defined $write) {
         return $withTime ? {'time' => -1, 'value' => $write} : $write;
      }
   
   # In prefetch cache ?
      my $pre = $self->{'_prefetch'}{$address};
      if (ref $pre and (not $withTime or exists $pre->{'time'})) {
         return $withTime ? $pre : $pre->{'value'};
      }

   # Need to read directly from device
      my $read = $withTime ?
         trb_registertime_read($self->getEndpoint, $address) :
         trb_register_read($self->getEndpoint, $address);
         
      defined $read or die( ($withTime ? "trb_registertime_read" : "trb_register_read") . sprintf("(0x%04x)\n", $address) .  trb_strerror());
      return $read->{$self->getEndpoint};
      
   } else {
   # TODO: Add write cache !!!
      my $read = trb_register_read_mem($self->getEndpoint, $address, 0, $len);
      defined $read or die(trb_strerror());
      return $read->{$self->getEndpoint};
   }
}

sub clearPrefetch {
   # TrbNet->clearPrefetch()
   #  
   my $self = shift;
   $self->{'_prefetch'} = {};
}

sub addPrefetchRegister {
   # TrbNet->addPrefetchRegister( $reg )
   #  where $reg is a reference to a TrbRegister instance or an integer register address

   my $self = shift;
   my $reg = shift;
   
   $self->{'_prefetch'}{ref $reg ? $reg->getAddress : $reg} = 1;
}

sub startCachedWrites {
   my $self = shift;
   $self->{'_cached_writes'} = 1;
}

sub stopCachedWrites { 
   my $self = shift;
   $self->flushWriteCache();
   $self->{'_cached_writes'} = 1;
}

sub flushWriteCache {
   my $self = shift;
   my $cache = $self->{'_write_cache'};
   
   if ($cache) {
      foreach my $address (keys $cache) {
         trb_register_write($self->getEndpoint, $address, $cache->{$address}) or die(trb_strerror);
      }
   }
   
   $self->{'_write_cache'} = {};
}

sub prefetch {
   my $self = shift;
   my $withTime = shift;
   my @addresses = sort keys $self->{'_prefetch'};
   $self->{'_prefetch'}{$_} = 0 for (@addresses);
  
   my $maxUnneededAddresses = 3;
   
   my $blockStart = shift @addresses;
   my $last = $blockStart;
   my $continueBlock = 1;
   
   for_addresses: foreach my $address (@addresses) {
      $continueBlock = 0;
      if ($address - $last <= $maxUnneededAddresses) {
         for(my $i=$last + 1; $i < $address; $i++) {
            next for_addresses unless (exists $self->{'_known_registers'}{$i});
         }
         
         if ($address == $addresses[-1]) {
            $last = $address;
            $continueBlock = 0;
         } else {
            $continueBlock = 1;
         }
      }
   } continue {
      if (!$continueBlock) {
         if ($blockStart < $last) {
            if ($withTime) {
               my $tmp = trb_registertime_read_mem($self->getEndpoint, $blockStart, 0, $last - $blockStart + 1);
               return unless $tmp;
               $tmp = $tmp->{$self->getEndpoint};
               
               for(my $i = $blockStart; $i <= $last; $i++) {
                  $self->{'_prefetch'}{$i} = {
                     'value' => $tmp->{'value'}->[$i - $blockStart],
                     'time'  => $tmp->{'time'}->[$i - $blockStart]
                  }
               }
            } else {
               my $tmp = trb_register_read_mem($self->getEndpoint, $blockStart, 0, $last - $blockStart + 1);
               return unless $tmp;
               $tmp = $tmp->{$self->getEndpoint};
               
               for(my $i = $blockStart; $i <= $last; $i++) {
                  $self->{'_prefetch'}{$i} = {
                     'value' => $tmp->[$i - $blockStart]
                  }
               }
            }
         }
         $blockStart = $address;
      }
      $last = $address;
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
      printf "// w 0x%04x 0x%04x 0x%08x\n", $self->getEndpoint, $address, $data;
      if ($self->{'_cached_writes'}) {
         $self->{'_write_cache'}{$address} = $data;
      } else {
         trb_register_write($self->getEndpoint, $address, $data) or die(trb_strerror);
      }
   } elsif (ref $data eq "ARRAY") {
      for(my $i=0; $i < @$data; $i++) {
         $self->write($address + $i, $data->[$i]);
      }
   }
}

sub getEndpoint {
   # TrbNet->getEndpoint()
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


1;