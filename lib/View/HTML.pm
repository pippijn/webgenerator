package View::HTML;

use common::sense;

sub menu {
   my ($cur, $data, $path) = @_;

   my $retval = "<ul>\n";
   for my $submenu (@$data) {
      $retval .= "<li>\n";
      if (@$submenu == 1) {
         # This branch is only here for the root index.
         if ($cur eq ${path} . "index") {
            $retval .= "<a id=\"actmenu\">$submenu->[0]";
         } else {
            $retval .= "<a href=\"$path\">$submenu->[0]";
         }
      } else {
         if ($cur eq $path . $submenu->[0]) {
            $retval .= "<a id=\"actmenu\">$submenu->[1]";
         } else {
            $retval .= "<a href=\"$path$submenu->[0]\">$submenu->[1]";
         }
      }
      if (@$submenu >= 3) {
         if (   $cur =~ /$submenu->[0]$/ 
             or $cur =~ /$submenu->[0]\//) {
            $retval .= " <span class=\"small\">[-]</span></a>";
            $retval .= menu ($cur, $submenu->[2], "$path$submenu->[0]/");
         } else {
            $retval .= " <span class=\"small\">[+]</span></a>";
         }
      } else {
         $retval .= "</a>";
      }
      $retval .= "</li>";
   }
   "$retval</ul>"
}


1
