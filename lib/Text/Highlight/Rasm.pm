package Text::Highlight::Rasm;

use strict;
use warnings FATAL => 'all';
use utf8;

use base qw/Text::Highlight::Module/;

sub syntax {
   {
      'name' => 'C/C++',
      'case' => 1,
      'blockCommentOn' => [
      ],
      'blockCommentOff' => [
      ],
      'lineComment' => [
         '#',
      ],
      'quot' => [
         '\'',
         '"',
      ],
      'escape' => '\\',
      'continueQuote' => 0,
      'delimiters' => '',
      # Keywords
      'key1' => [
         'prolog',
         'arg',
         'getarg',
         'sub',
         'blt',
         'prepare',
         'pusharg',
         'finish',
         'retval',
         'add',
         'ret',
         'patch',
         'mov',
      ],
      # Preprocessor
      'key2' => [
         '!forward',
      ],
      # Data types
      'key3' => [
         '=>',
      ],
      # Constants
      'key4' => [
         '%r0',
         '%r1',
         '%r2',
         '%v0',
         '%v1',
         '%v2',
         '%ret',
      ],
      # Classes
      'key5' => [
         '@self',
      ],
   }
}

1
