#!/usr/bin/perl -I /ebay/gauntlet/lib

use Getopt::Std;
use File::Basename;
use GauntletConfig;

$DEBUG = 1;

$prog = basename("%0");
getopts("h:k:p:P:");

$usage = "$prog"; 
print "trying to get into $hostname ... \n";
eval {
	local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
	alarm $timeout;

	print "checking for existing working key\n";
	`ssh -q  -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null $hostname uname -a`;
	unless ($?) {
		print "We can already get into $hostname, no changes made\n";
		exit 1;
	}
	alarm 0;
};
if ($@) {
	# timed out
	`echo $hostname timed out >> $timedout`;
	print "$hostname timed out\n";
	die unless $@ eq "alarm\n";   # propagate unexpected errors
	exit 1;
}

open(PASSLIST, $passlist) or die "cannot open: $passlist : $!";
@passwords = <PASSLIST>;
my $x = 0;
foreach $pass (@passwords) {
	chomp $pass;
	$x++;
	eval {
        	local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
	        alarm $timeout;

		print "trying pass # $x\n";
		print `$sshpass -p "$pass" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$hostname" uptime`;
		if ($? eq 0) {
			print "got in with pass # $x\n";
			print "  backing up authorized_keys2 on remote host\n";
			print `$sshpass -p "$pass" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$hostname" "mkdir -p .ssh ; cp -p .ssh/authorized_keys2 .ssh/authorized_keys2.bak || true; egrep -v 'adm1|adm2|dev-adm|qa-adm|admin01|master01' .ssh/authorized_keys2.bak > .ssh/authorized_keys2 || true"`;
			print "  pushing authorized_keys2 from local host\n";
			print `egrep 'adm1|adm2|dev-adm|qa-adm|admin01|master01' /.ssh/authorized_keys2 | $sshpass -p "$pass" ssh -q -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$hostname" "cat >> .ssh/authorized_keys2"`;
			unless ($?) {
		        	print "ssh keys installed on $hostname sucessfully\n";
			}
			exit 0;
		}
        	alarm 0;
        };
	if ($@) {
		# timed out
		`echo $hostname timed out >> $timedout`;
	        print "$hostname timed out\n";
		die unless $@ eq "alarm\n";   # propagate unexpected errors
		exit 1;
	}
}
print "Ran out of options for $hostname\n";
`echo $hostname does not use a known password >> $timedout`;
exit 1;
