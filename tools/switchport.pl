#!/usr/bin/perl

#Used to switch off or on a given port of a hub within Trbnet

$address = $ARGV[0];
$portnum = $ARGV[1];
$onoff   = $ARGV[2];
$chan    = defined($ARGV[3])?$ARGV[3]:"all";

if (!defined($address) || !$address  || !defined($portnum) || $address =~ /help/) {
	print "Usage: switchport.pl \$hubaddress \$port [on|off] (\$channel)\n";
}

if($portnum eq "all" && $onoff eq "on") {
	$port = 0xfffffff;
	}
else {
	$port = 1<<$portnum;
	}
	
sub ex{
	my ($cmd) = @_;
	my $err = 0;
	$cmd .= " 2>&1";
	my @out = qx($cmd);
	foreach my $s (@out) {
		print "$s";
		if($s =~ /ERROR/) {
			$err = 1;
			}
		}
	if ($err) {
		print "\n=========================================================\nSomething seems to be wrong. Ctrl-C might be a good choice.";
		getc();
		}
	}


if($onoff eq "on") {
  print("\t\tEnable port $portnum on hub $address channel $chan...\n");
  ex("trbcmd setbit $address 0xc0 $port") if ($chan == 0 || $chan eq "all");
  ex("trbcmd setbit $address 0xc1 $port") if ($chan == 1 || $chan eq "all");
  ex("trbcmd setbit $address 0xc3 $port") if ($chan == 3 || $chan eq "all");
  }
  
if($onoff eq "off") {
	print("\t\tDisable port $portnum on hub $address channel $chan...\n");
  ex("trbcmd clearbit $address 0xc0 $port") if ($chan == 0 || $chan eq "all");
  ex("trbcmd clearbit $address 0xc1 $port") if ($chan == 1 || $chan eq "all");
  ex("trbcmd clearbit $address 0xc3 $port") if ($chan == 3 || $chan eq "all");
  }
  
