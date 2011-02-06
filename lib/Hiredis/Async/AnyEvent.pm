package Hiredis::Async::AnyEvent;
# ABSTRACT:
use Moose;
use namespace::autoclean;
use Hiredis::Raw;
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

sub _build_redis {
    my $self = shift;
    return Hiredis::Async->new;
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
