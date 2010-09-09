package version::Semantic;

use 5.8.0;
use strict;
# I'm unable to override declare() if I use version on 5.10 or higher.
# No idea why not. So only load it if it's not core.
#require version if $] < 5.010;
use version;
use Scalar::Util ();

use overload (
    '""'  => \&stringify,
    '<=>' => \&compare,
    'cmp' => \&compare,
    'bool' => \&_bool,
);

our @ISA = qw(version);
our $VERSION = '0.1.0'; # For Module::Build

sub _die {
    require Carp;
    Carp::croak(@_);
}

my $num_rx = qr{^(?:[1-9][0-9]*|0)$};
my $alnum_rx = qr{^(?:[1-9][0-9]*|0)([a-zA-Z][-0-9A-Za-z]*)?$};

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $ival  = shift;
    use Test::More;
    # A vstring has only numbers, so just use them.
    return bless [ map { ord } split // => $ival ] => $class
        if Scalar::Util::isvstring($ival);

    # Get the parts and strip off optional leading "v".
    $ival =~ s/^v//;
    my @parts = split /[.]/ => $ival;

    # Validate each part.
    _die qq{Invalid semantic version string format: "$ival"}
        unless @parts == 3
        && $parts[0] =~ $num_rx
        && $parts[1] =~ $num_rx
        && $parts[2] =~ $alnum_rx;

    # If we found an ASCII string, store it separately.
    if (my $ascii = $1) {
        $parts[2] =~ s{\Q$ascii\E$}{};
        push @parts, $ascii;
    }

    return bless \@parts => $class;
}

$VERSION = __PACKAGE__->new($VERSION); # For ourselves.

sub declare {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $ival  = shift;

    return $proto->new($ival) if Scalar::Util::isvstring($ival);

    $ival =~ s/^v//;
    my @parts = split /[.]/ => $ival;
    my @ret = do {
        no warnings;
        map { int $parts[$_] } 0..2;
    };
    if ($ival =~ /([a-zA-Z][-0-9A-Za-z]*)[[:space:]]*$/) {
        push @ret, $1;
    }

    return bless \@ret => $class;
}

sub parse {
    my $proto = shift;
    my $class = ref $proto || $proto;
    my $ival  = shift;

    return $proto->new($ival) if Scalar::Util::isvstring($ival);

    $ival =~ s/([a-zA-Z][-0-9A-Za-z]*)[[:space:]]*$//;
    my $str = $1 || '';
    return $proto->new(version->parse($ival)->normal . $str);
}

sub normal   {
    my $self   = shift;
    my $format = '%s.%s.%s';
    $format   .= '%s' if @{ $self } == 4;
    sprintf $format, @{ $self }
}

*stringify = \&normal;
sub numify   { _die 'Semantic versions cannot be numified'; }
sub is_alpha { !!shift->[3]; }
sub is_qv    { 1 }
sub _bool    { 1 }
*_declare = \&declare;
*_parse   = \&parse;

sub compare {
    my ($left, $right, $rev) = @_;

    unless (eval { $right->isa(__PACKAGE__) }) {
        if (eval { $right->isa('version') }) {
            # Re-parse from the base class.
            $right = ref($left)->new($right->normal);
        } else {
            # try to bless $right into our class
            local $@;
            $right = eval { ref($left)->_declare($right) };
            return -1 if $@;
        }
    }

    # Reverse?
    ($left, $right) = ($right, $left) if $rev;

    # Major and minor win.
    for my $i (0..1) {
        if (my $ret = $left->[$i] <=> $right->[$i]) {
            return $ret;
        }
    }

    # Gotta compare patch version and alpha.
    my $lnum = $left->[2];
    my $lstr = $left->[3];
    my $rnum = $right->[2];
    my $rstr = $right->[3];

    if ($lstr) {
        # non-ascii is greater than with ascii.
        return $lnum <=> $rnum || -1 if not $rstr;
        # Both strings are present.
        return $lnum <=> $rnum|| lc $lstr cmp lc $rstr;
    } else {
        # No special string, just compare integers.
        return $lnum <=> $rnum if not $rstr;
        # non-ascii is greater than with ascii.
        return $lnum <=> $rnum || 1;
    }
}

1;
__END__

=head1 Name

version::Semantic - Use semantic version numbers

=head1 Synopsis

  use version::Semantic;
  our $VERSION = version::Semantic->new('1.2.0b1');

=head1 Description

This module subclasses L<version> to create semantic versions, as defined
by the L<Semantic Versioning Specification (SemVer)|http://semver.org/>. The two
salient points of the specification, for the purposes of version formatting,
are:

=over

=item 1.

A normal version number MUST take the form X.Y.Z where X, Y, and Z are
integers. X is the major version, Y is the minor version, and Z is the patch
version. Each element MUST increase numerically. For instance: 1.9.0 E<lt>
1.10.0 E<lt> 1.11.0.

=item 2.

A special version number MAY be denoted by appending an arbitrary string
immediately following the patch version. The string MUST be comprised of only
alphanumerics plus dash (C</0-9A-Za-z-/>) and MUST begin with an alpha
character (C</A-Za-z/>). Special versions satisfy but have a lower precedence
than the associated normal version. Precedence B<should> be determined by
lexicographic ASCII sort order. For instance: 1.0.0beta1 E<lt> 1.0.0beta2
E<lt> 1.0.0.

=back

=head1 See Also

=over

=item * L<Semantic Versioning Specification|http://semver.org/>.

=item * L<version>

=item * L<version::AlphaBeta>

=back

=head1 Support

This module is managed in an open GitHub repository,
L<http://github.com/theory/version-semantic/>. Feel free to fork and
contribute, or to clone L<git://github.com/theory/version-semantic.git> and send
patches!

Found a bug? Please L<post|http://github.com/theory/version-semantic/issues>
or L<email|mailto:bug-version-semantic@rt.cpan.org> a report!

=head1 Authors

David E. Wheeler <david@kineticode.com>

=head1 Copyright and License

Copyright (c) 2010 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
