# Module: Input Module Configuration (Type 0x10)
package CtsMod10;

@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;

sub moduleName {"Input Module Configuration"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x10}->read();
   
# registers
   for(my $i = 0; $i < $header->{'len'}; $i++) {
      my $key = "trg_input_config$i";
      
      $regs->{$key} = new TrbRegister($address + 1 + $i, $trb, {
         'delay'     => {'lower' =>  0, 'len' => 4},
         'spike_rej' => {'lower' =>  4, 'len' => 4},
         'invert'    => {'lower' =>  8, 'len' => 1, 'type' => 'bool'},
         'override'  => {'lower' =>  9, 'len' => 2, 'type' => 'enum', 'enum' => 
            {0 => 'off', 1 => 'to_low', 3 => 'to_high'}
         }
      }, {
         'accessmode' => "rw",
         'export'     => 1,
         'monitor' => '1',
         'label' => "Trigger Input Module Configuration $i"
      });
   }

   for(my $i = 0; $i < $header->{'itc_len'}; $i++) {
      $self->{'_cts'}->getProperties->{'itc_assignments'}[$i + $header->{'itc_base'}] = "Trigger Input $i";
   }

# properties
   $prop->{"trg_input_count"} = $header->{'len'};
   $prop->{"trg_input_itc_base"} = $header->{'itc_base'};

}

1;