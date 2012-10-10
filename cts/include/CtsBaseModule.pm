package CtsBaseModule;

use warnings;
use strict;

sub moduleName {""}

sub new {
   my $type = $_[0];
   my $cts  = $_[1];
   my $address = defined $_[2] ? $_[2] : 0;
   
   my $self = {
      '_cts' => $cts,
      '_address' => $address,
      '_registers' => {},
      '_properties' => {},
      '_exportRegs' => []
   };

   bless($self, $type);

   $self->init($address);

   return $self;
}

sub register {
   my $self = $_[0];
   
   my $cts = $self->{'_cts'};

   foreach my $hash ('_properties', '_registers') {
      foreach my $key (keys %{$self->{$hash}}) {
         #unless (substr($key,0,1) eq "_") {
            $cts->{$hash}{$key} = $self->{$hash}{$key}
         #}
      }
   }
}

sub getCTS {
   return $_[0]->{'_cts'};
}

sub getProperties {
   # returns a hash reference of the properties registered
   return $_[0]->{'_properties'};
}

sub getRegisters {
   # returns a hash reference of the registers known
   return $_[0]->{'_registers'};
}

1;
