#!/usr/bin/perl

use strict;
use warnings;

# Input species ID file
my $outdatedFile = $ARGV[0];
my $oldBlastResults = $ARGV[1];

# Open Outdated file
open my $fh_outdated, '<', $outdatedFile or die "Cannot open $outdatedFile: $!";
my @outdated;
while (my $line = <$fh_outdated>) {
    chomp $line;
    if ($line =~ /^(.+)/) {
        my ($outdatedSpecies) = ($1);
        push(@outdated, $outdatedSpecies);
    }
}
close $fh_outdated;

open my $fh_oldResults, '<', $oldBlastResults or die "Cannot open $oldBlastResults: $!";
open(OUT,">${oldBlastResults}.temp");
while (my $line = <$fh_oldResults>) {
    chomp $line;
    my ($qseqid,$qlen,$sseqid,$slen,$qstart,$qend,$sstart,$send,$evalue,$bitscore,$length,$nident,$pident,$positive,$qframe,$qstrand,$gaps,$qcovhsp,$scovhsp,$qseq) = split(/\t/, $line);
    $qseqid =~ s/\|\S+//g;	
    if (grep( /^$qseqid/, @outdated)) {
        next;
    }
    else {
        print OUT $line;
    }
}
system("rm ${oldBlastResults}");
system("mv ${oldBlastResults}.temp ${oldBlastResults}");
