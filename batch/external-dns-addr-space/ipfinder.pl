#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating ip reputation DB
# Copyright (c) 2011 Adam Beeman and eBay, Inc.

use DBI;
use File::Basename;
use GauntletConfig;


# database information
$connectionInfo="DBI:mysql:database=$iprepdb;$iprepdhost:3306";




foreach my $line (<>) {
	next if ($line =~ /^;/); # skip comments
	if ($line =~ /(\S+)\s+IN\s+A\s+(\S+\.\S+\.\S+\.\S+)/) {
		my $ip = $2; 
		next if ($ip =~ /^10\./); # skip 10.* internal addresses
		next if ($ip =~ /^192.168\./); # skip 192.168 internal addresses
		$ipaddrs{$ip} = 1;
	}
	# www                     A       72.3.243.237
	elsif ($line =~ /(\S+)\s+A\s+(\S+\.\S+\.\S+\.\S+)/) {
		my $ip = $2; 
		next if ($ip =~ /^10\./); # skip 10.* internal addresses
		next if ($ip =~ /^192.168\./); # skip 192.168 internal addresses
		$ipaddrs{$ip} = 1;
	}
}



@ipaddrs = sort(keys(%ipaddrs));
my $nrecs = $#ipaddrs + 1;
print "Found $nrecs A records, adding to IP rep DB...\n";
$dbh=DBI->connect($connectionInfo,$iprepuser,$ipreppass);

foreach my $ip (@ipaddrs) {
	$sql="insert into addresses (ipaddr) values ".  "('$ip' )";
	$sth=$dbh->do($sql);
}

print "Done\n";

