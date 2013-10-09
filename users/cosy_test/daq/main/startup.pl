#!/usr/bin/perl -w

use English;
use strict;
use Getopt::Long;
use FileHandle;
use File::Path;
use File::Basename;
use Data::Dumper;
use Time::HiRes;

use IO::Socket;
use Net::Ping;

use Config::Std;
use Carp qw( croak );
use Scalar::Util qw(reftype);
use List::Util;
use List::MoreUtils qw(any apply);

use IO::Socket;
use IO::Select;

use threads;
use threads::shared;

#use Clone qw(clone);

#- the command line option flags
my $opt_help    = 0;
my $opt_eb      = "on";
my $opt_check   = 1;
my $opt_rdo     = 0;
my $opt_test    = 0;
my $opt_file    = "../main/startup.script";
my $opt_etrax   = "etraxp022";
my $opt_verb    = 0;
my $opt_ora     = "file";
my @opt_macro;
my @dead_cservers;

GetOptions ('h|help'      => \$opt_help,
            'b|eb=s'      => \$opt_eb,
            'c|check=i'      => \$opt_check,
            'r|rdo'       => \$opt_rdo,
            'f|file=s'    => \$opt_file,
            'e|etrax=s'   => \$opt_etrax,
            'm|macro=s'   => \@opt_macro,
            'v|verb'      => \$opt_verb,
            'o|oracle=s'  => \$opt_ora,
             't|test'      => \$opt_test);

if( $opt_help ) {
    &help();
    exit(0);
}

my $parent_pid = $$;

my @subsys_array = ('mdc','rich','rpc','start','tof','wall','hub');

my $expect_script     = "/tmp/remote_exec.exp";
my $var_dir           = "/var/diskless/etrax_fs";
my $log_dir           = "/tmp/log";

my $cmd_server        = "./bin/command_server"; 
my $cmd_server_port   = 4712;
my $cmd_server_prtcl  = 'tcp';
my $cmd_server_answer = "";

my %addr_db_conf;                # Hash with all addresses, serials, uids from DBs 
my $addr_db_conf_href = \%addr_db_conf;
my @startup;                     # Array with all startup configuration
my $startup_aref = \@startup;
my %trb_hash;                    # Hash with TRBs for different subsystems
my $trb_href = \%trb_hash;
my %EB_Args;                     # Hash with EB args
my $EB_Args_href = \%EB_Args;
my @rdo;                         # Array with etrax names which run readout
my $rdo_aref = \@rdo;

my @usedMacros = ();             # Array of used macro names to identify names with typos

my %data2ora_hash;               # Hash with data to be stored in Oracle
my $data2ora_href = \%data2ora_hash;

my @subEvtIds;                   # Array with subevent Ids
my $subEvtIds_aref = \@subEvtIds;             

my %addressRange;                # Hash with ranges of TRBNet addresses for each type of board
my $addressRange_href = \%addressRange;

if( 0 != &checkArgs() ){
    print "Exit.\n";
    exit(1);
}

#- Get local time in seconds since Epoch
my $seconds1 = time;

my $child_pid = &forkStatusServer();

&prepareForStartup();   #0.05s
&cleanup();             #0.02s
&readScript($opt_file, 'local');	#1.3s
&checkUnusedMacros();   #0s

#print Dumper $startup_aref;
#print Dumper $trb_href;
#print Dumper $addr_db_conf_href->{'0x3230_3'};
&checkConnection() if($opt_check);     #2.6s

&closeEBs() if($opt_eb eq "on");
&execViaCmdServer();
&startEBs() if($opt_eb eq "on");

exit(0);

################### END OF MAIN ####################

sub help()
{
    print "\n";
    print << 'EOF';
startup.pl    

   This script starts readout via Command_Server running
   on etrax boards. The script also starts Event Builder
   to collect the data.

Usage:
   
   Command line:  startup.pl 
   [-h|--help]             : Show this help.
   [-f|--file <path/name>] : Path to main config file.
   [-b|--eb <on>|<off>]    : Automatic restart of EBs (default: on).
   [-r|--rdo]              : Start readout.
   [-e|--etrax <name>]     : Etrax name.
   [-m|--macro <name>]     : Macro names for preprocessing startup.script files.
                             Only !ifdef, !ifndef, !endif directives are defined.
                             !ifdef    - by default exclude following cmds,
                             !ifndef   - by default include following cmds.
   [-o|--oracle <null|
                 file>]    : Write ascii files with info for Oracle (default: file).
   [-t|--test]             : Test without execution.
   [-v|--verb]             : Verbose.

Examples:

   Start MDC script with macros CALIB and INIT:
      startup.pl -f ../mdc/startup.script -m CALIB -m INIT

EOF
}

sub checkArgs()
{
    my $retval = 0;

    if($opt_rdo){
        print "Option -r is not implemented yet.\n";
        $retval = 1;
    }
    if( ! (-e $opt_file) ){
        print "File $opt_file does not exist.\n";
        $retval = 1;
    }
    
    return $retval;
}

sub prepareForStartup()
{

    my $var_log_dir = $var_dir . "/tmp/log";
    &makeDir($var_log_dir);

    my $mode_dir = $log_dir . "/mode";
    &makeDir($mode_dir);

    #- Write expect script
    &writeExpect();
}

sub makeDir()
{
    my ($dir) = @_;

    #- Make all needed dirs/subdirs
    my @log_dir_list = split('/', $dir);

    my $dir2mk = "";
    foreach my $subdir (@log_dir_list){
        next unless( $subdir );

        $dir2mk =  $dir2mk . "/" . $subdir;
        mkdir($dir2mk) or die $! unless( -d $dir2mk);
    }
}

sub cleanup()
{
    system("rm $log_dir/log*.txt 2>/dev/null 2>/dev/null") unless($opt_test);
    system("rm $log_dir/board_ids_for_oracle*.txt 2>/dev/null 2>/dev/null") unless($opt_test);
    system("rm $log_dir/mode/* 2>/dev/null 2>/dev/null") unless($opt_test);
}

sub writeExpect()
{
    # If command_server is not started on Etrax at boot time
    # this expect script can be executed to start command_server.

    #! Look if /tmp dir exists
    my $tmp_dir = dirname("/tmp");
    if ( !(-d $tmp_dir) ){
        print "\nCannot access /tmp directory!\nExit.\n";
        exit(1);
    }

    my $expect_script_my = <<EOF;
#!/usr/bin/expect -f

# This script is automatically generated by startup.pl
# Do not edit, the changes will be lost.

# Print args
send_user "\$argv0 [lrange \$argv 0 \$argc]\\n"

# Get args
#
# host : etrax name
# path : path to executable
# bin  : executable name
# opt  : args for executable
#
if {\$argc>0} {
  set host [lindex \$argv 0]
  set path [lindex \$argv 1]
  set bin  [lindex \$argv 2]
  set opt  [lindex \$argv 3]
} else {
  send_user "Usage: \$argv0 host path binary options\\n"
}

spawn telnet \$host
expect {
        "error"     { exit; }
        "login:"    { send "root\\r"; exp_continue; }
        "Password:" { send "pass\\r" }
}

set timeout 240

expect "# "
send   "killall -9 \$bin\\r"
expect "# "
send   "cd /home/hadaq/\\r"
expect "# "
send   "\$path\$bin \$opt\\r"
expect "# "
    
EOF

    my $fh = new FileHandle(">$expect_script");

    if(!$fh) {
        my $txt = "\nError! Could not open file \"$expect_script\" for output. Exit.\n";
        print STDERR $txt;
        print $txt;
        exit(128);
    }

    print $fh $expect_script_my;
    $fh->close();    

    #- open permissions
    system("chmod 755 $expect_script") unless($opt_test);
}

sub getSubsysName()
{
    my ($script) = @_;

    my $subsys;

    if( $script =~ /..\/(\w+)\/(\w+).script/ ){
        $subsys = $1;

        die "getSubsysName(): Undefined subsystem: \'$script\'! Exit.\n" unless( defined $subsys ); 
    }
    else{
        $subsys = 'main';
    }

    return $subsys;
}

