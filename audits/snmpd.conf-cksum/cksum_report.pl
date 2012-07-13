#!/usr/bin/perl

$datafile = "snmpd.conf";
$datadir = "/ebay/gauntlet/data";
#@doms = ("eva.ebay.com", "phx.ebay.com");
@doms = ("eva.ebay.com");

foreach $domain (@doms) {
        my %audit;
        print "auditing $domain\n";
        chdir("$datadir/$domain");
        my @results = `cksum */$datafile`;
        $nlines = $#results + 1;
        print "$domain: $nlines of results to parse\n";
        foreach $result (@results) {
                chomp $result;
                my ($cksum, $size, $filename) = split(" ", $result);
                my ($hostname, $junk) = split("/", $filename);
                next unless $hostname;
                $audit{"$datafile"}{"$cksum"}{"$hostname"} = $size;
        }
        print "results scanned...\n";
        my @uniquefiles = keys( %{ $audit{"$datafile"}});
        my $utotal = $#uniquefiles +1;
        print "A total of $utotal unique versions found\n";
        foreach $unique (@uniquefiles) {
                my @numhosts = keys(%{ $audit{"$datafile"}{"$unique"}});
                my $nhosts = $#numhosts + 1;
                print "  $nhosts\thave $datafile with cksum $unique:\n";
                print "\t", join(" ", keys(%{ $audit{"$datafile"}{"$unique"}})), "\n";
        }
}

