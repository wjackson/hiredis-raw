use strict;
use warnings;
use Test::More;
use Test::Exception;

use Hiredis::Async;
use AnyEvent;
use t::Redis;

test_redis {
    my $port = shift;

    my $redis = Hiredis::Async->new("127.0.0.1", $port);

    my $cv = AE::cv;
    $cv->begin for 1..5;
    
    my @values;
    my $pong;
    my $error;
    
    cmp_ok my $fd = $redis->GetFd, '>', 0, 'got fd';
    
    $redis->Command(['PING'], sub { $pong = $_[0]; $cv->end });
    $redis->Command([qw/LPUSH key value/], sub { $cv->end }) for 1..3;
    $redis->Command([qw/LRANGE key 0 2/], sub { @values = @{$_[0]}; $cv->end });
    $redis->Command([qw/BOGUS/], sub { $error = $_[1]; $cv->end });
    
    my $r = AnyEvent->io( fh => $fd, poll => 'r', cb => sub { $redis->HandleRead } );
    my $w = AnyEvent->io( fh => $fd, poll => 'w', cb => sub { $redis->HandleWrite } );
    $cv->recv;
    
    is $pong, 'PONG', 'got PONG from PING';
    is_deeply \@values, [qw/value value value/], 'got values';
    is $error, q{ERR unknown command 'BOGUS'}, 'got error';
};

done_testing;
