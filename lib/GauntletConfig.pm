#!/usr/bin/perl -I /ebay/gauntlet/lib

$gbase		= "/ebay/gauntlet";
$gdhost		= "localhost";
$gdb		= "gauntlet";
$gdbuser	= "gauntlet";
$gdbpass	= "ebaygauntlet";
$connectionInfo="DBI:mysql:database=$gdb;$gdhost:3306";


$iprepdbhost 	= $gdbhost;
$iprepdb	= "iprep";
$iprepuser	= $gdbuser;
$ipreppass	= $gdbpass;

$fping = "/usr/bin/fping";
$gauntlet_base = "/ebay/gauntlet";

# some hosts need /usr/local/bin/ssh
$ssh = "ssh";
$scp = "scp";

$spooldir = "$gauntlet_base/spool";

# is the default domain name for a host in one of these environments?
%domains = ( "eva" => "eva.ebay.com", "arch" => "arch.ebay.com", 
	"dev" => "arch.ebay.com", "qate" => "qa.ebay.com" );

%domain_keys = ( "eva.ebay.com" => ["eva_dsa", "eva_rsa"], "phx.ebay.com" => ["eva_dsa", "eva_rsa"], "arch.ebay.com" => ["dev_dsa", "dev_rsa"],
	 "qa.ebay.com" => ["dev_dsa", "dev_rsa"] ); 

# this value gets overridden later by either domain defaults or host-specific keys
$ssh_key = "-i $gauntlet_base/keys/id_dsa";

# can be overridden on a per host / per domain basis later
$ssh_options = "";
$ssh_user = "root";


$timeout = 60;
$datadir = "$gauntlet_base/data";
$logdir = "$gauntlet_base/logs";
mkdir($datadir);
mkdir($logdir);
$timedout = $logdir . "/timedout";
$noping = $logdir . "/noping";
$nodns = $logdir . "/nodns";
$nokeys = $logdir . "/nokeys";
$errors = $logdir .  "/errors";

$date =  `date +%Y-%m-%d-%H:%M`;chomp $date;


1;
