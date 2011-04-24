use strict;
use warnings;
use Test::More;
use Test::Exception;

use t::Redis;

use ok 'Hiredis::Async::AnyEvent';

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

    $redis->Command([qw/BOGUS/], sub {
        my ($result, $error) = @_;

        is $result, undef, 'got undefined result on error';
        is $error, q{ERR unknown command 'BOGUS'}, 'got error';

        $done->send;
    }); 

    $done->recv;
};

{ # connection errors

    # Hiredis is lazy about connecting to the redis server so connection
    # related errors can occur at different times.

    # unresolvable hostname is reported right away
    throws_ok { Hiredis::Async::AnyEvent->new(host => 'bogus') }
        qr/Can't resolve/, 'got connection failure';

    # bad port is reported when the first command is run
    my $redis = Hiredis::Async::AnyEvent->new(port => 12345);
    my $done  = AE::cv;
    $redis->Command([qw/GET KEY/], sub { $done->send }); 

    throws_ok { $done->recv } qr/Connection refused/,
        'got connection exception';
}

done_testing;
