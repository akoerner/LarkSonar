#!/usr/bin/env perl

use strict;
use warnings;

use LarkSonar::Common;

print LarkSonar::Common::list_all_endpoints_with_throughput_data_available("hcc-ps02.unl.edu");