sub preprocess()
{
    my ($preproc, $line) = @_;

    my ($directive, $macro) = split(" ", $line);

    &preprocessCheck( $preproc, $directive );

    if(    $directive eq "!ifdef"  and (any {lc($_) eq lc($macro)} @opt_macro) ){
        $preproc->{'ifdef'}     = 'on';
        $preproc->{'skeepLine'} = 0;

        #- Save found macro names
        push(@usedMacros, $macro) unless(any {lc($_) eq lc($macro)} @usedMacros);

        return 1;
    }
    elsif( $directive eq "!ifdef" ){
        #- No ifdef macros defined in cmd line => skeep next lines
        $preproc->{'ifdef'}     = 'on';
        $preproc->{'skeepLine'} = 1;

        return 1;
    }
    elsif( $directive eq "!ifndef"  && (any {lc($_) eq lc($macro)} @opt_macro) ){
        $preproc->{'ifndef'}    = 'on';
        $preproc->{'skeepLine'} = 1;

        #- Save found macro names
        push(@usedMacros, $macro) unless(any {lc($_) eq lc($macro)} @usedMacros);

        return 1;
    }
    elsif( $directive eq "!ifndef" ){
        #- No ifndef macros defined in cmd line => include next lines
        $preproc->{'ifndef'}    = 'on';
        $preproc->{'skeepLine'} = 0;

        return 1;
    }
    elsif( $directive eq "!endif" ){
        $preproc->{'ifndef'}    = 'off';
        $preproc->{'ifdef'}     = 'off';
        $preproc->{'skeepLine'} = 0;

        return 1;
    }

    return $preproc->{'skeepLine'};
}

sub checkUnusedMacros()
{
    my @unusedMacros = ();
    my $foundUnused = 0;

    foreach my $macro (@opt_macro){
        unless((any {lc($_) eq lc($macro)} @usedMacros)){
            push(@unusedMacros, $macro);
            $foundUnused = 1;
        }
    }

    if($foundUnused){
        print "\nUnused macro names:";
        
        foreach my $macro (@unusedMacros){
            print " $macro";
        }
        
        print "\n";

        &askUser();
    }
}

sub preprocessInit()
{
    my %preproc = (
                   'ifdef'     => 'off',
                   'ifndef'    => 'off',
                   'skeepLine' => 0
                   );

    return \%preproc;
}

sub preprocessCheck()
{
    my ($preproc, $directive) = @_;

    if( $directive eq "!ifdef" || $directive eq "!ifndef" ){
        unless( ($preproc->{'ifdef'}  eq 'off') && 
                ($preproc->{'ifndef'} eq 'off') ){
            print "Encapsulated \'ifdef\'/\'ifndef\' are not supported. Each \'ifdef\'/\'ifndef\' must be closed with \'endif\' before next \'ifdef\'/\'ifndef\' can be opened.\n";
            exit(1);
        }
    }
    elsif( $directive eq "!endif" ){
        if( ($preproc->{'ifdef'}  eq 'on'  && $preproc->{'ifndef'} eq 'on') ||
            ($preproc->{'ifdef'}  eq 'off' && $preproc->{'ifndef'} eq 'off') ){
            print "The sequence of directives looks fishy. Each \'ifdef\'/\'ifndef\' must be closed with \'endif\' before next \'ifdef\'/\'ifndef\' can be opened.\n";
            exit(1);
        }
    }
    elsif( $directive =~ /!(\w+)/ ){
        print "Unknown directive $directive. Exit.\n";
        exit(1);
    }
}

sub readTRBSetup()
{
    my ($trb_db) = @_;

    my $fh = new FileHandle("$trb_db", "r");

    &isItDefined($fh, $trb_db);

    #- Init preprocessor hash
    my $preproc = &preprocessInit();

    my $SPACE = "";

    while(<$fh>){
        
        #- Remove all comments
        $_ =~ s{                # Substitue...
                 \#             # ...a literal octothorpe
                 [^\n]*         # ...followed by any number of non-newlines
               }
               {$SPACE}gxms;    # Raplace it with a single space

        #- Skip line if it contains only whitespaces
        next unless(/\S/);

        #- Check for preprocessor directives
        next if( &preprocess($preproc, $_) );

        #- Extract command and parameters
        my ($sys, $etrax, $rdo) = split(" ", $_);

        unless( defined $etrax ){
            print "Etrax is not defined in $trb_db for $sys! Exit\n";
            $fh->close;
            exit(1);
        }

        #- Add to a main configuration hash
        push( @{$trb_href->{$sys}}, $etrax );

        #- Add to a readout array for EB
        if( defined $rdo && $rdo =~ /rdo/ ){
            push( @$rdo_aref, $etrax );
        }
    }
    
    $fh->close;
}

sub readAddressRangeSetup()
{
    my ($addressRange_db) = @_;

    my $fh = new FileHandle("$addressRange_db", "r");

    &isItDefined($fh, $addressRange_db);

    #- Init preprocessor hash
    my $preproc = &preprocessInit();

    my $SPACE = "";

    while(<$fh>){
        
        #- Remove all comments
        $_ =~ s{                # Substitue...
                 \#             # ...a literal octothorpe
                 [^\n]*         # ...followed by any number of non-newlines
               }
               {$SPACE}gxms;    # Raplace it with a single space

        #- Skip line if it contains only whitespaces
        next unless(/\S/);

        #- Check for preprocessor directives
        next if( &preprocess($preproc, $_) );

        #- Extract command and parameters
        my ($sys, $min, $max, $type) = split(" ", $_);

        $min =~ s{                # Substitue...
                 0x               # ...hex zero
                 }{}gxms;       # ...with nothing

        $max =~ s{                # Substitue...
                 0x               # ...hex zero
                 }{}gxms;       # ...with nothing        


        unless( defined $sys && defined $min &&
                defined $max && defined $type){
            print "Something wrong with a format of $addressRange_db! Exit.\n";
            $fh->close;
            exit(1);
        }

        $addressRange_href->{$sys}->{'MIN'}  = $min;
        $addressRange_href->{$sys}->{'MAX'}  = $max;
        $addressRange_href->{$sys}->{'TYPE'} = $type;
    }
    
    $fh->close;    
}

sub readSubevtIdsSetup()
{
    my ($subevt_db) = @_;

    my $fh = new FileHandle("$subevt_db", "r");

    &isItDefined($fh, $subevt_db);

    #- Init preprocessor hash
    my $preproc = &preprocessInit();

    my $SPACE = "";

    while(<$fh>){
        
        #- Remove all comments
        $_ =~ s{                # Substitue...
                 \#             # ...a literal octothorpe
                 [^\n]*         # ...followed by any number of non-newlines
               }
               {$SPACE}gxms;    # Raplace it with a single space

        #- Skip line if it contains only whitespaces
        next unless(/\S/);

        #- Check for preprocessor directives
        next if( &preprocess($preproc, $_) );

        #- Extract command and parameters
        my $subevt;

        if( $_ =~ /0x(\w+)/ ){
            $subevt = $1;
        }
        else{
            print "Something wrong with a format of $subevt_db! Exit\n";
            $fh->close;
            exit(1);
        }

        #- Add to a config array
        push( @$subEvtIds_aref, $subevt );
    }
    
    $fh->close;
}

sub readScript()
{
    my ($script, $exec_sys) = @_;

    #- Extract subsystem name
    my $subsys = &getSubsysName($script);
    #print "script: $script, subsys: $subsys\n";

    my $fh = new FileHandle("$script", "r");
    &isItDefined($fh, $script);

    #- Init preprocessor hash
    my $preproc = &preprocessInit();

    my $SPACE = "";

    while(<$fh>){
        
        #- Remove all comments
        $_ =~ s{                # Substitue...
                 \#             # ...a literal octothorpe
                 [^\n]*         # ...followed by any number of non-newlines
               }
               {$SPACE}gxms;    # Raplace it with a single space

        #- Skip line if it contains only whitespaces
        next unless(/\S/);

        #- Check for preprocessor directives
        next if( &preprocess($preproc, $_) );

        #- Extract command and parameters
        my ($cmd, @param) = split(" ", $_);

        &add2startup( $subsys, $exec_sys, $cmd, \@param );
    }
    
    $fh->close;
}

