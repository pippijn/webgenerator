package View::Markdown::Handler;

use feature 'switch';
#use common::sense;
#use namespace::autoclean;

use Data::Dumper;
use XML::Generator;
use View;

use Markdent::Types qw(
   HeaderLevel Str Bool HashRef
   TableCellAlignment PosInt
);

use Moose;

with 'Markdent::Role::EventsAsMethods';

my $X = new XML::Generator ':pretty';

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
   CORE::push @{ $self->{stack} }, [$self->{current}, @kind];
   $self->{current} = [];
}

sub pop_level {
   my $self = shift;
   my ($prev, @kind) = @{ CORE::pop @{ $self->{stack} } };
   my $xml = $self->{current};
   $self->{current} = $prev;
   $xml, @kind
}


sub start_document {
   my ($self) = @_;
}

sub end_document {
   my ($self) = @_;
}

sub start_header {
   my ($self, %args) = @_;
   $self->push_level ("h" . ($args{level} + 1));
}

sub end_header {
   my ($self) = @_;
   my ($xml, $level) = $self->pop_level;
   $self->push ($X->$level (@$xml));
}

sub start_paragraph {
   my ($self, %args) = @_;
   $self->push_level ("p");
}

sub end_paragraph {
   my ($self) = @_;
   my ($xml, $level) = $self->pop_level;
   $self->push ($X->$level (@$xml));
}

sub start_link {
   my ($self, %args) = @_;
   $self->push_level ("a", $args{uri});
}

sub end_link {
   my ($self, %args) = @_;
   my ($xml, $level, $uri) = $self->pop_level;
   $self->push ($X->$level ({ href => $uri }, @$xml));
}

sub start_emphasis {
   my ($self, %args) = @_;
   $self->push_level ("em", $args{uri});
}

sub end_emphasis {
   my ($self, %args) = @_;
   my ($xml, $level, $uri) = $self->pop_level;
   $self->push ($X->$level ({ href => $uri }, @$xml));
}

sub start_code {
   my ($self, %args) = @_;
   given ($args{delimiter}) {
      when ('`') {
         $self->push_level ("code");
      }
      when ('```') {
         $self->push_level ("pre");
      }
      default {
         die "Unknown delimiter: $args{delimiter}"
      }
   }
}

sub end_code {
   my ($self) = @_;
   my ($xml, $level, @args) = $self->pop_level;
   $self->push ($X->$level (@args, @$xml));
}

sub code_block {
   my ($self, %args) = @_;
   View::normalise $args{code};
   $self->push ($X->pre ({ class => 'code-block' }, $args{code}));
}

sub preformatted {
   my ($self, %args) = @_;
   View::normalise $args{text};
   $self->push ($X->pre ({ class => 'verbatim' }, $args{text}));
}

sub start_unordered_list {
   my ($self, %args) = @_;
   $self->push_level ("ul");
}

sub end_unordered_list {
   my ($self) = @_;
   my ($xml, $level) = $self->pop_level;
   $self->push ($X->$level (@$xml));
}

sub start_list_item {
   my ($self) = @_;
   $self->push_level ("li");
}

sub end_list_item {
   my ($self) = @_;
   my ($xml, $level) = $self->pop_level;
   $self->push ($X->$level (@$xml));
}

sub text {
   my ($self, %args) = @_;
   $self->push ($args{text});
}

sub image {
   my ($self, %args) = @_;

   my ($alt, $href) = split /\|/, $args{alt_text}, 2;
   $self->push ($X->img ({ alt => $alt, src => $args{uri} }));

   if ($href) {
      $self->push ($X->a ({ href => $href }, $self->pop));
   }
}

1
