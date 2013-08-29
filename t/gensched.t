#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin '$Bin';
use lib "$Bin/../lib";
use GenSched;

# prepare a very simple problem
my $gs = GenSched->new(
    slots           => [qw(foo bar)],
    classes         => [qw(A F)],
    person_groups   => [[qw(Aaron Berta)]],
);

# test the resulting list vector space
is_deeply $gs->list_vector_space, [
    [qw(Aaron Berta)],
    [qw(Aaron Berta)],
    [qw(A F)],
    [qw(A F)],
], 'right list vector space';

# prepare periodic callbacks: each 5/3 seconds
my $now = time;
my ($last_a, $last_b, $count_a, $count_b) = ($now - 5, $now, 0, 0);
$gs->register_callback(sub {
    is time - $last_a, 5, 'right period (5)';
    $last_a = time;
    $count_a++;
    $gs->done(1) if $count_a == 2; # disables evolution after 2 calls
});
$gs->register_callback(GenSched::PeriodicCallback->new(
    seconds => 3, last => $now, code => sub {
        is time - $last_b, 3, 'right period (3)';
        $last_b = time;
        $count_b++;
    },
));

# block until the periods are over
$gs->max_generations(42_000_000);
$gs->max_fitness(1_000_001);
my $solution = $gs->solution;
is time - $now, 5, 'right evolution duration';
is $count_a, 2, 'right number of period-5 calls';
is $count_b, 1, 'right number of period-3 calls';

# should have a full fitness score after five seconds
is $gs->fitness($solution), 1_000_000, 'full fitness';

# test constraints (removance) explicitely
is scalar(grep { $_->name eq 'persons' } @{$gs->constraints}), 1,
    'persons constraint exists';
is scalar(grep { $_->name eq 'classes' } @{$gs->constraints}), 1,
    'classes constraint exists';
$gs->remove_constraint('classes');
is scalar(grep { $_->name eq 'classes' } @{$gs->constraints}), 0,
    'classes constraint deleted';

done_testing;
