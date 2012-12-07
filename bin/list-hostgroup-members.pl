#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -g <hostlist>\nhelp: $prog -h";

getopts('g:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

unless ($opt_g) {
  print "$usage\n";
  exit 1;
}

# successful audits

$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sql="select hostname from hostgroups where hostgroup = " . $dbh->quote("$opt_g");
$sth=$dbh->do($sql);


my $rs = $dbh->selectall_arrayref($sql);
#my $count = 0;

foreach my $myRow (@$rs) {
        print $$myRow[0], "\n";
#        $count++;
}
$dbh->disconnect();
#print "Total: $count\n";


