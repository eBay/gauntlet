#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -h <hostname> -d <domain> \nhelp: $prog -h";

getopts('h:d:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

unless ($opt_h && $opt_d) {
  print "$usage\n";
  exit 1;
}

$sql="insert into hosts (hostname, domain, altuser) values ".  "('$opt_h', '$opt_d', 'ebayroot')";
$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sth=$dbh->do($sql);

