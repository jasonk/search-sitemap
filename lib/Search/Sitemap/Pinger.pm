package Search::Sitemap::Pinger;
use strict; use warnings;
our $VERSION = '2.00';
our $AUTHORITY = 'cpan:JASONK';
use Moose;
use LWP::UserAgent;
use MooseX::Types::Moose qw( ArrayRef Str HashRef );
use MooseX::Types::URI qw( Uri );
use URI;
use Module::Find qw( usesub );
use Moose::Util::TypeConstraints;
use Class::Trigger qw(
    before_submit after_submit
    before_submit_url after_submit_url
    success failure
);
#use namespace::clean -except => [qw(
#    meta add_trigger call_trigger last_trigger_results
#)];

coerce( __PACKAGE__, from 'Str', via {
    my $class = join( '::', __PACKAGE__, $_ );
    Class::MOP::load_class( $class );
    return $class->new;
} );

sub ALL_PINGERS { grep { $_ ne __PACKAGE__ } usesub( __PACKAGE__ ) }

has 'user_agent'    => (
    is      => 'rw',
    isa     => 'LWP::UserAgent',
    lazy    => 1,
    default => sub {
        my $self = shift;
        LWP::UserAgent->new(
            timeout     => 10,
            env_proxy   => 1,
        );
    },  
);      

sub submit {
    my $self = shift;
    my $cb = ( ref $_[0] eq 'CODE' ) ? shift : undef;

    for my $url ( @_ ) {
        my $submit_url = $self->submit_url_for( "$url" );
        my $response = $self->user_agent->get( $submit_url );
        if ( $response->is_success ) {
            if ( $cb ) { $cb->( success => $url, $response->content ) }
            $self->call_trigger( success => $url, $response->content );
        } else {
            if ( $cb ) { $cb->( failure => $url, $response->status_line ) }
            $self->call_trigger( failure => $url, $response->status_line );
        }
    }
}

__PACKAGE__->meta->make_immutable;
1;
__END__

=head1 NAME

Search::Sitemap::Ping - Notify search engines of sitemap updates

=head1 SYNOPSIS

  use Search::Sitemap::Ping;
  
  my $ping = Search::Sitemap::Ping->new(
    'http://www.jasonkohles.com/sitemap.gz',
  );
  
  $ping->submit;
  
  for my $url ( $ping->urls ) {
      print "$url\n";
      for my $engine ( $ping->engines ) {
          printf( "    %25s %s\n", $engine, $ping->status( $url, $engine ) );
      }
  }

=head1 DESCRIPTION

This module makes it easy to notify search engines that your sitemaps, or
sitemap indexes, have been updated.  See L<Search::Sitemap> and
L<Search::Sitemap::Index> for tools to help you create sitemaps and indexes.

=head1 METHODS

=head2 new

Create a new L<Search::Sitemap::Ping> object.

=head2 add_url( @urls )

Add one or more urls to the list of URLs to submit.

=head2 urls

Return the list of urls that will be (or were) submitted.

=head2 add_engine( @engines )

Add one or more search engines to the list of search engines to submit to.

=head2 engines

Return the list of search engines that will be (or were) submitted to.

=head2 submit

Submit the urls to the search engines, returns the number of successful
submissions.  This module uses L<LWP::UserAgent> for the web-based submissions,
and will honor proxy settings in the environment.  See L<LWP::UserAgent> for
more information.

=head2 status( $url [, $engine ] )

Returns the status of the indicated submission.  The URL must be specified,
If an engine is specified it will return just the status of the submission
to that engine, otherwise it will return a hashref of the engines that the url
will be (or was) submitted to, and the status for each one.

The status may be one of:

=over 4

=item * undef or empty string

Not submitted yet.

=item * 'SUCCESS'

Succesfully submitted.  Note that this just means it was successfully
transferred to the search engine, if there are problems in the file the
search engine may reject it later when it attempts to use it.

=item * HTTP Error String

In case of an error, the error string will be provided as the status.

=back

=head1 MODULE HOME PAGE

The home page of this module is
L<http://www.jasonkohles.com/software/Search-Sitemap>.  This is where you
can always find the latest version, development versions, and bug reports.  You
will also find a link there to report bugs.

=head1 SEE ALSO

L<Search::Sitemap>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2005-2009 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

