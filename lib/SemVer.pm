package SemVer;

use 5.8.1;
use strict;
use version 0.82;
use Scalar::Util ();

use overload (
    '""'   => 'stringify',
    '<=>'  => 'vcmp',
    'cmp'  => 'vcmp',
);

our @ISA = qw(version);
our $VERSION = '0.1.0'; # For Module::Build

sub _die { require Carp; Carp::croak(@_) }

# Prevent version.pm from mucking with our internals.
sub import {}

# Borrowed from version.pm.
my $STRICT_INTEGER_PART = qr/0|[1-9][0-9]*/;
my $STRICT_DOTTED_INTEGER_PART = qr/\.[0-9]+/;
my $STRICT_DOTTED_INTEGER_VERSION =
    qr/ $STRICT_INTEGER_PART $STRICT_DOTTED_INTEGER_PART{2,} /x;
my $OPTIONAL_EXTRA_PART = qr/[a-zA-Z][-0-9A-Za-z]*/;

sub new {
    my ($class, $ival) = @_;

    # Handle vstring.
    return $class->SUPER::new($ival) if Scalar::Util::isvstring($ival);

    # Let version handle cloning.
    if (eval { $ival->isa('version') }) {
        my $self = $class->SUPER::new($ival);
        $self->{extra} = $ival->{extra};
        return $self;
    }

    my ($val, $extra) = (
        $ival =~ /^v?($STRICT_DOTTED_INTEGER_VERSION)($OPTIONAL_EXTRA_PART)?$/
    );
    _die qq{Invalid semantic version string format: "$ival"}
        unless defined $val;

    my $self = $class->SUPER::new($val);
    $self->{extra} = $extra;
    return $self;
}

$VERSION = __PACKAGE__->new($VERSION); # For ourselves.

sub declare {
    my ($class, $ival) = @_;
    return $class->new($ival) if Scalar::Util::isvstring($ival)
        or eval { $ival->isa('version') };

    (my $v = $ival) =~ s/($OPTIONAL_EXTRA_PART*)[[:space:]]*$//;
    my $extra = $1;
    $v =~ s/_//g; # ignore underscores.
    my $self = $class->SUPER::declare($v);
    $self->{extra} = $extra;
    return $self;
}

sub parse {
    my ($class, $ival) = @_;
    return $class->new($ival) if Scalar::Util::isvstring($ival)
        or eval { $ival->isa('version') };

    (my $v = $ival) =~ s/($OPTIONAL_EXTRA_PART*)[[:space:]]*$//;
    my $extra = $1;
    my $self = $class->SUPER::parse($v);
    $self->{extra} = $extra;
    return $self;
}

sub stringify {
    my $self = shift;
    return $self->SUPER::stringify . ($self->{extra} || '');
}

sub normal   {
    my $self = shift;
    (my $norm = $self->SUPER::normal) =~ s/^v//;
    if ($norm =~ s/_//g) {
        # Seems messed up. Should have three parts and no leading 0s.
        $norm = do {
            no warnings;
            join '.', map { int $_ } ( split /[.]/ => $norm )[0..2];
        };
    }
    return $norm . ($self->{extra} || '');
}

sub numify   { _die 'Semantic versions cannot be numified'; }
sub is_alpha { !!shift->{extra} }

sub vcmp {
    my $left  = shift;
    my $right = ref($left)->declare(shift);

    # Reverse?
    ($left, $right) = shift() ? ($right, $left): ($left, $right);

    # Major and minor win.
    if (my $ret = $left->SUPER::vcmp($right, 0)) {
        return $ret;
    } else {
        # They're equal. Check the extra text stuff.
        if (my $l = $left->{extra}) {
            my $r = $right->{extra} or return -1;
            return lc $l cmp lc $r;
        } else {
            return $right->{extra} ? 1 : 0;
        }
    }
}

1;
__END__

=head1 Name

SemVer - Use semantic version numbers

=head1 Synopsis

  use SemVer; our $VERSION = SemVer->new('1.2.0b1');

=head1 Description

This module subclasses L<version> to create semantic versions, as defined by
the L<Semantic Versioning Specification (SemVer)|http://semver.org/>. The two
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

    Argument  | new        | declare    | parse
 -------------+------------+-------------------------
  '1.0.0'     | 1.0.0      | 1.0.0      | 1.0.0
  '5.5.2b1'   | 5.5.2b1    | 5.5.2b1    | 5.5.2b1
  '1.0'       | <error>    | 1.0.0      | 1.0.0
  '  012.2.2' | <error>    | 12.2.2     | 12.2.2
  '1.1'       | <error>    | 1.1.0      | 1.100.0
   1.1        | <error>    | 1.1.0      | 1.100.0
  '1.1b1'     | <error>    | 1.1.0b1    | 1.100.0b1
  '1.2.b1'    | <error>    | 1.2.0b1    | 1.2.0b1
  '9.0beta4'  | <error>    | 9.0.0beta4 | 9.0.0beta4
  '9'         | <error>    | 9.0.0      | 9.0.0
  '1b'        | <error>    | 1.0.0b     | 1.0.0b
   0          | <error>    | 0.0.0      | 0.0.0
  '0rc1'      | <error>    | 0.0.0rc1   | 0.0.0rc1

