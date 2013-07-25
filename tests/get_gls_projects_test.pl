#!/usr/bin/env perl

use strict;
use warnings;

use LarkSonar::Common; 

print LarkSonar::Common::get_gls_projects("http://ps4.es.net:9990/perfSONAR_PS/services/gLS");
