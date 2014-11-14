#!/usr/bin/perl -w
use strict;
use warnings;
use CGI::Carp qw(fatalsToBrowser);
my $PATH  = "";
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Content-type: text/html\r\n\r\n";
  $PATH = "htdocs/dmon/";
  }
else {
  print "Content-type: text/html\n\n";
  }

my $out;

my $delay = 10;
my @args = split('-',$ENV{'QUERY_STRING'});

	if ($args[0] =~ m/^(\d+\.?\d?)$/) {
		$delay = $1;
		}

	if( $ENV{'QUERY_STRING'} =~ m/window-/ ) {
		my $newurl = "monitor.pl?";
		$newurl .= $ENV{'QUERY_STRING'};
		$newurl  =~ s/window-//;
		$newurl =~ /(-|^|\?)(\w+)$/;
		open(my $MYF,"<$PATH$2.htt");
		my $str = <$MYF>;
		close($MYF);
		$str =~ /width(\d+)\sheight(\d+)/;
		my $width = 80*$1-8;
		my $height = 50*$2-8;
		$out = qq$<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<title>Dmon</title>
<meta http-equiv="content-type" content="text/html;charset=UTF-8"/>
<link href="styles.css" rel="stylesheet" type="text/css"/>
</head>
<body >
<script type="text/javascript">
  document.write("Opening Window...<br>");
	win = window.open("$.$newurl.qq$","Dmon$.$newurl.qq$","name=Dmon,innerwidth=$.$width.qq$,innerheight=$.$height.qq$,scrollbars=no,status=no,location=no,menubar=no,resizable=no,titlebar=no,dialog=no");
	if(win) {
    win.focus();
    win.document.title="Dmon $.$newurl.qq#";
    history.back();
    }
  else {
    document.write("Can't open pop-up window. Please disable pop-up blocker. Starting monitor inline...");
    setTimeout('window.location.href = "$newurl"',1000);
    }
</script>
#;

	      } else {

		$out = qq$<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
<!--<meta http-equiv="refresh" content="$.$delay.qq$"/> -->
<link href="styles.css" rel="stylesheet" type="text/css"/>
<title>Dmon $.$ENV{'QUERY_STRING'}.qq$</title>
</head>
<body ><!--onmousedown="stoprefresh(0);" onmouseup="stoprefresh(0);" ondblclick="stoprefresh(0);"-->
<div class="button" style="width:45px;right:-8px;" onclick="askclose();">&nbsp;close&nbsp;</div>
<div class="button" id = "stop" style="right:35px;width:45px;" onclick="stoprefresh(1)">stop</div>
<div class="button" id = "big" style="right:75px;width:45px;" onclick="zoom();">&nbsp;bigger&nbsp;</div>

<div id="content" class="blinkon"></div>
$;



$out .= qq$<script  language='javascript'>
  var reloadevery = setTimeout('reload()',10);
  var saveScrollTop = 0;
  var forcereloadbecauseofmemoryleak = setTimeout("location.reload()",1800000);
  blinkcnt = 0;
  blinking = setInterval("blink()",490);
  currentzoom = 1;

function zoom() {
	var zoomstep = 1.5;
	if (currentzoom == 1) {
		currentzoom = 1.5;
		document.getElementById('content').style.MozTransform="scale("+currentzoom+")";	
		window.innerWidth *= zoomstep;
		window.innerHeight*= zoomstep;
		document.getElementById("big").innerHTML = "small";
		}
	else {
		currentzoom = 1;
		document.getElementById('content').style.MozTransform="scale("+currentzoom+")";	
		window.innerWidth /= zoomstep;
		window.innerHeight/= zoomstep;
		document.getElementById("big").innerHTML = "bigger";
		}
	}

function reload() {
  xmlhttp=new XMLHttpRequest();
  xmlhttp.onreadystatechange = function() {
    if(xmlhttp.readyState == 4) {
			document.getElementById("content").innerHTML=xmlhttp.responseText;
      if(document.getElementById('logbox')) {
        if(saveScrollTop) {
          document.getElementById('logbox').scrollTop = saveScrollTop;
          }
        }

      document.getElementById("stop").style.background="#444";
      reloadevery = setTimeout('reload()',$.($delay*1000).qq$);
      delete xmlhttp;
      delete saveScrollTop;

      heatmapRegister();
      }
    };
  if(document.getElementById('logbox')) {
    saveScrollTop = document.getElementById('logbox').scrollTop;
    if (saveScrollTop == 0) {saveScrollTop = 0.1;}
    }
  xmlhttp.open("GET","get.pl?$.$ENV{'QUERY_STRING'}.qq$",true);
  xmlhttp.send(null);
  document.getElementById("stop").style.background="#111";
  }

function stoprefresh(button) {
	if(reloadevery) {
		clearTimeout(reloadevery);
		reloadevery = false;
		document.getElementById("stop").style.background="red";
		document.getElementById("stop").style.color="white";
		document.getElementById("stop").innerHTML="cont.";
		}
	else {
		document.getElementById("stop").style.background="#444";
		document.getElementById("stop").style.color="#aaa";
		document.getElementById("stop").innerHTML="stop";
		reload();
		}
	return false;
	}

function askclose() {
	if(confirm("Close Window?")==true){window.close();}
	}

function clk(e) {
  document.getElementById("footer").innerHTML= e.getAttribute("alt");
  }

function openhelp(w) {
  x = "monitor.pl?window-"+w;
  /*y = window.open(x,"DaqMonitor","scrollbars=yes,location=yes,menubar=yes,toolbar=yes");
  y.focus();*/
  window.location.href=x;
  }



function blink() {
  if(blinkcnt&1) {
    document.getElementById('content').setAttribute("class","blinkoff");
    }
  else {
    document.getElementById('content').setAttribute("class","blinkon");
    }
  blinkcnt++;
  }

 function heatmapRegister() {
  if (!document.getElementById('heatmap-img')) return;

  if (typeof HeatmapDef === 'undefined') {
    var js = document.createElement("script");
    js.type = "text/javascript";
    js.src = '../HeatmapRichDefs.js';
    document.body.appendChild(js);
  }

  document.getElementById('heatmap-img').onmousemove =  document.getElementById('heatmap-img').onmouseover = function(e) {
    var cx = e.clientX;
    var cy = e.clientY;

    if (!cx || !cy) return;

    var ix = parseInt((cx - HeatmapDef.x) / HeatmapDef.w);
    var iy = 32- parseInt((cy - HeatmapDef.y) / HeatmapDef.h);
    if (ix < 0 || ix > 31 || iy < 0 || iy > 31) return;

    document.getElementById('heatmap-caption').innerHTML = HeatmapDef.labels[ix][iy];
  }
 }

</script>$;
	      }
$out .= qq$
</body>
</html>
$;

print $out;

