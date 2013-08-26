#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use FindBin '$Bin';
use lib "$Bin/../../lib";
use GenSched::Allocation;
use GenSched::Constraint::Classes;

# prepare constraint
my $constraint = GenSched::Constraint::Classes->new();
is $constraint->name, 'classes', 'right name';

# A A instead of A B
my $allo = GenSched::Allocation->new(
    genes           => [qw(Aaron Berta Chloro Dieter A A)],
    slot_names      => [qw(foo bar)],
    person_groups   => [[qw(Aaron Berta)], [qw(Chloro Dieter)]],
    classes         => [qw(A B)],
);
is $constraint->fitness_factor($allo), 0.01, 'right factor';

# everything's fine
$allo = GenSched::Allocation->new(
    genes           => [qw(Aaron Berta Chloro Dieter A B)],
    slot_names      => [qw(foo bar)],
    person_groups   => [[qw(Aaron Berta)], [qw(Chloro Dieter)]],
    classes         => [qw(A B)],
);
is $constraint->fitness_factor($allo), 1, 'right factor';

done_testing;
