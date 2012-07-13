#!/usr/bin/perl

$spooldir = "/ebay/gauntlet/spool";

print `date`;
print "Unassigned tasks: ", `/bin/ls $spooldir/unassigned| wc -w`;
print "Running tasks: ", `/bin/ls $spooldir/running| wc -w`;
