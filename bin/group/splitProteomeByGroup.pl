#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($groups,$proteome);

&GetOptions("groups=s"=> \$groups,
	    "proteome=s"=> \$proteome);

open(my $data, '<', $groups) || die "Could not open file $groups: $!";

while (my $line = <$data>) {
    chomp $line;
    if ($line =~ /^(\S+):\s(.+)/) {
	my $groupId = $1;
        my @seqs = split(/\s/, $2);
        `touch ${groupId}.temp`;
        `touch ${groupId}.fasta`;
	open(TEMP,">${groupId}.temp");
	foreach my $seq (@seqs) {
	    print TEMP "$seq\n";
	}
	`seqtk subseq ${proteome} ${groupId}.temp > ${groupId}.fasta`;
	close TEMP;
	`rm ${groupId}.temp`
    }
    else {
	die "Improper format of groups file $groups";
    }
}	
