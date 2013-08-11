package View::POD::TOC;

use common::sense;
use base 'Pod::POM::View';

our $toc;

sub import { $toc = $_[1] }

# Main

sub view_pod {
   my ($self, $item) = @_;

   $item->content->present ($self)
}

# Headers

sub view_head1 {
   my ($self, $item) = @_;
   $item->content->present ($self)
}

sub view_head2 {
   my ($self, $item) = @_;
   push @$toc, $item->title;
   $item->content->present ($self)
}

1
