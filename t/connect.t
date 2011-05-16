use strict;
use warnings;
use Test::More;
use Test::Exception;

use IO::Select;
use Hiredis::Async;
use t::Redis;

{ # Connection failure test

    # Connection problems are often not discovered until the first command is
    # executed. Here we test that they are noticed and reported properly.

    my $redis = Hiredis::Async->new(host => '127.0.0.1', port => 12345);

    cmp_ok my $fd = $redis->GetFd, '>', 0, 'got fd';

    my $pong;
    $redis->Command(['PING'], sub { $pong = $_[0] } );

    my $select = IO::Select->new($fd);
    $select->can_write;

    throws_ok { $redis->HandleWrite } qr/Connection refused/, 'bad port';

    $select->can_read;
    throws_ok { $redis->HandleRead } qr/does not have a struct/, 
        'read after connection failure is invalid';

    is $pong, undef, 'no PONG from PING';
};

done_testing;
