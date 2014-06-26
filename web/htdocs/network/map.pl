#!/usr/bin/perl
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Content-type: text/html\r\n\r\n";
  }
else {
  use lib '..';
#  use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
  print "Content-type: text/html\n\n";
  }

use CGI ':standard';
use HADES::TrbNet;
use POSIX;
use CGI::Carp qw(fatalsToBrowser);
use lib qw|../commands htdocs/commands|;
use xmlpage;
use Data::Dumper;
use Date::Format qw(time2str);
use v5.16;

###############################################################################  
##  Network Map
###############################################################################  
if($ENV{'QUERY_STRING'} =~ /getmap/) {
#   print "Getting map";
  
  trb_init_ports() or
    die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
    
  my $boards   = trb_read_uid(0xffff);
  my $temp     = trb_register_read(0xffff,0);
  my $ctime    = trb_register_read(0xffff,0x40);
  my $inclLow  = trb_register_read(0xffff,0x41);
  my $hardware = trb_register_read(0xffff,0x42);
  my $inclHigh = trb_register_read(0xffff,0x43);
  
  my @store;
  my $tree;
  my $lastlayer = 1;

  foreach my $id (keys %{$boards}) {
    foreach my $f (keys %{$boards->{$id}}) {
      my $addr = $boards->{$id}->{$f};
      next if $addr == 0xfc00;
      my @path = trb_nettrace($addr);
      my $parent, my $port;
      if(scalar @path == 0) {
        $parent = 0;
        $port   = 0;
        }
      else {
        $parent = $path[-1][-1]->{address};
        $port   = $path[-1][-1]->{port};
        }
      $tree->{$parent}->[$port]->{addr}   = $addr;
      }
    }


  print "<table id=\"content\" class=\"content map\"><tr class=\"head map\"><th>Board<th>Hardware<th>Design<th>Compile Time<th>Temperature\n";
  printlist(0,1);
  print "</table>";
  
  sub printlist {
    my ($parent,$layer) = @_;
    if($layer > 16) {die "More than 16 layers of network devices found. Aborting."}
    my @o;
    foreach my $p (keys @{$tree->{$parent}}) {
      next unless defined $tree->{$parent}->[$p];
      my $addr = $tree->{$parent}->[$p]->{addr};
      my $btype = "";
      for($hardware->{$addr}>>24&0xff) {
        when (0x90) {$btype= "TRB3 central";}
        when (0x91) {$btype= "TRB3 periph";}
        when (0x92) {$btype= "CBM-Rich";}
        when (0x93) {$btype= "CBM-Tof";}
        when (0x83) {$btype= "TRB2 RPC";}
        when (0x81) {$btype= "TRB2 TOF";}
        when (0x62) {$btype= "Hub AddOn";}
        when (0x52) {$btype= "CTS";}
        when (0x42) {$btype= "Shower AddOn";}
        when (0x33) {$btype= "RICH ADCM"; }
        when (0x23) {$btype= "MDC OEP"; }
        when (0x12) {$btype= "MDC Hub"; }
        }
      my $addontype = "";  
      if(($hardware->{$addr}>>24&0xff) == 0x91) {
        for($hardware->{$addr}>>12 & 0x7) {
          when (0) {$addontype= " & ADA v1";}
          when (1) {$addontype= " & ADA v2";}
          when (2) {$addontype= " & Multitest";}
          when (3) {$addontype= " & SFP";}
          when (4) {$addontype= " & Padiwa";}
          when (5) {$addontype= " & GPIN";}
          when (6) {$addontype= " & Nxyter";}
          when (7) {$addontype= " & 32PinAddOn";}
          when (9) {$addontype= " & MVD AddOn 13";}
          }
        }      
      my $feat = "";
      my $table = $inclHigh->{$addr}>>24&0xFF;
      if($table == 0) {
        my $hw = $hardware->{$addr};
        if(($hw>>24&0xff) == 0x91 || ($hw>>24&0xff) == 0x92 || ($hw>>24&0xff) == 0x93) {
          if(($hw & 0x8000) == 0x8000) {$feat .= "RX sync, ";}
          if(($hw & 0x0b00) == 0x000 && ($hw>>12 & 0x7) != 6 && ($hw>>12 & 0x7) != 3 && ($hw>>7 & 0x1) != 1) 
                                                      {$feat .= "TDC, single, ".(2**($hw>>4&0xf))."ch, ";}
          if(($hw & 0xf000) == 0x6000) {$feat .= "Nxyter RDO, ";}
          if(($hw & 0x0900) == 0x100)  {$feat .= "TDC, double, ".(2**($hw>>4&0xf))."ch, ";}
          if(($hw & 0x0900) == 0x800)  {$feat .= "TDC, dbl-sep, ".(2**($hw>>4&0xf))."ch, ";}
          if(($hw & 0x0200) == 0x200)  {$feat .= "Hub, ";}
          if(($hw & 0x0400) == 0x400)  {$feat .= "SPI, ";}
          if(($hw & 0x00f0) == 0x090)  {$feat .= "MVD rdo 2013, ";}
          $feat = substr($feat,0,-2);
          }
        if(($hw>>24&0xff) == 0x90) {
          if(($hw & 0xf001) == 0xc000) {$feat .= "CTS, ";}
          if(($hw & 0xf001) == 0xc001) {$feat .= "CTS w/AddOn, ";}
          if(($hw & 0x0f00) == 0x0e00) {$feat .= "GbE sctrl rdo, ";}
          if(($hw & 0x0f00) == 0x0d00) {$feat .= "GbE rdo, ";}
          if(($hw & 0x0010) != 0x0000) {$feat .= "opt. trg in, ";}
          if(($hw & 0x0020) != 0x0000) {$feat .= "opt. sctrl in, ";}
          if(($hw & 0x0040) != 0x0000) {$feat .= "opt. trg out, ";}
          if(($hw & 0x0080) != 0x0000) {$feat .= "opt. sctrl out, ";}
          $feat = substr($feat,0,-2);          
          }
        if ($feat eq "") {$feat = "N/A";}
        }
      if($table == 1) {
        if($inclLow->{$addr}&0x8000) { #CTS
          $feat .= "\nCTS: ";
          if(($inclLow->{$addr} & 0xF) == 1) { $feat .= "CBM-MBS module, ";}
          if(($inclLow->{$addr} & 0xF) == 2) { $feat .= "Mainz A2 module, ";}
          if(($inclLow->{$addr} & 0x10))     { 
            $feat .= "\nTDC: ";
            if(($inclLow->{$addr} & 0x20)) { $feat .= "non-standard pinout, ";}
            $feat .= GetTDCInfo($addr,$inclLow->{$addr},1);
            }
          }
        if($inclLow->{$addr}&0x800000) { #GbE
          $feat .= "\nGbE: ";
          if($inclLow->{$addr} & 0x10000) {$feat .= "data sending, ";}
          if($inclLow->{$addr} & 0x20000) {
            $feat .="slow control, ";
            if($inclLow->{$addr} & 0x400000) {
              $feat .= "with multi-packet";
              }
            }
          }
        $feat .= "\nHub: ".(($inclLow->{$addr}>>24)&0x7)." SFPs";  
        }
      if($table == 2) {
        if($inclLow->{$addr}&0x8000 || 1) {  # ||1 just because this not implemented yet in the test design..
          $feat .="\nTDC:";
          $feat .= GetTDCInfo($addr,$inclLow->{$addr},1);
          }
        }
      if($table == 1 || $table == 2) {
        if ($inclHigh->{$addr} & 0x400) { $feat .= "\nSPI";}
        if ($inclHigh->{$addr} & 0x800) { $feat .= "\nUART";}
        if ($inclHigh->{$addr}>>12&0xF) {
          $feat .= "\nInput monitor:";
          my $d = trb_register_read($addr,0xcf8f);
          $feat .= " ".($d->{$addr}>>8&0x1F)." inputs";
          $feat .= ", single Fifo" if     $d->{$addr}&0x1000;
          $feat .= ", indiv. Fifos" unless $d->{$addr}&0x1000;
          }

        if(($inclHigh->{$addr}>>16&0xF) == 1 || ($inclHigh->{$addr}>>16&0xF) == 2) {
          for($inclHigh->{$addr}>>16&0xF) {  
            when(1) {$feat .="\nTrigger Module: simple or";}
            when(2) {$feat .="\nTrigger Module: edge detect";}
            }
          my $d = trb_register_read($addr,0xcf27);
          $feat .= sprintf(", %i inputs, %i outputs",($d->{$addr}&0x3F),($d->{$addr}>>8&0xF));
          }
        for($inclHigh->{$addr}>>20&0xF) {  
          when(0) {$feat .="\nClock: on-board 200 MHz";}
          when(1) {$feat .="\nClock: on-board 125 MHz";}
          when(2) {$feat .="\nClock: received 200 MHz";}
          when(3) {$feat .="\nClock: received 125 MHz";}
          when(4) {$feat .="\nClock: external 200 MHz";}
          when(5) {$feat .="\nClock: external 125 MHz";}
          }    
        }
      
      printf("<tr class=\"level level%i%s\"><td><div>%i</div>0x%04x<td title=\"0x%08x\">%s<td title=\"0x%08x%08x\n%s\">%s<td title=\"0x%08x\">%s<td>%.1f°C\n",
                      $layer,
                      ($layer!=$lastlayer?' newlevel':' oldlevel'),
                      $p,
                      $addr,
                      $hardware->{$addr},
                      $btype.$addontype,
                      $inclHigh->{$addr},
                      $inclLow->{$addr},
                      $feat,
                      substr($feat,0,40).(length($feat)>40?"...":""),
                      $ctime->{$addr},
                      time2str('%Y-%m-%d %H:%M',$ctime->{$addr}),
                      ($temp->{$addr}>>20)/16);
      $lastlayer = $layer;
      printlist($tree->{$parent}->[$p]->{addr},$layer+1);
      }
    return 0;
    }
  }
  
