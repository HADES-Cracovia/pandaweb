# Module: Channel Configuration (Type 0x00)
# This block contains only one control register that holds
#  - the bitmask (bits 15:0) for the internal channel selection (0 = off, 1 = on)
#  - the bitmask (bits 31:16) enable rising edge operation (0 = level, 1 = edge).
# A trigger event is detected, if any of the masked channels is asserted.

package CtsMod00;

@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;

sub moduleName {"Channel Configuration"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $prop = $self->{'_properties'};

# registers
   $regs->{"trg_channel_mask"} = TrbRegister->new($address + 1, $trb, {
      'mask'     => {'lower' =>   0, 'len' => 16, 'type' => 'mask'},
      'edge'     => {'lower' =>  16, 'len' => 16, 'type' => 'mask'}
   }, {
      'accessmode' =>"rw",
      'monitor' => '1',
      'export' => '1',
      'label' => "Trigger Channel Mask"
   });
   
# properties
   $prop->{"trg_channel_count"} = 16;
}

1;