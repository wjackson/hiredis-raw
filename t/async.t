use strict;
use warnings;
use Test::More;
use Test::Exception;

use Hiredis::Raw;

my $called = 0;
my $redis = Hiredis::Async->new('localhost');
my @values;
my $pong;

$redis->_Command(['PING'], sub { $pong = $_[0]; $called++ });
$redis->_Command([qw/LPUSH key value/], sub { $called++ }) for 1..3;
$redis->_Command([qw/LRANGE key 0 2/], sub { @values = @{$_[0]}; $called++ });

for (1..100){
    $redis->HandleWrite();
    $redis->HandleRead();
}

cmp_ok $called, '>=', 5, 'called callback';
is $pong, 'PONG', 'got PONG from PING';
is_deeply \@values, [qw/value value value/], 'got values';
done_testing;
