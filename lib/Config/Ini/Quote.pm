package Config::Ini::Quote;

=begin html

 <style type="text/css">
 @import "http://dbsdev.galib.uga.edu/sitegen/css/sitegen.css";
 body { margin: 1em; }
 </style>

=end html

=head1 NAME

Config::Ini::Quote - Quoting strings for Config::Ini modules

=cut

use 5.008000;
use strict;
use warnings;
use Carp;
use HTML::Entities ();

use Exporter;
our @ISA = qw( Exporter );
our @EXPORT_OK = qw(
    unescape_for_double_quoted
    escape_for_double_quoted
    as_double_quoted
    as_single_quoted
    as_heredoc
    parse_double_quoted
    parse_single_quoted
    );
our %EXPORT_TAGS = (
    all => [@EXPORT_OK],
    escape => [qw(
        unescape_for_double_quoted
        escape_for_double_quoted
        )],
    );

# subroutines summary:
# unescape_for_double_quoted( $to_unescape, $escape );
# escape_for_double_quoted( $to_escape, $escape )
# as_double_quoted( $to_quote )
# as_single_quoted( $to_quote )
# as_heredoc(
#  value     => $value,
#  heretag   => $heretag,
#  herestyle => $herestyle,
#  quote     => $quote,
#  escape    => $escape,
#  indented  => $indented,
#  comment   => $comment,
#  extra     => $extra
#  )
# parse_double_quoted( $to_parse, $escape )
# parse_single_quoted( $to_parse )

=head1 SYNOPSIS

  use Config::Ini::Quote ':escape';
  
  binmode(STDOUT, ":utf8");
  my $smiley = qq{\t"smiley":\x{263a}\n};
  
  $smiley = escape_for_double_quoted( $smiley );
  print $smiley; # literally: \t"smiley":\u263A\n
  
  $smiley = unescape_for_double_quoted( $smiley );
  print $smiley; # same as: print qq{\t"smiley":\x{263a}\n};
 
  use Config::Ini::Quote ':all';
  
  print as_double_quoted( $smiley );
  # literally: "\t\"smiley\":\u263A\n"
  
  print as_single_quoted( $smiley );
  # same as: print qq{'\t"smiley":\x{263a}\n'};
  
  print as_heredoc( value => $smiley,
      heretag => 'EOT', quote => '"' );
  # literally:
  # <<"EOT"
  # \t"smiley":\u263A
  # EOT
  
  $smiley =~ s/"/\\"/g; # prepare for parse
  print parse_double_quoted( qq{"$smiley"} );
  # same as: print qq{\t"smiley":\x{263a}\n};
  
  print parse_single_quoted( "'''Hello, World.'''" );
  # 'Hello, World.'

=head1 VERSION

VERSION: 1.00

=cut

our $VERSION = '1.00';

# more POD after the __END__

#---------------------------------------------------------------------
# Printable characters for escapes (based on YAML Version 1.1 specs)

my %unescapes = 
  (
   0 => "\x00", a    => "\x07", b => "\x08", t => "\x09",
   n => "\x0a", v    => "\x0b", f => "\x0c", r => "\x0d",
   e => "\x1b", '\\' => '\\',   N => "\x85", _ => "\xa0",
   L => "\x{2028}",  P => "\x{2029}",
  );
# reverse hash
my %escapes = map { ord($unescapes{$_}) => $_ } keys %unescapes;

#---------------------------------------------------------------------
# change backslash escapes to their literal meanings
## unescape_for_double_quoted( $to_unescape, $escape );
# Note: this algorithm is such that "\" eq "\\", i.e.,
# a backslash that doesn't precede a recognized escape
# character is passed through as a backslash (instead of
# disappearing).  This is liberal and counted on in some
# cases (like the parameters passed to :parse)
sub unescape_for_double_quoted {
    my ( $to_unescape, $escape ) = @_;

    # :slash => \x00,\u0000 ... :html => &#x00;,&#x0000;
    my $slash = $escape ? ($escape =~ /:slash/) ? 1 : 0 : 1; # default
    my $html  = $escape ? ($escape =~ /:html/)  ? 1 : 0 : 0;

    $to_unescape =~ s/ \\
        ([PLan\\verb_f0Nt] |
        [ux]([0-9a-fA-F]{4}) |
        x([0-9a-fA-F]{2})
        )/
        (length($1)>4) ? pack("U*",hex($2)) :
        (length($1)>2) ? pack("H2",$3)      :
        $unescapes{$1} /gex if $slash;
    $to_unescape = HTML::Entities::decode( $to_unescape ) if $html;
    $to_unescape;
}

