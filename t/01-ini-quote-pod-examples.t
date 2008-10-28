#!/usr/local/bin/perl

use warnings;
use strict;

use Test::More tests => 34;

BEGIN { use_ok('Config::Ini::Quote') };

# SYNOPSIS
{
      use Config::Ini::Quote ':escape';

      binmode(STDOUT, ":utf8"); # to quiet warnings
      my $smiley = qq{\t"smiley":\x{263a}\n};

      $smiley = escape_for_double_quoted( $smiley );
      #print $smiley; # literally: \t"smiley":\u263A\n
is( $smiley, q{\t"smiley":\u263A\n}, "escape smiley".' ('.__LINE__.')' );

      $smiley = unescape_for_double_quoted( $smiley );
      #print $smiley; # same as: print qq{\t"smiley":\x{263a}\n};
is( $smiley, qq{\t"smiley":\x{263a}\n}, "unescape smiley".' ('.__LINE__.')' );

      use Config::Ini::Quote ':all';

      #print as_double_quoted( $smiley );
      # literally: "\t\"smiley\":\u263A\n"
is( as_double_quoted( $smiley ), q{"\t\"smiley\":\u263A\n"},
    'as_double_quoted'.' ('.__LINE__.')' );

      #print as_single_quoted( $smiley );
      # same as: print qq{'\t"smiley":\x{263a}\n'};
is( as_single_quoted( $smiley ), qq{'\t"smiley":\x{263a}\n'},
    'as_single_quoted'.' ('.__LINE__.')' );

      #print as_heredoc( value => $smiley,
      #    heretag => 'EOT', quote => '"' );
      # literally:
      # <<"EOT"
      # \t"smiley":\u263A
      # EOT
is( as_heredoc( value => $smiley,
    heretag => 'EOT', quote => '"' ), <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<"EOT"
	"smiley":\u263A
EOT
__

      $smiley =~ s/"/\\"/g; # prepare for parse
      #print parse_double_quoted( qq{"$smiley"} );
      # same as: print qq{\t"smiley":\x{263a}\n};
is( parse_double_quoted( qq{"$smiley"} ), qq{\t"smiley":\x{263a}\n},
    'parse_double_quoted'.' ('.__LINE__.')' );

      #print parse_single_quoted( "'''Hello, World.'''" );
      # 'Hello, World.'
is( parse_single_quoted( "'''Hello, World.'''" ), q{'Hello, World.'},
    'parse_single_quoted'.' ('.__LINE__.')' );
}

# FUNCTIONS
{
my $s = "<&>'\"\x00\x07\x08\x09\x0a\x0b\x0c\x0d\x1b\\\x85\xa0\x{2028}\x{2029}";
             my $e = escape_for_double_quoted( $s );
is( $e, q{<&>'"\0\a\b\t\n\v\f\r\e\\\\\N\_\L\P},
    'escape_for_double_quoted'.' ('.__LINE__.')' );

$e = escape_for_double_quoted( $s, ':html' );
is( $e, qq{&lt;&amp;&gt;'&quot;&#0;&#7;&#8;\t\n&#11;&#12;\r&#27;\\&#133;&nbsp;&#x2028;&#x2029;}, 'escape_for_double_quoted'.' ('.__LINE__.')' ); # note: qq

$e = escape_for_double_quoted( $s, ':slash:html' );
is( $e, q{&lt;&amp;&gt;'&quot;&#0;&#7;&#8;\t\n&#11;&#12;\r&#27;\\\\&#133;&nbsp;&#x2028;&#x2029;}, 'escape_for_double_quoted'.' ('.__LINE__.')' ); # note: q

my $smiley;
             $smiley = unescape_for_double_quoted( '\t"smiley":\u263a\n' );
is( $smiley, qq{\t"smiley":\x{263a}\n}, 'unescape_for_double_quoted'.' ('.__LINE__.')' );

$smiley = unescape_for_double_quoted( $e, ':slash:html' );
is( $smiley, $s, 'unescape_for_double_quoted'.' ('.__LINE__.')' );

$smiley = unescape_for_double_quoted( $e, ':html' );
is( $smiley, qq{<&>'"\0\a\b\\t\\n\x0b\x0c\\r\x1b\\\\\x85\xa0\x{2028}\x{2029}},
    'unescape_for_double_quoted'.' ('.__LINE__.')' );

             $e = as_double_quoted( $s );
is( $e, q{"<&>'\\"\0\a\b\t\n\v\f\r\e\\\\\N\_\L\P"},
    'escape_for_double_quoted'.' ('.__LINE__.')' );

             $e = as_single_quoted( $s );
is( $e, qq{'<&>''"\0\a\b\t\n\x0b\x0c\r\x1b\\\x85\xa0\x{2028}\x{2029}'},
    'escape_for_single_quoted'.' ('.__LINE__.')' );

             $s = qq{\t"smiley":\x{263a}\n};
             $e = as_heredoc(
                      value     => $s,   heretag => 'EOT',
                      herestyle => '<<', quote   => '"' );
             # <<"EOT"
             # \t"smiley":\u263A
             # EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<"EOT"
	"smiley":\u263A
EOT
__

             $e = as_heredoc( value => $s, quote => '"' );
             # <<""
             # \t"smiley":\u263A
             # <<
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<""
	"smiley":\u263A
<<
__

             $e = as_heredoc(
                 value => "Hey\n", heretag => 'EOT' );
             # <<EOT
             # Hey
             # EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<EOT
Hey
EOT
__

             $e = as_heredoc(
                 value => "Hey\n", heretag => 'EOT',
                 herestyle => '<<<<' );
             # <<EOT
             # Hey
             # <<EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<EOT
Hey
<<EOT
__

             $e = as_heredoc(
                 value => "Hey\n", heretag => 'EOT',
                 herestyle => '{' );
             # {EOT
             # Hey
             # EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
{EOT
Hey
EOT
__

             $e = as_heredoc(
                 value => "Hey\n", heretag => 'EOT',
                 herestyle => '{}' );
             # {EOT
             # Hey
             # }EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
{EOT
Hey
}EOT
__

             $s = qq{one\t"fish"\ntwo\t'fish'\n};
             $e = as_heredoc( value => $s, heretag => 'EOT', quote => '"' );
             # <<"EOT"
             # one\t"fish"
             # two\t'fish'
             # EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<"EOT"
one	"fish"
two	'fish'
EOT
__

             $e = as_heredoc( value => $s, heretag => 'EOT', quote => "'" );
             # <<'EOT'
             # one  "fish"
             # two  'fish'
             # EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<'EOT'
one	"fish"
two	'fish'
EOT
__

             $e = as_heredoc( value => $s, heretag => 'EOT' );
             # <<EOT
             # one  "fish"
             # two  'fish'
             # EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<EOT
one	"fish"
two	'fish'
EOT
__

             chomp $s;
             $e = as_heredoc( value => $s, heretag => 'EOT' );
             # <<EOT:chomp
             # one  "fish"
             # two  'fish'
             # EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<EOT:chomp
one	"fish"
two	'fish'
EOT
__

                $s = "vis-à-vis Beyoncé's naïve\n" .
                    "\tpapier-mâché résumé";
                $e = as_heredoc(
                    value     => $s,   heretag => 'EOT',
                    herestyle => '{}', quote   => 'double',
                    escape    => ':slash' );
                # {"EOT:chomp:slash"
                # vis-\xE0-vis Beyonc\xE9's na\xEFve
                # \tpapier-m\xE2ch\xE9 r\xE9sum\xE9
                # }EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
{"EOT:chomp:slash"
vis-\xE0-vis Beyonc\xE9's na\xEFve
	papier-m\xE2ch\xE9 r\xE9sum\xE9
}EOT
__

                $e = as_heredoc(
                    value     => $s,   heretag => 'EOT',
                    herestyle => '{}', quote   => 'double',
                    escape    => ':html' );
                # {"EOT:chomp:html"
                # vis-&agrave;-vis Beyonc&eacute;'s na&iuml;ve
                #   papier-m&acirc;ch&eacute; r&eacute;sum&eacute;
                # }EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
{"EOT:chomp:html"
vis-&agrave;-vis Beyonc&eacute;'s na&iuml;ve
	papier-m&acirc;ch&eacute; r&eacute;sum&eacute;
}EOT
__

                $e = as_heredoc(
                    value     => $s,   heretag => 'EOT',
                    herestyle => '{}', quote   => 'double',
                    escape    => ':html:slash' );
                # {"EOT:chomp:html:slash"
                # vis-&agrave;-vis Beyonc&eacute;'s na&iuml;ve
                # \tpapier-m&acirc;ch&eacute; r&eacute;sum&eacute;
                # }EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
{"EOT:chomp:html:slash"
vis-&agrave;-vis Beyonc&eacute;'s na&iuml;ve
	papier-m&acirc;ch&eacute; r&eacute;sum&eacute;
}EOT
__

                $e = as_heredoc(
                    value => "The quick brown fox\n" .
                        "jumped over the lazy dog\n",
                    indented => 1 );
                # <<:indented
                #     The quick brown fox
                #     jumped over the lazy dog
                # <<
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<:indented
    The quick brown fox
    jumped over the lazy dog
<<
__

                $e = as_heredoc( value => "Hey", heretag => 'EOT',
                    quote => "'", comment => 'This is a comment' );
                # <<'EOT:chomp' # This is a comment
                # Hey
                # EOT
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<'EOT:chomp' # This is a comment
Hey
EOT
__

                $e = as_heredoc( value => '{"a":1,"b":2,"c":3}',
                    extra => ':json' );
                # <<:chomp:json
                # {"a":1,"b":2,"c":3}
                # <<
is( $e, <<'__', 'as_heredoc'.' ('.__LINE__.')' );
<<:chomp:json
{"a":1,"b":2,"c":3}
<<
__

             $s = parse_double_quoted( q{"\t\\"smiley\\":\\u263a\n"} );
is( $s, qq{\t"smiley":\x{263a}\n},
    'parse_double_quoted'.' ('.__LINE__.')' );

             $s = parse_single_quoted( "'''Hello, World.'''" );
is( $s, q{'Hello, World.'}, 
    'parse_single_quoted'.' ('.__LINE__.')' );
}
