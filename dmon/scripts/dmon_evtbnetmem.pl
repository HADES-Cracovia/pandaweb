#!/usr/bin/perl -w

use warnings;
use strict;
use POSIX qw(strftime ceil floor);
use FileHandle;
use lib "./code";
use lib "./scripts";
use lib "../tools";
use lib "../users/gsi_dirc";
use lib "../perllibs/";
use List::Util qw[min max];
use Dmon;
use Data::Dumper;

my %config = Dmon::StartUp();

# my $str = Dmon::MakeTitle(9,10,"EvtbNetmem",0);
#    $str .= qq@<div style="padding:0"><img src="%ADDPNG EvtbNetmem.png%" type="image/png"></div></div>@;
#    $str .= Dmon::MakeFooter();
# Dmon::WriteFile("EvtbNetmem",$str);


# my $plot_filename = Dmon::DMONDIR."EvtbNetmem".".png";
my $shm_string = $config{EvtbNetmem}->{shm_string};
# print "$shm_string.\n";
my $eb_shm = "/dev/shm/daq_evtbuild$shm_string.shm";
my $nm_shm = "/dev/shm/daq_netmem$shm_string.shm";


while (1) {



  my $eb_data = slurp_shm($eb_shm);
  my $nm_data = slurp_shm($nm_shm);
  
#   print "evtbuid keys: \n".join(" ",sort keys %$eb_data)."\n\n"; 
#   print "netmem  keys: \n".join(" ",sort keys %$nm_data)."\n\n"; 
#  #evtbuid keys: 
#  #PID bytesWritten coreNr dataMover diskNum diskNumEB errBit0 errBit1 errBit10 errBit11 errBit12 errBit2 errBit3 errBit4 errBit5 errBit6 errBit7 errBit8 errBit9 errBitPtrn0 errBitPtrn1 errBitPtrn2 errBitPtrn3 errBitPtrn4 errBitStat0_0 errBitStat0_1 errBitStat0_10 errBitStat0_11 errBitStat0_12 errBitStat0_2 errBitStat0_3 errBitStat0_4 errBitStat0_5 errBitStat0_6 errBitStat0_7 errBitStat0_8 errBitStat0_9 errBitStat1_0 errBitStat1_1 errBitStat1_10 errBitStat1_11 errBitStat1_12 errBitStat1_2 errBitStat1_3 errBitStat1_4 errBitStat1_5 errBitStat1_6 errBitStat1_7 errBitStat1_8 errBitStat1_9 errBitStat2_0 errBitStat2_1 errBitStat2_10 errBitStat2_11 errBitStat2_12 errBitStat2_2 errBitStat2_3 errBitStat2_4 errBitStat2_5 errBitStat2_6 errBitStat2_7 errBitStat2_8 errBitStat2_9 errBitStat3_0 errBitStat3_1 errBitStat3_10 errBitStat3_11 errBitStat3_12 errBitStat3_2 errBitStat3_3 errBitStat3_4 errBitStat3_5 errBitStat3_6 errBitStat3_7 errBitStat3_8 errBitStat3_9 errBitStat4_0 errBitStat4_1 errBitStat4_10 errBitStat4_11 errBitStat4_12 errBitStat4_2 errBitStat4_3 errBitStat4_4 errBitStat4_5 errBitStat4_6 errBitStat4_7 errBitStat4_8 errBitStat4_9 evtId0 evtId1 evtId10 evtId11 evtId12 evtId13 evtId14 evtId15 evtId16 evtId17 evtId18 evtId19 evtId2 evtId20 evtId21 evtId22 evtId23 evtId24 evtId25 evtId26 evtId27 evtId28 evtId29 evtId3 evtId30 evtId31 evtId32 evtId33 evtId34 evtId35 evtId36 evtId37 evtId38 evtId39 evtId4 evtId40 evtId41 evtId42 evtId43 evtId44 evtId45 evtId46 evtId47 evtId48 evtId49 evtId5 evtId50 evtId51 evtId52 evtId53 evtId54 evtId55 evtId56 evtId57 evtId58 evtId59 evtId6 evtId60 evtId61 evtId62 evtId63 evtId7 evtId8 evtId9 evtbuildBuff0 evtbuildBuff1 evtbuildBuff10 evtbuildBuff11 evtbuildBuff12 evtbuildBuff2 evtbuildBuff3 evtbuildBuff4 evtbuildBuff5 evtbuildBuff6 evtbuildBuff7 evtbuildBuff8 evtbuildBuff9 evtsComplete evtsDataError evtsDiscarded evtsTagError nrOfMsgs pid prefix runId trigNr0 trigNr1 trigNr10 trigNr11 trigNr12 trigNr2 trigNr3 trigNr4 trigNr5 trigNr6 trigNr7 trigNr8 trigNr9

#  #netmem  keys: 
#  #PID bytesReceived0 bytesReceived1 bytesReceived10 bytesReceived11 bytesReceived12 bytesReceived2 bytesReceived3 bytesReceived4 bytesReceived5 bytesReceived6 bytesReceived7 bytesReceived8 bytesReceived9 bytesReceivedRate0 bytesReceivedRate1 bytesReceivedRate10 bytesReceivedRate11 bytesReceivedRate12 bytesReceivedRate2 bytesReceivedRate3 bytesReceivedRate4 bytesReceivedRate5 bytesReceivedRate6 bytesReceivedRate7 bytesReceivedRate8 bytesReceivedRate9 coreNr msgsDiscarded0 msgsDiscarded1 msgsDiscarded10 msgsDiscarded11 msgsDiscarded12 msgsDiscarded2 msgsDiscarded3 msgsDiscarded4 msgsDiscarded5 msgsDiscarded6 msgsDiscarded7 msgsDiscarded8 msgsDiscarded9 msgsReceived0 msgsReceived1 msgsReceived10 msgsReceived11 msgsReceived12 msgsReceived2 msgsReceived3 msgsReceived4 msgsReceived5 msgsReceived6 msgsReceived7 msgsReceived8 msgsReceived9 netmemBuff0 netmemBuff1 netmemBuff10 netmemBuff11 netmemBuff12 netmemBuff2 netmemBuff3 netmemBuff4 netmemBuff5 netmemBuff6 netmemBuff7 netmemBuff8 netmemBuff9 nrOfMsgs pid pktsDiscarded0 pktsDiscarded1 pktsDiscarded10 pktsDiscarded11 pktsDiscarded12 pktsDiscarded2 pktsDiscarded3 pktsDiscarded4 pktsDiscarded5 pktsDiscarded6 pktsDiscarded7 pktsDiscarded8 pktsDiscarded9 pktsReceived0 pktsReceived1 pktsReceived10 pktsReceived11 pktsReceived12 pktsReceived2 pktsReceived3 pktsReceived4 pktsReceived5 pktsReceived6 pktsReceived7 pktsReceived8 pktsReceived9 portNr0 portNr1 portNr10 portNr11 portNr12 portNr2 portNr3 portNr4 portNr5 portNr6 portNr7 portNr8 portNr9

  
  
#   print "eb data:\n";
#   print "evtsComplete: ".Dmon::SciNotation($eb_data->{evtsComplete})."\n";
#   print "bytesWritten: ".Dmon::SciNotation($eb_data->{bytesWritten})."\n";
#   print Dumper $eb_data;
#   print "nm data:\n";
#   print Dumper $nm_data;
 
  eval{ 
    my $status = Dmon::OK;
       $status = Dmon::ERROR unless defined $eb_data->{evtsComplete};
    my $title  = "EvtsComplete";
    my $value = Dmon::SciNotation($eb_data->{evtsComplete});
    my $longtext = "See plot";
    Dmon::WriteQALog($config{flog},"evtbnetmem",5,$status,$title,$value,$longtext,'');
  };
  eval{ 
    my $status = Dmon::OK;
       $status = Dmon::ERROR unless defined $eb_data->{bytesWritten};
    my $title  = "BytesWritten";
    my $value = Dmon::SciNotation($eb_data->{bytesWritten});
    my $longtext = "See plot";
    Dmon::WriteQALog($config{flog},"eb2",5,$status,$title,$value,$longtext,'');
  };
#   eval{ 
#     my $status = Dmon::OK;
#     my $title  = "NetmemStatus";
#     my $value = "dummy";
#     my $longtext = "See plot";
#     Dmon::WriteQALog($config{flog},"eb3",5,$status,$title,$value,$longtext,'');
#   };
  sleep(1);
}

sub slurp_shm {
  
  my $infile = shift;
  open (INFILE, "<", $infile) or return;
  binmode (INFILE);
  
  my $data = {};
  while (1) {
    my $string;
    my $rawval;
    read (INFILE, $string, 32) or last;
    ($string) = $string =~ m/^([\w]+)/;
    last unless ($string);
    read (INFILE, $rawval   ,  8) or last;
    my $number = unpack("L",pack("a8",$rawval));
#     printf("%20s : %16d (0x%016X) \n",$string,$number,$number);
    $data->{$string}=$number;
  }
  close(INFILE);
  return $data;
}
