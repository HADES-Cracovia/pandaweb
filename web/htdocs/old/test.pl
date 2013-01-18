&htsponse(200, "OK");
print "Content-type: text/html\r\n\r\n";


use HADES::TrbNet;
use Data::Dumper;

my    $header = qq$<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<!--<meta http-equiv="refresh" content="$.$delay.qq$"/> -->
<link href="styles.css" rel="stylesheet" type="text/css"/>
<title>Hmon $.$ENV{'QUERY_STRING'}.qq$</title>
</head>
<body>
$;
print $header;


 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }


print "<h2>Available Boards</h2>\n<table><tr><th>Board<th>Type<th>Description\n";
my $ids = trb_register_read(0xffff,0x42);
my $type = trb_register_read(0xffff,0x42);
foreach my $b (sort keys %$type) {
  my $desc = "";
  $desc .= "TRB3 central, "              if(($type->{$b} & 0xff000000) == 0x90000000);
  $desc .= "TRB3 peripheral, "           if(($type->{$b} & 0xff000000) == 0x91000000);
  $desc .= "CBM RICH, "                  if(($type->{$b} & 0xff000000) == 0x92000000);
  printf("<tr><td>0x%04x<td>0x%08x<td>%s\n",$b,$type->{$b},$desc);
  }
print "</table>";



print "</body></html>";
exit 1;

