#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);



# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

# successful audits

$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sql="select distinct hostgroup from hostgroups"; 
$sth=$dbh->do($sql);


my $rs = $dbh->selectall_arrayref($sql);
#my $count = 0;

foreach my $myRow (@$rs) {
        print $$myRow[0], "\n";
#        $count++;
}
$dbh->disconnect();
#print "Total: $count\n";


