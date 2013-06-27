#!/usr/bin/perl -w
print "Content-type: text/html\n\n";

my $me="cgitest.pl";

use strict;
use warnings;
use XML::LibXML;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);
use HTML::Entities;

sub initPage {
	
print <<EOF;
<HTML>
<HEAD>
<title>JTAG Editor</title>
<link href="../layout/styles.css" rel="stylesheet" type="text/css"/>
<link href="../layout/jtageditor.css" rel="stylesheet" type="text/css"/>
EOF
printJavaScripts();
print <<EOF;
</HEAD>
<BODY onload='reloadFileSelection()'>
<h2>JTAG Configuration File Editor</h2>
<div id="debug">
debug text
</div>
<div id="fileSelection">

Current File: unknown
</div>

<div id="roterBereich">
empty
</div>
<div id="blauerBereich">
empty
</div>


</BODY>
</HTML>
EOF

}



my %cgiHash = &read_input;


if (!keys %cgiHash) { # if script is called without arguments: initialize the html structure
initPage();
exit;
} 


my $parser = XML::LibXML->new();
my $specfile = "";
my $setfile = "";
my $spectree;
my $settree;

my $confDir = '../config';
my $specDir = '../specs';


if ($cgiHash{'print'} eq 'fileSelection'){
print "<div class='header'>File Selection</div>";

print_fileSelection();

}



if ($cgiHash{'print'} eq 'spectree') {
print "<div class='header'>Available Settings</div>\n";
parseSetAndSpec($cgiHash{'configFile'});
print_registers($specfile);
}


if ($cgiHash{'print'} eq 'settree') {
print "<div class='header'>Selected Settings</div>\n";
parseSetAndSpec($cgiHash{'configFile'});
print_registers($setfile);
}


if (defined $cgiHash{'debuginput'}) {
print $cgiHash{'debuginput'};
}

if (defined $cgiHash{'action'} ) {
	
	printHash(\%cgiHash);
	if($cgiHash{'action'} eq 'save') {
		parseSet($cgiHash{'configFile'});
		save($cgiHash{'register'},$cgiHash{'field'},$cgiHash{'value'});
	}
	if($cgiHash{'action'} eq 'delete'){
		parseSet($cgiHash{'configFile'});
		del($cgiHash{'register'},$cgiHash{'field'});
	}
	if($cgiHash{'action'} eq 'copyDefaultRegister'){
		parseSetAndSpec($cgiHash{'configFile'});
		del($cgiHash{'register'},""); # delete existing register from setfile
		copyDefaultRegister($cgiHash{'register'});
	}
}



#################### SUBLAND ######################

sub prepare_text {
  my $t = $_[0];
  chomp $t;
  $t = encode_entities($t);
  $t =~ s/^\s//;
  $t =~ s/^\n//;
  $t =~ s/\t//;
  return $t;
  }



sub parseSetAndSpec {
	$setfile = $confDir."/".$_[0];
	$settree = $parser->parse_file($setfile);
	my $specFileName = $settree->findvalue("/MAPS/\@specDbFile");
	$specfile = $specDir."/".$specFileName;
	$spectree = $parser->parse_file($specfile);	
}

sub parseSet {
	$setfile = $confDir."/".$_[0];
	$settree = $parser->parse_file($setfile);
}

sub del {


	my $registerName=$_[0];
		my $fieldName=$_[1];
		my $xmlfile = $setfile;
		my $xmltree = $settree;	
		my $maps = $xmltree->findnodes("/MAPS")->shift();
		my $register = $xmltree->findnodes("/MAPS/register[\@name='".$registerName."']")->shift();

		if ($fieldName eq "") { # no field specified, remove whole register
			unless($register eq ""){
				$maps->removeChild($register);
			}
			print "deleted whole register";
		} else {

		my $field = $xmltree->findnodes("/MAPS/register[\@name='".$registerName."']/field[\@name='".$fieldName."']")->shift();
		$register->removeChild($field);
		print "deleted field<br>";
		unless( $register->hasChildNodes()){
			$maps->removeChild($register);
			print "deleted register as well<br>";
		}
		}
		open(SCHREIBEN,"> $xmlfile")
  or print "could not open file $xmlfile for writing: $!\n";

print SCHREIBEN $xmltree->toString();
close SCHREIBEN;
}

