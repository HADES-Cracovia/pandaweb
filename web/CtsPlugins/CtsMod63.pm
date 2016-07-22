# Module: CBM DLM ETM
# 

package CtsMod63;

@ISA = (CtsBaseModule);

use warnings;
use strict;

sub moduleName {"M26 MVD ETM"}

sub init {
return;
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $expo = $self->{'_exportRegs'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x63}->read();
   
}

1;
