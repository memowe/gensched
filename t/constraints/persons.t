#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin '$Bin';
use lib "$Bin/../../lib";
use GenSched::Constraint;
use GenSched::Allocation;

# prepare constraint
my $constraint = $GenSched::Constraint::persons;
is $constraint->name, 'persons', 'right name';

# Chloro count 2
my $allo = GenSched::Allocation->new(
    genes           => [qw(Aaron Berta Chloro Chloro A F)],
    slot_names      => [qw(foo bar)],
    person_groups   => [[qw(Aaron Berta)], [qw(Chloro Dieter)]],
    classes         => [qw(A F)],
);
is $constraint->fitness_factor($allo), 0.1, 'right factor';

# one count 2 per group
$allo = GenSched::Allocation->new(
    genes           => [qw(Berta Berta Chloro Chloro A F)],
    slot_names      => [qw(foo bar)],
    person_groups   => [[qw(Aaron Berta)], [qw(Chloro Dieter)]],
    classes         => [qw(A F)],
);
is $constraint->fitness_factor($allo), 0.01, 'right factor';

# everything's fine
$allo = GenSched::Allocation->new(
    genes           => [qw(Aaron Berta Chloro Dieter A F)],
    slot_names      => [qw(foo bar)],
    person_groups   => [[qw(Aaron Berta)], [qw(Chloro Dieter)]],
    classes         => [qw(A F)],
);
is $constraint->fitness_factor($allo), 1, 'right factor';

done_testing;
