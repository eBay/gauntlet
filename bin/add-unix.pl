#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -h <hostname> [-a <altuser>] [-p <passfile>] \nhelp: $prog -h";

getopts('h:d:a:p:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

unless ($opt_h) {
  print "$usage\n";
  exit 1;
}

($host, $domain) = split('\.', $opt_h, 2);

print "host: $host, domain: $domain\n";

if ($opt_a && $opt_p) {
	$sql="insert into hosts (hostname, domain, altuser, passfile) values " . 
	 "('$host', '$domain', '$opt_a', '$opt_p')";
} elsif ($opt_a) {
	$sql="insert into hosts (hostname, domain, altuser) values ".
	 "('$host', '$domain', '$opt_a')";
} else {
	$sql="insert into hosts (hostname, domain) values ".  "('$host', '$domain')";
}
$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sth=$dbh->do($sql);

