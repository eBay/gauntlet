#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for scheduling gauntlet jobs
# Copyright (c) 2012 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

#$DEBUG = 1;

$prog=basename($0);

$usage="usage: $prog -a <audit> -b|-g <hostgroup> [-w <when>][-d <description>][-o <owner>]\nhelp: $prog -h\n<when> can be of the form: 'nowonly', 'sequential',   'min',  '5min',  '15min',  '30min',  '1hr',  '2hr',  '4hr',  '8hr',  '12hr',  'day',  '2day',  '7day',  'month'\nuse -b for batch jobs and -g <hostgroup> for group jobs\n";

getopts('a:bg:o:d:w:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

unless ($opt_a && $opt_g || $opt_a && $opt_b) {
  print "$usage\n";
  exit 1;
}

if ($opt_b && ! $opt_g) {
	$dir = "batch";
} else {
	$dir = "audits";
}
if (! -d "$gauntlet_base/$dir/$opt_a" ) {
  print "No such audit: $opt_a\n";
  exit 2;
}

$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);

# gather essential info
if (! $opt_o) {
	$opt_o = getlogin();
}

if ($opt_w && $opt_w ne "nowonly" && $opt_w ne "sequential") {
	if ($opt_b && ! $opt_g) {
		$sql="insert into schedule (owner, frequency, command, description) values ".  "('$opt_o', '$opt_w', '$gauntlet_base/bin/queue-job.pl -b -a $opt_a -o $opt_o', '$opt_d')";
	} else {
		$sql="insert into schedule (owner, frequency, command, description) values ".  "('$opt_o', '$opt_w', '$gauntlet_base/bin/queue-job.pl -g $opt_g -a $opt_a -o $opt_o', '$opt_d')";
	}
	my $sth = $dbh->prepare($sql);

	$sth->execute or die "Can't Add record : $dbh->errstr";
	$new_id = $sth->{mysql_insertid};
	print "$opt_o scheduled job: $new_id\n";
	exit 0 if ($new_id);
	exit 1;
}

#  batch jobs get scheduled a little differently from audits
if ($opt_b && ! $opt_g) {
	$sql="insert into jobs (owner, audit, hostgroup) values ".  "('$opt_o', '$opt_a', 'batch-job')";
	my $sth = $dbh->prepare($sql);
$sth->execute or
   	die "Can't Add record : $dbh->errstr";
	$new_id = $sth->{mysql_insertid};
	print "$opt_o created job: $new_id\n";
        $sql="insert into tasks (jobid, hostname, domain, audit, status) values ".  "('$new_id', 'batch-job', 'batch-job', '$opt_a', 'scheduled')";
        my $sth=$dbh->do($sql);

        print "adding to run list: job-${new_id}:${opt_a}:batch-job:batch-job\n" if ($DEBUG);
        `echo "$gauntlet_base/batch/${opt_a}/batch_job" > $gauntlet_base/spool/unassigned/job-${new_id}:${opt_a}:batch-job:batch-job`;
	exit 0;
}
$sql="insert into jobs (owner, audit, hostgroup) values ".  "('$opt_o', '$opt_a', '$opt_g')";
my $sth = $dbh->prepare($sql);
$sth->execute or 
   die "Can't Add record : $dbh->errstr";
$new_id = $sth->{mysql_insertid};
print "$opt_o created job: $new_id\n";
# attempting to start worker threads as another user doesn't work well.
#`$gauntlet_base/bin/startworkers.sh >> $gauntlet_base/logs/workers.log 2>&1`;

$sql="select distinct hostname from hostgroups where hostgroup = \"$opt_g\"";
$sth=$dbh->prepare($sql);
$sth->execute();
# retrieve the values returned from executing your SQL statement
my $seqdata;
while (@data = $sth->fetchrow_array()) {
	my $fqdn = $data[0];
	# print your table rows
	print "$fqdn\n" if ($DEBUG);
	my ($hostname, $domain) = split('\.', $fqdn,  2);

	$sql="insert into tasks (jobid, hostname, domain, audit, status) values ".  "('$new_id', '$hostname', '$domain', '$opt_a', 'scheduled')";
	my $sth=$dbh->do($sql);

	print "adding to run list: job-${new_id}:${opt_a}:${hostname}:${domain}\n" if ($DEBUG);

	if ($opt_w ne "sequential") {
		`echo "$gauntlet_base/audits/${opt_a}/audit_host $hostname.$domain" > $gauntlet_base/spool/unassigned/job-${new_id}:${opt_a}:${hostname}:${domain}`;
	} else {
		$seqdata .= "$gauntlet_base/audits/${opt_a}/audit_host $hostname.$domain \n sleep 5\n";
	}
}
if ($opt_w eq "sequential") {
	`echo \"$seqdata\" > $gauntlet_base/spool/unassigned/job-${new_id}:${opt_a}:sequential`; 
}
	
	
	


