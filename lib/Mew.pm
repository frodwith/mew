# ABSTRACT: Prototypal Object System for Perl

package Mew;

use warnings;
use strict;

require Mew::Object;

use Scalar::Util qw(refaddr);
use Kwargs;
use Sub::Exporter -setup => do {
    my @defaults = qw(mew proto extend own pairs);
    {
        exports => \@defaults,
        groups => { default => \@defaults }
    }
};


our $Object = extend(undef, {});

sub mew { extend($Object, @_) };

sub props { $_[0]->[0] }

sub proto {
    my $o = shift;
    $o->[1] = shift if @_ > 0;
    return $o->[1];
}

sub extend {
    my ($proto, $props) = kwn @_, 1;
    bless [ $props, $proto ], 'Mew::Object';
}

sub own {
    my ($obj, $name) = @_;
    exists props($obj)->{$name};
}

sub pairs {
    my $obj = shift;
    my @pairs;
    while ($obj) {
        push @pairs, [$_, $obj->{$_}] for keys %$obj;
        $obj = proto($obj);
    }
    return @pairs;
}

sub get {
    my ($self, $key) = @_;
    while ($self) {
        my $h = props($self);
        return $h->{$key} if exists $h->{$key};
        $self = Mew::proto($self);
    }
    return undef;
}

1;
