# Module: Pulser (Type 0x30) 
# Each pulser has one register that stores its interval length. The
# number represents the duration of the low-level in microseconds, which is followed
# by an one clock high-pulse. Hence 0 results in a constant high channel.

package CtsMod30;

@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;

sub moduleName {"Periodical Counter"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x30}->read();
   
# registers
   for(my $i = 0; $i < $header->{'len'}; $i++) {
      my $key = "trg_pulser_config$i";
      
      $regs->{$key} = new TrbRegister($address + 1 + $i, $trb, {
         'low_duration' => {'lower' =>  0, 'len' => 32},
      }, {
         'accessmode' => "rw",
         'label' => "Periodical Counter Configuration $i",
         'monitor' => '1',
         'export' => 1
      });
   }

   for(my $i = 0; $i < $header->{'itc_len'}; $i++) {
      $self->{'_cts'}->getProperties->{'itc_assignments'}[$i + $header->{'itc_base'}] = "Periodical Pulser $i";
   }
   
# properties
   $prop->{"trg_pulser_count"} = $header->{'len'};
}

1;