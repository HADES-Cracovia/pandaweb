#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML;
use Getopt::Long;
use Pod::Usage;
use FindBin qw($RealBin);
use Data::Dumper;

# some default config options
# and provide nice help documentation

my $man = 0;
my $help = 0;
my $verbose = 0;
my $db_dir = "$RealBin/database";

GetOptions(
           'help|h' => \$help,
           'man' => \$man,
           'verbose|v+' => \$verbose
          ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

print "Database: $db_dir\n" if $verbose;

my $doc = XML::LibXML->new->parse_file("$db_dir/testing.xml");
my $xmlschema = XML::LibXML::Schema->new('location' => "$db_dir/".
                                         $doc->getDocumentElement->getAttribute('xsi:noNamespaceSchemaLocation'));

$xmlschema->validate($doc);

#print $xsd;


__END__

=head1 NAME

xml-db.pl - Access the TRB XML Database

=head1 SYNOPSIS

xml-db.pl [options] [config file]

 Options:
   -h, --help     brief help message
   --xml-db_dir  database directory

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--db-dir>

Set the database directory where the default XML files can be found.

=back

=head1 DESCRIPTION

B<This program> provides basic access to the XML database describing
the TRB registers.

=cut
