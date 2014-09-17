#!/usr/bin/perl
use warnings;
use strict;
use Data::Dumper;
use MIME::Base64;
my $PATH  = "";
if ($ENV{'SERVER_SOFTWARE'} =~ /HTTPi/i) {
  print "HTTP/1.0 200 OK\n";
  print "Expires: Thu, 01 Dec 1994 16:00:00 GMT\r\n";
  print "Content-type: text/html\r\n\r\n";
  $PATH = "htdocs/dmon/";
  }
else {
  print "Expires: Thu, 01 Dec 1994 16:00:00 GMT\r\n";
  print "Content-type: text/html\n\n";
  }

my @args = split('-',$ENV{'QUERY_STRING'});

sub addpng {
  my ($file) = @_;
  my $out = "data:image/png;base64,";
  open (my $fh, "<$PATH$file");
  
  local $/;
  my $bin = <$fh>;
  $fh->close();
  $/='\n';
  $out .= encode_base64($bin);
  chomp $out;
  return $out;
  }

sub addfile {
	my ($file,$strip) = @_;
	my $MYF;
	$strip = 0 unless defined $strip;
	my $str = "";
	open ($MYF, "<$file") or return "";
	while (<$MYF>){
# 	  print $_;
		if ($_ =~ m%ADDFILE\s([/\w]*).svg%) {
	    $str .= addfile("$PATH$1.svg",1);
			}
		elsif  ($_ =~ m!^(.*)\%ADDPNG\s+(.+)\%(.*)$!) {
      $str .= $1;
      $str .= addpng($2);
      $str .= $3;
      }
		else {
			$_ =~ s/\t*/ /;
		  if($_ =~ m/^$/) {next;}
		  if($strip==1) {
		    $_ =~ s/<svg/<svg preserveAspectRatio="XMidYMid" /;
		    if($_ =~ m/<\?/) {next;}
		    if($_ =~ m/<!/) {next;}
		    if($_ =~ m/.dtd/) {next;}
				}
# 			my $r = int(rand(1000));
# 			$_ =~ s/(getpic.cgi\?[^"]+)"/$1-$r"/;
			$str .= $_;
			}
		}
	return $str;
      }



my $out;
	$out .= addfile($PATH."note.htt");
	foreach my $arg (@args) {
		if ($arg =~ m/(\w+)/) {
# 			$out .= $arg;
			$out .= addfile($PATH."$1.htt");
			}
		}
			
print $out;
		