#!/usr/bin/perl

use strict;
use warnings;

=pod

=head1 Description

Remove all values from the defline of an input fasta besides the sequence id. For example >ccin-old|example gene=example product=example would become >ccin-old|example. Needed for downstream create gene trees steps

=head1 Input Parameters

=over 4

=item fullProteome

Input fasta file

=back

=over 4

=item newProteome

Output fasta file

=back

=cut

# Input species ID file
my $fullProteome = $ARGV[0];
my $newProteome = $ARGV[1];

open my $fh_full, '<', $fullProteome or die "Cannot open $fullProteome: $!";
open(OUT,">$newProteome");
my $headerCount = 0;
# For each line in the fasta
while (my $line = <$fh_full>) {
    chomp $line;
    # If a defline, retrieve the sequence ID only and print
    if ($line =~ /^(>\S+)\s.+/) {
	$headerCount += 1;
        my $headerLine = ($1);
        print OUT "$headerLine\n";
    }
    # Else if sequence from last sequence, print
    else {
	print OUT "$line\n";
    }
}
close $fh_full;
close OUT;

if ($headerCount < 2) {
    `rm $newProteome`;
    print "$newProteome only contains a single sequence\n";
}
