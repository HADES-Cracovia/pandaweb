#!/usr/bin/perl -w
use HADES::TrbNet;
use Storable qw(lock_store lock_retrieve);
use feature "switch";
use CGI::Carp qw(fatalsToBrowser);

use if (!defined $ENV{'QUERY_STRING'}), warnings;
use if (!defined $ENV{'QUERY_STRING'}), Pod::Usage;
use if (!defined $ENV{'QUERY_STRING'}), Text::TabularDisplay;
use if (!defined $ENV{'QUERY_STRING'}), Data::Dumper;
use if (!defined $ENV{'QUERY_STRING'}), Data::TreeDumper;
use if (!defined $ENV{'QUERY_STRING'}), Getopt::Long;

# use Data::TreeDumper;
my ($db,$data,$once,$slice);
my $help = 0;
my $verbose = 0;
my $isbrowser = 0;
my $server = $ENV{'SERVER_SOFTWARE'} || "";
my @request;
my ($file,$entity,$netaddr,$name, $style, $storefile);


$ENV{'DAQOPSERVER'}="localhost:7" unless (defined $ENV{'DAQOPSERVER'});
die "can not connect to trbnet-daemon on $ENV{'DAQOPSERVER'}: ".trb_strerror() unless (defined &trb_init_ports());



if (defined $ENV{'QUERY_STRING'}) {
  @request = split("&",$ENV{'QUERY_STRING'});
  unless ($server  =~ /HTTPi/i) {
    print "Content-type: text/html\n\n";
    }
  }
else {
  $request[0] = ""; #Dummy entry to run foreach
  }

  


foreach my $req (@request) {
###############################
#### Check if browser or command line
###############################

  if(defined $ENV{'QUERY_STRING'}) {
    if($server =~ /HTTPi/i) {
      $isbrowser = 1;
      ($entity,$netaddr,$name,$style) = split("-",$req);
      $file = "htdocs/xml-db/cache/$entity.entity";
      }
    else {
  #     use FindBin qw($RealBin);
      my $RealBin = ".";
      $isbrowser = 1;
      ($entity,$netaddr,$name,$style) = split("-",$req);
      $file = "$RealBin/cache/$entity.entity";
      }
    $storefile = "/tmp/".$ENV{'QUERY_STRING'}.".store";
    }
  else {
  #   use FindBin qw($RealBin);
    my $RealBin = ".";
    Getopt::Long::Configure(qw(gnu_getopt));
    GetOptions(
              'help|h' => \$help,
              'verbose|v+' => \$verbose,
              ) or pod2usage(2);
    pod2usage(1) if $help;
    $entity  = $ARGV[0] || "";
    $file    = "$RealBin/cache/$ARGV[0].entity";
    $netaddr = $ARGV[1] || "";
    $name    = $ARGV[2] || "";
    $style   = $ARGV[3] || "";
    }

     $style = "" unless $style;
  my $isInline = $style =~ /inline/i;  
  my $isColor  = $style =~ /color/i;  
  my $sortAddr = $style =~ /sortaddr/i;
     $verbose  = ($style =~ /verbose/i) ||$verbose;
  my $rates    = $style =~ /rates/i;
  my $cache    = $style =~ /cache/i;
    
     
###############################
#### Check arguments for validity
###############################

  die "Entity $file not found.\n" unless(-e $file) ;
    
  if    ($netaddr=~ m/0x([0-9a-fA-F]{4})/) {$netaddr = hex($1);}
  elsif ($netaddr=~ m/([0-9]{1,5})/) {$netaddr = $1;}
  else {die "Could not parse address $netaddr\n";}


  $slice = undef;
  if    ($name =~ m/^([a-zA-Z0-9]+)\.(\d+)$/) {$name = $1; $slice = $2;}
  elsif ($name =~ m/^([a-zA-Z0-9]+)$/)       {$name = $1; $slice = undef;}
  else {die "Could not parse name $name \n";}

  $db = lock_retrieve($file);
  die "Unable to read cache file\n" unless defined $db;
  
  if($rates) {
    if(-e $storefile) {
      my $olddata = lock_retrieve($storefile);
      }
    }

  die "Name not found in entity file\n" unless(exists $db->{$name});

###############################
#### Main "do the job"
###############################
  $once = (defined $slice)?1:0;
  if ($isbrowser) {
    requestdata($db->{$name},$name,$slice);
    generateoutput($db->{$name},$name,$slice,$once);
    if($rates) {
      store_lock($data,$storefile);
      }
    }
  else {
    runandprint($db->{$name},$name,$slice,$once);
    }
}
 
