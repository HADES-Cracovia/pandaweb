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


my $help = 0;
my $verbose = 0;

Getopt::Long::Configure(qw(gnu_getopt));
GetOptions(
           'help|h' => \$help,
           'verbose|v+' => \$verbose,
          ) or pod2usage(2);
pod2usage(1) if $help;

my $file = "$RealBin/cache/$ARGV[0].entity";
unless(-e $file) {
  die "Entity $file not found.\n";
  }
  
my $netaddr = $ARGV[1] || "";
if    ($netaddr=~ m/0x([0-9a-fA-F]{4})/) {$netaddr = hex($1);}
elsif ($netaddr=~ m/([0-9]{1,5})/) {$netaddr = $1;}
else {die "Could not parse address $netaddr\n";}

my $name = $ARGV[2] || "";
my $slice = -1;
if    ($name =~ m/^([a-zA-Z0-9]+)(.\d+)$/) {$name = $1; $slice = $2;}
elsif ($name =~ m/^([a-zA-Z0-9]+)$/)       {$name = $1; $slice = -1;}
else {die "Could not parse name $name \n";}


if(!defined $ENV{'DAQOPSERVER'}) {
  die "DAQOPSERVER not set in environment";
}
  
if (!defined &trb_init_ports()) {
  die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
}

my $db = lock_retrieve($file);
die "Unable to read cache file\n" unless defined $db;





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
