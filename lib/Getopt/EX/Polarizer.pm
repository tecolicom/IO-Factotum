package Getopt::EX::Polarizer;

use v5.16;
use warnings;

use IO::Polarizer;

# -MPolarizer::load=NAME calls load(NAME => 1): the converter of
# IO::Polarizer::NAME is registered.  ARGV is not tied here; the
# program opens its files by IO::Polarizer::open_input.
sub load {
    while (my($name, $val) = splice @_, 0, 2) {
	next unless $val;
	$name =~ /\A\w+(?:::\w+)*\z/
	    or die "Polarizer: $name: invalid converter name\n";
	my $module = "IO::Polarizer::$name";
	eval "require $module; 1"
	    or die "Polarizer: $name: no such converter\n$@";
	my $setup = $module->can('setup')
	    or die "Polarizer: $module has no setup function\n";
	$setup->();
    }
    return;
}

1;

=encoding utf-8

=head1 NAME

Getopt::EX::Polarizer - Getopt::EX module to load IO::Polarizer converters

=head1 SYNOPSIS

    ansicolumn -MPolarizer::load=skylighting file.c file.h

=head1 DESCRIPTION

This is a module of L<Getopt::EX> for the commands which open their
files by C<IO::Polarizer::open_input>, as L<ansicolumn|App::ansicolumn>
does when L<IO::Polarizer> is loaded.

=over 4

=item B<load>=I<name>

Register the converter of C<IO::Polarizer::>I<name>, by calling its
C<setup> function.

=back

=head1 SEE ALSO

L<IO::Polarizer>, L<IO::Polarizer::skylighting>, L<Getopt::EX>

=cut

__DATA__
