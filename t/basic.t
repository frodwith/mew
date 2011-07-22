use warnings;
use strict;

use Test::More tests => 22;
use Mew;

my $a = mew foo => 'bar';
is $a->{foo}, 'bar';
my $b = extend $a;

ok own($a, 'foo');
ok !own($b, 'foo');
is $b->{foo}, 'bar';
$a->{foo} = 'a';
is $b->{foo}, 'a';

$b->{foo} = 'b';
ok own($b, 'foo');
is $a->{foo}, 'a';
is $b->{foo}, 'b';

delete $b->{foo};
ok !own($b, 'foo');
is $b->{foo}, 'a';

$a->{add} = sub {
    my ($self, $a, $b) = @_;
    return $a + $b;
};

is $a->add(1, 2), 3;
is $b->add(1, 2), 3;

is proto($b), $a;

my $c = mew;
is proto($c), $Mew::Object;

proto($c => $a);
is proto($c), $a;

proto($c => $b);
is proto($c), $b;
ok $c->isa($a);

$c = extend $a, (
    foo => sub { 'foo' },
    bar => sub { 'bar' },
    baz => sub { 'baz' }
);
is proto($c), $a;

is ref $c->{foo}, 'CODE'; 
is $c->bar, 'bar';

$c = extend $a, (
    subtract => sub { my ($self, $a, $b) = @_; $a - $b }
);

is $c->add(2, 2), 4;
is $c->subtract(4, 2), 2;
