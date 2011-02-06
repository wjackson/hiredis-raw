use strict;
use warnings;
use Test::More;

use ok 'Hiredis::Raw::Constants', qw(REDIS_OK);

is REDIS_OK, 0, 'REDIS_OK';

done_testing();
