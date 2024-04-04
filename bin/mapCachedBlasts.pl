#!/usr/bin/perl

use strict;
use Getopt::Long;
use File::Basename;
use Data::Dumper;

=pod

=head1 Description

Create a new cached directory of blast results from the last core run. All file names are moved from their old organism orthofinder internal id to their new. Additionally, all organisms whose proteome have changed (are in outdated.txt) are removed.

=head1 Input Parameters

=over 4

=item outdated

The file holding organism abbrevs of outdated organisms

=back

=over 4

=item cachedSpeciesMapping

The orthofinder species mapping file from the last run.

=back

=over 4

=item cachedSequenceMapping

The cached sequence mapping file from the last run.

=back

=over 4

=item newSpeciesMapping

The new species mapping file from orthofinder.

=back

=over 4

=item newSequenceMapping

The new sequence mapping file from orthofinder.

=back

=over 4

=item diamondCacheDir

The path to where the blasts from the last run are stored

=back

=over 4

=item outputDir

The directory where the mapped and filtered blast files will be placed.

=back

=cut

my ($outdated, $cachedSpeciesMapping, $cachedSequenceMapping, $newSpeciesMapping, $newSequenceMapping, $outputDir, $diamondCacheDir);

&GetOptions("outdated=s"=> \$outdated, # File indicating outdated/new species, one species per line
            "cachedSpeciesMapping=s" => \$cachedSpeciesMapping, # Species mapping file of the cache
            "cachedSequenceMapping=s" => \$cachedSequenceMapping, # Sequence mapping file of the cache
            "newSpeciesMapping=s" => \$newSpeciesMapping, # Species mapping file from the current run (from orthofinder setup)
            "newSequenceMapping=s" => \$newSequenceMapping, # Sequence mapping file from the current run (from orthofinder setup)
            "diamondCacheDir=s" => \$diamondCacheDir, # Directory contains pairwise blast results from the last run
            "outputDir=s" => \$outputDir # New cache directory
           );

open(FILE, $outdated) or die "cannot open file $outdated for reading: $!";

unless(-e $cachedSpeciesMapping && -e $cachedSequenceMapping) {
    print STDERR "NO CACHE Mapping found.  Processing all pairs\n";
    exit;
}

# Creating a hash of outdated species
my %outdated;
while(<FILE>) {
    chomp;
    my $organism = $_;
    $outdated{"${organism}.fasta"} = 1;
}
close FILE;

# Creating a hash object to hold the new species mapping information
my %newSpecies;
open(NEW, $newSpeciesMapping) or die "cannot open file $newSpeciesMapping for reading: $!";
while(<NEW>) {
    chomp;
    my ($organismId, $organismName) = split(/: /, $_);
    $newSpecies{$organismName} = $organismId;
}
close NEW;

# Creating a hash object to hold the cached species mapping information
open(CACHE, $cachedSpeciesMapping) or die "cannot open file $cachedSpeciesMapping for reading: $!";
my %speciesMap;
while(<CACHE>) {
    chomp;
    my ($organismId, $organismName) = split(/: /, $_);

    # don't read from cache if outdated
    if($outdated{$organismName}) {
        print STDERR "WARN:  SKIP Organism $organismName defined in Outdated File\n";
        $speciesMap{$organismId} = "outdated";
        next ;
    }


    # Use the organism name from the cache species mapping and the new species hash to get the new organism id
    my $newOrganismId = $newSpecies{$organismName};
    # If the organism has been removed, skip
    unless(defined $newOrganismId) {
        print STDERR "WARN:  SKIP Organism $organismName as it no longer exists in this run of orthofinder\n";
        $speciesMap{$organismId} = "NA";
        next;
    }

    # Step to make sure the organism sequence ids are indeed identical to last run. Should always be true if the organism wasn't identified as outdated in the outdated file
    if(&organismIsOutdated($organismId, $newOrganismId, $cachedSequenceMapping, $newSequenceMapping)) {
        print STDERR "WARN:  Unexpected skipping of organism $organismName\n";
    }

    # if we made it here, we can do the species mapping. Object holds new species mapping
    $speciesMap{$organismId} = $newOrganismId;
}
close CACHE;

# Get array of cache blast files
my @cachedBlastFiles = glob "$diamondCacheDir/Blast*.txt";

foreach my $cachedBlastFile (@cachedBlastFiles) {

    my $cachedBlastFileBasename = basename $cachedBlastFile;

    # Example: Blast1_0.txt We will be changing the numbers to their new mapping
    my ($org1, $org2) = $cachedBlastFileBasename =~ /Blast(\d+)_(\d+)\.txt/;

    # Get new species mapping
    my $newOrg1 = $speciesMap{$org1};
    my $newOrg2 = $speciesMap{$org2};
    
    # If we have mapping data for these organisms
    if(defined $newOrg1 && defined $newOrg2 && $newOrg1 ne "NA" && $newOrg1 ne "outdated" && $newOrg2 ne "NA" && $newOrg2 ne "outdated") {

        print STDERR "Mapping needed data for new org id $newOrg1 and $newOrg2\n";
	
	# Replace old species ids with new species ids
        my $newBlastFileBasename = "Blast${newOrg1}_${newOrg2}.txt";
        open(BLASTIN, $cachedBlastFile) or die "Cannot open file $cachedBlastFile for reading: $!";
        open(BLASTOUT, ">$outputDir/$newBlastFileBasename") or die "Cannot open file $outputDir/$newBlastFileBasename for writing: $!";

        while(<BLASTIN>) {
            chomp;
            my @line = split(/\t/, $_);

            # this will replace the species part of the id with the mapped id
            $line[0] =~ s/^(\d+)/$speciesMap{$1}/;
            $line[1] =~ s/^(\d+)/$speciesMap{$1}/;

	    # Print out pairwise results with translated mapping
            print BLASTOUT join("\t", @line) . "\n";
        }

        close BLASTIN;
        close BLASTOUT;
    }
    elsif($newOrg1 eq "outdated" || $newOrg2 eq "outdated") {
	print STDERR "WARN:  No Need To Map Outdated Organism\n";
    }
    elsif($newOrg1 eq "NA" || $newOrg2 eq "NA") {
	print STDERR "WARN:  No Need To Map Unused Data\n";
    }
    else {
        die "Could not find species mapping for $org1 or $org2";
    }
}

=pod

=head1 Subroutines

=over 4

=item organismIsOutdated()

The process is a check to insure that the sequence ids from the last run and the current run for an organism (not labeled as outdated) are indeed the same.

=back

=cut

sub organismIsOutdated {
    my ($cachedOrganismId, $newOrganismId, $cachedSequenceMapping, $newSequenceMapping) = @_;

    # Example 1_0: Original Sequence Defline

    # Retrieve the sequence ids from the cache, and the new sequence ids.
    my $cachedSeqIds = `grep ${cachedOrganismId}_ ${cachedSequenceMapping} |cut -f 2 -d ' '`;
    my $newSeqIds = `grep ${newOrganismId}_ ${newSequenceMapping} |cut -f 2 -d ' '`;

    # These should always be identical if the organism wasn't identified as outdated in the outdated organisms file
    if($cachedSeqIds eq $newSeqIds) {
        return 0;
    }

    return 1;
}

1;
