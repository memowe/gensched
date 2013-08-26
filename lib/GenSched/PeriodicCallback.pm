package GenSched::PeriodicCallback;

use Mo qw(default required);

has seconds => (default => 5);
has last    => (default => 0);
has code    => (required => 1);

1;
__END__
