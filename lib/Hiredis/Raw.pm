package Hiredis::Raw;
use strict;
use warnings;
use XSLoader;
use XS::Object::Magic;

our $VERSION = '0.01';

XSLoader::load('Hiredis::Raw', $VERSION);

require Hiredis::Async;

1;

__END__

=pod

=head1 NAME

Hiredis::Raw - Perl binding for asychronous hiredis API

=head1 DESCRIPTION

For internal use only. See L<Hiredis::Async>.
