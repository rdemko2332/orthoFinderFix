#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Split best reps fasta file into multiple files. Each file is named by their group and contains the sequence of the best representative

=head1 Input Parameters

=over 4

=item bestRepsFasta

Fasta file of core group best reps

=back

=over 4

=item outputDir

Output directory of fasta files 

=back

=cut

my ($bestRepsFasta,$outputDir);

&GetOptions("bestRepsFasta=s"=> \$bestRepsFasta,
	    "outputDir=s"=> \$outputDir);

open(my $reps, '<', $bestRepsFasta) || die "Could not open file $bestRepsFasta: $!";

my $currentGroupId;
while (my $line = <$reps>) {
    chomp $line;

    if ($line =~ /^>(.*)/) {
	my $groupId = $1;
	
	close OUT if ($currentGroupId);
	open(OUT,">$outputDir/${groupId}.fasta")  || die "Could not open file ${outputDir}/${groupId}.fasta: $!";
	print OUT "$line\n";
	$currentGroupId eq $groupId;
	
    }
    else {
        print OUT "$line\n";
    }
}	
close OUT;
close $reps;
