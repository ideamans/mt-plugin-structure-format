package MT::StructureFormat::Util;

use strict;
use warnings;
use Data::Dumper;

use base qw(Exporter);

our @EXPORT = qw(plugin pp plugin_config format_dump format_load);

sub plugin { MT->component('StructureFormat'); }

sub pp { print STDERR Dumper(@_); }

sub plugin_config {
    my ( $blog_id, $param ) = @_;
    my $scope = $blog_id ? "blog:$blog_id" : "system";

    my %config;
    plugin->load_config(\%config, $scope);

    my $saving = 0;
    if ( ref $param eq 'HASH' ) {
        foreach my $k ( %$param ) {
            $config{$k} = $param->{$k};
        }
        $saving = 1;
    } elsif ( ref $param eq 'CODE' ) {
        $saving = $param->(\%config);
    }

    plugin->save_config(\%config, $scope) if $saving;
    \%config;
}

sub format_proc {
    my ( $proc, $format, $value, $args ) = @_;

    my $formats = MT->registry('structure_formats') || return;
    my $formatter = $formats->{lc($format)} || return;
    my $handler = $formatter->{$proc} || return;
    $handler = MT->handler_to_coderef($handler) || return;

    $handler->($value, $args);
}

sub format_dump {
    format_proc('dump', @_);
}

sub format_load {
    format_proc('load', @_);
}

1;