#---------------------------------------------------------------------
## escape_for_double_quoted( $to_escape, $escape )
sub escape_for_double_quoted {
    my ( $to_escape, $escape ) = @_;

    # :slash => \x00,\u0000 ... :html => &#x00;,&#x0000;
    my $slash = $escape ? ($escape =~ /:slash/) ? 1 : 0 : 1; # default
    my $html  = $escape ? ($escape =~ /:html/)  ? 1 : 0 : 0;

    # do html first
    $to_escape = HTML::Entities::encode( $to_escape ) if $html;
    $to_escape = join("",
        map {
            exists $escapes{$_}       ?  # if \n, \t, etc.
            "\\$escapes{$_}"          :  # escaped as \.
            $_ > 255                  ?  # else if wide character
            sprintf("\\u%04X", $_)    :  # escaped as \u....
            chr($_) =~ /[[:^print:]]/ ?  # else if not printable
            sprintf("\\x%02X", $_)    :  # escaped as \x..
            chr($_)                      # else as itself
        } unpack("U*", $to_escape))      # unpack Unicode characters
        if $slash;
    $to_escape;
}

#---------------------------------------------------------------------
## as_double_quoted( $to_quote, $q, $escape )
sub as_double_quoted {
    my( $to_quote, $q, $escape ) = @_;
    $to_quote = escape_for_double_quoted( $to_quote, $escape );
    $q = '"' unless defined $q;
    $to_quote =~ s/$q/\\$q/g if $q;
    "$q$to_quote$q";
}

#---------------------------------------------------------------------
## as_single_quoted( $to_quote, $q )
sub as_single_quoted {
    my( $to_quote, $q ) = @_;
    $q = "'" unless defined $q;
    $to_quote =~ s/$q/$q$q/g if $q;
    "$q$to_quote$q";
}

#---------------------------------------------------------------------
## as_heredoc(
##  value     => $value,
##  heretag   => $heretag,
##  herestyle => $herestyle,
##  quote     => $quote,
##  escape    => $escape,
##  indented  => $indented,
##  comment   => $comment,
##  extra     => $extra
##  )

