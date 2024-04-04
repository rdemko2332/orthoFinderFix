#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Bio::SeqIO;

=pod

=head1 Description

Translate the best rep file to have real sequence ids not orthofinder internal ids

=head1 Input Parameters

=over 4

=item bestReps

A tsv file indicating the group ID and the internal sequence ID of it's best representative

=back

=over 4

=item sequenceIds

Orthofinder file contain internal and actual sequence id mapping

=back

=over 4

=item isResidual

A boolean indicating if these are residual or core groups (if residual, OG7_0000000 becomes OGR7_0000000)

=back

=over 4

=item outputFile

The path to the new translated bestReps file

=back

=cut

my ($bestReps,$sequenceIds,$isResidual,$outputFile);

&GetOptions("bestReps=s"=> \$bestReps, # Tab seperated file with group and seqID
	    "sequenceIds=s"=> \$sequenceIds,
            "outputFile=s"=> \$outputFile,
            "isResidual"=> \$isResidual);

my $groupPrefix = "OG";

open(MAP, '<', $bestReps) || die "Could not open file $bestReps: $!";

# Create hash to hold group and best rep id assignments
my %bestRepsMap;
while (my $line = <MAP>) {
    chomp $line;
    my ($group, $repseq) = split(/\t/, $line);
    $bestRepsMap{$group} = $repseq;
}
close MAP;

open(SEQ, '<', $sequenceIds) || die "Could not open file $sequenceIds: $!";

my %sequenceIdsMap;
while (my $line = <SEQ>) {
    chomp $line;
    if ($line =~ /^(\d+_\d+):\s(\S+\|\S+).+/) {
	my $internal = $1;
	my $actual = $2;
        $sequenceIdsMap{$internal} = $actual;
    }
    else {
        die "Improper sequence id file format: $!";
    }
}
close SEQ;

open(OUT, '>', $outputFile) || die "Could not open file $outputFile: $!";
# For each group best rep pair, translate the internalId
foreach my $group (keys(%bestRepsMap)) {
    my $internalId = $bestRepsMap{$group};
    my $actualId = $sequenceIdsMap{$internalId};
    if ($isResidual) {
        $group =~ s/OG/OGR/g;    
    }
    print OUT "$group\t$actualId\n";
}
close OUT;
		   
1;
