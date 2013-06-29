#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML;
use XML::LibXML::Debugging;
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
if($verbose) {
  print "Database directory: $db_dir\n";
}

# jump to subroutine which handles the job,
# depending on the options
&Main;

sub Main {
  # load the unmerged database
  my $db = &LoadDB;

  DoSomethingWithDb($db);
}

sub DoSomethingWithDb($) {
  my $db = shift;

  my $doc = $db->{'TDC.xml'};
  #my $doc = $db->{'testing.xml'};
  #print Dumper($doc->findnodes('TrbNet')->toDebuggingHash);
  # get the iterator for the document root.
  #my $iter = XML::LibXML::Iterator->new( $doc->documentElement );

  my $entityName = $doc->getDocumentElement->getAttribute('name');
  my $entityAddr = hex($doc->getDocumentElement->getAttribute('address'));

  # walk through the document, we select all groups
  foreach my $groupNode ($doc->findnodes('//group')) {
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
              $name, $field->getAttribute('name'));
        #print $field->getAttribute('errorflag'),"\n";
      }
    }
  }
}

sub GetBaseNameAndAddress($) {
  my $node = shift;
  
  #return ($baseName, $baseAddress);
}

sub LoadDB {
  # change to he db_dir here in this subroutine
  local $CWD = $db_dir;

  # we first load the schemas and parse them
  # so we can validate the XML files
  my %schemas = ();
  while(<*.xsd>) {
    $schemas{$_} = XML::LibXML::Schema->new(location => $_);
    print "Loaded schema <$_>\n" if $verbose;
  }

  # load the xml files
  my $parser = XML::LibXML->new(line_numbers => 1);
  my $db = {};
  while(<*.xml>) {
    my $doc = $parser->parse_file($_);
    my $xsd_file = $doc->getDocumentElement->getAttribute('xsi:noNamespaceSchemaLocation');
    die "Schema $xsd_file not found to validate <$_>" unless defined $schemas{$xsd_file};
    $schemas{$xsd_file}->validate($doc);
    $db->{$_} = $doc;
    print "Loaded and validated <$_>\n" if $verbose;
  }
  return $db;
}






#print $xsd;


__END__

=head1 NAME

xml-db.pl - Access the TRB XML Database

=head1 SYNOPSIS

xml-db.pl [options] [config file]

 Options:
   -h, --help    brief help message
   -v, --verbose be verbose
   --xml-db_dir  database directory

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
