#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Receive a fasta file and split into into separate organism fastas. Needed for orthofinder.

=head1 Input Parameters

=over 4

=item input

The fasta file to be split

=back

=over 4

=item outputDir

The directory to write the output files

=back

=cut

my ($input,$outputDir);

&GetOptions("input=s"=> \$input,
            "outputDir=s"=> \$outputDir);

open(my $data, '<', $input) || die "Could not open file $input: $!";

my $counter = 0;
my $organism;

# Foreach line in peripheral fasta
while (my $line = <$data>) {
    # If it is a def line
    if ($line =~ /^>(\w{4})\|/ || $line =~ /^>(\w{4}-old)\|/) {
	# Retrieve current organism
	my $currentOrganism = $1;
	# If first organism in file
	if ($counter == 0) {
	    $counter +=1;
	    $organism = $currentOrganism;
	    # Open the organism output file
            open(OUT,">$outputDir/${organism}.fasta");
	    print OUT $line;
        }
	# While the same organism, print out to same file
        elsif ($organism eq $currentOrganism) {
	    print OUT $line;
	}
	# Different organism, reset the organism and print out to new organism file
	else {
	    $organism = $currentOrganism;
            close OUT;
	    open(OUT,">$outputDir/${organism}.fasta");
	    print OUT $line;
	}
    }
    # Is a sequence, always follows defline so just print to current output
    else {
 	print OUT $line;
    }   
}	
