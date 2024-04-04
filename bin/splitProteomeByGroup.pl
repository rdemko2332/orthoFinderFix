#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Split a proteome into multiple group files using group assignments.

=head1 Input Parameters

=over 4

=item groups

The file containing sequence group assignments.

=back

=over 4

=item proteome

The proteome file you wish to split

=back

=cut

my ($groups,$proteome);

&GetOptions("groups=s"=> \$groups,
	    "proteome=s"=> \$proteome);

open(my $data, '<', $groups) || die "Could not open file $groups: $!";

while (my $line = <$data>) {
    chomp $line;

    if ($line =~ /^(\S+):\s(.+)/) {
	my $groupId = $1;
        my @seqs = split(/\s/, $2);

	open(OUT,">${groupId}.fasta")  || die "Could not open file ${groupId}.fasta: $!";
	open(TMP,">${groupId}.tmp")  || die "Could not open file ${groupId}.tmp: $!";

	foreach my $seq (@seqs) {
            print TMP "$seq\n";
	}
	close TMP;

	print OUT `samtools faidx $proteome -r ${groupId}.tmp`;
	close OUT;
	
    }

    else {
	die "Improper format of groups file $groups";
    }

}	
