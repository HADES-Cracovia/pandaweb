#!/usr/bin/perl -w

use HADES::TrbNet;
use Storable qw(lock_retrieve);
use Time::HiRes qw( usleep );
use feature "switch";

use if (defined $ENV{'QUERY_STRING'}), CGI::Carp => qw(fatalsToBrowser);
use if (!defined $ENV{'QUERY_STRING'}), warnings;
use if (!defined $ENV{'QUERY_STRING'}), Pod::Usage;
use if (!defined $ENV{'QUERY_STRING'}), Text::TabularDisplay;
use if (!defined $ENV{'QUERY_STRING'}), Data::Dumper;
use if (!defined $ENV{'QUERY_STRING'}), Data::TreeDumper;
use if (!defined $ENV{'QUERY_STRING'}), Getopt::Long;

my ($db,$data,$once,$slice);
my $help = 0;
my $verbose = 0;
my $isbrowser = 0;
my $server = $ENV{'SERVER_SOFTWARE'} || "";
my @request;
my ($file,$entity,$netaddr,@spi_chains,$fullname, $value);


$ENV{'DAQOPSERVER'}="localhost:7" unless (defined $ENV{'DAQOPSERVER'});
die "can not connect to trbnet-daemon on $ENV{'DAQOPSERVER'}: ".trb_strerror() unless (defined &trb_init_ports());



if (defined $ENV{'QUERY_STRING'}) {
  @request = split("&",$ENV{'QUERY_STRING'});
  unless ($server  =~ /HTTPi/i) {
    print "Content-type: text/html\n\n";
    }
  }
else {
  $request[0] = ""; #Dummy entry to run foreach
  }

  


foreach my $req (@request) {
###############################
#### Check if browser or command line
###############################

  if(defined $ENV{'QUERY_STRING'}) {
    if($server =~ /HTTPi/i) {
      $isbrowser = 1;
      ($entity,$netaddr,$name,$value) = split("-",$req);
      $file = "htdocs/xml-db/cache/$entity.entity";
      }
    else {
  #     use FindBin qw($RealBin);
      my $RealBin = ".";
      $isbrowser = 1;
      ($entity,$netaddr,$name,$value) = split("-",$req);
      $file = "$RealBin/cache/$entity.entity";
      }
    }
  else {
  #   use FindBin qw($RealBin);
    my $RealBin = ".";
    Getopt::Long::Configure(qw(gnu_getopt));
    GetOptions(
              'help|h' => \$help,
              'verbose|v+' => \$verbose,
              ) or pod2usage(2);
    pod2usage(1) if $help;
    $entity  = $ARGV[0] || "";
    $file    = "$RealBin/cache/$ARGV[0].entity";
    $netaddr = $ARGV[1] || "";
    $name    = $ARGV[2] || "";
    $value   = $ARGV[3] || "";
    }


  
###############################
#### Check arguments for validity
###############################

  die "Entity $file not found.\n" unless(-e $file) ;

  
  
  # trim whitespace from netaddr
  $netaddr =~ s/^\s+|\s+$//g;

  # split off the spi chain, if any, after reading the $db, it is parsed/checked
  ($netaddr, $spi_chains[0]) = split(':',$netaddr);

  if    ($netaddr=~ m/0x([0-9a-fA-F]{4})/) {$netaddr = hex($1);}
  elsif ($netaddr=~ m/([0-9]{1,5})/) {$netaddr = $1;}
  else {die "Could not parse address $netaddr\n";}


  if    ($name =~ m/^([a-zA-Z0-9]+)\.(\d+)$/) {$name = $1; $slice = $2;}
  elsif ($name =~ m/^([a-zA-Z0-9]+)$/)       {$name = $1; $slice = 0;}
  else {die "Could not parse name $name \n";}

  $db = lock_retrieve($file);
  die "Unable to read cache file\n" unless defined $db;

  die "Name not found in entity file\n" unless(exists $db->{$name});

  die "Object can not be written\n" unless ($db->{$name}->{mode} =~ /w/);


  # parse the spi chains
  if (defined $spi_chains[0]) {
    die "You specified some SPI chains but $entity is not an SpiEntity"
      if $db->{'§EntityType'} ne 'SpiEntity';
    die "SPI range '$spi_chains[0]' is invalid"
      unless $spi_chains[0] =~ m/^[0-9.,]+$/;
    @spi_chains = eval $spi_chains[0];
    die "Could not eval SPI range: $@"
      if $@;
    die "Empty SPI range supplied"
      if @spi_chains==0;
  } elsif ($db->{'§EntityType'} eq 'SpiEntity') {
    # no spi range supplied, just use chain 0 by default
    @spi_chains = (0);
  }


  $value = any2dec($value);
  
###############################
#### Main "do the job"
###############################

  writedata($db->{$name},$entity,$name,$slice,$netaddr,$value);
  }


