package GenSched::PeriodicCallback;

use GenSched::Mo qw(default required);

has seconds => 5;
has last    => 0;
has code    => (required => 1);

1;
__END__
