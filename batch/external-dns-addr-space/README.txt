IP Rep DB population

scan zone files for IP's.

Foreach IP found, run data collection script:

collecting A records - can grep dir for IP, get domain name from filename (db.XXX.YYY)
chain multiple A records into a CSV list?

it's obvious that PTR records will be a source of confusion and many errors 
ex. 8.0.120.117.in-addr.arpa = tools.ebay.com.au
smartrtm.ebay.in = 117.120.0.8

use whois + internal list of IP networks to ID physical location & whether eBay hosted

scripts:
addip.pl - add a single address to the DB
ipfinder.pl - parse a zone file for A records and add what's found. Reads stdin.
ipscanner.pl - walk through the addresses table, or update a single IP, run
	the various audits on it and update the table with results

truncate-addr-table.pl - delete all the records from the addresses table. Only used
	when repopulating the DB.

batch_job - top level script to be called by Gauntlet or Cron, that runs the entire audit

Still needed: data archiving methods. As it's possible to copy or rename tables, may want to do "snapshots" 
where previous data is preserved as a dated table name
