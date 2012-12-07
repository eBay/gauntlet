#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2012 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);


# this program uses results from a previous job to create a new hostgroup
# the new hostgroup can be all hosts that passed or failed the previous job
# it can also search for hosts which printed a particular message in the result


$usage="usage: $prog -j <jobid> -g <hostgroup> {-p|-f} [-m <message>]
-p: include hosts that passed
-f: include hosts that failed
-m <message>: include hosts that contain <message> in the result field
help: $prog -h";

getopts('j:g:pfm:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

unless ($opt_j && $opt_g) {
  print "$usage\n";
  exit 1;
}


# you have to use -p or -f but not both
if ($opt_p && $opt_f || (! $opt_p && ! $opt_f)) {
  print "$usage\n";
  exit 1;
}

$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);

$sql="select hostname, domain, audit, status, result from tasks where jobid = '$opt_j' " .
	($opt_p ? "and status = 'completed' " : '') .
	($opt_f ? "and status = 'failed' " : '') .
	($opt_m ? "and result like '%" . $opt_m . "%' " : '');
#print $sql, "\n";
#$sth=$dbh->prepare($sql);
#$sth->execute($opt_j);

$sth=$dbh->do($sql);


my $rs = $dbh->selectall_arrayref($sql);
my $count = 0;

foreach my $myRow (@$rs) {
        print $$myRow[0], ".", $$myRow[1], " completed with result: ", $$myRow[4], "\n";
	push(@hosts, $$myRow[0] . "." . $$myRow[1]);
        $count++;
}
print "Total: $count\n";

foreach $host (@hosts) {
	$sql="insert into hostgroups (hostname, hostgroup) values ".  "('$host', '$opt_g')";
	#print $sql, "\n";
	$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
	$sth=$dbh->do($sql);
}


