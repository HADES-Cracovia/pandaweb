#!/usr/bin/perl

use warnings;
use strict;
use Data::Dumper;

my $sernr = $ARGV[0];

if(!$sernr) {
    print "usage: generate_serial_table.pl <serial number>\n";
    exit;

}

my %e;

my @r = qx(trbcmd i 0xffff);
#my @r = qx(~/trbsoft/trbnettools/libtrbnet/trbcmd i 0xffff);

foreach my $cur_line (@r) {

    my @s=split /\s+/, $cur_line; 
    #print Dumper \@s;
    my $o=sprintf("%x", 0xc000 + hex($s[2])); 
    if(hex($s[2]) == 5) {
	$o="8000";
    }

#    my $c="~/trbsoft/trbnettools/libtrbnet/trbcmd s $s[1] $s[2] 0x$o"; 
    my $c="trbcmd s $s[1] $s[2] 0x$o"; 
    #print $c . "\n"; 
    print qx($c); 
    $e{hex($s[2])} = "   " . $sernr . hex($s[2]) . "        $s[1]\n"; 

}


foreach $_ (sort {$a cmp $b} keys (%e)) { 
    print $e{$_}; 
}

print "\n";
