#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating ip rep host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;
use Net::CIDR::Lite;

$prog=basename($0);

$usage="usage:\n$prog -i <ip>\n$prog -a\n$prog -u\nhelp: $prog -h";

getopts('aui:');

#$DEBUG = 1;

# build a list of known eBay address blocks
my %networks;

#my $cidr = Net::CIDR::Lite->new;
#$cidr->add("192.168.0.0/16");
#$cidr->add("212.222.51.0/24");
#$cidr->add("212.222.52.0/24");
#$cidr->add_range("66.135.192.0 - 66.135.223.255");
#$cidr->add_range("208.14.218.16 - 208.14.218.31");

# non-routed subnets
$unrouted = Net::CIDR::Lite->new;
$unrouted->add("10.0.0.0/8");
$unrouted->add("192.168.0.0/16");

$networks{'unrouted'} = $unrouted;

# SJC/EXDS/SC5
my $sjc = Net::CIDR::Lite->new;
$sjc->add("64.68.78.0/23");
$sjc->add("216.33.244.0/24");
$sjc->add("209.1.128.0/24");
$sjc->add("216.33.16.0/22");
$sjc->add("216.32.252.0/23"); 	# Exodus
$sjc->add("216.33.252.0/23"); 	# Exodus
$sjc->add("208.184.252.0/22");	# AboveNet
$sjc->add("208.185.220.0/22");	# AboveNet
$sjc->add("67.72.12.0/22"); 	# Level3
$sjc->add("216.113.160.0/20");	# SC5, QATE, etc.

$networks{'sjc'} = $sjc;


# SLC
my $slc = Net::CIDR::Lite->new;
$slc->add("208.14.218.16/28"); # Sprint
$slc->add("208.34.52.0/22"); # Sprint

$networks{'slc'} = $slc;

# Asia PAC
my $asia = Net::CIDR::Lite->new;
$asia->add("202.76.240.0/21");
$networks{'asia'} = $asia;

# Europe
my $ripe = Net::CIDR::Lite->new;
$ripe->add("93.94.40.0/21");
$networks{'europe'} = $ripe;

# SNV (Sunnyvale)
my $snv = Net::CIDR::Lite->new;
$snv->add("66.135.192.0/19"); # only using /20
$networks{'snv'} = $snv;

# PHX
my $phx = Net::CIDR::Lite->new;
$phx->add("66.211.160.0/19");
$networks{'phx'} = $phx;

# eVA IP ranges
my $eva = Net::CIDR::Lite->new;
$eva->add("66.211.179.196/26");
$eva->add("66.211.167.132/25");
$eva->add("66.211.164.0/25");
$eva->add("66.211.164.128/26");
$networks{'eva-phx'} = $eva;
my $eva2 = Net::CIDR::Lite->new;
$eva2->add("66.135.217.0/24");
$networks{'eva-slc'} = $eva2;

# DEN
my $den = Net::CIDR::Lite->new;
$den->add("216.113.160.0/19");
$networks{'den'} = $den;

# Herbst
my $herbst = Net::CIDR::Lite->new;
$herbst->add("212.222.51.0/24");
$herbst->add("212.222.52.0/24");
$herbst->add("91.203.202.0/24");
$herbst->add("91.203.203.0/24");
$networks{'herbst'} = $herbst;

# Rackspace
my $rackspace = Net::CIDR::Lite->new;
$rackspace->add("72.32.0.0/16");
$rackspace->add("174.143.0.0/16");
$rackspace->add("184.106.0.0/16");
$rackspace->add("67.192.0.0/16");
$rackspace->add("98.129.0.0/16");
$rackspace->add("74.205.0.0/17");
$rackspace->add("31.222.162.0/24");
$rackspace->add("72.3.128.0/17");
$rackspace->add("207.97.192.0/18");
$rackspace->add("46.38.160.0/19");
$rackspace->add_range("31.222.184.0 - 31.222.191.255");
$networks{'rackspace'} = $rackspace;

my $savvis = Net::CIDR::Lite->new;
$savvis->add("216.32.0.0/14");
$savvis->add_range("64.70.0.0 - 64.70.111.255");
$networks{'savvis'} = $savvis;


# some european/german place?
my $netmagic = Net::CIDR::Lite->new;
$netmagic->add_range("202.87.32.0 - 202.87.63.255");

$networks{'netmagic'} = $netmagic;

# marketplaats
my $marketplaats = Net::CIDR::Lite->new;
$marketplaats->add("195.78.84.0/23");
$networks{'marketplaats'} = $marketplaats;

