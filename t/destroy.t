use warnings;
use strict;

use Test::More tests => 4;
use Mew;

my $d = 0;
my $inc = sub { $d++ };

my $o = mew _destroy => $inc;

is $d, 0;
undef $o;
is $d, 1;

$d = 0;
$o = mew _destroy => $inc;
my $b = extend $o;
undef $o;

is $d, 0;
undef $b;
is $d, 1;
