#!/usr/bin/perl

use warnings;
use strict;

use Data::Dumper;
use HADES::TrbNet;

my $fn1 = $ARGV[0];
my $fn2 = $ARGV[1];

&usage if (!$fn1 || !$fn2);

# check input

open my $fh1, "<", $fn1 or die "could not open $fn1: $!";
open my $fh2, "<", $fn2 or die "could not open $fn2, $!";


trb_init_ports() or die trb_strerror();

my %trb;
foreach my $cur_ln (<$fh1>) {
    next if($cur_ln =~ /^\s*#/ or $cur_ln =~ /^\s*$/);
    (my $serial_nr, my $uid) = $cur_ln =~ /(\d+)\s+(\w+)/;
    next if (!defined $serial_nr);
    $serial_nr = int($serial_nr);
    $trb{$serial_nr}->{'uid'} = $uid;
}

#print Dumper \%trb;

foreach my $cur_ln (<$fh2>) {
    next if($cur_ln =~ /^\s*#/ or $cur_ln =~ /^\s*$/);
    (my $address, my $sernr1, my $sernr2) = $cur_ln =~ /(\w+)\s+(\d+)\s+(\d+)/;
    my $serial_nr = $sernr1*10 + $sernr2;
    next if (!defined $serial_nr);
    $trb{$serial_nr}->{'address'} = hex($address);
    $trb{$serial_nr}->{'endpoint_nr'} = $sernr2;
    $trb{$serial_nr}->{'uid'} = $trb{int($sernr1)}->{'uid'} unless $trb{$serial_nr}->{'uid'};  #compat. to old db files
}


#print Dumper \%trb;


foreach my $serial_nr (keys %trb) {
    next if(!$trb{$serial_nr}->{'address'} || !defined $trb{$serial_nr}->{'uid'});
    #printf "0x%4.4x  ", $trb{$serial_nr}->{'address'};
    #print $trb{$serial_nr}->{'uid'} . "  ";
    #printf "0x%2.2x\n", $trb{$serial_nr}->{'endpoint_nr'};

    no warnings 'portable';
    my $uid = hex($trb{$serial_nr}->{'uid'});
    use warnings 'portable';

    my $ref = trb_set_address($uid, $trb{$serial_nr}->{'endpoint_nr'} , $trb{$serial_nr}->{'address'});

}


exit;

sub usage {
    print <<EOF;
usage:
merge_serial_address.pl <serials.db> <address.db>

EOF

exit;
}
