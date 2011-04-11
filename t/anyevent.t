use strict;
use warnings;
use Test::More;

use Hiredis::Raw::Constants qw(:all);
use Hiredis::Async::AnyEvent;
use t::Redis;

test_redis {
    my $port = shift;

    my $redis = Hiredis::Async::AnyEvent->new(port => $port);

    my $done = AE::cv;

    $redis->Command([qw/SET KEY VALUE/], sub {
        is $_[0], 'OK', 'got ok';

        $redis->Command([qw/GET KEY/], sub {
            is $_[0], 'VALUE', 'got VALUE for KEY';
            $done->send;
        });
    }); 


    my $cnt = 1;
    for my $e (qw(a b c)) {

        $redis->Command([qw/ZADD myzset 0 /, $e], sub {

            is $_[0], 1, 'got 1';

            return if $cnt++ < 3; 

            $redis->Command([qw/ZRANGE myzset 0 -1/], sub {
                my ($zrange) = @_;
                is_deeply $zrange, [qw(a b c)], 'ZRANGE';
                $done->send;
            });
        }); 
    }

    $done->recv;
};

done_testing;
