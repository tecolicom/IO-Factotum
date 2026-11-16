package IO::Polarizer;

use v5.16;
use warnings;

our $VERSION = "0.01";

use Carp;
use IO::File;
use Command::Run;

my @converter;

sub register {
    my %arg = @_;
    my $match   = delete $arg{match}   // croak "register: match is required";
    my $command = delete $arg{command} // croak "register: command is required";
    croak "register: unknown parameter: @{[ sort keys %arg ]}" if %arg;
    ref $match eq 'Regexp' or ref $match eq 'CODE'
	or croak "register: match must be a regex or a code reference";
    ref $command eq 'ARRAY' && @$command
	or croak "register: command must be an array reference";
    push @converter, { match => $match, command => [ @$command ] };
    return;
}

sub clear {
    @converter = ();
    return;
}

sub converter {
    my $file = shift;
    for my $c (@converter) {
	my $match = $c->{match};
	if (ref $match eq 'CODE' ? $match->($file) : $file =~ $match) {
	    return $c;
	}
    }
    undef;
}

sub open_input {
    my $file = shift;

    # the standard input is read as it is
    if ($file eq '-') {
	my $fh = IO::File->new;
	open $fh, '<&', \*STDIN or return undef;
	binmode $fh, ':raw';
	return $fh;
    }

    # The file is opened first: a file which can not be read is an
    # error of the caller with $! set, whatever the converter does
    my $fh = IO::File->new($file, '<') // return undef;
    binmode $fh, ':raw';

    my $c = converter($file) // return $fh;
    my $run = Command::Run->new(
	command => [ @{$c->{command}}, $file ],
	stderr  => 'capture',
    )->update;
    # a converter which fails leaves the file as it is
    return $fh if $run->result->{result} != 0;

    my $converted = $run->fh;
    $converted->seek(0, 0) or return $fh;
    binmode $converted, ':raw';
    $converted;
}

# Register the converters of IO::Polarizer::NAME by their names
sub load {
    for my $name (@_) {
	$name =~ /\A\w+(?:::\w+)*\z/
	    or croak "IO::Polarizer: $name: invalid converter name";
	my $module = __PACKAGE__ . "::$name";
	eval "require $module; 1"
	    or die "IO::Polarizer: $name: no such converter\n$@";
	my $setup = $module->can('setup')
	    or die "IO::Polarizer: $module has no setup function\n";
	$setup->();
    }
    return;
}

sub tie_argv {
    return if tied *ARGV;
    require IO::Polarizer::ARGV;
    tie *ARGV, 'IO::Polarizer::ARGV';
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

IO::Polarizer - read files through a converter chosen by their names

=head1 SYNOPSIS

    use IO::Polarizer;

    IO::Polarizer::register(
        match   => qr/\.gz$/,
        command => [ 'gzip', '-dc' ],
    );

    my $fh = IO::Polarizer::open_input($file) or die "$file: $!";
    while (<$fh>) {
        ...
    }

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

A polarizer is a filter put in front of a lens: the subject is not
touched, and what comes through looks different.  This module does
the same to files.  A file is opened through a converter chosen by
its name, and the handle gives the output of the converter instead of
the content of the file.  The file itself is not changed, and the
program keeps its name.

Converters are registered with a condition on the file name.  A file
which no converter takes, and a file whose converter fails, is read
as it is.

=head1 FUNCTIONS

Nothing is exported.

=over 4

=item B<register>(B<match> => I<condition>, B<command> => I<command>)

Register a converter.  Converters are tried in the order they were
registered, and the first one that matches is used.

I<condition> is a regex which the file name is matched against, or a
code reference which is called with the file name and returns true
for the file to convert.

I<command> is an array reference in the form of L<Command::Run>: an
external command with its arguments, or a code reference with its
arguments.  The file name is added as the last argument, and the
standard output of the command is the converted content.  The command
is not given to the shell.

    register(match => qr/\.gz$/, command => [ 'gzip', '-dc' ]);

    register(match   => sub { -B $_[0] },
             command => [ \&to_text, '--plain' ]);

The standard error of the command is discarded.

=item B<clear>()

Remove all the converters.

=item B<open_input>(I<file>)

Open the I<file> for reading and return the handle, an L<IO::File>
object.  When a converter matches the name and exits with status 0,
the handle reads its output, which is kept in a temporary file
without a name.  Otherwise the handle reads the file itself.

It returns C<undef> with C<$!> set when the file can not be opened.

The handle has the C<:raw> layer.  Set the encoding by C<binmode>:

    my $fh = IO::Polarizer::open_input($file) or die "$file: $!";
    binmode $fh, ':encoding(utf8)';

The name C<-> is the standard input, which is not converted.

=item B<load>(I<name>, ...)

Register the converters of the modules C<IO::Polarizer::>I<name>, by
calling their C<setup> function.  It dies when there is no such
module.

    IO::Polarizer::load('skylighting');

=item B<tie_argv>()

Tie C<ARGV>, so that C<E<lt>E<gt>> reads the files of C<@ARGV> by
C<open_input>.  A program which reads by C<E<lt>E<gt>> gets the
converted content with no change in it:

    IO::Polarizer::tie_argv();
    while (<>) {
        print "$ARGV: $_";
    }

C<@ARGV> is looked at when the first line is read, so the options can
be taken from it before.  As with the plain C<E<lt>E<gt>>, C<$ARGV>
is the name of the file, C<$.> counts the lines of all the files,
C<eof()> is true at the end of the last file, C<close ARGV> starts
the line numbers again, and the standard input is read when there is
no file.  C<E<lt>E<lt>E<gt>E<gt>> and the C<-i> option of perl are
not supported.

=back

=head1 SEE ALSO

L<Command::Run>

=head1 AUTHOR

Kazumasa Utashiro

=head1 LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
