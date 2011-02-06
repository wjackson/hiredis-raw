package Hiredis::Raw::Constants;
use strict;
use warnings;

my %CONSTANTS;

BEGIN {
    %CONSTANTS = (
        REDIS_ERR           => -1,
        REDIS_OK            => 0,
        REDIS_ERR_IO        => 1,
        REDIS_ERR_EOF       => 3,
        REDIS_ERR_PROTOCOL  => 4,
        REDIS_ERR_OTHER     => 2,
        REDIS_BLOCK         => 0x1,
        REDIS_CONNECTED     => 0x2,
        REDIS_DISCONNECTING => 0x4,
        REDIS_FREEING       => 0x8,
        REDIS_IN_CALLBACK   => 0x10,
        REDIS_SUBSCRIBED    => 0x20,
        REDIS_REPLY_STRING  => 1,
        REDIS_REPLY_ARRAY   => 2,
        REDIS_REPLY_INTEGER => 3,
        REDIS_REPLY_NIL     => 4,
        REDIS_REPLY_STATUS  => 5,
        REDIS_REPLY_ERROR   => 6,
    );

    no strict 'refs';
    for my $k (keys %CONSTANTS){
        *{$k} = sub () { $CONSTANTS{$k} };
    }
};

use Sub::Exporter -setup => {
    exports => [ keys %CONSTANTS ],
};

1;
