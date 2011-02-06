use strict;
use warnings;
use Test::More;
use Test::Exception;

use Hiredis::Raw;

my $called = 0;
my $redis = Hiredis::Async->new('localhost');
$redis->_Command(['PING'], sub { diag $_[0]; $called++ });

for (1..100){
    $redis->HandleWrite();
    $redis->HandleRead();
}

cmp_ok $called, '>', 0, 'called callback';

done_testing;
