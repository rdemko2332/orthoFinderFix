#!/usr/bin/perl

use strict;

use Getopt::Long;

=pod

=head1 Description

Takes a set of file of filtered blast results from makeOrthogroupDiamondFiles. This process filtered the blast data to only contain sequences that were assigned to the same group. splitBlastsIntoGroupsFiles splits this output by group. This process will be parallelized and the outputs of this process will by joined with other runs. We will end up with all of the blast data being split by group.

=head1 Input Parameters

=over 4

=item input_file

File of filtered blast results from makeOrthogroupsDiamondFiles

=back

=over 4

=item output_file_suffix

The files will be named by group, but the suffix to these files is set here

=back

=cut

my ($inputFile, $outputFileSuffix);

# the input file here MUST be sorted by the first column.  the first column will be used to name an output file $col[0]_${outputFileSuffx}

&GetOptions("input_file=s" => \$inputFile,
            "output_file_suffix=s" => \$outputFileSuffix,
           );

open(FILE, $inputFile) or die "Cannot open $inputFile for reading: $!";

my $prevOutputFileName = "Holder";
my $fh;
my $count;

while(<FILE>) {
    chomp;

    my @a = split(/\t/, $_);
    my $group = shift @a;

    my $outputFileName = "${group}${outputFileSuffix}";

    unless($prevOutputFileName eq $outputFileName) {
        close $fh if($fh); #close the open one

        # NOTE:  Appending here is important.  we will be iterating over multiple blast/diamond files
        open($fh, ">>$outputFileName") or die "Cannot open file $outputFileName for writing: $!";
    }

    # always print the line
    print $fh join("\t", @a) . "\n";
    $prevOutputFileName = $outputFileName;
    $count++;
}

close $fh if($count);
close FILE;
