package TrbSlicedRegister;

use strict;
use warnings;

use Data::Dumper;

sub new {
# TrbSlicedRegister->new( $defs )
#  $regs contains a hash-reference, where the hash's keys
#  are reference to the corresponding TrbRegister reference.
#  The hash's values are list-reference, which contain the
#  registers slice. It is up to the user, to ensure, each
#  slice-key remains unambigious, i.e. no key is used by
#  included for different registers.

   my $type = $_[0];
   my $keys = $_[1];
   
   my $self = {
      '_keys' => $keys
   };
   
   bless($self, $type);
   
   return $self;
}

sub format {
# TrbSlicedRegister->format( [$scalar] )
#  Functions as a wrapper function to the registers included and
#  returns a hash that contains the values for all referenced slices.
#  If $scalar evaluates true, only the first entry is returned 

   my $self = $_[0];
   my $scalar = $_[1];
   my $result = {};
   
   my $cache = {};
   
   foreach my $key (keys %{$self->{'_keys'}}) {
      my $tmp;
      my $reg = $self->{'_keys'}{$key};
      
      if (exists $cache->{$reg}) {
         $tmp = $cache->{$reg};
      } else {
         $tmp = $reg->format();
         $cache->{$reg} = $tmp;
      }
         
      if ($scalar) {
         return $tmp->{$key};
      }

      $result->{$key} = $tmp->{$key};
   }

   return $result;
}

sub read {
# TrbSlicedRegister->read( [$scalar] )
#  Functions as a wrapper function to the registers included and
#  returns a hash that contains the values for all referenced slices.
#  If $scalar evaluates true, only the first entry is returned 

   my $self = $_[0];
   my $scalar = $_[1];

   my $result = {'_raw' => {}};
   
   my $cache = {};
   
   foreach my $key (keys %{$self->{'_keys'}}) {
      my $tmp;
      my $reg = $self->{'_keys'}{$key};
      
      if (exists $cache->{$reg}) {
         $tmp = $cache->{$reg};
      } else {
         $tmp = $reg->format();
         $cache->{$reg} = $tmp;
      }
         
      if ($scalar) {
         return $tmp->{$key};
      }

      $result->{$key} = $tmp->{$key};
   }

   return $result;
}

sub write {
# TrbSlicedRegister->write( $values )
#  If only one slice is referenced, $values is allowed to have
#  a scalar value. Otherwise a hash that maps a value to each key
#  that shall be written is expected.
   my $self   = $_[0];
   my $values = $_[1];

   if (ref $values) {
      my $valuesPerReg = {};
      
      foreach my $key (keys %$values) {
         $valuesPerReg->{$self->{'_keys'}{$key}} = $values->{$key};
      }
      
      foreach my $reg (keys %$valuesPerReg) {
         $reg->write( $valuesPerReg->{$reg} );
      }
   } else {
      if (%{$self->{'_keys'}} > 1) {
         warnings::warn("TrbSlicedRegister->write(): Scalar values are supported for exclusively defintions, containing only one slice");
      } else {
	 $self->{'_keys'}{ (keys %{$self->{'_keys'}})[0] }->write( $values );
         #$self->{'_keys'}{ (keys %{$self->{'_keys'})[0]->write( $values )};
      }
   }
}

sub getAddresses {
   # TrbSlicedRegister->getAddresses()
   #  returns array containg all addresses used by referenced slices
   
   my $self = shift;
   my %addresses = ();
   
   foreach my $key (keys %{$self->{'_keys'}}) {
      $addresses{$self->{'_keys'}{$key}->getAddress} = 1;
   }
   
   return \(sort {$a <=> $b} keys %addresses);
}

sub getAddress {
   # TrbSlicedRegister->getAddress()
   #  returns single address used by a randomly chosen slices
   
   my $self = shift;
   my @keys= (keys %{$self->{'_keys'}});
   
   return $self->{'_keys'}->{ $keys[0] }->getAddress;
}

sub getSliceNames {
   # TrbSlicedRegister->getSliceNames()
   #  returns an array reference containing all Slicenames
   my $self = shift;
   return [sort keys %{$self->{'_keys'}}];
}

sub getAccessMode { 
   # TrbSlicedRegister->getAccessMode()
   #  returns one of the following values "ro", "wo", "rw".
   #  the value is competed as the biggest common feature.

   my $self = shift;
  
   my $read = 1;
   my $write = 1;

   foreach my $key (keys %{$self->{'_keys'}}) {
      my $mode = $self->{'_keys'}{$key}->getAccessMode();
      
      if ($mode eq "ro") {$write = 0;}
      if ($mode eq "wo") {$read = 0;}
   }
   
   unless ($read or $write) {
      die("invalid multi-slice accessmodes");
   }
   
   my $mode = "";
   $mode .= 'r' if $read;
   $mode .= 'w' if $write;
   $mode .= 'o' if length($mode) == 1;
   return $mode;
}

sub TO_JSON {return %{ $_[0] };}

sub getOptions {{}}

1;
