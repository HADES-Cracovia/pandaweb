# Module: Random Pulser (Type 0x50)
# The random pulser generates irregular event patterns. As
# the pulser is not configurable, the sole purpose of this block is to inform about the
# presens of the unit and its mapping to the internal channel. The has no payload,
# i.e. a fixed size of 0 words.

package CtsMod50;

@ISA = (CtsBaseModule);

use warnings;
use strict;

sub moduleName {"Random Pulser"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $expo = $self->{'_exportRegs'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x50}->read();

   for(my $i = 0; $i < $header->{'itc_len'}; $i++) {
      $self->{'_cts'}->getProperties->{'itc_assignments'}[$i + $header->{'itc_base'}] = "Random Pulser";
   }
   
# registers
   $prop->{"trg_random_pulser_count"} = 1;
}

1;