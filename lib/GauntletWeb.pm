#!/usr/bin/perl -I /ebay/gauntlet/lib
# Copyright (c) 2011 Adam Beeman and eBay, Inc.

# This module contains all the Task Management related functions
# hence the name TaskMan.

use DBI;
use GauntletConfig;
use Audit;
use CGI qw(:standard);



use HTML::Entities ();
$ok_chars = 'a-zA-Z0-9. ,-_';
foreach $param_name ( param() ) {
    $_ = HTML::Entities::decode( param($param_name) );
    $_ =~ s/[^$ok_chars]//go;
    param($param_name,$_);
}


$query = new CGI;

###
### Hostgroup related functions 
###

sub ViewHostgroups {
        $sql="select distinct hostgroup from hostgroups";
        # prepare your statement for connecting to the database
        $sth=$dbh->prepare($sql);

        # execute your SQL statement
        $sth->execute();

        #print "<pre>\n";
	print b('Select a Host Group to View or Edit');
        # retrieve the values returned from executing your SQL statement
        while (@data = $sth->fetchrow_array()) {
                my $hostgroup = $data[0];
                print start_form, hidden('ViewHostgroup', $hostgroup), submit("$hostgroup"), end_form , "\n";

        }
        #print "</pre>\n";
	AddHostField();
}


sub HostgroupAdmin {
        print h3("Hostgroup Administration");
        # HTML for the beginning of the table
        # we are putting a border around the table for effect
        #print "<table border=\"1\" width=\"800\"> \n";
        print "<table border=\"1\"> \n";

        # print your table column headers
        print "<tr><td>Hostgroup</td>\n";

        # set the value of your SQL query
        $sql="select distinct hostgroup from hostgroups";

        # prepare your statement for connecting to the database
        $sth=$dbh->prepare($sql);

        # execute your SQL statement
        $sth->execute();

        # retrieve the values returned from executing your SQL statement
        while (@data = $sth->fetchrow_array()) {
                my $hostgroup = $data[0];

                # print your table rows
                print "<tr><td><a href=/gauntlet-cgi/index.cgi?viewhostgroup=$hostgroup>$hostgroup</a></td></tr>\n";
        }
        # close your table
        print "</table>\n";
	AddHostField();
}

sub AddHostField {
	# this ought to zap previous query_string stuff
	Delete_all();
	print b('Add a new host'); 
        #print "<table border=\"1\" width=\"800\"> \n";
        print "<table border=\"1\"> \n";
	print "<tr><td>", start_form, hidden('addHostToHostgroup', 'yes'),
	"Hostname (fully qualified): ",textfield('hostname'), "</td></tr><tr><td>",
	"Hostgroup: ",textfield('hostgroup'), "</td><td>", 
	submit('Add'), end_form, "</td></tr></table>\n";

}

sub AddHostToHostgroup {
	my $hostgroup = shift;
	my $hostname = shift;
	Delete_all();
	my $sql = "INSERT INTO hostgroups (hostname, hostgroup) VALUES ( ?, ? )";
	$sth = $dbh->prepare( $sql );
	$sth->execute( $hostname, $hostgroup );
	HostgroupView($hostgroup);
}

sub HostgroupView {
	my $hostgroup = shift;
        print b("Viewing Hostgroup: $hostgroup");
        # HTML for the beginning of the table
        # we are putting a border around the table for effect
        #print "<table border=\"1\" width=\"800\"> \n";
        print "<table border=\"1\"> \n";

        # print your table column headers
        print "<tr><td>Hostname</td><td>Delete?</td></tr>\n";

        # set the value of your SQL query
        $sql="select distinct hostname from hostgroups where hostgroup = \"$hostgroup\"";

        # prepare your statement for connecting to the database
        $sth=$dbh->prepare($sql);

        # execute your SQL statement
        $sth->execute();

	# flush the old params()
	Delete_all();
        # retrieve the values returned from executing your SQL statement
        while (@data = $sth->fetchrow_array()) {
                my $hostname = $data[0];

                # print your table rows
                print "<tr><td>$hostname</td><td>";
		print start_form, hidden('removeHost', $hostname), hidden('hostgroup', $hostgroup),  submit("Delete $hostname"), end_form , "</td>\n";


        }
        # close your table
        print "</table>\n";
	AddHostField();
}

