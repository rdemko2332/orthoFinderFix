#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Take a input file of pairwise similarity results of an organism proteome to the core best reps database, the groups file indicating to which groups these sequences were assigned, and a bestReps file that holds the sequenceID of the best representative for each group. Separate this file into a similarity file per group, only containing results between sequences assigned to that group and the groups best representative.

=head1 Input Parameters

=over 4

=item similarity

The organism specific specific pairwise results file

=back

=over 4

=item groups

A file containing the list of peripheral sequences and their group assignments

=back

=over 4

=item bestReps

A file containing the list of groups and their best representative

=back

=cut

my ($similarity,$bestReps,$groups);

&GetOptions("similarity=s"=> \$similarity, # Sorted diamond similarity results
            "bestReps=s"=> \$bestReps,
            "groups=s"=> \$groups); # Sorted group assignments

open(my $group, '<', $groups) || die "Could not open file $groups: $!";
open(my $sim, '<', $similarity) || die "Could not open file $similarity: $!";
open(my $reps, '<', $bestReps) || die "Could not open file $bestReps: $!";

# Make hash to store sequence group assignments
my %seqToGroup;

# For each line in groups file
while (my $line = <$group>) {
    chomp $line;
    my ($seq,$groupId) = split(/\t/, $line);
    # Record the group assignment for each sequence
    $seqToGroup{$seq} = $groupId;
}
close $group;

# Make hash to store group to best rep assignments
my %groupToRep;

# For each line in groups file
while (my $line = <$reps>) {
    chomp $line;
    my ($groupId,$rep) = split(/\t/, $line);
    # Record the group assignment for each sequence
    $groupToRep{$groupId} = $rep;
}
close $reps;

my $currentGroupId = "";
while (my $line = <$sim>) {
    chomp $line;
    my $groupId;
    my ($qseq,$sseq, @rest) = split(/\t/, $line);

    my $testGroup = $seqToGroup{$qseq};
    my $testRep = $groupToRep{$testGroup};

    #print "$sseq\t$testRep\n";

    if ($sseq eq $testRep) {
	print "DING\n";
    }
    
    # Skip result unless shared between sequence and the best representative of it's group assignment
    next unless($groupToRep{$seqToGroup{$qseq}} eq $sseq);

    $groupId = $seqToGroup{$qseq};
    
    # If same group that's currently opened, output.
    if ($groupId eq $currentGroupId) {
        print OUT "$line\n";
        next;
    }

    # Else, close current output file. Open new group file and output
    close OUT if($currentGroupId);
    $currentGroupId = $groupId;
    open(OUT, ">${groupId}_bestRep.tsv") || die "Could not open file ${groupId}_bestRep.tsv: $!";
    print OUT "$line\n";
}

close $sim;
close OUT;