# critical path
my $criticalpath = Net::CIDR::Lite->new;
$criticalpath->add("67.88.0.0/13");
$networks{'criticalpath'} = $criticalpath;

# eachnet
my $eachnet = Net::CIDR::Lite->new;
$eachnet->add_range("61.129.69.96 - 61.129.69.127");
$networks{'eachnet'} = $eachnet;

# chinanet
my $chinanet = Net::CIDR::Lite->new;
$chinanet->add_range("61.128.0.0 - 61.129.255.255");
$networks{'chinanet'} = $chinanet;

# database information
$connectionInfo="DBI:mysql:database=$iprepdb;$iprepdhost:3306";

unless ($opt_i || $opt_a || $opt_u) {
  print "$usage\n";
  exit 1;
}

sub findARecords {
	my $ip = shift;
	# need to move hardcoded path up to a config file
	my @lines = `grep $ip /ebay/gauntlet/audits/external-dns-addr-space/forward/*`;
	return unless (@lines);
	my @arecords;
	# ex: 
	# forward/db.ebay.com.au:tools                   IN      A       117.120.0.8
	foreach my $line (@lines) {
		next if ($line =~ /db.(\S+):;/); # skip comments
		if ($line =~ /db.(\S+):(\S+)\s+IN\s+A\s+$ip/) {
			my $domain = $1; 
			my $hostname = $2;
			my $fqdn;
			# Handle top level entries correctly by not appending domain
			if ($hostname =~/\.$/) {
				$fqdn = $hostname;
				chop $fqdn; 
			} else {
				$fqdn = $hostname . "." . $domain ;
			}
			print "hostname: $hostname , domain: $domain ,  fqdn: $fqdn\n" if ($DEBUG);
			push (@arecords, $fqdn);
		}
		# www                     A       72.3.243.237
		elsif ($line =~ /db.(\S+):(\S+)\s+A\s+$ip/) {
			my $domain = $1;
			my $hostname = $2;
                        if ($hostname =~/\.$/) {
				$fqdn = $hostname;
				chop $fqdn; 
			} else {
				$fqdn = $hostname . "." . $domain ;
			}
			print "fqdn: $fqdn\n" if ($DEBUG);
			push (@arecords, $fqdn);
		}
	}
	return @arecords;
}

sub whoOwns {
	my $ip = shift;
	# first check our specialized codes that may be part of a larger block (eva-phx and eva-slc)
	foreach my $dc ( "eva-phx", "eva-slc", keys(%networks)) { 
		print "looking in $dc space\n" if ($DEBUG);
		if ($networks{$dc}->find($ip)) {
			print "Found $ip in $dc address space.\n" if ($DEBUG);
			return $dc, "";
		}
	} 
	print "checking $ip\n" if ($DEBUG);
	my $text = `whois -h whois.arin.net $ip | grep -v "^#"`;
	if ($text =~ /eBay/) { return "eBay", ""; }
	if ($text =~ /SAVVIS/) { return "savvis", ""; }
	#print $text;

	return "unknown", "$text";
}

sub findPTRRecord {
	my $ip = shift;
	my $result = `host -W 1 $ip`;
	# 8.0.120.117.in-addr.arpa domain name pointer tools.ebay.com.au.
	if ($result =~ /domain name pointer (.*).$/) {
		#print $1, "\n";
		return $1; 
	}
}



$dbh=DBI->connect($connectionInfo,$iprepuser,$ipreppass);



# fetch all the addresses from the DB or just the one we're interested in
if ($opt_i) {
	chomp $opt_i;
	$sth=$dbh->prepare("select ipaddr from addresses where ipaddr = '$opt_i'");
} elsif ($opt_u) {
	$sth=$dbh->prepare("select ipaddr from addresses where sitecode='unknown' order by ipaddr ASC"); # all unknowns 
} else {
	$sth=$dbh->prepare("select ipaddr from addresses order by sitecode ASC"); # everything
}
my $rv=$sth->execute;

my $i = 0;
while (my $addr=$sth->fetchrow()) {
	$i++; 
	print "Processing $addr ($i of $rv)  \n";
	my @arecords = findARecords($addr);
	my $arecordlist = join(",", @arecords); 
	my ($owner, $whois) = whoOwns($addr);
	my $ptr = findPTRRecord($addr);
	$sql="update addresses set arecords='$arecordlist',sitecode='$owner',ptrrecords='$ptr',whois=" . $dbh->quote("$whois")
		. " where ipaddr='$addr'";
	print "$sql\n" if ($DEBUG);
	$dbh->do($sql);
}

$sth->finish();
