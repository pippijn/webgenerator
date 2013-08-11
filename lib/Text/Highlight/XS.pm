package Text::Highlight::XS;

use strict;
use warnings FATAL => 'all';
use utf8;

use base qw/Text::Highlight::CPP/;

sub syntax {
   my ($self) = @_;
   my $syntax = $self->SUPER::syntax;
   push @{ $syntax->{key1} }, (
      "MODULE",
      "PACKAGE",
      "CODE",
      "OUTPUT",
      "PROTOTYPE",
   );
   push @{ $syntax->{key2} }, (
      "RETVAL",
   );

   $syntax
}

1
