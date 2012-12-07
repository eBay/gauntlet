#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog\nhelp: $prog -h";



# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";


$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sql="delete from hostgroups where hostgroup like 'all_os%'";
$sth=$dbh->do($sql);

print "Number of rows removed: $sth\n";
