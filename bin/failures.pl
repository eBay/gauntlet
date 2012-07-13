#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -a <audit> [-d <domain>] \nhelp: $prog -h";

getopts('a:d:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

unless ($opt_a) {
  print "$usage\n";
  exit 1;
}

# successful audits
# select count(*) from tasks where status = 'completed' and audit = 'read-only-root-fs'

$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);

print "Gauntlet Failure Report for audit: $opt_a " .
	($opt_d ? "in domain: $opt_d " : '' ) .  "\n\n\n";
$sql="select hostname, domain, result from tasks where status = 'failed' " .
	($opt_d ?  "and domain='" . $opt_d . "'" : '' ) . " and audit = " 
	. $dbh->quote("$opt_a");
print "SQL: $sql\n" if ($DEBUG);
$sth=$dbh->do($sql);


my $rs = $dbh->selectall_arrayref($sql);

my $count = 0;

foreach my $myRow (@$rs) {
        print $$myRow[0], ".", $$myRow[1], " failed with error: ", $$myRow[2], "\n";
	$count++;
}
$dbh->disconnect();
print "Total: $count\n";

