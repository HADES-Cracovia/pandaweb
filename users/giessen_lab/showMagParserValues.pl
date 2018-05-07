#!/usr/bin/perl
use HADES::TrbNet;
use Data::Dumper;

use constant false => 0;
use constant true  => 1;

##########################################
#variables
##########################################
my $boardAddress = 0x0201;
my $numberOfBoards = 1;
my $numberOfSensors = 4;
my $secondsToWaitBeforeNextPrint = 3;
my $writeToFile = false;
my $filename = "output.txt";

##########################################
#functions
##########################################
#show output in a nice formattet format on the screen and 
#optional also write it to a file.
sub printNice {
  while(1) {
    #loop over all boards
    foreach my $board (1..$numberOfBoards) {
      my $serialNumber = trb_register_read($boardAddress,0xe000 + $board);
      print "Serial Number: $serialNumber->{$boardAddress}\n\n";
      if ($writeToFile) {
        print $fh "Serial Number: $serialNumber->{$boardAddress}\n\n";
      }
    
      #loop over all sensors on each board
      foreach my $sensorNo (0..$numberOfSensors - 1) {
        print "Sensor $sensorNo\n";
        if ($writeToFile) {
          print $fh "Sensor $sensorNo\n";
        }
      
        my $temperature = trb_register_read($boardAddress, 
          (0xe000 + ($board * 16) + ($sensorNo * $numberOfSensors)));
        my $temperaturVorzeichen = $temperature->{$boardAddress} >> 27;
        my $temperatureValue = $temperature->{$boardAddress}/100;
        if ($temperaturVorzeichen > 0) {
          $temperatureValue = $temperatureValue * (-1);
        }
        print "Temperatur: $temperatureValue\n";
        if ($writeToFile) {
          print $fh "Temperatur: $temperatureValue\n";
        }
      
        my $xAxis = trb_register_read($boardAddress,
          (0xe000 + ($board * 16) + ($sensorNo * $numberOfSensors + 1)));
        my $xAxisVorzeichen = $xAxis->{$boardAddress} >> 27;
        my $xAxisValue = ($xAxis->{$boardAddress} & 
          0b111111111111111111111111111)/1000;
        if ($xAxisVorzeichen > 0) {
          $xAxisValue = $xAxisValue * (-1);
        }
        print "X-Axis: $xAxisValue\n";
        if ($writeToFile) {
          print $fh "X-Axis: $xAxisValue\n";
        }

        my $yAxis = trb_register_read($boardAddress, 
          (0xe000 + ($board * 16) + ($sensorNo * $numberOfSensors + 2)));
        my $yAxisVorzeichen = $yAxis->{$boardAddress} >> 27;
        my $yAxisValue = ($yAxis->{$boardAddress} & 
          0b111111111111111111111111111)/1000;
        if ($yAxisVorzeichen > 0) {
          $yAxisValue = $yAxisValue * (-1);
        }
        print "Y-Axis: $yAxisValue\n";
        if ($writeToFile) {
          print "Y-Axis: $yAxisValue\n";
        }
      
        my $zAxis = trb_register_read($boardAddress, 
          (0xe000 + ($board * 16) + ($sensorNo * $numberOfSensors + 3)));
        my $zAxisVorzeichen = $zAxis->{$boardAddress} >> 27;
        my $zAxisValue = ($zAxis->{$boardAddress} & 
          0b11111111111111111111111111)/1000;
        if ($zAxisVorzeichen > 0) {
          $zAxisValue = $zAxisValue * (-1);
        }
        print "Z-Axis: $zAxisValue\n\n";
        if ($writeToFile) {
          print "Z-Axis: $zAxisValue\n\n";
        }
      }
      print "#########################\n\n";
      if ($writeToFile) {
        print "#########################\n\n";
      }
    }  
  
    #wait before next print
    sleep($secondsToWaitBeforeNextPrint);
  }
}

#show output the way it comes from the microcontroller and 
#optional also write it to a file.
sub printOneLine {
  while(1) {
    #loop over all boards
    foreach my $board (1..$numberOfBoards) {
      my $serialNumber = trb_register_read($boardAddress,0xe000 + $board);
    
      #loop over all sensors on each board
      foreach my $sensorNo (0..$numberOfSensors - 1) {
        
        #loop over all axis of each sensor (T, X, Y, Z)
        foreach my $axis (0..3) {
          printf("M_%02d_%01d_", $serialNumber->{$boardAddress},$sensorNo);
          if ($writeToFile) {
            printf("M_%02d_$sensorNo_", $serialNumber->{$boardAddress});
          }
        
          if ($axis == 0) {
            print "T ";
            if ($writeToFile) {
              print "T ";
            }
          } elsif ($axis == 1) {
            print "X ";
            if ($writeToFile) {
              print "X ";
            }
          } elsif ($axis == 2) {
            print "Y ";
            if ($writeToFile) {
              print "Y ";
            }
          } elsif ($axis == 3) {
            print "Z ";
            if ($writeToFile) {
              print "Z ";
            }
          }
          my $value = trb_register_read($boardAddress, 
            (0xe000 + ($board * 16) + ($sensorNo * $numberOfSensors + $axis)));
          my $sign = ($value->{$boardAddress} >> 27) & 0x1;
          $value = ($value->{$boardAddress} & 0b11111111111111111111111111)/100;
          if ($sign > 0) {
            $value = $value * (-1);
          }
          if ($axis > 0) {
            $value = $value/10;
            printf("%.3f\n", $value);
            if ($writeToFile) {
              printf("%.3f\n", $value);
            }
          } else {
            printf("%.2f\n", $value);
            if ($writeToFile) {
              printf("%.2f\n", $value);
            }
          }
        }
      }
    }

    #wait before next print
    sleep($secondsToWaitBeforeNextPrint);
  }
}


##########################################
#main
##########################################

#first init ports
trb_init_ports() or die trb_strerror();

#output: clock 
my $clock = trb_register_read($boardAddress,0xe000);
my $clockValue = 10000000/$clock;
print "Clock: $clock->{$boardAddress}\n\n";
if ($writeToFile) {
  open(my $fh, '>', $filename) or die "Could not open file '$filename' $!";
  print $fh "Clock: $clock->{$boardAddress}\n\n";
}

#print depending on console argument
if ($ARGV[0] eq "nice") {
  printNice();
} else {
  printOneLine();
}
