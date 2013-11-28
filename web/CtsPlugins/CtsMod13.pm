# Module: Periph FPGA Trigger Inputs
package CtsMod13;

@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;

sub moduleName {"AddOn Input Multiplexer"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x13}->read();
   
# registers
   my $key = "trg_periph_config";
   $regs->{$key} = new TrbRegister($address + 1, $trb, {
      'mask'  => {'lower' =>  0, 'len' => 4, 'type' => 'mask'}
   }, {
      'accessmode' => "rw",
      'export'     => 1,
      'monitor' => '1',
      'label' => "Periph. Trigger"
   });

   $self->{'_cts'}->getProperties->{'itc_assignments'}[$header->{'itc_base'}] = "Periph. FPGA Inputs";

# properties
   $prop->{"trg_periph_count"} = $header->{'len'};
   $prop->{"trg_periph_itc_base"} = $header->{'itc_base'};
}

1;