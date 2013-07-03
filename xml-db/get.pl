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

my $help = 0;
my $verbose = 0;

Getopt::Long::Configure(qw(gnu_getopt));
GetOptions(
           'help|h' => \$help,
           'verbose|v+' => \$verbose,
          ) or pod2usage(2);
pod2usage(1) if $help;



if(!defined $ENV{'DAQOPSERVER'}) {
  die "DAQOPSERVER not set in environment";
}
  
if (!defined &trb_init_ports()) {
  die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
}


__END__

=head1 NAME

get.pl - Access TrbNet elements with speaking names and formatted output

=head1 SYNOPSIS

get.pl
get.pl address entity name

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
