package Mew::Tied;

use warnings;
use strict;

require Mew;
require Tie::Hash;
our @ISA = qw(Tie::ExtraHash);

sub TIEHASH {
    my ($class, $o) = @_;
    return bless [Mew::props($o), $o], $class;
}

sub FETCH {
    my ($self, $key) = @_;
    Mew::get($self->[1], $key);
}

1;
