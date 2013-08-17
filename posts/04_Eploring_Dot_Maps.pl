#!/usr/bin/perl
use Modern::Perl;
use File::Slurp;
use JSON;

my %map;
my %worlds;
my %state;
my %seeds;
my $size = 4;
my @history;
my ($min_x, $min_y) = (1,1);
my ($max_x, $max_y) = (0,0);

my %commands = (
    "x" => sub { exit(); },
    "l" => \&load_map,
    "s" => \&show_map,
    "j" => \&jump,
    "m" => \&move,
    "d" => \&dots,
    "display" => \&display,
    "clear" => \&clear,
    "save" => \&save,
    "load" => \&load,
    );

sub load_map {
    my ($x, $y) = @_;
    die "Map size ($x,$y) is too big!" if $x > 99 || $y > 99;
    ($max_x, $max_y) = ($x,$y);
    undef(%map);
    for (1..$x) {
	my $a = $_;
	for (1..$y) {
	    my $b = $_;
	    my $hex = get_coords($a,$b);
	    $map{$hex} = "";
	    unless ($seeds{$hex}) {
		$seeds{$hex} = find_seed($hex);
	    }
	}
    }
    save_seeds();
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

sub get_function {
    my ($hex) = @_;
    return vonJeffmann2013($size, $hex);
}

sub find_seed {
    my $hex = shift;
    say "... Finding best seed for hex $hex.";
    my $f = get_function($hex);

    my $bigtree = -1;
    my %tree;
    for (0..9999) {
	my $seed = $_;
	$seed = "0" x (4 - length($seed)) . $seed;
	my ($length, $loopstart, $treelength, $looplength) = analyze($seed, $f);
	$tree{$seed} = $treelength;
	$bigtree = $seed if $treelength > ($tree{$bigtree} || 0);
    }
    return $bigtree;
}

sub save_seeds {
    my $json = JSON->new->allow_nonref;
    write_file("seeds.json", $json->encode( \%seeds ));
}

sub clear {
    undef(%map);
    undef(%worlds);
    # leave seeds alone!
}

sub dots {
    my ($min, $max) = @_;
    say "Making dots between $min and $max.";

    map {
	my $hex = $_;
	unless ($worlds{$hex}) {
	    my $f = get_function($hex);
	    my $value = $f->($seeds{$hex});
	    if ($value >= $min && $value <= $max) {
		say "Found world in $hex with seed $seeds{$hex}: $value";
		$worlds{$hex}++;
	    }
	}
    } sort keys %map;
}

sub display {
    my ($x2, $y2, $x1, $y1) = @_;
    $x1 = $min_x unless $x1;
    $y1 = $min_y unless $y1;
    $x2 = $max_x unless $x2;
    $y2 = $max_y unless $y2;
    if ($x1 < $min_x) {
	say "Display x1 must be less than $min_x.";
	return;
    }
    if ($y1 < $min_y) {
	say "Display y1 must be less than $min_y.";
	return;
    }
    if ($x2 > $max_x) {
	say "Display x2 must be less than $max_x.";
	return;
    }
    if ($y2 > $max_y) {
	say "Display y2 must be less than $max_y.";
	return;
    }

    for ($y1..$y2) {
	my $y = $_;
	my $one = "";
	my $two = "  ";
	for ($x1..$x2) {
	    my $x = $_;
	    my $hex = get_coords($x,$y);
	    my $c = ".";
	    $c = "*" if $worlds{$hex};
	    if ($x%2) {
		$one .= "   $c";
	    } else {
		$two .= "   $c";
	    }
	}
	print $one . "\n";
	print $two . "\n";
    }
}

sub save {
    my $file = shift || "default.toy";
    my $json = JSON->new->allow_nonref;
    write_file($file, $json->encode( \@history ));
}

sub load {
    my $file = shift || "default.toy";
    my $json = JSON->new->allow_nonref;
    @history = @{ $json->decode( read_file($file) ) };
    map {
	say "> $_";
	execute($_);
	say "";
    } @history;
}

sub execute {
    my ($x, $record) = @_;
    push(@history, $x) if $record;
    my @args = split(/\s+/, $x);
    my $c = shift(@args);
    
    if ($commands{$c}) {
	$commands{$c}->(@args);
    }
}

if (-e "seeds.json") {
    my $json = JSON->new->allow_nonref;
    %seeds = %{ $json->decode( read_file('seeds.json') ) };
}

unless (-e "default.toy") {
    execute("l 8 10", 1);
    say "Welcome to the toy universe!";
    execute("j 0406", 1);
} else {
    load("default.toy");
}

while (1) {
    print "\n> ";
    my $x = <STDIN>;
    chomp($x);
    push(@history, $x) unless $x =~ /^save/i;
    execute($x);
}
