use Test::Most tests => 7;

use ok( 'Search::Sitemap' );

my $baseurl = "http://www.jasonkohles.com/software/search-sitemap";

my $map;
ok( $map = Search::Sitemap->new( file => 'test.xml', pretty => 'indented' ) );
isa_ok( $map => 'Search::Sitemap' );
ok( $map->add( Search::Sitemap::URL->new(
    loc         => "$baseurl/test1",
    lastmod     => '2005-06-03',
    changefreq  => 'daily',
    priority    => 1,
) ) );
ok( $map->add(
    loc         => "$baseurl/test2",
    lastmod     => '2005-07-11',
    changefreq  => 'weekly',
    priority    => 0.1,
) );
ok( $map->add(
    loc         => "$baseurl/test2?foo=1&bar=2&baz=3>2",
    lastmod     => '2005-07-11',
    changefreq  => 'weekly',
    priority    => 0.1,
) );

ok( $map->write( 'test.xml' ) );

#eval "use XML::LibXML";
#my $HAVE_libxml = $XML::LibXML::VERSION;
#SKIP: {
#    skip "Need XML::LibXML for these tests", 1 unless $HAVE_libxml;
#    eval {
#        my $parser = XML::LibXML->new;
#        $parser->validation(1);
#        $parser->parse_file('test.xml');
#    };
#    ok(!$@,"test.xml validated with XML::LibXML");
#};
