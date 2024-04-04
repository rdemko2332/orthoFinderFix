#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

my ($coreGroup,$peripheralGroup,$output);

&GetOptions("coreGroup=s"=> \$coreGroup,
	    "peripheralGroup=s"=> \$peripheralGroup,
            "output=s"=> \$output);

open(my $core, '<', $coreGroup) || die "Could not open file $coreGroup: $!";
open(my $peripheral, '<', $peripheralGroup) || die "Could not open file $peripheralGroup: $!";
open(OUT,">$output");

while (my $line = <$core>) {
    chomp $line;
    if ($line =~ /^Orthogroup/) {
	next;
    }
    elsif ($line =~ /^(OG\S+)\t(.+)/) {
	my $groupId = $1;
	my $groupSeqs = $2;
	$groupSeqs =~ s/\t/ /g;
	$groupSeqs =~ s/,//g;
	my @sequences = split(/\s/, $groupSeqs);
	`grep "${groupId}" $peripheralGroup > ${groupId}.txt`;
	open(my $idFile, "<${groupId}.txt") || die "Could not open file ${groupId}.txt: $!";
	while (my $idLine = <$idFile>) {
	    chomp $idLine;
	    if ($idLine =~ /^(\S+)\t(\S+)/) {
		my $peripheralSeq = $1;
	        push(@sequences,$peripheralSeq);
	    }
	    else {
		die "Improper peripheralFile format\n";
	    }	
        }
	my $sequenceString = join(' ', @sequences);
        print OUT "$groupId: $sequenceString\n";
	`rm ${groupId}.txt`;
    }
    else {
	die "Improper groupFile format\n";
    }   
}	
