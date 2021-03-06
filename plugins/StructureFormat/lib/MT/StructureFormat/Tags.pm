package MT::StructureFormat::Tags;

use strict;
use warnings;

use MT::StructureFormat::Util;

sub set_as {
    my ( $ctx, $current, $value, $as ) = @_;

    # 属性が配列の場合、"キー名","フォーマット"と解釈する
    if ( ref $as eq 'ARRAY' ) {
        my $args = $as;
        my $name = shift @$args;
        my $format = shift @$args;

        $value = format_load($format, $value, $args);

        # 以後はasがテキストであることを期待する
        $as = $name;
    }

    $value = '' unless defined $value;
    if ( ref $current eq 'ARRAY' ) {
        push @$current, $value;
    } elsif ( ref $current eq 'HASH' ) {
        $current->{$as || '_'} = $value;
    } elsif ( defined($as) && $as ne '' ) {
        $ctx->var($as, $value);
    }

    1;
}

sub _format {
    my ( $ctx, $value, $format ) = @_;

    my $args = [];
    if ( ref $format eq 'ARRAY' ) {
        # 一つ目をフォーマット名、それ以後のパラメータとして期待する
        my $name = shift @$format;
        $args = $format;
        $format = $name;
    }

    if ( defined($format) && $format ne '' ) {
        defined ( my $result = format_dump($format, $value, $args) )
            || return $ctx->error(plugin->translate('Format "[_1]" is not found or not available.', $format));
        return $result;
    }

    "";
}

sub tag {
    my ( $default, $cb, $ctx, $args, $cond ) = @_;

    my $current = $ctx->{__stash}->{sf_current};
    local $ctx->{__stash}->{sf_current} = $default;

    my $builder = $ctx->stash('builder');
    my $tokens = $ctx->stash('tokens');
    defined ( my $out = $builder->build($ctx, $tokens, $cond) )
        || return $ctx->error($builder->errstr);

    my $value = $cb ? $cb->($out, @_) : $ctx->{__stash}->{sf_current};
    post_tag($value, $current, $ctx, $args);
}

sub post_tag {
    my ( $value, $current, $ctx, $args, $cond ) = @_;

    defined ( my $result = _format($ctx, $value, $args->{format}) )
        || return;

    my $as = delete $args->{set_as};
    if ( ref $value eq '' && !$args->{raw} ) {
        $value =~ s!^\s+|\s+$!!g;
    }
    defined ( set_as($ctx, $current, $value, $as) )
        || return;

    $result;
}

sub tag_Object {
    my ( $ctx, $args, $cond ) = @_;

    defined ( my $result = tag( {}, undef, @_ ) ) || return;
    $result;
}

sub tag_Array {
    my ( $ctx, $args, $cond ) = @_;

    defined ( my $result = tag( [], undef, @_ ) ) || return;
    $result;
}

sub tag_Value {
    my ( $ctx, $args, $cond ) = @_;

    my $cb = sub {
        my ( $value, $ctx ) = @_;
        $value;
    };
    defined ( my $result = tag( undef, $cb, @_ ) ) || return;
    $result;
}

sub tag_Var {
    my ( $ctx, $args, $cond ) = @_;

    my $current = $ctx->{__stash}->{sf_current};

    my $name = $args->{name} || '_';
    my $value = $ctx->var($name);

    post_tag($value, $current, @_);
}

sub tag_BulkTags {
    my ( $ctx, $args ) = @_;

    my $current = $ctx->{__stash}->{sf_current};

    my $special_args = {};
    foreach my $key ( keys %$args ) {
        if ( $key =~ /^:(.+)$/ ) {
            $special_args->{$1} = delete $args->{$key};
        }
    }

    my $prefix = $special_args->{prefix} || '';
    my $suffix = $special_args->{suffix} || '';

    my %tags;
    my %tag_args;
    foreach ( keys %$args ) {
        my $value = $args->{$_};
        my ( $as, $arg ) = split(/:/, $_, 2);
        if ( defined($arg) ) {
            $tag_args{$as} ||= {};
            $tag_args{$as}->{$arg} = $value;
        } elsif ( ref $value eq '' && $value ne '' ) {
            $tags{$as} = $value;
        }
    }

    foreach my $as ( keys %tags ) {
        my $tag = $args->{$as};
        my $tag_arg = $tag_args{$as} || {};

        $tag =~ s/^MT:?//i;
        $tag = "$prefix$tag$suffix";

        local $ctx->{'__stash'}{'tokens_else'} = undef;
        local $ctx->{_errstr} = undef;
        my $value = $ctx->tag( $tag, $tag_arg );

        set_as($ctx, $current, $value, $as);
    }

    '';
}

sub modifier_set_as {
    my ( $text, $arg, $ctx ) = @_;

    my $current = $ctx->{__stash}->{sf_current};
    set_as($ctx, $current, $text, $arg);

    $text;
}

1;