###############################
#### Formatting of values
###############################
sub FormatPretty {
  my ($value,$obj,$name,$cont,$class,$cstr) = @_;
  $value  = $value >> ($obj->{start});
  $value &= ((1<<$obj->{bits})-1);
  my $rawvalue = $value;
  $value = $value * ($obj->{scale}||1) + ($obj->{scaleoffset}||0);
  
  $class = "" unless $class;
  $cstr  = "" unless $cstr;
  my $ret, my $cl;
  if (defined $cont) {
    my $isflag = 1; $isflag = 0 if $obj->{noflag};
    $cl = "class=\"".($value?"bad":"good")."\"" if     ( $obj->{errorflag} && !$obj->{invertflag} && $isflag);
    $cl = "class=\"".($value?"good":"bad")."\"" if     ( $obj->{errorflag} &&  $obj->{invertflag} && $isflag);
    $cl = "class=\"".($value?"high":"low")."\"" if     (!$obj->{errorflag} && !$obj->{invertflag} && $isflag);
    $cl = "class=\"".($value?"low":"high")."\"" if     (!$obj->{errorflag} &&  $obj->{invertflag} && $isflag);
    $cl .= sprintf(" cstr=\"$cstr\" raw=\"0x%x\"><div class=\"$class\">",$rawvalue);
    
    my $t = "";
    $ret = "<$cont ";
    for($obj->{format}) {    
      when ("boolean") {
        if($obj->{errorflag}) { $ret .= "$cl".($value?"true":"false");}
        else                  { $ret .= "$cl".($value?"true":"false");}
          }
      when ("float")    { $ret .= sprintf("$cl%.2f",$value);}
      when ("integer")  { $t    = sprintf("%i",$value); 
                          $t =~ s/(?<=\d)(?=(?:\d\d\d)+\b)/&#8198;/g; 
                          $ret .= $cl.$t;
                          }
      when ("unsigned") { $t    = sprintf("%u",$value); 
                          $t =~ s/(?<=\d)(?=(?:\d\d\d)+\b)/&#8198;/g; 
                          $ret .= $cl.$t;
                          }
      when ("signed")   { $ret .= sprintf("$cl%d",$value);}
      when ("binary")   { $t    = sprintf("%0".$obj->{bits}."b",$value); 
                          $t =~ s/(?<=\d)(?=(?:\d\d\d\d)+\b)/&#8198;/g; 
                          $ret .= $cl.$t;
                          }
      when ("bitmask")  { my $tmp = sprintf("%0".$obj->{bits}."b",$value);
                          $tmp =~ s/(?<=\d)(?=(?:\d\d\d\d)+\b)/ /g;
                          $tmp =~ s/0/\&#9633\;/g;
                          $tmp =~ s/1/\&#9632\;/g;
                          $tmp =~ s/\s/\&#8198\;/g;
                          
                          $ret .= $cl.$tmp;
                          }
      when ("time")     {require Date::Format; $ret .= Date::Format::time2str('>%Y-%m-%d %H:%M',$value);}
      when ("hex")      {$ret .= sprintf($cl."0x%0".(int(($obj->{bits}+3)/4))."x",$value);}
      when ("enum")     { my $t = sprintf("%x",$value);
                          if (exists $obj->{enumItems}->{$t}) {
                            $ret .= $cl.$obj->{enumItems}->{$t} 
                            }
                          else {
                            $ret .= $cl."0x".$t;
                            }
                          }
      default           {$ret .= sprintf(">%08x",$value);}
      }
    my $range = $obj->{start}+$obj->{bits}-1;
    $range .= "..".$obj->{start} if ($obj->{bits}>1);
    $ret .= " ".$obj->{unit} if exists $obj->{unit};
    $ret .= sprintf("<span class=\"tooltip\"><b>$name</b> (Bit $range)<br>raw: 0x%x<br>$cstr</span></div>",$rawvalue);

    }
  else {
    for($obj->{format}) {
      when ("boolean")  {$ret = $value?"true":"false";}
      when ("float")    {$ret = sprintf("%.2f",$value);}
      when ("integer")  {$ret = sprintf("%i",$value);}
      when ("unsigned") {$ret = sprintf("%u",$value);}
      when ("signed")   {$ret = sprintf("%d",$value);}
      when ("binary")   {$ret = sprintf("%b",$value);}
      when ("bitmask")  {$ret = sprintf("%0".$obj->{bits}."b",$value);}
      when ("time")     {require Date::Format; $ret = Date::Format::time2str('%Y-%m-%d %H:%M',$value);}
      when ("hex")      {$ret = sprintf("0x%0".int(($obj->{bits}+3)/4)."x",$value);}
      when ("e1num")     { my $t = sprintf("%x",$value);
                          if (exists $obj->{enumItems}->{$t}) {
                            $ret = $obj->{enumItems}->{$t} 
                            }
                          else {
                            $ret = "0x".$t;
                            }
                          }
      default           {$ret = sprintf("0x%08x",$value);}
      }
    $ret .= " ".$obj->{unit} if exists $obj->{unit};
    }
  return $ret;
  }

  
