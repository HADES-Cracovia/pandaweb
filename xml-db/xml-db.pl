#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML;
use Data::TreeDumper;
use Getopt::Long;
use Pod::Usage;
use File::chdir;
use FindBin qw($RealBin);
use Data::Dumper;


# some default config options
# and provide nice help documentation
# some global variables, needed everywhere

my $man = 0;
my $help = 0;
my $verbose = 0;
my $warnings = 1;
my $dir = $RealBin;
my $dump_database = 0;
my $force = 0;

Getopt::Long::Configure(qw(gnu_getopt));
GetOptions(
           'help|h' => \$help,
           'man' => \$man,
           'verbose|v+' => \$verbose,
           'warnings|w!' => \$warnings,
           'dir=s' => \$dir,
           'dump' => \$dump_database,
           'force|f=s' => \$force
          ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

my $db_dir = "$dir/database";
my $schema_dir = "$dir/schema";


# tell something about the configuration
if ($verbose) {
  print STDERR "Database directory: $db_dir\n";
  print STDERR "Schema directory: $schema_dir\n";
  # always enable warnings if verbose
  $warnings = 1;
}

# jump to subroutine which handles the job,
# depending on the options

if ($dump_database) {
  &DumpDatabase;
} else {
  &Main;
}

sub Main {

}


sub PrintMessage($$) {
  my $node = shift;
  my $file = $node->ownerDocument->URI;
  my $line = $node->line_number;
  my $msg = shift;
  print STDERR "$file:$line: $msg\n";
  # third command indicates fatal error message,
  # so exit...
  exit 1 if shift;
}

sub DumpDatabase($) {
  my %entities = map { $_.'.xml' => 1 } (@ARGV);
  my $num = scalar keys %entities;
  local $CWD = $db_dir;
  while(<*.xml>) {
    next if $num>0 and not defined $entities{$_};
    my($doc,$name) = LoadXML($_);
    DumpDocument($doc);
  }
}

sub DumpDocument($) {
  my $doc = shift;

  my $entityName = $doc->getDocumentElement->getAttribute('name');
  my $entityAddr = hex($doc->getDocumentElement->getAttribute('address'));

  # recursively populate tree and print it
  my $tree = {};
  IterateChildren($tree, $doc->getDocumentElement, $entityAddr);
  print DumpTree($tree, $entityName,
                 USE_ASCII => 0, DISPLAY_OBJECT_TYPE => 0,
                 DISPLAY_ADDRESS => 0, NO_NO_ELEMENTS => 1);

}

sub IterateChildren {
  my $tree = shift;
  my $node = shift;
  my $baseaddress = shift;
  my $inrepeat = shift || 0;

  # now iterate over all children
  foreach my $curNode ($node->findnodes('register | memory | fifo | group')) {
    my $name = $curNode->getAttribute('name');
    my $address = $baseaddress+hex($curNode->getAttribute('address'));
    my $nodeName = $curNode->nodeName;
    if ($nodeName eq 'group') {
      my $key = $name;
      my $repeat = $curNode->getAttribute('repeat') || 1;
      $key .= $repeat>1 ? " x $repeat" : '';
      $tree->{$key} = {};
      IterateChildren($tree->{$key}, $curNode, $address, $repeat>1 || $inrepeat);
    } else {
      my $repeat = $curNode->getAttribute('repeat') || $inrepeat;
      my $key = '';
      $key .= sprintf('%04x', $address);
      $key .= $repeat ? '* ' : ' ';
      if ($nodeName ne 'register') {
        $key .= "($nodeName) ";
      }
      $key .= $name;
      $key .= $repeat>1 ? " x $repeat" : '';

      $tree->{$key} = {};

      my $fields = $curNode->findnodes('field');

      next if $fields->size < 2;
      foreach my $field (@$fields) {
        my $fieldname = $field->getAttribute('name');
        $tree->{$key}->{$fieldname} = [];
      }
    }
  }

}

BEGIN {
  # declare the variables $schemas and $parser persistent here
  my $parser = XML::LibXML->new(line_numbers => 1);
  my $schemas = {};

  sub LoadXML {
    my $filename = shift;
    local $CWD = $db_dir;
    my $doc = $parser->parse_file($filename);
    ValidateXML($doc);
    my $dbname = $doc->getDocumentElement->getAttribute('name');
    print STDERR "Loaded and validated entity <$dbname> from database <$filename>\n" if $verbose>1;
    return ($doc, $dbname);
  }

  sub ValidateXML {
    my $doc = shift;
    my $xsd_file = $doc->getDocumentElement->getAttribute('xsi:noNamespaceSchemaLocation');
    # Strip filename from path to select proper schema
    ($xsd_file) = $xsd_file =~ m%.*/([^/]*)$%;
    my $schema = LoadSchema($xsd_file);
    $schema->validate($doc);
  }

  sub LoadSchema {
    my $filename = shift;
    local $CWD = $schema_dir;
    unless (defined $schemas->{$filename}) {
      $schemas->{$filename} = XML::LibXML::Schema->new(location => $filename);
      print STDERR "Loaded schema <$filename> from database\n" if $verbose>1;
    }
    return $schemas->{$filename};
  }
}

__END__

=head1 NAME

xml-db.pl - Create cached data structures from the XML entities

=head1 SYNOPSIS

xml-db.pl
xml-db.pl --dump [entity names]

 Options:
   -h, --help     brief help message
   -v, --verbose  be verbose to STDERR
   -w, --warnings print warnings to STDERR
   --dir          directory that contains database and schema subdirs
   -f, --force    update all cache entries, regardless of their timestamp
   --dump         dump the database as tree, restricted to given entity names

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--verbose>

Print some information what is going on.

=item B<--dir>

Set the base directory where the default XML files can be found in sub-directories database and schema.

=back

=head1 DESCRIPTION

B<This program> updates the cache directory from the provided XML
files in the database directory.

=cut
