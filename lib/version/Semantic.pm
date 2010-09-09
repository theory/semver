package version::Semantic;

use 5.6.2;
use strict;
use warnings;
use version;

our @ISA = qw(version);
our $VERSION = '0.1.0'; # For Module::Build
$VERSION = __PACKAGE__->new($VERSION); # For ourselves.


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
