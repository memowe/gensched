package GenSched;

use Mo qw(is required default);

use Scalar::Util 'blessed';
use AI::Genetic;
use GenSched::Allocation;
use GenSched::Constraint::Persons;
use GenSched::Constraint::Classes;
use GenSched::PeriodicCallback;

# problem description
has slots           => (is => 'ro', required => 1);
has classes         => (is => 'ro', required => 1);
has person_groups   => (is => 'ro', required => 1);

# resulting list vector space
has vector_space    => (is => 'ro', default => sub {[
    (map { my $pg = $_; map $pg => @{$_[0]->slots}  } @{$_[0]->person_groups}),
    (map { $_[0]->classes                           } @{$_[0]->slots}),
]});

# genetic algorithm configuration
has population      => (is => 'ro', default => 500);
has crossover       => (is => 'ro', default => 0.95);
has mutation        => (is => 'ro', default => 0.05);
has strategy        => (is => 'rw', default => 'tournamentTwoPoint');

# termination conditions
has max_fitness     => (default => 1_000_000);
has max_generations => (default => 5_000);
has done            => (default => undef);

# genetic algorithm object
has _ga             => (is => 'ro', default => sub {
    my $self = shift;

    # construct
    my $ga = AI::Genetic->new(
        -type           => 'listvector', # the way GenSched encodes allocations
        -population     => $self->population,
        -crossover      => $self->crossover,
        -mutation       => $self->mutation,
        -fitness        => sub { $self->fitness(@_) },
        -terminate      => sub { my $ga = shift;
            if ($ga->generation         >= $self->max_generations or
                $ga->getFittest->score  >= $self->max_fitness) {
                $self->done(1); # terminate the outside loop, too
                return 1;
            }
            return;
        }
    );

    # initialize list vector
    $ga->init($self->vector_space);

    # done
    return $ga;
});

# solution: building uses evolution
has solution        => (is => 'ro', default => sub {
    my $self = shift;

    # evolve (terminated by the ga terminate callback)
    while (not $self->done) {

        # next evolution step
        $self->_ga->evolve($self->strategy);

        # call periodic callbacks
        for my $cb (@{$self->callbacks}) {
            next if $cb->last + $cb->seconds > time;
            $cb->last(time);
            $cb->code->();
        }
    }

    # done
    return $self->best_solution;
});

# the best solution so far wrapped in a GenSched::Allocation object
sub best_solution {
    my $self = shift;

    # extract and build wrapper
    my $best_genes = $self->_ga->getFittest->genes;
    return GenSched::Allocation->new(
        slot_names      => $self->slots,
        classes         => $self->classes,
        person_groups   => $self->person_groups,
        genes           => $best_genes,
    );
}

# periodically called callbacks
has callbacks       => (default => []);

# register a periodic callback (code ref or a GenSched::PeriodicCallback object)
sub register_callback {
    my ($self, $cb) = @_;
    $cb = GenSched::PeriodicCallback->new(code => $cb) unless blessed $cb;
    push @{$self->callbacks}, $cb;
}

# constraints
has constraints     => (default => [
    GenSched::Constraint::Persons->new(),
    GenSched::Constraint::Classes->new(),
]);
sub register_constraint { push @{shift->constraints}, shift }

sub fitness {
    my ($self, $genes) = @_;

    # initial fitness
    my $fitness = 1_000_000;

    # prepare allocation
    my $allocation = blessed($genes) ? $genes : GenSched::Allocation->new(
        slot_names      => $self->slots,
        classes         => $self->classes,
        person_groups   => $self->person_groups,
        genes           => $genes,
    );

    # multiply with all constraints
    $fitness *= $_->fitness_factor($allocation) for @{ $self->constraints };

    # done
    return $fitness;
}

1;
__END__
