#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;
use TaskMan;

$prog=basename($0);

$usage="usage: $prog -h <hostname> -d <domain> \nhelp: $prog -h";

getopts('h:d:');


unless ($opt_h && $opt_d) {
  print "$usage\n";
  exit 1;
}

getHostOverrides($opt_h, $opt_d);