sub RemoveHostFromHostgroup {
	my $hostname = shift;
        my $hostgroup = shift;
        print h3("Hostgroup: $hostgroup");

        # set the value of your SQL query
        $sql="delete from hostgroups where hostgroup = \"$hostgroup\" and hostname = \"$hostname\"";

        # prepare your statement for connecting to the database
        $sth=$dbh->prepare($sql);

        # execute your SQL statement
        $sth->execute();
	print "Delete $hostname from $hostgroup<br>\n";

	HostgroupView($hostgroup);

}

	
###
### Navigation functions
###

sub NavigationBar {
        #print "<table border=\"1\" width=\"800\"> \n";
        print "<br><table border=\"1\"> \n";
        print "<tr><td>", start_form, hidden('page1', 'hostgroups'), submit('Host Groups'), end_form , "</td>\n";
        print "<td>",  start_form, hidden('page2', 'schedule'), submit('Schedule Tasks'), end_form , "</td>\n";
        print "<td>", start_form, hidden('page3', 'results'), submit('View Results'), end_form , "</td>\n";
        print "<td>", start_form, hidden('page4', 'status'), submit('Server Status'), end_form , "</td>\n";
        print "<td>", start_form, hidden('page5', 'scheduleview'), submit('View Schedule'), end_form , "</td>\n";
#        print "<td>", start_form, hidden('page5', 'keys'), submit('Manage Keys'), end_form , "</td>\n";
	print "<td><a href=https://gauntlet.cloud.ebay.com/wordpress/?page_id=39 target=_new>Docs</a></td>\n";
        print "</tr></table><br>\n";
}

###
### Task related functions
###

# for now, we're basically looking at anything inside the "audits" directory
sub getTaskList {
	my @audits;
	opendir ( DIR, "$gauntlet_base/audits") || die "Error in opening dir $gauntlet_base/audits: $!\n";
	while( (my $filename = readdir(DIR))){
		next if ($filename eq ".");
		next if ($filename eq "..");
		push (@audits, $filename);
	}
	closedir(DIR);
	return sort @audits;
}

# similar function looks in a batch directory
sub getBatchList {
        my @audits;
        opendir ( DIR, "$gauntlet_base/batch") || die "Error in opening dir $gauntlet_base/batch: $!\n";
        while( (my $filename = readdir(DIR))){
                next if ($filename eq ".");
                next if ($filename eq "..");
                push (@audits, $filename);
        }
        closedir(DIR);
        return sort @audits;
}


