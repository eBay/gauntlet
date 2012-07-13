#!/usr/bin/perl -I /ebay/gauntlet/lib

use Audit;

#$DEBUG=1;
#print "starting worker thread\n";
while (1) {
	workerThread();
	sleep 5;
}
#print "execution completed\n";

