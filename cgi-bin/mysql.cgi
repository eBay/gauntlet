#!/usr/bin/perl
# CGI script for managing MySQL cloud DB instances
# Adam Beeman (abeeman@ebay.com)
# eBay, Inc. 2011

use CGI qw/:standard/;

$hostname = `hostname`;
chomp $hostname;



##
## Functions
##
sub logIt {
	my $text = shift;
	my $date = `date`;
	chomp $date;
	my $logcmd = "echo $date : $ENV{'REMOTE_USER'} - $text  >> /var/www/clouddbsetup.log";
	#print "$logcmd", "\n" if ($DEBUG);
	`$logcmd`;
}



##
## Main
##

print header,
	start_html('QA Cloud DB Administration'),
	h1("Cloud DB Admin for $hostname"),
	h2("Welcome, $ENV{'REMOTE_USER'} !"),
	hr;


##
## Actions based on previous page views
##
if (param('start')) {
	print h3("starting mysql...");
	print "<pre>\n";
	my $result = `sudo /var/www/scripts/startup.pl`;
	print "</pre>\n";
	&logIt("startup");
	if ($result =~ /quit without updating file/) {
		print h3("Couldn't start MySQL - perhaps you need to provision a DB first?");
	} else {
		print h3("Done!");
	}
}
if (param('shutdown')) {
	print h3("Stopping mysql...");
	print "<pre>\n";
	print `sudo /var/www/scripts/shutdown.pl`;
	print "</pre>\n";
	&logIt("shutdown");
	print h3("Done!");
}
if (param('restart')) {
	print h3("Restarting mysql...");
	print "<pre>\n";
	print `sudo /var/www/scripts/bounce.pl`;
	print "</pre>\n";
	&logIt("restart");
	print h3("Done!");
}

if (param('decomm')) {
	print h3("cleaning up previous installation...");
	print "<pre>\n";
	print `sudo /var/www/scripts/nukedb.pl`;
	print `ps -eaf | grep mysqld | grep -v grep`;
	print "</pre>\n";
	&logIt("decomm");
	print h3("Done!");
}

if (param('schema')) {
	my $schema = param('schema');
	my $user = param('user');
	my $pass = param('pass');
	my $force = param('force');
	print "<pre>\n";
	print "Creating database...:\n";
	print `sudo /var/www/scripts/setupclouddb.pl -s $schema -u $user -p $pass`;
	print "\n\n";
	print "Command exited with status: ", $?, "\n"; 
        #print `ps -eaf | grep mysqld | grep -v grep`;
	print "</pre>\n";
	&logIt("create: -s $schema -u $user -p $pass");
	print h3("Done!");
		
}

##
## Status
##


print h2('MySQL Server Status');
$procs = `ps -eaf | grep mysqld | grep -v grep`;
chomp $procs;
if (! $procs) {
#	print "MySQL is NOT running.", p;
} else {
	print "MySQL is running.", p;
	print "<pre>\n";
	print "$procs\n";
	print "</pre>\n";
}

print "Jumpdbcloud Status:\n", p;
print "<pre>\n";
$jdbstatus = `sudo /var/www/scripts/status.pl`;
print $jdbstatus;
print "</pre>\n", hr;

##
## Buttons and Forms for performing various actions
##

print start_form, hidden('start', 'yes'), submit('Start MySQL'), end_form unless ($procs  || $jdbstatus =~ /decom was already done/);
print  start_form, hidden('shutdown', 'yes'), submit('Shutdown MySQL'), end_form if ($procs);
print start_form, hidden('restart', 'yes'), submit('Restart MySQL'), end_form if ($procs);
print start_form, hidden('decomm', 'yes'), submit('Remove all MySQL databases from this server'), end_form unless ($jdbstatus =~ /decom was already done/);


print hr, start_form, h3('Create a new MySQL database'), p,
	"Schema name: ",textfield('schema'),p,
	"Username: ",textfield('user'),p,
	"Password: ",textfield('pass'),p,
	submit('Create new database'), end_form, hr if ($jdbstatus =~ /decom was already done/);


##
## Extra Status and logs
##

if (-f "/var/www/current-config" && ! ($jdbstatus =~ /decom was already done/)) {
	print "Current connection information:", p;
	print `cat /var/www/current-config`, p;
}

print h3("Recent History (last 20 events) for $hostname");
print "<pre>\n";
print `tail -20 /var/www/clouddbsetup.log`;
print "</pre>\n";

print h3("Server Load average/uptime information for $hostname");
print p, `uptime`, p;

print h3("Disk space information for $hostname");
print p, "<pre>\n", `df -h`, "\n", p;

