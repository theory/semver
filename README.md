SemVer version 0.2.0
====================

This module subclasses [`version`] to create semantic versions, as defined by
the [Semantic Versioning Specification]. The two salient points of the
specification, for the purposes of version formatting, are:

1. A normal version number MUST take the form X.Y.Z where X, Y, and Z are
integers. X is the major version, Y is the minor version, and Z is the patch
version. Each element MUST increase numerically. For instance: 1.9.0 < 1.10.0
< 1.11.0.

2. A special version number MAY be denoted by appending an arbitrary string
immediately following the patch version. The string MUST be comprised of only
alphanumerics plus dash (`/0-9A-Za-z-/`) and MUST begin with an alpha
character (`/A-Za-z/`). Special versions satisfy but have a lower precedence
than the associated normal version. Precedence **should** be determined by
lexicographic ASCII sort order. For instance: 1.0.0beta1 < 1.0.0beta2 < 1.0.0.

[`version`]: http://search.cpan.org/perldoc?version
[Semantic Versioning Specification]: http://semver.org/

Installation
============

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Dependencies
------------

SemVer requires version.

Copyright and License
---------------------

Copyright (c) 2010 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
