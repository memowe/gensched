package GenSched::Constraint;

use Mo qw(default required);

has name => 'anonymous';
has code => (required => 1);

sub fitness_factor {
    my ($self, $allocation) = @_;
    return $self->code->($allocation);
}

# some constraints GenSched needs every time

our $persons = GenSched::Constraint->new(
    name => 'persons',
    code => sub {
        my $allocation = shift;

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
    },
);

our $classes = GenSched::Constraint->new(
    name => 'classes',
    code => sub {
        my $allocation = shift;

        # initial factor
        my $factor = 1;

        # count expected distinct classes
        my %class;
        $class{$_}++ for @{ $allocation->classes };

        # count slots per class
        my %slot_count;
        for my $slot (@{ $allocation->slots }) {
            $slot_count{$slot->{class}}++;
        }

        # punish wrong number of slots
        while (my ($class, $count) = each %class) {
            $factor *= 0.1 ** abs(($count // 0) - ($slot_count{$class} // 0));
        }

        # done
        return $factor;
    },
);

1;
__END__
