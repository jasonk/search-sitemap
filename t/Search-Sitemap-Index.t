use Test::Most tests => 6;
die_on_fail;

use ok( 'Search::Sitemap::Index' );

my $baseurl = "http://www.example.com";

my $index;
ok( $index = Search::Sitemap::Index->new( pretty => 'indented' ) );
isa_ok( $index => 'Search::Sitemap::Index' );
ok( $index->add( Search::Sitemap::URL->new(
    loc         => "$baseurl/test-sitemap-1.gz",
    lastmod     => '2005-06-03',
) ) );
ok( $index->add(
    loc         => "$baseurl/test-sitemap-2.gz",
    lastmod     => '2005-07-11',
) );

ok( $index->write( 'test-sitemap.gz' ) );
