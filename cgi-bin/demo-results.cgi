#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;
use CGI qw(:standard);

# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";
$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);


# print the header
print header;

# HTML for the beginning of the table
# we are putting a border around the table for effect
print "<table border=\"1\" width=\"800\"> \n";

# print your table column headers
print "<tr><td>Hostname</td><td>Domain</td><td>Result</td>\n";

# set the value of your SQL query
$sql="select hostname, domain, result from tasks where status = 'completed' " .
       " and audit = 'read-only-root-fs'";


# prepare your statement for connecting to the database
$sth=$dbh->prepare($sql);
#$sth=$dbh->do($sql);

# execute your SQL statement
$sth->execute();

# retrieve the values returned from executing your SQL statement
while (@data = $sth->fetchrow_array()) {
	my $hostname = $data[0];
	my $domain = $data[1];
	my $result = $data[2];

	# print your table rows
	print "<tr><td>$hostname</td><td>$domain</td><td>$result</td></tr>\n";
}
# close your table
print "</table>\n";

# close database connection too
$dbh->disconnect();

# exit the script
exit;

