package Search::Sitemap::URLStore::Memory;
use strict; use warnings;
our $VERSION = '2.00';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
extends 'Search::Sitemap::URLStore';
use namespace::clean -except => 'meta';

has 'storage'   => ( is => 'ro', isa => 'HashRef', default => sub { {} } );

sub get {
    my ( $self, $url ) = @_;
    return $self->storage->{ $url };
}

sub put {
    my $self = shift;
    my $storage = $self->storage;
    for my $obj ( @_ ) { $self->storage->{ $obj->loc } = $obj }
}

sub all { return values %{ shift->storage } }

__PACKAGE__->meta->make_immutable;
1;
