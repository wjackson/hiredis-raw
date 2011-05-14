use strict;
use warnings;
use Test::More;
use Test::Exception;

use Hiredis::Async;
use AnyEvent;
# use Devel::Peek;

# Redis automatically frees the redis context causing major problems.  We make
# sure that we can't run any commands after this sort of error.

my $redis = Hiredis::Async->new('127.0.0.1', 12345);

# Dump($redis);
$redis->Command(['PING'], sub {} );

ok $redis->IsAllocated, 'make sure it got allocated';

eval {
    for (1..1000) {
        $redis->HandleWrite;
    }
};

like $@, qr/Connection refused/i, 'handle write failed';

ok !$redis->IsAllocated, 'make sure it got deallocated';
# Dump($redis);

done_testing;
