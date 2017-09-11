#!/usr/bin/perl -w
use warnings;
use FileHandle;
use Time::HiRes qw( usleep );
use Data::Dumper;
use Date::Format;
use Getopt::Long;
use Fcntl;
use Device::SerialPort;

my $fh;

if (!(defined $ARGV[0]) || !(defined $ARGV[1]) ) {
  print "usage: logicbox.pl \$device \$command \$options

\t readreg \t Read content of an arbitrary register, options: \$address
\t writereg \t Write content to a register options: \$address \$data
\t dumpcfg \t Dump content of configuration flash. Pipe output to file
\t writecfg \t Write content of configuration flash. options: \$filename
\t dumpflash \t Dump content of user flash. Pipe output to file
\t writeflash \t Write content of user flash. options: \$filename 

";
  exit;
}

my $port = new Device::SerialPort($ARGV[0]); 
$port->user_msg(ON); 
$port->baudrate(115200); 
$port->parity("none"); 
$port->databits(8); 
$port->stopbits(1); 
$port->handshake("none");
$port->datatype('raw');  
$port->write_settings;
$port->read_const_time(100);

#    my $burst = $_[1];

sub get {
    my $c = $_[0];
    
    $c = sprintf "R%02x" , $c;
    #printf("Send %s \n", $c);
    $port->lookclear; 
    $port->write($c);

    my ($count, $saw) = $port->read(11); 

    if ($count > 0) {
        #printf("Got %s \n", $saw);
        if ($saw =~ /R([A-Fa-f0-9]{8})/) {return hex($1);}
        return $saw;
    } else {
        printf("Timeout \n");
        return 0;
    }
}

sub get2 {
    my ($count, $saw) = $port->read(11);

    if ($count > 0) {
        #printf("Got %s \n", $saw);                                                                                                    
        if ($saw =~ /R([A-Fa-f0-9]{8})/) {return hex($1);}
        return $saw;
    } else {
        printf("Timeout \n");
        return 0;
    }
}


sub set {
    my $c = $_[1];
    my $addr = $_[0];
    #printf("Send %s \n", $c);
    $c = sprintf "W%02x%08x" , ($addr), ($c);
    #printf("Send %s \n", $c);
    $port->lookclear;
    $port->write($c);
}


if ($ARGV[1] eq "readreg") {
    my $b = get(hex($ARGV[2]));
    
    printf("0x%s = 0x%x\n", $ARGV[2], $b);
}

if ($ARGV[1] eq "writereg" && defined $ARGV[3]) {
    set(hex($ARGV[2]), hex($ARGV[3]));
}

sub flash_is_busy {
    my $b = get(0x5c);
    return (($b >> 2) & 0x1);
}

if ($ARGV[1] eq "dumpcfg") {
    for (my $p = 0; $p<0x0c80; $p++) { #3190  
        set(0x50, $p);
	set(0x5d, 0x313);
        while (flash_is_busy()) {
            printf(" busy - try again\n");
            usleep(300000);
        };

        printf("0x%04x:\t", $p);
#        for (my $i=0; $i<16; $i++) {
#            my $b = get(0x40 + $i);
#            printf(" %02x ", $b);
#        }
	my $b = get(0x40);
	printf(" %02x  %02x  %02x  %02x ", ($b>>24)&0xff, ($b>>16)&0xff, ($b>>8)&0xff, $b&0xff);
	for (my $i=0; $i<3; $i++) {
	    $b = get2();
	    printf(" %02x  %02x  %02x  %02x ", ($b>>24)&0xff, ($b>>16)&0xff, ($b>>8)&0xff, $b&0xff);
	}
        printf("\n");
        printf(STDERR "\r%d / 3190",$p) if(!($p%10));
    }
}

if ($ARGV[1] eq "writecfg" && defined $ARGV[2]) {

    set(0x5c, 0x1); #cfg flash enabled
    set(0x5d, 0x0);
    while (flash_is_busy()) {
        printf(" busy - try again\n");
        usleep(300000);
    };
    set(0x50, 0xE000);
    printf("Sent Erase command.\n");

    open(INF, $ARGV[2]) or die "Couldn't read file : $!\n";
    while (flash_is_busy()) {
        printf(" busy - try again\n");
        usleep(300000);
    };
    my $p = 0;
    while (my $s = <INF>) {
        my @t = split(' ',$s);
       
        for (my $i=0;$i<16;$i++) {
            if ($p eq 0x0c7e && $i eq 11) {
            # adds the magic 09 the last page of the config flash, 0x0c7e
                set(0x40+$i, 0x09);
            } else {
                set(0x40+$i, (hex($t[$i+1]) & 0xff));
            }
        }

        set(0x50, 0x4000 + $p);
        while (flash_is_busy()) {
            #printf(" busy - try again\n");
            usleep(30000);
        };

        $p++;
        printf(STDERR "\r%d / 3198",$p) if(!($p%10));
    }

####### File is shorter....
    for (my $i=0;$i<16;$i++) {
        if ($i eq 11) {
            set(0x40+$i, 0x09);
        } else {
            set(0x40+$i, 0x00);
        }
    }
    set(0x50, 0x4000 + 0x0c7e);
}


if ($ARGV[1] eq "writeflash" && defined $ARGV[2]) {

    set(0x5C, 0x0); #cfg flash disabled
    while (flash_is_busy()) {
        printf(" busy - try again\n");
        usleep(300000);
    };
    set(0x50, 0xFC00);
    printf("Sent Erase command.\n");

    open(INF,$ARGV[2]) or die "Couldn't read file : $!\n";
    while (flash_is_busy()) {
        printf(" busy - try again\n");
        usleep(300000);
    };
    my $p = 0x1C00;
    while (my $s = <INF>) {
        my @t = split(' ',$s);
        my @a;
        for (my $i=0;$i<16;$i++) {
            set(0x40+$i, (hex($t[$i+1]) & 0xff));
            
        }
        set(0x50, 0x4000 + $p);
        while (flash_is_busy()) {
            #printf(" busy - try again\n");                                                                                             usleep(30000);
        };
        
        $p++;
    }
}


if ($ARGV[1] eq "dumpflash") {
    set(0x5d, 0x0);
    for (my $p = 0x1c00; $p < 0x1c10; $p++) {
        set(0x50, $p);
        printf("0x%04x:\t",$p);
        for (my $i=0; $i<16; $i++) {
            my $b = get(0x40 + $i);
            printf(" %02x ", $b);
        }
        printf("\n");
        ##printf(STDERR "\r%d / 5760",$p) if(!($p%10));
    }
}
