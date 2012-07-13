#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

#$usage="usage: $prog -h <hostname> -d <domain> \nhelp: $prog -h";

#getopts('h:d:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

#unless ($opt_h && $opt_d) {
#  print "$usage\n";
#  exit 1;
#}

# successful audits
# select count(*) from tasks where status = 'completed' and audit = 'read-only-root-fs'

$sql="select hostname, domain, result from tasks where status = 'failed' and audit = 'read-only-root-fs'";
$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sth=$dbh->do($sql);


my $rs = $dbh->selectall_arrayref($sql);

foreach my $myRow (@$rs) {
	print $$myRow[0], ".", $$myRow[1], " failed with error: ", $$myRow[2];
}
$dbh->disconnect();

