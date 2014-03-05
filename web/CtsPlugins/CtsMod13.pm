# Module: Periph FPGA Trigger Inputs
package CtsMod13;

@ISA = (CtsBaseModule);

use warnings;
use strict;
use TrbRegister;
use Data::Dumper;

sub moduleName {"AddOn Output Multiplexer"}

sub init {
   my $self    = $_[0];
   my $address = $_[1];
   
   my $trb  = $self->{'_cts'}{'_trb'};
   
   my $regs = $self->{'_registers'};
   my $prop = $self->{'_properties'};
   my $cprop = $self->{'_cts'}{'_properties'};

   my $header = $self->{'_cts'}{'_enum'}{0x13}->read();
   
   print "WARNING: Enumeration of Trigger Module 0x13 has to be performed AFTER module 0x10 and 0x12 (if existing). Check FPGA design!\n" unless (exists $cprop->{"trg_input_count"});
   
# enum
   my $addon_reg = $self->{'_cts'}->getRegister("trg_input_mux0");
   my @addon_enum = ();
   @addon_enum = keys %{$addon_reg->{'_defs'}{'input'}{'enum'}} if $addon_reg;
   my $addon_line_count = scalar @addon_enum;
   my $enum = {};

   my $j = 0;
   
   for(my $i=0; $i<16; $i++) {$enum->{$i} = "itc[$i]";}
   $j = 16;
   
   for(my $i=0; $i<$cprop->{"trg_input_count"}-$cprop->{"trg_inp_mux_count"}; $i++) {$enum->{$j+$i} = "async[triggers_in[$i]_before_preproc]";}
   $j += $cprop->{"trg_input_count"}-$cprop->{"trg_inp_mux_count"};

   for(my $i=0; $i<$addon_line_count; $i++) {$enum->{$j+$i} = 'async[' .$addon_reg->{'_defs'}{'input'}{'enum'}{$i} . ']';}
   $j += $addon_line_count;
   
   for(my $i=0; $i<$cprop->{"trg_input_count"}-$cprop->{"trg_inp_mux_count"}; $i++) {$enum->{$j+$i} = "preproc[triggers_in[$i]]";}
   $j += $cprop->{"trg_input_count"}-$cprop->{"trg_inp_mux_count"};   
   
   for(my $i=0; $i<$cprop->{"trg_inp_mux_count"}; $i++) {$enum->{$j+$i} = "preproc[input_mux[$i]]";}
   $j += $cprop->{"trg_inp_mux_count"}; 
   
   $enum->{$j} = "sysclk";
   $j++;
   
# registers
   my @mux_names = ();
   for(my $i = 0; $i < $header->{'len'}; $i++) {
      my $key = "trg_addon_output_mux$i";
      
      $regs->{$key} = new TrbRegister($address + $i + 1, $trb, {
         'input'  => {'lower' =>  0, 'len' => 7, 'type' => 'enum', 'enum' => $enum}
      }, {
         'accessmode' => "rw",
         'export'     => 1,
         'monitor' => '1',
         'label' => "AddOn Output Multiplexer $i"
      });
      
      push @mux_names, "outmux[$i]";
   }

# properties
   $prop->{"trg_addon_output_mux_count"} = $header->{'len'};
   if (8 == $header->{'len'}) {
      $prop->{"trg_addon_output_mux_names"} = [
	 "jout1[0]/joutlvds[0]", "jout1[1]/joutlvds[1]", "jout1[2]/joutlvds[2]", "jout1[3]/joutlvds[3]", 
	 "jout2[0]/joutlvds[4]", "jout2[1]/joutlvds[5]", "jout2[2]/joutlvds[6]", "jout2[3]/joutlvds[7]", 
      ];
   } else {
      $prop->{"trg_addon_output_mux_names"} = \@mux_names;
   }
}

1;
