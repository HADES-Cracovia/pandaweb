#!/usr/bin/perl -w

use HADES::TrbNet;
use Storable qw(lock_retrieve);
use feature "switch";
use CGI::Carp qw(fatalsToBrowser);

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
my ($file,$entity,$netaddr,$fullname, $value);


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
    $o = trb_register_read($netaddr,$obj->{address}+$slice*$stepsize);
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
      trb_register_write($b,$obj->{address}+$slice*$stepsize,$new);
      }
    }
  else {
    my $mask = ~(((1<<$obj->{bits})-1) << $obj->{start});
    my $new = $value & ((1<<$obj->{bits})-1); 
    $new = $new << $obj->{start};

    trb_register_loadbit($netaddr,$obj->{address}+$slice*$stepsize,~$mask,$new);
    }
    
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



