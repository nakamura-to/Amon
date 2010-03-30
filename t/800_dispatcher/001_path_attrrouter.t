use strict;
use warnings;
use Test::More;
use Test::Requires 'Path::AttrRouter', 'Test::WWW::Mechanize::PSGI';

BEGIN {
    $INC{"MyApp.pm"}                = __FILE__;
    $INC{"MyApp/V/MT.pm"}           = __FILE__;
    $INC{"MyApp/Web/Dispatcher.pm"} = __FILE__;
};

{
    package MyApp;
    use Amon -base;
}

{
    package MyApp::Web;
    use Amon::Web -base => (
        default_view_class => 'MT',
    );
}

{
    package MyApp::Web::C;
    use base qw/Path::AttrRouter::Controller/;
    use Amon::Web::Declare;
    sub index :Path {
        my ($self, $c) = @_;
        res(200, [], 'index');
    }

    sub index2 :Path :Args(2) {
        my ($self, $c, $x, $y) = @_;
        res(200, [], "index2: $x, $y");
    }

    package MyApp::Web::C::Regex;
    use base qw/Path::AttrRouter::Controller/;
    use Amon::Web::Declare;

    sub index :Regex('^regex/(\d+)/(.+)') {
        my ($self, $c, $y, $m) = @_;
        res(200, [], "regexp: $y, $m");
    }
}

{
    package MyApp::Web::Dispatcher;
    use Amon::Web::Dispatcher::PathAttrRouter -base => (
        search_path => 'MyApp::Web::C',
    );
}

my $app = MyApp::Web->to_app();

my $mech = Test::WWW::Mechanize::PSGI->new(app => $app);
$mech->get_ok('/');
$mech->content_is('index');
$mech->get_ok('/a/b');
$mech->content_is("index2: a, b");
$mech->get_ok('/regex/1234/foo');
$mech->content_is( "regexp: 1234, foo");

done_testing;
