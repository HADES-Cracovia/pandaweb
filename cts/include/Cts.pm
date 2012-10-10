package Cts;

use strict;
use warnings;
use warnings::register;

use CtsPlugins::CtsModStatic;

sub new {
   my $type = $_[0];
   my $trb  = $_[1];
   
   my $self = {
      '_trb'   => $trb,
      
      '_modules'    => {},   # hash (header-type => module) of modules loaded during enumeration
      '_registers'  => {},   # hash of available registers
      '_properties' => {
         'itc_assignments' => [
         qw(unconnected unconnected unconnected unconnected
            unconnected unconnected unconnected unconnected 
            unconnected unconnected unconnected unconnected 
            unconnected unconnected unconnected unconnected)]
      },   # hash of properties (e.g. "number of inputs" ...)

      '_exportRegs' => []    # list of registers, that need to be stored, when saving configuration
   };
   
   bless($self, $type);
   
   my $static = $self->_loadModule("Static") or die("Error while loading mandantory module >CtsModStatic<");
   $static->register();
   
   $self->_enumerateTriggerLogic();
   
   return $self;
}

sub _enumerateTriggerLogic {
   # Starts 
   my $self = shift;
   my $address = shift;
   $address = 0xa100 if not defined $address;

   my $last = 0;
   my $offsetToNextHeader  = 1;
   my $regv = {};
   
   until ( defined($regv->{'last'}) and $regv->{'last'} ) {
# fetch next header
      my $reg  = TrbRegister->new($address, $self->{'_trb'}, {
         'type'      => {'lower' =>  0, 'len' => 8},   # type = enum, but modules not loaded yet - so just go with int
         'len'       => {'lower' =>  8, 'len' => 8},
         'itc_base'  => {'lower' => 16, 'len' => 5},
         'itc_len'   => {'lower' => 21, 'len' => 5},
         'last'      => {'lower' => 31, 'len' => 1, 'type' => 'bool'}
      }, {
         'accessmode' => 'ro',
         'constant'   => 1
      });

      $regv = $reg->read();
      
      $offsetToNextHeader = $regv->{'len'} + 1;

      if (defined $self->{'_enum'}{$regv->{'type'}}) {
         warnings::warn(sprintf("Block type 0x%02x appears multiple times (not allowed by specification). First encountered at address 0x%04x, now again at 0x%04x",
            $regv->{'type'}, $self->{'_enum'}{$regv->{'type'}}->{'_address'}, $address));
         
         next;
      }

      $self->{'_enum'}{$regv->{'type'}} = $reg;
      
# load module      
      my $mod = $self->_loadModule(sprintf("%02x", $regv->{'type'}), $address);
      if ($mod) {
         $mod->register();
      
      } else {
         warnings::warn(sprintf("Unknown block found during trigger logic enumeration: 0x%02x at address 0x%04x", $regv->{'type'}, $address));
         next;
         
      }
   
   } continue {
      $address += $offsetToNextHeader;
      
   }
   
}

sub _loadModule {
   my $self = shift;
   my $modKey = shift;
   my $address = shift;
   
   my $module = "CtsMod" . $modKey;
  
   my $mod = eval {
      (my $file = $module) =~ s|::|/|g;
      #print "require: CtsPlugins/$file.pm\n";
      require  "CtsPlugins/$file.pm";
      #print "require: CtsPlugins/$file.pm worked: module: $module\n";
      my $ret = $module->new($self, $address);
      #print "return of module -> new (self, address: $address => $ret\n";
      return $ret;
   };
   
   #print "return of eval module -> new (self, address: $address: $@\n";
   $self->{'_modules'}{$modKey} = $mod if $mod;
   return $mod;
}

sub getTrb {
   # returns a reference to the Trb instance used to communicate with the CTS
   return $_[0]->{'_trb'};
}

sub getModules {
   return $_[0]->{'_modules'}
}

sub getTriggerEnum {
   # returns a hash reference containing all trigger logic blocks found
   #  the keys represent the block type
   #  the values are TrbRegister reference to the header register
   return $_[0]->{'_enum'}
}

sub getProperties {
   # returns a hash reference of the properties registered
   return $_[0]->{'_properties'};
}

sub getRegisters {
   # returns a hash reference of the registers known
   return $_[0]->{'_registers'};
}

sub getExportRegisters {
   # returns a list reference of register keys, that need to be
   # stored in order to reproduce the current setup
   my $self = shift;
   my @regs = ();
   
   while ((my $key, my $reg) = each %{ $self->{'_registers'} }) {
      push @regs, $key if $reg->getOptions->{'export'};
   }
   
   return \@regs;
}

1;
