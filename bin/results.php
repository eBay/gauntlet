<?php
header ("Content-type:", "text/csv");


?>
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

print "Content-type: text/csv\n\n\n";

$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
$sql="select hostname, domain, audit, status, result from tasks where jobid = \? INTO OUTFILE '$gauntlet_base/html/csv/$opt_j.csv' FIELDS TERMINATED BY ',' ENCLOSED BY '\"' LINES TERMINATED BY '\n'";
$sth=$dbh->prepare($sql);
$sth->execute($opt_j);

#while ( my $row = $sth->fetchrow_arrayref ) {
#	print join( ",", @$row ), "\n";
#}

$dbh->disconnect();
print `cat $gauntlet_base/html/csv/$opt_j.csv`;