###############################
#### Intelligent data reader
###############################
sub requestdata {
  my ($obj,$name,$slice) = @_;
  my $o;
  print DumpTree($obj) if $verbose;
  if (defined $slice && defined  $obj->{repeat} && $slice >= $obj->{repeat}) {
    print "Slice number out of range.\n";
    return -1;
    }
  
  if($obj->{type} eq "group" && $obj->{mode} =~ /r/) {
    if(defined $obj->{continuous} && $obj->{continuous} eq "true") {
      my $stepsize = $obj->{stepsize} || 1;
      my $size   = $obj->{size};
      $slice = $slice || 0;
      do{
        $o = trb_register_read_mem($netaddr,$obj->{address}+$slice*$stepsize,0,$size);
        next unless defined $o;
        foreach my $k (keys %$o) {
          for(my $i = 0; $i < $size; $i++) {
            $data->{$obj->{address}+$slice*$stepsize+$i}->{$k} = $o->{$k}->[$i];
            }
          }
        } while(!$once && defined $obj->{repeat} && ++$slice < $obj->{repeat});  
      }
    else {      
      foreach my $c (@{$obj->{children}}) {
        requestdata($db->{$c},$c,$slice);
        }
      }
    }
  elsif(($obj->{type} eq "register" || $obj->{type} eq "registerfield" || $obj->{type} eq "field")  && $obj->{mode} =~ /r/) {
    my $stepsize = $obj->{stepsize} || 1;
    $slice = 0 unless defined $slice;
    do {
      $o = trb_register_read($netaddr,$obj->{address}+$slice*$stepsize);
      next unless defined $o;
      foreach my $k (keys %$o) {
        $data->{$obj->{address}+$slice*$stepsize}->{$k} = $o->{$k};
        }
      } while(!$once && defined $obj->{repeat} && ++$slice < $obj->{repeat});
    }
  }

  
  
  
sub generateoutput {
  my ($obj,$name,$slice,$once) = @_;
  my $t = "";
  if($obj->{type} eq "group") {
    foreach my $c (@{$obj->{children}}) {
      generateoutput($db->{$c},$c,$slice,$once);
      }
    }
  elsif(($obj->{type} eq "register" || $obj->{type} eq "registerfield" || $obj->{type} eq "field") && $obj->{mode} =~ /r/) {
    $t = "<hr class=\"queryresult\"><table class='queryresult'><thead>";
    my $stepsize = $obj->{stepsize} || 1;
       $slice = 0 unless defined $slice;

    my $addr = $obj->{address};   

    $t .= sprintf("<tr><th><div>$name<span class=\"tooltip\"><b>$name</b> (0x%04x)<br>$obj->{description}</span></div>",$addr);
    if($once != 1 && defined $obj->{repeat}) {
      $t .= "<th class=\"slice\">Slice";
      }
    if($obj->{type} eq "registerfield" || $obj->{type} eq "field"){
      my $range = $obj->{start}+$obj->{bits}-1;
      $range .= "..".$obj->{start} if ($obj->{bits}>1);
      $t .= "<th><div>$name<span class=\"tooltip\"><b>$name</b> (Bit $range)<br>$obj->{description}</span></div>";
      }
    elsif($obj->{type} eq "register"){
      foreach my $c (@{$obj->{children}}){
        $oc = $db->{$c};
        my $range = $oc->{start}+$oc->{bits}-1;
        $range .= "..".$oc->{start} if ($oc->{bits}>1);
        $t .= "<th><div>$c<span class=\"tooltip\"><b>$c</b> (Bit $range)<br>$oc->{description}</span></div>";
        }
      }   
    $t .= "</thead>";
    my %tarr;
    do {  
      $addr = $obj->{address}+$slice*$stepsize;
      #### Prepare table header line
      
      foreach my $b (sort keys %{$data->{$addr}}) {
        my $ttmp = "";
        my $sl;
        $sl = sprintf("<td class=\"slice\"><div>%i<span class=\"tooltip\"><b>$name.$slice</b> (0x%04x)</span></div>",$slice,$addr) if ($once != 1 && defined $obj->{repeat});
        
        $ttmp .= sprintf("<tr><td><div>%04x<span class=\"tooltip\"><b>$name</b> on 0x%04x<br>raw: 0x%x</span></div>%s",$b,$b,$data->{$addr}->{$b},$sl);
        if($obj->{type} eq "register") {
          foreach my $c (@{$obj->{children}}) {
            my $fullc = $c;
            $fullc .= ".$slice" if ($once != 1 && defined $obj->{repeat});
            my $cstr = sprintf("%s-0x%04x-%s", $entity,$b,$fullc );
            my $wr = 1 if $db->{$c}->{mode} =~ /w/;
            $ttmp .= FormatPretty($data->{$addr}->{$b},$db->{$c},$c,"td",($wr?"editable":""),$cstr);
            }
          }
        elsif($obj->{type} eq "field" || $obj->{type} eq "registerfield") {
          my $fullc = $name;
          $fullc .= ".$slice" if ($once != 1 && defined $obj->{repeat});
          my $cstr = sprintf("%s-0x%04x-%s", $entity,$b,$fullc );
          my $wr = 1 if $obj->{mode} =~ /w/;
          $ttmp .= FormatPretty($data->{$addr}->{$b},$obj,$fullc,"td",($wr?"editable":""),$cstr);
          }
        $tarr{sprintf("%05i%04i",$b,$slice)}=$ttmp;
        }
      
      } while($once != 1 && defined $obj->{repeat} && ++$slice < $obj->{repeat});
    $t .= $tarr{$_} for sort keys %tarr;
    $t .= "</table>";
    }
  print $t;
  }


  
