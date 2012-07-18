#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for generating email reports for Gauntlet
# Copyright (c) 2012 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;
use Net::SMTP;




$prog=basename($0);

$usage="usage: $prog -a <audit> -e <emailaddr> [-d <domain>] \nhelp: $prog -h";

getopts('a:d:e:');


# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";

unless ($opt_a && $opt_e) {
  print "$usage\n";
  exit 1;
}

$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);

$sql="select hostname, domain, result from tasks where status = 'failed' " .
	($opt_d ?  "and domain='" . $opt_d . "'" : '' ) . " and audit = " 
	. $dbh->quote("$opt_a");
print "SQL: $sql\n" if ($DEBUG);
$sth=$dbh->do($sql);


my $rs = $dbh->selectall_arrayref($sql);

my $count = 0;
my $data;
foreach my $myRow (@$rs) {
        $data .=  $$myRow[0] . $$myRow[1] . " failed with error: " . $$myRow[2] . "\n";
	print $data;
	$count++;
}
$dbh->disconnect();
#print "Total: $count\n";
#print "data: $data\n";

if ($count > 0 ) {
	print "Sending email ...\n ";
	$msg  = "To: $opt_e\nSubject: Gauntlet Failure Report for audit: $opt_a " .
		($opt_d ? "in domain: $opt_d " : '' ) .  "\n\n\n" . "$data";

	print $msg;
	$smtp = Net::SMTP->new($smtpserver);
	$smtp->mail($opt_e);
	$smtp->to($opt_e);
	$smtp->data();
	$smtp->datasend($msg);
	$smtp->dataend();
	$smtp->quit();
	print "Done.\n";
}

