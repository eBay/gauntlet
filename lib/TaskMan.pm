#!/usr/bin/perl -I /ebay/gauntlet/lib
# Copyright (c) 2011 Adam Beeman and eBay, Inc.

# This module contains all the Task Management related functions
# hence the name TaskMan.

use DBI;
use GauntletConfig;


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";
$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);

# db columns in "hosts" table
# hostname
# domain
# sshkey
# altuser
# active [boolean]
# sudo [boolean]

# table tasks:
# hostname
# domain
# audit
# result
# enabled [boolean]
# started [date/time]
# completed [date/time]
# status [ready|running|failed|completed]

sub addHost {
	my $hostname = shift;
	my $domain = shift;
	my $sshkey = shift; 
	my $sql="insert into tasks (hostname, domain, sshkey, active) values ".  "('$hostname', '$domain', '$sshkey', 1)";
	$sth=$dbh->do($sql);
}


sub addTask {
	my $hostname = shift;
	my $domain = shift;
	my $audit = shift; 
	my $sql="insert into tasks (hostname, domain, audit, enabled) values ".  "('$hostname', '$domain', '$audit', 1)";
	$sth=$dbh->do($sql);
}

sub scheduleTasks {
	$audit = shift;
	my $sql = "select * from tasks where audit = '$audit'";
	my $sth=$dbh->do($sql);
	while ( my $ref = $sth->fetchrow_hashref ) {
		# we will drop stuff into the run queue, for now just print
		print $$ref{'audit'} . " " .  $$ref{'hostname'} . " " . $$ref{'domain'} . "\n";
	}
}

sub getHostOverrides {
	my $hostname = shift;
	my $domain = shift;
	print "GHO: h = $hostname , d = $domain\n" if ($DEBUG);
	my $sql = "select * from hosts where hostname='$hostname' and domain='$domain'";
	my $ref = $dbh->selectrow_hashref($sql . " LIMIT 1");
	if ($$ref{'sshkey'}) {
		$ssh_key = "-i " . $gauntlet_base . "/keys/" . $$ref{'sshkey'};
	} elsif ($domain_keys{"$domain"}) {
		print "using domain key for $domain\n" if ($DEBUG);
		$ssh_key = " -i " . $gauntlet_base . "/keys/" . join(" -i " . $gauntlet_base . "/keys/",  @{ $domain_keys{$domain} });
	}
	if ($$ref{'altuser'}) {
		$ssh_user = $$ref{'altuser'};
	} 
	if ($$ref{'passfile'}) {
		$passfile = $$ref{'passfile'};
	}
	print "ssh_key = $ssh_key\n" if ($DEBUG);
}


1;

