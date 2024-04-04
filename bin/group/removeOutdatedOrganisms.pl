#!/usr/bin/perl

use strict;
use warnings;

# Input species ID file
my $outdatedFile = $ARGV[0];
my $oldProteome = $ARGV[1];
my $cleanedProteome = $ARGV[2];

# Open Outdated file
open my $fh_outdated, '<', $outdatedFile or die "Cannot open $outdatedFile: $!";
open(OUT,">$cleanedProteome");
my @outdated;
while (my $line = <$fh_outdated>) {
    chomp $line;
    if ($line =~ /^(.+)/) {
        my ($outdatedSpecies) = ($1);
        push(@outdated, $outdatedSpecies);
    }
}
close $fh_outdated;

open my $fh_old, '<', $oldProteome or die "Cannot open $oldProteome: $!";
my $skipSeqs = 0;
while (my $line = <$fh_old>) {
    chomp $line;
    if ($line =~ /^>(\S+)\s.+/) {
	$skipSeqs = 0;
        my $headerLine = ($1);
	$headerLine =~ s/\|\S+//g;	
	if ( grep( /^$headerLine/, @outdated ) ) {
            $skipSeqs = 1;
        }
        else {
	    print OUT "$line\n";
	}
    }
    elsif ($skipSeqs == 0) {
	print OUT "$line\n";
    }
}
close $fh_old;
close OUT;
