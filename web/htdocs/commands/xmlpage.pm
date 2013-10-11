
package xmlpage;


my $active = -1;
my @setup;

sub getView {
  my ($n) = @_;
  $active = $n;

  if($setup[$n]->{refresh}) {
    print qq|<input type="button" class="stdbutton" onClick="getdataprint('../xml-db/get.pl?|.$setup[$n]->{cmd}.qq|','content',false);" value="Refresh">|;
    }
  print qq|<script language="javascript">setTimeout("getdataprint('../xml-db/get.pl?|.$setup[$n]->{cmd}.qq|','content',false)",400);</script>|;
  print qq|<div id="content"></div>|;
  
  
}


sub initPage {
  my ($ref_setup) = @_;
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
  
  print <<EOF;
<HTML>
<HEAD>
<title>TrbNet Overview</title>
<link href="../layout/styles.css" rel="stylesheet" type="text/css"/>
<link href="../layout/blue.css" rel="stylesheet" title="Light Blue" type="text/css"/>
EOF
  printJavaScripts();
  print qq(
</HEAD>
<BODY>
<h2>TrbNet Overview</h2>
<div id="overview">
<div class="header">);

for ( my $s = 0; $s < scalar @setup; $s++) {
  print qq|<span class="|.(($n == $s)?"selected":"inactive").qq|"><a href="?|.$setup[$s]->{name}.qq|">|.$setup[$s]->{name}.qq|</a></span>|;
  }
print qq(</div>);

if ($active!=-1) {
  getView($active);
  }

print <<EOF ;

</div>
<div id="debugpane">
<div class="header">Debug Output</div>
debug text
</div>


</BODY>
</HTML>
EOF
}




sub printJavaScripts {

####### javascript function land ################

  print <<EOF;
<script language="javascript" src="../scripts/scriptsnew.js"></script>

<script language="javascript">

</script>
EOF
}


1;