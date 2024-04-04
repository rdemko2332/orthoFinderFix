#!/usr/bin/perl

use strict;
use warnings;
use Getopt::Long;

=pod

=head1 Description

Create a full singletons file with non-overlapping groups from all organism specific singleton files.

=head1 Input Parameters

=over 4

=item fileSuffix

A glob path to retrieve all singleton files

=back

=over 4

=item lastGroup

An string indicating the last non-singleton group ID from orthofinder output (Ex: OG0003785)

=back

=over 4

=item buildVersion

An integer indicating the build version of the orthofinder runs

=back

=over 4

=item outputFile

The path to the full singletons file

=back

=cut

my ($fileSuffix,$lastGroup,$buildVersion,$outputFile);

&GetOptions("fileSuffix=s"=> \$fileSuffix,
            "lastGroup=s"=> \$lastGroup,
            "buildVersion=s"=> \$buildVersion,
            "outputFile=s"=> \$outputFile);

# Setting variables in case they ever change
my $groupIntDigits = 7;

# Remove the last group prefix to just get the integer so we can iterate from it
my $lastGroupInteger = $lastGroup;
$lastGroupInteger =~ s/N0\.HOG//;

# Get all organism specific singleton files
my @singletonFiles = glob("*.${fileSuffix}");

open(OUT, ">singletonsFull.dat") || die "Could not open full singletons file: $!";

# for each organism specific singleton file
foreach my $file(@singletonFiles) {
    open(my $data, "<$file");
    while (my $line = <$data>) {
        chomp $line;
	# Create New Group
	$lastGroupInteger+=1;
	# Get New Length of Last Group Integer
	my $lengthOfLastGroupInteger = length($lastGroupInteger);
	# Add zeros in front of group to keep consistent formatting
	my $numberOfZerosToAddToStart = $groupIntDigits - $lengthOfLastGroupInteger;
	my $zeroLine = "0" x $numberOfZerosToAddToStart;
	print OUT "OG${buildVersion}_${zeroLine}${lastGroupInteger}\t$line\n";
    }
    close $data;
}

close OUT;
