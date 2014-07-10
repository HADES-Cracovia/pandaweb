#!/usr/bin/perl -w
use FileHandle;
use Data::Dumper;
use POSIX qw(strftime);
use lib "./code";
use Dmon;

my %config = do $ARGV[0];


while(1) {

open(FLOG, "tail -F ".Dmon::DMONDIR."qalog|") or (sleep(5) and next);

my $readlines = 0;
my $str = "";
my $oldtime = time();
my $store;

my @widthsettings = (3,3,4,5,6,7);

my $width = $widthsettings[scalar @{$config{activeScripts}->[0]}];


while($a = <FLOG>) {
#Store new entries
  chomp $a;
  my ($timestamp,$entry,$ttl,$sev,$title,$value,$longtext,$link) = split("\t",$a);
  $store->{$entry}->{"sev"} = $sev;
  $store->{$entry}->{"title"} = $title;
  $store->{$entry}->{"val"} = $value;
  $store->{$entry}->{"time"} = $timestamp;
  $store->{$entry}->{"ttl"} = $ttl+$timestamp;
  $store->{$entry}->{"long"} = $longtext || "No Text";
  $store->{$entry}->{"link"} = $link;


#Delete file if it contains more than 10000 lines
  if($readlines++ > 10000) {
    $readlines = 0;
    close(FLOG);
    open(FL,">".Dmon::DMONDIR."/qalog");
    close(FL);
    open(FLOG, "tail -F ".Dmon::DMONDIR."/qalog|");
    }
  my $i = 0;
#Generate output file at most once per second
  if(1 || $oldtime < time) {
    $oldtime = scalar time();
    $str  = Dmon::MakeTitle($width,7,"Tactical Overview",1);
    $str .= "<div class=\"QA\">";
    foreach my $row (@{$config{activeScripts}}) {
      $str .= "<div class=\"header\" style=\"clear:both\">".($config{qaNames}->[$i++])."</div>\n";
      foreach my $e (@$row) {
        my $sev   = $store->{$e}->{'sev'} || 0;
        my $value = $store->{$e}->{'val'} || "";
        my $title = $store->{$e}->{'title'} || $e;
        my $tim   = $store->{$e}->{'time'} || -1;
        my $time  = strftime("(%H:%M:%S)",localtime($tim)) if $tim != -1;
           $time  = "" if $tim == -1;
        my $text  = $store->{$e}->{'long'} || "";
        my $ttl   = $store->{$e}->{'ttl'} || 0;
        my $link  = $store->{$e}->{'link'} || "";
        
        if (!defined($sev)||$sev==Dmon::NA) {$sevcol = "bgr";}
        elsif ($ttl < $oldtime)             {$sevcol = "bwh";}
        elsif ($sev == Dmon::NOSTATE)       {$sevcol = "bbl";}
        elsif ($sev == Dmon::SCRIPTERROR)   {$sevcol = "bmg";}
        elsif ($sev < Dmon::NOTE)           {$sevcol = "bgn";}
        elsif ($sev < Dmon::WARN)           {$sevcol = "byg";}
        elsif ($sev < Dmon::WARN_2)         {$sevcol = "bye";}
        elsif ($sev < Dmon::ERROR)          {$sevcol = "bor";}
        elsif ($sev < Dmon::LETHAL)         {$sevcol = "brd";}
        elsif ($sev == Dmon::LETHAL)        {$sevcol = "brdb";}
        else                              {$sevcol = "bgr";}

        
        $str .= "<div id=\"$e\" class=\"".($sev||0)." $sevcol\" alt=\"$title $time: ".Dmon::LevelName($sev)."&lt;br /&gt; $text\" onmouseover=\"clk(this);\"";
        $str .= "onclick=\"openhelp('$link')\" >".$title."<br/>".$value."</div>\n";
        }
 
      }
    $str .="<div id=\"footer\" class=\"footer\"></div></div>";

    $str .= Dmon::MakeFooter();
    Dmon::WriteFile("QA",$str);      
     
    }
  }
  sleep(5);
}
