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

Getopt::Long::Configure(qw(gnu_getopt));
GetOptions(
           'help|h' => \$help,
           'verbose|v+' => \$verbose,
          ) or pod2usage(2);
pod2usage(1) if $help;


###############################
#### Check arguments for validity
###############################
my $file = "$RealBin/cache/$ARGV[0].entity";
die "Entity $file not found.\n" unless(-e $file) ;
die "DAQOPSERVER not set in environment" unless (defined $ENV{'DAQOPSERVER'});
die "can not connect to trbnet-daemon on $ENV{'DAQOPSERVER'}: ".trb_strerror() unless (defined &trb_init_ports());
  
my $netaddr = $ARGV[1] || "";
if    ($netaddr=~ m/0x([0-9a-fA-F]{4})/) {$netaddr = hex($1);}
elsif ($netaddr=~ m/([0-9]{1,5})/) {$netaddr = $1;}
else {die "Could not parse address $netaddr\n";}

my $name = $ARGV[2] || "";
my $slice = -1;
if    ($name =~ m/^([a-zA-Z0-9]+)(\.\d+)$/) {$name = $1; $slice = $2;}
elsif ($name =~ m/^([a-zA-Z0-9]+)$/)       {$name = $1; $slice = -1;}
else {die "Could not parse name $name \n";}

my $db = lock_retrieve($file);
die "Unable to read cache file\n" unless defined $db;

die "Name not found in entity file\n" unless(exists $db->{$name});

my $obj = $db->{$name};  

print DumpTree($obj) if $verbose;  




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
#       <xs:enumeration value="string"/>

###############################
#### Do Trbcmd access
###############################
my $o;
if($obj->{type} eq "register" || $obj->{type} eq "registerfield" || $obj->{type} eq "field") {
  $o = trb_register_read($netaddr,$obj->{address});
  print DumpTree($o) if $verbose>1;
  }

  
  
###############################
#### Prepare table header line
###############################

my @fieldlist;
push(@fieldlist,("Board","Reg."));
if($obj->{type} eq "register" || $obj->{type} eq "registerfield" || $obj->{type} eq "field") {
  push(@fieldlist,"raw");
  }

if($obj->{type} eq "registerfield"){
  push(@fieldlist,$name) ;
  }

if($obj->{type} eq "field"){
  push(@fieldlist,$name) ;
  }
  
if($obj->{type} eq "register"){
  foreach my $c (@{$obj->{children}}){
    push(@fieldlist,$c);
    }
  }
  
my $t = Text::TabularDisplay->new(@fieldlist);

  
  
###############################
#### Fill table with information
###############################
foreach my $b (sort keys %$o) {
  my @l;
  push(@l,sprintf("%04x",$b));
  push(@l,sprintf("%04x",$obj->{address}));
  push(@l,sprintf("%08x",$o->{$b}));
  if($obj->{type} eq "register") {
    foreach my $c (@{$obj->{children}}) {
      push(@l,FormatPretty($o->{$b},$db->{$c}));
      }
    }
  elsif($obj->{type} eq "field" || $obj->{type} eq "registerfield") {
    push(@l,FormatPretty($o->{$b},$obj));
    }
  $t->add(@l);
  }

  
  
###############################
#### Show the beautiful result...
###############################  
print $t->render;
    
print "\n";    

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
