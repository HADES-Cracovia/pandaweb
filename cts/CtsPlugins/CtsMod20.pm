# Module: Coincidence Configuration (Type 0x20)
package CtsMod20;

@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;

sub moduleName {"Coincidence Configuration"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x20}->read();
   
# registers
   for(my $i = 0; $i < $header->{'len'}; $i++) {
      my $key = "trg_coin_config$i";
      
      $regs->{$key} = new TrbRegister($address + 1 + $i, $trb, {
         'coin_mask'    => {'lower' =>  0, 'len' => 8, 'type' => 'mask'},
         'inhibit_mask' => {'lower' =>  8, 'len' => 8, 'type' => 'mask'},
         'window'       => {'lower' => 16, 'len' => 4}
      }, {
         'accessmode' => "rw",
         'label' => "Coincidence Configuration $i",
         'monitor' => '1',
         'export' => 1
      });
   }
   
   for(my $i = 0; $i < $header->{'itc_len'}; $i++) {
      $self->{'_cts'}->getProperties->{'itc_assignments'}[$i + $header->{'itc_base'}] = "Coincidence Module $i";
   }

# properties
   $prop->{"trg_coin_count"} = $header->{'len'};
}

1;