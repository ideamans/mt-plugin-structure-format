#!/usr/bin/perl
package MT::StructureFormat::Test;
use strict;
use warnings;
use utf8;
use FindBin qw($Bin);
use File::Spec;
use lib ("lib", "extlib");
use Test::More;

use MT;
use base qw( MT::Tool );
use Data::Dumper;
use Data::Dump::Color;

sub pp { dd($_) foreach @_ }

my $VERSION = 0.1;
sub version { $VERSION }

sub help {
    return <<'HELP';
OPTIONS:
    -h, --help             shows this help.
HELP
}

sub usage {
    return '[--help]';
}


## options
my ( $blog_id, $user_id, $verbose );

sub options {
    return (
    );
}

sub assert_template {
    my %args = @_;

    my @nodes = split( /::/, (caller(1))[3] );
    my $func = pop @nodes;

    require MT::Builder;
    require MT::Template::Context;
    my $ctx = MT::Template::Context->new;
    my $builder = MT::Builder->new;

    my $tokens = $builder->compile($ctx, $args{template}) or die $builder->errstr || 'Failed to compile.';

    $ctx->{__stash}->{vars} = $args{vars} || {};
    my $result = $builder->build($ctx, $tokens);

    if ( defined $result ) {
        $result =~ s/\s+$//gm;
        $result =~ s/^\n+//s;
        $result =~ s/\n+$//s;
        if ( defined( my $expect = $args{expect} ) ) {
            $expect =~ s/\s+$//gm;
            $expect =~ s/^\n+//s;
            $expect =~ s/\n+$//s;
            is($result, $expect, $func);
        }
    } else {
        if ( my $error = $args{error} ) {
            is($result, undef, $func);
        } elsif ( my $errstr = $args{errstr} ) {
            is($builder->errstr, $errstr, $func);
        }
    }
}

sub test_uses {
    use_ok('MT::StructureFormat::Util');
    use_ok('MT::StructureFormat::Format');
    use_ok('MT::StructureFormat::Tags');
}

sub test_simple {
    assert_template(
        template => <<"EOT",
<mtsf:Hash format="json">
  <mtsf:Value set_as="name1">value1</mtsf:Value>
</mtsf:Hash>
EOT
        expect => q({"name1":"value1"}),
    );
}

sub test_set_to_var {
    assert_template(
        template => <<"EOT",
<mtsf:Value set_as="var1">value1</mtsf:Value>
<mt:var name="var1">
EOT
        expect => <<"EXPECT"
value1
EXPECT
    );
}

sub test_complex {
    assert_template(
        template => <<"EOT",
<mtsf:Array format="json">
  <mtsf:Hash>
    <mtsf:Value set_as="name1">value1</mtsf:Value>
  </mtsf:Hash>
  <mtsf:Hash>
    <mtsf:Value set_as="name2">value2</mtsf:Value>
  </mtsf:Hash>
  <mtsf:Hash>
    <mtsf:Array set_as="array">
      <mtsf:Hash>
        <mtsf:Value set_as="nested">value</mtsf:Value>
      </mtsf:Hash>
    </mtsf:Array>
  </mtsf:Hash>
  <mtsf:Array>
    <mtsf:Value set_as="array1">array</mtsf:Value>
    <mtsf:Value set_as="array2">in</mtsf:Value>
    <mtsf:Value set_as="array3">array</mtsf:Value>
  </mtsf:Array>
</mtsf:Array>
EOT
        expect => q([{"name1":"value1"},{"name2":"value2"},{"array":[{"nested":"value"}]},["array","in","array"]]),
    );
}

sub test_modifier {
    assert_template(
        vars => { name1 => "value1" },
        template => <<"EOT",
<mtsf:Hash format="json">
  <mt:var name="name1" set_as="key">
</mtsf:Hash>
EOT
        expect => q({"key":"value1"}),
    );
}

sub test_var {
    assert_template(
        vars => {
            hash => {
                name1 => 'value1'
            },
            array => [ 'array1', 'array2' ]
        },
        template => <<"EOT",
<mtsf:Array format="json">
  <mtsf:var name="hash">
  <mtsf:Hash>
    <mtsf:var name="array" set_as="array">
  </mtsf:Hash>
</mtsf:Array>
EOT
        expect => q([{"name1":"value1"},{"array":["array1","array2"]}]),
    );
}

sub test_multi_args {
    assert_template(
        vars => {
            name1 => '{"child1":"value1"}'
        },
        template => <<"EOT",
<mtsf:Hash format="json">
<mt:var name="name1" set_as="name1","json">
</mtsf:Hash>
EOT
        expect => q({"name1":{"child1":"value1"}}),
    );
}

sub test_pretty_json {
    assert_template(
        template => <<"EOT",
<mtsf:Hash format="json","pretty">
  <mtsf:Value set_as="name1">value1</mtsf:Value>
</mtsf:Hash>
EOT
        expect => q({
   "name1" : "value1"
}),
    );
}

sub test_yaml {
    assert_template(
        vars => {
            yaml => <<"YAML"
array:
    -
        name1: value1
    -
        name2: value2
YAML
        },
        template => <<"EOT",
<mt:var name="yaml" set_as="data","yaml" setvar="null">
<mtsf:Var name="data" format="json">
<mtsf:Var name="data" format="yaml">
EOT
        expect => <<"EXPECT",
{"array":[{"name1":"value1"},{"name2":"value2"}]}
---
array:
  -
    name1: value1
  -
    name2: value2
EXPECT
    );
}

sub main {
    my $mt = MT->instance;
    my $class = shift;

    $verbose = $class->SUPER::main(@_);

    # Discover and run test_* subs
    no strict 'refs';
    my @subs = sort { $a cmp $b } grep { defined &{"$class\::$_"} && /^test_/ } keys %{"$class\::"};

    foreach (@subs) {
        &{"$class\::$_"}();
    }
}

__PACKAGE__->main() unless caller;

done_testing();
