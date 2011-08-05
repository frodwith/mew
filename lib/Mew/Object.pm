package Mew::Object;

use warnings;
use strict;

require Scalar::Util;
require Mew;
require Mew::Tied;

use overload
    '%{}'    => sub {
        my $self = shift;
        $self->[2] ||= do {
            tie my %h, 'Mew::Tied', $self;
            \%h;
        };
    },
    fallback => 1;

our $AUTOLOAD;

sub _autoload {
    my ($self, $name) = @_;
    return $self->can($name);
}

sub _destroy { }

sub isa {
    my ($self, $class) = @_;
    return UNIVERSAL::isa($self, $class) unless Scalar::Util::blessed($self);
    my $proto = Mew::proto($self);
    return UNIVERSAL::isa($self, $class) unless $proto;
    return 1 if $proto eq $class;
    return $proto->isa($class) if $proto;
}

sub can {
    my ($self, $name) = @_;
    return UNIVERSAL::can($self, $name) unless Scalar::Util::blessed($self);

    my $o = $self;
    while ($o) {
        return UNIVERSAL::can($o, $name)
            unless eval { $o->isa('Mew::Object') };

        my $p = Mew::props($o);

        if (exists $p->{$name}) {
            my $val     = $p->{$name};
            my $reftype = Scalar::Util::reftype($val);
            return $val if $reftype && (
                $reftype eq 'CODE' || overload::Method($val, '&{}')
            );
            return '';
        }

        $o = Mew::proto($o);
    }

    if (my $loader = Mew::get($self, '_autoload')) {
        my $loaded = $self->$loader($name);
        return $loaded if $loaded;
    }

    return '';
}

sub AUTOLOAD {
    my $self = shift;
    (my $name = $AUTOLOAD) =~ s/.*://;
    my $code = $self->can($name);
    unless ($code) {
        my ($pkg, $fn, $line) = caller;
        die qq(Runtime error: Can't locate object method "$name" ) .
        qq(via package "Mew::Object" called at $fn line $line.);
    }
    $self->$code(@_);
}

sub DESTROY {
    my $self = shift;
    my $d = $self->can('_destroy');
    $self->$d() if $d;
}

1;
