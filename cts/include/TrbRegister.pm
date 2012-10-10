package TrbRegister;

# This class offers a register-based semantic abstraction, i.e.
# each instance of this class represents exactly one register of
# a TrbEnd Endpoint.

# On construction a definition of the register's structure
# must be provided. If a registers hold more than one value,
# the structure contains multiple slices.

# Each slice is given by its lower bit, its length and an optional 
# type. The following types are supported:
#
#  uint (default)       The slice's contents is unsigned integer
#
#  hex                  Same behaivor as >uint<, however a hexadecimal
#                       representation is used when displayed to the user
#
#  bool                 Slice has to have length of 1. Same as >uint<,
#                       but user output is 0: "False", 1: "True"
#
#  enum                 Only valid, if additionally the property "enum"
#                       is as a hash-reference mapping the enum's keys
#                       to labels.
# 
#  mask                 Outputs a binary representation in nibble blocks     
#
# See TrbSlicedRegister to reference a slice subset or merge registers.

use strict;
use warnings;
use POSIX;

use Data::Dumper;

use TrbNet;

sub new {
   # TrbRegister->new( $address, $trb, [$defs], [$accessmode] )
   #  Creates a new TrbRegister description. If $defs is not provided,
   #  it is assumed, that the whole registers stores one 32 bit value:
   #   $defs = {
   #     'value' => {'lower' => 0, 'len' => 32, 'disp' => ''}
   #   }
   #  $accessmode may be: "ro" (read-only), "rw" (read-write, default), "wo" (write-only)

   my $type    = shift;
   my $address = shift;
   my $trb     = shift;
   my $defs    = shift;
   my $options = shift;
   
   my $def_options = {
      'label' => '',
      'export' => 0,
      'monitorrate' => 0,
      'accessmode' => 'rw',
      'constant'  => 0
   };
   
   $options = $options ? { %{$def_options}, %{$options} } : $def_options;
   
   # default values
   $defs       = {'value' => {'lower' => 0, 'len' => 32}} unless keys %$defs;
   
   my $self = {
      '_trb'     => $trb,
      '_address' => $address,
      '_defs'    => $defs,
      '_options' => $options,
      '_accessmode' => $options->{'accessmode'},
      '_const'   => $options->{'const'},
      '_cached'  => undef
   };

   # check values passed
   foreach my $key (keys %$defs) {
      my $def = $defs->{$key};
   
      # optional values
      $def->{'type'} = "uint" unless defined $def->{'type'};
   }
   
   bless ($self, $type);
   
   $trb->addKnownRegister($self);
   
   return $self;
}

sub read {
   # TrbRegister->read( [$return_unsliced], $withTime )
   #  Reads the register from TrbNet endpoint. If $return_unsliced evaluates to
   #  True, the raw data is returned as integer.
   #  The default behaivor, however, is to extract the single slices
   #  and return by a hash reference. The hash contains all keys
   #  provided when constructing this object. The special key "_raw"
   #  contains the raw data
   
   my $self = shift;
   my $return_unsliced = shift;
   my $withTime = shift;
   my $unsliced;
   my $time;

   if ($self->{'_accessmode'} ne "ro" and $self->{'_accessmode'} ne "rw") {
      warnings::warn("Register does not support read-access");
      return;
      
   }
   
   if ($self->{'_const'} and defined $self->{'_cached'} and not $withTime) {
      $unsliced = $self->{'_cached'};
   } elsif ($withTime) {
      my $tmp = $self->{'_trb'}->read($self->{'_address'}, 1, 1);
      $unsliced = $tmp->{'value'};
      $time = $tmp->{'time'};
   } else {
      $unsliced = $self->{'_trb'}->read($self->{'_address'});
      $self->{'_cached'} = $unsliced;
   }
   
   return ($withTime ? {'time' => $time, 'value' => $unsliced} : $unsliced) if $return_unsliced;
   
   my $sliced_result = {'_raw' => $unsliced};
   
   foreach my $key (keys %{$self->{'_defs'}}) {
      $sliced_result->{$key} = ($unsliced >> $self->{'_defs'}{$key}{'lower'}) # shift
                               & ((1 << $self->{'_defs'}{$key}{'len'}) - 1);  # and mask
   }
   
   return ($withTime ? {'time' => $time, 'value' => $sliced_result} : $sliced_result);
}

