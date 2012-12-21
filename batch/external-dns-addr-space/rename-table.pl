#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog <oldname> <newname>\nhelp: $prog -h";



# database information
$connectionInfo="DBI:mysql:database=$iprepdb;$iprepdhost:3306";

$oldt = shift;
$newt = shift;
chomp $newt;

unless ($newt) {
  print "$usage\n";
  exit 1;
}

$sql="RENAME TABLE $oldt TO $newt";
$dbh=DBI->connect($connectionInfo,$iprepuser,$ipreppass);
$sth=$dbh->do($sql);

