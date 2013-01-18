# Module: CBM Module
# 

package CtsMod60;

@ISA = (CtsBaseModule);

use warnings;
use strict;

sub moduleName {"CBM"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $expo = $self->{'_exportRegs'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x60}->read();
   
   $regs->{'trg_cbm_status'} = new TrbRegister($address + 1, $trb, {
         'value' => {'lower' =>  0, 'len' => 32, 'type' => 'hex'},
      }, {
         'accessmode' => "ro",
         'label' => "CBM Status Register",
         'monitor' => '1'
      });

   $regs->{'trg_cbm_control'} = new TrbRegister($address + 2, $trb, {},
      {
         'accessmode' => "rw",
         'label' => "CBM Control Register",
         'monitor' => '1',
         'export' => 1
      });

   $self->{'_cts'}->getProperties->{'itc_assignments'}[$header->{'itc_base'}] = "Ext. Logic - CBM";
}

1;