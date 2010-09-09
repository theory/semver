#!/usr/bin/env perl -w

use strict;
use warnings;
#use Test::More tests => 113;
use Test::More 'no_plan';
use Test::MockModule;

my $CLASS;
BEGIN {
    $CLASS = 'version::Semantic';
    use_ok $CLASS or die;
}

# Try the basics.
isa_ok my $version = $CLASS->new('0.1.0'), $CLASS, 'An instance';

for my $v qw(
    1.2.2
    0.2.2
    1.2.2
    0.0.0
    0.1.999
    9999.9999999.823823
    1.0.0beta1
    1.0.0beta2
    1.0.0
    0.0.0
    0.0.0rc1
    v1.2.2
    999999999999999333333.0.0
) {
    isa_ok my $semver =$CLASS->new($v), $CLASS, "new($v)";
    my $str = $v =~ /^v/ ? substr $v, 1 : $v;
    is "$semver", $str, qq{$v should stringify to "$str""};
    is $semver->normal, $str, qq{$v should normalize to "$str"};

    ok !!$semver, "$v should be true";
    ok $semver->is_qv, "$v should be dotted-decimal";

    my $is_alpha = $semver->is_alpha;
    if ($v =~ /[.]\d+[a-z]/) {
        ok $is_alpha, "$v should be alpha";
    } else {
        ok !$is_alpha, "$v should not be alpha";
    }
}

local $@;
eval { $CLASS->new('') };
ok $@, 'Empty string should be an invalid version';

for my $bv qw(
    1.2
    0
    0.0
    1.2b
    1.b
    1.65.r2
) {
    local $@;
    eval { $CLASS->new($bv) };
    like $@, qr{Invalid semantic version string format: "$bv"},
        qq{"$bv" should be an invalid semver};
}

# Try a vstring.
isa_ok $version = $CLASS->new(v2.3.2), $CLASS, 'vstring version';

# Numify should die
local $@;
eval { $version->numify };
like $@, qr{Semantic versions cannot be numified},
    'Should get error from numify()';

# Now do some comparisons. Start with equivalents.
for my $spec (
    [ '1.2.2',        '1.2.2' ],
    [ '1.2.23',       '1.2.23' ],
    [ '0.0.0',        '0.0.0' ],
    [ '999.888.7777', '999.888.7777' ],
    [ '0.1.2beta3',   '0.1.2beta3' ],
    [ '1.0.0rc-1',    '1.0.0RC-1' ],
) {
    my $l = $CLASS->new($spec->[0]);
    my $r = $CLASS->new($spec->[1]);
    is version::Semantic::compare($l, $r), 0, "compare($l, $r) == 0";
    is $l <=> $r, 0, "$l <=> $r == 0";
    is $r <=> $l, 0, "$r <=> $l == 0";
    ok $l == $r, "$l == $r";
    ok $l == $r, "$l == $r";
    ok $l <= $r, "$l <= $r";
    ok $l >= $r, "$l >= $r";
    is $l cmp $r, 0, "$l cmp $r == 0";
    is $r cmp $l, 0, "$r cmp $l == 0";
    ok $l eq $r, "$l eq $r";
    ok $l eq $r, "$l eq $r";
    ok $l le $r, "$l le $r";
    ok $l ge $r, "$l ge $r";
}

# Test not equal.
for my $spec (
    ['1.2.2', '1.2.3'],
    ['0.0.1', '1.0.0'],
    ['1.0.1', '1.1.0'],
    ['1.1.1', '1.1.0'],
    ['1.2.3b', '1.2.3'],
    ['1.2.3', '1.2.3b'],
    ['1.2.3a', '1.2.3b'],
    ['1.2.3aaaaaaa1', '1.2.3aaaaaaa2'],
) {
    my $l = $CLASS->new($spec->[0]);
    my $r = $CLASS->new($spec->[1]);
    cmp_ok version::Semantic::compare($l, $r), '!=', 0, "compare($l, $r) != 0";
    ok $l != $r, "$l != $r";
    ok $l ne $r, "$l ne $r";
}

# Test >, >=, <, and <=.
for my $spec (
    ['2.2.2', '1.1.1'],
    ['2.2.2', '2.1.1'],
    ['2.2.2', '2.2.1'],
    ['2.2.2b', '2.2.1'],
    ['2.2.2', '2.2.2b'],
    ['2.2.2c', '2.2.2b'],
    ['2.2.2rc-2', '2.2.2RC-1'],
    ['0.9.10', '0.9.9'],
) {
    my $l = $CLASS->new($spec->[0]);
    my $r = $CLASS->new($spec->[1]);
    cmp_ok version::Semantic::compare($l, $r), '>', 0, "compare($l, $r) > 0";
    cmp_ok version::Semantic::compare($r, $l), '<', 0, "compare($r, $l) < 0";
    ok $l >  $r, "$l > $r";
    ok $l >= $r, "$l >= $r";
    ok $r <  $l, "$r < $l";
    ok $r <= $l, "$r <= $l";
    ok $l gt $r, "$l gt $r";
    ok $l ge $r, "$l ge $r";
    ok $r lt $l, "$r lt $l";
    ok $r le $l, "$r le $l";
}

# Compare to version objects.
my $semver = $CLASS->new('1.2.0');
for my $v qw(
    1.002
    1.2.0
    v1.002
    v1.2.0
) {
    my $version = version->new($v);
    ok $semver == $version, "$semver == $version";
}
