package View::POD;

use common::sense;
use base 'Pod::POM::View';

our @toc;
our $base;

use Pod::POM;
use File::Temp;

# View methods

sub highlight {
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
         if ($line =~ /^<pre/) {
            $line =~ s/ id=/ class=/;
            push @data, $line;
            last;
         }
      }
      while (my $line = <$in>) {
         push @data, $line;
         if ($line =~ /^<\/pre>/) {
            last;
         }
      }

      join "", @data
   };

   #unlink $xhtml;
   $data
}

my %format = (
   html => sub {
      my ($text, @options) = @_;
      $text
   },
   code => sub {
      my ($text, @options) = @_;
      highlight $options[0], $text
   },
   small => sub {
      my ($text, @options) = @_;
      "<p class='small'>$text</p>"
   },
);

# Main

sub view_pod {
   my ($self, $item) = @_;

   $self->{tocid} = 0;
   $item->content->present ($self)
}

# Headers

sub gen_toc {
   my $i = 0;
   '<ul>'
   . (join "\n", map { ++$i; "<li><a href='#h$i'>$_</a></li>" } @toc)
   . '</ul>'
}

sub view_head1 {
   my ($self, $item) = @_;
   my $title = $item->title;
   if ($title =~ /^(.+)(?: \(@(.+)\))$/) {
      $title = "$1<a id='$2'></a>"
   }
   "<h2>\n"
   . $title
   . "</h2>\n"
   . gen_toc
   . $item->content->present ($self)
}

sub view_head2 {
   my ($self, $item) = @_;
   my $title = $item->title;
   my $id = ++$self->{tocid};
   "<h3>\n"
   . "<a id='h$id'>$title</a>"
   . "</h3>\n"
   . $item->content->present ($self)
}

sub view_head3 {
   my ($self, $item) = @_;
   my $title = $item->title;
   if ($title =~ /^(.+)(?: \(@(.+)\))$/) {
      $title = "$1<a id='$2'></a>",                                                                                                                                                                      
   }                                                                                                                                                                                                     
   "<h4>\n"
   . $title
   . "</h4>\n"
   . $item->content->present ($self)
}

sub view_head4 {
   my ($self, $item) = @_;
   my $title = $item->title;
   if ($title =~ /^(.+)(?: \(@(.+)\))$/) {
      $title = "$1<a id='$2'></a>",
   }
   "<h5>\n"
   . $title
   . "</h5>\n"
   . $item->content->present ($self)
}


# Text formatting
sub view_textblock {
   my ($self, $item) = @_;
   "<p>\n"
   . $item
   . "</p>\n"
}

sub view_verbatim {
   my ($self, $item) = @_;
   $self->xmlise (\$item);
   "<pre>\n$item</pre>"
}

sub view_begin {
   my ($self, $item) = @_;
   my ($format, @options) = split /\s+/, $item->format;
   $format{$format}->($item->content->present, @options)
}


# =over, =item

sub view_over {
   my ($self, $item) = @_;
   "<ul>\n"
   . $item->content->present ($self)
   . "</ul>\n"
}

sub view_item {
   my ($self, $item) = @_;
   my $title = $item->title->present ($self);
   if ($title =~ /^(.+)(?: \(@(.+)\))$/) {
      $title = "$1<a id='$2'></a>"
   }
   "<li>\n"
   . $title
   . $item->content->present ($self)
   . "</li>\n"
}


# Sequences
sub view_seq_link {
   my ($self, $item) = @_;
   my ($title, $link) = split /\|/, $item, 2;
   return "<a href='$link'>$title</a>"
      if $link;
   return "<a href='$title'>$title</a>"
}

sub view_seq_code { "<span class='code'>$_[1]</span>" }
sub view_seq_file { "<span class='filename'>$_[1]</span>" }
sub view_seq_bold { "<strong>$_[1]</strong>" }
sub view_seq_italic { "<em>$_[1]</em>" }
sub view_seq_index { "&lt;$_[1]&gt;" }
sub view_seq_space { "[$_[1]]" }

my %formatter = (
   link    => sub { "<a class='news-link' href='$_[1]'>Link</a>"   },
   author  => sub { "<div class='news-author'>Author: $_[1]</div>" },
   pubDate => sub { "<div class='news-date'>From: $_[1]</div>"     },
   img     => sub {
      chomp $_[1];
      my @p = split ' ', $_[1], 2;
      "<div class='centered-image'><div><img src=\"$base$p[0]\" alt='$p[1]'/></div>$p[1]</div>"
   },
);

sub view_for {
   my ($self, $text) = @_;

   $formatter{$text->format}->($self, scalar $text->text)
      if exists $formatter{$text->format}
}

sub xmlise {
   my ($self, $text) = @_;
   $$text =~ s/&/&amp;/g;
   $$text =~ s/>/&gt;/g;
   $$text =~ s/</&lt;/g;

   $$text
}


1