sub print_fileSelection {

print "<table>";
print "<tr>";
print "<td>select config file:<td>";
print "</tr>";

print "<tr>";

print "<td>";
    opendir(DIR, $confDir) or die $!;

print '<select name="fileSelectionDropdown" id="fileSelector">';

    while (my $file = readdir(DIR)) {

        # Use a regular expression to ignore files beginning with a period
        next if ($file =~ m/^\./);
	#print "$file\n";
	if ($file =~ m/\.xml$/){
	print '<option value="'.$file.'">'.$file.'</option>';
	}
    }

    closedir(DIR);

print '</select>';

print "</td>";

print "<td>";
print "<input type='button' onclick='reloadTrees()' value='load file'>";
print "</td>";

print "</tr>";

print "</table>";
}


sub save {

	my $registerName=$_[0];
		my $fieldName=$_[1];
		my $xmlfile = $setfile;
		my $newValue = $_[2];

		my $xmltree= $settree;
		my $maps = $xmltree->findnodes("/MAPS")->shift();
		#my @fields = $xmltree->findnodes("/MAPS/register[\@name='".$registerName."']/field[\@name='".$fieldName."']");
		my $register = $xmltree->findnodes("/MAPS/register[\@name='".$registerName."']")->shift();

		if($register eq ""){
			$register = $maps->addNewChild("","register");
			$register->setAttribute("name",$registerName);
		}

		
		my $field = $xmltree->findnodes("/MAPS/register[\@name='".$registerName."']/field[\@name='".$fieldName."']")->shift();

		if($field eq ""){
			$field = $register->addNewChild( "","field" );
			$field->setAttribute( "name", $fieldName );

		}
		#my $fieldValue = ($xmltree->findnodes("/MAPS/register[\@name='".$registerName."']/field[\@name='".$fieldName."']/\@name='value'"))[0];
		#print $fieldValue->findvalue("./");
		$field->setAttribute( "value", $newValue );
		print $field->findvalue("./\@value");
		open(SCHREIBEN,"> $xmlfile")
  or print "could not open file $xmlfile for writing: $!\n";

print SCHREIBEN $xmltree->toString();
close SCHREIBEN;
}

sub copyDefaultRegister {
		my $registerName=$_[0];
		my $settree = $parser->parse_file($setfile);	
		my $spectree = $parser->parse_file($specfile);	
		my $setmaps = $settree->findnodes("/MAPS")->shift();
		my $specmaps = $spectree->findnodes("/MAPS")->shift();

		my $specRegister = $spectree->findnodes("/MAPS/register[\@name='".$registerName."']")->shift();
		
		my $setRegister = $setmaps->addNewChild("","register");
		$setRegister->setAttribute("name",$registerName);
		
		my @specFields = $specRegister->findnodes("./field");
		
		for my $specField (@specFields){
			my $fieldName = $specField->findvalue("./\@name");
			my $fieldValue = $specField->findvalue("./\@defaultValue");
			my $setField = $setRegister->addNewChild( "","field" );
			$setField->setAttribute( "name", $fieldName );
			$setField->setAttribute( "value", $fieldValue );
			print $setField->findvalue("./\@value");
		}
		open(SCHREIBEN,"> $setfile")
  or print "could not open file $setfile for writing: $!\n";

print SCHREIBEN $settree->toString();
close SCHREIBEN;
}

sub by_name {
    my $a_name= $a->findvalue("./\@name") ;
    my $b_name= $b->findvalue("./\@name") ;

    # putting $b_published in front will ensure the descending order.
    return $a_name cmp $b_name;
}

sub printHash {
	my $hashref=$_[0];	
	for my $element( keys %{$hashref}){
		print $element."=".$hashref->{$element}."<br>\n";
	}
}


