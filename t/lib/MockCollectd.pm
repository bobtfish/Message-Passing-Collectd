package # PAUSE HIDE
    Collectd;
use strict;
use warnings;

BEGIN {
    $INC{'Collectd.pm'} = 1;
}

use constant TYPE_WRITE => 'WRITE';

sub plugin_register {}

1;

