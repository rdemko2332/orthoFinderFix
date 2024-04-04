#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($sequenceMapping,$missingGroups,$groupMapping);

&GetOptions("sequenceMapping=s"=> \$sequenceMapping,
            "groupMapping=s"=> \$groupMapping,
            "missingGroups=s"=> \$missingGroups);

my %sequenceMap = &makeSequenceMappingHash($sequenceMapping);

open(my $missing, '<', $missingGroups) || die "Could not open file $missingGroups: $!";
while (my $line = <$missing>) {
    chomp $line;
    my $missingGroup = $line;
    $line =~ s/OG\d+_/N0\.HOG/g;
    my $groupLine = `grep "$line" $groupMapping`;
    if ($groupLine =~ /^N0\.HOG\d+\tOG\d+\tn\d+\t(.*)/ || $groupLine =~ /^N0\.HOG\d+\tOG\d+\t-\t(.*)/) {
        my $groupSequences = $1;
        $groupSequences =~ s/ //g;
        $groupSequences =~ s/,/ /g;
        $groupSequences =~ s/\t+/ /g;
        my @missingSequences = split(/\s/, $groupSequences);
	@missingSequences = grep { $_ ne '' } @missingSequences;
        my $bestRepSequence = $sequenceMap{$missingSequences[0]};
	print "$missingGroup\t$bestRepSequence\n";
    }
    else {
        die "Improper group file format for line $line\n";
    }
}
close $missing;

sub makeSequenceMappingHash {
    my ($sequenceMapFile) = @_;
    my %sequenceMapping;
    open(my $map, '<', $sequenceMapFile) || die "Could not open file $sequenceMapFile: $!";
    while (my $line = <$map>) {
        chomp $line;
        my ($mapping, $sequence) = split(/:\s/, $line);
        my @sequenceArray = split(/\s/, $sequence);
        $sequenceMapping{$sequenceArray[0]} = $mapping;
    }
    close $map;
    return %sequenceMapping;
}
