#!/usr/local/bin/perl
use warnings;
use strict;

use Test::More tests => 41;
use Config::Ini::Quote qw( :all );

Subs: {
    my $s1 = <<'__';
\v\e\n\t\\\P\0\r\N\_\f\L\a\b
__
    chomp $s1;
    my $e1 =
        "\x0b\x1b\x0a\x09\\" .
        "\x{2029}\x00\x0d\x85\xa0" .
        "\x0c\x{2028}\x07\x08";
    my $d1 = '\\x61\\x62\\x63\\x64\\x65';
    my $d2 = '&#x61;&#x62;&#x63;&#x64;&#x65;';
    my $d3 = '\\x0061\\x0062\\x0063\\x0064\\x0065';
    my $d4 = '\\u0061\\u0062\\u0063\\u0064\\u0065';
    my $e2 = "abcde";

# unescape_for_double_quoted( $to_unescape, $types );
    my $e = unescape_for_double_quoted( $s1 );
    is( $e, $e1, "unescape_for_double_quoted" );

    $e = unescape_for_double_quoted( $d1 );
    is( $e, $e2, "unescape_for_double_quoted" );

    $e = unescape_for_double_quoted( $d2, ':html' );
    is( $e, $e2, "unescape_for_double_quoted" );

    $e = unescape_for_double_quoted( $d3 );
    is( $e, $e2, "unescape_for_double_quoted" );

    $e = unescape_for_double_quoted( $d4 );
    is( $e, $e2, "unescape_for_double_quoted" );

# escape_for_double_quoted( $to_escape, $types )
    my $s = "\r\a\f\t\e\n";
    $e = escape_for_double_quoted( $s );
    is( $e, '\\r\\a\\f\\t\\e\\n', "escape_for_double_quoted" );

    $e = escape_for_double_quoted( $s, ":html" );
    is( $e, "\r&#7;&#12;\t&#27;\n", "escape_for_double_quoted" );

    $e = escape_for_double_quoted( $s, ":slash:html" );
    is( $e, "\\r&#7;&#12;\\t&#27;\\n", "escape_for_double_quoted" );

# as_double_quoted( $to_quote )
    $e = as_double_quoted( $s );
    is( $e, '"\\r\\a\\f\\t\\e\\n"', "as_double_quoted" );

    $e = as_double_quoted( $s, '"', ":html" );
    is( $e, "\"\r&#7;&#12;\t&#27;\n\"", "as_double_quoted" );

    $e = as_double_quoted( $s, '"', ":slash:html" );
    is( $e, "\"\\r&#7;&#12;\\t&#27;\\n\"", "as_double_quoted" );

# as_single_quoted( $to_quote )
    $e = as_single_quoted( $s );
    is( $e, "'\r\a\f\t\e\n'", "as_single_quoted" );
    is( "'''Hello, World.'''", as_single_quoted( "'Hello, World.'" ),
        "as_single_quoted" );

# as_heredoc(
#     value     => $value,
#     heretag   => $heretag,
#     herestyle => $herestyle,
#     quote     => $quote,
#     escape    => $escape,
#     indented  => $indented,
#     comment   => $comment,
#     extra     => $extra
# );

    $s = "\r\a\f\t\e\n";
    $e = as_heredoc( value => $s );
    is( $e, <<"__", "as_heredoc, defaults" );
<<
\r\a\f	\e
<<
__
    $e = as_heredoc( value => $s, herestyle => '{' );
    is( $e, <<"__", "as_heredoc, style:{" );
{
\r\a\f	\e
}
__
    $e = as_heredoc( value => $s, herestyle => '{', quote => "'" );
    is( $e, <<"__", "as_heredoc, style:{, quote:single" );
{''
\r\a\f	\e
}
__
    $e = as_heredoc( value => $s, heretag => 'eod' );
    is( $e, <<"__", "as_heredoc, tag" );
<<eod
\r\a\f	\e
eod
__
    $e = as_heredoc( value => $s, heretag => 'eod', quote => "'" );
    is( $e, <<"__", "as_heredoc, tag, quote:single" );
<<'eod'
\r\a\f	\e
eod
__
    $e = as_heredoc( value => $s, heretag => 'eod', herestyle => '<<<<' );
    is( $e, <<"__", "as_heredoc, tag, style:<<<<" );
<<eod
\r\a\f	\e
<<eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '<<<<', quote => "'" );
    is( $e, <<"__", "as_heredoc, tag, style:<<<<, quote:single" );
