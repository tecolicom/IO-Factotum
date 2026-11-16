
# NAME

IO::Polarizer - read files through a converter chosen by their names

# SYNOPSIS

    use IO::Polarizer;

    IO::Polarizer::register(
        match   => qr/\.gz$/,
        command => [ 'gzip', '-dc' ],
    );

    my $fh = IO::Polarizer::open_input($file) or die "$file: $!";
    while (<$fh>) {
        ...
    }

# VERSION

Version 0.01

# DESCRIPTION

A polarizer is a filter put in front of a lens: the subject is not
touched, and what comes through looks different.  This module does
the same to files.  A file is opened through a converter chosen by
its name, and the handle gives the output of the converter instead of
the content of the file.  The file itself is not changed, and the
program keeps its name.

Converters are registered with a condition on the file name.  A file
which no converter takes, and a file whose converter fails, is read
as it is.

# FUNCTIONS

Nothing is exported.

- **register**(**match** => _condition_, **command** => _command_)

    Register a converter.  Converters are tried in the order they were
    registered, and the first one that matches is used.

    _condition_ is a regex which the file name is matched against, or a
    code reference which is called with the file name and returns true
    for the file to convert.

    _command_ is an array reference in the form of [Command::Run](https://metacpan.org/pod/Command%3A%3ARun): an
    external command with its arguments, or a code reference with its
    arguments.  The file name is added as the last argument, and the
    standard output of the command is the converted content.  The command
    is not given to the shell.

        register(match => qr/\.gz$/, command => [ 'gzip', '-dc' ]);

        register(match   => sub { -B $_[0] },
                 command => [ \&to_text, '--plain' ]);

    The standard error of the command is discarded.

- **clear**()

    Remove all the converters.

- **open\_input**(_file_)

    Open the _file_ for reading and return the handle, an [IO::File](https://metacpan.org/pod/IO%3A%3AFile)
    object.  When a converter matches the name and exits with status 0,
    the handle reads its output, which is kept in a temporary file
    without a name.  Otherwise the handle reads the file itself.

    It returns `undef` with `$!` set when the file can not be opened.

    The handle has the `:raw` layer.  Set the encoding by `binmode`:

        my $fh = IO::Polarizer::open_input($file) or die "$file: $!";
        binmode $fh, ':encoding(utf8)';

    The name `-` is the standard input, which is not converted.

# SEE ALSO

[Command::Run](https://metacpan.org/pod/Command%3A%3ARun)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
