# Module: Periph FPGA Trigger Inputs
package CtsMod14;

@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;

sub moduleName {"Periph Trigger Inputs"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x14}->read();
   
# registers
   for(my $i = 0; $i < $header->{'len'}; $i++) {
      my $key = "trg_periph_config$i";
      $regs->{$key} = new TrbRegister($address + 1 + $i, $trb, {
         'mask'  => {'lower' =>  0, 'len' => 20, 'type' => 'mask'}
      }, {
         'accessmode' => "rw",
         'export'     => 1,
         'monitor' => '1',
         'label' => "Periph. Trigger $i"
      });
      $self->{'_cts'}->getProperties->{'itc_assignments'}[$header->{'itc_base'}+$i] = "Periph. FPGA Inputs $i";
   }

# properties
   $prop->{"trg_periph_count"} = $header->{'len'};
   $prop->{"trg_periph_itc_base"} = $header->{'itc_base'};
}

1;