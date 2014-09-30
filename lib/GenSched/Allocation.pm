package GenSched::Allocation;

use GenSched::Mo qw(is required default build);

has genes           => (is => 'ro', required => 1);
has slot_names      => (is => 'ro', required => 1);
has person_groups   => (is => 'ro', required => 1);
has classes         => (is => 'ro', required => 1);

has slots => (default => sub {
    my $self = shift;
    return [ map {{
        name    => $_,
        persons => [],
        class   => undef,
    }} @{$self->slot_names} ];
});

sub BUILD {
    my $self = shift;

    # iterate person groups
    for my $pgi (0 .. $#{$self->person_groups}) {

        # iterate slots
        for my $si (0 .. $#{$self->slots}) {

            # find out allocation data
            my $slot    = $self->slots->[$si];
            my $person  = $self->genes->[$pgi * @{$self->slots} + $si];
            my $class   = $self->genes->[
                @{$self->person_groups} * @{$self->slots} + $si
            ];

            # store
            push @{$slot->{persons}}, $person;
            $slot->{class} //= $class;
        }
    }
}

sub slot {
    my ($self, $slot_name) = @_;

    # try to find the right slot
    for my $slot (@{$self->slots}) {
        return $slot if $slot->{name} eq $slot_name;
    }

    # nothing found
    return;
}

sub slots_of_person {
    my ($self, $person) = @_;

    # try to find the slots
    my @slots;
    for my $slot (@{$self->slots}) {
        push @slots, $slot if $person ~~ $slot->{persons};
    }

    # done
    return wantarray ? @slots : \@slots;
}

sub classes_of_person {
    my ($self, $person) = @_;

    # extract all classes from slots
    my @slots   = $self->slots_of_person($person);
    my @classes = map { $_->{class} } @slots;

    # done
    return wantarray ? @classes : \@classes;
}

sub slots_of_class {
    my ($self, $class) = @_;
    
    # try to find the slots
    my @slots;
    for my $slot (@{$self->slots}) {
        push @slots, $slot if $class eq $slot->{class};
    }

    # done
    return wantarray ? @slots : \@slots;
}

sub persons_of_class {
    my ($self, $class) = @_;

    # extract all persons from slots
    my @slots   = $self->slots_of_class($class);
    my @persons = map { @{$_->{persons}} } @slots;

    # extract unique persons
    @persons = sort keys %{{ map {$_ => 42} @persons }};

    # done
    return wantarray ? @persons : \@persons;
}

1;
__END__
