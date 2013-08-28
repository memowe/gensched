#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin '$Bin';
use lib "$Bin/../../lib";
use GenSched;

# prepare a simple problem
my $gs = GenSched->new(
    slots           => [qw(slot1    slot2   slot3)],
    classes         => [qw(class1   class2  class3)],
    person_groups   => [[qw(woman1  woman2  woman3)], [qw(man1 man2 man3)]],
);

# add matching-numbers-constraint
$gs->register_constraint(sub {
    my $allocation  = shift;
    my $factor      = 1;

    # iterate slots
    for my $slot (@{$allocation->slots}) {
        my $slot_number = ($slot->{name} =~ /(\d)$/)[0];

        # punish not-matching persons
        for my $person (@{$slot->{persons}}) {
            my $person_number = ($person =~ /(\d)$/)[0];
            $factor *= 0.5 if $slot_number != $person_number;
        }

        # punish not-matching classes
        my $class_number = ($slot->{class} =~ /(\d)$/)[0];
        $factor *= 0.5 if $slot_number != $class_number;
    }

    # done
    return $factor;
});

# evolve!
my $solution = $gs->solution;
is $gs->fitness($solution->genes), 1_000_000, 'full fitness';
is_deeply $solution->slots, [
    {name => 'slot1', persons => [qw(woman1 man1)], class => 'class1'},
    {name => 'slot2', persons => [qw(woman2 man2)], class => 'class2'},
    {name => 'slot3', persons => [qw(woman3 man3)], class => 'class3'},
], 'right solution';

done_testing;
