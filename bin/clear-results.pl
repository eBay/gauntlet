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

$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sql="delete from tasks where hostname=" . $dbh->quote($opt_h) . " and domain="
	. $dbh->quote($opt_d);
$sth=$dbh->do($sql);

print "Number of rows removed: $sth\n";
