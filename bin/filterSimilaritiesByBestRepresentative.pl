#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Filter group similarity files by only storing pairwise results that involve sequences being blasted against the best representative of the group to which they w

=head1 Input Parameters

=over 4

=item bestReps 

Tsv file containing a group ID and the sequence that best represents it

=item singletons Tsv file containing a group ID and the singleton sequence that represents it (and is the only sequence contained in it)

=back 

=cut

my ($bestReps, $singletons,$missingGroups);

&GetOptions("bestReps=s"=> \$bestReps,
            "singletons=s"=> \$singletons,
            "missingGroups=s"=> \$missingGroups);

# Open file that contains ids of best reps and their group
open(my $data, '<', $bestReps) || die "Could not open file $bestReps: $!";
# Open singleton file so we can identify singletons
open(my $single, '<', $singletons) || die "Could not open file $singletons: $!";
open(my $missing, '<', $missingGroups) || die "Could not open file $missingGroups: $!";

# Make array to hold all missing groups
my @missingGroups;
while (my $line = <$missing>) {
    chomp $line;
    push(@missingGroups,$line);
}

# Make array to hold all groups that are singletons
my @singletonGroups;
while (my $line = <$single>) {
    chomp $line;
    my ($group, $seqID) = split(/\t/, $line);
    push(@singletonGroups,$group);
}

# For each line in best representative file
while (my $line = <$data>) {
    chomp $line;
    # Get the group and sequence id
    my ($group, $seqID) = split(/\t/, $line);
    # If the group is a singleton, we just make an empty file, as this group does not have any non self blast results to the best rep

    open(OUT, ">${group}_bestRep.tsv") or die "Cannot open file ${group}_bestRep.tsv for writing:$!";
    if ( grep( /^$group/, @singletonGroups ) ||  grep( /^$group/, @missingGroups ) ) {
        close OUT
    }
    # If the group is not a singleton or missing, go get all pairwise blast results that involve the best representative and output it to a groups file
    else {
        # we want only where the seqId is in the 2nd column to avoid dups
        open(IN, "< ${group}.sim") or die "cannot open file ${group}.sim for reading: $!";
        while(<IN>) {
            if(/\t${seqID}\t/) {
                print OUT $_;
            }
        }

        close IN;
        close OUT;
    }
}

close $data;
