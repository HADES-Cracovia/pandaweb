#!/usr/bin/perl

use warnings;
use strict;
use Parallel::ForkManager;
use Net::Ping;
use Getopt::Long;

my $power;
my $help;

my $result = GetOptions (
    "h|help"          => \$help,
    "p|powercycle"    => \$power,
    );


my @trbs = (56, 72, 99, 73, 74, 104, 97, 83, 89, 111, 13, 77, 57);

my $map = {
 0  =>  { trb =>  72, sys => "MCP 00" },
 1  =>  { trb =>  99, sys => "MCP 01" },
 2  =>  { trb =>  73, sys => "MCP 02" },
 3  =>  { trb =>  74, sys => "MCP 03" },
 4  =>  { trb => 104, sys => "MCP 04" },
 5  =>  { trb =>  97, sys => "TOF 1"  },
 6  =>  { trb =>  83, sys => "TOF 2"  },
 7  =>  { trb =>  89, sys => "HODO"   },
 8  =>  { trb => 111, sys => "FLASH"  },
 9  =>  { trb =>  13, sys => "DISC1"  },
 10 =>  { trb =>  77, sys => "DISC2"  },
 11 =>  { trb =>  57, sys => "AUX"    },
-1  =>  { trb =>  56, sys => "CTS"    },
};

my $MAX_PROCESSES=50;
my $pm = Parallel::ForkManager->new($MAX_PROCESSES);

$pm->run_on_finish(
    sub { my ($pid, $exit_code, $ident) = @_;
#	  print "** $ident just got out of the pool ".
#	      "with PID $pid and exit code: $exit_code\n";
    }
    );


#my $p = Net::Ping->new();

foreach my $ct (keys $map) {
    my $success = 0;
    #my $num = sprintf "%3.3d", $ct;
    my $trbnum= $map->{$ct}->{trb};
    my $num = sprintf "%3.3d", $trbnum;
    my $host= "trb" . $num;
    my $system = $map->{$ct}->{sys};
    #print "192.168.0.$ct   $host.gsi.de $host\n";
    #my $r = $p->ping($host,1);
    my $c= "ping -W1 -c1 $host";

    my $pid = $pm->start("$trbnum") and next;

    #my $p = Net::Ping->new("udp", 1);
    #my $r = $p->ping("192.168.0.56");
    #$p->close();
    #print "result: $r\n";

    my $r = qx($c);
    my $sysnum = sprintf "0x80%.2x", $ct;
    $sysnum = "0x7999" if $ct == -1;
    #printf "$sysnum, system: %-8s, trb: $host ", $system;
    printf "$sysnum  $host  %-8s ", $system;
    if (grep /64 bytes/, $r) {
	print "is alive.\n";
	$success = 1;
    }
    else {
	print "is not alive.\n";
   }

    my $str = "jhhj";
    $pm->finish($success, \$str); # Terminates the child process
}

$pm->wait_all_children;
#$p->close();



