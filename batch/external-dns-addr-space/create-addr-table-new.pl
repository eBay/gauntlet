#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;

$prog=basename($0);

$usage="usage: $prog -y \nhelp: $prog -h";

getopts('y');


# database information
$connectionInfo="DBI:mysql:database=$iprepdb;$iprepdhost:3306";

unless ($opt_y ) {
  print "$usage\n";
  exit 1;
}

$sql="CREATE TABLE IF NOT EXISTS `addresses` (
  `ipaddr` varchar(32) NOT NULL,
  `ptrrecords` varchar(256) DEFAULT NULL,
  `arecords` varchar(256) DEFAULT NULL,
  `asnumber` int(11) DEFAULT NULL,
  `ipnetwork` varchar(128) DEFAULT NULL,
  `adminemail` varchar(256) DEFAULT NULL,
  `admindomain` varchar(256) DEFAULT NULL,
  `openports` text,
  `sitecode` varchar(32) DEFAULT NULL,
  `whitehat` tinyint(1) DEFAULT NULL,
  `qualys` tinyint(1) DEFAULT NULL,
  `whois` text NOT NULL,
  UNIQUE KEY `ipaddr` (`ipaddr`)
) ENGINE=MyISAM DEFAULT CHARSET=utf8;";
$dbh=DBI->connect($connectionInfo,$iprepuser,$ipreppass);
$sth=$dbh->do($sql);

