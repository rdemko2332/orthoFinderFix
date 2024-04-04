#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Bio::SeqIO;

=pod

=head1 Description

Create a fasta file of best representatives.

=head1 Input Parameters

=over 4

=item bestReps

A tsv file indicating the group ID and the sequence ID of it's best representative

=back

=over 4

=item isResidual

A boolean indicating if these are residual or core groups (if residual, OG7_0000000 becomes OGR7_0000000)

=back

=over 4

=item outputFile

The path to the new bestReps fasta file

=back

=cut

my ($bestReps,$isResidual,$outputFile);

&GetOptions("bestReps=s"=> \$bestReps, # Tab seperated file with group and seqID
            "outputFile=s"=> \$outputFile,
            "isResidual"=> \$isResidual);

my $groupPrefix = "OG";

my $in  = Bio::SeqIO->new(-fh => \*STDIN,
                          -format => 'Fasta');

my $bestRepsFasta = Bio::SeqIO->new(-file => ">$outputFile" ,
                                   -format => 'Fasta');


open(MAP, '<', $bestReps) || die "Could not open file $bestReps: $!";

# Create hash to hold group and best rep id assignments
my %map;
while (my $line = <MAP>) {
    chomp $line;
    my ($group, $repseq) = split(/\t/, $line);
    $map{$repseq} = $group;
}
close MAP;

# For each input sequence, if it is a best rep, output it to the outputfile. The sequence is named by group
while ( my $seq = $in->next_seq() ) {
    my $seqId = $seq->id();
    my $group = $map{$seqId};
    die "No Group defined for Seq $seqId" unless($group);
    if ($isResidual) {
        $group =~ s/${groupPrefix}/${groupPrefix}R/;
    }
    $seq->id($group);
    $bestRepsFasta->write_seq($seq);
}

1;
