#!/usr/bin/env perl

use strict;
use warnings;

use LarkSonar::Common; 

print LarkSonar::Common::get_ls_sitelist("Internet2","http://ps4.es.net:9990/perfSONAR_PS/services/gLS");
