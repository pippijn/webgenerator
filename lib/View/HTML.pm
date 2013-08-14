package View::HTML;

use common::sense;

use XML::Generator (
   escape => 'unescaped',
   conformance => 'strict',
   pretty => 2,
);

sub menu {
   my ($cur, $data, $path) = @_;

   my @retval;
   for my $submenu (@$data) {
      my ($retval, $menu);

      if (@$submenu >= 3) {
         if (   $cur =~ /$submenu->[0]$/ 
             or $cur =~ /$submenu->[0]\//) {
            $retval = span ({ class => "small" }, "[-]");
            $menu = menu ($cur, $submenu->[2], "$path$submenu->[0]/");
         } else {
            $retval = span ({ class => "small" }, "[+]")
         }
      }

      if (@$submenu == 1) {
         $retval = a (
            ($cur eq $path . "index"
               # This branch is only here for the root index.
               ? { id => "actmenu" }
               : { href => "$path" }),
            $submenu->[0],
            $retval
         )
      } else {
         $retval = a (
            ($cur eq $path . $submenu->[0]
               ? { id => "actmenu" }
               : { href => "$path$submenu->[0]" }
            ),
            $submenu->[1],
            $retval
         )
      }

      push @retval, li ($retval, $menu);
   }
   ul (@retval)
}


1
