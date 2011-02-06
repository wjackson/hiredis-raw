package Hiredis::Raw;
use strict;
use warnings;
use XSLoader;
use XS::Object::Magic;

our $VERSION = '0.01';

XSLoader::load('Hiredis::Raw', $VERSION);

require Hiredis::Async;

1;
