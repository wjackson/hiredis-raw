use strict;
use warnings;
use Test::More;
use Test::Exception;

use Hiredis::Async;
use AnyEvent;
use t::Redis;

{ # Connection failure test

    # Connection problems are often not discovered until the first command is
    # executed. Here we test that they are noticed and reported properly.

    my $redis = Hiredis::Async->new('127.0.0.1', 12345);
    my $cv    = AE::cv;
    $cv->begin;

    cmp_ok my $fd = $redis->GetFd, '>', 0, 'got fd';

    my $pong;
    $redis->Command(['PING'], sub { $pong = $_[0]; $cv->end } );

    my $r = AnyEvent->io(
        fh   => $fd,
        poll => 'r',
        cb   => sub { $redis->HandleRead },
    );

    my $w = AnyEvent->io(
        fh   => $fd,
        poll => 'w',
        cb   => sub {
            throws_ok { $redis->HandleWrite } qr/Connection refused/, 'bad port';
            $r = undef;
            $cv->send;
        },
    );

    $cv->recv;

    is $pong, undef, 'no PONG from PING';
};

done_testing;
