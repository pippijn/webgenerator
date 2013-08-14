package View::Pod;

use common::sense;

use base 'Pod::Parser';
use XML::Generator ':pretty';
use Data::Dumper;


sub push {
   my $self = shift;
   push @{ $self->{current} }, @_;
}

sub pop {
   my $self = shift;
   @{ $self->{current} }
}

sub level {
   my ($self) = @_;
   my (undef, @kind) = @{ $self->{stack}[@{ $self->{stack} } - 1] };
   @kind
}

sub push_level {
   my ($self, @kind) = @_;
   push @{ $self->{stack} }, [$self->{current}, @kind];
   $self->{current} = [];
}

sub pop_level {
   my $self = shift;
   my ($prev, @kind) = @{ pop @{ $self->{stack} } };
   my $xml = $self->{current};
   $self->{current} = $prev;
   $xml, @kind
}


sub parse {
   my ($self, $file) = @_;
   $self->parse_from_file ($file);
}


sub view_textblock {
   my ($self, $ptree) = @_;
   given (my $type = ref $ptree) {
      when ("Pod::ParseTree") {
         map { $self->view_textblock ($_) } $ptree->children
      }
      when ("Pod::InteriorSequence") {
         my @content = $self->view_textblock ($ptree->parse_tree);
         $self->interior_sequence ($ptree->cmd_name, @content);
      }
      when ("") {
         $ptree;
      }
      default {
         die "Unhandled parse tree node: $type"
      }
   }
}


sub command {
   my ($self, $command, $paragraph, $line_num) = @_;

   given ($command) {
      when ("head1") {
         $self->push (h2 ($paragraph))
      }
      when ("head2") {
         $self->push (h3 ($paragraph))
      }
      when ("head3") {
         $self->push (h4 ($paragraph))
      }
      when ("head4") {
         $self->push (h5 ($paragraph))
      }
      when ("for") {
         $self->push ($self->format (split /\s+/, $paragraph))
      }
      when ("over") {
         $self->push_level ("ul")
      }
      when ("item") {
         # If we are currently in another item, pop its xml
         # and finalise the <li>.
         my ($level, $name) = $self->level;
         if ($level eq 'li') {
            my ($xml) = $self->pop_level;
            $self->push (li (
               $self->interpolate ($name),
               @$xml
            ))
         }

         # Open the next <li>.
         $self->push_level ("li", $paragraph)
      }
      when ("back") {
         my ($xml, $level, $name) = $self->pop_level;
         if ($level eq 'li') {
            $self->push (li (
               $self->interpolate ($name),
               @$xml
            ));
            ($xml, $level) = $self->pop_level;
         }

         die "unexpected kind '$level'" unless $level eq 'ul';
         $self->push (ul (@$xml))
      }
      when ("begin") {
         die "Nested =begin not supported" if exists $self->{begin};
         die "Unclaimed verbatim: @{ $self->{verbatim} }" if exists $self->{verbatim};

         my @args = split /\s+/, $paragraph;
         given ($self->{begin} = shift @args) {
            when ("code") {
               $self->{language} = \@args;
            }
            when ("small") {
               $self->push_level ("small")
            }
            default {
               die "Unhandled =begin: $self->{begin}"
            }
         }
      }
      when ("end") {
         given (my $begin = delete $self->{begin}) {
            when ("code") {
               my $xml = code ();
               my $args = delete $self->{language};
               my $code = delete $self->{verbatim};

               my ($lang, @args) = @$args;

               push @{ $self->{highlight}{lc $lang} }, [$xml, \@args, join '', @$code];

               $self->push ($xml);
            }
            when ("small") {
               my ($xml, $level) = $self->pop_level;
               die "unexpected kind '$level'" unless $level eq 'small';
               $self->push (p ({ class => 'small' }, @$xml))
            }
            default {
               die "Unhandled =begin: $begin"
            }
         }
      }
      default {
         die "Unhandled command: $command at line $line_num"
      }
   }
}

sub verbatim {
   my ($self, $paragraph, $line_num) = @_;

   if (exists $self->{begin}) {
      push @{ $self->{verbatim} }, $paragraph;
   } elsif ($paragraph !~ /^\s+$/) {
      $self->push (pre ($paragraph));
   }
}

sub interpolate {
   my ($self, $paragraph) = @_;
   my $ptree = $self->parse_text ($paragraph);
   $self->view_textblock ($ptree)
}

sub textblock {
   my ($self, $paragraph, $line_num) = @_;
   $self->push (p ($self->interpolate ($paragraph)))
}

sub interior_sequence {
   my ($self, $seq_command, @seq_argument) = @_;

   given ($seq_command) {
      when ("L") {
         map {
           my ($title, $link) = split /\|/, $_, 2;
           $link ||= $title;
           a ({ href => $link }, $title)
         } @seq_argument
      }
      when ("I") {
         map {
           em ($_)
         } @seq_argument
      }
      when ("B") {
         map {
           strong ($_)
         } @seq_argument
      }
      when ("F") {
         map {
           span ({ class => 'filename' }, $_)
         } @seq_argument
      }
      when ("C") {
         map {
           code ($_)
         } @seq_argument
      }
      default {
         die "Unhandled sequence: $seq_command"
      }
   }
}

sub format {
   my ($self, @args) = @_;

   given (my $fmt = shift @args) {
      when ("img") {
         my ($src, $alt) = @args;
         div ({ class => 'centered-image'},
            div (img ({ src => $src, alt => $alt })),
            $alt
         )
      }
      default {
         die "Unhandled format: $fmt"
      }
   }
}


1
