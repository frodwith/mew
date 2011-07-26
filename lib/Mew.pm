# ABSTRACT: Prototypal Object System for Perl

package Mew;

use warnings;
use strict;

require Mew::Object;
require Mew::Hash;

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

BEGIN {
    my $mk = sub {
        my $h = shift;
        sub {
            my $o = shift;
            my $i = refaddr $o;
            if (@_ > 0) {
                if (my $v = shift) {
                    $h->{$i} = $v;
                }
                else {
                    delete $h->{$i};
                }
            }
            return $h->{$i};
        };
    };

    *proto = $mk->(\my %proto);
    *props = $mk->(\my %props);
    *ties  = $mk->(\my %ties);
}

sub extend {
    my ($proto, $props) = kwn @_, 1;
    my $o = do { \my $o };
    bless $o, 'Mew::Object';
    proto($o => $proto);
    props($o => $props);
    tie my %h, 'Mew::Hash', $o;
    ties( $o => \%h);
    return $o;
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

1;
