#!/usr/local/bin/perl
use warnings;
use strict;

use Test::More tests => 4;
use Config::Ini::Quote qw( :all );

my $bs = "\\";

is( unescape_for_double_quoted($bs),      $bs,      'lone backslash' );
is( unescape_for_double_quoted("$bs$bs"), $bs,      'double backslash' );
is( unescape_for_double_quoted("p$bs"),   "p$bs",   'ending backslash' );
is( unescape_for_double_quoted("${bs}p"), "${bs}p", 'spurious backslash' );

