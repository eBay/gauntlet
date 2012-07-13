#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog [-r] -f <frequency>\nfrequency can be one of: 'min',  '5min',  '15min',  '30min',  '1hr',  '2hr',  '4hr',  '8hr',  '12hr',  'day',  '2day',  '7day',  'month'\nWill only run the jobs if -r option is included, otherwise just prints them\n";

getopts('rf:');

unless ($opt_f ) {
  print "$usage\n";
  exit 1;
}


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";


$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sql="select id, owner, command from schedule where frequency = '$opt_f'";
$sth=$dbh->do($sql);

my $rs = $dbh->selectall_arrayref($sql);
my $count = 0;

printf("%5s %15s %25s\n", "ID", "owner", "command");

foreach my $myRow (@$rs) {
        printf("%5s %15s %25s\n", $$myRow[0], $$myRow[1], $$myRow[2]); 
	print `$$myRow[2]` if ($opt_r);
        $count++;
}
$dbh->disconnect();
print "Total: $count\n";


