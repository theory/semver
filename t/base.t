#!/usr/bin/env perl -w

use strict;
use warnings;
use Test::More tests => 395;
# use Test::More 'no_plan';

my $CLASS;
BEGIN {
    $CLASS = 'version::Semantic';
    use_ok $CLASS or die;
}

can_ok $CLASS, qw(
    new
    declare
    parse
    normal
    numify
    is_alpha
    is_qv
    compare
);

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
    0.0.0rc1
    v1.2.2
    999999999999999333333.0.0
) {
    isa_ok my $semver =$CLASS->new($v), $CLASS, "new($v)";
    my $str = $v =~ /^v/ ? substr $v, 1 : $v;
    is "$semver", $str, qq{$v should stringify to "$str""};
    is $semver->normal, $str, qq{$v should normalize to "$str"};

    ok $v =~ /0\.0\.0/ ? !$semver : !!$semver, "$v should be true";
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
    cmp_ok $l, '==', $r, "$l == $r";
    cmp_ok $l, '==', $r, "$l == $r";
    cmp_ok $l, '<=', $r, "$l <= $r";
    cmp_ok $l, '>=', $r, "$l >= $r";
    is $l cmp $r, 0, "$l cmp $r == 0";
    is $r cmp $l, 0, "$r cmp $l == 0";
    cmp_ok $l, 'eq', $r, "$l eq $r";
    cmp_ok $l, 'eq', $r, "$l eq $r";
    cmp_ok $l, 'le', $r, "$l le $r";
    cmp_ok $l, 'ge', $r, "$l ge $r";
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
    cmp_ok $l, '!=', $r, "$l != $r";
    cmp_ok $l, 'ne', $r, "$l ne $r";
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
    cmp_ok $l, '>',  $r, "$l > $r";
    cmp_ok $l, '>=', $r, "$l >= $r";
    cmp_ok $r, '<',  $l, "$r < $l";
    cmp_ok $r, '<=', $l, "$r <= $l";
    cmp_ok $l, 'gt', $r, "$l gt $r";
    cmp_ok $l, 'ge', $r, "$l ge $r";
    cmp_ok $r, 'lt', $l, "$r lt $l";
    cmp_ok $r, 'le', $l, "$r le $l";
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

# Compare to strings.
for my $v qw(
    1.2.0
    v1.2.0
) {
    my $semver = $CLASS->new($v);
    cmp_ok $semver, '==', $v, qq{$semver == "$v"};
    cmp_ok $v, '==', $semver, qq{"$v" == $semver};
    cmp_ok $semver, 'eq', $v, qq{$semver eq "$v"};
    cmp_ok $v, 'eq', $semver, qq{"$v" eq $semver};
}

# Test declare() and parse.
for my $spec (
    ['1.2.2',          '1.2.2'],
    ['01.2.2',         '1.2.2'],
    ['1.02.2',         '1.2.2'],
    ['1.2.02',         '1.2.2'],
    ['1.2.02b',        '1.2.2b'],
    ['1.2.02beta-3  ', '1.2.2beta-3'],
    ['1.02.02rc1',     '1.2.2rc1'],
    ['1.0',            '1.0.0'],
    ['.0.02',          '0.0.2'],
    ['1..02',          '1.0.2'],
    ['1..',            '1.0.0'],
    ['1.1',            '1.1.0',   '1.100.0'],
    ['1.1b1',          '1.1.0b1', '1.100.0b1'],
    ['1.2.b1',         '1.2.0b1'],
    ['1b',             '1.0.0b'],
    ['9.0beta4',       '9.0.0beta4'],
    ['9b',             '9.0.0b'],
    ['rc1',            '0.0.0rc1'],
    ['',               '0.0.0'],
    ['..2',            '0.0.2'],
    ['  012.2.2',      '12.2.2'],
    ['99999998',  '99999998.0.0'],
) {
    my $r = $CLASS->new($spec->[1]);
    isa_ok my $l = version::Semantic->_declare($spec->[0]), $CLASS,
        "$spec->[0] should be declarable as a semver";
    is $l->normal, $spec->[1], "... And it should be normalized to $spec->[1]";

    # Compare the non-semantic version string to the semantic one.
    cmp_ok $spec->[0], '==', $r, qq{$r == "$spec->[0]"};

    if ($spec->[0] && $spec->[0] !~ /^[a-z]/ && $spec->[0] !~ /[.]{2}/) {
        my $exp = $spec->[2] || $spec->[1];
        isa_ok $l = version::Semantic->parse($spec->[0]), $CLASS,
            "$spec->[0] should be parseable as a semver";
        is $l->normal, $exp, "... And it should be normalized to $exp";

        # Try with the parsed version.
        $r = $CLASS->new($spec->[2]) if $spec->[2];
        cmp_ok $l, '==', $r, qq{$l == $r};
    }
}
