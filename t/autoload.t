use warnings;
use strict;

use Test::More tests => 8;
use Mew;

my $sw = sub {
    my $l = shift;
    sub {
        my ($self, $name) = @_;
        return sub { $name } if $name =~ /^$l/;
        return undef;
    };
};

my $a = mew {
    normal => sub { 'foo' },
    _autoload => $sw->('a'),
};

my $b = extend $a, {
    _autoload => $sw->('b'),
};

my $c = extend $a, {
    _autoload => sub {
        my ($self, $name) = @_;
        return sub { ':)' } if $name eq 'smiley';
        return proto($self)->_autoload($name);
    },
};

is $a->normal, 'foo';
is $a->albatross, 'albatross';
is $b->battlement, 'battlement';
eval { $a->battlement };
ok $@;
eval { $b->albatross };
ok $@;

is $c->smiley, ':)';
is $c->albatross, 'albatross';
is $b->battlement, 'battlement';
