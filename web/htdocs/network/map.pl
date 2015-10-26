#!/usr/bin/perl
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
    print "HTTP/1.0 200 OK\n";
    print "Content-type: text/html\r\n\r\n";
}

else {
    use lib '..';
    use if (!($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i)), apacheEnv;
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
use v5.10;

###############################################################################  
##  Network Map
###############################################################################  
if($ENV{'QUERY_STRING'} =~ /getmap/) {
#   print "Getting map";
    
    trb_init_ports() or
	die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
    
    my $boards   = trb_read_uid(0xffff);
    my $temp     = trb_register_read(0xffff,0);
    my $sfpDat1  = trb_register_read(0xffff,0xd201);
    my $sfpDat2  = trb_register_read(0xffff,0xd202);  
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
    

    print "<table id=\"content\" class=\"content map\"><tr class=\"head map\"><th>Board<th>Hardware<th>Design<th>Compile Time<th>Temperature<th>Link Strength SFP1<th>Link Strength SFP8\n";
    printlist(0,1);
    print "</table>";
    
    sub printlist {
    my ($parent,$layer) = @_;
    if($layer > 16) {die "More than 16 layers of network devices found. Aborting."}
    my @o;
    for (my $p = 0; $p < scalar (@{$tree->{$parent}}); $p++) {
	next unless defined $tree->{$parent}->[$p];
	my $addr = $tree->{$parent}->[$p]->{addr};
	my $btype = "";
	my $value = $hardware->{$addr}>>24&0xff;
	
	if ($value==0x90) {$btype= "TRB3 central";}
	if ($value==0x91) {$btype= "TRB3 periph";}
	if ($value==0x92) {$btype= "CBM-Rich";}
	if ($value==0x93) {$btype= "CBM-Tof";}
	if ($value==0x83) {$btype= "TRB2 RPC";}
	if ($value==0x81) {$btype= "TRB2 TOF";}
	if ($value==0x62) {$btype= "Hub AddOn";}
	if ($value==0x52) {$btype= "CTS";}
	if ($value==0x42) {$btype= "Shower AddOn";}
	if ($value==0x33) {$btype= "RICH ADCM"; }
	if ($value==0x23) {$btype= "MDC OEP"; }
	if ($value==0x12) {$btype= "MDC Hub"; }
        
	my $addontype = "";  
	if(($hardware->{$addr}>>24&0xff) == 0x91) {
	    $value= $hardware->{$addr}>>12 & 0xF; 
	    if ($value==0) {$addontype= " & ADA v1";}
	    if ($value==1) {$addontype= " & ADA v2";}
	    if ($value==2) {$addontype= " & Multitest";}
	    if ($value==3) {$addontype= " & SFP";}
	    if ($value==4) {$addontype= " & Padiwa";}
	    if ($value==5) {$addontype= " & GPIN";}
	    if ($value==6) {$addontype= " & Nxyter";}
	    if ($value==7) {$addontype= " & 32PinAddOn";}
	    if ($value==9) {$addontype= " & ADC AddOn";}
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
	    if($inclLow->{$addr}&0x30000) { #GbE
		$feat .= "\nGbE: ";
		if($inclLow->{$addr} & 0x10000) {
		    $feat .= "data sending buffer 64kB, " if(($inclLow->{$addr} & 0xc0000) == 0x40000);
		    $feat .= "data sending, "             if(($inclLow->{$addr} & 0xc0000) == 0x00000);
		}
		if($inclLow->{$addr} & 0x20000) {
		    $feat .= "slow control buffer 4kB, "  if(($inclLow->{$addr} & 0x300000) == 0x10000);
		    $feat .= "slow control buffer 64kB, " if(($inclLow->{$addr} & 0x300000) == 0x20000);
		    $feat .= "slow control, "             if(($inclLow->{$addr} & 0x300000) == 0x00000);
		    $feat .= "with multi-packet"          if ($inclLow->{$addr} & 0x400000);
		}
	    }
	    $feat .= "\nHub: ".(($inclLow->{$addr}>>24)&0x7)." SFPs";  
        }
	if($table == 2) {
	    if($inclLow->{$addr}&0x8000) {  # ||1 just because this not implemented yet in the test design..
		$feat .="\nTDC:";
		$feat .= GetTDCInfo($addr,$inclLow->{$addr},1);
	    }
        }
	if($table == 3) {
	    $feat .= sprintf("%i sensors in %i chains",$inclLow->{$addr} & 0xff,$inclLow->{$addr}>>8 & 0xf);
	    $feat .= ", normal readout"    if ($inclLow->{$addr}>>16 & 0x3) == 0;
	    $feat .= ", testmode"          if ($inclLow->{$addr}>>16 & 0x3) == 1;
	    $feat .= ", testmode optional" if ($inclLow->{$addr}>>16 & 0x3) == 2;
	    $feat .= ", for M26"           if ($inclLow->{$addr}>>20 & 0xf) == 0;
        }
	if($table == 4) {
	    $feat .= sprintf("Channels: %i",               $inclLow->{$addr}>>16 & 0x000000ff);
	    $feat .= sprintf(", Sampling Frequency %i MHz",$inclLow->{$addr}>>0  & 0x000000ff);
	    $feat .= "\nDummy read-out"                if ($inclLow->{$addr}&0x0f00) == 0x000;
	    $feat .= "\nBasic Processing and trigger"  if ($inclLow->{$addr}&0x0f00) == 0x100;
	    $feat .= "\nAdvanced filtering"            if ($inclLow->{$addr}&0x0f00) == 0x200;
	    $feat .= "\nFeature Extraction"            if ($inclLow->{$addr}&0x0f00) == 0x800;
	    $feat .= ", baseline determination"        if ($inclLow->{$addr}&0x4000);
	    $feat .= ", trigger generation"            if ($inclLow->{$addr}&0x8000);
        }
	if($table == 1 || $table == 2 || $table ==3 || $table == 4) {
	    if ($inclHigh->{$addr} & 0x200) { $feat .= "\nReference Time: through Clock Manager";}
	    if ($inclHigh->{$addr} & 0x400) { $feat .= "\nSPI";}
	    if ($inclHigh->{$addr} & 0x800) { $feat .= "\nUART";}
	    if ($inclHigh->{$addr}>>12&0xF) {
		$feat .= "\nInput monitor:";
		my $d = trb_register_read($addr,0xcf8f);
		$feat .= " ".($d->{$addr}>>8&0x1F)." inputs";
		$feat .= ", single Fifo" if     $d->{$addr}&0x8000;
		$feat .= ", indiv. Fifos" unless $d->{$addr}&0x8000;
	    }
	    
	    if(($inclHigh->{$addr}>>16&0xF) == 1 || ($inclHigh->{$addr}>>16&0xF) == 2) {
		my $value = $inclHigh->{$addr}>>16&0xF;  
		if($value==1) {$feat .="\nTrigger Module: simple or";}
		if($value==2) {$feat .="\nTrigger Module: edge detect";}
		my $d = trb_register_read($addr,0xcf27);
		$feat .= sprintf(", %i inputs, %i outputs",($d->{$addr}&0x3F),($d->{$addr}>>8&0xF));
	    }
	    my $value = $inclHigh->{$addr}>>20&0xF; 
		if ($value==0) {$feat .="\nClock: on-board 200 MHz";}
		if ($value==1) {$feat .="\nClock: on-board 125 MHz";}
		if ($value==2) {$feat .="\nClock: received 200 MHz";}
		if ($value==3) {$feat .="\nClock: received 125 MHz";}
		if ($value==4) {$feat .="\nClock: external 200 MHz";}
		if ($value==5) {$feat .="\nClock: external 125 MHz";}
	}
	
	# SFP Optical Transceiver Rx Power Readbacks
	my $SFP1Rx = "-";
	my $SFP2Rx = "-";
	my $SFP3Rx = "-";
	my $SFP4Rx = "-";
	my $SFP5Rx = "-";
	my $SFP6Rx = "-";
	my $SFP7Rx = "-";
	my $SFP8Rx = "-";
	
	if ( ($btype eq "TRB3 central") || ($btype eq "Hub AddOn") ) {
	    $SFP1Rx = "NA";
	    my $val1 = ($sfpDat1->{$addr} & 0x000000FF);
	    if ($val1 != 254) {
		$val1 = int(($val1 * 1.6) + 0.5);
		if ($val1 < 150) {
		    $SFP1Rx = "<font color = 'red'>$val1 uW</font>";
		} else {
		    $SFP1Rx = "$val1 uW";
		}
	    }
	    $SFP2Rx = "NA";
	    my $val2 = ($sfpDat1->{$addr} >>  8) & 0x000000FF;
	    if ($val2 != 254) {
		$val2 = int(($val2 * 1.6) + 0.5);
	        if ($val2 < 150) {
		    $SFP2Rx = "<font color = 'red'>$val2 uW</font>";
		} else {
		    $SFP2Rx = "$val2 uW";
		}
	    }
	    $SFP3Rx = "NA";
	    my $val3 = ($sfpDat1->{$addr} >> 16) & 0x000000FF;
	    if ($val3 != 254) {
		$val3 = int(($val3 * 1.6) + 0.5);
		if ($val3 < 150) {
		    $SFP3Rx = "<font color = 'red'>$val3 uW</font>";
		} else {
		    $SFP3Rx = "$val3 uW";
		}
	    }
	    $SFP4Rx = "NA";
	    my $val4 = ($sfpDat1->{$addr} >> 24);
	    if ($val4 != 254) {
		$val4 = int(($val4 * 1.6) + 0.5);
		if ($val4 < 150) {
		    $SFP4Rx = "<font color = 'red'>$val4 uW</font>";
		} else {
		    $SFP4Rx = "$val4 uW";
		}
	    }
	    $SFP5Rx = "NA";
	    my $val5 = ($sfpDat2->{$addr} & 0x000000FF);
	    if ($val5 != 254) {
		$val5 = int(($val5 * 1.6) + 0.5);
		if ($val5 < 150) {
		    $SFP5Rx = "<font color = 'red'>$val5 uW</font>";
		} else {
		    $SFP5Rx = "$val5 uW";
		}
	    }
	    $SFP6Rx = "NA";
	    my $val6 = ($sfpDat2->{$addr} >>  8) & 0x000000FF;
	    if ($val6 != 254) {
		$val6 = int(($val6 * 1.6) + 0.5);
		if ($val6 < 150) {
		    $SFP6Rx = "<font color = 'red'>$val6 uW</font>";
		} else {
		    $SFP6Rx = "$val6 uW";
		}
	    }
	    $SFP7Rx = "NA";
	    my $val7 = ($sfpDat2->{$addr} >> 16) & 0x000000FF;
	    if ($val7 != 254) {
		$val7 = int(($val7 * 1.6) + 0.5);
		if ($val7 < 150) {
		    $SFP7Rx = "<font color = 'red'>$val7 uW</font>";
		} else {
		    $SFP7Rx = "$val7 uW";
		}
	    }
	    $SFP8Rx = "NA";
	    my $val8 = ($sfpDat2->{$addr} >> 24);
	    if ($val8 != 254) {
		$val8 = int(($val8 * 1.6) + 0.5);
		if ($val8 < 150) {
		    $SFP8Rx = "<font color = 'red'>$val8 uW</font>";
		} else {
		    $SFP8Rx = "$val8 uW";
		}
	    }
	}
	
	printf("<tr class=\"level level%i%s\"><td><div>%i</div>0x%04x<td title=\"0x%08x\">%s<td title=\"0x%08x%08x\n%s\">%s<td title=\"0x%08x\">%s<td>%.1f°C<td>%s<td>%s\n",
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
	       ($temp->{$addr}>>20)/16,
	       $SFP1Rx,
	       $SFP8Rx);
	
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
    my $module = ($info>>16&0x3)+1;
    $feat .= " ".($d->{$addr}>>8&0xFF)." channels";
    $feat .= " read by ".$module." module(s)";
    $feat .= ", version ".(($d->{$addr}&0x0e000000)>>25).".".(($d->{$addr}&0x1e00000)>>21).".".(($d->{$addr}&0x1e0000)>>17);
    my $value;
    if($inp) {
	$value = $info&0xFF;
	if ($value==0) {$feat .=", input select by mux";}
	if ($value==1) {$feat .=", input 1-to-1";}
	if ($value==2) {$feat .=", on every second input";}
	if ($value==3) {$feat .=", on every fourth input";}
	
	$value = $info>>8&0xF;
	if ($value==0) {$feat .=", single edge";}
	if ($value==1) {$feat .=", dual edge in same channel";}
	if ($value==2) {$feat .=", dual edge in alternating channels";}
	if ($value==3) {$feat .=", dual edge same channel + stretcher";}
	
	$value = $info>>12&0x7;
	if ($value==0) {$feat .=", RingBuffer size: 12 words";}
	if ($value==1) {$feat .=", RingBuffer size: 44 words";}
	if ($value==2) {$feat .=", RingBuffer size: 76 words";}
	if ($value==3) {$feat .=", RingBuffer size: 108 words";}
    }
	
    return $feat;
}

1;


