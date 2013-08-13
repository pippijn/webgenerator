package View::VIM;

use common::sense;

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

      join "", @data
   };

   unlink $xhtml;
   $data
}


sub highlight {
   my ($type, @text) = @_;

   my $combined = join "\000\n", map { $_->[2] } @text;
   split '\^@', highlight_one $type, $combined
}


1