sub add2startup(){

    my ($subsys, $exec_sys, $cmd, $aref) = @_;

    die "add2startup(): one or more arguments are not defined! Exit.\n"
        unless( defined $subsys && defined $exec_sys && defined $cmd && defined $aref);
    
    if(    $cmd =~ /exec_script{(\w+)}/ ){
        my $exec_sys = $1;

        #- exec_script is followed only by one parameter [0]: script name
        &readScript( $aref->[0], $exec_sys );
    }
    elsif( $cmd =~ /exec_cmd{(\w+)}/){
        my $exec_sys = $1;

        my $args = &getArgs4cmd($aref, $subsys);
        &push2array( \@startup, $exec_sys, $args );
    }
    elsif( $cmd eq 'exec_cmd'){
        
        my $args = &getArgs4cmd($aref, $subsys);

        &push2array( \@startup, $exec_sys, $args );
    }
    elsif( $cmd eq 'wait'){

        #- At this point we will wait for the forked children
        push( @startup, {$cmd => ['-']} );
    }
    elsif( $cmd eq 'trbcmd'){
        my $args = &getArgs4cmd($aref, $subsys);
        my $cmd_line = "$cmd $args";
        
        &push2array( \@startup, $exec_sys, $cmd_line );
    }
    elsif( $cmd eq 'set_addresses' ){
        my $serials     = $aref->[0];
        my $addresses   = $aref->[1];
        
        my $conf = $subsys . "-" . $cmd . "-" . $serials . ".conf";
        my $args = &makeAddressesConf( $subsys, $serials, $addresses, $conf );
        my $bash_script = "trbdhcp -f $args";

        &push2array( \@startup, $exec_sys, $bash_script );
    }
    elsif( $cmd eq 'load_register' ){
        my $register     = $aref->[0];
        
        my $conf = $subsys . "-" . $cmd . "-" . $register . ".conf";
        my $args = &makeRegisterConf( $subsys, $register, $conf );
        my $bash_script = "trbcmd -f $args";
        
        &push2array( \@startup, $exec_sys, $bash_script );
    }
    elsif( $cmd eq 'daqop' ){
        my $args = &getArgs4cmd($aref, $subsys);
        my $bash_script = "$cmd $args";
        
        &push2array( \@startup, $exec_sys, $bash_script );
    }
    elsif( $cmd eq 'read_trb_db' ){
        #- Read database file with TRB setup
        my $trb_db = $aref->[0];

        &readTRBSetup( $trb_db );
    }
    elsif( $cmd eq 'read_addrange_db' ){
        #- Read database file with TRBNet address ranges
        my $addrRanges_db = $aref->[0];
        
        &readAddressRangeSetup($addrRanges_db);
    }    
    elsif( $cmd eq 'read_subevtids_db' ){
        #- Read database file with subevent Ids
        my $subevt_db = $aref->[0];

        &readSubevtIdsSetup( $subevt_db );
    }
    elsif( $cmd eq 'read_eb_conf' ){
        #- Read config file with EB settings
        my $eb_conf = $aref->[0];

        read_config $eb_conf => %$EB_Args_href;
    }
    else{
        die "add2startup(): do not know what to do with command \'$cmd\' for subsystem \'$subsys\'! Exit.\n";
    }
}

sub checkScript()
{
}

sub getArgs4cmd()
{
    my ($aref, $subsys) = @_;

    my $args = "";

    if( $aref->[0] eq '-f' && defined $subsys ){
        my $conf = $aref->[1];
        system("cp ../$subsys/$conf $var_dir/tmp/.") unless($opt_test);
        $args = "-f /home/hadaq/tmp/" . $conf;  
    }
    else{
        for( my $i=0; $i < scalar (@{$aref}); $i++){
            $args = $args . " " . $aref->[$i];
        }
    }

    return $args;
}

sub isItDefined()
{
    my ($fh, $name) = @_;

   if(!$fh) {
        my $txt = "\nError! Could not open file \'$name\'. Exit.\n";
        print STDERR $txt;
        print $txt;
        exit(128);
    }

    return 0;
}

sub isVarDefined()
{
    my ($var, $name) = @_;

    unless( defined $var ){
        print "$name is not defined! Exit.\n";
        exit(1);
    }
}

sub push2array()
{
    my ($aref, $exec_sys, $cmd) = @_;

    if( defined $aref->[-1] && defined $aref->[-1]->{$exec_sys} ){
        #- If last exec_sys equals current exec_sys
        #- push current cmd to the same exec_sys
        push( @{$aref->[-1]->{$exec_sys}}, $cmd );
    }
    else{
        #- Unless create new entry in the main array
        push( @$aref, {$exec_sys => [$cmd]} );
    }
}

sub execViaCmdServer()
{
    my (@process_list);

    my $i = 1;

    #- Loop over subsystems
    foreach my $href ( @$startup_aref ){        
# 				print Time::HiRes::time()."\n" ;

        my ($exec_sys, $cmd_aref) = each ( %$href );

        if($exec_sys eq 'con') {
					foreach my $cmd ( @{$cmd_aref} ){
						system($cmd);
						}
					}
        
        if( $exec_sys eq 'wait' ){
            $| = 1;  # turn off stdout buffering
            print "wait...\r";
            #- Wait for the forked children
            foreach my $cur_child_pid (@process_list) {
                waitpid($cur_child_pid,0);
            }
            &scanLogs();
# 						print Time::HiRes::time()."\n";
            next;
        }

        print "exec: $exec_sys\n" unless( $exec_sys eq "local" || $exec_sys eq "con");

        #system("logger -p local1.info -t DAQ $exec_sys");

        #- Loop over TRBs for given exec_sys
        if( $exec_sys =~ /etrax/ ){
            #- Name of etrax is explicitly written in exec_cmd{}
            #  in main startup script.
            if($opt_etrax){
                my $log = $log_dir . "/" . "log" . $i . "_"  . $exec_sys . "_" . $opt_etrax . ".txt";
                &forkMe( $cmd_aref, \@process_list, $opt_etrax, $log);
            }
            else{
                my $log = $log_dir . "/" . "log" . $i . "_"  . $exec_sys . ".txt";
                &forkMe( $cmd_aref, \@process_list, $exec_sys, $log);
            }
        }
        elsif( $exec_sys eq 'local' ){
            my $log = $log_dir . "/" . "log" . $i . "_"  . $exec_sys . ".txt";
            &forkMe( $cmd_aref, \@process_list, $exec_sys, $log);
        }
        elsif( $exec_sys eq 'nofork'){
						&execLocal($cmd_aref,$exec_sys);
        }
        else{
            #- Loop over TRBs for a given subsys
            foreach my $trb ( @{$trb_href->{$exec_sys}} ){
                my $log = $log_dir . "/" . "log" . $i . "_"  . $exec_sys . "_" . $trb . ".txt";
                &forkMe( $cmd_aref, \@process_list, $trb, $log);
            }
        }

        $i++;  #increment log file index
    }

    #- Wait for children
    foreach my $cur_child_pid (@process_list) {
        waitpid($cur_child_pid,0);
    }
}

sub execLocal()
{
    my ($cmd_aref) = @_;

    #- Loop over cmds to be executed on the local system
    #  without forking
    foreach my $cmd ( @{$cmd_aref} ){
        $| = 1;  # turn off stdout buffering

        if($cmd =~ /check_compile_time/){
            &checkCompileTime($cmd) unless($opt_test);
        }
    }
}

sub forkMe()
{
    my ($cmd_aref, $proc_list, $etrax, $log) = @_;
    
    my $child = fork();

    if( $child ){                           # parent
        push( @$proc_list, $child );
#         print "$child:  ".$cmd_aref->[0]."\n";
    }
    elsif( $child == 0 ) {                        # child
        exit(0) if($opt_test);

        if( $etrax eq "local" ){

            #- Loop over cmds to be executed on the local system
            foreach my $cmd ( @{$cmd_aref} ){
                $| = 1;  # turn off stdout buffering
                print "sleep...\r" if( $cmd =~ /sleep/ );
                
                if($cmd =~ /daq2oracle/){
                    &data2ora() unless($opt_test);
                }
                else{

                    #- Redirect STDOUT but not for 'echo'
                    unless($cmd =~ /echo/){
                        open(STDOUT, ">>$log") || die "Cannot redirect STDOUT";
                        open(STDERR, ">>&STDOUT") || die "Cannot dup STDERR";
                        select STDERR; $| = 1; # make unbuffered
                        select STDOUT; $| = 1; # make unbuffered
                    }

                    unless($opt_test){
                        print "===> $cmd\n" unless($cmd =~ /echo/);
                        system("$cmd");
                        print "> returned value of command $?\n" unless($cmd =~ /echo/);
                    }
                    
                    unless($cmd =~ /echo/){
                        close(STDOUT);
                        close(STDERR);
                    }
                }
            }
        }
        else{
            #- Connect to commandServer to exec commands on the remote systems
            if( &connectCmdServer($cmd_aref, $etrax, $cmd_server_port, $cmd_server_prtcl, $log) ){
                #print "Something went wrong on commandServer side.\n";
            }
        }

        exit(0);   # exit child
    }
    else{
        print "Could not fork: $!\n";
        exit(1);
    }
}

