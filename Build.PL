use strict;
use warnings;
use Module::Build;

Module::Build->new(
    module_name        => 'version::Semantic',
    license            => 'perl',
    configure_requires => {
        'Module::Build' => '0.30',
    },
    build_requires     => {
        'Module::Build'    => '0.30',
        'Test::More'       => '0.88',
    },
    requires           => {
        'version' => 0.82,
        'perl'    => 5.008001,
    },
    meta_merge         => {
        resources => {
            homepage    => 'http://search.cpan.org/dist/version-Semantic/',
            bugtracker  => 'http://github.com/theory/version-semantic/issues/',
            repository  => 'http://github.com/theory/version-semantic/tree/',
        }
    },
)->create_build_script;
