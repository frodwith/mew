use warnings;
use strict;

use Test::More tests => 4;
use Mew;

my $o = mew (
    foo => sub { 'bar' },
);

ok $o->can('foo');
ok !$o->can('bar');

my $code = $o->can('foo');
is $o->can('foo'), $o->{foo};

my $o2 = extend $o;
is $o2->can('foo'), $o->{foo};
