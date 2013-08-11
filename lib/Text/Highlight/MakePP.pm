package Text::Highlight::MakePP;

use strict;
use warnings FATAL => 'all';
use utf8;

use base qw/Text::Highlight::Module/;

sub syntax {
   {
      name => 'Make++',
      case => 1,
      blockCommentOn => [],
      quot => [
         '\'',
         '"',
      ],
      escape => '\\',
      continueQuote => 1,
      lineComment => [
         '#',
      ],
      delimiters => ',{}+/~!&|?;%',
      key1 => [
         qw/
         program library sources link build cflags cppflags custom ex li
         extra_dist nodist_sources rule ldflags project section headers
         functions arg_enable arg_with options define c_bigendian c_typeof
         c_charset c_enum_fwdecl c_late_expansion c_token_paste c_float_format
         c_stdint_h alignof c_stmt_exprs output exclude pkg-config template
         verbatim extend global extern
         /,
      ],
      key2 => [
         qr/\$[*<@]/,
         qr/\$[0-9]+/,
         qr/\$([^)]+)/,
         qr/\$\[\w+\]/,
      ],
      key3 => [
         "->",
         "=>",
         "=",
         ":",
      ],
      key4 => [
         'if',
      ],
      key5 => [
         qw/
         version: contact: config_header: symbol: header:
         /,
      ],
   }
}

1
