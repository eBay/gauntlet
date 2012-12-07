#!/usr/bin/perl -I /ebay/gauntlet/lib

# Tool for updating gauntlet host data
# Copyright (c) 2011 Adam Beeman and eBay, Inc.


use DBI;
use Getopt::Std;
use File::Basename;
use GauntletConfig;
use GauntletWeb;
use CGI qw(:standard);
use Data::Dumper;

$| = 1; # set stdout to be unbuffered

# database information
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";
$dbh=DBI->connect($connectionInfo,$gdbuser,$gdbpass);


$hostname = `hostname`;
chomp $hostname;


##
## Functions
##
sub logIt {
	my $text = shift;
	my $date = `date`;
	chomp $date;
	my $logcmd = "echo $date : $ENV{'REMOTE_USER'} - $text  >> $gbase/logs/webcgi.log";
	#print "$logcmd", "\n" if ($DEBUG);
	`$logcmd`;
}



##
## Main
##


# this seems to be the only one of several methods that actually loaded the CSS
#print header, "<head> <meta http-equiv=content-type content='text/html; charset=iso-8859-1' />
#	<title>Gauntlet Administration Console</title>
#	<script type='text/javascript'></script>
#	<style type='text/css' media='all'>
#		\@import '/gauntlet/main.css'; </style> </head>\n";




# print the header
print header, start_html( 
	-title =>  'Gauntlet Administration Console',
	-style => { -src => '/gauntlet/main.css' 
	-type => 'text/css',
	-media => 'screen' },); 
print "<img src=/gauntlet/GauntletLogo.png>\n";

##
## Header buttons
##

#print h2('Gauntlet Admin Console');

NavigationBar();

##
## Actions based on query-string/post parameters
##

if (param('ViewHostgroup')) {
	HostgroupView(param('ViewHostgroup'));
} elsif (param('removeHost') && param('hostgroup')) {
	RemoveHostFromHostgroup(param('removeHost'), param('hostgroup'));
} elsif (param('addHostToHostgroup')) {
	AddHostToHostgroup(param('hostgroup'), param('hostname'));
} elsif (param('DeleteHostgroup')) {
	DeleteHostgroup(param('DeleteHostgroup'));
	ViewHostgroups();
} elsif (param('page')) {
	print h3(param('page'));
} elsif (param('page1') eq 'hostgroups') {
	ViewHostgroups();
} elsif (param('page2') eq 'schedule') {
	TaskScheduling();
} elsif (param('page3') eq 'results') {
	ViewResults();
} elsif (param('page4') eq 'status') {
	ServerStatus();
} elsif (param('page5') eq 'scheduleview') {
	ViewSchedule();
} elsif (param('ViewJob')) {
        ViewJob(param('ViewJob'));
} elsif (param('DeleteJobResults')) {
	DeleteJobResults(param('DeleteJobResults')); 
} elsif (param('DeleteScheduleItem')) {
	DeleteScheduleItem(param('DeleteScheduleItem')); 
} elsif (param('DeleteAllResults')) {
	DeleteAllResults(param('DeleteAllResults')); 
} elsif (param('DeleteResult')) {
	DeleteResult(param('DeleteResult'), param('hostname')); 
} elsif (param('DeleteAllHostResults')) {
	DeleteAllHostResults(param('DeleteAllHostResults')); 
} elsif (param('ViewHostResults')) {
	ViewHostResults(param('host')); 
} elsif (param('ViewDetailedResults')) {
	ViewDetailedResults(param('audit')); 
} elsif (param('ScheduleTask')) {
	ScheduleTask(param('when'), param('hostgroup'), param('audit'), param('description'));
} elsif (param('ScheduleBatch')) {
	ScheduleBatch(param('when'), param('batch'), param('description'));
} elsif (param('CreateResultsGroup')) {
	CreateResultsGroup(param('job'), param('hostgroup'), param('status'), param('message'));
} else { 
	exit 0;
}




if (param('view')) {
	print h3(param('view'));
}

#print hr; 
NavigationBar();


sub ServerStatus {
	print h3("Server Status");
	print "<pre>\n";
	print `uptime`;
	print `$gauntlet_base/bin/spoolinfo.pl`;	
        print "Running Gauntlet workers: ", `ps -eaf | grep worker.pl | grep -v grep | wc -l`;
	print "</pre>\n";
	
}

sub ManageKeys {
	print h3("Manage Keys");
}

# close database connection too
$dbh->disconnect();