sub as_heredoc {
    my( %parms ) = @_;

    my( $value,  $heretag,  $herestyle, $quote,
        $escape, $indented, $comment,   $extra
        ) = @parms{ qw(
        value    heretag    herestyle   quote
        escape   indented   comment     extra
        ) };

    $heretag = '' unless defined $heretag;
    $herestyle ||= '<<';
    $quote = !defined($quote) ? ''  :
        ($quote=~/^\s*["d]/i) ? '"' :
        ($quote=~/^\s*['s]/i) ? "'" : '';
    $indented = !$indented   ? ''        :
        ($indented=~/^\s+$/) ? $indented : ' 'x4;
    my $indent_mod = $indented ? ':indented' : '';
    $escape  ||= '';
    $extra   ||= '';

    my $chomp = '';
    unless( $value =~ /\n$/ ) {
        $chomp = ':chomp'; $value .= "\n"; }

    if( $heretag eq '' ) {
        $herestyle = ($herestyle=~/^\s*{/) ? '{}' : '<<<<';
    }  #(vi})

    if( $quote eq '"' ) {
        $value = escape_for_double_quoted( $value, $escape );
        $value =~ s/\\n/\n/g;  # put newlines back in for heredoc
        $value =~ s/\\t/\t/g;  # put tabs back in for heredoc
    }

    if( $comment ) {
        for( $comment ) {
            s/\n+$//;
            s/\n/ /g;
            s/^(?!\s*[#;])/ # /;
        }
        $quote = "'" unless $quote;  # comment needs quote
    }
    else {
        $comment = '';
    }

    my $end   = $heretag;
    my $begin = join '', $quote, $heretag, $chomp, $escape,
        $indent_mod, $extra, $quote, $comment;

    for( $herestyle ) {  #vi{{
        /{}/   and do { $end   = "}$end"; last };
        /<<<</ and do { $end   = "<<$end" };
    }

    if( $value =~ /^\s*$end\s*$/m ) { # end tag found in data?
        my $t = 'a';
        $t++ while $value =~ /^\s*${end}_$t\s*/m;
        $heretag .= "_$t";
        $end     .= "_$t";
        $begin = join '', $quote, $heretag, $chomp, $escape,
            $indent_mod, $extra, $quote, $comment;
    }

    for( $herestyle ) {
        /{/    and do { $begin = "{$begin"; last };  #vi}}}
        /<</   and do { $begin = "<<$begin"; };
    }

    $value =~ s/^/$indented/mg if $indented;

    "$begin\n$value$end\n";
}

#---------------------------------------------------------------------
# Parse double quoted string (also regex-like, i.e., /xyz/).
## parse_double_quoted( $to_parse, $q, $escape )
sub parse_double_quoted {
    my( $to_parse, $q, $escape ) = @_;
    $q = '"' unless defined $q;
    if( $q ) {
        if( $to_parse =~  /^\s*$q((?:\\$q|[^$q])*)$q\s*$/ ) {
            $to_parse = $1;
            $to_parse =~ s/\\$q/$q/g;
        }
        else {
            croak "Bad double_quoted string: $to_parse";
        }
    }
    $to_parse = unescape_for_double_quoted( $to_parse, $escape );
}

#---------------------------------------------------------------------
# Parse single quoted string.
## parse_single_quoted( $to_parse, $q )
sub parse_single_quoted {
    my( $to_parse, $q ) = @_;
    $q = "'" unless defined $q;
    if( $q ) {
        if ($to_parse =~ /^\s*$q((?:$q$q|[^$q])*)$q\s*$/) {
            $to_parse = $1;
            $to_parse =~ s/$q$q/$q/g;
        }
        else {
            croak "Bad single_quoted string: $to_parse";
        }
    }
    $to_parse;
}

1;

__END__

=head1 DESCRIPTION

This module is designed to provide backslash-escaped character support
for the Config::Ini::Edit and Config::Ini::Expanded modules.

If requested, it will also interpret HTML entities in double quoted
strings (using HTML::Entities).

=head1 FUNCTIONS

No functions are exported by default.  The following are exported with
C<':escape'>, e.g.

 Use Config::Ini::Quote qw( :escape );
 
 unescape_for_double_quoted()
 escape_for_double_quoted()

All functions can be exported with C<':all'>, e.g.,

 Use Config::Ini::Quote qw( :all );

=head2 escape_for_double_quoted( $to_escape, $escape )

Escapes unprintable and unicode characters.

 my $e = escape_for_double_quoted( $s );

The parameter, $escape, may contain any combination of these strings:
C<':slash'>, C<':html'>.  If $escape is false (e.g., C<undef> or
C<''>), the default is C<':slash'>, which encodes the following
characters:

 "\x00" as \0     (null)
 "\x07" as \a     (bell)
 "\x08" as \b     (backspace)
 "\x09" as \t     (tab)
 "\x0a" as \n     (new line)
 "\x0b" as \v     (vertical tab)
 "\x0c" as \f     (form feed)
 "\x0d" as \r     (carriage return)
 "\x1b" as \e     (ascii escape)
 '\\'   as \\     (escaped backslash)
 "\x85" as \N     (Unicode next line)
 "\xa0" as \_     (Unicode non-breaking space)
 "\x{2028}" as \L (Unicode line separator)
 "\x{2029}" as \P (Unicode paragraph separator)

Other unprintable characters are encoded as C<'\xXX'>, and (wide)
Unicode characters as C<'\uXXXX'>, where C<'XX'> and C<'XXXX'> are the
hex code for the character.

If C<$escape> matches C</:html/>, the string is first encoded using
HTML::entities::encode's defaults, i.e., it will encode control chars,
high-bit chars, and the C<< '<' >>, C<'&'>, C<< '>' >>, C<"'"> and
C<'"'> characters. If C<$escape> also matches C</:slash/>, then any
remaining characters from the above table, e.g., C<'\n'>, C<'\t'>,
etc., will be encoded as above.

=head2 unescape_for_double_quoted( $to_unescape, $escape );

Converts escaped text to actual characters.

 $smiley = unescape_for_double_quoted( '\t"smiley":\u263a\n' );

The parameter, C<$escape>, may contain any combination of these
strings:  C<':slash'>, C<':html'>, as described in
C<escape_for_double_quoted()> above. By default, the codes in the above
table, e.g., C<'\n'>, C<'\t'>, etc., and codes of the form C<'\xXX'>,
C<'\xXXXX'>, and C<'\uXXXX'> will be decoded to their actual
characters. (Note that C<'\xXXXX'> is accepted as a synonym for
C<'\uXXXX'>.)

If C<$escape> matches C</:html/>, HTML entities will be decoded using
HTML::Entities::decode's defaults. If C<$escape> also matches
C</:slash/>, then other codes, e.g., C<'\n'>, C<'\t'>, etc., will be
decoded, too.

If you use C<':html'>, the default escaping technique, C<':slash'>,
will be disabled unless you explicitly include it, too, e.g.,
C<$escape eq ':html:slash'>.

=head2 as_double_quoted( $to_quote, $escape )

Double quotes a string--with character escapes; double quotes are
escaped as C<\">.

 $e = as_double_quoted( $s );

Characters in the string will be escaped using
C<escape_for_double_quoted()> as described above, including how the
C<$escape> parameter works.  Double quotes in the string will be
escaped as C<'\"'>.  The value returned will begin and end with a
double quote C<'"'>.

=head2 as_single_quoted( $to_quote )

Single quotes a string--without character escapes; single quotes are
escaped by doubling: C<"''">.  The value returned will begin and end
with a single quote C<"'">.

 $e = as_single_quoted( $s );

=head2 as_heredoc( ... )

 as_heredoc(
    value     => $value,
    heretag   => $heretag,
    herestyle => $herestyle,
    quote     => $quote,
    escape    => $escape,
    indented  => $indented,
    comment   => $comment,
    extra     => $extra
    );

'Quotes' a string using heredoc notation.

 $s = qq{\t"smiley":\x{263a}\n};
 $e = as_heredoc(
          value     => $s,   heretag => 'EOT',
          herestyle => '<<', quote   => '"' );
 # <<"EOT"
 # \t"smiley":\u263A
 # EOT

The C<'heretag'> parameter is the heredoc tag for the begin and end.
If null, the 'tagless' style is used, e.g.,

 $e = as_heredoc( value => $s, quote => '"' );
 # <<""
 # \t"smiley":\u263A
 # <<

The C<'herestyle'> parameter is one of: C<< '<<' >>, C<< '<<<<' >>,
C<'{'>, or C<'{}'>.  The default is C<< '<<' >>. Examples may explain
best:

 $e = as_heredoc(
     value => "Hey\n", heretag => 'EOT',
     herestyle => '<<' );  # the default
 # <<EOT
 # Hey
 # EOT
 
 $e = as_heredoc(
     value => "Hey\n", heretag => 'EOT',
     herestyle => '<<<<' );
 # <<EOT
 # Hey
 # <<EOT
 
 $e = as_heredoc(
     value => "Hey\n", heretag => 'EOT',
     herestyle => '{' );
 # {EOT
 # Hey
 # EOT
 
 $e = as_heredoc(
     value => "Hey\n", heretag => 'EOT',
     herestyle => '{}' );
 # {EOT
 # Hey
 # }EOT

The C<'quote'> parameter should match C<'/^\s*["d's]/i'>, e.g.,
C<< quote => '"' >>, C<< quote => 'double' >> (double quote),
C<< quote => "'" >>, C<< quote => 'single' >> (single quote).

Unlike Perl's heredocs, if C<'quote'> is not specified, single quote is
the default.

If double quote, the text in the heredoc is escaped using
C<escape_for_double_quoted()>, except that C<"\n"> and C<"\t"> and
double quotes are not escaped. A double quote is placed around the tag
and modifiers.

 $s = qq{one\t"fish"\ntwo\t'fish'\n};
 $e = as_heredoc( value => $s, heretag => 'EOT', quote => '"' );
 # <<"EOT"
 # one	"fish"
 # two	'fish'
 # EOT

If single quote or no quote (single quote implicit), the text is left
alone.  Single quotes in the string are not escaped.  If single quote
is explicit, a single quote is placed around the tag and modifiers.

 $e = as_heredoc( value => $s, heretag => 'EOT', quote => "'" );
 # <<'EOT'
 # one	"fish"
 # two	'fish'
 # EOT
 
 $e = as_heredoc( value => $s, heretag => 'EOT' );
 # <<EOT
 # one	"fish"
 # two	'fish'
 # EOT

Whether single or double quoted, if the string does not end with a
newline, the :chomp modifier is added

 chomp $s;
 $e = as_heredoc( value => $s, heretag => 'EOT' );
 # <<EOT:chomp
 # one	"fish"
 # two	'fish'
 # EOT

The C<'escape'> parameter is the same as described in
C<escape_for_double_quoted()> above, i.e., it contains C<':slash'>
and/or C<':html'>, defaulting to C<':slash'>.  It is recognized only
with double quotes.  The value of C<'escape'> is appended to the
heredoc tag, so the same types of quote escapes to be honored when the
Ini file is read later.

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
 
 $e = as_heredoc(
     value     => $s,   heretag => 'EOT',
     herestyle => '{}', quote   => 'double',
     escape    => ':html' );
 # {"EOT:chomp:html"
 # vis-&agrave;-vis Beyonc&eacute;'s na&iuml;ve
 # 	papier-m&acirc;ch&eacute; r&eacute;sum&eacute;
 # }EOT
 
 $e = as_heredoc(
     value     => $s,   heretag => 'EOT',
     herestyle => '{}', quote   => 'double',
     escape    => ':html:slash' );
 # {"EOT:chomp:html:slash"
 # vis-&agrave;-vis Beyonc&eacute;'s na&iuml;ve
 # \tpapier-m&acirc;ch&eacute; r&eacute;sum&eacute;
 # }EOT

The C<'indented'> parameter will indent the value.  If C<'indented'> is
whitespace, e.g., C<< 'indented' => "\t" >>, then that value will be
inserted at the beginning of each line.  Otherwise, if C<'indented'> is
true, then four spaces will be inserted.

 $e = as_heredoc(
     value => "The quick brown fox\n" .
         "jumped over the lazy dog",
     indented => 1 );
 # <<:indented
 #     The quick brown fox
 #     jumped over the lazy dog
 # <<

The C<'comment'> parameter provides for a comment on the same line as
the beginning of the heredoc.  A comment is only allowed if there are
quotes, so if quote is not given, the C<'comment'> parameter is
silently ignored.

If the comment does not begin with C<'#'> or C<';'>, C<'# '> will be
added to it.

 $e = as_heredoc( value => "Hey", heretag => 'EOT',
     quote => "'", comment => 'This is a comment' );
 # <<'EOT:chomp' # This is a comment
 # Hey
 # EOT

The C<'extra'> parameter allows you to pass along to C<as_heredoc()>
any modifiers that you want it to include, whether or not
C<as_heredoc()> recognizes them.

The value of extra will be added to any other modifiers that
C<as_heredoc()> would normally include.

 $e = as_heredoc( value => '{"a":1,"b":2,"c":3}',
     extra => ':json' );
 # <<:chomp:json
 # {"a":1,"b":2,"c":3}
 # <<

In the above example C<':json'> is not a modifier that
Config::Ini::Quote recognizes.  But Config::Ini::Edit does, and
C<as_heredoc()> passes it along.

=head2 parse_double_quoted( $to_parse, $types )

Parses a double-quoted string, unescaping escaped characters.

 $s = parse_double_quoted( q{"\t\\"smiley\\":\\u263a\n"} );

It expects the value to begin and end with double quotes; other double
quotes must be escaped C<\">.

=head2 parse_single_quoted( $to_parse )

Parses a single-quoted string; recognizes no escapes except doubled
single quotes: C<''>.

 $s = parse_single_quoted( "'''Hello, World.'''" );

It expects the value to begin and end with single quotes; other single
quotes must be escaped C<"''">.

=head1 SEE ALSO

Config::Ini::Edit,
Config::Ini::Expanded

=head1 AUTHOR

Brad Baxter, E<lt>bmb@mail.libs.uga.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Brad Baxter

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself, either Perl version 5.8.7 or, at
your option, any later version of Perl 5 you may have available.

=cut
