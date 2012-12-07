#!/usr/bin/perl -I /ebay/gauntlet/lib

# This is the Gauntlet command toolchain by Adam Beeman, 2011, eBay Inc.

# This module contains all the host Audit related functions

# ssh key installation logic - see magic-update-keys script 
# this logic requires ssh-askpath and access to the password list

use Socket;
use DBI;
use GauntletConfig;
use TaskMan;




sub workerThread {
	# grab an item at random (using sort -R) from the unassigned queue
	while (my $task  = `/bin/ls $spooldir/unassigned | sort -R | head -1`) {
		chomp $task;
		if ($task =~ /(\S+)/) {
			#$jobid = $1;
			`mv $spooldir/unassigned/$task $spooldir/running`;
			# if the previous command had an exit status, another worker has picked up the task
			next if ($?);
			my $cmd = `cat $spooldir/running/$task`;
			chomp $cmd;
			my ($jobid, $audit, $hostname, $domain);
			if ($task =~ /job-(\S+):(\S+):(\S+):(\S+)$/ ) {
				$jobid = $1;
				$audit = $2;
				$hostname = $3;
				$domain = $4; 
				$sql = "update tasks set status='running',started='$date'" .
     				" where hostname='$hostname' and domain='$domain' and audit='$audit' and jobid='$jobid'";
				# database information
				$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
				$dbh->do($sql);
				$dbh->disconnect();
				print "running: $task : $cmd\n";
				my $retcode;
				my $result = `$cmd`;
				if ($?) {
					$retcode = "failed";
				} else {
					$retcode = "completed";
				}
				chomp $result;
				unlink("$spooldir/running/$task");
				$date = `date`;
				chomp $date;
				$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);
				$sql = "update tasks set status='$retcode', " .
					" completed='$date', result=" .
					$dbh->quote("$result") . " where " .
					"hostname='$hostname' and " .
					"domain='$domain' and audit='$audit'" .
					" and jobid='$jobid'";
				print "SQL: $sql\n";
				$dbh->do($sql);
				$dbh->disconnect();
			}
		}
	}
	print "no more tasks in spool dir\n" if ($DEBUG);
}



sub basicLoginCheck {
	my $host = shift;
	my $env = shift;
	# DNS test
	my ($short, $domain) = lookupHostDomain($host, $env);
	if (! $domain) {
		print "Cannot determine domain for $host : $env !\n";
		`echo $date $host $env >> $nodns`;
		return 1;
	}
	my $fqdn = $short . "." . $domain;
	
	# ping test
        `$fping -r 2 -t 5000 $fqdn `;
        $pings=$?;
	if ($pings) {
		print "Cannot ping $fqdn !\n";
                `echo $date $fqdn >> $noping`;
                return 2;
	}
	# this is a basic validation of being able to login and run "uname" using our ssh keys, etc.
	gauntletRunCommand($fqdn, 'uname -a \; cat /etc/\*release', "hostinfo");
}
	

# takes a hostname, optional domain name, and gets an an IP, or fails.
sub lookupHostDNS {
	my $hostname = shift;
	my $env = shift;
	my $shortname;
	my $domain;
	my $fqdn;
	if ($hostname =~ /(.*)\.(.*)\.ebay.com/ && ! $env ) {
		$shortname = $1;
		$domain = "$2.ebay.com";
		$fqdn = $hostname;
		print "lookupHostDNS: got $domain from $hostname\n" if ($DEBUG);
	} elsif ($env) {
		$domain = $domains{$env};	
		print "lookupHostDNS: got $domain from env $env\n" if ($DEBUG);
		$fqdn = $hostname . "." . $domain;
	} else {
		$fqdn = $hostname;
		print "$lookupHostDNS: using no domain for lookup\n" if ($DEBUG);
	}
	my $packed_ip = gethostbyname($fqdn);
	if (defined $packed_ip) {
		my $ip_address = inet_ntoa($packed_ip);
		print "lookupHostDNS: found $ip_address\n" if ($DEBUG);
		return $ip_address;
	} else { 
		warn "no matching A record for $hostname\n";
		return 0;
	}

}


sub lookupHostDomain {
	my $hostname = shift;
	my $env = shift;
	if ($hostname =~ /(.*)\.(.*\..*\.com)/) {
		print "lookupHostDomain: parsed $hostname to get $2\n" if ($DEBUG);
		return ($1, $2);
	}
	my $hostout = `host $hostname`;
	#if ($hostout =~ /(.*)\.(.*\..*\.com) has address/) {
	if ($hostout =~ /(\S+) has address/) {
		my @parts = split('\.', $1 , 2);
		print "matched $1 from lookup, splitting to @parts\n" if ($DEBUG);
		return ($parts[0], $parts[1]);
	}
	my $ip = lookupHostDNS($hostname, $env);
	if ($ip) {
		my $iaddr = inet_aton("$ip"); # or whatever address
		print "lookupHostDomain: iaddr = $iaddr , ip = $ip\n" if ($DEBUG);
		# we can't assume everything has a PTR!
		my $fqdn = gethostbyaddr($iaddr, AF_INET);
		print "lookupHostDomain: found $fqdn\n" if ($DEBUG);
#		if ($fqdn =~ /(.*)\.(.*\..*\.com)/) {
		if ($fqdn =~ /(.*)\.(.*\.com)/) {
			return ($1, $2);
		}
	}
	return;
}



