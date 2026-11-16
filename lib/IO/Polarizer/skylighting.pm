package IO::Polarizer::skylighting;

use v5.16;
use warnings;

use IO::Polarizer;

our @COMMAND = qw(skylighting -f ansi -r -C 16 -S pygments);

# A file which has an escape character is left as it is: skylighting
# takes the ANSI sequences in it apart, and exits with status 0.
sub match {
    my $file = shift;
    return 0 unless -f $file;
    open my $fh, '<:raw', $file or return 0;
    local $/;
    my $content = <$fh> // return 0;
    index($content, "\e") < 0;
}

my $done;
sub setup {
    return if $done++;
    IO::Polarizer::register(match => \&match, command => \@COMMAND);
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
and so is a file which has an escape character already.

The C<pygments> style, the default of pandoc, has no background
color, and C<-C 16> uses the 16 colors of the terminal, so that the
colors go with those of the terminal.

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
