package View::Markdown::Handler;

use common::sense;
use namespace::autoclean;

use Data::Dumper;
use Markdent::Types qw(
   HeaderLevel Str Bool HashRef
   TableCellAlignment PosInt
);

use Moose;

with 'Markdent::Role::EventsAsMethods';

sub start_document {
   my ($self) = @_;
}

sub end_document {
   my ($self) = @_;
}

sub start_header {
   my ($self) = @_;
}

sub end_header {
   my ($self) = @_;
}

sub start_paragraph {
   my ($self) = @_;
}

sub end_paragraph {
   my ($self) = @_;
}

sub start_link {
   my ($self) = @_;
}

sub end_link {
   my ($self) = @_;
}

sub start_code {
   my ($self) = @_;
}

sub end_code {
   my ($self) = @_;
}

sub start_unordered_list {
   my ($self) = @_;
}

sub end_unordered_list {
   my ($self) = @_;
}

sub start_list_item {
   my ($self) = @_;
}

sub end_list_item {
   my ($self) = @_;
}

sub text {
   my ($self) = @_;
}

1