sub TaskScheduling {


        # set the value of your SQL query
        $sql="select distinct hostgroup from hostgroups";
        # prepare your statement for connecting to the database
        $sth=$dbh->prepare($sql);
        # execute your SQL statement
        $sth->execute();
        # retrieve the values returned from executing your SQL statement
	my @hostgroups;
        while (@data = $sth->fetchrow_array()) {
                push(@hostgroups, $data[0]);
        }
	my @when = ( "nowonly",   "min",  "5min",  "15min",  "30min",  "1hr",  "2hr",  "4hr",  "8hr",  "12hr",  "day",  "2day",  "7day",  "month");
	my @audits = getTaskList();
        print h4("Schedule a task to run on a group of systems: ");
	
	print start_form, hidden('ScheduleTask', 'yes'), popup_menu('when',  [ @when ]),
		popup_menu('hostgroup',  [ @hostgroups ]),
		popup_menu('audit', [ @audits ]), "Description: ", textfield('description'), submit('Schedule Task'), end_form;
	print h4("Here are the currently available group tasks:");
	print "<table border=\"1\"><th>Task Name</th><th>Description</th></tr>\n";
	foreach my $task (@audits) {
		print "<td>$task</td>\n";
		if (-e "$gauntlet_base/audits/$task/README.txt") {
			print "<td>", `cat $gauntlet_base/audits/$task/README.txt` , "</td>\n";
		}
		print "</tr>\n";
	};
	print "</table>\n";

        my @batches = getBatchList();
        print h4("Schedule batch job to run: ");

        print start_form, hidden('ScheduleBatch', 'yes'), popup_menu('when',  [ @when ]),
                popup_menu('batch', [ @batches ]), "Description: ", textfield('description'), submit('Schedule Task'), end_form;
        print h4("Here are the currently available batch jobs:");
        print "<table border=\"1\"><th>Task Name</th><th>Description</th></tr>\n";
        foreach my $task (@batches) {
                print "<td>$task</td>\n";
                if (-e "$gauntlet_base/batch/$task/README.txt") {
                        print "<td>", `cat $gauntlet_base/batch/$task/README.txt` , "</td>\n";
                }
                print "</tr>\n";
        };
        print "</table>\n";


	

}

sub ScheduleTask {
	my $when = shift;
	my $hostgroup = shift;
	my $audit = shift;
	my $description = shift;

	my $remoteUser = $ENV{REMOTE_USER};
	if (! $remoteUser) { $remoteUser = "unknown"; }
        print "<pre>\n";
        print `$gauntlet_base/bin/queue-job.pl -g $hostgroup -a $audit -o $remoteUser -w $when -d \"$description\"`;       
        print "</pre>\n";
}


sub ScheduleBatch {
        my $when = shift;
        my $audit = shift;
        my $description = shift;

        my $remoteUser = $ENV{REMOTE_USER};
        if (! $remoteUser) { $remoteUser = "unknown"; }
        print "<pre>\n";
        print `$gauntlet_base/bin/queue-job.pl -b -a $audit -o $remoteUser -w $when -d \"$description\"`;
        print "</pre>\n";
}

###
### Results viewing functions
###

# this one shows us results organized by audit
sub ViewResults {

	# Recent Jobs
        print h3("Recent jobs:");
        $sql="select id, owner, hostgroup, audit, started from jobs order by id desc"; 
        $sth=$dbh->do($sql);

        #print "<table border=\"1\" width=\"800\"> \n";
        print "<table border=\"1\"> \n";

        my $rs = $dbh->selectall_arrayref($sql);
        # print your table column headers
        print "<tr><td>ID</td><td>owner</td><td>hostgroup </td><td>audit</td><td>Time Started</td></tr>\n";


	# this helps clear the previous parameters
	Delete_all();
        foreach my $myRow (@$rs) {
                print "<td>", start_form, hidden('ViewJob', $$myRow[0]), hidden('jobid', $$myRow[0]), submit("$$myRow[0]"), end_form;
                print "<a href=\"/gauntlet-cgi/results.csv?job=$$myRow[0]\" target=\"_new\">CSV</a></td><td>", $$myRow[1], " </td><td> ", $$myRow[2],"</td><td>", $$myRow[3], "</td><td>", $$myRow[4], "</td></tr>\n";

	}
        # close your table
        print "</table>\n";

	# Search by audit
	print h3("Search by audit:");
	$sql="select distinct audit from tasks"; 
	# prepare your statement for connecting to the database
	$sth=$dbh->prepare($sql);

        # execute your SQL statement
        $sth->execute();

        # retrieve the values returned from executing your SQL statement
	my @audits;
        while (@data = $sth->fetchrow_array()) {
                push(@audits, $data[0]);
	}
	print start_form, hidden('ViewDetailedResults', 'yes'), popup_menu('audit', [ @audits ]), 
		 submit("View Results"), end_form , "\n";

	# Search by host	
	print h3("Search by host:");
	$sql ="select distinct hostname from tasks";
	# prepare your statement for connecting to the database
        $sth=$dbh->prepare($sql);

        # execute your SQL statement
        $sth->execute();
	my @hosts;
        while (@data = $sth->fetchrow_array()) {
                push(@hosts, $data[0]);
        }
        print start_form, hidden('ViewHostResults', 'yes'), popup_menu('host',  [ @hosts ]),
                submit('View Results'), end_form, "\n";
}

