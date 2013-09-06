use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'gensched',
    VERSION             => '0.01',
    ABSTRACT            => 'Flexible genetic scheduling',
    AUTHOR              => 'Mirko Westermeier <mirko@westermeier.de>',
    LICENSE             => 'mit',
    META_MERGE          => {
        resources   => {
            repository  => 'https://github.com/memowe/gensced',
            bugtracker  => 'https://github.com/memowe/gensced/issues',
        },
    },
    MIN_PERL_VERSION    => '5.10.1',
    PREREQ_PM           => {
        'Scalar::Util'  => '1.21',
        'List::Util'    => '1.21',
        'Mo'            => '0.35',
        'AI::Genetic'   => '0.05',
    },
    test                => {TESTS => 't/*.t t/*/*.t'},
);
