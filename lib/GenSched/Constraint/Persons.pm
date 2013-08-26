package GenSched::Constraint::Persons;

use Mo;

sub name { 'persons' }

sub fitness_factor {
    my ($self, $allocation) = @_;

    # initial factor
    my $factor = 1;

    # per person group
    for my $pg (0 .. $#{ $allocation->slots->[0]{persons} }) {

        # count slots per person
        my %slot_count;
        for my $slot (@{ $allocation->slots }) {
            my $person = $slot->{persons}[$pg];
            $slot_count{$person}++;
        }

        # punish multiple slots
        $factor *= 0.1 ** ($_ - 1) for values %slot_count;
    }

    # done
    return $factor;
}

1;
__END__
