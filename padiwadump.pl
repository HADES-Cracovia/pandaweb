#!/usr/bin/perl

if($ARGV[0] eq "") {
  die "Requires four hex digit network address of board to dump";
	}

system("./cts/htdocs/commands/getpadiwa.pl ".$ARGV[0]." threshdump")
