package Hiredis::Async;
use strict;
use warnings;
use Hiredis::Raw;

sub new {
    my ($class, %connect_args) = @_;

    my $self = bless {}, $class;

    $self->Connect(
        $connect_args{host},
        $connect_args{port},
        $connect_args{addRead},
        $connect_args{delRead},
        $connect_args{addWrite},
        $connect_args{delWrite},
        $connect_args{cleanup},
    );

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

  Hiredis::Async->new(
      host => '127.0.0.1',
      port => 6379,

      # callbacks (optional)
      addRead  => sub { # add read event watcher     }
      delRead  => sub { # delete read event watcher  },
      addWrite => sub { # add write event watcher    },
      delWrite => sub { # delete write event watcher },
      cleanup  => sub { # perform cleanup operations },
  );

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

C<Hiredis::Async> contains Perl bindings for the asynchronous features of the
hiredis C library (L<https://github.com/antirez/hiredis>).

The main entry point c<Command> is how you interact with the Redis server.  It
takes two arguments: an array ref containing the Redis command and its
arguments, and a callback to call with the reply when it has arrived.

The other commands deal with I/O to and from the server.  GetFd returns the
socket that's connected to the server. You can use this fd to poll for
readablity or writability with an event loop.  When this fd is readable, call
HandleRead.  When the fd is writable and there are hiredis indicates there are
writes to perform, call HandleWrite.  Note under normal circumstances the fd
will be writable most of the time. So it's important to enable the callback
only when there are outstanding writes.  Otherwise your program will use 100%
even when idle.  Use the available callbacks to determine when there are
outstanding writes.

=head1 METHODS

=head2 new

Example:

  Hiredis::Async->new(
      host => '127.0.0.1',
      port => 6379,

      # callbacks (optional)
      addRead  => sub { # add read event watcher     }
      delRead  => sub { # delete read event watcher  },
      addWrite => sub { # add write event watcher    },
      delWrite => sub { # delete write event watcher },
      cleanup  => sub { # perform cleanup operations },
  );

Takes the following named arguments:

=over4

=item host

=item port

=back

The remaining constructor arguments are callbacks used to handle various
hiredis events.  They're all passed the Redis connection file descriptor as
their one and only argument.

=over4

=item addRead

Start the read watcher.

=item delRead

Stop the read watcher.

=item addWrite

Start the write watcher.

=item delRead

Stop the write watcher.

=item cleanup

Hiredis is about to cleanup.

=back

=head2 Command

Takes an array ref representing a command to send to Redis and calls a
callback with the result or error.

=head2 GetFd

Returns the file descriptor being used to communicate with the Redis server.

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