sub connectCmdServer()
{
    my ($cmd, $remote_host, $remote_port, $protocol, $log) = @_;

    # '$cmd' can be a reference to an array of commands
    # or just single command. In the first case, the commands
    # from the array will be executed one after another.

    &isVarDefined( $cmd, "connectCmdServer(): cmd" );
    &isVarDefined( $remote_host, "connectCmdServer(): remote_host" );

    my $fh = new FileHandle(">$log");

    if(!$fh) {
        my $txt = "\nError! Could not open file \"$log\" for output. Exit.\n";
        print STDERR $txt;
        print $txt;
        exit(128);
    }

    my $answer;
    my $retval = 1;

    my $socket = IO::Socket::INET->new(PeerAddr => $remote_host,
                                       PeerPort => $remote_port,
                                       Proto    => $protocol,
                                       Type     => SOCK_STREAM)
     or $answer = "ERROR: No response from Cmd Server at $remote_host:$remote_port\n";

    unless( defined $answer ){
        $socket->autoflush(1);
        print $socket "iamfromhadesdaq\n";
        $answer = <$socket>;

        &print2file($fh, $answer);

        my $reftype = reftype \$cmd;

        if( $reftype =~ /REF/ ){
            #- Loop over commands to be executed on etrax
            foreach my $command ( @{$cmd} ){
                
                $command = &cmdParam( $command, $remote_host );

                print $socket "$command\n";
                &print2file( $fh, "===> $command\n" );
                
                while ( <$socket> ) { 
                    &print2file( $fh, $_ );

                    if( $_ =~ /- END OF OUTPUT -/ ){
                        last;
                    }
                }
            }
        }
        else{
            print $socket "$cmd\n";
            &print2file( $fh, "===> $cmd\n" );
            
            while ( <$socket> ) { 
                &print2file( $fh, $_ );

                if( $_ =~ /- END OF OUTPUT -/ ){
                    last;
                }
            }
        } 

        close($socket);
    }

    if( $answer =~ /Connection accepted/ ){
        $retval = 0;
    }
    else{
        &print2file( $fh, $answer );
    }
    
    $fh->close();
    
    return $retval;
}

sub cpThresholds()
{
    my ($timestamp) = @_;
    
    my $thresh_dir = "/data/lxhadesdaq/daq/thresh";
    my %ora_thresh;
    my $ora_thresh_href = \%ora_thresh;

    foreach my $my_href ( @{$startup_aref} ){

        my %my_hash = %$my_href;

        my ($exec_sys, $cmd_aref) = each ( %my_hash );
        
        next unless( defined $exec_sys );

        next if( $exec_sys eq 'wait' );

        foreach my $cmd ( @{$cmd_aref} ){
            if( $cmd =~ /spi_trb/ ){
                $cmd =~ s/^\s+//;   # remove leading whitespace

                my ($spi, $thresh) = split(" ", $cmd);
                my $thresh_name_new = $thresh_dir . "/thresh_" . $timestamp . "_" . $exec_sys;

                $ora_thresh_href->{$exec_sys} = $thresh_name_new;

                my $THRPATH = "/var/diskless/etrax_fs"; 
                
                $thresh =~ s{                # Substitue...
                              \/home\/hadaq  # ...an Etrax path
                            }
                            {$THRPATH}gxms;    # ...with lxhadesdaq path

                if( $thresh =~ /\${TRBNUM}/ ){
                    foreach my $trb ( @{$trb_href->{$exec_sys}} ){
                        my $trbnum = 0; #default
                        if( $trb =~ /etraxp?(\d{3})/ || $trb =~ /trb?\d(\d{2})/){
                            $trbnum = $1;
                        }
                        else{
                            croak "cmdParam: unexpected etrax name: $trb. Exit.\n";
                        }

                        #- replace TRBNUM
                        $thresh =~ s{                # Substitue ...
                                      \${TRBNUM}     # ... a parameter
                                    }
                                    {$trbnum}gxms;   # ... with a TRB number

                        my $thresh_name_trb = $thresh_name_new . "_" . $trbnum;

                        system("cp $thresh $thresh_name_trb");
                    }
                }
                else{
                    system("cp $thresh $thresh_name_new");
                }
            }
        }
    }

    #- Build a line for Oracle DB
    my $line = "";

    foreach my $exec_sys (sort keys %{$ora_thresh_href}){
        my $thresh_name = $ora_thresh_href->{$exec_sys};
        $line = $line . " " . $exec_sys . " lxhadesdaq:" . $thresh_name . "%"; 
    }

    unless( $line eq "" ){
        $line = "loaded_thresholds " . $timestamp . " Loaded thresholds:% " . $line . "\n";
    }
    else{
        print "WARNING: could not identify file names for loaded thresholds!\n"
    }

    return $line;
}

sub print2file()
{
    my ($fh, $toprint) = @_;

    if( defined $toprint ){
        print $fh $toprint; 
        
        if( $opt_verb || $toprint =~ /ERROR/){
            print "$toprint\n";
        }
    }
}

sub cmdParam(){
    my ($cmd, $etrax) = @_;

    croak "cmdParam: undefined etrax name. Exit.\n" unless( defined $etrax );

    my $trbnum = 0; #default
    if( $etrax =~ /etraxp?(\d{3})/ || $etrax =~ /trb?\d(\d{2})/ || $etrax =~ /hades?\w(\d{2})/){
        $trbnum = $1;
    }
    else{
        croak "cmdParam: unexpected etrax name: $etrax. Exit.\n";
    }

    my $eb_port = $EB_Args_href->{'Main'}->{'PORT_BASE'} + $trbnum;
    my $eb_ip   = $EB_Args_href->{'Main'}->{'EB_IP'};
    
    #- replace TRBNUM
    $cmd =~ s{                # Substitue...
               \${TRBNUM}     # ...a parameter
             }
             {$trbnum}gxms;   # Raplace it with a TRB number
        
    #- replace EBIP
    $cmd =~ s{                # Substitue...
               \${EBIP}       # ...a parameter
             }
             {$eb_ip}gxms;    # Raplace it with a EB IP    

    #- replace EBPORT
    $cmd =~ s{                # Substitue...
               \${EBPORT}     # ...a parameter
             }
             {$eb_port}gxms;  # Raplace it with a EB PORT 
    
    $cmd = "source /home/hadaq/.bashrc; " . $cmd if($etrax =~ /hades?\w(\d{2})/);

    return $cmd;
}

sub makeRegisterConf()
{
    my ($subsys, $register, $outConf) = @_;

    $register = "../" . $subsys . "/" . $register;

    my %reg_hash;
    my $reg_href = \%reg_hash;

    my $fh = new FileHandle("$register", "r");
    &isItDefined($fh, $register);

    my $reg_table = 0;
    my $val_table = 0;
    my $ver_table = 0;
    my $ver_tdcmask = 0;
    my %mb_type;               #Motherboard type
    my $mb_type = \%mb_type;

    my $SPACE = "";

    while(<$fh>){

        #- Remove all comments
        $_ =~ s{                # Substitue...
                 \#             # ...a literal octothorpe
                 [^\n]*         # ...followed by any number of non-newlines
               }
               {$SPACE}gxms;    # Raplace it with a single space        

        #- Skip line if it contains only whitespaces
        next unless(/\S/);

        #- Find which table we will read now
        if(/^(\s+)?!Register\stable/){
            $reg_table   = 1;
            $val_table   = 0;
            $ver_table   = 0;
            $ver_tdcmask = 0;
            next;
        }
        elsif(/^(\s+)?!Value\stable/){
            $reg_table   = 0;
            $val_table   = 1;
            $ver_table   = 0;
            $ver_tdcmask = 0;
            next;
        }
        elsif(/^(\s+)?!Version\stable/){
            $reg_table   = 0;
            $val_table   = 0;
            $ver_table   = 1;
            $ver_tdcmask = 0;
            next;
        }
        elsif(/^(\s+)?!Version\stdcmask/){
            $reg_table   = 0;
            $val_table   = 0;
            $ver_table   = 0;
            $ver_tdcmask = 1;
            next;
        }

        if($reg_table){
            my ($type, @reg) = split(" ", $_);
            my $reg = \@reg;
            $mb_type->{$type} = $reg;
        }
        elsif($val_table){
            # We assume here that reg_table was before val_table
            # thus mb_type hash is already filled at this point.

            my ($addr, $type, @val) = split(" ", $_);

            if( ! defined $mb_type->{$type} ){
                print "Error: Board type '$type' specified in 'Value table' in $register\n";
                print "is most likely not defined in 'Register table'! Exit.\n";
                $fh->close;
                exit(1);
            }

            my $arr_size = scalar @{ $mb_type->{$type} };
            
            for(my $i=0; $i<$arr_size; $i++){
                my $reg = @{$mb_type->{$type}}[$i];
                my $val = $val[$i];

                push(@{$reg_hash{$addr}}, {$reg => $val});
            }
        }
        elsif($ver_table){
            $data2ora_href->{"MDC"}->{"THRESH_VERS"} = $_ if( $subsys eq "mdc");
            $data2ora_href->{"RICH"}->{"THRESH_VERS"} = $_ if( $subsys eq "rich");
        }
        elsif($ver_tdcmask){
            $data2ora_href->{"MDC"}->{"TDCMASK_VERS"} = $_ if( $subsys eq "mdc");
        }
    }

    $fh->close;

    #--------------- Write config file 
    my $outConf_register = $var_dir . "/tmp/" . $outConf;
    my $ret_register     = "/home/hadaq/tmp/" . $outConf;

    $fh = new FileHandle(">$outConf_register");

    foreach my $addr ( sort keys %{$reg_href} ){
        foreach my $ref (@{$reg_href->{$addr}}){
            my ($reg, $thr) = each( %{$ref} );
            
            print $fh "w $addr $reg $thr\n";
        }
    }

    $fh->close;
    
    return $ret_register;
}

