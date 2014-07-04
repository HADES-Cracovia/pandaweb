#!/usr/bin/perl -w


package this;

use strict;
use warnings;
use POSIX;
use Data::Dumper;
use FileHandle;
use Getopt::Long;
use File::Basename;
use File::Copy;
# use Cwd;

my $opt;

Getopt::Long::Configure(qw(gnu_getopt));
GetOptions(
           'help|h'      => \$opt->{help},
           'caption|c=s' => \$opt->{caption},
           'label|l=s'   => \$opt->{label},
           'group|g=s'   => \$opt->{group},
           'entity|e=s'  => \$opt->{entity},
           'output|o=s'  => \$opt->{output},
           'pdf'         => \$opt->{pdf},
           'standalone'  => \$opt->{standalone}
          );

printHelpMessage() if $opt->{help};
printHelpMessage() unless $opt->{entity} && $opt->{group};


my $me = this->new();

$me->setEntity($opt->{entity});
# $me->{entityFile} = "/home/micha/mnt/55local1/htdocs/daqtools/xml-db/cache/CbController.entity";
$me->{group} = $opt->{group};
$me->{table}->{label}   = $opt->{label}||"tab:".$opt->{group};
$me->{table}->{caption} = $opt->{caption}||"Registers in group ".$opt->{group};
$me->produceTable();


$me->writeTexFile($opt->{output}, $opt->{standalone} );

if ($opt->{pdf}){
  if ($opt->{output}){
    $me->pdflatex($opt->{output});
  } else {
    die "\n\ncannot make pdf!\nno output file specified, use the -o <file.tex> argument!\n";
  }
}



########### simple subs   ########

sub printHelpMessage{
print <<EOF;
xml-db2tex.pl -e <entityName> -g <group> [-o <output.tex>] [OPTIONS]

Generates a latex table of an xml-db group.

Options:
  -h, --help       brief help/usage message
  -e, --entity     enter entity name or /path/to/entityName.entity
  -g, --group      the xml-db group to be transformed into a table
  -o, --output     write tex output to this file, if left out,
                   will write tex code to STDOUT
                   
  -c, --caption    caption of the table
  -l, --label      latex label of the table
  
  --standalone     generate standalone compilable latex file
  --pdf            compile directly to pdf
  

EOF
exit;
}


########### object methods ########

sub new {
  my $class = shift;
  my %options = @_;

  my $self = {};
  
  $self->{table} = textabular->new(); # create new latex table object  
  
  # default formatting of the table
  $self->{table}->{dataKeys} = [ 'name', 'addr', 'bits', 'description' ];
  $self->{table}->{header} = [ 'register', 'addr', 'bits', 'description' ];
  $self->{table}->{format} = '@{} l l l p{8cm} @{}';
  
  $self  = {
    %$self,
    %options
  };
  bless($self, $class);  
  return $self;
}

sub setEntity {
  my $self=shift;
  my $entity=shift;
  
  if(-e $entity) { # treat as /path/to/File
    $self->{entityFile} = $entity;
  } elsif (-e dirname($0)."/cache/".$entity.".entity"){
    $self->{entityFile} = dirname($0)."/cache/".$entity.".entity";
  } else {
    die "Entity $entity not found (not even in xml-db/cache)\n";
  }
}

sub produceTable {
  my $self= shift;
  my $xmldb = xmlDbMethods->new( entityFile => $self->{entityFile} );
  my $list = $xmldb->unfoldTree($self->{group});
  my $data = [];
  for my $name (@$list) { # processing the list
    my $node = $xmldb->{entity}->{$name};
    my $type = $node->{type};
    my $repeat = $node->{repeat} || 1;
    my $stepsize = $node->{stepsize}||0;
    my $bits = "";
    if ($type ne 'register'){
      my $start = $node->{start};
      my $stop = $node->{start}+$node->{bits}-1;
      if ($start == $stop){
	$bits = $start;
      } else {
	$bits = "$start--$stop";
      }
    }
    #indent register fields
    if ($type eq 'field'){
      $name= '\quad  '.$name;
    }
    for (my $i=0;$i<$repeat;$i++){
      my $name_ = $name;
      if ($repeat > 1) {
        $name_ = $name.".$i";
      }  
      my $addr_ = $node->{address}+$i*$stepsize;
      my $hexaddr = sprintf("0x%04x",$addr_ );
      
      if ($type eq 'register' || $type eq 'registerfield'){
        #write register names bold
        $name_ = '\textbf{'.$name_.'}';
      }
      if ($type eq 'field'){
        $hexaddr = ''; # don't print addr it's already in the register
      }
      
      push(@{$data},{%$node, name => $name_, addr => $hexaddr, bits => $bits, addr_uint => $addr_});
    }
  }

  @$data = sort { $a->{bits} cmp $b->{bits} } @$data; # bit fields in ascending order
  @$data = sort { $a->{addr_uint} cmp $b->{addr_uint} } @$data; # addresses in ascending order


  my $last_addr;
  for my $item (@$data){
    # make hline at each new register
    my $cur_addr = $item->{addr_uint};
    if($last_addr){
      if($last_addr != $cur_addr){
        $self->{table}->addData(plain_code => '\hline');
      }
    }
    $self->{table}->addData(%$item); # fill it with the sorted data
    $last_addr = $cur_addr;
  }

}

