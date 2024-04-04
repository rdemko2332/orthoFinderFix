#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use Bio::SeqIO;
use Data::Dumper;

=pod

=head1 Description

Per organism, takes a file with sequence group assignments and the organism's proteome. All sequences with group assignments are sent to the peripheral fasta and all those without are sent to the residuals fasta.

=head1 Input Parameters

=over 4

=item groups

The group assignments file

=back

=over 4

=item seqFile

Organism proteome fasta

=back

=over 4

=item residuals

The residual fasta to write the residual sequences to

=back

=over 4

=item peripherals

The peripheral fasta to write the peripheral sequences to

=back

=cut

my ($groups,$seqFile,$residuals,$peripherals);

&GetOptions("groups=s"=> \$groups, # File contains sequence group mappings
	    "seqFile=s"=> \$seqFile, # Full proteome file
            "residuals=s"=> \$residuals, # File to hold residuals
            "peripherals=s"=> \$peripherals); # File to hold peripherals


my $proteome = Bio::SeqIO->new(-file => "$seqFile", -format => 'Fasta');

open(PERI,">$peripherals");
open(RESI,">$residuals");
open(my $group, '<', $groups);

my %seqsAndGroups;
# Make a hash object that contains sequence group mappings
while (my $line = <$group>) {
    chomp $line;
    my ($seq, $groupId) = split(/\t/, $line);
    $seqsAndGroups{$seq} = $groupId;
}

close $group;

# For each sequence in proteome file
while ( my $seq = $proteome->next_seq() ) {
    my $seqId = $seq->id();
    my $sequence = $seq->seq();
    # If the sequence has a group mapping, send it to the peripheral fasta
    if ($seqsAndGroups{$seqId}) {
        print PERI ">${seqId}\n${sequence}\n";
    }
    # If the sequence does not have a group mapping, send it to the residual fasta
    else {
        print RESI ">${seqId}\n${sequence}\n";	
    }
}

close PERI;
close RESI;
