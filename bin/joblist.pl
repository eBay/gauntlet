#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog \nhelp: $prog -h";


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";


$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sql="select id, owner, audit, hostgroup, started from jobs order by id desc";
$sth=$dbh->do($sql);


my $rs = $dbh->selectall_arrayref($sql);
my $count = 0;

printf("%5s %15s %25s %20s %25s\n", "ID", "owner", "audit", "hostgroup", "started");

foreach my $myRow (@$rs) {
        #print $$myRow[0], "\t", $$myRow[1], "\t", $$myRow[2], "\t", $$myRow[3], "\t", $$myRow[4], "\n";
        printf("%5s %15s %25s %20s %25s\n", $$myRow[0], $$myRow[1], $$myRow[2], $$myRow[3], $$myRow[4]);
        $count++;
}
$dbh->disconnect();
print "Total: $count\n";


