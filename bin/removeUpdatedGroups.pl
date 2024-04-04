#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($missingGroups,$groups,$output);

&GetOptions("groups=s"=> \$groups,
            "missingGroups=s"=> \$missingGroups,
            "output=s"=>\$output);

open(OUT, '>', $output) || die "Could not open file $output: $!";
open(my $missing, '<', $missingGroups) || die "Could not open file $missingGroups: $!";
open(my $groupData, '<', $groups) || die "Could not open file $groups: $!";

my @missingGroupArray;

while (my $line = <$missing>) {
    chomp $line;
    push(@missingGroupArray,$line);
}
close $missing;

while (my $line = <$groupData>) {
    chomp $line;
    if ($line =~ /^(OG\d+_\d+):\s(.+)/) {
	my $group = $1;
	my $sequenceLine = $2;
	if (grep( /^$group$/, @missingGroupArray )) {
            my @groupSequences = split(/\s/, $sequenceLine);
	    my $groupSize = scalar(@groupSequences);
	    if ($groupSize == 1) {
		print OUT "$line\n";
	    }
	}
	else {
	    print OUT "$line\n";
	}
    }
    else {
	die "Improper group file format";
    }	    
}

close $groupData;
close OUT;