sub print_registers {
my $xmlfile = $_[0];
my $xmltree;
if ($xmlfile eq $setfile) {
 $xmltree = $settree;
} elsif ($xmlfile eq $specfile) {
	$xmltree = $spectree;
} else {
	die "xmlfile given to sub print_registers is unknown";
}
my @registers = sort by_name $xmltree->findnodes("/MAPS/register");
print "<table class=\"registers\">";
for my $register (@registers ){
	
	my $registerName = $register->findvalue("./\@name");
	my $registerId = $register->findvalue("./\@id");
	my $registerSize = $register->findvalue("./\@size");
  my $registerDescr = prepare_text($spectree->findvalue("/MAPS/register[\@name='".$registerName."']/description") || "n/a");

	my $flistid = $xmlfile."//".$registerName;
	
	print "<tr>";

	print <<EOF;
<td onClick='toggleVis("$flistid",this)' class='regheader'>&nbsp;+&nbsp;</td>
EOF
	print "<td title=\"$registerDescr\">$registerName</td>";	
	#print "<td>$registerId</td>";

		if($xmlfile eq $setfile){
		print <<EOF;
<td class='button_move' onclick='deleteSettings("$registerName","");'>&nbsp;X&nbsp;</td>
EOF
		}	
		if($xmlfile eq $specfile){
		print <<EOF;
<td class='button_move' onclick='copyDefaultRegister("$registerName");'>&nbsp;&rarr;&nbsp;</td>
EOF
		}	

	print "</tr>";
	#print "<tr>";

	print '<tr id="'.$flistid.'" class="bitfield">';
	print '<td></td>';
	print '<td  class="fieldcontainer">';
		print_fields($xmlfile,$register);
	print "<td>";
	print "</tr>";
}
print "</table>";
}

sub print_fields {

	my $register = $_[1];
	my $xmlfile = $_[0];
	my $registerName = $register->findvalue("./\@name");
	my @fields = sort by_name $register->findnodes("./field");
	print "<table class=\"fields\">";
	for my $field (@fields){
		my $fieldName = $field->findvalue("./\@name");
		my $readOnlyFlag = 0;	
		my $fieldValue = $field->findvalue("./\@value");
		my $fieldDescr = prepare_text($spectree->findvalue("/MAPS/register[\@name='".$registerName."']/field[\@name='".$fieldName."']/description") || "n/a");
		my $fieldId = $xmlfile."//".$registerName."/".$fieldName;
		if ($fieldValue eq "") {
			$fieldValue = $field->findvalue("./\@defaultValue");
			$readOnlyFlag=1;
		}

		print "<tr>";
		print "<td width=120  title=\"$fieldDescr\">$fieldName</td>";
		print "<td> &nbsp;=&nbsp;</td>";
		if ($readOnlyFlag){
		print <<EOF;
		<td width=120  align='right'>$fieldValue</td>
EOF
		} else {
		print <<EOF;
<td align='right'>
<input type='text' align='right' value='$fieldValue' onchange='saveSettings("$registerName","$fieldName",this.value)'  >
</td>
EOF
		
		}
		print '</td>';
		if($xmlfile eq $specfile){
		print <<EOF;
<td class='button_move' onclick='saveSettings("$registerName","$fieldName","$fieldValue");'>&nbsp;&rarr;&nbsp;</td>
EOF
		}	
		if($xmlfile eq $setfile){
		print <<EOF;
<td class='button_move' onclick='deleteSettings("$registerName","$fieldName");'>&nbsp;X&nbsp;</td>
EOF
		}	
		print "</tr>";	
	}
	print "</table>";

}


sub read_input
{
    my $buffer; my @pairs; my $pair; my $name; my $value;my %FORM;
    # Read in text
    $ENV{'REQUEST_METHOD'} =~ tr/a-z/A-Z/;
    if ($ENV{'REQUEST_METHOD'} eq "POST")
    {
	read(STDIN, $buffer, $ENV{'CONTENT_LENGTH'});
    } else
    {
	$buffer = $ENV{'QUERY_STRING'};
    }
    # Split information into name/value pairs
    @pairs = split(/&/, $buffer);
    foreach $pair (@pairs)
    {
	($name, $value) = split(/=/, $pair);
	$value =~ tr/+/ /;
	$value =~ s/%(..)/pack("C", hex($1))/eg;
	$FORM{$name} = $value;
    }
    %FORM;
}



