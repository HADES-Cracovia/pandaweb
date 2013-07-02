#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML;
#use XML::LibXML::Debugging;
#use XML::LibXML::Iterator;
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
my $db_dir = "$RealBin/database";
my $dump_database = 0;

Getopt::Long::Configure(qw(gnu_getopt));
GetOptions(
           'help|h' => \$help,
           'man' => \$man,
           'verbose|v+' => \$verbose,
           'warnings|w!' => \$warnings,
           'db-dir=s' => \$db_dir,
           'dump' => \$dump_database
          ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

# tell something about the configuration
if ($verbose) {
  print STDERR "Database directory: $db_dir\n";
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
  # load the unmerged database and the provided files
  my ($db,$files) = &LoadDBAndFiles(@ARGV);


  # this ref holds all the vital "information". There's a merged
  # TrbNetEntity-based document at
  # $merged->{$trbaddress}->{$base_address}
  my $merged = {};

  foreach my $item (@$files) {
    my $file = $item->[0];
    my $doc = $item->[1];

    foreach my $trbnode ($doc->getDocumentElement->findnodes('trb')) {
      # Note: we cannot first collect all the <trb> nodes and then
      # work on them as a whole (this would limit the possibilites in
      # a setup file...)
      my $trbaddress = EvaluateTrbNode($db, $trbnode, $merged);
      WorkOnEntities($merged->{$trbaddress});
    }
  }
}

sub WorkOnEntities($) {
  my $entities = shift;
  # first, we need to expand the repeat/size statements and calculate
  # the "real" register address (but still relative to parent!). we do
  # this on a cloned copy of the document, since each trb node might
  # change this!
  foreach my $e (keys %$entities) {
    my $doc = $entities->{$e}->cloneNode(1);
    print $e,"\n";
    foreach my $reg ($doc->findnodes('//register[@repeat]')) {
      print $reg->getAttribute('repeat'),"\n";
    }
    # first expand registers
    
  }
}

sub EvaluateTrbNode($$$) {
  my $db = shift;
  my $trbnode = shift;
  my $merged = shift;

  my $trbaddress = $trbnode->getAttribute('address');
  PrintMessage($trbnode, "Evaluating <trb> at 0x$trbaddress") if $verbose;
  foreach my $node ($trbnode->findnodes('entity')) {
    my $ref = $node->getAttribute('ref');
    # check if we know this type
    PrintMessage($node, "Fatal Error: Entity reference $ref not found in database", 1)
      unless defined $db->{$ref};

    # use the provided base address for the registers of the entity
    # or the default one from the db
    my $base_address = $node->getAttribute('address') ||
      $db->{$ref}->{'Doc'}->getDocumentElement->getAttribute('address');
    # check if we know already something about that entity at this
    # trbaddress and base_address...then use this, otherwise use the
    # a cloned entity from the database as a starting point
    unless (defined $merged->{$trbaddress} and
            defined $merged->{$trbaddress}->{$base_address}) {
      PrintMessage($node, "Cloning entity from database") if $verbose>1;
      # clone deeply (argument = 1)
      $merged->{$trbaddress}->{$base_address} = $db->{$ref}->{'Doc'}->cloneNode(1);
    }

    # define a shortcut for the reference to the full entity (to be further modified!)
    my $entity = $merged->{$trbaddress}->{$base_address};

    # now we apply the changes $entitynode (provided by elements
    # like field, register, group, ...) to the "full" TrbNetEntity
    # in $entity
    foreach my $elem ($node->findnodes('*')) {
      # try to find the element in $e specified by its unique name
      # attribute
      MergeElementIntoEntity($entity, $elem)
    }

    # after the merging, we can validate $entity again
    # now having a nice schema really pays off!
    eval { $db->{$ref}->{'Schema'}->validate($entity) };
    if ($@) {
      print $entity->toString(2,1) if $verbose>2;
      PrintMessage($node,
                   "Fatal Error: Merged entity is not valid anymore:\n$@",1);
    }
  }

  # the really relevant information is in the reference $merged,
  # so not returned here
  return $trbaddress;
}

sub MergeElementIntoEntity($$) {
  # note that merging two XML nodes is not simple and
  # thus not in all cases well-defined
  my $entity = shift;
  my $elem = shift;

  my $uniquename = $elem->getAttribute('name');
  my $xpath = sprintf('//%s[@name="%s"]',
                      $elem->nodeName,
                      $uniquename);
  my $e_node = $entity->findnodes($xpath);
  if ($e_node->size == 0) {
    PrintMessage($elem, "Warning: XPath $xpath not found in database entity, skipping") if $warnings;
    next;
  } elsif ($e_node->size > 1) {
    # this should never happen due to schema restrictions, but
    # check again here...
    PrintMessage($elem, "Fatal Error: XPath $xpath found more than once in entity, i.e. ".
                 "$uniquename not unique!", 1);
  }

  # now apply the changes to that single node
  $e_node = $e_node->shift;
  PrintMessage($elem, "Merging entity item <$uniquename>") if $verbose;
  PrintMessage($elem, "Before merge:\n".$e_node->toString(2)) if $verbose>2;

  # override the attributes (using nice tied hash functionality)
  foreach my $attr (keys %$elem) {
    next if $attr eq 'name';
    $e_node->setAttribute($attr, $elem->{$attr});
  }

  # appending all additional elements
  foreach my $subelem ($elem->findnodes('*')) {
    $e_node->appendChild($subelem);
  }

  # delete all text node, and add the new text (effectively overriding)
  $e_node->findnodes('text()')->map(sub {$e_node->removeChild($_)});
  $e_node->appendChild(XML::LibXML::Text->new($elem->textContent));

  PrintMessage($elem, "After merge:\n".$e_node->toString(2)) if $verbose>2;
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
  # we ignore all files on cmd line
  my ($db, undef) = &LoadDBAndFiles;
  my %entities = map { $_ => 1 } @ARGV;
  my $num = scalar keys %entities;
  foreach my $entity (keys %$db) {
    next if $num>0 and not exists $entities{$entity};
    print "Dumping Entity <$entity>:\n" if $num>1;
    DumpDocument($db->{$entity}->{'Doc'});
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
      print STDERR "Loaded schema <$_> from database\n" if $verbose>1;
    }

    # load the xml files in the database
    while (<*.xml>) {
      my $doc = $parser->parse_file($_);
      my $schema = ValidateXML($doc, $schemas);
      my $dbname = $doc->getDocumentElement->getAttribute('name');
      die "File <$_>: Entity with name $dbname already exists in database"
        if exists $db->{$dbname};
      $db->{$dbname}->{'Doc'} = $doc;
      $db->{$dbname}->{'Schema'} = $schema;
      print STDERR "Loaded and validated entity <$dbname> from database <$_>\n" if $verbose>1;
    }
  }

  # now, back in the normal working directoy, load and
  # validate the provided files
  my $files = [];
  for (@_) {
    my $doc = $parser->parse_file($_);
    ValidateXML($doc, $schemas);
    push(@$files, [$_, $doc]);
    print STDERR "Loaded and validated <$_>\n" if $verbose>1;
    #print "Encoding: ", $doc->getEncoding, "\n";
  }

  return ($db, $files);
}

sub ValidateXML($$) {
  my $doc = shift;
  my $schemas = shift;
  my $xsd_file = $doc->getDocumentElement->getAttribute('xsi:noNamespaceSchemaLocation');
  die "Schema $xsd_file not found to validate <$_>" unless defined $schemas->{$xsd_file};
  $schemas->{$xsd_file}->validate($doc);
  return $schemas->{$xsd_file};
}


#print $xsd;


__END__

=head1 NAME

xml-db.pl - Manipulate the TrbNet descriptively using XML

=head1 SYNOPSIS

xml-db.pl [options] [xml file(s)]
xml-db.pl --dump [entity names]

 Options:
   -h, --help     brief help message
   -v, --verbose  be verbose to STDERR
   -w, --warnings print warnings to STDERR
   --db-dir       database directory
   -g, --generate generate config xml file (smart guessing from TrbNet)
   -s, --save     save all config fields from TrbNet in xml file
   -l, --restore  load config fields into TrbNet from xml file
   --dump         dump the database as tree, restricted to given entity names

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
