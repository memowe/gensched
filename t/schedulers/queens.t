#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use List::Util 'shuffle';

use FindBin '$Bin';
use lib "$Bin/../../lib";
use GenSched;
use GenSched::Constraint;

# an horrigly inefficient but working test for the n queens problem

# stringification
sub stringify_genes {
    my ($n, $genes) = @_;
    my $output      = '';
    for my $ri (reverse 0 .. $n-1) {
        for my $fi (0 .. $n-1) {
            $output .= $genes->[ $ri * $n + $fi ] . ' ';
        }
        $output .= "\n";
    }
    return $output;
}

# logging
sub evolution_log {
    my ($n, $gs)    = @_;
    my $gen         = $gs->_ga->generation;
    my $best        = $gs->_ga->getFittest;
    print "generation $gen with score " . $best->score . ":\n";
    print stringify_genes($n, scalar $best->genes);
}

# do a n queens run
sub queens_run {
    my $n           = shift;
    my @ranks       = 1 .. $n;
    my @files       = (42, 'a' .. 'z')[1 .. $n];
    my %file_index  = map {$files[$_] => $_} 0 .. $n-1;
    is $file_index{$files[$_]}, $_, 'right file index' for 0 .. $n-1;

    # prepare the problem
    my $gs = GenSched->new(
        slots           => [ map { my $f = $_; map "$f$_" => @ranks } @files ],
        classes         => ['dummy'],
        person_groups   => [['Q', '_']],
    );

    # disable normal scheduling constraints
    $gs->remove_constraint('persons');
    $gs->remove_constraint('classes');

    # right number of queens constraint with some tests
    my $number_of_queens = GenSched::Constraint->new(
        name => 'n queens',
        code => sub {
            0.5 ** abs($n - @{[ shift->slots_of_person('Q') ]});
        },
    );
    is $number_of_queens->fitness_factor(new GenSched::Allocation(
        slot_names      => $gs->slots,
        person_groups   => $gs->person_groups,
        classes         => $gs->classes,
        genes           => [
            shuffle( ('Q') x ($n-1), ('_') x ($n**2-($n-1)) ),
            ('dummy') x $n**2
        ],
    )), 0.5, 'right factor for n - 1 queens';
    is $number_of_queens->fitness_factor(new GenSched::Allocation(
        slot_names      => $gs->slots,
        person_groups   => $gs->person_groups,
        classes         => $gs->classes,
        genes           => [
            shuffle( ('Q') x $n, ('_') x ($n**2-$n) ),
            ('dummy') x $n**2
        ],
    )), 1, 'right factor for n queens';
    is $number_of_queens->fitness_factor(new GenSched::Allocation(
        slot_names      => $gs->slots,
        person_groups   => $gs->person_groups,
        classes         => $gs->classes,
        genes           => [
            shuffle( ('Q') x ($n+2), ('_') x ($n**2-($n+2)) ),
            ('dummy') x $n**2
        ],
    )), 0.25, 'right factor for n - 1 queens';
    $gs->register_constraint($number_of_queens);

    # queen-capture punishment
    my $queen_captures = GenSched::Constraint->new(
        name => 'queen captures queen',
        code => sub {
            my $allo    = shift;
            my $factor  = 1;

            # prepare sum hashes
            my %filesum     = map {$_ => 0} @files;
            my %ranksum     = map {$_ => 0} @ranks;
            my %diagupsum   = map {$_ => 0} 1 .. 2 * $n - 1;
            my %diagdownsum = map {$_ => 0} 1 .. 2 * $n - 1;

            # iterate slots
            for my $slot (@{$allo->slots}) {
                my ($f, $r) = $slot->{name} =~ /([a-z])(\d)/;

                # queen found
                if ($slot->{persons}[0] eq 'Q') {
                    
                    # remember rectangular position
                    $filesum{$f}++;
                    $ranksum{$r}++;
                    
                    # remember diagonals
                    my $diag_up     = $n + $file_index{$f} + 1 - $r;
                    my $diag_down   = $n + $file_index{$f} - ($n-$r);
                    $diagupsum{$diag_up}++;
                    $diagdownsum{$diag_down}++;
                }
            }

            # punish overfull files
            for my $file (grep {$filesum{$_} > 1} @files) {
                $factor *= 0.8 ** ($filesum{$file} - 1);
            }

            # punish overfull ranks
            for my $rank (grep {$ranksum{$_} > 1} @ranks) {
                $factor *= 0.8 ** ($ranksum{$rank} - 1);
            }

            # punish overfull up-diagonals
            for my $ud (grep {$diagupsum{$_} > 1} 1 .. 2*$n-1) {
                $factor *= 0.8 ** ($diagupsum{$ud} - 1);
            }

            # punish overfull down-diagonals
            for my $dd (grep {$diagdownsum{$_} > 1} 1 .. 2*$n-1) {
                $factor *= 0.8 ** ($diagdownsum{$dd} - 1);
            }

            # done
            return $factor;
        },
    );
    is $queen_captures->fitness_factor(new GenSched::Allocation(
        slot_names      => $gs->slots,
        person_groups   => $gs->person_groups,
        classes         => $gs->classes,
        genes           => [ ('_') x $n**2, ('dummy') x $n ],
    )), 1, 'empty board';
    is $queen_captures->fitness_factor(new GenSched::Allocation(
        slot_names      => $gs->slots,
        person_groups   => $gs->person_groups,
        classes         => $gs->classes,
        genes           => [
            ('Q', ('_') x ($n-1)) x 2, ('_') x ($n*($n-2)),
            ('dummy') x $n,
        ],
    )), 0.8, 'overfull file';
    is $queen_captures->fitness_factor(new GenSched::Allocation(
        slot_names      => $gs->slots,
        person_groups   => $gs->person_groups,
        classes         => $gs->classes,
        genes           => [
            'Q', ('_') x ($n-2), 'Q', ('_') x ($n*($n-1)),
            ('dummy') x $n,
        ],
    )), 0.8, 'overfull rank';
    is $queen_captures->fitness_factor(new GenSched::Allocation(
        slot_names      => $gs->slots,
        person_groups   => $gs->person_groups,
        classes         => $gs->classes,
        genes           => [
            '_', 'Q', ('_') x ($n-2), '_', '_', 'Q', ('_') x ($n-3),
            ('_') x ($n*($n-2)),
            ('dummy') x $n,
        ],
    )), 0.8, 'overfull up-diagonal';
    $gs->register_constraint($queen_captures);
    is $queen_captures->fitness_factor(new GenSched::Allocation(
        slot_names      => $gs->slots,
        person_groups   => $gs->person_groups,
        classes         => $gs->classes,
        genes           => [
            
            ('_') x $n, ('_') x ($n-1), 'Q', ('_') x ($n-2), 'Q', '_',
            ('_') x ($n*($n-2)),
            ('dummy') x $n,
        ],
    )), 0.8, 'overfull down-diagonal';
    $gs->register_constraint($queen_captures);

    # register periodic stringification
    if ($ENV{GENSCHED_QUEENS_LOG}) {
        $gs->register_callback(GenSched::PeriodicCallback->new(
            seconds => 2,
            code    => sub { evolution_log($n, $gs) },
        ));
    }

    # calculate a solution
    my $solution = $gs->solution;
    is $gs->fitness($solution->genes), 1_000_000, 'full fitness';
    if ($ENV{GENSCHED_QUEENS_LOG}) {
        print 'done: ';
        evolution_log($n, $gs);
    }
    return $solution;
}

# solve the 4 queens problem
my $four_queens = queens_run(4);
my $board       = join '' => @{$four_queens->genes}[0 .. 4**2-1];
ok $board eq '_Q_____QQ_____Q_' || $board eq '__Q_Q______Q_Q__', 'solved';

# solve a possibly bigger queens problem (optional; with logging)
SKIP: {
    skip 'set GENSCHED_QUEENS_N to 5, 6, 7 or 8 for a customized run.', 1
        unless  defined $ENV{GENSCHED_QUEENS_N}
                and     $ENV{GENSCHED_QUEENS_N} =~ /^[5-8]$/;
    $ENV{GENSCHED_QUEENS_LOG} = 1;
    queens_run($ENV{GENSCHED_QUEENS_N});
}

done_testing;
