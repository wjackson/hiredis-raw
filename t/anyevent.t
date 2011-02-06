use strict;
use warnings;
use Test::More;
use Hiredis::Async::AnyEvent;
use feature 'say';

my $done = AE::cv;
my $redis = Hiredis::Async::AnyEvent->new;
$redis->Command([qw/SET KEY VALUE/], sub {
    say "set key to value";
    is $_[0], 'OK', 'got ok';
    $redis->Command([qw/GET KEY/], sub {
        is $_[0], 'VALUE', 'got VALUE for KEY';
        $done->send;
    });
});

$done->recv;

done_testing;