# verify/install ssh key
# Takes: hostname, keyfile
# returns: message or 0 if unsuccessful.
sub verifyKeys {
	my $hostname = shift;
	my $keyfile = shift;
	my $key = `cat $keyfile`;
	chomp $key;
	if (!$key) {
		warn "can't open keyfile $keyfile!";
		return 0;
	}
	my @keyparts = split(" ", $key);
	my $keyname = $keyparts[-1];
	print "using key named $keyname\n" if ($DEBUG);
	print "backing up authorized_keys2 on remote host\n" if ($DEBUG);
	my $output = gauntletRunCommand($hostname, "pwd ; mkdir -p .ssh ; cp -p .ssh/authorized_keys2 .ssh/authorized_keys2.bak ;id ;  ls -la .ssh ;egrep -v \"" . $keyname . "\" .ssh/authorized_keys2.bak > .ssh/authorized_keys2", "backup-keys");
	print $output if ($DEBUG);
	print "pushing authorized_keys2 from local host\n" if ($DEBUG);
	my $output = `cat $keyfile | $ssh $ssh_key -q -o LogLevel=ERROR -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l $ssh_user $ssh_options "$hostname" "cat >> .ssh/authorized_keys2"`;
	print $output if ($DEBUG);
	if ($output =~ /Permission denied/) {
		warn "Couldn't update keys on $hostname";
		return 0;
	}
	print "ssh keys installed on $hostname sucessfully\n" if ($DEBUG);
	return "success";
}


sub getHostDataDir {
	my $host = shift;
	my $env = shift;
        my ($short, $domain) = lookupHostDomain($host, $env);
        if (! $short || ! $domain) {
                print "Cannot determine domain for $host : $env !\n";
                `echo $date $host $env >> $nodns`;
                return;
        }
        $hostdata = $datadir . "/$domain/$short";
	return $hostdata;
}

# perhaps need to split this into file fetch vs. install/dist methods
# takes: hostname, filename, dstfilename
sub gauntletCopyFile {
	my $host = shift;
	my $copyfile = shift;
	my $dstfile = shift;
	my ($short, $domain) = lookupHostDomain($host);
	if (! $short || ! $domain) {
		print "Cannot determine domain for $host : $env !\n";
		`echo $date $host $env >> $nodns`;
		return 1;
	}
	$hostdata = $datadir . "/$domain/$short";
	mkdir("$datadir/$domain");
        getHostOverrides($short, $domain);
	eval {
		# setup alarm
		local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
		alarm $timeout;
		print `$scp $ssh_key -q -o ConnectTimeout\=5 -o BatchMode\=yes -q -o LogLevel=ERROR -o StrictHostKeyChecking\=no -o UserKnownHostsFile\=/dev/null -p $ssh_user\@${host}:$copyfile $hostdata/$dstfile`;
		# disable alarm
		alarm 0;
	};
	if ($@) {
		# timed out
		`echo $date $host >> $timedout`;
		print "timed out\n";
		
		die unless $@ eq "alarm\n";   # propagate unexpected errors
	} else {
		return 0;
	}
}

# file distribution mechanism - differs from above in that dstfilename is a path on the remote host
# and filename is an absolute path to a local file on the gauntlet server
# takes: hostname, filename, dstfilename
sub gauntletPushFile {
        my $host = shift;
        my $copyfile = shift;
        my $dstfile = shift;
        my ($short, $domain) = lookupHostDomain($host);
        if (! $short || ! $domain) {
                print "Cannot determine domain for $host : $env !\n";
                `echo $date $host $env >> $nodns`;
                return 1;
        }
        getHostOverrides($short, $domain);
        eval {
                # setup alarm
                local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
                alarm $timeout;
                print `$scp $ssh_key -q -o ConnectTimeout\=5 -o BatchMode\=yes -o LogLevel\=ERROR -o StrictHostKeyChecking\=no -o UserKnownHostsFile\=/dev/null -p $copyfile $ssh_user\@${host}:$dstfile`;
                # disable alarm
                alarm 0;
        };
        if ($@) {
                # timed out
                `echo $date $host >> $timedout`;
                print "timed out\n";

                die unless $@ eq "alarm\n";   # propagate unexpected errors
        } else {
                return 0;
        }
}



