package View;

use common::sense;

sub normalise {
   for (@_) {
      s/^\t/        /;
      s/^( {8})\t/$1        /;
      s/^( {16})\t/$1        /;
      s/^( {24})\t/$1        /;
      die "Only 4 leading tabs supported" if /^\s*\t/;

      my $indent = 128;
      for (split "\n", $_) {
         if (/^( *)[^ ]/) {
            my $spaces = length $1;
            $indent = $spaces < $indent ? $spaces : $indent;
         }
      }

      $indent = ' ' x $indent;
      $_ =~ s/(?:^\n*$indent|(\n)$indent)/$1/g;
      $_ =~ s/\n+$//g;
   }
}


1