sub makeAddressesConf()
{
    my ($subsys, $serials, $addresses, $outConf) = @_;

    $serials   = "../" . $subsys . "/" . $serials;
    $addresses = "../" . $subsys . "/" . $addresses;

    my %trbdhcp_hash;
    my $trbdhcp_href = \%trbdhcp_hash;

    #------------ Read addresses into trbdhcp hash
    my $fh = new FileHandle("$addresses", "r");
    &isItDefined($fh, $addresses);

    my $SPACE = "";

    while(<$fh>){

        #- Remove all comments
        $_ =~ s{                # Substitue...
                 \#             # ...a literal octothorpe
                 [^\n]*         # ...followed by any number of non-newlines
               }
               {$SPACE}gxms;    # Raplace it with a single space

        #- Skip line if it contains only whitespaces
        next unless(/\S/);

        my ($addr, $serial, $endpoint, $design, $trbNr) = split(" ", $_);

        #- All fields must be defined
        next unless( defined $design && defined $addr && 
                     defined $serial && defined $endpoint);

        #- Skip all lines with serial number zero
        next if( $serial eq '0' );

        #- Define uniqueu key
        my $key = $addr . "_" . $endpoint;

        $trbdhcp_href->{$key}->{'addr'}     = lc($addr);
        $trbdhcp_href->{$key}->{'design'}   = $design;
        $trbdhcp_href->{$key}->{'endpoint'} = $endpoint;
        $trbdhcp_href->{$key}->{'serial'}   = $serial;
        $trbdhcp_href->{$key}->{'trb'}      = $trbNr;

    }

    $fh->close;

    #------------ Read serials into trbdhcp hash
    $fh = new FileHandle("$serials", "r");
    &isItDefined($fh, $serials);

    while(<$fh>){
        
        #- Remove all comments
        $_ =~ s{                # Substitue...
                 \#             # ...a literal octothorpe
                 [^\n]*         # ...followed by any number of non-newlines
               }
               {$SPACE}gxms;    # Raplace it with a single space

        #- Skip line if it contains only whitespaces
        next unless(/\S/);

        my ($serial, $uid) = split(" ", $_);

        next unless( defined $serial && defined $uid );

        #- Skip all lines with serial number zero
        next if( $serial eq '0' );

        foreach my $key ( keys %{$trbdhcp_href} ){

            next unless( $serial eq $trbdhcp_href->{$key}->{'serial'} );
            $trbdhcp_href->{$key}->{'uid'} = lc($uid);
        }
    }

    $fh->close;

    #------------ Write config file for 'trbdhcp'
    my $outConf_trbdhcp = $var_dir . "/tmp/" . $outConf;
    my $ret_trbdhcp     = "/home/hadaq/tmp/" . $outConf; 

    $fh = new FileHandle(">$outConf_trbdhcp");

    foreach my $key (sort keys %$trbdhcp_href) {
        my $addr     = $trbdhcp_href->{$key}->{'addr'};
        my $uid      = $trbdhcp_href->{$key}->{'uid'};
        my $endpoint = $trbdhcp_href->{$key}->{'endpoint'};
        
        next if( ! defined $addr || ! defined $uid || ! defined $endpoint);

        print $fh "$addr $uid $endpoint\n";
    }

    $fh->close;

    #--- Add this hash to a global hash
    %addr_db_conf = (%addr_db_conf, %$trbdhcp_href);

    return $ret_trbdhcp;
}

sub checkCompileTime()
{
    my ($cmd) = @_;

    my $sys;
    my $compile_time;

    if($cmd =~ /check_compile_time\s+(\w+)\s+0x(\w+)/){
        $sys = lc($1);
        $compile_time = hex($2);
    }

    unless( defined $sys || defined $compile_time ){
        die "check_compile_time command must contain system and compile time as arguments! Exit.\n";
    }

    my $read_cmd = "";
    if(lc($sys) eq "oep"){
        $read_cmd = "trbcmd r 0xfffd 0x40";
    }
    else{
        print "Reading compile times failed: unsupported sys type $sys\n";
        return 0;
    }

    my @out = `$read_cmd`;

    my $oldCompileTime = 0;

    foreach my $line (@out){

        next if($line =~ /Read compile time/ );

        if( $line =~ /failed/ ){
            print "ERROR: when reading compile times of $sys: $line\n";
            &askUser();
        }

        my $local_time;
        my $local_addr;

        if( $line =~ /0x(\w+)\s+0x(\w+)/ ){
            $local_addr = lc($1);
            $local_time = hex($2);
        }

        unless( defined $local_addr || defined $local_time ){
            print "ERROR: unexpected output: $line\n from command: $read_cmd\n";
            &askUser();
        }

        if( defined $local_time && defined $local_addr){
            if( $local_time < $compile_time ){
                $oldCompileTime = 1;
                print "Compile time for $sys $local_addr is too old!\n";
            }
        }
    }

    &askUser() if($oldCompileTime);
}

sub askUser()
{
    my $answer = &promptUser("Continue?", "Enter to continue, Ctrl+C to stop");
    if( $answer eq "no" || $answer eq "n" ){
        print "Exit.\n";
        exit(0);
    }
    else{
        print "Continue...\n";
    }    
}

sub checkConnection()
{

    #----------- Check connection to hosts -------------
    print "Check connection to hosts...\n";

    my @dead_hosts = ();
    my @alive_hosts = ();
    &pingHosts(\@alive_hosts, \@dead_hosts);

    if( @dead_hosts ){
        print "Cannot connect to the following hosts:\n";
        
        foreach my $host (@dead_hosts){

            my $msg = "undef";
            if($host =~ /etraxp?(\d{3})/){
                my $serial = $1;

                if(&checkShowerNORPC($host)){
                    $msg = "addr: - type: -";
                }
                else{
                    $msg = &serial2addrAndSysType($serial, "TRB");
                }
            }
            
            print "$host   $msg\n";
            system("logger -p local1.info -t DAQ STARTUP \\<E\\> Cannot connect to $host  $msg");
        }
        
        &askUser();
    }
    else{
        print "Connection to hosts is OK.\n";
    }

    #---------- Check connection to command servers -------------
#     print "Check connection to command servers...\n";

#     my @dead_cservers = ();

#     &checkCmdServers(\@alive_hosts, \@dead_cservers);

    if( @dead_cservers ){
        print "Cannot connect to command servers for the hosts:\n";
        
        foreach my $host (@dead_cservers){
            print "$host\n";
            system("logger -p local1.info -t DAQ STARTUP \\<E\\> Cannot connect to command server at $host");
        }

        print "I will try to restart the command servers\n";

        &restartCmdServers(\@dead_cservers);

        @dead_cservers = ();
        
        &pingHosts(\@alive_hosts, \@dead_cservers);
        
        if( @dead_cservers ){
            print "Still cannot connect to command servers for the hosts:\n";
            
            foreach my $host (@dead_cservers){
                print "$host\n";
            }

            print "Try to start \'command_server -p 4712 &\' on these hosts by hand.\n";
            print "Exit.\n";
            exit(0);
        }
        else{
            print "Missing command_servers have been started! Continue...\n";
            sleep(2);
        }

    }
    else{
        print "Connection to command servers is OK.\n";
    }
	if( @dead_hosts ){
		&rmDeadHosts(\@dead_hosts);
		}
}

