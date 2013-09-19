package View;

use common::sense;

sub normalise {
   for (@_) {
      die "No tabs supported" if /\t/;

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
