#!/usr/bin/perl -w
&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use Date::Format;
use HADES::TrbNet;
use Data::Dumper;

 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }


my $boards = trb_read_uid(0xffff);
my $types = trb_register_read(0xffff,0x42);
my $ctime = trb_register_read(0xffff,0x40);
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
      push(@o,sprintf("%04x#%d#%d#%04x#%d#%s&",$b->{parent},$b->{port},$layer,$b->{addr},$b->{type},time2str('%Y-%m-%d %H:%M',$b->{ctime})));      $o[-1] .= printlist($b->{addr},$layer+1);
      }
    }
  return join("",sort @o);
  }
sprintf("%4s\t%s\t%8s",$a, time2str('%Y-%m-%d %H:%M',hex($t)),$t);

# parent port layer board type compiletime
