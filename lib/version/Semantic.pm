package version::Semantic;

use 5.10.0;
use strict;
# XXX I'm unable to override declare() if I explicitly `use version`. No idea
# why not. So don't load it for now. 5.8.x won't work, but meh.
#use version;
use Scalar::Util ();

use overload (
    '""'   => 'stringify',
    '<=>'  => \&compare,
    'cmp'  => \&compare,
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

sub _new {
    my $class = shift;
    $class = ref $class || $class;

    return bless {
        original => shift,
        qv       => 1,
        version  => shift,
    } => $class;
}

sub new {
    my ($class, $ival) = @_;

    # A vstring has only numbers, so just use them.
    return $class->_new($ival, [ map { ord } split // => $ival ])
        if Scalar::Util::isvstring($ival);

    # Get the parts and strip off optional leading "v".
    my @parts = split /[.]/ => $ival;
    $parts[0] =~ s/^v// if $parts[0];

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

    return $class->_new($ival, \@parts);
}

$VERSION = __PACKAGE__->new($VERSION); # For ourselves.

sub declare {
    my ($class, $ival) = @_;

    return $class->new($ival) if Scalar::Util::isvstring($ival);

    my @parts = split /[.]/ => $ival;
    $parts[0] =~ s/^v// if $parts[0];
    my @ret = do {
        no warnings;
        map { int $parts[$_] } 0..2;
    };
    if ($ival =~ /([a-zA-Z][-0-9A-Za-z]*)[[:space:]]*$/) {
        push @ret, $1;
    }

    return $class->_new($ival, \@ret);
}

sub parse {
    my ($class, $ival) = @_;

    return $class->new($ival) if Scalar::Util::isvstring($ival);

    (my $v = $ival) =~ s/([a-zA-Z][-0-9A-Za-z]*)[[:space:]]*$//;
    my $alpha = $1 || '';
    return $class->new(version->parse($v)->normal . $alpha);
}

sub normal   {
    my $version = shift->{version};
    my $format = '%s.%s.%s';
    $format   .= '%s' if @{ $version } == 4;
    sprintf $format, @{ $version }
}

sub numify    { _die 'Semantic versions cannot be numified'; }
sub is_alpha  { !!shift->{version}[3]; }
sub _bool     {
    my $v = shift->{version};
    return $v->[0] || $v->[1] || $v->[2];
}

sub compare {
    my ($left, $right, $rev) = @_;

    unless (eval { $right->isa(__PACKAGE__) }) {
        if (eval { $right->isa('version') }) {
            # Re-parse from the base class.
            $right = ref($left)->new($right->normal);
        } else {
            # try to bless $right into our class
            local $@;
            $right = eval { ref($left)->declare($right) };
            return -1 if $@;
        }
    }

    # Reverse?
    ($left, $right) = $rev
         ? ($right->{version}, $left->{version})
         : ($left->{version}, $right->{version});

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

=head2 Usage

For strict parsing of semantic version numbers, use the C<new()> constructor.
If you need something more flexible, use C<declare()>. And if you need
something more comparable with what L<version> expects, try C<parse()>.
Compare how these constructors deal with various version strings:

     String   | new        | declare    | parse
 -------------+------------+-------------------------
  '1.0.0'     | 1.0.0      | 1.0.0      | 1.0.0
  '5.5.2b1'   | 5.5.2b1    | 5.5.2b1    | 5.5.2b1
  '1.0'       | <error>    | 1.0.0      | 1.0.0
  '.0.02'     | <error>    | 0.0.2      | 0.0.2
  '1..'       | <error>    | 1.0.0      | <error>
  'rc1'       | <error>    | 0.0.0rc1   | <error>
  ''          | <error>    | 0.0.0      | <error>
  '  012.2.2' | <error>    | 12.2.2     | 12.2.2
  '1.1'       | <error>    | 1.1.0      | 1.100.0
  '1.1b1'     | <error>    | 1.1.0b1    | 1.100.0b1
  '1.2.b1'    | <error>    | 1.2.0b1    | 1.2.0b1
  '1b'        | <error>    | 1.0.0b     | 1.0.0b
  '9.0beta4'  | <error>    | 9.0.0beta4 | 9.0.0beta4

As with L<version> objects, the comparison and stringification operators are
all overloaded, so that you can compare semantic versions. You can also
compare semantic versions with version objects (but not the other way around,
alas). Boolean operators are also overloaded, such that all semantic version
objects except for those consisting only of zeros are considered true.

=head1 Interface

=head2 Constructors

=head3 C<new>

  my $semver = version::Semantic->new('1.2.2');

Performs a validating parse of the version string and returns a new semantic
version object. If the version string does not adhere to the semantic version
specification an exception will be thrown. See C<declare> and C<parse> for
more forgiving constructors.

=head3 C<declare>

  my $semver = version::Semantic->declare('1.2'); # 1.2.0

Similar to L<version>'s C<declare()> constructor, the parts of the version
string parsed are always considered to be integers. This method will also fill
in other missing parts.

This constructor uses the most forgiving parser. Consider using it to
normalize version strings.

=head3 C<parse>

  my $semver = version::Semantic->parse('1.2'); # 1.200.0

This parser dispatches to C<version>'s C<parse> constructor, which tries to be
more flexible in how it converts simple decimal strings. Some examples: Not
really recommended, but given the sorry history of version strings in Perl,
it's gotta be there.

=head2 Instance Methods

=head3 C<normal>

=head3 C<numify>

=head3 C<is_alpha>

=head3 C<compare>

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
