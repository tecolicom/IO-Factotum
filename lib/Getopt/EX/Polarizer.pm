package Getopt::EX::Polarizer;

use v5.16;
use warnings;

use IO::Polarizer;

# -MPolarizer::load=NAME calls load(NAME => 1): the converter of
# IO::Polarizer::NAME is registered.  ARGV is not tied here; the
# program opens its files by IO::Polarizer::open_input.
sub load {
    my @names;
    while (my($name, $val) = splice @_, 0, 2) {
	push @names, $name if $val;
    }
    IO::Polarizer::load(@names);
}

1;

=encoding utf-8

=head1 NAME

Getopt::EX::Polarizer - Getopt::EX module to load IO::Polarizer converters

=head1 SYNOPSIS

    ansicolumn -MPolarizer::load=skylighting file.c file.h

=head1 DESCRIPTION

This is a module of L<Getopt::EX> for the commands which open their
files by C<IO::Polarizer::open_input>.

Note that L<optex|App::optex> takes a C<-M> option after the command
name as its own module, when it can load it.  L<ansicolumn|App::ansicolumn>
has the C<--polarizer> option, which does the same and is not taken.

=over 4

=item B<load>=I<name>

Register the converter of C<IO::Polarizer::>I<name>
(C<IO::Polarizer::load>).

=back

=head1 SEE ALSO

L<IO::Polarizer>, L<IO::Polarizer::skylighting>, L<Getopt::EX>

=cut

__DATA__
