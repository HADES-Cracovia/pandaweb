
package xmlpage;


my $active = 0;
my @setup;
our $getscript;

sub initPage {
  my ($ref_setup,$page) = @_;
  @setup = @$ref_setup;
  my ($command,$style) = split("-",$ENV{'QUERY_STRING'});
  $command = "" unless defined $command;
  $style   = ""  unless defined $style;
  for(my $i=0; $i<scalar @setup;$i++) {
    if($setup[$i]->{name} eq $command) {
      $active = $i;
      last;
      }
    }
  
  my $cmd     = $setup[$active]->{cmd};
  my $period  = $setup[$active]->{period};
  my $name    = $setup[$active]->{name};
  my ($cmdMod,$cmdAddr,$cmdReg) = split('-',$setup[$active]->{cmd});
  my $israte  = $setup[$active]->{rate};
  my $iscache = $setup[$active]->{cache};
  
  $getscript = $page->{getscript};
  if(!defined $getscript) {
    $getscript = "../xml-db/get.pl";
    }

  
  print <<EOF;
<HTML>
<HEAD>
<title>$setup[$active]->{name} - $page->{title}</title>
<link href="../layout/styles.css" rel="stylesheet" type="text/css"/>
<link href="../layout/blue.css" rel="stylesheet" title="Light Blue" type="text/css"/>
EOF
  printJavaScripts($active);
  print qq(
</HEAD>
<BODY>
<h2><a href="$page->{link}">).$page->{title}.qq(</a></h2>
<div id="overview">
<div class="header">);


for ( my $s = 0; $s < scalar @setup; $s++) {
  print qq|<span class="|.(($active == $s)?"selected":"inactive").qq|"><a href="?$setup[$s]->{name}">$setup[$s]->{name}</a></span>|;
  }
print qq(</div>);

print '<div class="head">';
if($setup[$active]->{generic} == 1) {
  print qq|
  <input type="text" id="target" title="Enter any valid command in the form Module-Address-Name" 
  value="$cmd" onChange="settarget()" onLoad="settarget()"
  style="width:150px;text-align:left">
  |;
  }

if(!$setup[$active]->{generic}) {
  print qq|
  <input type="text" id="address" title="Enter any valid TrbNet address" 
         value="$cmdAddr" onChange="setaddress()" onLoad="setaddress()"
         style="text-align:left">
  |;
  }  
  
print qq|
<input type="text" id="period" title="Refresh interval in ms. Set to -1 to disable automatic refresh" 
       value="$period" onChange="setperiod()" onLoad="setperiod()">
<div class="checkbox"><input type="checkbox" onChange="settarget()" value="1" id="rate" title="Convert register counter to rates where possible" $israte><label for="rate">Rates</label></div>       
<div class="checkbox"><input type="checkbox" onChange="settarget()" value="1" id="cache" title="Use caching of data to reduce load on DAQ network" $iscache><label for="cache">Use Cache</label></div>
<input type="button" class="stdbutton" onClick="refresh(-1);" value="Refresh">
</div>
<div id="content"></div>|;

print <<EOF ;

</div>
<div id="debugpane">
<div class="header">Debug Output</div>
<span id="returntext"></span>
</div>
</BODY>
</HTML>
EOF

}





sub printJavaScripts {
  my ($n) =  @_;
####### javascript function land ################

  print qq|
<script language="javascript" src="../scripts/scriptsnew.js"></script>
<script language="javascript" src="../scripts/xmlpage.js"></script>
<script language="javascript">
  GETCOMMAND = "$getscript";
  var period = |.$setup[$n]->{period}.qq|;
  var command="|.$setup[$n]->{cmd}.qq|";
  var Timeoutvar;
  
  
  if(period != -1) {
    Timeoutvar = setTimeout("refresh(0)",400);
    }
  else {
    Timeoutvar = setTimeout("refresh(-1)",400);
    }
  setTimeout('document.getElementById("content").addEventListener("click",editsetting,0)',400);
  setTimeout('document.getElementById("period").value = period;',300);
  
</script>
|;
}


1;
