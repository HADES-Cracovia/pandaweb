#!/usr/bin/perl -w

use warnings;
use HADES::TrbNet;
use Dmon;
use Time::HiRes qq|usleep|;
use Data::Dumper;

trb_init_ports() or die trb_strerror();

my $act_ports;
my $to_ports;
my $er_ports;
my $number_of_dirich;
my $number_of_combiner;

sub read_regs {
  $act_ports = trb_register_read(0xfe52,0x84); #active ports
  $to_ports  = trb_register_read(0xfe52,0x8b); #ports with timeouts
  $er_ports  = trb_register_read(0xfe52,0xa4); #ports with errors on sctrl
}

sub count {
  my $dirich = trb_read_uid(0xfe51);
  my $combiner = trb_read_uid(0xfe52);
  $number_of_dirich = scalar keys %$dirich;
  $number_of_combiner = scalar keys %$combiner;

  printf("Combiners: %i\tDiRich: %i\n",$number_of_combiner, $number_of_dirich);
  }

count();

my $error = 0;
my $warning_error_count = 0;
my $max_warning_error_count = 6;

read_regs();


#turn all dirich on
trb_register_write(0xfe52,0xd580,0);

while (($error = trb_errno()) != 0 && ($warning_error_count < $max_warning_error_count) ) {
  print "error: $error\n";
  if ($error == 26) { # status warning
    my $error_str = trb_strerror();
    if ($error_str =~ /no endpoint has been reached/mg) {
      print "Warning: no endpoint has been reached. => reset\n";
      qx(trbcmd reset);
      sleep 1;
    }
  }
  read_regs();
  print "count after error:\n";
  count();
  $warning_error_count++;
}

my $expected_number_of_dirich = 9;
my $expected_number_of_combiner = 1;
my $mask;
#my $always_missing = (0x1<<7);
#my $always_missing = (0x1<<7) | (0x1 << 2);
my $always_missing = 0;

#determine_mask();

my $nr_of_ldo_cycle_retries = 0;
my $max_nr_of_ldo_cycle_retries = 20;
my $first_check_completed = 0;

while ( ($number_of_dirich < $expected_number_of_dirich || $first_check_completed==0 || $number_of_combiner < $expected_number_of_combiner)
        && $nr_of_ldo_cycle_retries < $max_nr_of_ldo_cycle_retries) {
  $first_check_completed = 1;
  $nr_of_ldo_cycle_retries++;
  print "ldo cycle counter: ", $nr_of_ldo_cycle_retries++ . "\n";
  foreach my $combs (keys %$act_ports) {
  #($combs) = keys %$act_ports;
  #while (1) {
    #not active or timeout or error
    my $active_ports  = ((~$act_ports->{$combs}) & 0x1ffe);
    my $timeout_ports = ($to_ports->{$combs}     & 0x1ffe);
    my $error_ports   = ($er_ports->{$combs}     & 0x1ffe);

    $active_ports  ^= $always_missing if($combs == 0x8301);

    $mask = ( $active_ports | $timeout_ports | $error_ports);
    #shift for LDO switch
    #$mask = 0x1 << 3;
    #$mask ^= $always_missing;
    printf("%04x\t%08x\t%08x\t%08x\t%08x\n",$combs, $active_ports, $timeout_ports, $error_ports, $mask);
    $mask <<= 15;
    next if $mask == 0;
    trb_register_setbit($combs,0xd580,$mask); #off
    #usleep(500000);
    qx(trbcmd reset);
    trb_register_clearbit($combs,0xd580,$mask); #on
    usleep(1000000);
    qx(trbcmd reset);
  }
  qx(trbcmd reset);

  count();
  read_regs();
  while (($error = trb_errno()) != 0 && $warning_error_count < $max_warning_error_count ) {
    print "error: $error\n";
    qx(trbcmd reset);
    read_regs();
  }

}

if ($number_of_dirich < $expected_number_of_dirich || $number_of_combiner < $expected_number_of_combiner) {
  print "Complete Power-Cycle needed!\n";
}
