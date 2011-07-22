my %proto;
my %ties;
my %props;

{
    package Mew;

    use warnings;
    use strict;

    use Scalar::Util qw(refaddr blessed);
    use Kwargs;
    use Sub::Exporter -setup => {
        exports => [qw(mew proto extend own)],
        groups => {
            default => [qw(mew proto extend own)],
        }
    };

    our $Object = extend(undef, {});

    sub mew { extend($Object, @_) };

    sub proto {
        my $id = refaddr shift;
        $proto{$id} = shift if @_ > 0;
        $proto{$id};
    }

    sub extend {
        my ($proto, $props) = kwn @_, 1;
        my $o = do { \my $o };
        bless $o, 'Mew::Object';
        my $id = refaddr $o;
        $proto{$id} = $proto;
        $props{$id} = $props;
        tie my %h, 'Mew::Object::Hash', $o;
        $ties{$id} = \%h;
        return $o;
    }

    sub own {
        my ($obj, $name) = @_;
        exists $props{refaddr $obj}{$name};
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
        my $proto = $proto{Scalar::Util::refaddr $self};
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

            $self = $proto{Scalar::Util::refaddr $self};
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
        delete $proto{$id};
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
            my $id = refaddr $self;
            my $h  = $props{$id};
            return $h->{$key} if exists $h->{$key};
            $self = $proto{$id};
        }
        return undef;
    }

}

1;
