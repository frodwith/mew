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

        my $ex = eval { exists $o->{$name} };
        # lookup can fail during global destruction, or if someone does
        # something crazy like Sub::Delete-ing Mew::ties or something. If that
        # happens, we'll just say "no, we can't."
        return '' if $@;
        if ($ex) {
            my $prop = $o->{$name};
            my $reft = Scalar::Util::reftype($prop);
            return $prop if $reft && (
                $reft eq 'CODE' || overload::Method($prop, '&{}')
            );
            return '';
        }

        $o = Mew::proto($o);
    }

    if (my $loader = $self->{_autoload}) {
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
    if (my $d = $self->can('_destroy')) {
        $self->$d();
    }
    Mew::proto($self, undef);
    Mew::props($self, undef);
    Mew::ties($self, undef);
}

1;
