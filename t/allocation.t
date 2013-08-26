#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin '$Bin';
use lib "$Bin/../lib";
use GenSched::Allocation;

# generate simple allocation
my $a = GenSched::Allocation->new(
    genes           => [qw(Aaron Berta Aaron Cyrill Dorian Dorian A B A)],
    slot_names      => [qw(foo bar baz)],
    person_groups   => [[qw(Aaron Berta)], [qw(Cyrill Dorian)]],
    classes         => [qw(A A B)],
);

# basics
isa_ok $a, 'GenSched::Allocation';
is_deeply $a->slots, [
    {name => 'foo', persons => [qw(Aaron Cyrill)], class => 'A'},
    {name => 'bar', persons => [qw(Berta Dorian)], class => 'B'},
    {name => 'baz', persons => [qw(Aaron Dorian)], class => 'A'},
], 'right slots generated from genes';

# find slots by name
is $a->slot('foo'), $a->slots->[0], 'right foo slot';
is $a->slot('bar'), $a->slots->[1], 'right bar slot';
is $a->slot('baz'), $a->slots->[2], 'right baz slot';

# find slots for a person
is_deeply [$a->slots_of_person('Aaron')], [$a->slot('foo'), $a->slot('baz')],
    'right slots for Aaron';
is_deeply [$a->slots_of_person('Berta')], [$a->slot('bar')],
    'right slots for Berta';
is_deeply [$a->slots_of_person('Cyrill')], [$a->slot('foo')],
    'right slots for Cyrill';
is_deeply [$a->slots_of_person('Dorian')], [$a->slot('bar'), $a->slot('baz')],
    'right slots for Dorian';

# find classes for a person
is_deeply [$a->classes_of_person('Aaron')], ['A', 'A'],
    'right classes for Aaron';
is_deeply [$a->classes_of_person('Berta')], ['B'],
    'right classes for Berta';
is_deeply [$a->classes_of_person('Cyrill')], ['A'],
    'right classes for Cyrill';
is_deeply [$a->classes_of_person('Dorian')], ['B', 'A'],
    'right classes for Dorian';

# find slots for a class
is_deeply [$a->slots_of_class('A')], [$a->slot('foo'), $a->slot('baz')],
    'right slots for class A';
is_deeply [$a->slots_of_class('B')], [$a->slot('bar')],
    'right slots for class B';

# find persons for a class
is_deeply [$a->persons_of_class('A')], [qw(Aaron Cyrill Dorian)],
    'right persons for class A';
is_deeply [$a->persons_of_class('B')], [qw(Berta Dorian)],
    'right persons for class B';

done_testing;
