#!/usr/bin/perl -I /ebay/gauntlet/lib

use Audit;

$DEBUG=1;
#print "starting worker thread\n";
workerThread();
#print "execution completed\n";

