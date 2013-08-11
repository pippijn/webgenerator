package Text::Highlight;

use strict;
use warnings FATAL => 'all';
use utf8;

use Carp qw/cluck croak/;

#accessable and editable if someone really wants them
use vars qw($VERSION $VB_FORMAT $VB_WRAPPER $VB_ESCAPE
  $TGML_FORMAT $TGML_WRAPPER $TGML_ESCAPE $RAW_COLORS
  $DEF_FORMAT $DEF_ESCAPE $DEF_WRAPPER $DEF_COLORS
  $ANSI_FORMAT $ANSI_WRAPPER $ANSI_COLORS);
$VERSION = 0.04;

#some wrapper settings for typical message boards (ie, the ones I frequent :)
#Anyone with an idea for IPB or phpBB settings, let me know. Last time I checked IPB,
#    the only way to set mono-spaced font is to use [code] tags, which destroy any markup within.
#A PHP port is planned once the issues with this get ironed out.
$VB_FORMAT  = '[color=%s]%s[/color]';
$VB_WRAPPER = '[code]%s[/code]';

# [ -> &#91;
$VB_ESCAPE = sub { $_[0] =~ s/\[/&#91;/g; $_[0] };

$TGML_FORMAT  = '[color %s]%s[/color]';
$TGML_WRAPPER = "[code]\n%s\n[/code]";

# [ -> [&#91;]
$TGML_ESCAPE = sub { $_[0] =~ s/\[/[&#91;]/g; $_[0] };

$RAW_COLORS = {
   comment => '#006600',
   string  => '#808080',
   number  => '#FF0000',
   key1    => '#0000FF',
   key2    => '#FF0000',
   key3    => '#FF8000',
   key4    => '#00B0B0',
   key5    => '#FF00FF',
   key6    => '#D0D000',
   key7    => '#D0D000',
   key8    => '#D0D000',
};

#default values in new ()
$DEF_FORMAT  = '<span class="%s">%s</span>';
$DEF_ESCAPE  = \&_simple_html_escape;
$DEF_WRAPPER = '<pre>%s</pre>';
$DEF_COLORS  = {
   comment => 'comment',
   string  => 'string',
   number  => 'number',
   key1    => 'key1',
   key2    => 'key2',
   key3    => 'key3',
   key4    => 'key4',
   key5    => 'key5',
   key6    => 'key6',
   key7    => 'key7',
   key8    => 'key8',
};

#set limit maximum of keyword groups (must change default colors hash, too)
#not a package var, must be changed here (better know what you're doing)
my $KEYMAX = 8;

sub new {
   my $class = shift;
   
   #set defaults (as copies of $DEF_*)
   my $self = bless {
      _output => '',
      _format => $DEF_FORMAT,
      _escape => $DEF_ESCAPE,
      _wrapper => $DEF_WRAPPER,
      _colors => { %$DEF_COLORS },
      _grammars => { },
   }, $class;
   
   #set any parameters passed to new
   $self->configure (@_);
   
   return $self;
}

sub configure {
   my $self = shift;
   
   #my extensive parameter checking :(
   my %param = @_ if (@_ % 2 == 0);
   
   return unless %param;
   
   #do we want vBulletin-friendly output?
   if (exists $param{vb} && $param{vb}) {
      #set generalised defaults for posting in a forum
      $self->{_format}  = $VB_FORMAT;
      $self->{_wrapper} = $VB_WRAPPER;
      %{ $self->{_colors} } = %$RAW_COLORS;
      $self->{_escape} = $VB_ESCAPE;
   }
   
   #do we want Tek-Tips-friendly output?
   if (exists $param{tgml} && $param{tgml}) {
      
      #set generalised defaults for posting in a forum
      $self->{_format}  = $TGML_FORMAT;
      $self->{_wrapper} = $TGML_WRAPPER;
      %{ $self->{_colors} } = %$RAW_COLORS;
      $self->{_escape} = $TGML_ESCAPE;
   }
   
   #do we want ANSI-terminal-friendly output?
   if (exists $param{ansi} && $param{ansi}) {
      #dumped in an eval block to only require the module for those who use it
      eval {
         require Term::ANSIColor;
         $ANSI_FORMAT   = '%s%s'.color ('reset');
         $ANSI_WRAPPER  = '%s';
         $ANSI_COLORS   = { comment => color ('bold green'),
            string  => color ('bold yellow'),
            number  => color ('bold red'),
            key1    => color ('bold cyan'),
            key2    => color ('bold red'),
            key3    => color ('bold magenta'),
            key4    => color ('bold blue'),
            key5    => color ('bold blue'),
            key6    => color ('bold blue'),
            key7    => color ('bold blue'),
            key8    => color ('bold blue'),
         };
      };
      if ($@) {
         cluck $@;
      } else {
         #set ANSI color escape sequences
         $self->{_format}  = $ANSI_FORMAT;
         $self->{_wrapper} = $ANSI_WRAPPER;
         %{ $self->{_colors} } = %$ANSI_COLORS;
         
         #set the escape to undef, assuming it's not already set
         $param{escape} = undef unless (exists $param{escape});
      }
   }
   
   #if array ref, set to all readable files in list, else just the one passed
   if (exists $param{wordfile}) {
      if (ref $param{wordfile} eq 'ARRAY') {
         my $tmpref = [];
         for (@{ $param{wordfile} }) {
            -r && push @$tmpref, $_;
         }
         $self->{_wordfile} = $tmpref if (@$tmpref > 0);
      } else {
         -r $param{wordfile} && push @{ $self->{_wordfile} },
         $param{wordfile};
      }
   }
   
   #should have two "%s" strings in it, for type and code
   if (exists $param{format}) {
      if ($param{format} =~ m/(\%s.*){2}/) {
         $self->{_format} = $param{format};
      } else {
         cluck "Param format invalid: does not have two %s strings.\n";
      }
   }
   
   #need one %s for the code
   if (exists $param{wrapper}) {
      
      #undef -> no wrapper
      unless (defined ($param{wrapper})) {
         $self->{_wrapper} = '%s';
      }
      #if not undef, needs to have a %s for the code
      elsif ($param{wrapper} =~ m/\%s/) {
         $self->{_wrapper} = $param{wrapper};
      } else {
         cluck "Param wrapper invalid: does not have %s string.\n";
      }
   }
   
   #sub is the same prototype as CGI.pm's escapeHTML ()
   #and HTML::Entity's encode_entities ()
   #$escaped_string = escapeHTML ("unescaped string");
   if (exists $param{escape}) {
      
      #undef -> no escaping, set dummy sub to return input
      unless (defined ($param{escape})) {
         $self->{_escape} = sub { return $_[0] };
      }
      #if not undef, check for code ref
      elsif (ref $param{escape} eq 'CODE') {
         $self->{_escape} = $param{escape};
      }
      #and last, check for 'default' string
      elsif ($param{escape} =~ m/^default$/i) {
         $self->{_escape} = $DEF_ESCAPE;
      } else {
         cluck "Param escape invalid: is not coderef, undef, or 'default' string.\n";
      }
   }
   
   #must pass a hashref
   if (exists $param{colors}) {
      if (ref $param{colors} eq 'HASH') {
         
         #loop over only predefined classes (defaults from new)
         for (keys %{ $self->{_colors} }) {
            $self->{_colors}{$_} = $param{colors}{$_}
            if (exists $param{colors}{$_});
         }
      } else {
         cluck "Param colors invalid: is not a hashref.\n";
      }
   }
}

#get the syntax from a sub-module, and maybe the sub-module will even do the parsing
sub highlight {
   my $self = shift;
   
   #call with a hash or not
   my %args = @_ if (@_ % 2 == 0);
   my ($type, $code, $options);
   if (exists $args{type} && exists $args{code}) {
      $type    = $args{type};
      $code    = $args{code};
      $options = $args{options};    #optional
   } else {
      $type    = shift;
      $code    = shift;
      $options = shift;             #optional
   }

   croak "Attempted to highlight reference" if length ref $code;
   
   #check null context
   return unless wantarray;
   
   #this is not a class method, don't try it
   return unless ref $self;

   #check if we've loaded this type custom from a file, as it overrides any default option
   if (exists $self->{_grammars}{$type}) {
      $self->{_active} = $self->{_grammars}{$type};
      $self->_highlight ($code);
   } else {
      #this is where the module for this type should be
      #since this is being require-d, should probably taint check $type a bit
      my $package = __PACKAGE__ . "::$type";
      
      #try to include it
      eval "require $package" or croak "Bad grammar: $@";
      my $grammar = $package->new;
      
      #clear output
      $self->{_output} = '';
      
      #check if the module has a highlight method, else just get the syntax from it and use the parser here
      if ($grammar->can ('highlight') and $options and $options ne 'simple') {
         $grammar->highlight ($self, $code, $options);
      } elsif ($grammar->can ('syntax')) {
         $self->{_active} = $grammar->syntax;
         $self->hashset;
         $self->_highlight ($code);
      } else {
         croak "$grammar does not have a highlight or syntax method.";
      }
   }
   
   #wrap the code in whatever tags
   $self->{_output} = sprintf ($self->{_wrapper}, $self->{_output});
   
   return $self->output;
}

#the one that does all the work
sub _highlight {
   my $self = shift;
   my $code = shift;
   
   #make a hash to store the index of the next occurance of each comment/string/escape delimiter
   my %delims;
   
   $delims{ $self->{_active}{escape} } = 1;
   
   #check definedness and emptiness in case of ordering oddities in the grammar file
   defined && ($_ ne '') && ($delims{$_} = 1)
   for (@{ $self->{_active}{quot} });
   defined && ($_ ne '') && ($delims{$_} = 1)
   for (@{ $self->{_active}{lineComment} });
   
   #a valid open AND close tag is a must to consider a block comment
   for (0, 1) {
      if (   defined $self->{_active}{blockCommentOn}[$_]
            and $self->{_active}{blockCommentOn}[$_] ne ''
            and defined $self->{_active}{blockCommentOff}[$_]
            and $self->{_active}{blockCommentOff}[$_] ne '')
      {
         $delims{ $self->{_active}{blockCommentOn}[$_] } = 1;
      }
   }

   #index to the current string location in $code
   my $cur = 0;
   
   #search for the first occurance of each delimiter
   $delims{$_} = index ($code, $_, $cur) for (keys %delims);
   
   #while some delimiters still remain
   while (%delims and $cur != -1) {
      
      #find the next delimiter and recalculate any passed indexes
      my $min = _find_next_delim (\%delims, \$code, $cur);
      
      #break out of the loop if it couldn't find a delim
      last unless (defined ($min));
      
      #colorise what was before the found comment/string
      $self->_keyword (substr ($code, $cur, $delims{$min} - $cur));
      
      #I realise this is pretty pointless, it's just that in older versions of this
      #whose code is reused, there was no $min, just a $delim that was pulled from a regex
      #mnemonically, $delim is the delimiter, and $min is the key to the minimum index
      #spare the couple bytes for now so I don't have to say $delims{$delim}
      my $delim = $min;
      
      #move the index of $min past the delimiter itself
      #it makes for easier reading substr () and index () calls
      #it gets reset to 0 after each call below, anyway,
      #so it will get recalculated on the next iteration
      $delims{$min} += length ($min);
      
      #if an escape sequence
      if ($delim eq $self->{_active}{escape}) {
         
         #pass thru uncolored (might define an 'escape' color sometime)
         #most escape sequences tend to be in strings, anyway
         #the original delimiter (escape character) and the one after it are passed
         $self->_colourise (undef,
            $delim . substr ($code, $delims{$min}, 1));
         
         #move the current index past the character following the escape
         $cur = $delims{$min} + 1;

         #reset escape's next position
         $delims{$min} = 0;
         
         #find me another delimiter!
         next;
      }

      #if a quote
      if (grep { $delim eq $_ } @{ $self->{_active}{quot} }) {
         
         #since a string can contain escape sequences, this if {} block functions
         #roughly the same as the outer while {} block, but with its own %delim (as %d)
         #and $min (as $m) and $cur (as $idx)

         #init %d with whatever quote character got us in here (and may get us out)
         #and the stored escape character for this language
         my %d = ($delim => 1, $self->{_active}{escape} => 1);
         
         #add newline as an escape unless this language support multiline quotes
         $d{"\n"} = 1 unless ($self->{_active}{continueQuote});

         #the search for the end of the string starts after the starting quote
         my $idx = $delims{$min};
         
         #search for the first occurance of each delimiter
         $d{$_} = index ($code, $_, $idx) for (keys %d);
         
         while (%d and $idx != -1) {
            
            #find the next delimiter
            my $m = _find_next_delim (\%d, \$code, $idx);
            
            #if it couldn't find any delimter or we found a newline, we couldn't
            #close the string, so set a negative index and drop out of the loop
            if (!defined ($m) || $m eq "\n") {
               $idx = -1;
               last;
            }
            
            #set after the found delimiter
            $d{$m} += length ($m);

            #if esc, set the index past the escape sequence and reset esc's idx
            if ($m eq $self->{_active}{escape}) {
               $idx = $d{$m} + 1;
               $d{$m} = 0;
            }
            
            #if a closing quote, set index to after it and drop from the loop
            if ($m eq $delim) {
               $idx = $d{$m};
               last;
            }
         }
         
         #if a suitable closing delimiter was found
         if ($idx != -1) {
            $self->_colourise ('string',
               $delim
               . substr ($code, $delims{$min}, $idx - $delims{$min}));
            $cur = $idx;
         } else    #couldn't close the quote, just send it on
         {
            $self->_colourise (undef, $delim);
            $cur = $delims{$min};
         }
         $delims{$min} = 0;
         next;
      }
      
      #check if it starts a line comment
      if (grep { $delim eq $_ } @{ $self->{_active}{lineComment} }) {
         
         #comment to the next newline
         if ((my $end = index ($code, "\n", $delims{$min})) != -1) {
            #check if we split a windows newline in the source, and move before it
            $end-- if (substr ($code, $end - 1, 1) eq "\r");
            
            #if the source is viewed, it'll look prettier if the closing comment tag
            #is before the newline, so don't move the index past it
            $self->_colourise ('comment',
               $delim
               . substr ($code, $delims{$min}, $end - $delims{$min}));
            $cur = $end;
         } else    #no newline found, so comment to string end
         {
            $self->_colourise ('comment',
               $delim . substr ($code, $delims{$min}));
            $cur = -1;
         }
         $delims{$min} = 0;
         next;
      }
      
      #something to remember which block comment this is
      my $t;
      
      #check if it starts a block comment
      if (
         grep {
            ($delim eq $self->{_active}{blockCommentOn}[$_]) and defined ($t = $_)
         } (0 .. $#{ $self->{_active}{blockCommentOn} })
      )
      {
         
         #comment to the closing comment tag
         if (
            (
               my $end = index (
                  $code, $self->{_active}{blockCommentOff}[$t],
                  $delims{$min}
               )
            ) != -1
         )
         {
            
            #set end after the closing tag
            $end += length ($self->{_active}{blockCommentOff}[$t]);
            $self->_colourise ('comment',
               $delim
               . substr ($code, $delims{$min}, $end - $delims{$min}));
            $cur = $end;
         } else    #no closing tag found, so comment to string end
         {
            $self->_colourise ('comment',
               $delim . substr ($code, $delims{$min}));
            $cur = -1;
         }
         $delims{$min} = 0;
         next;
      }
   }
   
   #colorise last chunk after all comments and strings if there is one
   print ref $code;
   $self->_keyword (substr ($code, $cur)) if ($cur != -1);
   
   #return $self->output;
}

sub output {
   my $self = shift;
   
   #return a two-element list of the marked-up code and the code type's name,
   #or just the marked-up code itself, depending on context
   #return wantarray ? ($self->{_output}, $self->{_active}{name}) : $self->{_output};
   
   #the above was useful when code's extention was passed, but now since module names
   #are passed, I assume those will be pretty descriptive, and this name method isn't needed.
   #Likely it'll just cause problems with people unexpected using list context (like print)
   return $self->{_output};
}

sub _find_next_delim {
   
   #hash-ref, scalar-ref (could be a big scalar), scalar
   my ($delims, $code, $cur) = @_;
   my $min;
   for (keys %$delims) {
      #find a new index for those not after the current "start" position
      $delims->{$_} = index ($$code, $_, $cur) if ($delims->{$_} < $cur);
      
      #doesn't exist in the remaining code, don't touch it again
      if ($delims->{$_} == -1) {
         delete $delims->{$_};
         next;
      }
      
      #if min is not defined or min is less than new delim, set to new
      $min = $_ if (!defined ($min) or $delims->{$_} < $delims->{$min});
   }
   return $min;
}

sub _simple_html_escape {
   my $code = shift;
   
   #escape the only three characters that "really" matter for displaying html
   $code =~ s/&/&amp;/g;
   $code =~ s/</&lt;/g;
   $code =~ s/>/&gt;/g;
   
   return $code;
}

sub _colourise {
   my ($self, $type, $what) = @_;
   
   #do any escaping of characters before appending to output
   $what = &{ $self->{_escape} } ($what);
   
   #check if type is defined. Append type's class, else just the bare text
   $self->{_output} .= defined ($type)
                       ? sprintf ($self->{_format}, $self->{_colors}{$type}, $what)
                       : $what;
}

sub _keyword {
   my ($self, $code) = @_;

   #escape all the delimiters that need to be and dump in char class
   my $d = quotemeta $self->{_active}{delimiters};
   
   #save the pattern so it doesn't compile each time (whitespace is considered a delim, too)
   my $re = qr/\G(.*?)([$d\s]+)/s;

   #could help, in theory, but it doesn't seem to help at all when doing
   #repeated m//g global searches with position anchors defeats the point of study ()
   #study ($code);
   
   while (
      $code =~ m/$re/gc ||   #search for a delimiter (don't reset pos on fail)
      $code =~ m/\G(.+)/sg
   )    #grab what's left in the string if there's no delim
   {
      
      #before the delimiter
      my $chunk = $1;
      
      #the delimiter(s), or empty if no more delims
      my $delim = defined ($2) ? $2 : undef;
      
      #remember if we actually did anything
      my $done = 0;
      
      #find which key group, if any, this chunk falls under
      #start at 1 and work up
      my $key = 1;
      
      #check if this key group exists for this language
      while (exists $self->{_active}{"key$key"}) {
         my $check = ($self->{_active}{case}) ? $chunk : lc ($chunk);
         
         #check if this chunk exists for this keygroup
         for (grep { ref $self->{_active}{"key$key"}->{$_} eq "Regexp" } keys %{ $self->{_active}{"key$key"} }) {
            if ($chunk =~ $self->{_active}{"key$key"}->{$_}) {
               $self->_colourise ("key$key", $chunk);
               $done = 1;
               last
            }
         }
         if (exists $self->{_active}{"key$key"}->{$check}) {
            #colorise it as this group, set done/found and exit loop
            # XXX: this colourises
            $self->_colourise ("key$key", $chunk);
            $done = 1;
            last;
         }

         #nope, not this key group, maybe next
         $key++;
      }
      
      #I had a much better "number" regex, but it was probably perl-specific and this should do
      if ($chunk =~ m/^[-+]?\d*\.?\d+$/) {
         $self->_colourise ('number', $chunk);
         $done = 1;
      }
      
      #if the chunk didn't match a pattern above, it's nothing and gets no color but default
      $self->_colourise (undef, $chunk) unless ($done);
      
      #dump the delimiter to output, too, without color
      $self->_colourise (undef, $delim) if (defined ($delim));
   }
}

sub hashset {
   my ($self) = @_;
   for (grep { /^key/ } keys %{ $self->{_active} }) {
      my $keywords = $self->{_active}->{$_};
      my %hashset;
      $hashset{$_} = $_ for @$keywords;
      $self->{_active}->{$_} = \%hashset;
   }
}


1
