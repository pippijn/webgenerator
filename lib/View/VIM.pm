package View::VIM;

use common::sense;
use View;

sub highlight_one {
   my ($type, $text) = @_;

   my $xhtml = do {
      my $fh = new File::Temp (TEMPLATE => '/tmp/vimhlXXXXXX');
      print $fh $text;

      my $xhtml = $fh->filename . '.xhtml';
      open my $null, '-|', "vim", "-enX", $fh->filename,
         "+set syn=$type",
         "+runtime! syntax/2html.vim",
         "+w $xhtml",
         "+qa!";

      $xhtml;
   };

   my $data = do {
      my @data;
      open my $in, '<', $xhtml or die $!;
      while (my $line = <$in>) {
         last if $line =~ /^<pre/
      }
      while (my $line = <$in>) {
         last if $line =~ /^<\/pre>/;
         push @data, $line;
      }

      pop @data while $data[$#data] =~ /^\s*$/;

      join "", @data
   };

   unlink $xhtml;
   $data
}

sub highlight {
   my ($type, @text) = @_;

   View::normalise $_->[2] for @text;

   my $combined = join "\n\000\n", map { $_->[2] } @text;
   my @highlighted = split /\n\^@\n/, highlight_one $type, $combined;

   die "Failure: arity of split does not match joined"
      if @highlighted != @text;

   @highlighted
}


1
