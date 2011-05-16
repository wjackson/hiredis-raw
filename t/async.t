use strict;
use warnings;
use Test::More;
use Test::Exception;

use Hiredis::Async;
use IO::Select;
use t::Redis;

test_redis {
    my $port = shift;

    my $cleanup_cnt      = 0;
    my $write_watcher_on = 0;
    my $read_watcher_on  = 0;

    my $redis = Hiredis::Async->new(
        host => "127.0.0.1",
        port => $port,

        addRead  => sub { $read_watcher_on  = 1 },
        delRead  => sub { $read_watcher_on  = 0 },
        addWrite => sub { $write_watcher_on = 1 },
        delWrite => sub { $write_watcher_on = 0 },
        cleanup  => sub { $cleanup_cnt++   },
    );

    cmp_ok my $fd = $redis->GetFd, '>', 0, 'got fd';

    my $select = IO::Select->new($fd);
    ok $write_watcher_on, 'write after connecting';
    ok !$read_watcher_on, 'no results to read yet';

    $select->can_write;
    $redis->HandleWrite;
    ok !$write_watcher_on, 'finished post connect write';
    ok $read_watcher_on,   'read results';

    my @values;
    my $pong;
    my $error;

    $redis->Command(['PING'],              sub { $pong = $_[0] });
    $redis->Command([qw/LPUSH key value/], sub { } ) for 1..3;
    $redis->Command([qw/LRANGE key 0 2/],  sub { @values = @{$_[0]} });
    $redis->Command([qw/BOGUS/],           sub { $error = $_[1] });
    ok $write_watcher_on, 'commands are buffered';

    $select->can_write;
    $redis->HandleWrite;
    ok !$write_watcher_on, 'commands written';

    $select->can_read;
    $redis->HandleRead;

    ok $read_watcher_on, 'always be reading';

    is $pong, 'PONG', 'got PONG from PING';
    is_deeply \@values, [qw/value value value/], 'got values';
    is $error, q{ERR unknown command 'BOGUS'}, 'got error';

    ok !$write_watcher_on, 'no new commands';

    ok !$cleanup_cnt, 'no cleanup yet';

    $redis = undef;

    ok $cleanup_cnt, 'cleanup happened';
};

done_testing;
