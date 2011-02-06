use strict;
use warnings;
use Test::More;
use Test::Exception;

use ok 'Hiredis::Raw';

my @version = Hiredis::Raw::Version();
is scalar @version,  3, 'got major/minor/patch';

throws_ok {
    Hiredis::Async->new('does-not-exist.example.com', 12345);
} qr/Can't resolve:/, q{dies when we can't resolve the host to connect to};


my $redis;
lives_ok {
    $redis = Hiredis::Async->new('localhost', 6379);
} 'can connect to localhost';

done_testing;
