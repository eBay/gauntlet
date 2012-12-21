#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -i <ip> \nhelp: $prog -h";

getopts('i:');


# database information
$connectionInfo="DBI:mysql:database=$iprepdb;$iprepdhost:3306";

unless ($opt_i ) {
  print "$usage\n";
  exit 1;
}

$sql="insert into addresses (ipaddr) values ".  "('$opt_i' )";
$dbh=DBI->connect($connectionInfo,$iprepuser,$ipreppass);
$sth=$dbh->do($sql);

