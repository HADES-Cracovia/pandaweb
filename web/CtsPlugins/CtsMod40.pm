# Module: Event types (Type 0x40)
# This block contains exactly two registers, that assign a trigger
# type id (4bit) to each internal trigger channel. Starting with the type of the first
# channel at the lowest four bits of the first register, each word stores 8 types.

package CtsMod40;

@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;
use TrbSlicedRegister;

sub moduleName {"Event Types"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $prop = $self->{'_properties'};

# registers
   for(my $i = 0; $i < 2; $i++) {
      my $key = "_trg_trigger_types$i";
      
      my $enumDef = {
         0x0 => '0x0',
         0x1 => '0x1_physics_trigger',
         0x2 => '0x2',
         0x3 => '0x3',
         0x4 => '0x4',
         0x5 => '0x5',
         0x6 => '0x6',
         0x7 => '0x7',
      
         0x8 => '0x8',
         0x9 => '0x9_mdc_calibration_trigger',
         0xa => '0xa_shower_calibration_trigger',
         0xb => '0xb_shower_pedestal_trigger',
         0xc => '0xc',
         0xd => '0xd_tdc_calibration_trigger',
         0xe => '0xe_status_information_trigger',
         0xf => '0xf'
      };
      
      $regs->{$key} = new TrbRegister($address + 1 + $i, $trb, {
         'type' . (8*$i + 0) => {'lower' =>  0, 'len' => 4, 'type' => 'enum', 'enum' => $enumDef},
         'type' . (8*$i + 1) => {'lower' =>  4, 'len' => 4, 'type' => 'enum', 'enum' => $enumDef},
         'type' . (8*$i + 2) => {'lower' =>  8, 'len' => 4, 'type' => 'enum', 'enum' => $enumDef},
         'type' . (8*$i + 3) => {'lower' => 12, 'len' => 4, 'type' => 'enum', 'enum' => $enumDef},

         'type' . (8*$i + 4) => {'lower' => 16, 'len' => 4, 'type' => 'enum', 'enum' => $enumDef},
         'type' . (8*$i + 5) => {'lower' => 20, 'len' => 4, 'type' => 'enum', 'enum' => $enumDef},
         'type' . (8*$i + 6) => {'lower' => 24, 'len' => 4, 'type' => 'enum', 'enum' => $enumDef},
         'type' . (8*$i + 7) => {'lower' => 28, 'len' => 4, 'type' => 'enum', 'enum' => $enumDef}
      }, {
         'accessmode' => "rw",
         'label' => "Trigger Event Type $i",
         'monitor' => '1',
         'export' => 1
      });
   }

#   for(my $i=0; $i<16; $i++) {
#      $regs->{'trg_trigger_type' . $i} = new TrbSlicedRegister({
#         'type' => $regs->{'_trg_trigger_types' . ($i < 8 ? '0' : '1')},
#      });
#   } 
}

1;
