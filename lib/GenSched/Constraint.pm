package GenSched::Constraint;

use Mo qw(is required);

sub name {
    die 'unimplemented';
}

sub fitness_factor {
    my ($self, $allocation) = @_;
    die 'unimplemented';
}

1;
__END__
