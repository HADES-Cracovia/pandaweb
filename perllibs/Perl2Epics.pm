package Perl2Epics;
use warnings;
use strict;
use Data::Dumper;
# use Hmon;

#Add all possible paths here...
use lib '/home/hadaq/EPICS/base-3.14.12.3/lib/perl';
use lib '/mnt/home_cbm02/hadaq/EPICS/base-3.14.12.3/lib/perl';
use CA;

# Address list for Epics IOCs. Don't remove unused values
$ENV{EPICS_CA_ADDR_LIST} = "10.160.0.63 192.168.1.100";
$ENV{EPICS_CA_AUTO_ADDR_LIST} = 'YES';

my $EpicsValues = {};
my $EpicsStore = {};
my @EpicsChans = ();
my  $EpicsNames = {};
my $errcnt = {};

sub callback {
    my ($chan, $status, $data) = @_;
    #print Dumper $data;
    if ($status) {
  printf "%-30s %s\n", $chan->name, $status;
    } 
    else {
#       print $chan->name . ": $data->{value}\n";
#       print scalar @{$EpicsStore->{$chan->name}->{tme}}."\n";
  if(scalar @{$EpicsStore->{$chan->name}->{tme}} > 10) {
      shift @{$EpicsStore->{$chan->name}->{tme}};
      shift @{$EpicsStore->{$chan->name}->{val}};
        }
  push(@{$EpicsStore->{$chan->name}->{tme}}, $data->{stamp});
  push(@{$EpicsStore->{$chan->name}->{val}},  $data->{value});
  $EpicsValues->{$chan->name}->{tme} = $data->{stamp};
  $EpicsValues->{$chan->name}->{val}  = $data->{value};
    }
}


sub Connect {
    my ($title, $varname, $type, $wait) =  @_;
    #   push(@EpicsChans,CA->new($name));
    #   $EpicsChans[-1]->create_subscription('v', \&callback, 'DBR_TIME_DOUBLE');
    ## print $varname."\n";
    $type = 'DBR_TIME_DOUBLE' unless defined $type;
    $EpicsStore->{$varname}->{tme} = [];
    $EpicsStore->{$varname}->{val} = [];
    $EpicsNames->{$title} = $varname;
    $errcnt->{$varname} = 0;
    my $success;
    eval {
  my $c = CA->new($varname);
  CA->pend_io($wait || 0.05);
  $c->create_subscription('v', \&callback, $type);
#     $c->get_callback(\&callback, $type, 1);
  $EpicsStore->{$varname}->{ca} = $c;
  $success = $c->is_connected();
    };
    #print Dumper $EpicsValues;
    return ($success);
}

sub Update {
    CA->pend_event($_[0]);
}


sub GetAll {
    my $store = {};
    my $time;
    my $val;
    
    Update(0.001);
    
    foreach my $el (keys %{$EpicsNames}) {
  my $varname = $EpicsNames->{$el};
  my $ca = $EpicsStore->{$varname}->{ca};
  my $r = $ca->is_connected() if(defined $ca);
  my $success = 1;
  if(!$r && (!defined $errcnt->{$el} || $errcnt->{$el} < 20)) {
      $success = Connect($el, $varname);
      $errcnt->{$el}++;
  }

  if(!$success) {
      $time = -1;
      $val  = 0;
  } elsif (scalar @{$EpicsStore->{$varname}->{tme}} > 0) {
      $time = (@{$EpicsStore->{$varname}->{tme}})[-1];
      $val  = (@{$EpicsStore->{$varname}->{val}})[-1];
  } else {
      $time = $EpicsStore->{$varname}->{lasttime};
      $val  = $EpicsStore->{$varname}->{lastval};
  }
  $store->{$el}->{tme} = $time;
  $store->{$el}->{val}  = $val;
  $EpicsStore->{$varname}->{lasttime} = $time;
  $EpicsStore->{$varname}->{lastval}  = $val;
    }
    
    return $store;
}

sub Get {
    my ($title,$latest) = @_;
    my $varname = $EpicsNames->{$title};
    my $time;
    my $val;
#   print $varname;

    my $c = $EpicsStore->{$varname}->{ca};
    my $r = $c->is_connected() if(defined $c);

    my $success = 1;
    if(!$r) {
  $success = Connect($title, $varname);
    }

    if(!$success) {
  return (-1, 0);
    }

    Update(0.00001);

    if (scalar @{$EpicsStore->{$varname}->{tme}} > 0) {
  if(defined $latest && $latest == 1) {
      $time = (@{$EpicsStore->{$varname}->{tme}})[-1];
      $val  = (@{$EpicsStore->{$varname}->{val}})[-1];
  }
  else {  #if (scalar @{$EpicsStore->{$varname}->{tme}} > 1)
      $time = shift  (@{$EpicsStore->{$varname}->{tme}});
      $val  = shift  (@{$EpicsStore->{$varname}->{val}});
  }
    }
    else {
  $time = $EpicsStore->{$varname}->{lasttime};
  $val  = $EpicsStore->{$varname}->{lastval};
    }
    $EpicsStore->{$varname}->{lasttime} = $time;
    $EpicsStore->{$varname}->{lastval}  = $val;
    $time = $time || -1;
    $val  = $val || 0;
    return ($time,$val);
}

sub Put {
    my ($title, $value) =  @_;
    my $varname = $EpicsNames->{$title};
    if (!defined $varname) {
  return -1;
    }
    
    my $c = $EpicsStore->{$varname}->{ca};
    my $r = $c->is_connected() if(defined $c);
    
    my $success = 1;
    if(!$r) {
  $success = Connect($title, $varname);
    }
    
    if(!$success) {
        return -2;
    }
            
    if (($c->element_count()) != 1) {
  print "5\n";
  return -3;
    }
    
    my $type = $c->field_type;
    my @values;
    if ($type !~ m/ ^DBR_STRING$ | ^DBR_ENUM$ /x) {
  # Make @ARGV strings numeric
  push (@values, (map { +$_; } $value));
    } else {
  # Use strings
  push (@values, $value);
    }
    $c->put(@values);
    
    return 0;
}

1;
__END__
