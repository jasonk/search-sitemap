package Search::Sitemap::Types;
use strict; use warnings;
our $VERSION = '2.10';
our $AUTHORITY = 'cpan:JASONK';
use MooseX::Types -declare => [qw(
    SitemapURL SitemapUrlStore SitemapChangeFreq SitemapLastMod SitemapPriority
    XMLPrettyPrintValue XMLTwig SitemapPinger
)];
use MooseX::Types::Moose qw( Object HashRef Str Int Bool Num );
use MooseX::Types::URI qw( Uri );
use POSIX qw( strftime );

class_type( 'Search::Sitemap::URL' );
subtype SitemapURL, as 'Search::Sitemap::URL';

coerce SitemapURL,
    from HashRef, via {
        Class::MOP::load_class( 'Search::Sitemap::URL' );
        Search::Sitemap::URL->new( $_ );
    },
    from Str, via {
        Class::MOP::load_class( 'Search::Sitemap::URL' );
        Search::Sitemap::URL->new( loc => $_ );
    };

subtype XMLPrettyPrintValue, as Str, where {
    $_ =~ m{ ^ (
        none | nsgmls | nice | indented | indented_c | indented_a | cvs |
        wrapped | record | record_c
    ) $ }x;
};

coerce XMLPrettyPrintValue,
    from Int, via { $_ ? 'nice' : 'none' },
    from Str, via { $_ ? 'nice' : 'none' };

subtype SitemapChangeFreq, as Str, where {
    $_ =~ m{ ^ (
        always | hourly | daily | weekly | monthly | yearly | never
    ) $ }x;
};
coerce SitemapChangeFreq, from Str, via {
    my %types = (
        a => 'always',
        h => 'hourly',
        d => 'daily',
        w => 'weekly',
        m => 'monthly',
        y => 'yearly',
        n => 'never',
    );
    if ( m{ ^( [ahdwmyn] ) }ix ) { return $types{ lc $1 } }
    return;
};

my $lastmod_re = qr/ ^
    (\d\d\d\d-\d\d-\d\d)    # date
    (?:                     # time portion is optional
        [T\s]               # T or ' '
        (\d\d:\d\d)(:\d\d)? # time, with optional seconds
        (Z|\+\d\d?)(:\d\d)? # timezone offset, with optional seconds
    )?
$ /xi;

subtype SitemapLastMod, as Str, where { /$lastmod_re/ };

class_type 'DateTime';
class_type 'HTTP::Response';
class_type 'File::stat';
class_type 'Path::Class::File';

coerce SitemapLastMod,
    from Str, via {
        if ( /$lastmod_re/ ) {
            my ( $date, $time, $sec, $tzoff, $tzsec ) = ( $1, $2, $3, $4, $5 );

            return $date unless $time;

            $time .= $sec || ':00';

            if ( defined $tzsec ) { $tzoff .= $tzsec }

            if ( $tzoff =~ /^([+-])?(\d\d):?(\d\d)/ ) {
                $tzoff = sprintf( '%s%02d:%02d', $1 || '+', $2, $3 || 0 );
            } else {
                $tzoff = '+00:00';
            }
            return $date.'T'.$time.$tzoff;
        } elsif ( $_ eq 'now' ) {
            return strftime( "%Y-%m-%dT%H:%M:%S+00:00", gmtime( time ) );
        } elsif ( $_ =~ /^\d+$/ ) {
            return strftime( "%Y-%m-%dT%H:%M:%S+00:00", gmtime( $_ ) );
        } else {
            die "Unknown string value '$_'";
        }
    },
    from Num, via {
        return strftime( "%Y-%m-%dT%H:%M:%S+00:00", gmtime( $_ ) );
    },
    from 'DateTime', via {
        my ( $date, $tzoff ) = $_->strftime("%Y-%m-%dT%H:%M:%S","%z");
        if ( $tzoff =~ /^([+-])?(\d\d):?(\d\d)/ ) {
            $tzoff = sprintf( '%s%02d:%02d', $1 || '+', $2, $3 || 0 );
        } else {
            $tzoff = '+00:00';
        }
        return $date.$tzoff;
    },
    from 'HTTP::Response', via {
        my $modtime = $_->last_modified || ( time - $_->current_age );
        return strftime( "%Y-%m-%dT%H:%M:%S+00:00", gmtime( $modtime ) );
    },
    from 'File::stat', via {
        return strftime( "%Y-%m-%dT%H:%M:%S+00:00", gmtime( $_->mtime ) );
    },
    from 'Path::Class::File', via {
        return strftime( "%Y-%m-%dT%H:%M:%S+00:00", gmtime( $_->stat->mtime ) );
    };

subtype SitemapPriority, as Num, where { $_ >= 0 && $_ <= 1 };

class_type( 'Search::Sitemap::URLStore' );
subtype SitemapUrlStore, as 'Search::Sitemap::URLStore';

coerce SitemapUrlStore,
    from HashRef, via {
        my $type = $_->{ 'type' } || 'Memory';
        my $class = $type =~ /::/
            ? $type
            : 'Search::Sitemap::URLStore::'.$type;
        Class::MOP::load_class( $class );
        $class->new( $_ )
    },
    from Str, via {
        my $class = 'Search::Sitemap::URLStore::'.$_;
        Class::MOP::load_class( $class );
        return $class->new;
    };

class_type( 'XML::Twig' );

class_type( 'Search::Sitemap::Pinger' );

subtype SitemapPinger, as 'Search::Sitemap::Pinger';
coerce SitemapPinger, from Str, via {
    my $class = 'Search::Sitemap::Pinger::'.$_;
    Class::MOP::load_class( $class );
    return $class->new;
};

class_type( 'LWP::UserAgent' );

1;
__END__

=head1 NAME

Search::Sitemap::Types - MooseX::Types library for Search::Sitemap

=head1 DESCRIPTION

This is a L<MooseX::Types> library containing type constrations and coercions
for L<Search::Sitemap>.

=head1 SEE ALSO

L<Search::Sitemap>

L<MooseX::Types>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

