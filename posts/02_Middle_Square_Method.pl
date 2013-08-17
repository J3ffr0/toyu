#!/usr/bin/perl
use Modern::Perl;

# Patterns unfamiliar, patterns lead you through
# To patterns of discovery tracing out the clues
# Can you recognize the patterns that you find?
#                           -- Devo's "Patterns"

sub vonNeumann1949 {
    my ($size) = @_;
    return sub {
	my ($x) = @_;
	$x = $x**2;
	$x = "0" x (8 - length($x)) . $x if length($x) < 8;
	my $start = int(length($x)/2) - $size/2;
	return substr($x,$start, $size);
    }
}

sub destructing_iterator {
    my ($seed, $function) = @_;;
    my %history;
    $history{$seed}++;
    return sub {
	$seed = $function->($seed);
	return if $history{$seed} || $seed =~ /^0+$/;
	$history{$seed}++;
	return $seed;
    }
}

my $x = shift(@ARGV);
my $size = shift(@ARGV) || 6;
my $plus = shift(@ARGV) || 0;
if ($x =~ /^\d+$/) {
    my $di = destructing_iterator($x + $plus, vonNeumann1949($size));
    while (defined($x)) {
	$x = $di->();
	say $x if $x;
    }
} else {
    my %tally;
    for (1..9999) {
	my $x = $_;
	$x = "0" x (4 - length($x)) . $x;
	my $original = $x;
	my $di = destructing_iterator($x + $plus, vonNeumann1949($size));
	my $count;
	while (defined($x)) {
	    $x = $di->();
	    $count++;
	}	
	$tally{$original} = $count - 1;
    }
    map {
	my $x = $_;
	say "$x,$tally{$x}";
    } sort {$tally{$b} <=> $tally{$a}} keys %tally;
}

