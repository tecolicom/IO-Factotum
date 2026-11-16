use v5.16;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    my $found = grep { -x "$_/skylighting" } File::Spec->path;
    plan skip_all => 'skylighting is not installed' unless $found;
}

use IO::Polarizer;

my $dir = tempdir(CLEANUP => 1);
my $lib = File::Spec->rel2abs('lib');

sub put {
    my($name, $text) = @_;
    open my $fh, '>', "$dir/$name" or die "$name: $!";
    print $fh $text;
    close $fh;
    "$dir/$name";
}

sub slurp {
    my $fh = shift;
    local $/;
    scalar <$fh>;
}

put 'a.c',   "int x = 1;\n";
put 'e.c',   "\e[31mred\e[m\n";
put 'noext', "#!/bin/bash\necho\n";

# the module registers its converter, without tying ARGV when it is
# only required
require IO::Polarizer::skylighting;
IO::Polarizer::skylighting::setup();
ok !tied(*ARGV), 'setup does not tie ARGV';

subtest 'skylighting: C source' => sub {
    my $out = slurp(IO::Polarizer::open_input("$dir/a.c"));
    like $out, qr/\e\[/, 'has colors';
    like $out, qr/int/, 'has the text';
    # -S pygments has no background, -C 16 no 256 or RGB colors
    unlike $out, qr/\e\[[0-9;]*\b(?:4[0-7]|10[0-7]|[34]8)\b/, 'no background, 16 colors';
};

subtest 'skylighting: file with ESC' => sub {
    is slurp(IO::Polarizer::open_input("$dir/e.c")), "\e[31mred\e[m\n",
	'as it is';
};

subtest 'skylighting: no extension' => sub {
    is slurp(IO::Polarizer::open_input("$dir/noext")), "#!/bin/bash\necho\n",
	'as it is';
};

subtest 'skylighting: setup twice' => sub {
    IO::Polarizer::skylighting::setup();
    like slurp(IO::Polarizer::open_input("$dir/a.c")), qr/\e\[/;
};

subtest 'skylighting: -M ties ARGV' => sub {
    my $out = qx{$^X -I"$lib" -MIO::Polarizer::skylighting -ne 'print "\$ARGV: \$_"' "$dir/a.c" 2>&1};
    like $out, qr/^\Q$dir\E\/a\.c: .*\e\[/, 'one-liner reads the colored text';
};

subtest 'Getopt::EX::Polarizer: load' => sub {
    my $script = put 'load.pl', q{
	use Getopt::EX::Polarizer;
	Getopt::EX::Polarizer::load(skylighting => 1);
	print tied(*ARGV) ? "tied\n" : "not tied\n";
	print IO::Polarizer::open_input(shift)->getlines;
    };
    my $out = qx{$^X -I"$lib" "$script" "$dir/a.c" 2>&1};
    like $out, qr/\Anot tied\n/, 'ARGV is not tied';
    like $out, qr/\e\[/, 'has colors';
};

subtest 'load' => sub {
    my $script = put 'ioload.pl', q{
	use IO::Polarizer;
	IO::Polarizer::load('skylighting');
	print tied(*ARGV) ? "tied\n" : "not tied\n";
	print IO::Polarizer::open_input(shift)->getlines;
    };
    my $out = qx{$^X -I"$lib" "$script" "$dir/a.c" 2>&1};
    like $out, qr/\Anot tied\n/, 'ARGV is not tied';
    like $out, qr/\e\[/, 'has colors';
    ok !eval { IO::Polarizer::load('nosuchconverter'); 1 }, 'unknown name dies';
    like $@, qr/nosuchconverter: no such converter/, 'with the name';
    ok !eval { IO::Polarizer::load('a b'); 1 }, 'invalid name dies';
};

subtest 'Getopt::EX::Polarizer: unknown name' => sub {
    my $script = put 'unknown.pl', q{
	use Getopt::EX::Polarizer;
	Getopt::EX::Polarizer::load(nosuchconverter => 1);
    };
    my $out = qx{$^X -I"$lib" "$script" 2>&1};
    isnt $?, 0, 'fails';
    like $out, qr/nosuchconverter/, 'with the name';
};

done_testing;
