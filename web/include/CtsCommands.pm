#implements functions such as list, dumoing, reading and writing registers
# called by frontends

use warnings;
use strict;

use POSIX qw[ceil];
use Scalar::Util qw[looks_like_number];
use List::Util qw[min max sum];   
use Date::Format;
use Data::Dumper;

use Time::HiRes qw(usleep gettimeofday tv_interval);
   
sub printTable {
   # printTable ($data, [$linefill], [$colsep])
   #  $data expects an array reference. Each entry is interpreted
   #  as one row. If the row itself is an array reference, each 
   #  entry hold the data of one column. If the row is a string,
   #  it is displayed as a header
   my $data = shift;
   my $linefill = shift;
   my $colsep = shift;
   
   $linefill = "-"   unless defined $linefill;
   $colsep   = " | " unless defined $colsep;
   
# find max len per column
   my @len = (0);
   
   my $linelength = 0;
   foreach my $row ( @{$data} ) {
      if (ref $row) {
         foreach my $i ( 0 .. $#{$row} ) {
            $len[$i] = 0 unless exists $len[$i];
            $len[$i] = max($len[$i], length $row->[$i]);
         }
      } else {
         $linelength = max($linelength, length $row);
      }
   }
   
   $linelength = max($linelength, sum(@len) + length($colsep) * $#len);

# print table
   foreach my $row ( @{$data} ) {
      my $line = "";
      if (ref $row) {
         my @tmp = ();
         my $last = "";
         
         foreach my $i ( 0 .. $#{$row} ) {
            my $rc  = exists $row->[$i] ? $row->[$i] : " ";
            my $rcs = $rc . (" " x ($len[$i] - length $rc));
            
            if ($rc eq "") {
               $last .= " " x length $colsep if $last;
               $last .= $rcs;
            } else {
               push @tmp, $last if $last;
               push @tmp, $rcs;
               $last = "";
            }
         }
      
         push @tmp, $last if $last;
         
         $line = join $colsep, @tmp;
      } else {
         $line = substr($row . ($linefill x ceil( ($linelength - length $row) / length $linefill )), 0, $linelength)
      }
      
      print $line . "\n";
  }
}
   

sub commandDump {
   # commandDump($cts, $mode);
   #  $mode
   #    -> "shell" gemerate a shell script invoking a number of trbcmd calls
   #    -> "trbcmd" generate a trbcmd script
   #  returns a string containing the script
   my $cts  = shift;
   my $mode = shift;
   
   my $result;
   my $prefix = "";
   $prefix = "trbcmd " if $mode eq 'shell';
   
   $result  = "# CTS Configuration dump\n";
   $result .= "#  generated:        " . time2str('%Y-%m-%d %H:%M', time) . "\n";
   $result .= "#  CTS Compile time: " . time2str('%Y-%m-%d %H:%M', $cts->getTrb()->read(0x40)) . "\n#\n";
   $result .= "# " . $prefix . "Dev.   Reg.   Value\n";
   
   foreach my $reg ( @{$cts->getExportRegisters()} ) {
      my $val = $cts->getRegisters->{$reg}->format();
      my @compact = split /, /, $val->{'_compact'};
      my @ccompact = ();
      my $tmp = "";
      
      foreach my $c (@compact) {
         if (length ($tmp . $c) > 40) {
            push @ccompact, $tmp . ($tmp ? ", ":"") . $c;
            $tmp = "";
         } else {
            $tmp .= ($tmp ? ", " : "") . $c;
         }
      }
      
      push @ccompact, $tmp if ($tmp);
      unshift @ccompact, "" if ($#ccompact > 0); 
      
      $result .= sprintf($prefix . "w 0x%04x 0x%04x 0x%08x  # %s: %s\n", 
         $cts->getTrb()->getEndpoint(),
         $cts->getRegisters->{$reg}->getAddress(),
         $val->{'_raw'},
         $reg,
         join "\n" . (" " x 28) . "# ",  @ccompact
      );
   }
   
   return $result;
}

sub commandList {
   # commandList ($cts);
   #  returns a two-dimensional array compatible to the printTable-format
   my $cts = shift;

   my @keys = sort keys %{$cts->getRegisters};

   my $data = [
      ['Key', 'R/W', 'Module', 'Address', 'Slices'],
      '-'
   ];
   
   my @mods = sort keys %{$cts->getModules};

   my $index = 0;
   $index++ until $mods[$index] eq 'Static';
   
   if ($index) {
      splice(@mods, $index, 1);
      unshift @mods, "Static"
   }

   foreach my $modType (@mods) {
      my $mod = $cts->getModules->{$modType};
      my $modName = "";

      $modName = sprintf("0x%02x - ", $modType) if looks_like_number($modType);
      $modName .= $mod->moduleName;

      foreach my $reg (sort keys %{$mod->getRegisters}) {
         next if substr($reg, 0, 1) eq "_";

         my $slices = join(", ",  @{$cts->getRegisters->{$reg}->getSliceNames});
         $slices = substr($slices, 0, 40) . "..." if length($slices) > 43;

         push @$data, [
            $reg,
            $cts->getRegisters->{$reg}->getAccessMode(),
            $modName,
            sprintf("0x%04x", $cts->getRegisters->{$reg}->getAddress()),
            $slices
         ];
      }
   }
   
   return $data;
}

sub commandRead {
   # commandRead($cts, $keys)
   #  where keys is a string containing a whitespace seperated
   #  list of register names
   #  returns a two-dimensional array compatible to the printTable-format

   my $cts = shift;
   my @keys = @{shift()};
   
   my $data = [
      ['Key', 'Address', 'Value', 'Slice', 'Slice Value'],
      '-'
   ];
   
   foreach my $key (@keys) {
      chomp $key;
      my $reg = $cts->getRegisters->{$key};
      next unless $reg;
      
      $cts->getTrb->addPrefetchRegister($reg);
   }
   
   $cts->getTrb->prefetch();
   
   foreach my $key (@keys) {
      chomp $key;
      next unless $key;
      
      my $reg = $cts->getRegisters->{$key};
      if (defined $reg) {
         my $values = $reg->format();
         
         #print Dumper $values;
         
         my $columns = [
            $key, 
            sprintf("0x%04x", $reg->getAddress()),
            sprintf("0x%08x", $values->{'_raw'})
         ];
         
         foreach my $sliceKey (sort keys %$values) {
            next if substr($sliceKey, 0, 1) eq "_";
            
            push @$columns, $sliceKey;
            push @$columns, $values->{$sliceKey};
            push @$data, $columns;
            
            $columns = ['', '', ''];

         }
      } else {
         push @$data, [$key, 'Key not found'];
      }
   }

   $cts->getTrb->clearPrefetch();

   return $data;
}

sub commandWrite {
   my $cts = shift;
   my @exps = split /,/, shift;
   
   my $values = {};
   
   foreach my $expr (@exps) {
      if ($expr =~ /^\s*([\w\d_]+)(|\.[\w\d_]+)\s*=\s*(.*)\s*$/) {
         my $key   = $1;
         my $slice = $2;
         my $value = $3;

         if ($slice) {
            if (exists $values->{$key} and not ref $values->{$key}) {
               die "Mixing of sliced/unsliced values for same register not allowed";
            
            } elsif (not exists $values->{$key}) {
               $values->{$key} = {};
               
            }
            
            $values->{$key}->{substr $slice, 1} = $value;
         
         } else {
            if (exists $values->{$key} and ref $values->{$key}) {
               die "Mixing of sliced/unsliced values for same register not allowed";
            }
         
            unless(looks_like_number($value)) {
               die "Assignment of non-numeric values is allowed only for compatible sliced registers";
            }
            
            $values->{$key} = $value;
         
         }
      
      } else {
         die ("Invalid expression: $expr");
      }
   }
   
   foreach my $key (keys %$values) {
      $cts->getRegisters->{$key}->write( $values->{$key} );
   }
   
   print "Done.\n";
}

# commandMonitor $cts $config
# where $config is a hash-reference with the following properties
#   dump_dir     Empty, or path to directory in which all results are to
#   interval     Time between two monitoring cycles in milliseconds 
#   quite        If True the output to stdout is strongly reduced
#   log_path     Path to a cvs file in which current rate is dumped
#   log_skip     Number of monitoring cycles to be skipped between two file accesses 
sub commandMonitor {
   my $cts = shift;
   my $config = shift;
   
   my $trb = $cts->getTrb;
   my @rateRegs = ();
   my @slices = ();
   
   my @monRegs = ();
   
   
   my $logSkipCounter = 1;
   
   local $| = 1 if $config->{'quiet'};

# gather all registers and slices that need to be monitored
   $trb->clearPrefetch();
   while ((my $key, my $reg) = each %{ $cts->getRegisters }) {
      next unless $reg->isa( 'TrbRegister' );
   
      if ($reg->getOptions->{'monitorrate'}) {
         $trb->addPrefetchRegister($reg);
         
         if ( scalar keys %{$reg->getDefinitions} == 1 ) {
            push @rateRegs, $key;
            push @slices, @{$reg->getSliceNames()}[0];
         } else {
            while ((my $sliceKey, my $slice) = each %{ $cts->getDefitions }) {
               next unless $slice->{'monitorrate'};
               push @rateRegs, $key;
               push @slices, $sliceKey;
            }
         }
      } elsif ($reg->getOptions->{'monitor'}) {
         $trb->addPrefetchRegister($reg);
         push @monRegs, $key;

      }
   }
   
   @monRegs = sort @monRegs;
   @rateRegs = sort @rateRegs;
   
# write enumration + enviroment into cache
   if ($config->{'dump_dir'}) {
      open FH, ">$config->{'dump_dir'}/enum.js";
      print FH JSON_BIND->new->encode({
         'endpoint'  => sprintf("0x%04x", $trb->getEndpoint()),
         'daqop'     => $ENV{'DAQOPSERVER'},
         'enumCache' => $cts->{'_enumCache'}
      });
      close FH;
   }
   
# monitor !
   my $t0;
   my $rates = {};
   my $lastRead = {};
   
   my $timeOverflow = 1.048576; #s
   my $time = 0;

   my $monData = {};
   
   my $plotData = [];
   
   my $gnuplot_fh = new FileHandle ("|gnuplot");
   if ($gnuplot_fh) {
      $gnuplot_fh->autoflush(1);
      
      print $gnuplot_fh <<"EOF";
set terminal png font "monospace,8" size 450,185
#set font 
set grid
set key 
set autoscale xfixmin
#set yrange [* : *<1000000]
set xlabel "Time since last update [s]"
set ylabel "Rate [Hz]"
EOF
               ;
   }
   
   while (1) {
      my $tab = [
         ['Label', 'Register', 'Address', 'Value'],
         '-'
      ];
      
      # clear screen
      print chr(27) . "[1;1H" . chr(27) . "[2J" unless $config->{'quiet'};
   
      my $read = {};
      $trb->prefetch(1);
      my $pcInterval = $t0 ? tv_interval($t0) : 0;
      $t0 = [gettimeofday];

 # monitoring
      foreach my $regKey (@monRegs) {
         $monData->{$regKey}->{'v'} = $cts->getRegisters->{$regKey}->read();
         $monData->{$regKey}->{'f'} = $cts->getRegisters->{$regKey}->format();
         
         my $reg = $cts->getRegisters->{$regKey};
         my $label = $reg->getOptions->{'label'};
         my @values = split /,\s*/, $monData->{$regKey}->{'f'}{'_compact'};
         
         my @dispValues = (shift @values);
         
         while (my $val = shift @values) {
            if ( length($dispValues[-1]) + length $val < 55 ) {
               $dispValues[-1] .= ', ' . $val;
            } else {
               push @dispValues, $val
            }
         }
         
         push @$tab, [$label, $regKey, sprintf("0x%04x", $reg->getAddress), shift @dispValues];
         
         while (my $val = shift @dispValues) {
            push @$tab, [' ', ' ', ' ', $val];
         }
      }

      unless ($config->{'quiet'}) {
         printTable $tab;
         print "\n";
      }
      
      $tab = [
         ['Label', 'Register', 'Address', 'Rate [1/s]', 'Abs. Value'],
         '-'
      ];
      
 # rates
      foreach my $i (0..$#rateRegs) {
         my $regKey = $rateRegs[$i];
         my $slice =  $slices[$i];
         
        
         my $cur = $read->{$regKey} = $cts->getRegisters->{$regKey}->read(0, 1);
         
         if ($pcInterval) {
            my $last = $lastRead->{$regKey};
            
            my $timeDiff = ($cur->{'time'} - $last->{'time'}) * 1.6e-5;  #s
            my $exactPeriod = $timeDiff + $timeOverflow * sprintf("%.0f", abs($pcInterval - $timeDiff)/$timeOverflow);

            $time += $exactPeriod unless $i;
            
            my $counterDiff = $cur->{'value'}{$slice} - $last->{'value'}{$slice};
            $counterDiff += (1 << $cts->getRegisters->{$regKey}->{'_defs'}{$slice}{'len'}) - 1 if $counterDiff < 0;
            
            my $rate = $counterDiff / $exactPeriod;
            
            $rates->{$regKey . '.' . $slice} = {
               'rate' => sprintf("%.2f", $rate) + 0.0,     # add 0 to numifying value,  
               'value' => $cur->{'value'}{$slice} + 0.0    # i.e. prevent escape in json
            };
            
            my $label = $cts->getRegisters->{$regKey}->getOptions->{'label'};
            $label = $regKey unless $label;
            
            $rate = sprintf("%.2f", $rate);
            $rate = " " x (12 - length($rate)) . $rate;
            
            my $value = " " x (12 - length($cur->{'value'}{$slice})) . $cur->{'value'}{$slice};

            push @$tab, [$label, $regKey, 
               sprintf("0x%04x", $cts->getRegisters->{$regKey}->getAddress),
               $rate , $value];
         }
      }
      
      printTable $tab unless $config->{'quiet'};
      
      if ($config->{'dump_dir'}) {
      # store json
         my $json = JSON_BIND->new->encode({
            'time' => $time,
            'servertime' => time2str('%Y-%m-%d %H:%M', time),
            'interval' => $config->{'interval'},
            'endpoint' => $trb->getEndpoint,
            'rates' => $rates,
            'monitor' => $monData
         });

         open FH, ">$config->{'dump_dir'}/dump.js";
         syswrite FH, $json;
         close FH;

      # generate plot
         if ($gnuplot_fh) {
            shift @$plotData if $#{ $plotData } > 180;
            push @$plotData, [
               $time,
               $rates->{'cts_cnt_trg_asserted.value'}{'rate'},
               $rates->{'cts_cnt_trg_edges.value'}{'rate'},
               $rates->{'cts_cnt_trg_accepted.value'}{'rate'}
            ] if $rates->{'cts_cnt_trg_asserted.value'};

            if ($#{ $plotData } > 4) {
               open FH, ">$config->{'dump_dir'}/plot.data";
               foreach (@{$plotData}) {
                  my @row = (@{ $_ });
                  $row[0] -= $plotData->[-1][0];
                  print FH (join "  ", @row) . "\n";
               }
               close FH;

               # First plot into a different file and the issue a move command,
               # in order to reduce the number of accesses from the webserver to
               # a corrupt image file (works quite well !)
               print $gnuplot_fh <<"EOF"
set xrange [*:0]
set output "$config->{'dump_dir'}/_tmp_plot.png"
plot \\
"$config->{'dump_dir'}/plot.data" using 1:3:(\$3 / 1000) with yerrorlines title "Edges", \\
"$config->{'dump_dir'}/plot.data" using 1:4:(\$4 / 1000) with yerrorlines title "Accepted"

set xrange [-5:0]
set output "$config->{'dump_dir'}/_tmp_plotshort.png"
plot \\
"$config->{'dump_dir'}/plot.data" using 1:3:(\$3 / 1000) with yerrorlines title "Edges", \\
"$config->{'dump_dir'}/plot.data" using 1:4:(\$4 / 1000) with yerrorlines title "Accepted"

EOF
;
               rename "$config->{'dump_dir'}/_tmp_plot.png",      "$config->{'dump_dir'}/plot.png";
               rename "$config->{'dump_dir'}/_tmp_plotshort.png", "$config->{'dump_dir'}/plotshort.png";

               print ($config->{'quiet'} ? "." : "Plot produced\n");
            } else {
               print "Plotting delayed as too few points captured yet\n";
            }
         }
      }
      
      if (0 == $logSkipCounter and $config->{'log_path'}) {
         my $new_file = not (-e $config->{'log_path'});  # True if log file does not exists (yet)
         my $log_fh = new FileHandle (">>$config->{'log_path'}");
         if ($log_fh) {
            print $log_fh "Timestamp,Trigger Asserted,Trigger Rising Edges,Trigger Accepted\n" if $new_file;
            print $log_fh sprintf("%d,%.1f,%.1f,%.1f\n", 
               scalar time,
               $rates->{'cts_cnt_trg_asserted.value'}{'rate'},
               $rates->{'cts_cnt_trg_edges.value'}{'rate'},
               $rates->{'cts_cnt_trg_accepted.value'}{'rate'}
            );
         }
         close $log_fh;
         $logSkipCounter = $config->{'log_skip'};
      } else {
         $logSkipCounter--;
      }
      
      $lastRead = $read;
      usleep($config->{'interval'}*1e3);
   }
}

1;
