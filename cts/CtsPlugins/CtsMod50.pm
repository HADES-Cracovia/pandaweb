# Module: Random Pulser (Type 0x50)
# A random pulser generates irregular event patterns. Each instance is configured
# with a single word control registers, which holds its threshold. There is a
# linear depency between the average trigger rate F and the threshold T given by
#  F(T) = Freq_Base * T / Max_T = 100 MHz * T / Max_T

package CtsMod50;

@ISA = (CtsBaseModule);

use warnings;
use strict;

sub moduleName {"Random Pulser"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $expo = $self->{'_exportRegs'};
   my $prop = $self->{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x50}->read();

   for(my $i = 0; $i < $header->{'len'}; $i++) {
      my $key = "trg_random_pulser_config$i";
      
      $regs->{$key} = new TrbRegister($address + 1 + $i, $trb, {
         'threshold' => {'lower' =>  0, 'len' => 32},
      }, {
         'accessmode' => "rw",
         'label' => "Random Pulser Threshold $i",
         'monitor' => '1',
         'export' => 1
      });
   }   
   
   for(my $i = 0; $i < $header->{'itc_len'}; $i++) {
      $self->{'_cts'}->getProperties->{'itc_assignments'}[$i + $header->{'itc_base'}] = "Random Pulser $i";
   }
   
# registers
   $prop->{"trg_random_pulser_count"} = $header->{'len'};
}

1;