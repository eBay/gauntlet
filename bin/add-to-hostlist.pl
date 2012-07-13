#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -h <fully_qualified_hostname> -g <hostgroup> \nhelp: $prog -h";

getopts('h:g:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

unless ($opt_h && $opt_g) {
  print "$usage\n";
  exit 1;
}

$sql="insert into hostgroups (hostname, hostgroup) values ".  "('$opt_h', '$opt_g')";
$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sth=$dbh->do($sql);