sub writedata {
  my ($obj,$entity,$name,$slice,$netaddr,$value) = @_;
  my $stepsize = $obj->{stepsize} || 1;
  my $o;
  
  unless ($obj->{type} eq "field" || $obj->{type} eq "registerfield") {
    print "No valid object name.\n";
    return -1;
    }
  
  if($obj->{mode} =~ /r/) {
    $o = register_read($netaddr,$obj->{address}+$slice*$stepsize);
    unless (defined $o) {
      print "No valid answer.\n";
      return -2;
      }
    foreach my $b (keys %$o) {
      $old  = $o->{$b};
      my $mask = ~(((1<<$obj->{bits})-1) << $obj->{start});
      $old = $old & $mask;

      my $new = $value & ((1<<$obj->{bits})-1);
      $new = $new << $obj->{start};
      $new = $new | $old;
      register_write($b,$obj->{address}+$slice*$stepsize,$new);
      }
    }
  else {
    die "Writing write-only non-TrbNetEntity registers not implemented"
      if $db->{'§EntityType'} ne 'TrbNetEntity';

    my $mask = ~(((1<<$obj->{bits})-1) << $obj->{start});
    my $new = $value & ((1<<$obj->{bits})-1); 
    $new = $new << $obj->{start};

    trb_register_loadbit($netaddr,$obj->{address}+$slice*$stepsize,~$mask,$new);
    }
  }

sub register_read {
  my ($netaddr, $regaddr) = @_;
  for ($db->{'§EntityType'}) {
    when ("TrbNetEntity")  {
      $o =  trb_register_read($netaddr, $regaddr);
    }
    when ("SpiEntity") {
      $o = spi_register_read($netaddr, $regaddr);
    }
    default {die "EntityType not recognized";}
  }
  return $o;
}

sub register_write {
  my ($netaddr, $regaddr, $value) = @_;
  for ($db->{'§EntityType'}) {
    when ("TrbNetEntity")  {
      $o =  trb_register_write($netaddr, $regaddr, $value);
    }
    when ("SpiEntity") {
      $o = spi_register_write($netaddr, $regaddr, $value);
    }
    default {die "EntityType not recognized";}
  }
  return $o;
}

sub spi_register_read {
  # inspired by the simple padiwa.pl
  my ($netaddr, $regaddr) = @_;
  $o = {};
  foreach my $chain (@spi_chains) {
    # in $cmd, the lower 16 bits are the payload
    # the upper 16 bits control:
    # 31..24: select (something like an address)
    # 23..20: command read=0x0, write=0x8
    # 19..16: channel/register (something like an address)

    # the lower 4 bits directly map:
    my $cmd = $regaddr & 0xF;
    # the next 8 bits need to be shifted
    $cmd |= (($regaddr >> 4) & 0xFF) << 8;
    # shift it to the upper 16 bits finally
    $cmd <<= 16;

    my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,1];
    trb_register_write_mem($netaddr,0xd400,0,$c,scalar @{$c});
    usleep(1000);
    my $res = trb_register_read($netaddr,0xd412);
    next unless defined $res;
    foreach my $board (keys %$res) {
      my $b = sprintf('%d:%d', $board, $chain); # no hex conversion here
      $o->{$b} = $res->{$board};
    }
  }

  return $o;
}

sub spi_register_write {
  # inspired by the simple padiwa.pl
  my ($netaddr, $regaddr, $value) = @_;

  ($netaddr, $spi_chains[0]) = split(':',$netaddr);
  die "Cannot write to multiple chains, $spi_chains[0] not a number"
    unless $spi_chains[0]=~/^\d+$/;

  # see spi_register_read
  # we set additionally the write bit and the $value payload
  my $cmd = $regaddr & 0xF;
  $cmd |= (($regaddr >> 4) & 0xFF) << 8;
  $cmd |= 0x0080;
  $cmd <<= 16;
  $cmd |= 0xFFFF & $value;

  #print sprintf('Write cmd %08x, Chain %d, Netaddr %04x', $cmd, $spi_chains[0], $netaddr),"\n";

  my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$spi_chains[0],1];
  trb_register_write_mem($netaddr,0xd400,0,$c,scalar @{$c});
  usleep(1000);

  # TODO: some response cheking??
}



  
sub any2dec { # converts numeric expressions 0x, 0b or decimal to decimal
  
  my $argument = $_[0];
  #print "any2dec input argument $argument\n";  

  if ( $argument =~ m/0[bxBX]/) { 
    return oct $argument;
  } else {
    return $argument;
  }
}  
  
print "Done\n";
1;



