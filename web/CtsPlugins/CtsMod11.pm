# Module: Input Event Counter (Type 0x11).
# Similiarly to the Internal Channel Event Counters (Type 0x01)
# this block contains one status register for each input channel. The here-mentioned
# counters, however, use the unprocessed trigger inputs instead of the internal trigger
# channels. Hence by comparing both counter types, one can infere the number of
# events filtered by the spike rejection.


package CtsMod11;

@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;

sub moduleName {"Channel Event Counter"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $expo = $self->{'_exportRegs'};
   my $prop = $self->{'_properties'};
   
   my $header = $self->getCTS->getTriggerEnum->{0x11}->read();
   

# registers
   for(my $i=0; $i < $header->{'len'} / 2; $i++) {
      $regs->{"trg_input_asserted_cnt$i"} = TrbRegister->new($address + 1 + 2*$i, $trb, {}, {
         'accessmode' => "ro",
         'label' => "Trigger Input Asserted Counter $i",
         'monitorrate' => 1
      });

      $regs->{"trg_input_edge_cnt$i"} = TrbRegister->new($address + 1 + 2*$i + 1, $trb, {}, {
         'accessmode' => "ro",
         'label' => "Trigger Input Edge Counter $i",
         'monitorrate' => 1
      });
   }
}

1;