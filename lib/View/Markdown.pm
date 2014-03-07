package View::Markdown;

use common::sense;

use Data::Dumper;
use Markdent::Dialect::GitHub::BlockParser;
use Markdent::Handler::MinimalTree;
use Markdent::Parser;
use View::Markdown::Handler;

my $handler = new View::Markdown::Handler;

my $parser = new Markdent::Parser (
   dialects => 'GitHub',
   handler => $handler,
);

sub new {
   bless {
      current => ["unimplemented"]
   }, $_[0]
}

sub parse {
   my ($self, $file) = @_;
   $handler->{highlight} = delete $self->{highlight};
   $parser->parse (markdown => do { local $/; open my $fh, '<', $file or die $!; <$fh> });
   $self->{current} = delete $handler->{current};
   $self->{highlight} = delete $handler->{highlight};
}


1
