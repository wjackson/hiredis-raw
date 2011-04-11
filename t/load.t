use strict;
use warnings;
use Test::More;
use Test::Exception;
use t::Redis;

use ok 'Hiredis::Raw';

my @version = Hiredis::Raw::Version();
is scalar @version,  3, 'got major/minor/patch';

throws_ok {
    Hiredis::Async->new('does-not-exist.example.com', 12345);
} qr/Can't resolve:/, q{dies when we can't resolve the host to connect to};

lives_ok {
    Hiredis::Async->new('localhost', 12345)
} q{don't notice a bogus port until at this point};

test_redis {
    my ($port) = @_;

    lives_ok {
        Hiredis::Async->new('localhost', $port)
    } 'can connect to localhost';
};

done_testing;
