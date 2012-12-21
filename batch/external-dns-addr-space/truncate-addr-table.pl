#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -y \nhelp: $prog -h";

getopts('y');


# database information
$connectionInfo="DBI:mysql:database=$iprepdb;$iprepdhost:3306";

unless ($opt_y ) {
  print "$usage\n";
  exit 1;
}

$sql="delete from addresses";
$dbh=DBI->connect($connectionInfo,$iprepuser,$ipreppass);
$sth=$dbh->do($sql);

