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

# This will be 2 now because it will be called for on $b's destruction, and
# ALSO on $o's destruction ($b will no longer be referencing it as its
# prototype).
is $d, 2;
