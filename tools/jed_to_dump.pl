#!/usr/bin/perl

use Modern::Perl;
use FileHandle;

my $inputFilename;
my $outputFilename;

if( not defined $ARGV[0] ) {
  say "Argument missing. Please pass the JEDEC (*.jed) file as first argument.";
  say "Usage: ./jed_to_dump.pl inputfile [outputfile]";
  exit;
}

if( @ARGV > 2 ) {
  say "To much arguments";
  exit;
}

if ( $ARGV[0] =~ /\.jed$/ ) {
  $inputFilename = $ARGV[0];
} else {
  say "Please pass the JEDEC (*.jed) file as first argument.";
  exit;
}

if( defined $ARGV[1] ) {
  $outputFilename = $ARGV[1];
  if( ! ( $outputFilename =~ /.dump/ ) ) {
    $outputFilename .= ".dump";
  }
} else {
  $outputFilename = $inputFilename;
  $outputFilename =~  s/\.jed/\.dump/;
}

open my $fh, ">", $outputFilename or die "Output $outputFilename file can't be created: $!";

while (<>) {
  state $lineNumber = 0;
  if ( /^[01]/ ) {
    my $completeHexString = unpack( "H32", pack( "B*", $_ ) );
    my @hexArray; 
    @hexArray = unpack( "A2" x (length($completeHexString)/2), $completeHexString);
    printf $fh "0x" . "%04x" . ":\t ", $lineNumber;
    $lineNumber++;
    local $" = "  ";
    printf $fh "@hexArray \n";
  } else {
    if ( /NOTE TAG DATA\*/ ) {
      say "$inputFilename successfuly converted to $outputFilename.";
      last; # last interation in while loop;
    }
  }
}

close $fh;

exit;
