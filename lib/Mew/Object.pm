package Mew::Object;

use warnings;
use strict;

require Scalar::Util;
require Mew;
require Mew::Hash;

use overload
    '%{}'    => sub {
        my $self = shift;
        Mew::ties($self) || do {
            tie my %h, 'Mew::Hash', $self;
            Mew::ties($self => \%h)
        };
    },
    fallback => 1;

our $AUTOLOAD;

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

    while ($self) {
        return UNIVERSAL::can($self, $name)
            unless eval { $self->isa('Mew::Object') };

        if (exists $self->{$name}) {
            my $prop = $self->{$name};
            return $prop
                if Scalar::Util::reftype($prop) eq 'CODE'
                || overload::Method($prop, '&{}');
            return '';
        }

        $self = Mew::proto($self);
    }
    return '';
}

sub AUTOLOAD {
    my $self = shift;
    (my $name = $AUTOLOAD) =~ s/.*://;
    my $code = $self->can($name);
    $self->$code(@_);
}

sub DESTROY {
    my $self = shift;
    if (my $d = $self->{DESTROY}) {
        $self->$d();
    }
    Mew::proto($self, undef);
    Mew::props($self, undef);
    Mew::ties($self, undef);
}

1;
