# Module: Internal Channel Event Counter (Type: 0x01)
# This block contains 32 status registers, that allow read access to
# the level and edge counters of each internal trigger channel. Each channel has
# its two 32 bit counters, that count the number of clock cycles the channel
# is asserted / the number of rising edges. All counters work independently and 
# an overflow of one register does not affect the other registers.

package CtsMod01;

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
   my $prop = $self->{'_properties'};
   
   my $header = $self->getCTS->getTriggerEnum->{0x01}->read();
   

# registers
   for(my $i=0; $i < $header->{'len'} / 2; $i++) {
      $regs->{"trg_channel_asserted_cnt$i"} = TrbRegister->new($address + 1 + 2*$i, $trb, {}, {
         'accessmode' => "ro",
         'label' => "Trigger Channel Asserted Counter $i",
         'monitorrate' => 1
      });

      $regs->{"trg_channel_edge_cnt$i"} = TrbRegister->new($address + 1 + 2*$i + 1, $trb, {}, {
         'accessmode' => "ro",
         'label' => "Trigger Channel Edge Counter $i",
         'monitorrate' => 1
      });      
   }
}

1;