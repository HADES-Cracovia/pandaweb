
package xmlpage;


my $active = 0;
my @setup;


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
  
  print <<EOF;
<HTML>
<HEAD>
<title>$page->{title}</title>
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
  print qq|<span class="|.(($active == $s)?"selected":"inactive").qq|"><a href="?|.$setup[$s]->{name}.qq|">|.$setup[$s]->{name}.qq|</a></span>|;
  }
print qq(</div>);

if ($active!=-1) {

  if($setup[$active]->{refresh}) {
    print qq|<input type="button" class="stdbutton" onClick="refresh();" value="Refresh">|;
    }
  print qq|<div id="content"></div>|;
  print qq|<script language="javascript">
    setTimeout("refresh()",400);
    document.getElementById("content").addEventListener("click",editsetting,0);
  </script>|;
  }

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

<script language="javascript">

  
  function editsetting(e) {
    if(e.target.getAttribute("class") && e.target.getAttribute("class").indexOf("editable")!=-1) {
      var text = e.target.getAttribute("cstr");
          text += "\\nCurrent Value: "+e.target.innerHTML+" ("+e.target.getAttribute("raw")+")\\n ";
      var newval = prompt(text,e.target.getAttribute("raw"));
      if (newval != null) {
        getdataprint('../xml-db/put.pl?'+e.target.getAttribute("cstr")+'-'+newval,'returntext',false,0,refresh);
        }
      }
    }
    
  function refresh() {
    getdataprint('../xml-db/get.pl?|.$setup[$n]->{cmd}.qq|','content',false,|.$setup[$n]->{period}.qq|);
    }
  
</script>
|;
}


1;