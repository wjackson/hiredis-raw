use strict;
use warnings;
use Test::More;

use Hiredis::Async::AnyEvent;
use t::Redis;

test_redis {
    my $port = shift;

    my $redis = Hiredis::Async::AnyEvent->new(port => $port);

    my $done = AE::cv;

    $redis->Command([qw/SET KEY VALUE/], sub {
        diag "set key to value";
        is $_[0], 'OK', 'got ok';
        $redis->Command([qw/GET KEY/], sub {
            is $_[0], 'VALUE', 'got VALUE for KEY';
            $done->send;
        });
    });

    $done->recv;
};


done_testing;
