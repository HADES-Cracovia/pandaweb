#!/usr/bin/perl -w

use English;
use strict;
use Getopt::Long;
use Data::Dumper;
use IO::Socket;

#- the command line option flags
my $opt_help    = 0;
my $opt_etrax;
my $opt_port    = 4712;
my $opt_command;
my $opt_inter   = 0;

GetOptions ('h|help'      => \$opt_help,
	    'e|etrax=s'   => \$opt_etrax,
	    'p|port=i'    => \$opt_port,
	    'c|command=s' => \$opt_command,
	    'i|inter'     => \$opt_inter);


if( $opt_help ) {
    &help();
    exit(0);
}

if( &checkArgs() ){
    print "Exit.\n";
    exit(1);
}

my $cmd_server_prtcl  = 'tcp';
my $cmd_server_answer = "";

&connectCmdServer();

exit(0);

################### END OF MAIN ####################

sub help()
{
    print "\n";
    print << 'EOF';
startup.pl    

   This script executes the command via Command_Server running
   on etrax boards.

Usage:
   
   Command line:  command_client.pl 
   [-h|--help]             : Show this help.
   [-e|--etrax <name>]     : Etrax board name.
   [-c|--command <'cmd'>]  : Command to execute. 
   [-p|--port <port>]      : Port to connect to a server (default: 4712).
   [-i|--inter]            : Interactive execution of the commands.

Examples:

   Execute command 'sleep 10' on etraxp086:
      command_client.pl -c 'sleep 10' -e etraxp086

   Execute commands on etraxp086 interactively:
      command_client.pl -i -e etraxp086

EOF
}

sub checkArgs()
{
    my $retVal = 0;

    unless( $opt_inter || defined $opt_command ){
	print "You should use either '-c' or '-i' options\n";
	$retVal = 1;
    }

    if( $opt_inter && defined $opt_command ){
	print "You should use either '-c' or '-i' options\n";
	$retVal = 1;
    }

    unless( defined $opt_etrax ){
	print "You must use '-e' option\n";
	$retVal = 1;
    }
    
    return $retVal;
}

sub getAnswerFromServer()
{
    my ($socket) = @_;

    while( <$socket> ){ 
	print $_;
	
	if( $_ =~ /- END OF OUTPUT -/ ){
	    last;
	}
    }
}

sub connectCmdServer()
{
    my $answer;

    my $socket = IO::Socket::INET->new(PeerAddr => $opt_etrax,
				       PeerPort => $opt_port,
				       Proto    => $cmd_server_prtcl,
				       Type     => SOCK_STREAM)
     or $answer = "ERROR: No response from Cmd Server at $opt_etrax:$opt_port\n";

    unless( defined $answer ){
	$socket->autoflush(1);
	print $socket "iamfromhadesdaq\n";
	$answer = <$socket>;

	print $answer;

	if($opt_inter){
	    #- Interactive commands from keyboard
	    while(1){
		print "Enter command:  ";
		my $cmd = <STDIN>;
		print $socket "$cmd";
		&getAnswerFromServer($socket);
	    }
	}
	elsif( defined $opt_command ){
	    #- Command from the argumant
	    print $socket "$opt_command\n";
	    &getAnswerFromServer($socket);
	}

	close($socket);
    }

    unless( $answer =~ /Connection accepted/ ){
	print $answer;
    }
}
