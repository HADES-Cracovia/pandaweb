# Module: Mimosa26 External Trigger Module
# 

package CtsMod63;

@ISA = (CtsBaseModule);

use warnings;
use strict;

sub moduleName {"M26 MVD ETM"}

sub init {
return;
   $regs->{'trg_m26_status'} = new TrbRegister($address + 1, $trb, {
         'value' => {'lower' =>  0, 'len' => 32, 'type' => 'hex'},
      }, {
         'accessmode' => "ro",
         'label' => "Mimosa26 Status Register",
         'monitor' => '1'
      });

   $regs->{'trg_m26_control'} = new TrbRegister($address + 2, $trb, {},
      {
         'accessmode' => "rw",
         'label' => "Mimosa26 Control Register",
         'monitor' => '1',
         'export' => 1
      });

   $self->{'_cts'}->getProperties->{'itc_assignments'}[$header->{'itc_base'}] = "External Trigger - Mimosa26";
}

1;
