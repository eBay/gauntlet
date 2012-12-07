#!/usr/bin/perl -I/ebay/gauntlet/lib

use Audit;

$timeout = 900;

$hostname = shift;
$cmd = shift;
chomp $cmd;

if (! $cmd) {
	print "Usage: $0 <hostname> <cmd>\n";
	exit 2;
}

#$DEBUG = 1;

my $datadir = getHostDataDir($hostname);
my $result = gauntletRunCommand($hostname, $cmd, "testcmd");
# log our results to stdout and return an exit status 
print "STDOUT: ", `cat $datadir/testcmd`;
print "STDERR: ", `cat $datadir/testcmd.err`;
print "\n";
if ($result) {
	print "return code: $result\n";
}
if ($result gt 256) { exit(255); }
exit ($result); 
