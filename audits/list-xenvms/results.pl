#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -j <jobid> \nhelp: $prog -h";

getopts('j:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

chomp $opt_j;

unless ($opt_j) {
  print "$usage\n";
  exit 1;
}


# successful audits
# select count(*) from tasks where status = 'completed' and audit = 'read-only-root-fs'

$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sql="select result from tasks where jobid = \?"; 
$sth=$dbh->prepare($sql);
$sth->execute($opt_j);

while ( my $row = $sth->fetchrow_arrayref ) {
	next unless ($$row[0]);
	print $$row[0], "\n";
}

$dbh->disconnect();