###############################
#### Analyze Object & print contents (the simple minded way)
###############################
sub runandprint {
  my ($obj,$name,$slice,$once) = @_;
  my $o;
  print DumpTree($obj) if $verbose;  
  #### Iterate if group
  if($obj->{type} eq "group") {
    foreach my $c (@{$obj->{children}}) {
      runandprint($db->{$c},$c,$slice,$once);
      }
    }
  
  #### print if entry is a register or field
  elsif($obj->{type} eq "register" || $obj->{type} eq "registerfield" || $obj->{type} eq "field") {
    print DumpTree($o) if $verbose>1;
    
    my $stepsize = $obj->{stepsize} || 1;
       $slice = 0 unless defined $slice;

  
    do {
      if (defined  $obj->{repeat} && $slice >= $obj->{repeat}) {
        print "Slice number out of range.\n";
        return -1;
        }
      $o = trb_register_read($netaddr,$obj->{address}+$slice*$stepsize);
      next unless defined $o;
      
      #### Prepare table header line
      my $t;
      my @fieldlist;
      push(@fieldlist,("Board","Reg."));
      push(@fieldlist,"raw");

      if($obj->{type} eq "registerfield"){
        push(@fieldlist,$name);
        }
      elsif($obj->{type} eq "field"){
        push(@fieldlist,$name) ;
        }
      elsif($obj->{type} eq "register"){
        foreach my $c (@{$obj->{children}}){
          push(@fieldlist,$c);
          }
        }
        
      if($isbrowser == 0) {
        $t = Text::TabularDisplay->new(@fieldlist);
        }
      else {
        if($once == 1 || $slice == 0) {
          $t = "<table class='queryresult'><tr><th>";
          $t .= join("<th>",@fieldlist);
          }
        else{ 
          $t = "";
          }
        }

      #### Fill table with information
      foreach my $b (sort keys %$o) {
        my @l;
        push(@l,sprintf("%04x",$b));
        push(@l,sprintf("%04x",$obj->{address}+$slice*$stepsize));
        push(@l,sprintf("%08x",$o->{$b}));
        if($obj->{type} eq "register") {
          foreach my $c (@{$obj->{children}}) {
            push(@l,FormatPretty($o->{$b},$db->{$c}));
            }
          }
        elsif($obj->{type} eq "field" || $obj->{type} eq "registerfield") {
          push(@l,FormatPretty($o->{$b},$obj));
          }
        if($isbrowser == 0) {
          $t->add(@l);
          }
        else {
          $t .= "<tr><td>";
          $t .= join("<td>",@l);
          }
        }
      
      #### Show the beautiful result...
      if($isb1rowser == 0) {
        print $t->render;
        }
      else {
        print $t;
        }
      print "\n";    
      } while($once != 1 && defined $obj->{repeat} && ++$slice < $obj->{repeat});
    print "</table>" if $isbrowser;
    }
    
  }
  
print "\n";  
  
1;  
  
  
###############################
#### Feierabend!
###############################     
__END__

=head1 NAME

get.pl - Access TrbNet elements with speaking names and formatted output

=head1 SYNOPSIS

get.pl entity address name style

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