sub writeTexFile {
  my $self = shift;
  my $output = shift;
  my $standalone = shift;
  
  
  # unless specified by --output/-o, the print OUTPUT commands go to STDOUT
  if ($output) {
    open(OUTPUT, '>', $output) or die "could not open $output for writing!";
  } else {
    *OUTPUT = *STDOUT;
  }
  
  if ($standalone){
    print OUTPUT q%
    \documentclass[a4paper,11pt]{article}
    \usepackage[T1]{fontenc}
    \usepackage{lmodern}
    \usepackage{booktabs}
    \usepackage{longtable}
    \usepackage{geometry}
    \geometry{verbose,tmargin=3cm,bmargin=3cm,lmargin=3cm,rmargin=3cm}
    \begin{document}
    %;
  }
  print OUTPUT $self->{table}->generateString();
  
  print OUTPUT '\end{document}'."\n" if $standalone;
#   OUTPUT->close();
  close(OUTPUT);
}

sub pdflatex{
  my $self = shift;
  my $output = shift||$me->{group};
  my $here = qx("pwd");
  $here =~ s/\n//g;
  my $directory = "/dev/shm/xml-db2tex".rand();
  unless(-e $directory or mkdir $directory) {
	  die "Unable to create $directory\n";
  }
  my $texfile = $me->{group}.".tex";
  my $pdffile = $me->{group}.".pdf";
  
  $output =~ s/\.(tex|pdf)//;
  $output.= ".pdf";
  
  chdir $directory;
  $me->writeTexFile($texfile, "standalone");
  system("pdflatex $texfile");
  system("pdflatex $texfile");
  copy("$directory/$pdffile","$here/$output");
  chdir $here;
  system("rm -rf $directory");
  
}



package xmlDbMethods;

use Storable qw(lock_store lock_retrieve);
use Data::Dumper;

sub new {
  my $class = shift;
  my %options = @_;
  my $self  = {
    entityFile => '/dev/null',
    %options
  };
  bless($self, $class);
  $self->{entity} = lock_retrieve($self->{entityFile});
  die "cannot open xml-db entity file ".$self->{entityFile}."\n" unless defined $self->{entity};
  return $self;
}



sub dumpItem { # for debug
  my $self = shift;
  my $item = shift;
  unless (defined($item)){
    print Dumper $self->{entity};
  } else {
    print Dumper $self->{entity}->{$item};
  }
}


sub unfoldTree {
  my $self = shift;
  my $name = shift;
  my $depth = shift||0;
  my $list = shift || [];
  
  my $node = $self->{entity}->{$name};
  unless($node->{type} eq 'group'){
    push(@{$list},$name);
  }
  
  if ($node->{type} eq 'group' || $node->{type} eq 'register' ){
    for my $child (@{$node->{'children'}}){
#       print $child."\n";
      $self->unfoldTree($child,$depth+1,$list);
    }
  }
  
  return $list;
}

1;

package textabular;


sub new {
  my $class = shift;
  my %options = @_;
  my $self  = {
    dataKeys => [],
    header => [],
    data => [],
    caption => '',
    label => '',
    %options
  };
  bless($self, $class);
  return $self;
}

sub addData {
  my $self = shift;
  my %data = @_;
  push(@{$self->{data}}, \%data);
  return $self;
}

sub generateString {
  my $self = shift;
  my $str = '% remember to include the following latex packages:
  % booktabs
  % longtable'."\n";
  
  my $header;
  
  if ( @{$self->{header}} ){ # if no header list ...
    $header= "  ".join(" & ",map { '\textbf{'.$_.'}' } @{$self->{header}}).' \\\\'."\n";
  } else { # print the keys instead
    $header= "  ".join(" & ",map { '\textbf{'.$_.'}' } @{$self->{dataKeys}}).' \\\\'."\n";
  }
  
  $str .= '\begin{longtable}'."\n";
  $str .="{".($self->{format}||"")."}\n";

  
  # define first header
  $str.='\toprule'."\n";
  $str.= $header;
  $str.='\midrule'."\n";
  $str.='\midrule'."\n";
  $str.='\endfirsthead';
  
  # define (continued) header
  $str.='\multicolumn{'.@{$self->{dataKeys}}.'}{c}';
  $str.='{\tablename\ \thetable\ -- \textit{Continued from previous page}} \\\\';
  $str.='\toprule'."\n";
  $str.= $header;
  $str.='\midrule'."\n";
  $str.='\midrule'."\n";
  $str.='\endhead';
  
  $str.='\multicolumn{'.scalar(@{$self->{dataKeys}}).'}{r}{\textit{Continued on next page}} \\\\
  \endfoot 
  \endlastfoot';
  
  for my $data (@{$self->{data}}){
    
    if ( $data->{plain_code} ) { #if there are strings in the data, just print them
      $str.=$data->{plain_code}."\n";
    } else {
      
      my @line;
      for my $dataKey (@{$self->{dataKeys}}){
        push(@line,$data->{$dataKey});
      }
      my $line = "  ".join(" & ", @line) . ' \\\\'."\n";
      $line =~ s/_/\\_/g; # remove all stupid underscores
      $str.=$line;
      
    }
  }
  $str.='\bottomrule'."\n";
#   $str.='\hline'."\n";
  
  $str.='\caption{'.$self->{caption}.'}' if $self->{caption}."\n";
  $str.='\label{'.$self->{label}.'}' if $self->{label}."\n";
  
  $str.='\end{longtable}'."\n";
  
#   $str.='\end{table}'."\n";
  return $str;
}