sub write {
   # TrbRegister->write( $value )
   #  If $value is not a reference its value is directly written to
   #  the endpoint. Otherwise, a hash reference containing the sliced data
   #  is expected and unsliced, before beeing written to the endpoint.
   
   my $self = $_[0];
   my $value = $_[1];

   if ($self->{'_accessmode'} ne "wo" and $self->{'_accessmode'} ne "rw") {
      warnings::warn("Register does not support write-access");
      return;
      
   }
   
   my $unsliced = 0;
   
   if (ref $value) {
      if (%$value lt $self->{'_defs'}) {
         # as $value seems to be incomplete -> fetch current_settings
         $unsliced = $self->read(1);
      }

      foreach my $key (keys %$value) {
         if (not defined $self->{'_defs'}{$key}) {
            die("Undefined property: $key");
         }
         
         my $def = $self->{'_defs'}{$key};
         my $mask = ((1 << $def->{'len'}) - 1);
         
         my $sliceValue = lc $value->{$key};

         my %revEnumVal;
         if ($def->{'type'} eq "enum") {
            %revEnumVal = reverse %{ $def->{'enum'} };
         }
         
         if ($def->{'type'} eq "enum" and exists $revEnumVal{$sliceValue}) {
           $sliceValue = $revEnumVal{$sliceValue};
           
         } elsif ($sliceValue =~ /^0x([\da-f]+)$/) {
            $sliceValue = hex($1);
            
         } elsif ($sliceValue =~ /^0b([01]+)$/) {
            $sliceValue = unpack("N", pack("B32", substr("0" x 32 . $1, -32)));
            
         }
         
         if ( ($sliceValue & $mask) != $sliceValue ) {
            die(sprintf "Value 0x%x for %s to big for mask 0x%x", $sliceValue, $key, $mask) 
         }
         
         $unsliced &= ~($mask << $def->{'lower'});
         $unsliced |= ($sliceValue & $mask) << $def->{'lower'}; 
      }
      
   } else {
      # $value seemes to be encoded already, so just write it to endpoint ...
      $unsliced = $value;
   }
   
   $self->{'_trb'}->write($self->{'_address'}, $unsliced);
   $self->{'_cached'} = $unsliced;
}

sub format {
   # TrbRegister->format()
   #  Reads register and formats slices depending on their type.
   #  Returns hash indexed by slice-key. All entries are strings.
      
   my $self = $_[0];
   
   my %values = %{$self->read()};
   
   my %defs = %{ $self->{'_defs'} };
   my %result = ('_raw', $values{'_raw'});
   
   my @compact = ();
   
   foreach my $key (sort keys %defs) {
      my $type = $defs{$key}->{'type'};
   
      if ($type eq "hex") {
         my $nibbles = ceil( $defs{$key}->{'len'} / 4 );
         $result{$key} = sprintf("0x%0" . $nibbles . "x", $values{$key}); 

      } elsif($type eq "enum") {
         my $val = $defs{$key}->{'enum'}{$values{$key}};
         $result{$key} = defined $val ? $val : "-n/a-";

      } elsif($type eq "bool") {
         $result{$key} = $values{$key} ? "true" : "false";
      
      } elsif($type eq "mask") {
         my $tmp = sprintf("%b", $values{$key});
         $tmp = "0" x ($defs{$key}->{'len'} - (length $tmp)) . $tmp;
         
         for(my $i = $defs{$key}->{'len'} - 4; $i; $i -= 4) {
            $tmp = substr($tmp, 0, $i) . " " . substr($tmp, $i);
         }
      
         $result{$key} = $tmp;
         
      } else {
         $result{$key} = $values{$key};
         
      }
      
      push @compact, $key . "=" . $result{$key};
   }
   
   $result{"_compact"} = join ", ", @compact;
   
   return \%result;
}

sub getAddress    {return $_[0]->{'_address'}}
sub getAccessMode {return $_[0]->{'_accessmode'}}
sub getSliceNames {return [sort keys %{$_[0]->{'_defs'}}]}
sub getDefinitions{return $_[0]->{'_defs'}}

sub getOptions    {return $_[0]->{'_options'}}

sub TO_JSON {return {%{ $_[0] }};}

1;
