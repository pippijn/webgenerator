package Text::Highlight::Lisp;

use strict;
use warnings FATAL => 'all';
use utf8;

use base qw/Text::Highlight::Module/;

sub syntax {
   {
      'name' => 'Lisp',
      'case' => 1,
      'lineComment' => [
         ';',
      ],
      'delimiters' => ',()"\'|;#',
      'key1' => [
         '*',
         '/',
         '+',
         '-',
         '<',
         '=',
         '<=',
         'defun',
         'defmacro',
         'labels',
         'macroexpand',
         'if',
         'or',
         'zerop',
         'print',
         'write-line',
         'setq',
         'first',
      ],
      'quot' => [
         '\'',
         '"',
      ],
      'escape' => '\\',
      'continueQuote' => 0,
   }
}

1
