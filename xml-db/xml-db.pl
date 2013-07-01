#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML;
#use XML::LibXML::Debugging;
#use XML::LibXML::Iterator;
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
my $db_dir = "$RealBin/database";

GetOptions(
           'help|h' => \$help,
           'man' => \$man,
           'verbose|v+' => \$verbose,
           'db-dir=s' => \$db_dir
          ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

# tell something about the configuration
if ($verbose) {
  print "Database directory: $db_dir\n";
}

# jump to subroutine which handles the job,
# depending on the options
&Main;

sub Main {
  # load the unmerged database and the provided files
  my ($db,$files) = &LoadDBAndFiles;

  #print Dumper($files);
  foreach my $item (@$files) {
    my $file = $item->[0];
    my $doc = $item->[1]; print "Working on $file...\n" if $verbose;
    my $merged = {};
    foreach my $trbnode ($doc->getDocumentElement->findnodes('trb')) {
      my $trbaddress = $trbnode->getAttribute('address');
      print $trbaddress,"\n";
      foreach my $entitynode ($trbnode->findnodes('entity')) {
        my $type = $entitynode->getAttribute('type');
        # check if we know this type
        FatalError($entitynode, "Entity type $type not found in database")
          unless defined $db->{"$type.xml"};
        
        print $type,"\n";
      }
    }
  }
  # testing...
  #DumpDatabase($db);
}

sub FatalError($$) {
  my $node = shift;
  my $file = $node->ownerDocument->URI;
  my $line = $node->line_number;
  my $msg = shift;
  print "$file:$line: Fatal Error: $msg\n";
  exit 1;
}

sub DumpDatabase($) {
  my $db = shift;
  foreach my $file (keys %$db) {
    print "Dumping $file...\n";
    DumpDocument($db->{$file});
  }
}

sub DumpDocument($) {
  my $doc = shift;
  #my $doc = $db->{'testing.xml'};
  #my $doc = $db->{'jtag_registers_SPEC.xml'};
  #print Dumper($doc->findnodes('TrbNet')->toDebuggingHash);
  # get the iterator for the document root.
  #my $iter = XML::LibXML::Iterator->new( $doc->documentElement );

  my $entityName = $doc->getDocumentElement->getAttribute('name');
  my $entityAddr = hex($doc->getDocumentElement->getAttribute('address'));

  # walk through the document, we select all groups and the top entity
  foreach my $groupNode ($doc->findnodes('//group | TrbNetEntity')) {
    # determine base name (concatenated by /)
    # and base address (just add all previous offsets)
    my $baseaddress = $entityAddr;
    my $basename = $entityName;
    foreach my $anc ($groupNode->findnodes('ancestor-or-self::group')) {
      $baseaddress += hex($anc->getAttribute('address'));
      $basename .= '/'.$anc->getAttribute('name');
    }

    # now iterate over all children
    foreach my $curNode ($groupNode->findnodes('register | memory | fifo')) {
      #print $curNode->nodeName,"\t",$curNode->nodePath,"\n";
      my $name = $basename.'/'.$curNode->getAttribute('name');
      my $address = $baseaddress+hex($curNode->getAttribute('address'));
      #printf("%s %04x\n\n",$name,$address);
      foreach my $field ($curNode->findnodes('field')) {
        printf("%04x:%02d:%02d %s/%s\n", $address,
               $field->getAttribute('start'),
               $field->getAttribute('size') || 1,
               $name, $field->getAttribute('name')
              );

        #print $field->getAttribute('errorflag') || 'false',"\n";
      }
    }
  }
}


sub LoadDBAndFiles {
  my $schemas = {};
  my $db = {};
  my $parser = XML::LibXML->new(line_numbers => 1);

  {
    # change to the db_dir in the first part
    local $CWD = $db_dir;


    # we first load the schemas and parse them
    # so we can validate the XML files
    while (<*.xsd>) {
      $schemas->{$_} = XML::LibXML::Schema->new(location => $_);
      print "Loaded schema <$_> from database\n" if $verbose;
    }

    # load the xml files in the database
    while (<*.xml>) {
      my $doc = $parser->parse_file($_);
      ValidateXML($doc, $schemas);
      $db->{$_} = $doc;
      print "Loaded and validated <$_> from database\n" if $verbose;
    }
  }

  # now, back in the normal working directoy, load and
  # validate the provided files
  my $files = [];
  for (@ARGV) {
    my $doc = $parser->parse_file($_);
    ValidateXML($doc, $schemas);
    push(@$files, [$_, $doc]);
    print "Loaded and validated <$_>\n" if $verbose;
  }

  return ($db, $files);
}

sub ValidateXML($$) {
  my $doc = shift;
  my $schemas = shift;
  my $xsd_file = $doc->getDocumentElement->getAttribute('xsi:noNamespaceSchemaLocation');
  die "Schema $xsd_file not found to validate <$_>" unless defined $schemas->{$xsd_file};
  $schemas->{$xsd_file}->validate($doc);
}


#print $xsd;


__END__

=head1 NAME

xml-db.pl - Manipulate the TrbNet descriptively using XML

=head1 SYNOPSIS

xml-db.pl [options] [xml file(s)]

 Options:
   -h, --help     brief help message
   -v, --verbose  be verbose
   --db-dir       database directory
   -g, --generate generate config xml file (smart guessing from TrbNet)
   -s, --save     save all config fields from TrbNet in xml file
   -l, --restore  load config fields into TrbNet from xml file

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--verbose>

Print some information what is going on.

=item B<--db-dir>

Set the database directory where the default XML files can be found.

=back

=head1 DESCRIPTION

B<This program> provides basic access to the XML database describing
the TRB registers.

=cut