<<'eod'
\r\a\f	\e
<<eod
__
    $e = as_heredoc( value => $s, heretag => 'eod', herestyle => '{' );
    is( $e, <<"__", "as_heredoc, tag, style:{" );
{eod
\r\a\f	\e
eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '{', quote => "'" );
    is( $e, <<"__", "as_heredoc, tag, style:{, quote:single" );
{'eod'
\r\a\f	\e
eod
__
    $e = as_heredoc( value => $s, heretag => 'eod', herestyle => '{}' );
    is( $e, <<"__", "as_heredoc, tag, style:{}" );
{eod
\r\a\f	\e
}eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '{}', quote => "'" );
    is( $e, <<"__", "as_heredoc, tag, style:{}, quote:single" );
{'eod'
\r\a\f	\e
}eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '{}', quote => "s" );
    is( $e, <<"__", "as_heredoc, quote:single" );
{'eod'
\r\a\f	\e
}eod
__
    
# double quotes

    $e = as_heredoc( value => $s, herestyle => '{', quote => '"' );
    is( $e, <<"__", "as_heredoc, style:{, quote:double" );
{""
\\r\\a\\f	\\e
}
__
    $e = as_heredoc( value => $s, heretag => 'eod', quote => '"' );
    is( $e, <<"__", "as_heredoc, tag, quote:double" );
<<"eod"
\\r\\a\\f	\\e
eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '<<<<', quote => '"' );
    is( $e, <<"__", "as_heredoc, tag, style:<<<<, quote:double" );
<<"eod"
\\r\\a\\f	\\e
<<eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '{', quote => '"' );
    is( $e, <<"__", "as_heredoc, tag, style:{, quote:double" );
{"eod"
\\r\\a\\f	\\e
eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '{}', quote => '"' );
    is( $e, <<"__", "as_heredoc, tag, style:{}, quote:double" );
{"eod"
\\r\\a\\f	\\e
}eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '{}', quote => 'd' );
    is( $e, <<"__", "as_heredoc, tag, style:{}, quote:double" );
{"eod"
\\r\\a\\f	\\e
}eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '{}', quote => '"', escape => ':slash' );
    is( $e, <<"__", "as_heredoc, tag, style:{}, quote:double, type:slash" );
{"eod:slash"
\\r\\a\\f	\\e
}eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '{}', quote => '"', escape => ':html' );
    is( $e, <<"__", "as_heredoc, tag, style:{}, quote:double, type:html" );
{"eod:html"
\r&#7;&#12;	&#27;
}eod
__
    $e = as_heredoc( value => $s, heretag => 'eod',
        herestyle => '{}', quote => '"', escape => ':html:slash' );
    is( $e, <<"__", "as_heredoc, tag, style:{}, quote:double, type:html:slash" );
{"eod:html:slash"
\\r&#7;&#12;	&#27;
}eod
__
    $e = as_heredoc( value => qq'{\n  "a" : "b"\n}\n',
        herestyle => '{}', escape => ':json' );
    is( $e, <<"__", "as_heredoc, generated tag, style:{}, type:json" );
{_a:json
{
  "a" : "b"
}
}_a
__

# parse_double_quoted( $to_parse, $types )
    $e = parse_double_quoted( qq'"$s1"' );
    is( $e, $e1, "parse_double_quoted" );

    $e = parse_double_quoted( qq'"$d1"' );
    is( $e, $e2, "parse_double_quoted" );

    $e = parse_double_quoted( qq'"$d2"', '"', ':html' );
    is( $e, $e2, "parse_double_quoted" );

    $e = parse_double_quoted( qq'"$d3"' );
    is( $e, $e2, "parse_double_quoted" );

    $e = parse_double_quoted( qq'"$d4"' );
    is( $e, $e2, "parse_double_quoted" );

# parse_single_quoted( $to_parse )
    is( "'Hey'", parse_single_quoted( "'''Hey'''" ),
        "parse_single_quoted" );

}
