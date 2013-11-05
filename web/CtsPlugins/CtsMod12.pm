# Module: AddOn Input Multiplexer (Type 0x12)
package CtsMod12;

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

   my $header = $self->{'_cts'}{'_enum'}{0x12}->read();
   
# registers
   for(my $i = 0; $i < $header->{'len'}; $i++) {
      my $key = "trg_addon_config$i";
      
      $regs->{$key} = new TrbRegister($address + 1 + $i, $trb, {
         'input'  => {'lower' =>  0, 'len' => 7, 'type' => 'enum', 'enum' => 
            {
              0 => 'jeclin[0]', 1 => 'jeclin[1]', 2 => 'jeclin[2]', 3 => 'jeclin[3]', 
              4 => 'jin1[0]',   5 => 'jin1[1]',   6 => 'jin1[2]',   7 => 'jin1[3]', 
              8 => 'jin2[0]',   9 => 'jin2[1]',  10 => 'jin2[2]',  11 => 'jin2[3]',
             12 => 'nimin1',   13 => 'nimin2'
            }
         }
      }, {
         'accessmode' => "rw",
         'export'     => 1,
         'monitor' => '1',
         'label' => "AddOn Multiplexer $i"
      });
   }

   for(my $i = 0; $i < $header->{'itc_len'}; $i++) {
      $self->{'_cts'}->getProperties->{'itc_assignments'}[$i + $header->{'itc_base'}] = "AddOn Multiplexer $i";
   }

# properties
   $prop->{"trg_addon_count"} = $header->{'len'};
   $prop->{"trg_addon_itc_base"} = $header->{'itc_base'};

}

1;