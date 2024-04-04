#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Reformat the N0.tsv file produce by orthofinder. The singletons file is concatenated to the end of this file, as that has already been formatted. The current file contains one line per group. Sequences within a group are comma delimited, with these sets being tab delimited by organism.

=head1 Input Parameters

=over 4

=item groupFile

The N0.tsv file

=back

=over 4

=item buildVersion

An integer indicating the build version of orthomcl

=back

=cut

my ($groupFile,$buildVersion);

&GetOptions("groupFile=s"=> \$groupFile,
            "buildVersion=i"=> \$buildVersion);

open(my $data, '<', $groupFile) || die "Could not open file $groupFile: $!";
open(OUT, '>reformattedGroups.txt') || die "Could not open file reformattedGroups.txt: $!";

my $numberOfOrganisms;

# For each line in groups file
while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^HOG/) {
	# Get the values
        my @headerArray = split(/\t/, $line);
	# Calculate the number of columns
	my $numberOfColumns = scalar @headerArray;
	# Derive the number of organisms that have sequences in this group
	$numberOfOrganisms = $numberOfColumns - 3;
    }
    else {
	$line =~ s/,//g;
	# Retrieve sets of sequences by organism
	my @valuesArray = split(/\t/, $line);
	my @allSequences;
	# For each organism on this line
	foreach my $i (1..$numberOfOrganisms) {
	    # Skip first 3 columns as they are unneeded
	    my $index = 2 + $i;
	    if ($valuesArray[$index]) {
		# Push the organism sequences to the allSequences object
                push(@allSequences,$valuesArray[$index]);
	    }
	}
	# Get the group id
	my $group = $valuesArray[0];
	print "Group is $group\n";
	$group =~ s/N0.H//g;
	print "Reformat group is $group\n";
	# Add in build version and formatting
        $group =~ s/OG/OG${buildVersion}_/;
	# Print out data in new format
        print OUT "$group: @allSequences\n";
    }
}

close $data;
close OUT