As with L<version> objects, the comparison and stringification operators are
all overloaded, so that you can compare semantic versions. You can also
compare semantic versions with version objects (but not the other way around,
alas). Boolean operators are also overloaded, such that all semantic version
objects except for those consisting only of zeros are considered true.

=head1 Interface

=head2 Constructors

=head3 C<new>

  my $semver = SemVer->new('1.2.2');

Performs a validating parse of the version string and returns a new semantic
version object. If the version string does not adhere to the semantic version
specification an exception will be thrown. See C<declare> and C<parse> for
more forgiving constructors.

=head3 C<declare>

  my $semver = SemVer->declare('1.2'); # 1.2.0

This parser strips out any underscores from the version string and passes it
to to C<version>'s C<declare> constructor, which always creates dotted-integer
version objects. This is the most flexible way to declare versions. Consider
using it to normalize version strings.

=head3 C<parse>

  my $semver = SemVer->parse('1.2'); # 1.200.0

This parser dispatches to C<version>'s C<parse> constructor, which tries to be
more flexible in how it converts simple decimal strings and numbers. Not
really recommended, since it's treatment of decimals is quit different from
the dotted-integer format of semantic version strings, and thus can lead to
inconsistencies. Included only for proper compatibility with L<version>.

=head2 Instance Methods

=head3 C<normal>

  SemVer->declare('v1.2')->normal;      # 1.2.0
  SemVer->parse('1.2')->normal;         # 1.200.0
  SemVer->declare('1.02.0b1')->normal;  # 1.2.0b1
  SemVer->parse('1.02_30')->normal      # 1.230.0
  SemVer->parse(1.02_30)->normal        # 1.23.0

Returns a normalized representation of the version. This string will always be
a strictly-valid dotted-integer semantic version string suitable for passing
to C<new()>. Unlike L<version>'s C<normal> method, there will be no leading
"v".

=head3 C<stringify>

  SemVer->declare('v1.2')->stringify;    # v1.2
  SemVer->parse('1.200')->stringify;     # v1.200
  SemVer->declare('1.2b1')->stringify;   # v1.2b1
  SemVer->parse(1.02_30)->stringify;     # v1.0230
  SemVer->parse(1.02_30)->stringify;     # v1.023

Returns a string that is as close to the original representation as possible.
If the original representation was a numeric literal, it will be returned the
way perl would normally represent it in a string. This method is used whenever
a version object is interpolated into a string.

=head3 C<numify>

Throws an exception. Semantic versions cannot be numified. Just don't go
there.

=head3 C<is_alpha>

  my $is_alpha = $semver->is_alpha;

Returns true if an ASCII string is appended to the end of the version string.
This also means that the version number is a "special version", in the
semantic versioning specification meaning of the phrase.

=head3 C<vcmp>

Compares the semantic version object to another version object or string and
returns 0 if they're the same, -1 if the invocant is smaller than the
argument, and 1 if the invocant is greater than the argument.

Mostly you don't need to worry about this: Just use the comparison operators
instead. They will use this method:

  if ($semver < $another_semver) {
      die "Need $another_semver or higher";
  }

Note that in addition to comparing other semantic version objects, you can
also compare regular L<version> objects:

  if ($semver < $version) {
      die "Need $version or higher";
  }

You can also pass in a version string. It will be turned into a semantic
version object using C<declare>. So if you're using integer versions, you may
or may not get what you want:

  my $semver  = version::Semver->new('1.2.0');
  my $version = '1.2';
  my $bool    = $semver == $version; # true

If that's not what you want, pass the string to C<parse> first:

  my $semver  = version::Semver->new('1.2.0');
  my $version = version::Semver->parse('1.2'); # 1.200.0
  my $bool    = $semver == $version; # false

=head1 See Also

=over

=item * L<Semantic Versioning Specification|http://semver.org/>.

=item * L<version>

=item * L<version::AlphaBeta>

=back

=head1 Support

This module is managed in an open GitHub repository,
L<http://github.com/theory/semver/>. Feel free to fork and contribute, or to
clone L<git://github.com/theory/semver.git> and send patches!

Found a bug? Please L<post|http://github.com/theory/semver/issues> or
L<email|mailto:bug-semver@rt.cpan.org> a report!

=head1 Acknowledgements

Many thanks to L<version> author John Peacock for his suggestions and
debugging help.

=head1 Authors

David E. Wheeler <david@kineticode.com>

=head1 Copyright and License

Copyright (c) 2010 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
