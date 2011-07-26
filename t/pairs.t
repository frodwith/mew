use warnings;
use strict;

use Test::More tests => 5;
use Test::Deep;
use Mew;

my $one = mew foo => 'bar';
my $two = extend $one, bar => 'baz', baz => 'qux';

cmp_bag [keys %$one], ['foo'];
cmp_bag [values %$one], ['bar'];
cmp_bag [keys %$two], ['bar', 'baz'];
cmp_bag [values %$two], ['baz', 'qux'];
cmp_bag [pairs $two], [[foo=>'bar'],[bar=>'baz'],[baz=>'qux']];
