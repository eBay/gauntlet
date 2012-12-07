#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -g <hostgroup> \nhelp: $prog -h";

getopts('g:');


unless ($opt_g) {
  print "$usage\n";
  exit 1;
}



# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";


$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sql="delete from hostgroups where hostgroup = " . $dbh->quote($opt_g);
$sth=$dbh->do($sql);

print "Number of rows removed: $sth\n";