sub printJavaScripts {


####### javascript function land ################


print <<EOF ;

<script language="javascript">


function selectedConfigFile(){
var e = document.getElementById("fileSelector");
return e.options[e.selectedIndex].text;
}


var visHash= new Object();


function reloadSpecTree(){
getdata('$me?print=spectree&configFile='+selectedConfigFile(),'roterBereich',false);
for (var key in visHash) {
if(visHash[key]==true){
showElement(key);
}
}
}

function reloadSetTree(){
getdata('$me?print=settree&configFile='+selectedConfigFile(),'blauerBereich',false);
for (var key in visHash) {
if(visHash[key]==true){
showElement(key);
}
}
}

function reloadTrees(){
debugOutput("reload Trees from "+selectedConfigFile());
reloadSpecTree();
reloadSetTree();
}

function reloadFileSelection(){
getdata('$me?print=fileSelection','fileSelection',false);
}

function saveSettings(register,field,value){
//getdata("$me?debuginput=tralla","debug");
var file_ = encodeURIComponent(selectedConfigFile());
var register_ = encodeURIComponent(register);
var field_ = encodeURIComponent(field);
var value_ =  encodeURIComponent(value);

getdata("$me?action=save&configFile="+file_+"&register="+register_+"&field="+field_+"&value="+value_,"debug",false);
//getdata("$me?print=settree","blauerBereich",true);
reloadSetTree();
}

function deleteSettings(register,field){
//getdata("$me?debuginput=tralla","debug");
var file_ = encodeURIComponent(selectedConfigFile());
var register_ = encodeURIComponent(register);
var field_ = encodeURIComponent(field);

getdata("$me?action=delete&configFile="+file_+"&register="+register_+"&field="+field_,"debug",false);
//getdata("$me?print=settree","blauerBereich",true);
reloadSetTree();
}

function copyDefaultRegister(register){
var register_ = encodeURIComponent(register);
var file_ =encodeURIComponent(selectedConfigFile());
getdata("$me?action=copyDefaultRegister&register="+register_+'&configFile='+file_,"debug",false);
//getdata("$me?print=settree","blauerBereich",true);
reloadSetTree();
}

function debugOutput(input){
getdata("$me?debuginput="+encodeURIComponent(input),"debug",true);
}

function writeToElementId(input,destId){
	if(document.getElementById(destId).innerHTML){
	document.getElementById(destId).innerHTML  = input;	
	}

}


function toggleVis(elementId,t) {
if(document.getElementById(elementId)){
if( document.getElementById(elementId).style.visibility == "visible") {
	document.getElementById(elementId).style.visibility = "collapse";
	visHash[elementId]=false;
	t.innerHTML = "&nbsp;&plus;&nbsp;";
} else {
	document.getElementById(elementId).style.visibility = "visible" ;
	visHash[elementId]=true;
  t.innerHTML = "&nbsp;&minus;&nbsp;";
}
}
}
function showElement(elementId) {
	if(document.getElementById(elementId)){
	document.getElementById(elementId).style.visibility = "visible" ;
	visHash[elementId]=true;
	}
}
function hideElement(elementId) {
	if(document.getElementById(elementId)){
	document.getElementById(elementId).style.visibility = "hidden" ;
	visHash[elementId]=false;
	}
}
function collapseElement(elementId) {
	if(document.getElementById(elementId)){
	document.getElementById(elementId).style.visibility = "collapse" ;
	visHash[elementId]=false;
	}
}

</script>

<script language="javascript">
function getdata(command,dId,async) {
  var xmlhttp = null;
  //var cb = null;
  xmlhttp=new XMLHttpRequest();
  //cb = callback;
	var destId = dId;
  
  xmlhttp.onreadystatechange = function() {
    if(xmlhttp.readyState == 4 && xmlhttp.status==200) {
      //if(cb)
	if(document.getElementById(destId).innerHTML){
	document.getElementById(destId).innerHTML  = xmlhttp.responseText;	
	}
        //cb(xmlhttp.responseText);
	//document.getElementById(destId).innerHTML  = xmlhttp.responseText;	
      }
    }

  xmlhttp.open("GET",command,async);
  xmlhttp.send(null);
  }
</script>
EOF

}
