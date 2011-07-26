# ABSTRACT: Prototypal Object System for Perl

my %proto;
my %ties;
my %props;

{
    package Mew;

    use warnings;
    use strict;

    use Scalar::Util qw(refaddr blessed);
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

    sub proto {
        my $id = refaddr shift;
        if (@_ > 0) {
            if (my $p = shift) {
                $proto{$id} = $p;
            }
            else {
                delete $proto{$id};
            }
        }
        $proto{$id};
    }

    sub extend {
        my ($proto, $props) = kwn @_, 1;
        my $o = do { \my $o };
        bless $o, 'Mew::Object';
        my $id = refaddr $o;
        proto($o => $proto);
        $props{$id} = $props;
        tie my %h, 'Mew::Object::Hash', $o;
        $ties{$id} = \%h;
        return $o;
    }

    sub own {
        my ($obj, $name) = @_;
        exists $props{refaddr $obj}{$name};
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
}

{
    package Mew::Object;

    use warnings;
    use strict;

    use overload 
        '%{}' => sub {
            my $self = shift;
            $ties{Scalar::Util::refaddr $self};
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
        my $id = Scalar::Util::refaddr($self);
        Mew::proto($self, undef);
        delete $ties{$id};
        delete $props{$id};
    }

}

{
    package Mew::Object::Hash;

    use warnings;
    use strict;

    use Scalar::Util qw(refaddr);
    require Tie::Hash;
    our @ISA = qw(Tie::ExtraHash);

    sub TIEHASH {
        my ($class, $o) = @_;
        return bless [$props{refaddr $o}, $o], $class;
    }

    sub FETCH {
        my ($self, $key) = @_;
        my $props = $self->[0];
        $self = $self->[1];
        while ($self) {
            my $h  = $props{refaddr $self};
            return $h->{$key} if exists $h->{$key};
            $self = Mew::proto($self);
        }
        return undef;
    }

}

1;
