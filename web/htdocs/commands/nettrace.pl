#!/usr/bin/perl
use Date::Format;
use HADES::TrbNet;
use Data::Dumper;
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Content-type: text/html\r\n\r\n";
  }
else {
  use lib '..';
  use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
  print "Content-type: text/html\n\n";
  }



 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }

my $temps  = trb_register_read(0xffff,0);
my $boards = trb_read_uid(0xffff);
my $types  = trb_register_read(0xffff,0x42);
my $ctime  = trb_register_read(0xffff,0x40);
my @store;

foreach my $id (sort keys %{$boards}) {
  foreach my $f (sort keys %{$boards->{$id}}) {
    my $addr = $boards->{$id}->{$f};
    my @path = trb_nettrace($addr);
#     print Dumper @path;
    my $o;
    if(scalar @path == 0) {
      $o->{parent} = 0;
      }
    else {
      $o->{parent} = $path[-1][-1]->{address};
      $o->{port}   = $path[-1][-1]->{port};
      }
    $o->{ctime}  = $ctime->{$addr};
    $o->{type}   = $types->{$addr};
    $o->{addr}   = $addr;
    $o->{temp}   = $temps->{$addr};
    push (@store,$o);
    }
  }
 

print printlist(0,1);

sub printlist {
  my ($parent,$layer) = @_;
  if($layer > 16) {die "More than 16 layers of network devices found. Aborting."}
  my @o;
  foreach my $b (@store) {
    if ($b->{parent} == $parent) {
      push(@o,sprintf("%04x#%d#%d#%04x#%d#%s#%.1f&",$b->{parent},$b->{port},$layer,$b->{addr},$b->{type},time2str('%Y-%m-%d %H:%M',$b->{ctime}),($b->{temp}>>20)/16));      
      $o[-1] .= printlist($b->{addr},$layer+1);
      }
    }
  return join("",sort @o);
  }
#sprintf("%4s\t%s\t%8s",$a, time2str('%Y-%m-%d %H:%M',hex($t)),$t);

# parent port layer board type compiletime
