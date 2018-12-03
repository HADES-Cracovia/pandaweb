package Dmon;
use POSIX qw/floor ceil strftime/;
use Data::Dumper;
use warnings;
use strict;
use HADES::TrbNet;
use Time::HiRes qq|usleep|;

#print STDERR "Script started at ".strftime("%d.%m.%y %H:%M:%S", localtime()).".\n";



###############################################################################
#  Some default settings
###############################################################################

use constant DMONDIR => "/dev/shm/dmon/";


###############################################################################
#  Initializing file handles and TrbNet link
###############################################################################
sub StartUp {
  my %config = do $ARGV[0];
  $config{flog} = OpenQAFile();
  trb_init_ports() or die trb_strerror();
  return %config;
  }

###############################################################################
#  Make Rates from register read
###############################################################################
my $OldValues; my $firstrun = 1;
sub MakeRate {
  my ($pos,$width,$usets,$t) = @_;
  my $res;
  return unless defined $t;  

  foreach my $b (keys %$t) {
    for my $i (0..((scalar @{$t->{$b}{value}})-1)) {
      my $value    = $t->{$b}{value}[$i]||0;
         $value    = ($value>>$pos) & (2**$width-1);
      my $diff     = $value - ($OldValues->{$b}{value}[$i]||0);
         $diff    += 2**$width if $diff < 0;
      my $tdiff    = $t->{$b}{time}[$i] - ($OldValues->{$b}{time}[$i]||0);
         $tdiff   += 2**16 if $tdiff < 0;
      my $rate     = $diff;
         $rate     = $diff / (($tdiff*16E-6)||1) if $usets;
      $res->{$b}{rate}[$i]  = $rate;
      $res->{$b}{value}[$i] = $value;
      $res->{$b}{time}[$i]  = $t->{$b}{time}[$i];
      $res->{$b}{tdiff}[$i] = $tdiff;
      }
    }
  if (!$firstrun) {  
    $OldValues = $res;  
    return $res;
    }
  else {
    $OldValues = $res;  
    $firstrun = 0;
    return undef;
    }
  }
  

###############################################################################
#  Make Title & Footer
###############################################################################
sub MakeTitle {
  my ($width,$height,$title,$time,$error) = @_;
  my $str;
  $time = 1 unless defined $time;
  $str  = "<div class=\"width$width height$height\">\n";
  if ($time) {
    $str .= "<div class=\"timestamp\">".strftime("%H:%M:%S", localtime())."</div>\n";
  }
  if (defined $error && $error ne "") {
    $str .= "<div class=\"errorstamp\">$error</div>\n";
  }
  $str .= "<h3 id='title'>$title</h3>";
  return $str;
}

sub MakeFooter {
  my $str;
  $str = "</div>\n";
  return $str;
}

sub AddStyle {
  return "";
}


############################################
#  Write to File
############################################
sub WriteFile {
  my ($name,$str) = @_;
  open FH,"> ".Dmon::DMONDIR."/$name.htt";
  print FH $str;
  close FH;
}


###############################################################################
# Voice Synthesis
###############################################################################
my $speaklog;
sub Speak {
  my ($id,$str) = @_;
#   print "$id $str $speaklog->{$id}\n";
  if (!defined $speaklog->{$id} || $speaklog->{$id} < time()-120) {
#     my $cmd = "ssh hades30 'espeak -ven-male2 -s 120 -g 1 \"$str\" ' 2>/dev/null";
    my $fh;
    open($fh, ">>",Dmon::DMONDIR."/speaklog");
    $fh->autoflush(1);
    print $fh $str."\n";
    $speaklog->{$id} = time();
    close($fh);
    }
  }

###############################################################################
#  Calculate Colors
###############################################################################
sub findcolor {
  my ($v,$min,$max,$lg) = @_;
  my ($r,$g,$b);
  $v = 0 unless defined $v;
  $v = log($v) if $v && $lg;
  $min = log($min) if $min && $lg;
  $max = log($max) if $max && $lg;
  $max  = 1 unless $max;

  my $step = (($max-$min)/655);


  if ($v == 0) {
    $r = 220;
    $g = 220;
    $b = 220;
  } else {
    $v -= $min;
    $v  = $v/$step if $step;
    if ($v<156) {
      $r = 0;
      $g = $v+100;
      $b = 0;
    } elsif ($v<412) {
      $v -= 156;
      $r = $v;
      $g = 255;
      $b = 0;
    } else {
      $v -= 412;
      $r = 255;
      $g = 255-$v;
      $b = 0;
    }
  }

  my $ret = sprintf("#%02x%02x%02x",$r%256,$g%256,$b%256);

  return $ret;
}


###############################################################################
#  Error Levels
###############################################################################
use constant {
  NOSTATE => -10,
  SCRIPTERROR => -1,
  NA => 0,
  OK => 10,
  NOTE => 20,
  NOTE_2 => 22,
  WARN => 40,
  WARN_2 => 42,
  ERROR => 70,
  ERROR_2 => 72,
  LETHAL => 100,
  FATAL => 100
};

###############################################################################
#  Functions
###############################################################################


############################################
# Opens QA Logfile and gives back a filehandle
sub OpenQAFile {
  my $fh;
  open($fh, ">>",Dmon::DMONDIR."/qalog");
  $fh->autoflush(1);
  return $fh;
}



