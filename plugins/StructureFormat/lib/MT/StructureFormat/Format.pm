package MT::StructureFormat::Format;

use strict;
use warnings;

use MT::Util;
use MT::Util::YAML;
use MT::StructureFormat::Util;

sub dump_json {
    my ( $value, $args ) = @_;

    my $param = {};
    $args = [] if ref $args ne 'ARRAY';
    foreach (@$args) {
        $param->{pretty} = 1 if $_ eq 'pretty';
        $param->{utf8} = 1 if $_ eq 'utf8';
    }

    eval { MT::Util::to_json($value, $param) };
}

sub load_json {
    my ( $value, $args ) = @_;
    eval { MT::Util::from_json($value) };
}

sub dump_yaml {
    my ( $value, $args ) = @_;
    MT::Util::YAML::Dump($value);
}

sub load_yaml {
    my ( $value, $args ) = @_;
    MT::Util::YAML::Load($value);
}

sub load_tags {
    my ( $value, $args ) = @_;
    my @tags = grep { defined($_) && $_ ne '' } map { s/^\s+|\s+$//g; $_ } split(/[\n,]/s, $value);
    \@tags;
}

1;
