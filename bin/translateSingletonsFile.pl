#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Takes a file containing singleton sequences and their group assignments and a file with the internal orthofinder sequence mappings. Used the sequence mappings to translate the sequences in the singletons file to their real sequence name.

=head1 Input Parameters

=over 4

=item singletons

The singletons file

=back

=over 4

=item sequenceMapping

The file containing the orthofinder internal sequence mappings

=back

=cut

my ($singletons,$sequenceMapping);

&GetOptions("singletons=s"=> \$singletons,
            "sequenceMapping=s"=> \$sequenceMapping);

my %group_mapping = &makeGroupMappingHash($singletons);

my %mapping_sequence = &makeMappingSequenceHash($sequenceMapping);


open(OUT, '>translated.out') || die "Could not open file translated.out: $!";

foreach my $key (keys %group_mapping) {
    my $mapping = $group_mapping{$key};
    my $sequence = $mapping_sequence{$mapping};
    print OUT "$key: $sequence\n";
}

close OUT;

# ========================== Subroutines =================================

=pod

=head1 Subroutines

=over 4

=item makeGroupMappingHash()

This process take the singletons file and creates a hash object that contains value mapping pairs of the singletons and their group assignments.

=back

=cut

sub makeGroupMappingHash {
    my ($singletons) = @_;
    my %group_mapping;
    open(my $data, '<', $singletons) || die "Could not open file $singletons: $!";
    while (my $line = <$data>) {
        chomp $line;
        my ($group, $mapping) = split(/\t/, $line);
        $group_mapping{$group} = $mapping;
    }
    close $data;
    return %group_mapping;
}

=pod

=over 4

=item makeGroupMappingHash()

This process take the internal sequence file and creates a hash object that contains value mapping pairs of the internal and true sequence name.

=back

=cut

sub makeMappingSequenceHash {
    my ($sequenceMapFile) = @_;
    my $mapping_sequence;
    open(my $map, '<', $sequenceMapFile) || die "Could not open file $sequenceMapFile: $!";
    while (my $line = <$map>) {
        chomp $line;
        my ($mapping, $sequence) = split(/:\s/, $line);
        my @sequenceArray = split(/\s/, $sequence);
        $mapping_sequence{$mapping} = $sequenceArray[0];
    }
    close $map;
    return %mapping_sequence;
}
