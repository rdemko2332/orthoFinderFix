#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;
use List::Util qw/sum/;

my ($groupsFile,$output);

&GetOptions("groupsFile=s"=> \$groupsFile,
    	    "output=s"=> \$output);

open(my $groups, '<', $groupsFile) || die "Could not open file $groupsFile: $!";
open(OUT,">>$output");

while (my $line = <$groups>) {
    chomp $line;
    if ($line =~ /^Orthogroup/) {
	next;
    }
    elsif ($line =~ /^(OG\d+):\s(.+)/) {
	my $groupId = $1;
	my $groupSeqs = $2;
	my @sequences = split(/\s/, $groupSeqs);
	my $similarityPairCount = 0;
	my @evalueArray = ();
        my @pidentArray = ();
	my @matchPercentArray = ();
	open(my $results, "<${groupId}.fasta.out") || die "Could not open file ${groupId}.fasta.out: $!";
	while (my $resultLine = <$results>) {
	    chomp $resultLine;
	    my ($qseqid,$qlen,$sseqid,$slen,$qstart,$qend,$sstart,$send,$evalue,$bitscore,$length,$nident,$pident,$positive,$qframe,$qstrand,$gaps,$qcovhsp,$scovhsp,$qseq) = split(/\t/, $resultLine);
	    next if ($qseqid eq $sseqid);
	    $similarityPairCount += 1;
	    push(@evalueArray,$evalue);
    	    push(@pidentArray,$pident);
	    ($qcovhsp >= $scovhsp) ? push(@matchPercentArray,$scovhsp) : push(@matchPercentArray,$qcovhsp);
        }
	close $results;
        my $numberOfProteins = scalar @sequences;
        my $maxPossiblePairsWithSimilarity = ($numberOfProteins - 1) * $numberOfProteins;
	if ($similarityPairCount > 0) {
	    my $percentPairsWithSimilarity = $similarityPairCount / $maxPossiblePairsWithSimilarity;
	    my $avgEValue = sum(@evalueArray) / $similarityPairCount;
	    my $avgPIdent = sum(@pidentArray) / $similarityPairCount;
	    my $avgMatchPercent = sum(@matchPercentArray) / $similarityPairCount;
	    print OUT "$groupId\t$numberOfProteins\t$avgMatchPercent\t$avgPIdent\t$similarityPairCount\t$maxPossiblePairsWithSimilarity\t$percentPairsWithSimilarity\t$avgEValue\n";
	}
	else {
	    print OUT "$groupId\t$numberOfProteins\tNA\tNA\t0\t$maxPossiblePairsWithSimilarity\t0\tNA\n";
	}
        
    }
    else {
	die "Improper groupFile format\n";
    }   
}	
close OUT;
close $groups;
