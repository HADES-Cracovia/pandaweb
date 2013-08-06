#!/usr/bin/perl -w
use warnings;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use Data::TreeDumper;
use HADES::TrbNet;
use Date::Format;
use Pod::Usage;
use Getopt::Long;
use File::chdir;
use FindBin qw($RealBin);
use Storable qw(lock_retrieve);
use Text::TabularDisplay;
use feature "switch";


my $help = 0;
my $verbose = 0;
my $isbrowser = 0;

my ($file,$netaddr,$name, $option);
$ENV{'DAQOPSERVER'}="localhost:7" unless (defined $ENV{'DAQOPSERVER'});

###############################
#### Check if browser or command line
###############################
if(defined $ENV{'QUERY_STRING'}) {
  $isbrowser = 1;
  ($file,$netaddr,$name,$option) = split("-",$ENV{'QUERY_STRING'});
  $file = "$RealBin/cache/$file.entity";
  use CGI::Carp qw(fatalsToBrowser);
  print "Content-type: text/html\n\n";
  }
else {
  Getopt::Long::Configure(qw(gnu_getopt));
  GetOptions(
            'help|h' => \$help,
            'verbose|v+' => \$verbose,
            ) or pod2usage(2);
  pod2usage(1) if $help;
  
  $file    = "$RealBin/cache/$ARGV[0].entity";
  $netaddr = $ARGV[1] || "";
  $name    = $ARGV[2] || "";
  }


###############################
#### Check arguments for validity
###############################

die "Entity $file not found.\n" unless(-e $file) ;
die "DAQOPSERVER not set in environment" unless (defined $ENV{'DAQOPSERVER'});
die "can not connect to trbnet-daemon on $ENV{'DAQOPSERVER'}: ".trb_strerror() unless (defined &trb_init_ports());
  
if    ($netaddr=~ m/0x([0-9a-fA-F]{4})/) {$netaddr = hex($1);}
elsif ($netaddr=~ m/([0-9]{1,5})/) {$netaddr = $1;}
else {die "Could not parse address $netaddr\n";}


my $slice = undef;
if    ($name =~ m/^([a-zA-Z0-9]+)\.(\d+)$/) {$name = $1; $slice = $2;}
elsif ($name =~ m/^([a-zA-Z0-9]+)$/)       {$name = $1; $slice = undef;}
else {die "Could not parse name $name \n";}

my $db = lock_retrieve($file);
die "Unable to read cache file\n" unless defined $db;

die "Name not found in entity file\n" unless(exists $db->{$name});

###############################
#### Main "do the job"
###############################

my $once = (defined $slice)?1:0;
runandprint($db->{$name},$name,$slice,$once);


 
###############################
#### Formatting of values
###############################
sub FormatPretty {
  my ($value,$obj) = @_;
  $value  = $value >> ($obj->{start});
  $value &= ((1<<$obj->{bits})-1);
  
  my $ret;
  for($obj->{format}) {
    when ("boolean")  {$ret = $value?"true":"false";}
    when ("integer")  {$ret = sprintf("%i",$value);}
    when ("unsigned") {$ret = sprintf("%u",$value);}
    when ("signed")   {$ret = sprintf("%d",$value);}
    when ("binary")   {$ret = sprintf("%b",$value);}
    when ("bitmask")  {$ret = sprintf("%b",$value);}
    when ("time")     {$ret = time2str('%Y-%m-%d %H:%M',$value);}
    when ("hex")      {$ret = sprintf("%8x",$value);}
    when ("enum")     { my $t = sprintf("%x",$value);
                        if (exists $obj->{enumItems}->{$t}) {
                          $ret = $obj->{enumItems}->{$t} 
                          }
                        else {
                          $ret = $t;
                          }
                        }
    default           {$ret = sprintf("%08x",$value);}
    }
  
  return $ret;
  }

  
###############################
#### Analyze Object & print contents
###############################
sub runandprint {
  my ($obj,$name,$slice,$once) = @_;
  my $o;
  print DumpTree($obj) if $verbose;  
  #### Iterate if group
  if($obj->{type} eq "group") {
    foreach my $c (@{$obj->{children}}) {
      runandprint($db->{$c},$c,$slice,$once);
      }
    }
  
  #### print if entry is a register or field
  elsif($obj->{type} eq "register" || $obj->{type} eq "registerfield" || $obj->{type} eq "field") {
    print DumpTree($o) if $verbose>1;
    
    my $stepsize = $obj->{stepsize} || 1;
       $slice = 0 unless defined $slice;

  
    do {
    
      $o = trb_register_read($netaddr,$obj->{address}+$slice*$stepsize);
      
      #### Prepare table header line
      my $t;
      my @fieldlist;
      push(@fieldlist,("Board","Reg."));
      push(@fieldlist,"raw");

      if($obj->{type} eq "registerfield"){
        push(@fieldlist,$name);
        }
      elsif($obj->{type} eq "field"){
        push(@fieldlist,$name) ;
        }
      elsif($obj->{type} eq "register"){
        foreach my $c (@{$obj->{children}}){
          push(@fieldlist,$c);
          }
        }
        
      if($isbrowser == 0) {
        $t = Text::TabularDisplay->new(@fieldlist);
        }
      else {
        if($once == 1 || $slice == 0) {
          $t = "<table class='queryresult'><tr><th>";
          $t .= join("<th>",@fieldlist);
          }
        else{ 
          $t = "";
          }
        }

      #### Fill table with information
      foreach my $b (sort keys %$o) {
        my @l;
        push(@l,sprintf("%04x",$b));
        push(@l,sprintf("%04x",$obj->{address}+$slice*$stepsize));
        push(@l,sprintf("%08x",$o->{$b}));
        if($obj->{type} eq "register") {
          foreach my $c (@{$obj->{children}}) {
            push(@l,FormatPretty($o->{$b},$db->{$c}));
            }
          }
        elsif($obj->{type} eq "field" || $obj->{type} eq "registerfield") {
          push(@l,FormatPretty($o->{$b},$obj));
          }
        if($isbrowser == 0) {
          $t->add(@l);
          }
        else {
          $t .= "<tr>";
          $t .= join("<td>",@l);
          }
        }
      
      #### Show the beautiful result...
      if($isbrowser == 0) {
        print $t->render;
        }
      else {
        print $t;
        print "</table>" if ($once == 1 || !defined $obj->{repeat} || $slice == $obj->{repeat}-1);
        }
      print "\n";    
      } while($once != 1 && defined $obj->{repeat} && ++$slice < $obj->{repeat})
    }
    
  }
  
  
  
  
  
  
###############################
#### Feierabend!
###############################     
__END__

=head1 NAME

get.pl - Access TrbNet elements with speaking names and formatted output

=head1 SYNOPSIS

get.pl entity address name

 Options:
   -h, --help     brief help message
   -v, --verbose  be verbose to STDERR

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--verbose>

Print some information what is going on.

=back

=head1 DESCRIPTION

=cut
