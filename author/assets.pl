#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use 5.008001;
use LWP::UserAgent;
use autodie;
use Data::Dumper;
use File::Basename;
use File::Temp qw/tmpnam tempdir/;
use Archive::Zip;

my $ua = LWP::UserAgent->new();

&main;exit;

sub main {
    local $Data::Dumper::Terse = 1;

    if (@ARGV) {
        __PACKAGE__->can($ARGV[0])->();
    } else {
        run_blueprint();
        run_jquery();
    }
}

sub slurp {
    open my $fh, '<', shift;
    local $/;
    <$fh>;
}

sub run_blueprint {
    my $url = 'http://github.com/joshuaclayton/blueprint-css/tarball/master';

    my $fname = '/tmp/blueprint-asset.tgz';
    my $res = $ua->mirror($url, $fname);

    my $dir = tempdir(CLEANUP => 1);
    system("tar xzvf $fname -C $dir") == 0 or die "oops; $!";

    my ($screen_css) = glob("$dir/*/blueprint/screen.css");
    my ($print_css) = glob("$dir/*/blueprint/print.css");
    my ($ie_css) = glob("$dir/*/blueprint/ie.css");

    $screen_css or die;
    $print_css or die;
    $ie_css or die;

    open my $fh, '>:utf8', 'lib/Amon2/Setup/Asset/Blueprint.pm';
    print {$fh} sprintf(<<"...", Dumper(slurp $screen_css), Dumper(slurp $print_css), Dumper(slurp $ie_css));
# This file is generated by $0. Do not edit manually.
package Amon2::Setup::Asset::Blueprint;
use strict;
use warnings;

sub screen_css {
    %s
}

sub print_css {
    %s
}

sub ie_css {
    %s
}

1;
...
    close $fh;
}

sub run_jquery {
    my $url = 'http://code.jquery.com/jquery-1.5.1.min.js';
    my $res = $ua->get($url);
    $res->is_success or die "Cannot fetch $url: " . $res->status_line;

    my $jquery = $res->decoded_content;
    open my $fh, '>:utf8', 'lib/Amon2/Setup/Asset/jQuery.pm';
    print {$fh} sprintf(<<"...", Dumper(basename($url)), Data::Dumper::Dumper($jquery));
# This file is generated by $0. Do not edit manually.
package Amon2::Setup::Asset::jQuery;
use strict;
use warnings;

sub jquery_min_basename { %s }

sub jquery_min_content {
    %s
}

1;
...
    close $fh;
}