###############################################################################  
##  Main page
###############################################################################  
else {
  my $page;
  $page->{title} = "TrbNet Network Setup";
  $page->{link}  = "../";
  $page->{getscript} = "map.pl";

  my @setup;
  $setup[0]->{name}    = "NetworkMap";
  $setup[0]->{cmd}     = "getmap";
  $setup[0]->{period}  = -1;
  $setup[0]->{noaddress} = 1;
  $setup[0]->{norate}    = 1;
  $setup[0]->{nocache}   = 1;
  $setup[0]->{generic}   = 0;

  xmlpage::initPage(\@setup,$page);
  } 

sub GetTDCInfo {
  my ($addr,$info,$inp) = @_;
  my $d = trb_register_read($addr,0xc100);
  my $feat = "";
  $feat .= " ".($d->{$addr}>>8&0xFF)." channels";
  $feat .= ", version ".(($d->{$addr}&0x0e000000)>>25).".".(($d->{$addr}&0x1e00000)>>21).".".(($d->{$addr}&0x1e0000)>>17);
  if($inp) {
    for($info&0xFF) {
      when (0) {$feat .=", input select by mux";}
      when (1) {$feat .=", input 1-to-1";}
      when (2) {$feat .=", on every second input";}
      when (3) {$feat .=", on every fourth input";}
      }
    }
  for($info>>8&0xF) {
    when (0) {$feat .=", single edge";}
    when (1) {$feat .=", dual edge in same channel";}
    when (2) {$feat .=", dual edge in alternating channels";}
    when (3) {$feat .=", dual edge same channel + stretcher";}
    }
  return $feat;
  }

1;


