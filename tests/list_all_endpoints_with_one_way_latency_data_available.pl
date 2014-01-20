#!/usr/bin/env perl

use strict;
use warnings;

use LarkSonar::Common;

my $site = "perfsonar.icecube.wisc.edu";

print LarkSonar::Common::list_all_endpoints_with_one_way_latency_data_available($site);
