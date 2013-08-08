#!/usr/bin/env perl

use strict;
use warnings;

use LarkSonar::Common;

my $site = "perfsonar.icecube.wisc.edu";
my $source = "psonarl.fnal.gov";
my $destination = $site;
my $startUnixTimestamp =  time() - 36000000000;
my $endUnixTimestamp = time();
	
	
	
print LarkSonar::Common::get_throughput_between_two_endpoints($site, $source, $destination, $startUnixTimestamp, $endUnixTimestamp);
