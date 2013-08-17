#!/usr/bin/perl
use Modern::Perl;

my %map;

sub vonJeffmann2013 {
    my ($size,$hex) = @_;
    $hex = 1 unless $hex;
    return sub {
	my $x = shift || 0;
	$x = ($x * $hex)**2 + $hex**5;
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
	return if $history{$seed};
	$history{$seed}++;
	return $seed;
    }
}

sub load_map {
    my ($x, $y) = @_;
    die "Map size ($x,$y) is too big!" if $x > 99 || $y > 99;
    undef(%map);
    for (1..$x) {
	my $a = $_;
	for (1..$y) {
	    my $b = $_;
	    $map{get_coords($a,$b)} = "";
	}
    }
}

sub get_coords {
    my ($x, $y) = @_;
    $x = "0$x" if $x < 10;
    $y = "0$y" if $y < 10;
    return "$x$y";
}

sub analyze {
    my ($seed, $f) = @_;
    my $di = destructing_iterator($seed, $f);
    my %history;
    my $count = 0;
    my $last;
    $history{$seed} = $count;
    while (my $x = $di->()) {
	$count++;
	$history{$x} = $count;
	$last = $x;
    }    
    my $loopstart =  $f->($last);
    my $val = $history{$f->($last)} || 1;
    my $looplength = $count - $val + 1;
    my $treelength = $count - $looplength;

    return ($count, $looplength, $treelength, $looplength);
}

load_map(8,10);
my $size = 4;

map {
    my $hex = $_;
    say "-" x 60;
    say "Hex: $hex";

    my $f = vonJeffmann2013($size, $hex);

    my %tree;
    my %loop;
    my %tot;

    my $bigtree = -1;
    my $bigloop = -1;

    for (0..9999) {
	my $seed = $_;
	$seed = "0" x (4 - length($seed)) . $seed;
	my ($length, $loopstart, $treelength, $looplength) = analyze($seed, $f);
	
	$tree{$seed} = $treelength;
	$loop{$seed} = $looplength;
	$tot{$seed} = $length;

	$bigtree = $seed if $treelength > ($tree{$bigtree} || 0);
	$bigloop = $seed if $length > ($tot{$bigloop} || 0);
    }

    my $treestuff = "$tree{$bigtree} + $loop{$bigtree} = $tot{$bigtree}";
    my $loopstuff = "$tree{$bigloop} + $loop{$bigloop} = $tot{$bigloop}";
    my $treetext = "BiggestTree: $bigtree ---> $treestuff";
    my $looptext = "BiggestLoop: $bigloop ---> $loopstuff";
    say $treetext;
    say $looptext if $bigtree ne $bigloop;
} sort keys %map;
