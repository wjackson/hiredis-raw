package Hiredis::Async::AnyEvent;
use Moose;
use namespace::autoclean;
use Hiredis::Async;
use AnyEvent;

has 'redis' => (
    is         => 'ro',
    isa        => 'Hiredis::Async',
    lazy_build => 1,
    handles    => {
        GetFd       => 'GetFd',
        HandleRead  => 'HandleRead',
        HandleWrite => 'HandleWrite',
        Command     => '_Command',
    },
);

has 'watchers' => (
    is         => 'ro',
    isa        => 'ArrayRef',
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

sub _build_watchers {
    my $self = shift;
    my $fd = $self->GetFd;
    return [
        AnyEvent->io( fh => $fd, poll => 'r', cb => sub { $self->HandleRead  } ),
        AnyEvent->io( fh => $fd, poll => 'w', cb => sub { $self->HandleWrite } ),
    ];
}

sub BUILD {
    my $self = shift;
    $self->redis;
    $self->watchers;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 NAME

Hiredis::Async::AnyEvent - AnyEvent interface to hiredis.

=head1 SYNOPSIS

    my $redis = Hiredis::Async::AnyEvent->new;

    my $done = AE::cv;

    $redis->Command([qw/SET KEY VALUE/], sub {
        is $_[0], 'OK', 'got ok';

        $redis->Command([qw/GET KEY/], sub {
            is $_[0], 'VALUE', 'got VALUE for KEY';
            $done->send;
        });
    }); 

    $done->recv;
