package GenSched::Constraint::Classes;

use Mo;
extends 'GenSched::Constraint';

sub name { 'classes' }

sub fitness_factor {
    my ($self, $allocation) = @_;

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
}

1;
__END__
