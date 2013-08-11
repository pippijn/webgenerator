package Text::Highlight::Pascal;

use strict;
use warnings FATAL => 'all';
use utf8;

use base qw/Text::Highlight::Module/;

sub syntax {
   {
      'name' => 'Pascal',
      'case' => 1,
      'blockCommentOn' => [
         '/*',
      ],
      'blockCommentOff' => [
         '*/',
      ],
      'lineComment' => [
         '//',
      ],
      'quot' => [
         '\'',
         '"',
      ],
      'escape' => '\\',
      'continueQuote' => 0,
      'delimiters' => ',(){}[]-+*%/="\'~!&|<>?:;.#',
      # Keywords
      'key1' => [
         'program',
         'var',
         'begin',
         'end',
         'not',
         'if',
         'then',
         'else',
         'while',
         'label',
         'for',
         'to',
         'do',
         'goto',
      ],
      # Preprocessor
      'key2' => [
      ],
      # Datatypes
      'key3' => [
         'boolean',
         'integer',
      ],
      # Constants
      'key4' => [
         'false',
         'true',
      ]
   }
}

1
