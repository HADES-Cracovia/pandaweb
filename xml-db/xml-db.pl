#!/usr/bin/perl
use strict;
use warnings;

use XML::LibXML;
# use Data::TreeDumper;
use Getopt::Long;
use Pod::Usage;
use File::chdir;
use FindBin qw($RealBin);
use Data::Dumper;
use Storable qw(lock_store);

# some default config options
# and provide nice help documentation
# some global variables, needed everywhere

my $man = 0;
my $help = 0;
my $verbose = 0;
my $warnings = 1;
my $dir = $RealBin;
my $dump = 0;
my $dumpitem;

Getopt::Long::Configure(qw(gnu_getopt));
GetOptions(
           'help|h' => \$help,
           'man' => \$man,
           'verbose|v+' => \$verbose,
           'warnings|w!' => \$warnings,
           'dir=s' => \$dir,
           'dump' => \$dump,
           'dumpitem|i=s' => \$dumpitem
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


&Main;

sub Main {
  # ensure a cache directory exists
  local $CWD = $dir;
  (mkdir 'cache' or die "Can't create cache directory") unless -d 'cache';

  my @docs;
  {
    local $CWD = $db_dir;
    my %filter;
    foreach (@ARGV) {
      $_ = "$_.xml" unless /\.xml$/;
      $filter{$_} = 1;
    }
    my $num = scalar @ARGV;
    while (<*.xml>) {
      next if $num>0 and not defined $filter{$_};
      my $doc = LoadXML($_);
      if ($dump) {
        DumpDocument($doc);
        next;
      }
      push(@docs, $doc);
    }
  }

  foreach my $doc (@docs) {
    my $db = WorkOnDoc($doc);
    #print Dumper($db->{'BasicStatus'});
    #print Dumper($db->{'ChannelEnable'});
    #print Dumper($db->{'ReadoutFSM'});
    #print Dumper($db->{'JtagErrorCount1'});
    #print Dumper($db->{'JtagLastDataChanged'});
    my $name = $doc->getDocumentElement->getAttribute('name');
    if($dumpitem) {
      foreach my $key (keys %$db) {
        next unless $key =~ /$dumpitem/;
        my $item = $db->{$key};
        $item->{address} = sprintf("0x%04x",$item->{address});
        MyDumpTree($item,"$key (in entity $name)");
      }
      next;
    }
    #print DumpTree($db);
    my $cachefile = "cache/$name.entity";
    lock_store($db, $cachefile);
    print STDERR "Wrote $cachefile\n" if $verbose>0;
#     print STDERR "\n",DumpTree($db,$name),"\n" if $verbose>2;
  }


}

sub WorkOnDoc {
  my $doc = shift;
  my $db = {};

  # add the name of the entity as some special key (starting with §)
  # this is later on needed by get.pl to determine how to obtain data
  $db->{'§EntityType'} = $doc->getDocumentElement->nodeName;

  # we populate first the db. then we can check when adding the
  # children that they exist, and we can also handle the special case
  # when a node has the same name as the single field it contains
  my $nodelist = $doc->findnodes('//register | //memory | //fifo | //group');
  foreach my $node (@$nodelist) {
    my $name = $node->getAttribute('name');
    # this check should also be enforced by the schema, but
    # double-check can't harm
    PrintMessage($node, "Fatal Error: Name $name is not unique", 1) if defined $db->{$name};
    $db->{$name} = MakeOrMergeDbItem($node);
  }

  # now add the children and the fields
  foreach my $node (@$nodelist) {
    my $name = $node->getAttribute('name');
    my $dbitem = $db->{$name};

    #print $n->nodeName," ",$name," ",$children->size,"\n";

    my $children = $node->findnodes('group | register | memory | fifo | field');

    # if there's only one child...
    if ($children->size==1) {
      my $childnode = $children->get_node(1);
      my $childname = $childnode->getAttribute('name');
      # ...and it's a field with the same name as the parent,
      # we merge that
      if ($childnode->nodeName eq 'field' and $childname eq $name) {
        PrintMessage($childnode, "Merging field $childname into parent") if $verbose>1;
        MakeOrMergeDbItem($childnode, $dbitem);
        next;
      }
    }

    foreach my $childnode (@$children) {
      my $childname = $childnode->getAttribute('name');

      if ($childnode->nodeName eq 'field') {
        $db->{$childname} = MakeOrMergeDbItem($childnode);
      } elsif (not defined $db->{$childname}) {
        PrintMessage($childnode, "Fatal Error: Child $childname of $name not found in database", 1)
      }
      push(@{$dbitem->{'children'}}, $childname);
    }
  }


  # add a HeadNode with its top-level children
  my $headnode = {};
  my $hn_children = $doc->getDocumentElement->findnodes('group | register | memory | fifo');
  foreach my $childnode (@$hn_children) {
    my $childname = $childnode->getAttribute('name');

    if (not defined $db->{$childname}) {
      PrintMessage($childnode, "Fatal Error: Child $childname of §HeadNode not found in database", 1)
    }
    push(@{$headnode->{'children'}}, $childname);
  }
  $db->{'§HeadNode'} = $headnode;

  return $db;
}


sub MakeOrMergeDbItem {
  my $n = shift;
  # always append the type, start with an empty one
  my $dbitem = shift || {type => ''};
  $dbitem->{'type'} .= $n->nodeName;
  # determine the absolute address, include node itself (not
  # necessarily a group) default address is 0, and we start always
  # from 0, overwriting a previously determined address
  $dbitem->{'address'} = 0;
  foreach my $anc ($n->findnodes('ancestor-or-self::*')) {
    $dbitem->{'address'} += hex($anc->getAttribute('address') || '0');
  }

  # add all attributes
  foreach my $a ($n->attributes()) {
    my $a_name = $a->getName();
    next if $a_name eq 'name' or $a_name eq 'address';
    $dbitem->{$a_name} = $a->getValue();
  }

  # find required attributes from first ancestor which knows
  # something about it, if we don't know it already
  foreach my $a (qw(purpose mode)) {
    next if defined $dbitem->{$a};
    my $value = $n->findnodes("ancestor::*[\@$a][1]/\@$a");
    $dbitem->{$a} = $value->string_value if $value->string_value;
  }

  # set description, we should always find one, but not more due to
  # last() predicate
  my $desc = $n->findnodes('(ancestor-or-self::*/description)[last()]');
  PrintMessage($n, "Warning: Found more than one description, taking first one.")
    if $warnings and $desc->size>1;
  $dbitem->{'description'} = SanitizedContent($desc->get_node(1));

  # save enumItems (if any)
  foreach my $item ($n->findnodes('enumItem')) {
    my $val = $item->getAttribute('value');
    $dbitem->{'enumItems'}->{$val} = SanitizedContent($item);
  }

  PrintMessage($n, "Warning: Found enumItems although not format=enum")
    if $warnings and defined $dbitem->{'enumItems'} and $n->getAttribute('format') ne 'enum';

  # is this node in something repeatable?
  my $repeats = $n->findnodes('ancestor::*[@repeat>1]');
  PrintMessage($n, "Warning: Found more than one ancestor with repeat attribute, taking first one.")
    if $warnings and $repeats->size>1;

  if ($repeats->size>0) {
    my $repeat = $repeats->get_node(1);
    $dbitem->{'stepsize'} = $repeat->getAttribute('size');
    $dbitem->{'repeat'} = $repeat->getAttribute('repeat');
  }


  return $dbitem;
}

sub SanitizedContent {
  my $n = shift;
  my $text = $n->textContent;
  $text =~ s/\s+/ /g;
  return $text;
}

sub PrintMessage {
  my $node = shift;
  my $file = $node->ownerDocument->URI;
  my $line = $node->line_number;
  my $msg = shift;
  print STDERR "$file:$line: $msg\n";
  # third command indicates fatal error message,
  # so exit...
  exit 1 if shift;
}

sub DumpDocument {
  my $doc = shift;

  my $entityName = $doc->getDocumentElement->getAttribute('name');
  my $entityAddr = hex($doc->getDocumentElement->getAttribute('address'));

  # recursively populate tree and print it
  my $tree = {};
  IterateChildren($tree, $doc->getDocumentElement, $entityAddr);
  MyDumpTree($tree, $entityName);
}

sub MyDumpTree {
  print DumpTree(shift, shift,
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
    my $name = $doc->getDocumentElement->getAttribute('name');
    print STDERR "Loaded and validated entity <$name> from database <$filename>\n"
      if $verbose>1;
    print STDERR "Warning: Filename not consistent with TrbNetEntity attribute"
      if $warnings and "$name.xml" ne $filename;
    return $doc;
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

xml-db.pl [entity names]
xml-db.pl --dump [entity names]
xml-db.pl --dumpitem=<regex> [entity names]

 Options:
   -h, --help     brief help message
   -v, --verbose  be verbose to STDERR
   -w, --warnings print warnings to STDERR
   --dir          directory that contains database and schema subdirs
   --dump         dump the database as tree, restricted to given entity names
   -i, --dumpitem dump a given named item as tree

=head1 OPTIONS

=over 8

=item B<--help>

Print a brief help message and exits.

=item B<--verbose>

Print some information what is going on.

=item B<--dir>

Set the base directory where the default XML files can be found in
sub-directories database and schema. In the same directory the cache
will be created.

=item B<--dump>

Dump the tree-structured database of the specified entity.

=item B<--dumpitem>

Dump items matching the specified regex to be found in the database of
the given entities (if no entity is given, all are searched). Don't
forget to enquote your regex with 'single quotes' to prevent your
shell fiddling around with that expression. If you want to have an
exact match, use somthing like '^MyExactName$'.

=back

=head1 DESCRIPTION

This program updates the cache directory from the provided XML files
in the database directory (also validates them against the schema).
You can restrict the files being worked by stating them as arguments,
the extension .xml will be added for convenience.

=cut
