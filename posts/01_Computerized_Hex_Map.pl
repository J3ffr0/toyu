#!/usr/bin/perl
use Modern::Perl;

my %map;
my %state;

my %commands = (
    "x" => sub { exit(); },
    "l" => \&load_map,
    "s" => \&show_map,
    "j" => \&jump,
    "m" => \&move,
    );

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

sub show_map {
    print "Hexes: ";
    map {
	print " $_";
    } sort keys %map;
    print "\n\n";
}

sub jump {
    my ($to) = @_;
    if (exists ($map{$to})) {
	$state{cur} = $to;
	say "You are now at $to.";
    } else {
	say "There is no location at hex $to.";
    }
}

sub move {
    my $dir = shift(@_);
    my ($x, $y);
   
    ($x, $y) = ($1, $2) if $state{cur} =~ /(\d{2})(\d{2})/;
    $x =~ s/^0+//;
    $y =~ s/^0+//;
 
    if ($dir == 8) {
	$y -= 1; #North
    } elsif ($dir == 2) {
	$y += 1; #South
    } elsif ($dir == 7) {
	$x -= 1; #Northwest
	$y -= 1 unless ($x % 2);
    } elsif ($dir == 9) {
	$x += 1; #Northeast
	$y -= 1 unless ($x % 2);
    } elsif ($dir == 1) {
	$x -= 1; #Southwest
	$y += 1 if ($x % 2);
    } elsif ($dir == 3) {
	$x += 1; #Southeast
	$y += 1 if ($x % 2);
    }
  
    my $c = get_coords($x,$y);
    if (exists $map{$c}) {
	$state{cur} = $c;
	if (scalar @_) {
	    move(@_);
	} else {
	    say "You are now at $c.";
	}
    } else {
	say "That is off the map!";
    }
}

load_map(8,10);
say "Welcome to the toy universe!";
jump("0406");

while (1) {
    print "\n> ";
    my $x = <STDIN>;
    chomp($x);
    my @args = split(/\s+/, $x);
    my $c = shift(@args);

    if ($commands{$c}) {
	$commands{$c}->(@args);
    }
}
