# Module: Unified AddOn Module
package CtsMod15;

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
   my $cprop = $self->{'_cts'}{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x15}->read();

   print "Trigger Modules 0x12 and 0x15 cannot be instantiated in the same design\n" if exists $self->{'_cts'}{'_enum'}{0x12};
   
# registers
   for(my $i = 0; $i < $header->{'len'}; $i++) {
      my $key = "trg_input_mux$i";
      
      $regs->{$key} = new TrbRegister($address + 1 + $i, $trb, {
         'input'  => {'lower' =>  0, 'len' => 7, 'type' => 'enum', 'enum' => 
            {
              0 => 'extclk[0]', 1 => 'extclk[1]', 2 => 'trgext[2]', 3 => 'trgext[3]', # rj45 jacks on trb3
              4 => 'jeclin[0]', 5 => 'jeclin[1]', 6 => 'jeclin[2]', 7 => 'jeclin[3]', 
              8 => 'jin1[0]',   9 => 'jin1[1]',  10 => 'jin1[2]',  11 => 'jin1[3]', 
             12 => 'jin2[0]',  13 => 'jin2[1]',  14 => 'jin2[2]',  15 => 'jin2[3]',
             16 => 'nimin1',   17 => 'nimin2',   18 => 'any[jeclin]', 19 => 'any[jin1]',
             20 => 'any[jin2]',21 => 'any[nimin]'
            }
         }
      }, {
         'accessmode' => "rw",
         'export'     => 1,
         'monitor' => '1',
         'label' => "Input Multiplexer $i"
      });
   }

   for(my $i = 0; $i < $header->{'itc_len'}; $i++) {
      $self->{'_cts'}->getProperties->{'itc_assignments'}[$i + $header->{'itc_base'}] = "AddOn Multiplexer $i";
   }

# properties
   $prop->{"trg_inp_mux_count"} = $header->{'len'};
   $prop->{"trg_inp_mux_itc_base"} = $header->{'itc_base'};
}

1;