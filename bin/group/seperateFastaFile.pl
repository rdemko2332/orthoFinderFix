#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($input,$outputDir, $fastaSubsetSize);

&GetOptions("input=s"=> \$input,
            "outputDir=s"=> \$outputDir,
            "fastaSubsetSize=i"=> \$fastaSubsetSize);

open(my $data, '<', $input) || die "Could not open file $input: $!";

my $counter = 0;
my $fileCounter = 0;
open(OUT,">$outputDir/fasta$fileCounter.fa");
while (my $line = <$data>) {
    if ($line =~ m/^>/ && $counter == 0) {
	print OUT $line;
	$counter+=1;
    }
    elsif ($line =~ m/^>/ && $counter != 0 && $counter % $fastaSubsetSize == 0) {
	close OUT;
	$counter+=1;
	$fileCounter+=1;
	open(OUT,">$outputDir/fasta$fileCounter.fa");
	print OUT $line;
    }
    elsif ($line =~ m/^>/ && $counter != 0 && $counter % $fastaSubsetSize != 0) {
	$counter+=1;
	print OUT $line;
    }
    else {
 	print OUT $line;
    }   
}	
