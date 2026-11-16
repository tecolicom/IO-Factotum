package IO::Polarizer::skylighting;

use v5.16;
use warnings;

use IO::Polarizer;

our @COMMAND = qw(skylighting -f ansi -r -C 16 -S pygments);

# A file larger than this is left as it is, 0 for no limit.  The
# colored text is many times larger than the file, and takes time to
# fold: some seconds for a megabyte.
our $MAX_SIZE = 256 * 1024;

# A file which has an escape character is left as it is: skylighting
# takes the ANSI sequences in it apart, and exits with status 0.
# So are an empty file, which would get a line, and a large one.
sub match {
    my $file = shift;
    return 0 unless -f $file;
    my $size = -s _ or return 0;
    return 0 if $MAX_SIZE and $size > $MAX_SIZE;
    open my $fh, '<:raw', $file or return 0;
    local $/;
    my $content = <$fh> // return 0;
    index($content, "\e") < 0;
}

# Run skylighting on the file given as the last argument, and print
# what it gives without the sequences which do nothing: skylighting
# puts \e[22;23;24m after every reset, and resets twice at the top.
# A line which ends with two sequences gets an empty line after it
# when it is folded by Text::ANSI::Fold and the text fills the width.
# This is called in a process of its own (IO::Polarizer), and dies
# when skylighting fails: the file is then read as it is.
sub highlight {
    my $file = $_[-1];
    my $pid = open my $fh, '-|', @COMMAND, $file or die "skylighting: $!\n";
    my $out = do { local $/; <$fh> };
    close $fh or die "skylighting failed\n";
    $out //= '';
    $out =~ s/\e\[0m\K\e\[22;23;24m//g;
    $out =~ s/\e\[0m\K(?:\e\[0m)+//g;
    # CR LF stay together: the reset comes between them
    $out =~ s/\r((?:\e\[[0-9;]*m)+)$/$1\r/mg;
    print $out;
}

my $done;
sub setup {
    return if $done++;
    IO::Polarizer::register(match => \&match, command => [ \&highlight ]);
    return;
}

sub import {
    setup();
    IO::Polarizer::tie_argv();
}

1;

__END__

=encoding utf-8

=head1 NAME

IO::Polarizer::skylighting - syntax highlight by skylighting

=head1 SYNOPSIS

    perl -MIO::Polarizer::skylighting -ne 'print' file.c

    ansicolumn --polarizer=skylighting file.c file.h

=head1 DESCRIPTION

This module registers a converter of L<IO::Polarizer> which colors
source files by the C<skylighting> command, the syntax highlighter of
pandoc:

    skylighting -f ansi -r -C 16 -S pygments FILE

The language is told by C<skylighting> from the name of the file.  A
file it does not know, as one without an extension, is read as it is,
and so are a file which has an escape character already, an empty
file, and a file larger than C<$IO::Polarizer::skylighting::MAX_SIZE>
bytes (256 KB by default, 0 for no limit): the colored text is many
times larger than the file and takes time to process.

The C<pygments> style, the default of pandoc, has no background
color, and C<-C 16> uses the 16 colors of the terminal, so that the
colors go with those of the terminal.

The sequences which do nothing in the output of C<skylighting>, as
C<ESC[22;23;24m> after every reset, are taken away.

Loaded by C<use> or C<-M>, it also ties C<ARGV>
(C<IO::Polarizer::tie_argv>), and a program which reads by
C<E<lt>E<gt>> gets the colored text.  C<setup> only registers the
converter.

=head1 INSTALL

C<skylighting> is in Homebrew and in the packages of the Linux
distributions:

    brew install skylighting

=head1 SEE ALSO

L<IO::Polarizer>, L<Getopt::EX::Polarizer>

L<https://github.com/jgm/skylighting>

=cut
