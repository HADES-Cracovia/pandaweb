# Module: Mainz A2 External Trigger Module
# 

package CtsMod61;

@ISA = (CtsBaseModule);

use warnings;
use strict;

sub moduleName {"Mainz A2"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $expo = $self->{'_exportRegs'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x61}->read();
   
   $regs->{'trg_a2_status'} = new TrbRegister($address + 1, $trb, {
         'value' => {'lower' =>  0, 'len' => 32, 'type' => 'hex'},
      }, {
         'accessmode' => "ro",
         'label' => "Mainz A2 Status Register",
         'monitor' => '1'
      });

   $regs->{'trg_a2_control'} = new TrbRegister($address + 2, $trb, {},
      {
         'accessmode' => "rw",
         'label' => "Mainz A2 Control Register",
         'monitor' => '1',
         'export' => 1
      });

   $self->{'_cts'}->getProperties->{'itc_assignments'}[$header->{'itc_base'}] = "External Trigger - A2";
}

1;
