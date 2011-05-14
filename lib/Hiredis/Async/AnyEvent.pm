package Hiredis::Async::AnyEvent;
# ABSTRACT: non-blocking hiredis based client
use Moose;
use namespace::autoclean;
use Hiredis::Async;
use AnyEvent;

has 'redis' => (
    is         => 'ro',
    isa        => 'Hiredis::Async',
    lazy_build => 1,
    handles => {
        GetFd        => 'GetFd',
        HandleRead   => 'HandleRead',
        HandleWrite  => 'HandleWrite',
        _Command     => 'Command',
        BufferLength => 'BufferLength',
    },
);

has 'read_watcher' => (
    is         => 'ro',
    lazy_build => 1,
);

has 'write_watcher' => (
    is         => 'ro',
    lazy_build => 1,
);

has 'host' => (
    is      => 'ro',
    isa     => 'Str',
    default => '127.0.0.1',
);

has 'port' => (
    is      => 'ro',
    isa     => 'Int',
    default => 6379,
);

sub _build_redis {
    my $self = shift;
    return Hiredis::Async->new($self->host, $self->port);
}

sub _build_read_watcher {
    my $self = shift;
    my $fd = $self->GetFd;
    return AnyEvent->io( fh => $fd, poll => 'r', cb => sub { $self->HandleRead  } );
}

sub _build_write_watcher {
    my $self = shift;
    my $fd = $self->GetFd;
    return AnyEvent->io( fh => $fd, poll => 'w', cb => sub {
        if ($self->BufferLength <= 0) {
            $self->clear_write_watcher;
        }
        else {
            $self->HandleWrite;
        }
    });
}

sub Command {
    my ($self, $cmd, $cb) = @_;

    $self->_Command($cmd, $cb);

    $self->write_watcher;
}

sub BUILD {
    my $self = shift;
    $self->redis;
    $self->read_watcher;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

Hiredis::Async::AnyEvent - hiredis AnyEvent client

=head1 SYNOPSIS

  use Hiredis::Async::AnyEvent;

  my $redis = Hiredis::Async::AnyEvent->new(
    host => '127.0.0.1',
    port => 6379,
  );

  $redis->Command( [qw/SET foo bar/], sub { warn "SET!" } );
  $redis->Command( [qw/GET foo/, sub { my $value = shift } );

  $redis->Command( [qw/LPUSH listkey value/] );
  $redis->Command( [qw/LPOP listkey/], sub { my $value = shift } );

  # errors
  $redis->Command( [qw/SOMETHING WRONG/, sub { my $error = $_[1] } );

=head1 DESCRIPTION

Hiredis::Async::AnyEvent is a non-blocking Redis client that uses the hiredis C
client library (L<https://github.com/antirez/hiredis>).

=head1 METHODS

=head2 new

  my $redis = Redis->new; # 127.0.0.1:6379

  my $redis = Redis->new( server => '192.168.0.1', port => '6379');

=head2 Command

  $redis->Command( ['SET', $key, 'foo'], sub {
      my ($result, $error) = @_;

      $result; # 'OK'
  });

  $redis->Command( ['GET', $key], sub {
      my ($result, $error) = @_;

      $result; # 'foo'
  });

If the Redis server replies with an error then C<$result> will be C<undef> and
C<$error> will contain the redis error string.  Otherwise C<$error> will be
C<undef>.

=head1 REPOSITORY

L<http://github.com/wjackson/hiredis-raw>

=head1 AUTHORS

Whitney Jackson

Jon Rockway

=head1 SEE ALSO

L<Redis>, L<AnyEvent>, L<AnyEvent::Redis>
