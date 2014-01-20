#!/usr/bin/perl
use CGI::Carp qw(warningsToBrowser fatalsToBrowser); 
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print header("text/html");
  }
else {
  print "Content-type: text/html\n\n";
  use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
  }




use CGI qw/:standard/;


my $dn = $ENV{'PWD'};
my $daqop = $ENV{'DAQOPSERVER'};

print <<"HTML_DOCUMENT"
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<link href="layout/styles.css" rel="stylesheet" type="text/css"/>
<script src="scripts/scripts.js" type="text/javascript"></script>
<title>DAQ Control</title>
</head>
<body class="index">


<h2>DAQ Control</h2>
Welcome to your all-round DAQ monitor and control tool.

<h3>Documentation</h3>
<div class="index">
The main documentation of the network can be found in these documents and locations:
<ul>
<li><a href="http://jspc22.x-matter.uni-frankfurt.de/pub/trbnetdocumentation.pdf">A Users Guide to the HADES DAQ System</a>
<li><a href="http://jspc29.x-matter.uni-frankfurt.de/docu/trb3docu.pdf">A Users Guide to the TRB3 and FPGA-TDC Based Platforms</a>
<li><a href="http://trb.gsi.de">TRB Homepage</a></li>
</ul>
</div>

<h3>Monitoring and Control Features</h3>
<div class="index">
<div class="floatindex">
<h3>Network &amp; CTS</h3>
<div class="index">
<ul>
<li><a href="cts/cts.htm">CTS Control</a>
<li><a href="network/trbnet.pl">TrbNet status</a>
<li><a href="network/hub.pl">Network Hubs</a>
<li><a href="network/gbe.htm">GbE status</a>
<li><a href="network/map.htm">Network Map</a>
</ul>
</div>
</div>

<div class="floatindex">
<h3>Time measurement</h3>
<div class="index">
<ul>
<li><a href="tdc/tdc.htm">TDC</a>
<li><a href="tdc/tdc_debug.htm">TDC Debug</a>
</ul>
</div>
</div>

<div class="floatindex">
<h3>Front-ends</h3>
<div class="index">
<ul>
<li><a href="padiwa/padiwa.htm">Padiwa</a>
<li><a href="thresh/threshold.htm">Threshold settings</a>
</ul>
</div>
</div>


<div  class="floatindex">
<h3>Building Blocks</h3>
<div class="index">
<ul>
<li><a href="tdc/tdcstatctrl.pl">TDC (xml-based)</a>
<li><a href="nxyter/index.pl">Nxyter Read-out</a>
<li><a href="mvd/jtag.pl">MVD Jtag Controller</a>
<li><a href="mvd/roc.pl">MVD read-out Controller</a>
<li><a href="mvd/cb_controller.pl">MVD Converter Board Controller</a>
<li><a href="network/generic.pl">Everything else</a>
</ul>
</div>
</div>

<div class="floatindex">
<h3>Further Tools</h3>
<div class="index">
<ul>
<li><a href="tools/pwr/index.html" title="Currently supported: GW-Instek PSP-405 family, HMP2020 - HMP4040 family">Control for power supplies</a>
<li><a href="tools/vxi/index.html" title="Tested with Tektronix AFG3000 function generator">Control for devices running the VXI-11 protocol</a>
</ul>
</div>
</div>
</div>

<h3 style="clear:both">Server Details</h3>
<div class="index">
   <table id="server-details">
      <tr>
         <td class="label">Location</td>
         <td class="pre-value"><pre>$dn</pre></td></tr>
      </tr>
      <tr>
         <td class="label">DAQ OP Server</td>
         <td class="pre-value"><pre>$daqop</pre></td></tr>
      </tr>
   </table>
</div>


</body>
</html>
HTML_DOCUMENT
;
