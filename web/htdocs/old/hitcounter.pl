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
<script src="scripts.js" type="text/javascript"></script>
<title>Hmon $.$ENV{'QUERY_STRING'}.qq$</title>
</head>
<body>
$;
print $header;


 if (!defined &trb_init_ports()) {
   die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
 }

 
my $board = 0xffff;
my $e = <<EOD;
<h4>Hit Counters</h4>
<form acion="">
<table><tr><td>Board<td><input type="text" id="form_board" name="board" maxlength="4" value="ffff">
<tr><td># of Channels<td><input type="text" id="form_channels" name="channels" maxlength="3" value="65">
<tr><td>Update Interval (ms)<td><input type="text" id="form_rate" name="rate" maxlength="5" value="1000">
<tr><td>Differences<td><input type="checkbox" id="form_diff" name="diff" value="1">
<tr><td><td><input type="button" onClick="setValues()" value="OK">
</table>
</form>

EOD

print $e;


print "<table id=\"content\"><tr><th>Channel<th>Value\n";
for(my $c =0; $c < channels; $c++) {
  print "<tr><td>$c<td id=\"content".($c+1)."\">";
  }
  
print "</table>";


$e = <<EOD;
<script language="javascript">
var updaterate = document.getElementById("form_rate").value;
var board      = document.getElementById("form_board").value;
var channels   = document.getElementById("form_channels").value;
var updateTask = setInterval("getdata('get.pl?"+board+"-c000-"+channels+"',update)",updaterate);
var differences= document.getElementById("form_diff").checked;
var oldvalues = {};


function update(data) {
  if(!document.getElementById("content").innerHTML) return;
  var b = data.split("&");
  var c = {};
  o = "<tr><th>Channel";

  for(j=0;j<b.length-1;j++) {
    c[j] = b[j].split(" ");
    if(!oldvalues[j]) oldvalues[j] = c[j];
    o += "<th>"+c[j][0];
    } 
  
  for(i = 1; i <= channels; i++) {
    o += "<tr><th>"+(i-1);
    for(j=0;j<b.length-1;j++) {
      if(differences) {
        val = c[j][i]- (oldvalues[j][i]||0);
        }
      else {
        val = c[j][i];
        }
      o += "<td>"+val;
      }
    }
  oldvalues = c;
  document.getElementById("content").innerHTML  = o;
  }
  
function setValues() {
  updaterate = document.getElementById("form_rate").value;
  board      = document.getElementById("form_board").value;
  differences= document.getElementById("form_diff").checked;
  channels   = document.getElementById("form_channels").value;
  clearInterval(updateTask);
  updateTask = setInterval("getdata('get.pl?"+board+"-c000-"+channels+"',update)",updaterate);
  }
  
</script>

EOD

print $e;
print "</body></html>";
exit 1;

