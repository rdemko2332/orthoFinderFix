#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Takes a set of blast results between two organisms and the group assignments for the sequences of those two organisms. The blast results are filtered by only retainging results where the query and subject sequence are in the same group. The output from this script is sent to splitBlastsIntoGroupFiles. This script splits the output from this process by group. This process will be parallelized and the outputs of this process will by joined with other runs. We will end up with all of the blast data being split by group.

=head1 Input Parameters

=over 4

=item diamondFile

The pairwise results file.

=back

=over 4

=item species0File

File containing sequence group assignments for the query organism

=back

=over 4

=item species1File

File containing sequence group assignments for the subject organism

=back

=over 4

=item outputFile

The path to where the filtered data will be written

=back

=cut

my ($species0File, $species1File, $diamondFile, $outputFile);

&GetOptions("diamondFile=s" => \$diamondFile,
            "species0File=s" => \$species0File,
            "species1File=s" => \$species1File,
            "outputFile=s" => \$outputFile,
           );

my %species0Orthologs = &makeOrthologsFromFile($species0File);
my %species1Orthologs = &makeOrthologsFromFile($species1File);

open(BLAST, $diamondFile) or die "Cannot open file $diamondFile for reading: $!";
open(OUT, ">$outputFile") or die "Cannot open $outputFile for writing: $!";

while(<BLAST>) {
    chomp;

    # Split pairwise blast results
    my @a = split(/\t/, $_);

    # filter out self-self
    next if($a[0] eq $a[1]);

    # If sequences are in the same group
    if($species0Orthologs{$a[0]} && $species1Orthologs{$a[1]}) {
	if ($species0Orthologs{$a[0]} eq $species1Orthologs{$a[1]}) {
            unshift @a, $species0Orthologs{$a[0]};
            print OUT join("\t", @a) . "\n";
        }
    }
}

close BLAST;
close OUT;

# ===================== Subroutines ===================================

=pod

=head1 Subroutines

=over 4

=item makeOrthologsFromFile()

Returns a hash item with value mapping pairs of sequences to their group assignments

=back

=cut

sub makeOrthologsFromFile {
    my ($speciesFile) = @_;
    my %speciesOrthologs;
    open(SPF, $speciesFile) or die "Cannot open file $speciesFile for reading: $!";
    while(<SPF>) {
        chomp;
        my ($og, $seq) = split(/\t/, $_);
        $speciesOrthologs{$seq} = $og;
    }
    close SPF;
    return %speciesOrthologs;
}