############################################
# Writes an entry to the QA file. Arguments:
# $fh        file handle of logfile
# $cat       category of entry
# $entry     name of entry
# $ttl       time the entry is valid (in seconds)
# $status    Status, one of the constants defined above
# $title     First line of monitor entry
# $value     Second line of monitor entry
# $longtext  Long description text (PopUp)
sub WriteQALog {
  my ($fh, $entry, $ttl, $status, $title, $value, $longtext,$link) = @_;
  $link = "" unless defined $link;
  my $tmp = time()."\t$entry\t$ttl\t$status\t$title\t$value\t$longtext\t$link\n";

  if ($fh == 0) {
    $fh = OpenQAfile();
    print $fh $tmp;
    close $fh;
    }
  else {
    print $fh $tmp;
    }

}

############################################
# Returns the appropriate status flag (simplified). Arguments:
# $mode     how to determine status, supported: "below","above"
# $val      the value
# @limits   Array with limits
sub GetQAState {
  my ($mode, $val, @limits) = @_;
  my ($ok, $warn, $err) = @limits;
  if (!defined($val)) {
    return NA;
  }
  if ($val eq "err") {   return SCRIPTERROR; }
  if ($_[0] eq 'below') {
    if ($val <= $ok) {   return OK; }
    if ($val <= $warn) { return WARN;}
    if ($val <= $err) {  return ERROR; }
    if ($val >  $err) {  return FATAL; }
  } elsif ($_[0] eq 'above') {
    if ($val >= $ok) {   return OK;}
    if ($val >= $warn) { return WARN;}
    if ($val >= $err) {  return ERROR;}
    if ($val <  $err) {  return FATAL;}
  } elsif ($_[0] eq 'inside') {
    if (abs($val) <= $ok) {   return OK;}
    if (abs($val) <= $warn) { return WARN;}
    if (abs($val) <= $err) {  return ERROR;}
                              return FATAL;
  }
  return SCRIPTERROR;
}

############################################
#Returns a string matching the given severity level
sub LevelName {
  my ($level) = @_;
  if ($level == SCRIPTERROR) { return "Script Error";}
  if ($level == NA) {          return "Not available";}
  if ($level < NOTE ) {        return "OK";}
  if ($level < WARN ) {        return "Note";}
  if ($level < ERROR ) {       return "Warning";}
  if ($level < FATAL ) {       return "Error"; }
                               return "Severe Error";
  }

############################################
# Tries to nicely format an integer
sub SciNotation {
  my $v = shift;
  return "undef" if (!defined $v);
  return "0" if $v == 0;
#   print $v."\n";
  if(abs($v) >= 1) {
    return  sprintf("%i", $v) if (abs($v) < 1000) ;
    return  sprintf("%.1fk", $v / 1000.) if (abs($v) < 20000) ;
    return  sprintf("%ik", $v / 1000.) if (abs($v) < 1E6) ;
    return  sprintf("%.1fM", $v / 1000000.) if (abs($v) < 20E6) ;
    return  sprintf("%iM", $v / 1000000.) if (abs($v) < 1E9) ;
    return  sprintf("%.1fG", $v / 1000000000.) if (abs($v) < 20E9) ;
    return  sprintf("%iG", $v / 1000000000.) if (abs($v) < 1E12) ;
    return  sprintf("%i",$v);
    }
  else {
    return sprintf("%in", $v*1E9) if (abs($v) < 1E-6) ;
    return sprintf("%iu", $v*1E6) if (abs($v) < 1E-3) ;
    return sprintf("%.1fm", $v*1E3);
    }
}


############################################
# Sends a command to a Padiwa
sub PadiwaSendCmd {
  my ($cmd,$board,$chain) = @_;
  my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,0x10001];
  my $errcnt = 0;
  while(1){
    trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});

    if (trb_strerror() =~ "no endpoint has been reached") {return -1;}
    if (trb_strerror() ne "No Error") {
      usleep 3E4;
      if($errcnt >= 12) {
        return {error => "SPI still blocked\n"};
        }
      elsif($errcnt++ >= 10) {
        trb_register_read($board,0xd412);
        }
      }
    else {
      last;
      }
    } 
  return trb_register_read($board,0xd412);
  }

sub PadiwaSendCmdMultiple {
  my ($cmd,$board,$chain,$delay) = @_;
  my $length = 0;
  my $str = "";
  for (my $i = 0; $i < 16; $i++) {
    $length++ if defined $cmd->[$i];
    $cmd->[$i] = $cmd->[$i] || 0;
    $str .= sprintf("%08x\t",$cmd->[$i]);
    }
  push(@{$cmd},1<<$chain);
  push(@{$cmd},0x1080 + $length);
#   print STDERR "$str\n";
  my $errcnt = 0;
  while(1){
    trb_register_write_mem($board,0xd400,0,$cmd,scalar @{$cmd});

    if (trb_strerror() =~ "no endpoint has been reached") {return -1;}
    if (trb_strerror() ne "No Error") {
      usleep($delay||1E5);
      if($errcnt >= 12) {
        return "SPI still blocked\n";
        }
      elsif($errcnt++ >= 10) {
        trb_register_read($board,0xd412);
        }
      }
    else {
      last;
      }
    } 
  return trb_register_read($board,0xd412);
  }

1;
__END__
