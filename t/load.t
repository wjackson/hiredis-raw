use strict;
use warnings;
use Test::More;

use ok 'Hiredis::Raw';

my @version = Hiredis::Raw::Version();
is scalar @version,  3, 'got major/minor/patch';

done_testing;
