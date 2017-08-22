#!/usr/bin/perl -w
use warnings;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use HADES::TrbNet;
use Date::Format;
use Dmon;


if (!defined $ENV{'DAQOPSERVER'}) {
  die "DAQOPSERVER not set in environment";
}

if (!defined &trb_init_ports()) {
  die("can not connect to trbnet-daemon on the $ENV{'DAQOPSERVER'}");
}


if (!(defined $ARGV[0]) || !(defined $ARGV[1]) || !(defined $ARGV[2])) {
  print "usage: dirich_threshold.pl \$FPGA \$chain \$command \$options

\t readreg \t Read content of an arbitrary register, options: \$address

";
  exit;
}
my $board, my $value, my $mask;

($board) = $ARGV[0] =~ /^0?x?(\w+)/;
$board = hex($board);

my $chain = hex($ARGV[1]);

sub sendcmd16 {
  my @cmd = @_;
  my $c = [@cmd,1<<$chain,16+0x80];
  #   print Dumper $c;
  trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});
  usleep(1000);
}

sub sendcmd {
  my ($cmd) = @_;
  return Dmon::PadiwaSendCmd($cmd,$board,$chain);
  #  my $c = [$cmd,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1<<$chain,1];
  #  trb_register_write_mem($board,0xd400,0,$c,scalar @{$c});
  #   trb_register_write($board,0xd410,1<<$chain) or die "trb_register_write: ", trb_strerror();   
  #   trb_register_write($board,0xd411,1);
  #  usleep(1000);
  #  return trb_register_read($board,0xd412);
}

sub flash_is_busy {
    sendcmd(0x50800000);
    my $b = sendcmd(0x40000000);
    return (($b->{$board} >> 15) & 0x1);
}

if ($ARGV[2] eq "readreg") {
  my $b = sendcmd(hex($ARGV[3])<<24);
  printf("0x%x\n", hex($ARGV[3])<<24);
  foreach my $e (sort keys %$b) {
    printf("0x%x\n", ($b->{$e}) & 0xffff);
  }
}

if ($ARGV[2] eq "writereg" && defined $ARGV[4]) {
    my $b = sendcmd(0x00800000+(hex($ARGV[3])<<24) + hex($ARGV[4]));
}

if ($ARGV[2] eq "dumpcfg") {
    for (my $p = 0; $p<5760; $p++) { #5758                                                                                               
	sendcmd(0x50800000 + $p);
	printf("0x%04x:\t",$p);
	for (my $i=0;$i<16;$i++) {
	    my $b = sendcmd(0x40000000 + ($i << 24));
	    foreach my $e (sort keys %$b) {
		printf(" %02x ",$b->{$e}&0xff);
	    }
	}
	printf("\n");
	printf(STDERR "\r%d / 5760",$p) if(!($p%10));
    }
}

if ($ARGV[2] eq "erasecfg") {
    while (flash_is_busy()) {
        printf(" busy - try again\n");
        usleep(300000);
    };
    sendcmd(0x5080E000);
    printf("Sent Erase command.\n");
}


if ($ARGV[2] eq "writecfg" && defined $ARGV[3]) {

    while (flash_is_busy()) {
        printf(" busy - try again\n");
        usleep(300000);
    };
    sendcmd(0x5080E000);
    printf("Sent Erase command.\n");

    open(INF,$ARGV[3]) or die "Couldn't read file : $!\n";
    while (flash_is_busy()) {
	printf(" busy - try again\n");
	usleep(300000);
    };
    my $p = 0;
    while (my $s = <INF>) {
	my @t = split(' ',$s);
	my @a;
	for (my $i=0;$i<16;$i++) {
	    if ($p eq 0x167e && $i eq 11) {
            # adds the magic 09 the last page of the config flash, 0x167e
		push(@a,0x40800000 + (0x09) + ($i << 24));
	    } else {
		push(@a,0x40800000 + (hex($t[$i+1]) & 0xff) + ($i << 24));
	    }
	}
	sendcmd16(@a);
	sendcmd(0x50804000 + $p);



	$p++;
	printf(STDERR "\r%d / 5760",$p) if(!($p%10));
    }

####### File is shorter....
    for (my $i=0;$i<16;$i++) {
	if ($i eq 11) {
            # adds the magic 09 the last page of the config flash, 0x167e                                                            
	    push(@a,0x40800000 + (0x09) + ($i << 24));
	} else {
	    push(@a,0x40800000 + (0x00) + ($i << 24));
	}
    }
    sendcmd16(@a);
    sendcmd(0x50804000 + 0x167e);
}

if ($ARGV[2] eq "writeflash" && defined $ARGV[3]) {

    sendcmd(0x5C800000); #cfg flash disabled
    while (flash_is_busy()) {
        printf(" busy - try again\n");
        usleep(300000);
    };
    sendcmd(0x5080FC00);
    printf("Sent Erase command.\n");

    open(INF,$ARGV[3]) or die "Couldn't read file : $!\n";
    while (flash_is_busy()) {
        printf(" busy - try again\n");
        usleep(300000);
    };
    my $p = 0x1C00;
    while (my $s = <INF>) {
        my @t = split(' ',$s);
        my @a;
        for (my $i=0;$i<16;$i++) {
	    push(@a,0x40800000 + (hex($t[$i+1]) & 0xff) + ($i << 24));
        }
        sendcmd16(@a);
        sendcmd(0x50804000 + $p);

        $p++;
    }
}

if ($ARGV[2] eq "dumpflash") {
    for (my $p = 0x1c00; $p < 0x1c10; $p++) {                                                                                                                                  
        sendcmd(0x50800000 + $p);
        printf("0x%04x:\t",$p);
        for (my $i=0;$i<16;$i++) {
            my $b = sendcmd(0x40000000 + ($i << 24));
            foreach my $e (sort keys %$b) {
                printf(" %02x ",$b->{$e}&0xff);
            }
        }
        printf("\n");
        ##printf(STDERR "\r%d / 5760",$p) if(!($p%10));
    }
}