# gauntletRunCommand($host, "ls -l /usr/bin/vmware-config-tools.pl", "config-tools");
sub gauntletRunCommand {
	my $host = shift;
	my $cmd = shift;
	my $outfile = shift;
	my ($short, $domain) = lookupHostDomain($host);
	if (! $short || ! $domain) {
		print "Cannot determine domain for $host : $env !\n";
		`echo $date $host $env >> $nodns`;
		return 1;
	}
        $hostdata = $datadir . "/$domain/$short";
	print "host data dir: $hostdata\n" if ($DEBUG);
	mkdir("$datadir/$domain");
	mkdir($hostdata);
	getHostOverrides($short, $domain);
	my $rcode;
	eval {
		# setup alarm
		local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
		alarm $timeout;
		#open(SAVESTDERR,">&STDERR") || warn "$0: unable to open SAVESTDERR ($!)\n";

		if ($pid = fork) {
			#print "$$ waiting for $pid\n";
			waitpid $pid, 0;
			$rcode = $?;
			print "waitpid done - rcode = $rcode\n" if ($DEBUG);
			# disable alarm
			alarm 0;
		} else {
        		#close (STDOUT);
			#close (STDERR);
       			#print "kickoff ssh to $host \n"; 
			if ($host eq "localhost") {
				print "localhost\n" if ($DEBUG);
				exec("$cmd 1> $hostdata/$outfile 2> $hostdata/$outfile.err");
			} else {
				print "$host\n" if ($DEBUG);
				exec("$ssh $ssh_key -o ConnectTimeout=5 -o LogLevel=ERROR -o BatchMode=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -l $ssh_user $host \"$cmd\" 1> $hostdata/$outfile 2> $hostdata/$outfile.err");
				#print "$$ completed with $retcode\n" if ($DEBUG);
			}
		}
	};
	if ($@) {
		# timed out
		`echo $date $host >> $timedout`;
		print "timed out\n";
		kill 9, $pid;
		die unless $@ eq "alarm\n";   # propagate unexpected errors
		exit 1;
	} else {
		if ($rcode) { $rcode = $rcode/256; }
		return $rcode;
	}
}



#Linux lab-loaner02 2.6.32-27-server #49-Ubuntu SMP Thu Dec 2 02:05:21 UTC 2010 x86_64 GNU/Linux
#DISTRIB_ID=Ubuntu
#DISTRIB_RELEASE=10.04
#DISTRIB_CODENAME=lucid
#DISTRIB_DESCRIPTION="Ubuntu 10.04.1 LTS"


#Linux lab-loaner01.arch.ebay.com 2.6.32-71.el6.x86_64 #1 SMP Wed Sep 1 01:33:01 EDT 2010 x86_64 x86_64 x86_64 GNU/Linux
#Red Hat Enterprise Linux Server release 6.0 (Santiago)
#Red Hat Enterprise Linux Server release 6.0 (Santiago)
#Red Hat Enterprise Linux ES release 4 (Nahant Update 6)

#CentOS release 5.4 (Final)


#SunOS devdb26 5.10 Generic_138888-05 sun4v sparc SUNW,Sun-Fire-T200
#                      Solaris 10 10/08 s10s_u6wos_07b SPARC
#           Copyright 2008 Sun Microsystems, Inc.  All Rights Reserved.
#                        Use is subject to license terms.
#                            Assembled 27 October 2008


# call this only after a basic login check has been done
# returns OS and arch info
sub gauntletHostArch {
	my $hostname = shift;

	my $datadir = getHostDataDir($hostname);
        my $result = gauntletRunCommand($hostname, 'uname -a ; cat /etc/*release', "hostinfo");
	if ($result) { 
		# We don't want to exit the program... but we didn't get data 
		print STDERR "gauntletHostArch() bailed when getting error code $result from gauntletRunCommand()\n"; 
		#exit 1;
		return ;
	}

	$hostinfo = `cat $datadir/hostinfo`;
	chomp $hostinfo;

	#SunOS devdb26 5.10 Generic_138888-05 sun4v sparc SUNW,Sun-Fire-T200
	if ($hostinfo =~ /^SunOS \S+ \S+ \S+ (\S+)/) {
		$os = "solaris"; $arch = $1; 
	} elsif ($hostinfo =~ /Red Hat Enterprise Linux Server release (\S+) \(/) {
		$os = "redhat-$1";
		my @parts = split(' ', $hostinfo);
		$arch = $parts[11];
	} elsif ($hostinfo =~ /Red Hat .* release (\S+) \(.* Update (\S+)\)/) {
		$os = "redhat-$1" . "." . $2; 
		my @parts = split(' ', $hostinfo);
		$arch = $parts[11];
	} elsif ($hostinfo =~ /DISTRIB_RELEASE=(\S+)/) {
		$os = "ubuntu-$1"; $arch = "x86";
	} elsif ($hostinfo =~ /CentOS release (\S+)/) {
		$os = "centos-$1"; $arch = "x86";
	} elsif ($hostinfo =~ /CentOS release \S+ \(Final\)/) {
		$os = "centos-$1"; $arch = "x86";
	} else {
		print "unknown OS\n";
		return;
	}
	return ($os, $arch);
}

############
1;
