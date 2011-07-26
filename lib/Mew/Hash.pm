package Mew::Hash;

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
    $self = $self->[1];
    while ($self) {
        my $h = Mew::props($self);
        return $h->{$key} if exists $h->{$key};
        $self = Mew::proto($self);
    }
    return undef;
}

1;
