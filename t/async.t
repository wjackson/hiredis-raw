use strict;
use warnings;
use Test::More;
use Test::Exception;

use Hiredis::Async;
use IO::Select;
use t::Redis;

test_redis {
    my $port = shift;

    my $redis = Hiredis::Async->new("127.0.0.1", $port);

    cmp_ok my $fd = $redis->GetFd, '>', 0, 'got fd';

    my $select = IO::Select->new($fd);

    ok $redis->HasBufferedWrites, 'write after connecting';

    $select->can_write;
    $redis->HandleWrite;

    ok !$redis->HasBufferedWrites, 'post connect write is complete';

    my @values;
    my $pong;
    my $error;

    $redis->Command(['PING'],              sub { $pong = $_[0] });
    $redis->Command([qw/LPUSH key value/], sub { } ) for 1..3;
    $redis->Command([qw/LRANGE key 0 2/],  sub { @values = @{$_[0]} });
    $redis->Command([qw/BOGUS/],           sub { $error = $_[1] });

    ok $redis->HasBufferedWrites, 'commands are buffered';

    $select->can_write;
    $redis->HandleWrite;

    ok !$redis->HasBufferedWrites, 'commands have been written';

    $select->can_read;
    $redis->HandleRead;

    is $pong, 'PONG', 'got PONG from PING';
    is_deeply \@values, [qw/value value value/], 'got values';
    is $error, q{ERR unknown command 'BOGUS'}, 'got error';

    ok !$redis->HasBufferedWrites, 'no new writes';
};

done_testing;
