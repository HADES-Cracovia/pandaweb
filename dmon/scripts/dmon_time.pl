#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX qw(strftime);
use FileHandle;
use lib "./code";
use Dmon;

use Getopt::Long;

my $flog = Dmon::OpenQAFile();

Dmon::WriteQALog($flog,"daqop",100000000,Dmon::NOSTATE,"trbnetd",$ENV{"DAQOPSERVER"},"Trbnet daemon is accessed via ".$ENV{"DAQOPSERVER"});



while(1) {
  my $title    = "Wall Clock";
  my $value    = strftime("%H:%M:%S", localtime());
  my $longtext = "This is a good time to work.";
  Dmon::WriteQALog($flog,"time",10,Dmon::OK,$title,$value,$longtext);

  sleep(2);
}