sub DeleteAllHostResults {
        my $host = shift;
        $sql="delete from tasks where hostname = \"$host\"";
        # prepare your statement for connecting to the database
        $sth=$dbh->prepare($sql);

        # execute your SQL statement
        $sth->execute();
        print "Deleted all results for host: $host<p>\n";
        ViewResults();
}


sub DeleteAllResults {
	# delete from both the audit and jobs table...
        my $audit = shift;
	$sql="delete from tasks where audit = \"$audit\"";
        $sth=$dbh->prepare($sql);
        $sth->execute();
        $sql="delete from jobs where audit = \"$audit\"";
        # prepare your statement for connecting to the database
        $sth=$dbh->prepare($sql);
        $sth->execute();


        print "Deleted all results for audit: $audit <p>\n";
        ViewResults();
}

sub DeleteJobResults {
        my $jobid = shift;
	$sql="delete from tasks where jobid = \"$jobid\"";
        $sth=$dbh->prepare($sql);
        $sth->execute();
	$sql="delete from jobs where id = \"$jobid\"";
        $sth=$dbh->prepare($sql);
        $sth->execute();
        print "Deleted all results for job: $jobid <p>\n";
        ViewResults();
}

sub DeleteResult {
	my $audit = shift;
	my $host = shift;
        $sql="delete from tasks where audit = \"$audit\" and hostname = \"$host\"";
        # prepare your statement for connecting to the database
        $sth=$dbh->prepare($sql);

        # execute your SQL statement
        $sth->execute();

        print "Deleted results for audit: $audit of $host<p>\n";
	ViewDetailedResults($audit);
}


sub ViewDetailedResults {
	my $audit = shift;


	$sql="select hostname, domain, result, completed from tasks where audit = " . $dbh->quote("$audit") .
		"order by status";
	$sth=$dbh->do($sql);

	Delete_all();
	#print "<table border=\"1\" width=\"800\"> \n";
	print "<table border=\"1\"> \n";
	print "<tr><td>Showing results for audit: $audit </td><td>\n";
	print start_form, hidden('DeleteAllResults', $audit), submit("Delete ALL results for $audit"), end_form , "</td></tr></table><p>\n";
	#print "<table border=\"1\" width=\"800\"> \n";
	print "<table border=\"1\"> \n";

	my $rs = $dbh->selectall_arrayref($sql);
	my $count = 0;

	# print your table column headers
        print "<tr><td>Hostname</td><td>result</td><td>Date completed</td><td>Delete?</td></tr>\n";


	foreach my $myRow (@$rs) {
        	print "<td>", $$myRow[0], ".", $$myRow[1], " </td><td><pre>", $$myRow[2], "</pre></td><td> ", $$myRow[3], "</td>\n";
		# this helps clear the previous parameters
		Delete_all();
		print "<td>", start_form, hidden('DeleteResult', $audit), hidden('hostname', $$myRow[0]), submit("$$myRow[0]"), end_form , "</td></tr>\n";

        	$count++;
        }
        # close your table
        print "</table>\n";

	print br, "Total: $count\n";
}

