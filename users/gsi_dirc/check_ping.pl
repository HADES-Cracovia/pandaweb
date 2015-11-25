#!/usr/bin/perl

use warnings;
use strict;
use Parallel::ForkManager;
use Net::Ping;
use Getopt::Long;
use Data::Dumper;

my $power;
my $reboot;
my $help;

my $result = GetOptions (
			 "h|help"          => \$help,
			 "p|powercycle"    => \$power,
			 "r|reboot"    => \$reboot
			);


# not used.... :-)
#my @trbs = (56, 72, 99, 73, 74, 104, 97, 59, 89, 57);

my $map = {
	   0  =>  { trb =>  72, sys => "MCP 00" },
	   1  =>  { trb =>  99, sys => "MCP 01" },
	   2  =>  { trb =>  73, sys => "MCP 02" },
	   3  =>  { trb =>  74, sys => "MCP 03" },
	   4  =>  { trb => 104, sys => "MCP 04" },
#	   5  =>  { trb =>  97, sys => "TOF 1"  },
#	   6  =>  { trb =>  59, sys => "TOF 2"  },
#	   7  =>  { trb =>  89, sys => "HODO"   },
	   5  =>  { trb =>  57, sys => "AUX"    },
	   -1 =>  { trb =>  56, sys => "CTS"    },
	  };

my $MAX_PROCESSES=30;
my $pm = Parallel::ForkManager->new($MAX_PROCESSES);
my $maximal_reboot_counter = 4;
my $number_of_reboots_done = 0;

my $rh_unsuccessful = {};

$pm->run_on_finish(
		   sub { my ($pid, $exit_code, $ident,  $exit_signal, $core_dump, $data_structure_reference) = @_;
			 #print "** $ident just got out of the pool ".
			 #    "with PID $pid and exit code: $exit_code\n";
			 #print Dumper ($pid, $exit_code, $ident,  $exit_signal, $core_dump, $data_structure_reference);
			 if ($exit_code == 0) {
			   $rh_unsuccessful->{$ident} = $$data_structure_reference;
			 }
		       }
		  );




#my $p = Net::Ping->new();

my $first_iteration = 1;

#print Dumper keys %$rh_unsuccessful;

while ( (($first_iteration == 1) || keys %$rh_unsuccessful) &&
	($number_of_reboots_done < $maximal_reboot_counter) ) {
  #print Dumper $rh_unsuccessful;
  #print Dumper keys %$rh_unsuccessful;

  $rh_unsuccessful = {};
  $first_iteration = 0;
  foreach my $ct (keys %$map) {
    my $success = 0;
    #my $num = sprintf "%3.3d", $ct;
    my $trbnum= $map->{$ct}->{trb};
    my $num = sprintf "%3.3d", $trbnum;
    my $host= "trb" . $num;
    my $system = $map->{$ct}->{sys};
    #print "192.168.0.$ct   $host.gsi.de $host\n";
    #my $r = $p->ping($host,1);
    my $c= "ping -W1 -c2 $host";

    my $sysnum = sprintf "0x80%.2x", $ct;
    $sysnum = "0x7999" if $ct == -1;

    my $pid = $pm->start("$sysnum") and next;

    #my $p = Net::Ping->new("udp", 1);
    #my $r = $p->ping("192.168.0.56");
    #$p->close();
    #print "result: $r\n";

    my $r = qx($c);
    #printf "$sysnum, system: %-8s, trb: $host ", $system;
    printf "$sysnum  $host  %-8s ", $system;
    if (grep /64 bytes/, $r) {
      print "is alive.\n";
      $success = $trbnum;
    } else {
      print "is not alive.\n";
    }

    my $str = "jhhj";
    $pm->finish($success, \$host); # Terminates the child process
  }

  $pm->wait_all_children;

  #$rh_unsuccessful = { "0x8007"=>"hh", "0x8001"=>"jjhj"} ;

  if ($reboot && ($number_of_reboots_done < $maximal_reboot_counter) && keys %$rh_unsuccessful) {
    #print Dumper $rh_unsuccessful;
    print "have to reboot FPGAs, first make a reset and reassign the addresses.\n";
    my $cmd = "trbcmd reset;  ~/trbsoft/daqtools/merge_serial_address.pl ~/trbsoft/daqtools/base/serials_trb3.db ~/trbsoft/daqtools/users/gsi_dirc/addresses_trb3.db";
    qx($cmd);
    sleep 3;
    # test trbnet:
    my $error_str = "ERROR: read_uid failed: Termination Status Error";
    $cmd = "trbcmd i 0xffff 2>&1";
    my $r = qx($cmd);
    if ($r=~/$error_str/) {
      print "could not access trbnet, so have to reboot all FPGAs.\n";
      $rh_unsuccessful = { "0xffff"=>"all"} ;
    }

    if ($rh_unsuccessful->{"0x7999"} || (scalar keys %$rh_unsuccessful) > 5) {
      print "many TRBs (or 0x7999) are not alive, so let us make a reload of all FPGAs.\n";
      $rh_unsuccessful = { "0xffff"=>"all"} ;
    }

    foreach my $cur (keys %$rh_unsuccessful) {
      my $host = $rh_unsuccessful->{$cur};
      #my $cmd = "trbcmd reload " . $cur;
      $cmd = "trbcmd reload $cur";
      print "rebooting: $cur\n";
      #print "$cmd\n";
      qx($cmd);
      #print "number of reboots done: $number_of_reboots_done\n";
    }
    print "wait 9 seconds\n";
    sleep 9;
    $number_of_reboots_done++;
  }



}

exit 1 if(scalar keys %$rh_unsuccessful > 0);

#$p->close();