sub rmDeadHosts()
{
    my ($dead_hosts_aref) = @_;

    #my $copy = clone($some_ref);
    
    foreach my $sys (%$trb_href){

        next unless( defined @{$trb_href->{$sys}} && $#{$trb_href->{$sys}} > 0 );

        foreach my $host (@$dead_hosts_aref){
            @{$trb_href->{$sys}} = grep { !($_ eq $host) } @{$trb_href->{$sys}};
        }
    }
}



sub promptUser {
#----------------------------(  promptUser  )-----------------------------
#                                                                         
#  FUNCTION:        promptUser                                                
#                                                                         
#  PURPOSE:        Prompt the user for some type of input, and return the    
#                input back to the calling program.                        
#                                                                         
#  ARGS:        $promptString - what you want to prompt the user with     
#                $defaultValue - (optional) a default value for the prompt 
#  
#  EXAMPLES:
#    $username = &promptUser("Enter the username ");
#    $password = &promptUser("Enter the password ");
#    $homeDir  = &promptUser("Enter the home directory ", "/home/$username");
#    print "$username, $password, $homeDir\n";
#                                                              
#-------------------------------------------------------------------------
   #  two possible input arguments - $promptString, and $defaultValue 
   #  make the input arguments local variables.                        

   my ($promptString,$defaultValue) = @_;

   #  if there is a default value, use the first print statement; if  
   #  no default is provided, print the second string.                 

   if ($defaultValue) {
      print $promptString, "[", $defaultValue, "]: ";
   } else {
      print $promptString, ": ";
   }

   $| = 1;               # force a flush after our print
   my $input = <STDIN>;  # get the input from STDIN (presumably the keyboard)

   # remove the newline character from the end of the input the user gave us

   chomp($input);

   #  if we had a $default value, and the user gave us input, then   
   #  return the input; if we had a default, and they gave us no     
   #  no input, return the $defaultValue.                            
   #                                                                  
   #  if we did not have a default value, then just return whatever  
   #  the user gave us.  if they just hit the <enter> key,           
   #  the calling routine will have to deal with that.               

   if ("$defaultValue") {
      return $input ? $input : $defaultValue; # return $input if it has a value
   } else {
      return $input;
   }
}

sub pingHosts()
{
    my ($alive_hosts_aref, $dead_hosts_aref) = @_;
    my @thread_list = ();
    my @host_tmp_list = ();

    foreach my $sys (%$trb_href){
        foreach my $host ( @{$trb_href->{$sys}} ){

            next if(any {$host eq $_} @host_tmp_list); # Exclude hosts which were already checked
            push(@thread_list, threads->new( \&pingHost, $host));
            push(@host_tmp_list, $host);
        }
    }

    #- Join threads
    my $retcode;

    foreach my $t (@thread_list){
        $retcode = $t->join();
        
        next if($retcode eq -1);

        my ($host, $hstat) = split(/:/, $retcode);

        if( $hstat eq "alive" ){
            push( @$alive_hosts_aref, $host );
        }
        elsif( $hstat eq "dead" ){
            push( @$dead_hosts_aref, $host );
        }
        elsif( $hstat eq "cmdserverdead" ){
            push( @$alive_hosts_aref, $host );
            push( @dead_cservers, $host );
        }        
        else{
            print "ping $host returned unknown status: $hstat. Exit.\n";
            exit(0);
        }
    }
}

sub pingHost()
{
    my ($host) = @_;
    
    my $retval = "undef";
# print $host." ".Time::HiRes::time()."\n" ;
    my $p = Net::Ping->new();

    if( $p->ping($host,1) ){
        $retval = "$host:alive";
    }
    else{
        $retval = "$host:dead";
        return $retval;
    }
    $p->close();
# print $host." ".Time::HiRes::time()."\n" ;
    #Jan 06.01.12
		my $sock = new IO::Socket::INET ( 
                                          PeerAddr => $host, 
                                          PeerPort => $cmd_server_port, 
                                          Proto => 'tcp'); 
    $retval = "$host:cmdserverdead" unless $sock; 
    close($sock) if( defined $sock );
    #Jan 06.01.12
#print $host." ".Time::HiRes::time()."\n" ;
    return $retval;
}

# sub checkCmdServers()
# {
#     my ($alive_hosts_aref, $dead_cservers_aref) = @_;
# 
#     foreach my $host (@$alive_hosts_aref){
#         my $sock = new IO::Socket::INET ( 
#                                           PeerAddr => $host, 
#                                           PeerPort => $cmd_server_port, 
#                                           Proto => 'tcp'); 
#         push( @$dead_cservers_aref, $host ) unless $sock; 
#         close($sock) if( defined $sock );
#     }
# }

sub execViaExpect()
{
    my ($etrax, $path, $cmd, $args, $log) = @_;

    my $exe = "$expect_script $etrax $path $cmd $args > $log 2>&1";
    print "exe: $exe\n" if($opt_verb);
    system($exe) unless($opt_test);
}

sub restartCmdServers()
{
    my ($dead_cservers_aref) = @_;

    my $path = "/home/hadaq/bin/";

    foreach my $host (@$dead_cservers_aref){
        my $log = $log_dir . "/expect_" . $host . ".log";
        &execViaExpect( $host, $path, "command_server", "\'-p 4712 &\'", $log);
    }
}

sub data2ora()
{

    #- Read unique IDs
    my @id_list = `trbcmd i 0xffff`;

    foreach my $id_line (@id_list){

        if( $id_line =~ /failed/ ){
            print "ERROR: data2ora(): 'daqop read ids' failed! Exit.\n";
            exit(1);
        }

        if( $id_line =~ /0x(\w+)\s+0x(\w+)\s+0x(\w+)/ ){
            my $addr = lc($1);
            my $uid  = lc($2);
            my $fpga = $3;

            #- There are boards with several FPGAs
            #  These boards have identical Ids but several different
            #  trbnet addresses (three addresses for the board with three FPGAs)
            #  The smallest address is of importance for us because it is an address
            #  of FPGA which sends the data out (uplink). Thus the smallest
            #  address is the address of the data source.
            if( defined $data2ora_href->{"BOARDID"}->{$uid} ){
                if( hex($addr) < hex($data2ora_href->{"BOARDID"}->{$uid}->{'ADDR'}) ){
                    $data2ora_href->{"BOARDID"}->{$uid}->{'ADDR'} = $addr;
                }
            }
            else{
                $data2ora_href->{"BOARDID"}->{$uid}->{'ADDR'} = $addr;
            }
        }
    }

    #-------- Write data to a file to be passed to Oracle

    my $timestamp = &timeStamp();
    my $ora_file  = "/home/hadaq/oper/daq2ora/daq2ora_" . $timestamp . ".txt";
    my $current_file  =  "/home/hadaq/oper/daq2ora/daq2ora_current.txt";

    #- Read settings with resolution mode of TRBs
    my $TDCsettings_href = &readTRBTDCsettings();

    open( FILE, '>', $ora_file ) or die "Could not open $ora_file: $!" if($opt_ora eq "file");

    #- Write threshold file names
    my $line_thresh = &cpThresholds($timestamp);
    if( $line_thresh =~ /loaded_thresholds/){
        #print FILE $line_thresh;
    }

    foreach my $uid ( sort keys %{$data2ora_href->{"BOARDID"}} ){
        my $addr = $data2ora_href->{"BOARDID"}->{$uid}->{'ADDR'};
        my $subevtid;

        if( any {lc($_) eq lc($addr)} @subEvtIds ){
            $subevtid = lc($addr);
        }
        else{
            $subevtid = "NULL";
        }

        #- Get TRB resolution mode (returns 0 if the board is not TRB)
        my $mode = &getTRBResolutionMode($TDCsettings_href, lc($addr));

        my $outdata = sprintf("%19s %6s %6s %4s", $uid, $addr, $subevtid, $mode);
        
        print "data2ora: $outdata\n" if($opt_ora eq "file" && $opt_verb);
        print FILE "$outdata\n" if($opt_ora eq "file");

        #- If mode == 0x00 it not necessary to write these zeros to the register
        #  because '00' is the default value of the register.
        unless( $mode eq "NULL" || $mode == 0 ){
            my $cmd  = "/home/hadaq/scripts/set_modrc.sh 0x$mode 0x$addr 0xa0c2"; 
            #my $host = @{$trb_href->{"scs"}}[0];  # CTS Etrax name;
            my $host = "localhost";  # pexor slow control interface;
            my $log  = $log_dir . "/mode/modrc_" . $host . ".log";
            &connectCmdServer($cmd, $host, $cmd_server_port, $cmd_server_prtcl, $log);
        }
    }

    if( defined $data2ora_href->{"MDC"}->{"THRESH_VERS"} ){
        my $var = $data2ora_href->{"MDC"}->{"THRESH_VERS"};
        print FILE "mdc_thresh_version $var\n" if($opt_ora eq "file");
    }

    if( defined $data2ora_href->{"MDC"}->{"TDCMASK_VERS"} ){
        my $var = $data2ora_href->{"MDC"}->{"TDCMASK_VERS"};
        print FILE "mdc_tdcmask_version $var\n" if($opt_ora eq "file");
    }

    if( defined $data2ora_href->{"RICH"}->{"THRESH_VERS"} ){
        my $var = $data2ora_href->{"RICH"}->{"THRESH_VERS"};
        print FILE "rich_thresh_version $var\n" if($opt_ora eq "file");
    }    

    close( FILE ) or die "Could not close $ora_file: $!" if($opt_ora eq "file");

    system("cp $ora_file $current_file") if($opt_ora eq "file");
}

sub readTRBTDCsettings()
{
    #-------- Read TRB TDC settings
    my $config_file = "/var/diskless/etrax_fs/trbtdctools/config/TRB_TDC_settings.conf";

    my $TDCsettings_href;

    unless( $TDCsettings_href = do $config_file ){
        die "Couldn't parse $config_file: $@, stopped"  if $@;
        die "Couldn't do $config_file: $!, stopped"     unless defined $TDCsettings_href;
        die "Couldn't run $config_file, stopped"        unless $TDCsettings_href;
    }

    return $TDCsettings_href;
}

sub getTRBResolutionMode()
{
    my ($TDCsettings_href, $addr) = @_;

    my $mode;

    my $board_type;
    my $board_sysType;
    &boardSysType(lc($addr), \$board_type, \$board_sysType);

    if( $board_type eq "TRB" && $board_sysType ne "CTS" && (&excludeBoards($addr)) ){
        my $serial = &addr2serial(lc($addr));
        $mode      = &resMode($TDCsettings_href, $serial);
    }
    else{
        $mode = "NULL";
    }

    return $mode;
}

sub resMode()
{
    my ($TDCsettings_href, $serial) = @_;

    my $trbname = sprintf("TRB_%03d", $serial);

    my $mrcc_a = $TDCsettings_href->{$trbname}->{'TDC'}->{'TDC_A'}->{'mode_rc_compression'};
    my $mrc_a  = $TDCsettings_href->{$trbname}->{'TDC'}->{'TDC_A'}->{'mode_rc'};
    my $mrcc_b = $TDCsettings_href->{$trbname}->{'TDC'}->{'TDC_B'}->{'mode_rc_compression'};
    my $mrc_b  = $TDCsettings_href->{$trbname}->{'TDC'}->{'TDC_B'}->{'mode_rc'};
    my $mrcc_c = $TDCsettings_href->{$trbname}->{'TDC'}->{'TDC_C'}->{'mode_rc_compression'};
    my $mrc_c  = $TDCsettings_href->{$trbname}->{'TDC'}->{'TDC_C'}->{'mode_rc'};
    my $mrcc_d = $TDCsettings_href->{$trbname}->{'TDC'}->{'TDC_D'}->{'mode_rc_compression'};
    my $mrc_d  = $TDCsettings_href->{$trbname}->{'TDC'}->{'TDC_D'}->{'mode_rc'};

    my $mode_undefined = 0;

    unless( defined $mrcc_a ){
        $mode_undefined = 1;
        print "ERROR: $trbname, TDC_A: mode_rc_compression is not defined! Exit.\n";
    }
    unless( defined $mrc_a ){
        $mode_undefined = 1;
        print "ERROR: $trbname, TDC_A: mode_rc is not defined! Exit.\n";
    }
    unless( defined $mrcc_b ){
        $mode_undefined = 1;
        print "ERROR: $trbname, TDC_B: mode_rc_compression is not defined! Exit.\n";
    }
    unless( defined $mrc_b ){
        $mode_undefined = 1;
        print "ERROR: $trbname, TDC_B: mode_rc is not defined! Exit.\n";
    }
    unless( defined $mrcc_c ){
        $mode_undefined = 1;
        print "ERROR: $trbname, TDC_C: mode_rc_compression is not defined! Exit.\n";
    }
    unless( defined $mrc_c ){
        $mode_undefined = 1;
        print "ERROR: $trbname, TDC_C: mode_rc is not defined! Exit.\n";
    }
    unless( defined $mrcc_d ){
        $mode_undefined = 1;
        print "ERROR: $trbname, TDC_D: mode_rc_compression is not defined! Exit.\n";
    }
    unless( defined $mrc_d ){
        $mode_undefined = 1;
        print "ERROR: $trbname, TDC_D: mode_rc is not defined! Exit.\n";
    }

    #- All four TDCs must have identical modes
    unless( $mode_undefined ){
        unless( $mrcc_a == $mrcc_b && $mrcc_a == $mrcc_c && $mrcc_a == $mrcc_d &&
                $mrc_a == $mrc_b && $mrc_a == $mrc_c && $mrc_a == $mrc_d ){
            print "ERROR: $trbname, resolution modes must be identical for all four TDCs! Exit.\n";
        }
    }
    
    if( $mode_undefined ){
        exit(1);
    }

    # Description of the resolution modes:
    #
    # mrcc = mode_rc_compression
    # mrc  = mode_rc
    #
    # mrcc  mrc  mode
    # 0     0    00 - high resolution mode (100ps binning)
    # 1     1    01 - very high resolution mode (25ps binning)
    # 0     1    02 - very high resolution mode calibration data 
    #                (one hit produces 4 data words like in high resolution mode)

    my $mode;

    if(    $mrcc_a eq "0" && $mrc_a eq "0" ){
        $mode = "00";
    }
    elsif( $mrcc_a eq "1" && $mrc_a eq "1" ){
        $mode = "01";
    }
    elsif( $mrcc_a eq "0" && $mrc_a eq "1" ){
        $mode = "02";
    }
    else{
        print "ERROR: $trbname, resolution modes have wrong values! Exit.\n";
    }

    return $mode;
}

sub addr2serial()
{
    my ($addr) = @_;

    my $serial;
    
    my $addr_hex = "0x" . lc($addr);

    foreach my $key ( keys %$addr_db_conf_href ){
        if( $addr_db_conf_href->{$key}->{'addr'} eq $addr_hex ){
            unless( defined $addr_db_conf_href->{$key}->{'serial'} ){
                next;
            }

            $serial = $addr_db_conf_href->{$key}->{'serial'};
            last;
        }
    }

    unless( defined $serial ){
        print "ERROR: addr2serial(): unknown serial number for address $addr. Exit.\n";
        exit(1);
    }

    return $serial;
}

sub checkShowerNORPC()
{
    my ($trb) = @_;

    my $retVal = 0;

    unless(defined $trb_href->{'rpc'}){
        if(any {$trb eq $_} @{$trb_href->{'shower'}}){
            $retVal = 1;
        }
    }

    return $retVal;
}

sub serial2addrAndSysType()
{
    my ($serial, $board_type) = @_;

    # There is no direct connection between serial number
    # and TRB-Net address. One should provide board type
    # in addition to serial number. 

    my $addr;
    my $bType;
    my $bSysType;

    foreach my $key ( keys %$addr_db_conf_href ){
        next unless( defined $addr_db_conf_href->{$key}->{'serial'} );
        next unless( defined $addr_db_conf_href->{$key}->{'trb'} );

        if( $addr_db_conf_href->{$key}->{'serial'} == $serial &&
            $addr_db_conf_href->{$key}->{'serial'} == $addr_db_conf_href->{$key}->{'trb'} ){
            unless( defined $addr_db_conf_href->{$key}->{'addr'} ){
                next;
            }

            $addr = $addr_db_conf_href->{$key}->{'addr'};

            &boardSysType($addr, \$bType, \$bSysType);

            next unless($bType eq $board_type);

            last;
        }
    }    

    unless( defined $addr ){
        print "ERROR: serial2addr(): unknown address for serial number $serial.\n";
        #exit(1);
    }    
    
    unless( defined $bSysType ){
        print "ERROR: serial2addr(): unknown board system type for serial number $serial.\n";
        #exit(1);
    } 

    my $retval = "";
    if( defined $addr && defined $bSysType ){
        $retval = "addr: $addr type: $bSysType";
    } 
    
    return $retval;
}

sub excludeBoards()
{
    my ($addr) = @_;

    # This subroutine excludes boards which have unused TDCs
    # and those TDCs must not be configured. Moreover the corresponding
    # register should not be overwritten with TDC resoltuion mode value.

    # Exclude all CTS and SCS boards
    my $board_sys;
    my $retval = 1;

    foreach my $sys ( keys %$addressRange_href ){
        my $addr_min = lc($addressRange_href->{$sys}->{'MIN'});
        my $addr_max = lc($addressRange_href->{$sys}->{'MAX'});
        
        if( hex(lc($addr)) >= hex($addr_min) && hex(lc($addr)) <= hex($addr_max) ){
            $board_sys = $addressRange_href->{$sys};
            last;
        }
    }

    unless( defined $board_sys ){
        print "TRB-Net address $addr is outside of the known address ranges! Exit.\n";
        exit(0);
    }

    if( $board_sys eq "CTS" || $board_sys eq "SCS" ){
        $retval = 0;
    }

    return $retval;
}

sub boardSysType()
{
    my ($addr, $bType_ref, $bSysType_ref) = @_;
    
    foreach my $sys ( keys %$addressRange_href ){
        my $addr_min = lc($addressRange_href->{$sys}->{'MIN'});
        my $addr_max = lc($addressRange_href->{$sys}->{'MAX'});

        if( hex(lc($addr)) >= hex($addr_min) && hex(lc($addr)) <= hex($addr_max) ){
            $$bType_ref    = $addressRange_href->{$sys}->{'TYPE'};
            $$bSysType_ref = $sys;
            last;
        }
    }

    unless( defined $$bType_ref ){
        print "ERROR: boardSysType(): unknown board type for address $addr.\n";
        $$bType_ref = "undef";
    }    

    unless( defined $$bSysType_ref ){
        print "ERROR: boardSysType(): unknown board system type for address $addr.\n";
        $$bSysType_ref = "undef";
    }    
}

sub boardType()
{
    my ($addr) = @_;

    my $board_type;

    foreach my $sys ( keys %$addressRange_href ){
        my $addr_min = lc($addressRange_href->{$sys}->{'MIN'});
        my $addr_max = lc($addressRange_href->{$sys}->{'MAX'});

        if( hex(lc($addr)) >= hex($addr_min) && hex(lc($addr)) <= hex($addr_max) ){
            $board_type = $addressRange_href->{$sys}->{'TYPE'};
            last;
        }
    }

    unless( defined $board_type ){
        print "ERROR: boardType(): unknown board type for address $addr. Exit.\n";
        exit(1);
    }

    return $board_type;
}

sub timeStamp()
{
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime($seconds1);
    my $timestamp = sprintf("%4d-%02d-%02d_%02d.%02d.%02d",
                            $year+1900, $mon+1, $mday, $hour, $min, $sec);

    return $timestamp;
}

sub scanLogs()
{
    #- Check the log files which were created
    #  after DAQ restart (after $seconds)

    opendir(DIR, $log_dir) or die "Could not open $log_dir: $!";;
    my @logfile_list = grep(/^log/, readdir(DIR));
    closedir(DIR);

    #- Sort files by modification date
    @logfile_list = sort { -M "$log_dir/$a" <=> -M "$log_dir/$b" } (@logfile_list);

    my $errorFound = 0;

    foreach my $file (@logfile_list){

        #- Modification date in seconds since EPOCH
        my $seconds2 = (stat "$log_dir/$file")[9];

        if( $seconds2 > $seconds1 ){
            if(&scanLogFile("$log_dir/$file")){
                $errorFound = 1;
            }
        }
    }

    if($errorFound){
        &askUser();
    }

    #- Update time.
    #  We want to look only at the log files
    #  which were not checked before.
    $seconds1 = time;
}

sub scanLogFile()
{
    my ($logFile) = @_;

    my $retval = 0;

    open(DAT, $logFile) || die("Could not open $logFile!");
    my @log_data = <DAT>;
    close(DAT); 

    if( any {$_ =~ /TX Busy/} @log_data ){
        print "Found \'TX Busy\' in $logFile. Press Ctrl-C and try again!\n";
        system("logger -p local1.info -t DAQ STARTUP \\<E\\> Found \'TX Busy\' in $logFile");
        $retval = 1;
    }

    if( any {$_ =~ /Verification Failure/} @log_data ){
        print "Found \'Verification Failure\' in $logFile. Problem with jam-programming?\n";
        system("logger -p local1.info -t DAQ STARTUP \\<E\\> Found \'Verification Failure\' in $logFile");
        $retval = 1;
    }

    if( any {$_ =~ /Fifo not empty/} @log_data ){
        print "Found \'Fifo not empty\' in $logFile. Problem with TRB-Net?\n";
        system("logger -p local1.info -t DAQ STARTUP \\<E\\> \'Fifo not empty\' in $logFile");
        $retval = 1;
    }

    if( any {$_ =~ /command not found/} @log_data ){
        print "Found \'command not found\' in $logFile. Problem with environment settings?\n";
        system("logger -p local1.info -t DAQ STARTUP \\<E\\> \'command not found\' in $logFile");
        $retval = 1;
    }

    if( any {$_ =~ /file not found/} @log_data ){
        print "Found \'file not found\' in $logFile. Problem with environment settings?\n";
        system("logger -p local1.info -t DAQ STARTUP \\<E\\> \'file not found\' in $logFile");
        $retval = 1;
    }

    if( any {$_ =~ /No such file or directory/} @log_data ){
        print "Found \'No such file or directory\' in $logFile. Problem with missing file?\n";
        system("logger -p local1.info -t DAQ STARTUP \\<E\\> \'No such file or directory\' in $logFile");
        $retval = 1;
    }

    if( any {$_ =~ /Permission denied/} @log_data ){
        print "Found \'Permission denied\' in $logFile. Problem with permission settings?\n";
        system("logger -p local1.info -t DAQ STARTUP \\<E\\> \'Permission denied\' in $logFile");
        $retval = 1;
    }
    if( any {$_ =~ /RPC/} @log_data ){
        print "Found \'Remote Procedure Call (RPC) Error\' in $logFile. Problem with trbnet deamon?\n";
        system("logger -p local1.info -t DAQ STARTUP \\<E\\> \'Remote Procedure Call (RPC) Error\' in $logFile");
        $retval = 1;
    }
    if( any {$_ =~ /(DMA|SEMAPHORE|PEXOR)/i} @log_data ){
        print "Found \'DMA/Semaphore/Pexor Error\' in $logFile. Problem with PEXOR?\n";
        system("logger -p local1.info -t DAQ STARTUP \\<E\\> \'Logfile shows DMA/Semaphore/Pexor Error\' in $logFile");
        $retval = 1;
    }    

    return $retval;
}

sub forkStatusServer()
{
    my $child = fork();

    if( $child ){                  # parent
    }
    elsif( $child == 0 ) {            # child   
        &statusServer();
        exit(0);   # exit child
    }
    else{
        print "Could not fork statusServer: $!\n";
        exit(1);
    }

    return $child;
}

sub statusServer()
{

    #- socket for broadcast
    my  $sock_udp = IO::Socket::INET->new(PeerPort  => 1960,
                                          PeerAddr  => "192.168.103.255",
                                          Proto     => 'udp',
                                          LocalAddr => "192.168.100.50",
                                          Broadcast => 1,
                                          Reuse     => 1)
        or die "Can't bind : $@\n";
    
    #- Inform all clients that DAQ is being restarted
    $sock_udp->send("STARTING") or die("Socket send error $!");
    close($sock_udp);
    
    #- Start TCP server
    my $sock = new IO::Socket::INET( LocalAddr => "192.168.100.50",
                                     LocalPort => 1972,
                                     Proto     => 'tcp',
                                     Listen    => SOMAXCONN,
                                     Reuse     => 1);

    $sock or die "Cannot bind socket :$!";    

    STDOUT->autoflush(1);

    my($new_sock, $buf);

    my $selector = new IO::Select( $sock );

    while(1) {

        # wait 3 seconds for connections
        while (my @file_handles = $selector->can_read( 3 )) {

            foreach my $file_handle (@file_handles) {

                if($file_handle == $sock) {

                    # create a new socket for this transaction
                    unless (defined( $new_sock = $sock->accept() ))
                    {
                        print "statusServer: ERROR - Cannot open socket to send status!\n";
                        return;
                    }

                    while (defined($buf = <$new_sock>)) {
                        #print "client asked: $buf";
                        if($buf =~ /MON_HUB: STILL STARTING\?/){
                            $new_sock->send("STARTING\n") or die("Socket send error $!");
                        }

                        unless( kill(0, $parent_pid) ){
                            print "Exit status server thread.\n";
                            close( $new_sock );
                            close( $sock );
                            exit(0);
                        }
                    }

                    close( $new_sock );
                }
            }

            unless( kill(0, $parent_pid) ){
                print "Exit status server thread.\n";
                close( $sock );
                exit(0);
            } 
        }

        unless( kill(0, $parent_pid) ){
            print "Exit status server thread.\n";
            close( $sock );
            exit(0);
        }
    }
}

sub closeEBs()
{
    print "Kill EBs...";
#    system("cd ../evtbuild/; ./start_eb_gbe.pl -e stop -n 1-16");
    print "\n";
}

sub startEBs()
{
    print "Start EBs...\n";
#    system("cd ../evtbuild/; ./start_eb_gbe.sh");
    print "\n";
}
