&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";



use HADES::TrbNet;
use Data::Dumper;

 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }

my ($board,$addr,$amount,$split) = split('-',$ENV{'QUERY_STRING'}); 
 
$board = hex($board);
$addr = hex($addr);
$amount = 1 unless $amount;
$split = 1 unless $split;


if($amount != 1) {
  if ($split <= 1) {
    my $hits = trb_register_read_mem($board,$addr,0,$amount);
    foreach my $b (sort keys %$hits) {
      printf ("%04x",$b);
      for(my $c =0; $c < $amount; $c++) {
        printf(" %d",$hits->{$b}->[$c]);
        }
      print "&";
      }
    }
  else {
    my $chunk = int($amount/$split);
    if($amount%$split) {$chunk++;}
    my $i = 0;
    my @hits;
    do {
      $hits[$i] = trb_register_read_mem($board,$addr+$i*$chunk,0,$chunk);
#      print Dumper  %{$hits[$i]};
#       print ($board." ".($addr+$i*$chunk)." ".($amount/$split)."\n");
      } while(++$i < $split);
    foreach my $b (sort keys %{$hits[0]}) {
      printf ("%04x",$b);
      for(my $i = 0; $i < scalar @hits; $i++) {
        for(my $c =0; $c < $chunk; $c++) {
          if($i*$chunk + $c < $amount) {
            printf(" %d",$hits[$i]->{$b}->[$c]);
            }
          }
        }
      print "&";
      }
    }
  }
else {
  my $hits = trb_register_read($board,$addr);
  foreach my $b (sort keys %$hits) {
    printf ("%04x",$b);
    printf(" %d",$hits->{$b});
    print "&";
    }
  
  }
  
exit 1;
