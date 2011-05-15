package Hiredis::Async;
use strict;
use warnings;
use Hiredis::Raw;

sub new {
    my ($class, @connect_args) = @_;
    my $self = bless {}, $class;
    $self->Connect(@connect_args);
    return $self;
}

sub DESTROY {
    my $self = shift;
    $self->Disconnect if $self->IsAllocated;
}

1;

__END__

=pod

=head1 NAME

Hiredis::Async - Perl binding for asychronous hiredis API

=head1 SYNOPSIS

  use Hiredis::Async;

  Hiredis::Async->new('127.0.0.1', 6379);

  $redis->Command(['PING'], sub {
    my $result = shift;
    say "the server said: $result"; # PONG
  });

  $redis->Command([qw/LPUSH key value/], sub {
    my ($result, $err) = @_;
    ...;
  });

  $redis->Command([qw/LRANGE key 0 2/], sub {
    my ($result, $err) = @_;
    my @list = @{ $result };
    ...;
  });

=head1 DESCRIPTION

The main entry point Command is how you interact with the Redis server.  It
takes two arguments: an array ref containing the Redis command and its
arguments, and a callback to call with the reply when it has arrived. 

The other commands deal with I/O to and from the server.  GetFd returns the
socket that's connected to the server. You can use this fd to poll for
readablity or writability with an event loop.  When this fd is readable, call
HandleRead.  When the fd is writable and BufferLength returns a number greater
than 0 call HandleWrite.  Note that if you don't check BufferLength and just
call HandleWrite then your program will use 100% cpu.

=head1 METHODS

=head2 new

Takes two mandatory arguments: host and port number.

=head2 Command

Takes an array ref representing a command to send to redis and calls a
callback with the result or error.

=head2 BufferLength

Returns the nubmer of bytes that need to be written to the Redis server.

=head2 GetFd

Returns the file descriptor being used to communicatote with the Redis server.

=head2 HandleRead

Reads as many bytes from the Redis server as possible without blocking.  It
may call callbacks if results are available.

=head2 HandleWrite

Write as many bytes to the Redis server as possible without blocking.

=head1 REPOSITORY

L<http://github.com/wjackson/hiredis-raw>

=head1 AUTHORS

Whitney Jackson C<< <whitney@cpan.org> >>

Jonathan Rockway C<< <jrockway@cpan.org> >>

=head1 SEE ALSO

L<Redis>, L<AnyEvent::Redis>