sub ViewHostResults {
        my $host = shift;


        $sql="select hostname, audit, result, completed from tasks where hostname = " . $dbh->quote("$host") .
                "order by status";
        $sth=$dbh->do($sql);

        Delete_all();
        #print "<table border=\"1\" width=\"800\"> \n";
        print "<table border=\"1\"> \n";
        print "<tr><td>Showing results for audit: $audit </td><td>\n";
        print start_form, hidden('DeleteAllHostResults', $host), submit("Delete ALL results for $host"), end_form , "</td></tr></table><p>\n";
        #print "<table border=\"1\" width=\"800\"> \n";
        print "<table border=\"1\"> \n";

        my $rs = $dbh->selectall_arrayref($sql);
        my $count = 0;

        # print your table column headers
        print "<tr><td>Hostname</td><td>audit</td><td>result</td><td>Date completed</td><td>Delete?</td></tr>\n";


        foreach my $myRow (@$rs) {
                print "<td>", $$myRow[0], "</td><td> ", $$myRow[1], " </td><td><pre>", $$myRow[2], "</pre></td><td> ", $$myRow[3], "</td>\n";
                # this helps clear the previous parameters
                Delete_all();
                print "<td>", start_form, hidden('DeleteResult', $$myRow[1]), hidden('hostname', $$myRow[0]), submit("$$myRow[1]"), end_form , "</td></tr>\n";

                $count++;
        }
        # close your table
        print "</table>\n";

        print br, "Total: $count\n";
}

sub ViewJob {
        my $jobid = shift;

        $sql="select audit, hostname, domain, status, completed, result from tasks where jobid = " 
		. $dbh->quote("$jobid") . "order by status";
	$sth=$dbh->do($sql);

	Delete_all();
	#print "<table border=\"1\" width=\"800\"> \n";
	print "<table border=\"1\"> \n";
        print "<tr><td>Showing results for jobid: $jobid</td>\n";
	print "<td>", start_form, hidden('DeleteJobResults', $jobid), submit("Delete ALL results for job: $jobid"), end_form , "</td></tr></table>\n";
        #print "<table border=\"1\" width=\"800\"> \n";
        print "<table border=\"1\" > \n";
        my $rs = $dbh->selectall_arrayref($sql);
        my $count = 0;

        # print your table column headers        
	print "<tr><td>Task</td><td>Hostname</td><td>Status</td><td>Date completed</td><td>Result</td></tr>\n";


        foreach my $myRow (@$rs) {
                print "<td>", $$myRow[0], "</td><td>", $$myRow[1], ".", $$myRow[2], " </td><td>", $$myRow[3], "</td><td>", $$myRow[4], "</td><td><pre>", $$myRow[5], "</pre></td></tr>\n";
        }
        # close your table        
	print "</table>\n";

}

##
## Schedule Viewing
##
sub ViewSchedule {
        print h3("Your Current Schedule:");
        $sql="select id, owner, frequency, command, description from schedule order by id desc";
        $sth=$dbh->do($sql);

        #print "<table border=\"1\" width=\"800\"> \n";
        print "<table border=\"1\"> \n";

        my $rs = $dbh->selectall_arrayref($sql);
        # print your table column headers
        print "<tr><td>ID</td><td>owner</td><td>frequency</td><td>command</td><td>description</td></tr>\n";


        # this helps clear the previous parameters
        Delete_all();
        foreach my $myRow (@$rs) {
                print "<td>", start_form, hidden('DeleteScheduleItem', $$myRow[0]), hidden('jobid', $$myRow[0]), submit("Delete $$myRow[0]"),
 end_form;
		print "</td><td>", $$myRow[1], " </td><td> ", $$myRow[2],"</td><td>", $$myRow[3], "</td><td>", $$myRow[4], "</td></tr>\n";

        }
        # close your table
        print "</table>\n";
}

sub DeleteScheduleItem {
        my $schedid = shift;
        $sql="delete from schedule where id = \"$schedid\"";
        $sth=$dbh->prepare($sql);
        $sth->execute();
        print "Deleted id from schedule: $schedid <p>\n";
        ViewSchedule();
}



1;


