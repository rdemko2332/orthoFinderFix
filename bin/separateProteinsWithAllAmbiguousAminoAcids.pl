#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Bio::SeqIO;

=pod

=head1 Description

Take a fasta file and separate it into a fasta file with ambigious sequences and a fasta file with unambiguous sequences. This is done by seeing if the sequence contains any of a certain set of characters. This is needed because orthofinder will fail if isn't a sequence with unambiguous characters in the first 10 sequences. I.E. it complains that it can't tell if this is a proteome or not.

=head1 Input Parameters

=over 4

=item input

The input fasta file

=back

=over 4

=item ambiguous

The output file to write ambiguous sequences

=back

=over 4

=item unambiguous

The output file to write unambiguous sequences

=back

=cut

my ($input,$ambiguousOutput, $unambiguousOutput);


&GetOptions("input=s"=> \$input,
            "ambiguous=s"=> \$ambiguousOutput,
            "unambiguous=s"=> \$unambiguousOutput
           );


# Creation of SeqIO object for organism fasta
my $in  = Bio::SeqIO->new(-file => $input ,
                         -format => 'Fasta');

# Prepare unambigous and ambigous output fasta files
my $unambiguous = Bio::SeqIO->new(-file => ">$unambiguousOutput" ,
                                   -format => 'Fasta');

my $ambiguous = Bio::SeqIO->new(-file => ">$ambiguousOutput" ,
                                -format => 'Fasta');

# For each sequence in input fasta
while ( my $seq = $in->next_seq() ) {
    # If sequence contains specified letters, write to unambiguous file
    if($seq->seq() =~  /[EFILPQ]/) {
        $unambiguous->write_seq($seq);
    }
    # Else write to ambigous file
    else {
        $ambiguous->write_seq($seq);
    }
}

=head4 
The ambigous file is concatenated to the end of the unambigous file, ensuring that we have the full fasta and that an unambigous sequence is in the first 10 sequences.
=cut

1;
