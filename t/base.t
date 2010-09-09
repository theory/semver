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
